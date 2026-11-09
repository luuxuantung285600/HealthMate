import 'package:healthmate/features/nutrition/data/unified_food_search_service.dart';
import 'fake_food_search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/reports/providers/report_providers.dart';
import 'package:healthmate/features/reports/data/day_review_repository.dart';
import 'fake_day_review_repository.dart';
import 'package:healthmate/app.dart';
import 'package:healthmate/features/premium/providers/play_billing_providers.dart';
import 'package:healthmate/features/wellness/data/wellness_device.dart';
import 'package:healthmate/features/wellness/providers/wellness_providers.dart';
import 'package:healthmate/features/wellness/models/wellness_models.dart';
import 'package:healthmate/features/food_library/providers/favorite_food_providers.dart';
import 'fake_favorite_food_repository.dart';
import 'fake_food_library_repository.dart';
import 'package:healthmate/features/food_library/providers/food_library_providers.dart';
import 'package:healthmate/features/nutrition_targets/providers/nutrition_target_providers.dart';
import 'package:healthmate/features/nutrition_targets/data/nutrition_target_repository.dart';
import 'fake_nutrition_target_repository.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';

import 'package:healthmate/features/auth/providers/auth_providers.dart';
import 'package:healthmate/features/chatbot/providers/chat_providers.dart';
import 'package:healthmate/features/chatbot/providers/assistant_providers.dart';
import 'package:healthmate/features/chatbot/data/chat_assistant.dart';
import 'package:healthmate/features/food_scanner/data/food_image_picker.dart';
import 'package:healthmate/features/food_scanner/data/food_scanner_service.dart';
import 'package:healthmate/features/food_scanner/providers/food_scanner_providers.dart';
import 'package:healthmate/features/activity/providers/activity_providers.dart';
import 'package:healthmate/features/dashboard/providers/dashboard_providers.dart';
import 'package:healthmate/features/goals/providers/goals_providers.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/profile/providers/profile_providers.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';
import 'package:healthmate/shared/providers/theme_mode_provider.dart';
import 'package:healthmate/shared/providers/local_clock_provider.dart';
import 'package:healthmate/features/premium/providers/premium_providers.dart';
import 'package:healthmate/features/premium/models/premium_models.dart';

import 'fake_account_data_repository.dart';
import 'fake_energy_repository.dart';
import 'package:healthmate/features/wellness/data/energy_repository.dart';
import 'package:healthmate/features/wellness/providers/energy_providers.dart';
import 'fake_chat_repository.dart';
import 'fake_activity_repository.dart';
import 'fake_goals_repository.dart';
import 'fake_auth_repository.dart';
import 'fake_health_profile_repository.dart';
import 'fake_nutrition_repository.dart';
import 'fake_water_repository.dart';
import 'fake_theme_preference_store.dart';
import 'fake_private_local_data.dart';
import 'fake_food_camera.dart';
import 'package:healthmate/features/food_scanner/presentation/barcode_scanner_screen.dart';
import 'package:healthmate/features/food_scanner/models/barcode_product_models.dart';
import 'package:healthmate/features/food_scanner/data/food_camera_service.dart';
import 'package:healthmate/core/data/private_local_data.dart';
import 'package:healthmate/features/meal_drafts/data/meal_draft_store.dart';

/// Reports follow Figma's title/export header; the Home avatar opens Profile.
Future<void> openProfileFromShell(WidgetTester tester) async {
  if (find.byKey(const ValueKey('nav-profile')).evaluate().isEmpty) {
    await tester.tap(find.byKey(const ValueKey('nav-dashboard')));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.byKey(const ValueKey('nav-profile')));
  await tester.tap(find.byKey(const ValueKey('nav-profile')));
  await tester.pumpAndSettle();
}

Future<void> openWellnessFromShell(WidgetTester tester) async {
  await openProfileFromShell(tester);
  final link = find.byKey(const ValueKey('open-wellness'));
  await tester.ensureVisible(link);
  await tester.pumpAndSettle();
  await tester.tap(link);
  await tester.pumpAndSettle();
}

Future<void> openMealTools(WidgetTester tester) async {
  final toggle = find.byKey(const ValueKey('meal-more-tools'));
  if (toggle.evaluate().isEmpty) return;
  final icon = tester.widget<IconButton>(toggle).icon as Icon;
  if (icon.icon == Icons.more_horiz) {
    await tester.tap(find.byKey(const ValueKey('meal-more-tools')));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> openSelectedMealItems(WidgetTester tester) async {
  if (find.byTooltip('Sửa khẩu phần').evaluate().isNotEmpty) return;
  final selected = find.byKey(const ValueKey('selected-meal-items'));
  await tester.ensureVisible(selected);
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .descendant(of: selected, matching: find.textContaining('Đã chọn'))
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> selectHomeDate(
  WidgetTester tester,
  DateTime day, {
  bool settle = true,
}) async {
  await tester.tap(find.byKey(const ValueKey('today-date-picker')));
  await tester.pump(const Duration(milliseconds: 300));
  Navigator.of(tester.element(find.byType(DatePickerDialog))).pop(day);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> openActivityDetails(WidgetTester tester) async {
  final section = find.byKey(const ValueKey('journal-activity-details'));
  if (find.byKey(const ValueKey('add-activity')).evaluate().isNotEmpty) return;
  await tester.ensureVisible(section);
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: section, matching: find.text('Vận động')).first,
  );
  await tester.pumpAndSettle();
}

Finder journalTotals(String text) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      w.key == const ValueKey('nutrition-daily-totals') &&
      (w.semanticsLabel ?? w.data) == text,
);

Future<void> openJournalNutritionDetails(WidgetTester tester) async {
  await tester.ensureVisible(
    find.byKey(const ValueKey('journal-nutrition-details')),
  );
  await tester.tap(find.byKey(const ValueKey('journal-nutrition-details')));
  await tester.pumpAndSettle();
}

Future<void> openDashboardDetails(
  WidgetTester tester, {
  bool settle = true,
}) async {
  final disclosure = find.byKey(const ValueKey('dashboard-details'));
  if (disclosure.evaluate().isEmpty ||
      find.byKey(const ValueKey('dashboard-goals')).evaluate().isNotEmpty) {
    return;
  }
  await tester.ensureVisible(disclosure);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.tap(
    find.descendant(of: disclosure, matching: find.byType(ExpansionTile)),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

class UnsupportedTestWellnessDevice extends WellnessDevice {
  @override
  bool get supported => false;
}

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  FakeAuthRepository? repository,
  FakeChatRepository? chatRepository,
  FakeKnowledgeService? knowledgeService,
  Future<void> Function(PremiumAiFeature)? premiumQuota,
  ChatAssistant? chatAssistant,
  String chatApiEndpoint = '',
  FoodImagePicker? foodImagePicker,
  FoodCameraService? foodCameraService,
  Future<BarcodeMealSelection?> Function(BuildContext)? barcodeScanner,
  FoodScannerService? foodScannerService,
  FakeHealthProfileRepository? profileRepository,
  FakeNutritionRepository? nutritionRepository,
  UnifiedFoodSearchService? foodSearchService,
  FakeWaterRepository? waterRepository,
  FakeActivityRepository? activityRepository,
  FakeGoalsRepository? goalsRepository,
  FakeAccountDataRepository? accountDataRepository,
  FakeThemePreferenceStore? themePreferenceStore,
  ThemeMode initialThemeMode = ThemeMode.system,
  DateTime? dashboardNow,
  DateTime Function()? dashboardNowSource,
  DateTime Function()? goalsNow,
  bool settle = true,
  AppFeatureFlags featureFlags = const AppFeatureFlags(),
  GlobalKey? captureKey,
  NutritionTargetRepository? targetRepository,
  DayReviewRepository? dayReviewRepository,
  FakeFavoriteFoodRepository? favoriteRepository,
  FakeFoodLibraryRepository? libraryRepository,
  PrivateLocalData? privateLocalData,
  DateTime Function()? authNow,
  EnergyRepository? energyRepository,
  List<StepDay> stepDays = const [],
  List<SleepLog> sleepLogs = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final auth =
      repository ?? FakeAuthRepository(user: FakeAuthRepository.testUser);
  final healthProfile =
      profileRepository ??
      FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
      );
  final nutrition = nutritionRepository ?? FakeNutritionRepository();
  final water = waterRepository ?? FakeWaterRepository();
  final activity = activityRepository ?? FakeActivityRepository();
  final goals = goalsRepository ?? FakeGoalsRepository();
  final accountData = accountDataRepository ?? FakeAccountDataRepository();
  final themeStore = themePreferenceStore ?? FakeThemePreferenceStore();
  final favorites = favoriteRepository ?? FakeFavoriteFoodRepository();
  final library = libraryRepository ?? FakeFoodLibraryRepository();
  final container = ProviderContainer(
    overrides: [
      playBillingSupportedProvider.overrideWithValue(false),
      if (premiumQuota != null)
        premiumQuotaProvider.overrideWithValue(premiumQuota),
      stepHistoryProvider.overrideWith((ref) => Stream.value(stepDays)),
      sleepHistoryProvider.overrideWith((ref) => Stream.value(sleepLogs)),
      sleepStartProvider.overrideWith((ref) => Stream.value(null)),
      energyRepositoryProvider.overrideWithValue(
        energyRepository ?? FakeEnergyRepository(),
      ),
      wellnessDeviceProvider.overrideWithValue(UnsupportedTestWellnessDevice()),
      if (authNow != null) authClockProvider.overrideWithValue(authNow),
      if (barcodeScanner != null)
        barcodeMealScannerProvider.overrideWithValue(barcodeScanner),
      foodCameraServiceProvider.overrideWithValue(
        foodCameraService ??
            FoodCameraService(createSession: FakeFoodCamera.new),
      ),
      unifiedFoodSearchProvider.overrideWithValue(
        foodSearchService ?? FakeFoodSearchService(),
      ),
      privateLocalDataProvider.overrideWithValue(
        privateLocalData ?? FakePrivateLocalData(available: false),
      ),
      dayReviewRepositoryProvider.overrideWithValue(
        dayReviewRepository ?? FakeDayReviewRepository(),
      ),
      foodLibraryRepositoryProvider.overrideWithValue(library),
      favoriteFoodRepositoryProvider.overrideWithValue(favorites),
      localClockProvider.overrideWith(
        (ref) => ref.watch(currentLocalTimeProvider)(),
      ),
      nutritionTargetRepositoryProvider.overrideWithValue(
        targetRepository ?? FakeNutritionTargetRepository(),
      ),
      appFeatureFlagsProvider.overrideWithValue(featureFlags),
      chatApiEndpointProvider.overrideWithValue(chatApiEndpoint),
      if (chatAssistant != null)
        chatAssistantProvider.overrideWithValue(chatAssistant),
      authRepositoryProvider.overrideWithValue(auth),
      if (foodImagePicker != null)
        foodImagePickerProvider.overrideWithValue(foodImagePicker),
      if (foodScannerService != null)
        foodScannerServiceProvider.overrideWithValue(foodScannerService),
      chatRepositoryProvider.overrideWithValue(
        chatRepository ?? FakeChatRepository(),
      ),
      knowledgeServiceProvider.overrideWithValue(
        knowledgeService ?? FakeKnowledgeService(),
      ),
      healthProfileRepositoryProvider.overrideWithValue(healthProfile),
      nutritionRepositoryProvider.overrideWithValue(nutrition),
      waterRepositoryProvider.overrideWithValue(water),
      activityRepositoryProvider.overrideWithValue(activity),
      goalsRepositoryProvider.overrideWithValue(goals),
      if (goalsNow != null)
        goalsClockProvider.overrideWith((ref) => goalsNow())
      else
        goalsClockProvider.overrideWithValue(dashboardNow ?? DateTime.now()),
      accountDataRepositoryProvider.overrideWithValue(accountData),
      themePreferenceStoreProvider.overrideWithValue(themeStore),
      initialThemeModeProvider.overrideWithValue(initialThemeMode),
      currentLocalTimeProvider.overrideWithValue(
        dashboardNowSource ?? () => dashboardNow ?? DateTime.now(),
      ),
      if (dashboardNowSource != null)
        dashboardClockProvider.overrideWith((ref) => dashboardNowSource())
      else
        dashboardClockProvider.overrideWithValue(
          dashboardNow ?? DateTime.now(),
        ),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await favorites.dispose();
    await library.dispose();
    await auth.dispose();
    await healthProfile.dispose();
    await nutrition.dispose();
    await water.dispose();
    await activity.dispose();
    await goals.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: captureKey == null
          ? const HealthMateApp()
          : RepaintBoundary(key: captureKey, child: const HealthMateApp()),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return container;
}
