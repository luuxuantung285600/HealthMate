import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/data/user_data_revision.dart';
import 'package:healthmate/core/data/private_data_changes.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/food_library/models/food_library_models.dart';
import 'package:healthmate/features/food_library/providers/food_library_providers.dart';
import 'package:healthmate/features/nutrition/models/food_visibility.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/reports/models/period_report.dart';
import 'package:healthmate/features/reports/providers/report_providers.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';
import 'package:healthmate/features/weekly_reflection/providers/weekly_reflection_providers.dart';
import 'support/fake_activity_repository.dart';
import 'support/fake_food_library_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_nutrition_repository.dart';
import 'support/fake_nutrition_target_repository.dart';
import 'support/fake_water_repository.dart';

void main() {
  test(
    'Spark watches bounded calendar ranges, legacy meals, effective targets and one private library document',
    () {
      final start = DateTime(2026, 11, 2), end = DateTime(2026, 11, 9);
      final meal = privateRangeScopes('meal_logs', start, end);
      expect(meal.map((scope) => scope.field), ['dateKey', 'consumedAt']);
      expect(meal.first.lower, '2026-11-02');
      expect(meal.first.upper, '2026-11-09');
      expect(meal.first.upperInclusive, isFalse);
      expect(meal.last.lower, Timestamp.fromDate(start));
      for (final source in [
        'water_logs',
        'activity_logs',
        'body_metrics',
        'day_reviews',
        'sleep_logs',
      ]) {
        expect(
          privateRangeScopes(source, start, end).single.maxRecords,
          source == 'day_reviews' ? 90 : 2000,
        );
      }
      final targets = privateRangeScopes('nutrition_targets', start, end);
      expect(targets.first.descending, isTrue);
      expect(targets.first.maxRecords, 1);
      expect(targets.first.upperInclusive, isTrue);
      expect(targets.last.lowerInclusive, isFalse);
      expect(privateLibraryScope('recipes', 'fixture').documentId, 'fixture');
      expect(
        () => privateLibraryScope('users', 'other'),
        throwsFormatException,
      );
      expect(
        () => privateLibraryScope('custom_foods', 'a/b'),
        throwsFormatException,
      );
      expect(
        () => privateRangeScopes('water_logs', start, DateTime(2027, 3)),
        throwsA(anything),
      );
    },
  );

  const owner = AuthUser(
    uid: 'realtime-owner',
    email: 'owner@example.test',
    emailVerified: true,
  );

  test(
    'an open weekly reflection reloads all four sources after remote changes',
    () async {
      final revisions = StreamController<Map<String, dynamic>>.broadcast();
      final meals = FakeNutritionRepository();
      final water = FakeWaterRepository();
      final activity = FakeActivityRepository();
      final profile = FakeHealthProfileRepository();
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith((ref) => Stream.value(owner)),
          userDataRevisionProvider.overrideWith((ref) => revisions.stream),
          nutritionRepositoryProvider.overrideWithValue(meals),
          waterRepositoryProvider.overrideWithValue(water),
          activityRepositoryProvider.overrideWithValue(activity),
          healthProfileRepositoryProvider.overrideWithValue(profile),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await revisions.close();
        await meals.dispose();
        await water.dispose();
        await activity.dispose();
        await profile.dispose();
      });
      final session = container.listen(authSessionProvider, (_, _) {});
      addTearDown(session.close);
      await container.read(authSessionProvider.future);
      final provider = weeklyLogsProvider(DateTime(2026, 11, 2));
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      revisions.add({});
      await Future<void>.delayed(Duration.zero);
      expect((await container.read(provider.future)).water, isEmpty);
      final initial = meals.rangeCalls;
      await water.add(
        uid: owner.uid,
        draft: WaterLogDraft(
          amountMl: 250,
          consumedAt: DateTime(2026, 11, 6, 9),
        ),
      );
      final state = <String, dynamic>{};
      for (final (index, source) in [
        'meal_logs',
        'water_logs',
        'activity_logs',
        'body_metrics',
      ].indexed) {
        state[source] = Timestamp.fromMillisecondsSinceEpoch(index + 1);
        revisions.add({...state});
        await Future<void>.delayed(Duration.zero);
        final logs = await container.read(provider.future);
        expect(logs.water.single.amountMl, 250);
        expect(meals.rangeCalls, initial + index + 1);
        expect(water.rangeCalls, meals.rangeCalls);
        expect(activity.rangeCalls, meals.rangeCalls);
        expect(profile.metricRangeCalls, meals.rangeCalls);
      }
      final loaded = meals.rangeCalls;
      revisions.add({
        ...state,
        'recipes': Timestamp.fromMillisecondsSinceEpoch(10),
      });
      await Future<void>.delayed(Duration.zero);
      expect(
        meals.rangeCalls,
        loaded,
        reason: 'Unrelated changes must not reread the week.',
      );
    },
  );

  for (final kind in [FoodSourceKind.custom, FoodSourceKind.recipe]) {
    test(
      'open ${kind.name} detail reflects remote edits and deletion without unrelated reads',
      () async {
        final revisions = StreamController<Map<String, dynamic>>.broadcast();
        final library = FakeFoodLibraryRepository();
        LibraryEntry entry(String name) => kind == FoodSourceKind.custom
            ? PersonalFood(
                id: 'fixture',
                name: name,
                per100g: const NutritionTotals(
                  kcal: 100,
                  proteinG: 2,
                  carbsG: 20,
                  fatG: 1,
                ),
              )
            : FoodRecipe(
                id: 'fixture',
                name: name,
                ingredients: [
                  MealItemSnapshot.fromCatalog(
                    FakeNutritionRepository.egg,
                    100,
                  ),
                ],
                yieldGrams: 100,
              );
        library.seed(owner.uid, entry('Before remote edit'));
        final container = ProviderContainer(
          overrides: [
            authSessionProvider.overrideWith((ref) => Stream.value(owner)),
            userDataRevisionProvider.overrideWith((ref) => revisions.stream),
            foodLibraryRepositoryProvider.overrideWithValue(library),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await revisions.close();
          await library.dispose();
        });
        final session = container.listen(authSessionProvider, (_, _) {});
        addTearDown(session.close);
        await container.read(authSessionProvider.future);
        final provider = libraryEntryProvider((kind: kind, id: 'fixture'));
        final subscription = container.listen(provider, (_, _) {});
        addTearDown(subscription.close);
        revisions.add({});
        await Future<void>.delayed(Duration.zero);
        expect(
          (await container.read(provider.future))?.name,
          'Before remote edit',
        );
        final initial = library.loadCalls;
        final source = kind == FoodSourceKind.custom
            ? 'custom_foods'
            : 'recipes';
        final other = kind == FoodSourceKind.custom
            ? 'recipes'
            : 'custom_foods';
        final first = Timestamp.fromMillisecondsSinceEpoch(1);
        revisions.add({other: first});
        await Future<void>.delayed(Duration.zero);
        expect(library.loadCalls, initial);
        library.seed(owner.uid, entry('After remote edit'));
        revisions.add({source: first, other: first});
        await Future<void>.delayed(Duration.zero);
        expect(
          (await container.read(provider.future))?.name,
          'After remote edit',
        );
        expect(library.loadCalls, initial + 1);
        await library.delete(owner.uid, kind, 'fixture');
        revisions.add({
          source: Timestamp.fromMillisecondsSinceEpoch(2),
          other: first,
        });
        await Future<void>.delayed(Duration.zero);
        expect(await container.read(provider.future), isNull);
        expect(library.loadCalls, initial + 2);
      },
    );
  }

  test(
    'archiving a public food suppresses both cache IDs and USDA identity, while restore and private foods remain available',
    () {
      const cached = FoodCatalogItem(
        id: 'usda_123',
        name: 'Synthetic cached food',
        category: 'Fixture',
        servingBasis: ServingBasis.per100g,
        sourceLabel: 'Test fixture',
        isEstimated: true,
        fdcId: 123,
      );
      const own = FoodCatalogItem(
        id: 'custom-123',
        name: 'Private food',
        category: 'Fixture',
        servingBasis: ServingBasis.per100g,
        sourceLabel: 'User',
        isEstimated: true,
        dataSource: FoodDataSource.user,
        fdcId: 123,
      );
      expect(
        const FoodVisibility(hiddenIds: {'usda-123'}).allows(cached),
        isFalse,
      );
      expect(const FoodVisibility(hiddenFdcIds: {123}).allows(cached), isFalse);
      expect(const FoodVisibility(hiddenFdcIds: {123}).allows(own), isTrue);
      expect(const FoodVisibility().allows(cached), isTrue);
    },
  );

  test(
    'only the changed source invalidates range reports and daily nutrition targets',
    () async {
      const user = AuthUser(
        uid: 'realtime-owner',
        email: 'owner@example.test',
        emailVerified: true,
      );
      final revisions = StreamController<Map<String, dynamic>>.broadcast();
      final meals = FakeNutritionRepository(),
          targets = FakeNutritionTargetRepository();
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith((ref) => Stream.value(user)),
          userDataRevisionProvider.overrideWith((ref) => revisions.stream),
          nutritionRepositoryProvider.overrideWithValue(meals),
          nutritionTargetRepositoryProvider.overrideWithValue(targets),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await revisions.close();
        await meals.dispose();
      });
      final session = container.listen(authSessionProvider, (_, _) {});
      addTearDown(session.close);
      await container.read(authSessionProvider.future);
      final range = ReportRange(DateTime(2026, 11, 7), 7);
      final mealSubscription = container.listen(
        periodMealsProvider(range),
        (_, _) {},
      );
      final targetSubscription = container.listen(
        nutritionTargetProvider('2026-11-06'),
        (_, _) {},
      );
      addTearDown(mealSubscription.close);
      addTearDown(targetSubscription.close);
      revisions.add({});
      await Future<void>.delayed(Duration.zero);
      await container.read(periodMealsProvider(range).future);
      await container.read(nutritionTargetProvider('2026-11-06').future);
      final initialMeals = meals.rangeCalls, initialTargets = targets.readCalls;
      final first = Timestamp.fromMillisecondsSinceEpoch(1);
      revisions.add({'water_logs': first});
      await Future<void>.delayed(Duration.zero);
      expect(meals.rangeCalls, initialMeals);
      expect(targets.readCalls, initialTargets);
      revisions.add({'water_logs': first, 'meal_logs': first});
      await Future<void>.delayed(Duration.zero);
      await container.read(periodMealsProvider(range).future);
      expect(meals.rangeCalls, initialMeals + 1);
      expect(targets.readCalls, initialTargets);
      revisions.add({'meal_logs': first, 'nutrition_targets': first});
      await Future<void>.delayed(Duration.zero);
      await container.read(nutritionTargetProvider('2026-11-06').future);
      expect(targets.readCalls, initialTargets + 1);
    },
  );
}
