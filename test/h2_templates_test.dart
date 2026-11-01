import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/meal_templates/models/meal_template.dart';
import 'package:healthmate/features/meal_templates/data/meal_template_repository.dart';
import 'package:healthmate/features/meal_templates/providers/meal_template_providers.dart';
import 'package:healthmate/features/meal_templates/presentation/meal_template_panel.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_nutrition_repository.dart';

final item = MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, 150);

class MemoryTemplates implements MealTemplateRepository {
  final values = <String, Map<String, MealTemplate>>{};
  final ids = <String>[];
  Completer<void>? gate;
  bool fail = false;
  @override
  String newId() => 'stable-template';
  @override
  Stream<List<MealTemplate>> watch(String uid, {int limit = 40}) =>
      Stream.value(values[uid]?.values.take(limit).toList() ?? []);
  @override
  Future<void> save(String uid, MealTemplate t, {required bool create}) async {
    ids.add(t.id);
    if (gate != null) await gate!.future;
    if (fail) throw const MealTemplateFailure('QA failed');
    values.putIfAbsent(uid, () => {})[t.id] = t;
  }

  @override
  Future<void> delete(String uid, String id) async {
    values[uid]?.remove(id);
  }
}

void main() {
  test(
    'pending template result from A cannot become B state or data',
    () async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final repo = MemoryTemplates()
        ..gate = Completer<void>()
        ..fail = true;
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          mealTemplateRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      container.listen(authSessionProvider, (_, _) {});
      await container.read(authSessionProvider.future);
      final subscription = container.listen(
        mealTemplateControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final pending = container
          .read(mealTemplateControllerProvider.notifier)
          .save(
            MealTemplate(id: 'pending-a', name: 'A draft', items: [item]),
            create: true,
          );
      auth.emitUser(
        const AuthUser(emailVerified: true, uid: 'b', email: 'b@example.com'),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      repo.gate!.complete();
      expect(await pending, isFalse);
      expect(container.read(mealTemplateControllerProvider).hasError, isFalse);
      expect(container.read(mealTemplateControllerProvider).isLoading, isFalse);
      expect(repo.values['b'], isNull);
    },
  );
  test(
    'template bounded snapshots roundtrip independently of source changes',
    () {
      final t = MealTemplate(
        id: 'stable',
        name: 'Bữa mẫu',
        items: [item, item.withGrams(100)],
      );
      final loaded = MealTemplate.fromData(
        t.id,
        Map<String, dynamic>.from(t.toData()),
      );
      expect(loaded.items.length, 2);
      expect(loaded.items.first.nutrition.kcal, 195);
      final edited = loaded.items.first.withGrams(200);
      expect(edited.nutrition.kcal, 260);
      expect(loaded.items.first.grams, 150);
      for (final list in [<MealItemSnapshot>[], List.filled(6, item)]) {
        expect(
          () => MealTemplate(id: 'x', name: 'Bữa mẫu', items: list).validate(),
          throwsFormatException,
        );
      }
      expect(
        () => MealTemplate(id: 'x', name: '', items: [item]).validate(),
        throwsFormatException,
      );
    },
  );
  test(
    'frequent counts meals, keeps latest quantity, and uses bounded input only',
    () {
      MealLog meal(String id, List<MealItemSnapshot> items) => MealLog(
        id: id,
        type: MealType.lunch,
        consumedAt: DateTime(2026, 1, 1),
        items: items,
        totals: const NutritionTotals(),
        source: MealSource.manual,
      );
      final egg = MealItemSnapshot.fromCatalog(FakeNutritionRepository.egg, 50);
      final ranked = frequentMealItems([
        meal('new', [item.withGrams(200), item]),
        meal('older', [item, egg]),
        meal('old', [egg]),
      ]);
      expect(ranked.map((r) => r.count), [2, 2]);
      expect(ranked.first.item.grams, 200);
      expect(frequentMealItems([], limit: 8), isEmpty);
    },
  );

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets(
      'template editor retains failed draft and ID, blocks repeated pending save x$scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = MemoryTemplates()
          ..gate = Completer<void>()
          ..fail = true;
        final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(auth),
              mealTemplateRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp(
              builder: (_, child) => MediaQuery(
                data: MediaQueryData(
                  size: const Size(360, 800),
                  textScaler: TextScaler.linear(scale),
                  viewInsets: const EdgeInsets.only(bottom: 200),
                ),
                child: child!,
              ),
              home: Consumer(
                builder: (context, ref, _) {
                  final session = ref.watch(authSessionProvider);
                  return Scaffold(
                    body: TextButton(
                      onPressed: session.value == null
                          ? null
                          : () => editMealTemplate(
                              context,
                              initialItems: [item, item.withGrams(100)],
                            ),
                      child: const Text('Open'),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('meal-template-name')),
          'Bữa mẫu QA',
        );
        final save = find.byKey(const ValueKey('save-meal-template'));
        await tester.tap(save);
        await tester.pump();
        await tester.tap(save, warnIfMissed: false);
        await tester.pump();
        expect(repo.ids, ['stable-template']);
        expect(find.byType(MealTemplateEditor), findsOneWidget);
        repo.gate!.complete();
        await tester.pumpAndSettle();
        expect(find.text('Bữa mẫu QA'), findsOneWidget);
        repo.fail = false;
        repo.gate = null;
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(repo.ids, ['stable-template', 'stable-template']);
        expect(
          repo
              .values[FakeAuthRepository.testUser.uid]!
              .values
              .single
              .items
              .length,
          2,
        );
        expect(find.byType(MealTemplateEditor), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
