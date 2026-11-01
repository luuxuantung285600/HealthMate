import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/food_library/models/favorite_food.dart';
import 'package:healthmate/features/food_library/presentation/meal_food_sources.dart';
import 'package:healthmate/features/food_library/providers/favorite_food_providers.dart';
import 'package:healthmate/features/journal/providers/journal_date_provider.dart';
import 'package:healthmate/features/nutrition/models/nutrition_failure.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';
import 'package:healthmate/features/nutrition/presentation/meal_log_section.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'support/fake_auth_repository.dart';
import 'support/fake_favorite_food_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/test_app.dart';

MealLog meal(
  String id, {
  MealType type = MealType.lunch,
  DateTime? date,
  double grams = 150,
}) {
  final draft = MealDraft(
    type: type,
    consumedAt: date ?? DateTime(2026, 10, 16, 12, 30),
    items: [MealItemSnapshot.fromCatalog(FakeNutritionRepository.rice, grams)],
    source: MealSource.manual,
  );
  return MealLog(
    id: id,
    type: type,
    consumedAt: draft.consumedAt,
    items: draft.items,
    totals: draft.totals,
    source: draft.source,
    dateKey: draft.dateKey,
    timezoneOffsetMinutes: draft.timezoneOffsetMinutes,
  );
}

class CatalogRepository extends FakeNutritionRepository {
  CatalogRepository({
    this.foods = const [FakeNutritionRepository.rice],
    this.catalogError,
  });
  final List<FoodCatalogItem> foods;
  final Object? catalogError;
  @override
  Stream<List<FoodCatalogItem>> watchFoodCatalog() =>
      catalogError == null ? Stream.value(foods) : Stream.error(catalogError!);
}

class UnknownAckRepository extends FakeNutritionRepository {
  UnknownAckRepository() : super(meals: [meal('source')]);
  final gate = Completer<void>();
  int attempts = 0;
  @override
  Future<String> addMeal({
    required String uid,
    required MealDraft draft,
    String? operationId,
  }) async {
    attempts++;
    if (attempts == 1) {
      await gate.future;
      await super.addMeal(uid: uid, draft: draft, operationId: operationId);
      throw const NutritionFailure('Chưa nhận xác nhận.');
    }
    return super.addMeal(uid: uid, draft: draft, operationId: operationId);
  }
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<ProviderContainer> sources(
  WidgetTester tester, {
  FakeNutritionRepository? nutrition,
  FakeFavoriteFoodRepository? favorites,
  FakeAuthRepository? auth,
  ValueChanged<MealItemSnapshot>? onRecent,
  ValueChanged<FoodCatalogItem>? onCatalog,
  Widget Function(Widget child)? wrap,
  GlobalKey? capture,
  bool dark = false,
}) async {
  final n = nutrition ?? FakeNutritionRepository();
  final f = favorites ?? FakeFavoriteFoodRepository();
  final a = auth ?? FakeAuthRepository(user: FakeAuthRepository.testUser);
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(a),
      nutritionRepositoryProvider.overrideWithValue(n),
      favoriteFoodRepositoryProvider.overrideWithValue(f),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await n.dispose();
    await f.dispose();
    await a.dispose();
  });
  final child = MealFoodSources(
    onCatalog: onCatalog ?? (_) {},
    onRecent: onRecent ?? (_) {},
    onCustom: () {},
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: capture,
        child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          locale: const Locale('vi'),
          supportedLocales: const [Locale('vi')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home:
              wrap?.call(child) ??
              Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: child,
                ),
              ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() async {
    final fonts = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(
        rootBundle.load('assets/fonts/be_vietnam_pro/BeVietnamPro-$weight.ttf'),
      );
    }
    await fonts.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  test(
    'favorite identity is deterministic, namespaced and rejects invalid IDs',
    () {
      expect(favoriteFoodId('cơm-1'), 'catalog_cơm-1');
      expect(favoriteFoodId('Rice'), isNot(favoriteFoodId('rice')));
      for (final id in ['', 'a/b', 'a' * 101]) {
        expect(() => favoriteFoodId(id), throwsFormatException);
      }
    },
  );
  test(
    'copy crosses month/year and midnight, preserves snapshots and derives local date',
    () {
      final original = meal('source', date: DateTime(2026, 1, 1, 0, 0));
      final copied = original.copyDraft(
        day: DateTime(2025, 12, 31),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(copied.consumedAt, DateTime(2025, 12, 31));
      expect(copied.dateKey, '2025-12-31');
      expect(
        copied.timezoneOffsetMinutes,
        copied.consumedAt.timeZoneOffset.inMinutes,
      );
      expect(copied.items.single.nutrition.kcal, 195);
      expect(
        copied.items.single.sourceLabel,
        original.items.single.sourceLabel,
      );
      expect(() => copied.items.clear(), throwsUnsupportedError);
      expect(original.consumedAt, DateTime(2026, 1, 1));
      final late = meal('late', date: DateTime(2026, 1, 1, 23, 59));
      expect(
        late
            .copyDraft(
              day: DateTime(2026, 1, 2),
              now: DateTime(2026, 1, 2, 7, 15),
            )
            .consumedAt,
        DateTime(2026, 1, 2, 7, 15),
      );
      expect(
        () => late.copyDraft(
          day: DateTime(2026, 1, 3),
          now: DateTime(2026, 1, 2),
        ),
        throwsFormatException,
      );
    },
  );
  testWidgets(
    'catalog failure does not hide independent meal groups or their totals',
    (tester) async {
      final logs = [
        meal('one', type: MealType.breakfast),
        meal('two', type: MealType.breakfast, grams: 100),
        meal('three', type: MealType.dinner),
      ];
      MealType? added;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MealLogSection(
                catalogState: AsyncError(
                  Exception('fixture'),
                  StackTrace.current,
                ),
                mealsState: AsyncData(logs),
                catalog: const [],
                meals: logs,
                action: const AsyncData(null),
                onAdd: () {},
                onAddForType: (type) => added = type,
                onScan: null,
                onEdit: (_) {},
                onDelete: (_) {},
                onRetry: () {},
                onDismissError: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('325 kcal'), findsOneWidget);
      for (final type in MealType.values) {
        expect(find.byKey(ValueKey('meal-group-${type.name}')), findsOneWidget);
      }
      expect(find.textContaining('Cơm trắng chín · 150 g'), findsNWidgets(2));
      await tapVisible(tester, find.byKey(const ValueKey('add-meal-snack')));
      expect(added, MealType.snack);
    },
  );
  testWidgets('group add keeps selected day and chosen type', (tester) async {
    final repository = FakeNutritionRepository();
    final container = await pumpApp(tester, nutritionRepository: repository);
    container.read(appRouterProvider).go(AppRoutes.journal);
    container.read(journalDateProvider.notifier).select(DateTime(2026, 10, 15));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('add-meal-dinner')));
    final form = tester.widget<MealFormDialog>(find.byType(MealFormDialog));
    expect(form.initialType, MealType.dinner);
    expect(form.initialConsumedAt!.day, 15);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(repository.addCalls, 0);
  });
  testWidgets(
    'bounded recent window is shared for initial choice; other sources remain lazy',
    (tester) async {
      final repository = FakeNutritionRepository();
      MealItemSnapshot? selected;
      await sources(
        tester,
        nutrition: repository,
        onRecent: (item) => selected = item,
      );
      expect(repository.recentWatchCalls, 1);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('food-source-recent')),
      );
      expect(
        find.textContaining('Chưa có món gần đây phù hợp'),
        findsOneWidget,
      );
      await repository.addMeal(uid: 'test-uid', draft: meal('new').toDraft());
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byTooltip('Dùng lại Cơm trắng chín'));
      expect(selected!.grams, 150);
      expect(selected!.nutrition.kcal, 195);
      expect(find.byType(ChoiceChip), findsNWidgets(6));
      expect(find.text('Công thức'), findsOneWidget);
    },
  );
  testWidgets(
    'recent loading, read failure/retry and cached empty are distinct',
    (tester) async {
      final repository = FakeNutritionRepository(emitImmediately: false);
      await sources(tester, nutrition: repository);
      await tester.tap(find.byKey(const ValueKey('food-source-recent')));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      repository.recentError = const NutritionFailure('fixture');
      repository.emitPending();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('không coi lỗi là chưa có dữ liệu'),
        findsOneWidget,
      );
      repository.recentError = null;
      repository.recentFromCache = true;
      await tester.tap(find.text('Thử tải lại nguồn món'));
      await tester.pump();
      repository.emitPending();
      await tester.pumpAndSettle();
      expect(
        find.text('Chưa xác nhận được món gần đây từ máy chủ.'),
        findsOneWidget,
      );
    },
  );
  testWidgets('recent snapshot remains usable when catalog is gone', (
    tester,
  ) async {
    final repository = CatalogRepository(foods: []);
    await repository.addMeal(uid: 'test-uid', draft: meal('old').toDraft());
    MealItemSnapshot? selected;
    await sources(
      tester,
      nutrition: repository,
      onRecent: (item) => selected = item,
    );
    await tapVisible(tester, find.byKey(const ValueKey('food-source-recent')));
    await tapVisible(tester, find.byTooltip('Dùng lại Cơm trắng chín'));
    expect(selected!.withGrams(100).nutrition.kcal, 130);
  });
  testWidgets(
    'saving favorite twice keeps one entry; pending blocks duplicate; failure permits retry',
    (tester) async {
      final favorites = FakeFavoriteFoodRepository()
        ..pending = Completer<void>();
      await sources(tester, favorites: favorites);
      final button = find.byKey(const ValueKey('save-favorite-rice-cooked'));
      await tester.tap(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      expect(favorites.calls, 1);
      expect(find.text('Đang lưu yêu thích…'), findsOneWidget);
      favorites.pending!.complete();
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(favorites.byUid['test-uid'], hasLength(1));
      favorites.failWrite = true;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text(const FavoriteFoodFailure().message), findsOneWidget);
      favorites.failWrite = false;
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(favorites.byUid['test-uid'], hasLength(1));
    },
  );
  testWidgets(
    'missing favorite source can be removed without synthesizing nutrition',
    (tester) async {
      final favorites = FakeFavoriteFoodRepository()
        ..byUid['test-uid'] = {
          'catalog_gone': const FavoriteFood(sourceId: 'gone'),
        };
      await sources(tester, favorites: favorites);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('food-source-favorites')),
      );
      expect(find.text('Món không còn khả dụng: gone'), findsOneWidget);
      expect(find.byTooltip('Thêm gone'), findsNothing);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('remove-favorite-gone')),
      );
      expect(favorites.byUid['test-uid'], isEmpty);
      expect(find.textContaining('Chưa có yêu thích.'), findsOneWidget);
    },
  );
  testWidgets(
    'favorites read error, retry and cached empty do not claim server empty',
    (tester) async {
      final favorites = FakeFavoriteFoodRepository()..failRead = true;
      await sources(tester, favorites: favorites);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('food-source-favorites')),
      );
      expect(
        find.textContaining('không coi lỗi là danh sách rỗng'),
        findsOneWidget,
      );
      favorites.failRead = false;
      favorites.fromCache = true;
      await tapVisible(tester, find.text('Thử tải lại nguồn món'));
      expect(
        find.text('Chưa xác nhận được yêu thích từ máy chủ.'),
        findsOneWidget,
      );
    },
  );
  testWidgets('favorites expand beyond 40 without hiding missing sources', (
    tester,
  ) async {
    final favorites = FakeFavoriteFoodRepository()
      ..byUid['test-uid'] = {
        for (var i = 0; i < 41; i++)
          'catalog_missing$i': FavoriteFood(sourceId: 'missing$i'),
      };
    await sources(tester, favorites: favorites);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('food-source-favorites')),
    );
    expect(find.text('Món không còn khả dụng: missing40'), findsNothing);
    await tapVisible(tester, find.byKey(const ValueKey('more-favorites')));
    expect(find.text('Món không còn khả dụng: missing40'), findsOneWidget);
    expect(favorites.watchCalls, 2);
  });
  testWidgets('account switch isolates list and ignores late favorite result', (
    tester,
  ) async {
    final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
    final favorites = FakeFavoriteFoodRepository()..pending = Completer<void>();
    final container = await sources(tester, auth: auth, favorites: favorites);
    final future = container
        .read(favoriteFoodControllerProvider.notifier)
        .setFavorite('rice-cooked', true);
    await tester.pump();
    auth.emitUser(
      const AuthUser(
        emailVerified: true,
        uid: 'bob',
        email: 'bob@example.test',
      ),
    );
    await tester.pumpAndSettle();
    favorites.pending!.complete();
    await tester.pumpAndSettle();
    expect(await future, isFalse);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('food-source-favorites')),
    );
    expect(find.textContaining('Chưa có yêu thích.'), findsOneWidget);
    expect(favorites.writtenUids, ['test-uid']);
    expect(favorites.byUid['bob'], isNull);
    expect(find.text('Đã lưu món vào yêu thích.'), findsNothing);
  });
  testWidgets(
    'copy cancel writes nothing; unknown acknowledgment retry uses same ID and preserves source',
    (tester) async {
      final repository = UnknownAckRepository();
      final container = await pumpApp(tester, nutritionRepository: repository);
      container.read(appRouterProvider).go(AppRoutes.journal);
      container
          .read(journalDateProvider.notifier)
          .select(DateTime(2026, 10, 16));
      await tester.pumpAndSettle();
      void duplicate() => tester
          .widgetList<PopupMenuButton<String>>(
            find.byType(PopupMenuButton<String>),
          )
          .first
          .onSelected!('duplicate');
      duplicate();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      expect(repository.addCalls, 0);
      duplicate();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-meal')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('save-meal')))
            .onPressed,
        isNull,
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('save-meal'))),
      );
      await tester.pump();
      expect(repository.attempts, 1);
      repository.gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(MealFormDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MealFormDialog),
          matching: find.text('Chưa nhận xác nhận.'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('save-meal')));
      await tester.pumpAndSettle();
      expect(repository.meals, hasLength(2));
      expect(repository.operationIds[0], repository.operationIds[1]);
      expect(
        repository.meals
            .firstWhere((m) => m.id == 'source')
            .items
            .single
            .nutrition
            .kcal,
        195,
      );
      duplicate();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-meal')));
      await tester.pumpAndSettle();
      expect(repository.meals, hasLength(3));
      expect(
        repository.operationIds.last,
        isNot(repository.operationIds.first),
      );
    },
  );
  testWidgets('missing catalog nutrition is disabled, not presented as zero', (
    tester,
  ) async {
    const missing = FoodCatalogItem(
      id: 'bad',
      name: 'Món thiếu chất béo',
      alternateNames: [],
      category: 'Fixture',
      servingBasis: ServingBasis.per100g,
      unit: 'g',
      per100g: NutritionTotals(),
      sourceLabel: 'Fixture',
      isEstimated: true,
      hasNutritionData: false,
    );
    FoodCatalogItem? selected;
    await sources(
      tester,
      nutrition: CatalogRepository(foods: [missing]),
      onCatalog: (food) => selected = food,
    );
    expect(find.textContaining('thiếu dữ liệu dinh dưỡng'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('catalog-food-bad')),
                  matching: find.byType(IconButton),
                )
                .last,
          )
          .onPressed,
      isNull,
    );
    expect(find.textContaining('0 kcal / 100 g'), findsNothing);
    expect(selected, isNull);
    expect(() => missing.forGrams(150), throwsFormatException);
    var writes = 0;
    await sources(
      tester,
      wrap: (_) => MealFormDialog(
        catalog: const [missing],
        suggestedFood: missing,
        onSave: (_) async {
          writes++;
          return false;
        },
      ),
    );
    expect(
      find.textContaining('Món gợi ý thiếu dữ liệu dinh dưỡng'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('save-meal')));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'copied draft edits date, time, type and grams without touching source',
    (tester) async {
      final original = meal('source');
      MealDraft? saved;
      await sources(
        tester,
        wrap: (_) => MealFormDialog(
          catalog: const [],
          initialConsumedAt: original.consumedAt,
          initialItems: original.items,
          initialType: original.type,
          aiAssisted: true,
          onSave: (draft) async {
            saved = draft;
            return false;
          },
        ),
      );
      await tester.tap(find.byTooltip('Ngày và giờ ăn'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Ngày:').last);
      await tester.pumpAndSettle();
      Navigator.of(
        tester.element(find.byType(DatePickerDialog)),
      ).pop(DateTime(2026, 10, 15));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ngày và giờ ăn'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Giờ:').last);
      await tester.pumpAndSettle();
      Navigator.of(
        tester.element(find.byType(TimePickerDialog)),
      ).pop(const TimeOfDay(hour: 18, minute: 45));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<MealType>>(
            find.byKey(const ValueKey('meal-type')),
          )
          .onChanged!(MealType.dinner);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip('Sửa khẩu phần'),
        180,
        scrollable: find
            .descendant(
              of: find.byType(MealFormDialog),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tapVisible(tester, find.byTooltip('Sửa khẩu phần'));
      await tester.enterText(find.byKey(const ValueKey('meal-grams')), '100');
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-meal')));
      await tester.pumpAndSettle();
      expect(saved!.type, MealType.dinner);
      expect(saved!.consumedAt, DateTime(2026, 10, 15, 18, 45));
      expect(saved!.dateKey, '2026-10-15');
      expect(saved!.source, MealSource.aiAssisted);
      expect(saved!.items.single.grams, 100);
      expect(saved!.totals.kcal, 130);
      expect(original.items.single.grams, 150);
      expect(original.totals.kcal, 195);
    },
  );
  testWidgets(
    'group and daily totals refresh after editing and deleting one independent log',
    (tester) async {
      final repository = FakeNutritionRepository(
        meals: [
          meal('one', type: MealType.breakfast),
          meal('two', type: MealType.breakfast, grams: 100),
        ],
      );
      final container = await pumpApp(tester, nutritionRepository: repository);
      container.read(appRouterProvider).go(AppRoutes.journal);
      container
          .read(journalDateProvider.notifier)
          .select(DateTime(2026, 10, 16));
      await tester.pumpAndSettle();
      expect(find.text('325 kcal'), findsOneWidget);
      await repository.updateMeal(
        uid: 'test-uid',
        mealId: 'one',
        draft: meal('edited', type: MealType.dinner, grams: 50).toDraft(),
      );
      await tester.pumpAndSettle();
      expect(find.text('130 kcal'), findsOneWidget);
      expect(find.text('65 kcal'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('nutrition-daily-totals')))
            .semanticsLabel,
        startsWith('195 kcal'),
      );
      await repository.deleteMeal(uid: 'test-uid', mealId: 'one');
      await tester.pumpAndSettle();
      expect(repository.meals.single.id, 'two');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('nutrition-daily-totals')))
            .semanticsLabel,
        startsWith('130 kcal'),
      );
    },
  );
  for (final count in [5, 6]) {
    testWidgets(
      'meal draft validates $count selected items without raising the limit',
      (tester) async {
        var saved = 0;
        await sources(
          tester,
          wrap: (_) => MealFormDialog(
            catalog: const [],
            initialItems: List.generate(
              count,
              (_) => meal('fixture', grams: 10).items.single,
            ),
            onSave: (draft) async {
              saved++;
              return false;
            },
          ),
        );
        await tester.tap(find.byKey(const ValueKey('save-meal')));
        await tester.pumpAndSettle();
        expect(saved, count == 5 ? 1 : 0);
        if (count == 6) {
          expect(
            find.textContaining('Mỗi bản ghi tối đa 5 món'),
            findsOneWidget,
          );
        }
      },
    );
  }
  for (final width in [360.0, 390.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('C3 sources/form keyboard fit $width x$scale dark=$dark', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(tester.view.resetViewInsets);
          final capture = GlobalKey();
          final favorites = FakeFavoriteFoodRepository()
            ..byUid['test-uid'] = {
              'catalog_rice-cooked': const FavoriteFood(
                sourceId: 'rice-cooked',
              ),
              'catalog_missing-source-long-name': const FavoriteFood(
                sourceId: 'missing-source-long-name',
              ),
            };
          await sources(
            tester,
            favorites: favorites,
            dark: dark,
            capture: capture,
            wrap: (_) => MealFormDialog(
              catalog: const [],
              initialItems: meal('copy').items,
              sourcesBuilder:
                  (onCatalog, onRecent, onCustom, diet, avoidance) =>
                      MealFoodSources(
                        diet: diet,
                        avoidance: avoidance,
                        onCatalog: onCatalog,
                        onRecent: onRecent,
                        onCustom: onCustom,
                      ),
            ),
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('food-search')),
            180,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('meal-manual-content')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(find.byKey(const ValueKey('food-search')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('food-search')));
          await tester.pump();
          tester.view.viewInsets = const FakeViewPadding(bottom: 260);
          await tester.pumpAndSettle();
          expect(
            tester.getBottomRight(find.byKey(const ValueKey('save-meal'))).dy,
            lessThanOrEqualTo(540),
          );
          expect(tester.takeException(), isNull);
          if ((width == 360 && scale == 1 && !dark) ||
              (width == 390 && scale == 1.5 && dark) ||
              (width == 412 && scale == 2 && !dark)) {
            await tester.runAsync(() async {
              final boundary =
                  capture.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              await Directory('build/c3-layout').create(recursive: true);
              await File(
                'build/c3-layout/$width-$scale-$dark.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
            });
          }
          tester.view.resetViewInsets();
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tapVisible(
            tester,
            find.byKey(const ValueKey('food-source-favorites')),
          );
          await tapVisible(
            tester,
            find.byKey(
              const ValueKey('remove-favorite-missing-source-long-name'),
            ),
          );
          expect(favorites.byUid['test-uid'], hasLength(1));
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('favorite-food-rice-cooked')),
            -150,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('meal-manual-content')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
