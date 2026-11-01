import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:healthmate/core/config/app_feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/config/ai_access_policy.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/chatbot/models/chat_models.dart';
import 'package:healthmate/features/chatbot/providers/chat_providers.dart';
import 'package:healthmate/features/food_scanner/data/food_scanner_service.dart';
import 'package:healthmate/features/food_scanner/models/ai_food_suggestion.dart';
import 'package:healthmate/features/food_scanner/providers/food_scanner_providers.dart';
import 'package:healthmate/features/nutrition/models/nutrition_validation.dart';
import 'package:healthmate/features/profile/models/profile_validation.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';
import 'package:healthmate/features/water/models/water_log.dart';

import 'support/fake_chat_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/test_app.dart';
import 'support/fake_water_repository.dart';

class _PendingWater extends FakeWaterRepository {
  final confirmation = Completer<void>();
  @override
  Future<String> add({
    required String uid,
    required WaterLogDraft draft,
  }) async {
    await confirmation.future;
    return super.add(uid: uid, draft: draft);
  }
}

UserProfile _profile(
  DateTime? birthDate, {
  String uid = 'test-uid',
  bool completed = true,
}) {
  final base = FakeHealthProfileRepository.testProfile;
  return UserProfile(
    uid: uid,
    displayName: base.displayName,
    email: base.email,
    heightCm: base.heightCm,
    birthDate: birthDate,
    healthGoal: base.healthGoal,
    targetWeightKg: base.targetWeightKg,
    onboardingCompletedAt: completed ? base.onboardingCompletedAt : null,
    createdAt: base.createdAt,
    updatedAt: base.updatedAt,
    schemaVersion: base.schemaVersion,
  );
}

void main() {
  testWidgets(
    'pending journal writes show an acknowledgement state and block duplicate quick adds',
    (tester) async {
      final repository = _PendingWater();
      final container = await pumpApp(tester, waterRepository: repository);
      container.read(appRouterProvider).go(AppRoutes.journal);
      await tester.pumpAndSettle();
      final quick = find.byKey(const ValueKey('quick-water-250'));
      await tester.ensureVisible(quick);
      await tester.pumpAndSettle();
      await tester.tap(quick);
      await tester.pump();
      expect(find.textContaining('Đang lưu thay đổi'), findsOneWidget);
      expect(tester.widget<ActionChip>(quick).onPressed, isNull);
      expect(repository.addCalls, 0);
      repository.confirmation.complete();
      await tester.pumpAndSettle();
      expect(repository.addCalls, 1);
      expect(find.textContaining('Đang chờ máy chủ xác nhận'), findsNothing);
    },
  );
  test('MVP age boundary uses the full birthday, not just birth year', () {
    final today = DateTime(2026, 10, 16);
    expect(
      ProfileValidation.birthDate(DateTime(2008, 10, 16), today: today),
      isNull,
    );
    expect(
      ProfileValidation.birthDate(DateTime(2008, 10, 17), today: today),
      isNotNull,
    );
    expect(
      ProfileValidation.birthDate(DateTime(2009, 1, 1), today: today),
      isNotNull,
    );
    expect(
      ProfileValidation.birthDate(DateTime(2027), today: today),
      isNotNull,
    );
    expect(
      ProfileValidation.birthDate(DateTime(1906, 10, 16), today: today),
      isNull,
    );
    expect(
      ProfileValidation.birthDate(DateTime(1905, 10, 16), today: today),
      isNotNull,
    );
    expect(
      aiAccessFor(
        'test-uid',
        _profile(DateTime(2008, 10, 16)),
        today: today,
      ).allowed,
      isTrue,
    );
    expect(
      aiAccessFor(
        'test-uid',
        _profile(DateTime(2008, 10, 17)),
        today: today,
      ).allowed,
      isFalse,
    );
    expect(
      aiAccessFor('test-uid', _profile(null), today: today).allowed,
      isFalse,
    );
    expect(
      aiAccessFor(
        'another-uid',
        _profile(DateTime(2000)),
        today: today,
      ).allowed,
      isFalse,
    );
    expect(
      aiAccessFor(null, _profile(DateTime(2000)), today: today).allowed,
      isFalse,
    );
    expect(
      aiAccessFor(
        'test-uid',
        _profile(DateTime(2000), completed: false),
        today: today,
      ).allowed,
      isFalse,
    );
  });

  test(
    'non-finite input never reaches body metrics, nutrition, BMI or charts',
    () {
      for (final value in ['NaN', 'Infinity', '-Infinity', '1e9999']) {
        expect(ProfileValidation.height(value), isNotNull);
        expect(ProfileValidation.weight(value), isNotNull);
        expect(ProfileValidation.parseDecimal(value), isNull);
        expect(NutritionValidation.grams(value), isNotNull);
        expect(NutritionValidation.parseDecimal(value), isNull);
      }
      expect(ProfileValidation.bmi(heightCm: double.nan, weightKg: 70), isNull);
      expect(
        ProfileValidation.bmi(heightCm: 170, weightKg: double.infinity),
        isNull,
      );
      expect(ProfileValidation.parseDecimal('65,5'), 65.5);
      expect(NutritionValidation.grams('150,5'), isNull);
    },
  );

  test('scanner parsing rejects malformed or excessive model output', () {
    const valid = {
      'dishName': 'Cơm',
      'description': 'Món cơm',
      'ingredients': ['gạo'],
      'searchTerms': ['cơm'],
    };
    for (final invalid in [
      'not json',
      ' ' * 16385,
      '[]',
      jsonEncode({...valid, 'dishName': 12}),
      jsonEncode({...valid, 'description': 'x' * 241}),
      jsonEncode({...valid, 'ingredients': List.filled(13, 'gạo')}),
      jsonEncode({...valid, 'searchTerms': []}),
      jsonEncode({
        ...valid,
        'searchTerms': ['x' * 61],
      }),
    ]) {
      expect(
        () => AiFoodSuggestion.fromJsonText(invalid),
        throwsFormatException,
      );
    }
    expect(AiFoodSuggestion.fromJsonText(jsonEncode(valid)).dishName, 'Cơm');
  });

  testWidgets(
    'legacy underage profile returns to onboarding without erasing data or crashing date picker',
    (tester) async {
      final old = _profile(DateTime(DateTime.now().year - 16, 1, 15));
      final repository = FakeHealthProfileRepository(profile: old);
      final container = await pumpApp(tester, profileRepository: repository);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        AppRoutes.onboarding,
      );
      expect(repository.currentProfile, same(old));
      // The profile remains untouched until the user explicitly submits valid data.
      expect(repository.updateProfileCalls, 0);
      expect(repository.completeOnboardingCalls, 0);
      final dateButton = find.byKey(const ValueKey('onboarding-birth-date'));
      await tester.ensureVisible(dateButton);
      await tester.tap(dateButton);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Chat and scanner gates reject a missing or underage profile before any AI request',
    (tester) async {
      final ai = FakeKnowledgeService();
      final container = await pumpApp(
        tester,
        profileRepository: FakeHealthProfileRepository(
          profile: _profile(DateTime(2010)),
        ),
        knowledgeService: ai,
        featureFlags: const AppFeatureFlags(
          chatbotEnabled: true,
          foodScannerEnabled: true,
        ),
      );
      final subscription = container.listen(chatControllerProvider, (_, _) {});
      addTearDown(subscription.close);
      await tester.pumpAndSettle();
      await container
          .read(chatControllerProvider.notifier)
          .send('', DateTime.now(), topic: KnowledgeTopic.readingLabels);
      await tester.pumpAndSettle();
      expect(ai.topics, isEmpty);
      expect(container.read(chatControllerProvider).error, contains('18 tuổi'));
      expect(container.read(aiAccessProvider).allowed, isFalse);
      await expectLater(
        Future.sync(
          () => container
              .read(foodScannerServiceProvider)
              .analyze(bytes: Uint8List.fromList([1]), mimeType: 'image/png'),
        ),
        throwsA(
          isA<FoodScannerFailure>().having(
            (failure) => failure.message,
            'message',
            contains('18 tuổi'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
