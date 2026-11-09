import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/journal/presentation/journal_meal_entry.dart';
import 'package:healthmate/features/meal_drafts/data/meal_draft_store.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_private_local_data.dart';
import 'support/test_app.dart';

final draftAt = DateTime.utc(2026, 11, 7, 18, 30);
final draftItem = MealItemSnapshot.fromCatalog(
  FakeNutritionRepository.rice,
  100,
);

MealLog sourceMeal({int schema = 4}) => MealLog(
  id: 'source',
  type: MealType.dinner,
  consumedAt: draftAt,
  items: [draftItem],
  totals: draftItem.nutrition,
  source: MealSource.manual,
  dateKey: '2026-11-08',
  timezoneOffsetMinutes: 420,
  schemaVersion: schema,
);

SavedMealDraft editDraft(String id, {String? mealId = 'source'}) =>
    SavedMealDraft(
      operationId: id,
      mealId: mealId,
      updatedAt: DateTime.now(),
      draft: MealDraft(
        type: MealType.dinner,
        consumedAt: draftAt,
        items: [draftItem.withGrams(200)],
        source: MealSource.manual,
        minimumSchemaVersion: 4,
        timezoneOffsetOverride: 420,
      ),
    );

class ControlledDraftDisk extends FakePrivateLocalData {
  Completer<void>? readGate;
  bool failRead = false;
  int reads = 0;
  @override
  Future<String?> read(String uid) async {
    reads++;
    await readGate?.future;
    if (failRead) throw StateError('Fixture disk read failure');
    return super.read(uid);
  }
}

class DraftNutritionRepository extends FakeNutritionRepository {
  DraftNutritionRepository({int schema = 4})
    : super(meals: [sourceMeal(schema: schema)]);
  bool failUpdate = false;
  Completer<void>? updateGate;
  final updates = <({String uid, String id, MealDraft draft})>[];
  @override
  Future<void> updateMeal({
    required String uid,
    required String mealId,
    required MealDraft draft,
  }) async {
    updates.add((uid: uid, id: mealId, draft: draft));
    await updateGate?.future;
    if (failUpdate) throw StateError('Fixture server rejection');
    return super.updateMeal(uid: uid, mealId: mealId, draft: draft);
  }
}

class EntryHarness extends ConsumerWidget {
  const EntryHarness({this.meal, super.key});
  final MealLog? meal;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The real app keeps profile/session subscriptions active for its router.
    ref.watch(userProfileProvider);
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: const ValueKey('open-entry'),
            onPressed: () => openJournalMealForm(
              context,
              ref,
              const [FakeNutritionRepository.rice],
              meal: meal,
              initialConsumedAt: draftAt,
            ),
            child: const Text('Mở bữa'),
          ),
        ),
      ),
    );
  }
}

class DraftFixture {
  DraftFixture({int schema = 4})
    : nutrition = DraftNutritionRepository(schema: schema);
  final disk = ControlledDraftDisk();
  final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
  final DraftNutritionRepository nutrition;
  late ProviderContainer container;
  MealDraftStore get store => container.read(mealDraftStoreProvider);
  Future<void> start(WidgetTester tester, {bool editing = false}) async {
    container = await pumpApp(
      tester,
      repository: auth,
      nutritionRepository: nutrition,
      privateLocalData: disk,
    );
    // Reuse app boundaries but keep this entry point mounted through session changes.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: EntryHarness(meal: editing ? nutrition.meals.single : null),
      ),
    );
    await tester.pumpAndSettle();
  }

  void open(WidgetTester tester) => tester
      .widget<TextButton>(find.byKey(const ValueKey('open-entry')))
      .onPressed!();
}

Future<void> tapDraft(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'meal toDraft retains the recorded timezone across a different local timezone',
    () {
      final original = sourceMeal();
      expect(original.consumedAt.timeZoneOffset.inMinutes, 0);
      expect(original.toDraft().dateKey, original.dateKey);
      expect(original.toDraft().timezoneOffsetMinutes, 420);
    },
  );

  testWidgets(
    'starting a fresh edit preserves the older edit draft and its ID',
    (tester) async {
      final fixture = DraftFixture();
      await fixture.start(tester, editing: true);
      final old = editDraft('edit-source');
      await fixture.store.put('test-uid', old);
      fixture.open(tester);
      await tester.pumpAndSettle();
      expect(find.text('Sửa từ bữa đã lưu'), findsOneWidget);
      await tapDraft(tester, find.text('Sửa từ bữa đã lưu'));
      final kept = await fixture.store.list('test-uid');
      expect(kept, hasLength(2));
      final previous = kept.singleWhere(
        (d) => d.operationId == old.operationId,
      );
      final fresh = kept.singleWhere((d) => d.operationId != old.operationId);
      expect(previous.draft.items.single.grams, 200);
      expect(fresh.draft.items.single.grams, 100);
      expect(fresh.mealId, 'source');
      await tapDraft(tester, find.byTooltip('Đóng và giữ nháp'));
      expect(await fixture.store.list('test-uid'), hasLength(2));
      expect(fixture.nutrition.updates, isEmpty);
    },
  );

  testWidgets(
    'restored edit uses update, retains data on failure, retries and removes only its own draft',
    (tester) async {
      final fixture = DraftFixture();
      await fixture.start(tester);
      await fixture.store.put('test-uid', editDraft('old-edit'));
      await fixture.store.put(
        'test-uid',
        editDraft('other-draft', mealId: null),
      );
      fixture.open(tester);
      await tester.pumpAndSettle();
      await tapDraft(
        tester,
        find.byKey(const ValueKey('restore-draft-old-edit')),
      );
      expect(find.text('Sửa bữa ăn'), findsOneWidget);
      fixture.nutrition.failUpdate = true;
      await tapDraft(tester, find.byKey(const ValueKey('save-meal')));
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(
        (await fixture.store.list('test-uid'))
            .singleWhere((d) => d.operationId == 'old-edit')
            .draft
            .items
            .single
            .grams,
        200,
      );
      fixture.nutrition.failUpdate = false;
      await tapDraft(tester, find.byKey(const ValueKey('save-meal')));
      expect(fixture.nutrition.addCalls, 0);
      expect(fixture.nutrition.updates.map((u) => (u.uid, u.id)), [
        ('test-uid', 'source'),
        ('test-uid', 'source'),
      ]);
      expect(fixture.nutrition.meals.single.items.single.grams, 200);
      expect(fixture.nutrition.meals.single.dateKey, '2026-11-08');
      expect(
        (await fixture.store.list('test-uid')).single.operationId,
        'other-draft',
      );
      expect(find.text('Đã cập nhật bữa ăn.'), findsOneWidget);
    },
  );

  testWidgets(
    'legacy schema 1 meal can keep and save a valid draft without shifting day or offset',
    (tester) async {
      final fixture = DraftFixture(schema: 1);
      await fixture.start(tester, editing: true);
      fixture.open(tester);
      await tester.pumpAndSettle();
      expect(find.text('Đã giữ nháp trên thiết bị'), findsOneWidget);
      final kept = (await fixture.store.list('test-uid')).single;
      expect(kept.draft.minimumSchemaVersion, 2);
      expect(kept.draft.timezoneOffsetMinutes, 420);
      expect(kept.draft.dateKey, '2026-11-08');
      await tapDraft(tester, find.byKey(const ValueKey('save-meal')));
      final sent = fixture.nutrition.updates.single.draft;
      expect(sent.consumedAt, draftAt);
      expect(sent.dateKey, '2026-11-08');
      expect(sent.timezoneOffsetMinutes, 420);
      expect(sent.items.single.toData(), draftItem.toData());
      expect(await fixture.store.list('test-uid'), isEmpty);
    },
  );

  testWidgets(
    'double open before disk responds creates one chooser and one form',
    (tester) async {
      final fixture = DraftFixture();
      await fixture.start(tester);
      await fixture.store.put(
        'test-uid',
        editDraft('only-draft', mealId: null),
      );
      fixture.disk.readGate = Completer<void>();
      final before = fixture.disk.reads;
      fixture.open(tester);
      fixture.open(tester);
      await tester.pump();
      expect(fixture.disk.reads - before, 1);
      expect(find.byType(MealFormDialog), findsNothing);
      fixture.disk.readGate!.complete();
      fixture.disk.readGate = null;
      await tester.pumpAndSettle();
      expect(find.text('Bản nháp chưa xác nhận'), findsOneWidget);
      await tapDraft(
        tester,
        find.byKey(const ValueKey('restore-draft-only-draft')),
      );
      expect(find.byType(MealFormDialog), findsOneWidget);
      fixture.open(tester);
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(find.text('Bản nháp chưa xác nhận'), findsNothing);
    },
  );

  testWidgets(
    'disk read failure releases entry guard so opening can be retried',
    (tester) async {
      final fixture = DraftFixture();
      await fixture.start(tester);
      fixture.disk.failRead = true;
      fixture.open(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa đọc được nháp cũ'), findsOneWidget);
      expect(find.byType(MealFormDialog), findsNothing);
      fixture.disk.failRead = false;
      fixture.open(tester);
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsOneWidget);
    },
  );

  testWidgets(
    'A to logout to A invalidates an old disk read without releasing the newer form guard',
    (tester) async {
      final fixture = DraftFixture();
      await fixture.start(tester);
      fixture.disk.readGate = Completer<void>();
      fixture.open(tester);
      await tester.pump();
      fixture.auth.emitUser(null);
      await tester.pumpAndSettle();
      fixture.auth.emitUser(FakeAuthRepository.testUser);
      await tester.pumpAndSettle();
      expect(
        fixture.container.read(authSessionProvider).value?.uid,
        'test-uid',
      );
      fixture.open(tester);
      await tester.pump();
      fixture.disk.readGate!.complete();
      fixture.disk.readGate = null;
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsOneWidget);
      fixture.open(tester);
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(find.text('Bản nháp chưa xác nhận'), findsNothing);
      expect(fixture.nutrition.addCalls, 0);
    },
  );

  testWidgets('cancel chooser releases guard and writes nothing', (
    tester,
  ) async {
    final fixture = DraftFixture();
    await fixture.start(tester);
    await fixture.store.put('test-uid', editDraft('leave-later', mealId: null));
    fixture.open(tester);
    await tester.pumpAndSettle();
    await tapDraft(tester, find.text('Để sau'));
    fixture.open(tester);
    await tester.pumpAndSettle();
    expect(find.text('Bản nháp chưa xác nhận'), findsOneWidget);
    expect(
      (await fixture.store.list('test-uid')).single.operationId,
      'leave-later',
    );
    expect(fixture.nutrition.addCalls, 0);
    expect(fixture.nutrition.updates, isEmpty);
  });

  testWidgets(
    'disposing the old entry while disk is pending does not block a new mounted entry',
    (tester) async {
      final fixture = DraftFixture();
      await fixture.start(tester);
      fixture.disk.readGate = Completer<void>();
      fixture.open(tester);
      await tester.pump();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: fixture.container,
          child: const EntryHarness(key: ValueKey('replacement-entry')),
        ),
      );
      await tester.pumpAndSettle();
      fixture.open(tester);
      await tester.pump();
      fixture.disk.readGate!.complete();
      fixture.disk.readGate = null;
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsOneWidget);
      fixture.open(tester);
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(fixture.nutrition.addCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
