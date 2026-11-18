import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/profile/data/profile_image_picker.dart';
import 'package:healthmate/features/profile/models/profile_appearance.dart';
import 'package:healthmate/features/profile/models/profile_failure.dart';
import 'package:healthmate/features/profile/models/user_profile.dart';
import 'package:healthmate/features/profile/presentation/profile_identity_dialog.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/load_icon_font.dart';
import 'support/test_app.dart';

late Uint8List sourcePng;
late ProfileImage avatar, cover, background;

class Picker implements ProfileImagePicker {
  int calls = 0;
  bool cancel = false;
  ProfileFailure? failure;
  Completer<ProfileImage?>? pending;
  @override
  Future<ProfileImage?> pick(ProfileImageSlot slot) async {
    calls++;
    if (pending != null) return pending!.future;
    if (failure != null) throw failure!;
    if (cancel) return null;
    return switch (slot) {
      ProfileImageSlot.avatar => avatar,
      ProfileImageSlot.cover => cover,
      ProfileImageSlot.background => background,
    };
  }
}

Future<void> tapVisible(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<ProviderContainer> openEditor(
  WidgetTester tester, {
  required FakeHealthProfileRepository repo,
  required Picker picker,
  FakeAuthRepository? auth,
  ThemeMode mode = ThemeMode.dark,
  double scale = 1,
  GlobalKey? captureKey,
}) async {
  final container = await pumpApp(
    tester,
    profileRepository: repo,
    profileImagePicker: picker,
    repository: auth,
    initialThemeMode: mode,
    size: Size(scale == 2 ? 320 : 390, 844),
    textScale: scale,
    captureKey: captureKey,
  );
  container.read(appRouterProvider).go(AppRoutes.profile);
  await tester.pumpAndSettle();
  await tapVisible(tester, 'edit-profile-identity');
  return container;
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/profile-personalization-20261117/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadIconFont();
    final font = FontLoader('Public Sans');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(
        rootBundle.load('assets/fonts/public_sans/PublicSans-$weight.ttf'),
      );
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 500, 300),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(500, 300),
          [const Color(0xFFBC7770), const Color(0xFF314051)],
        ),
    );
    canvas.drawCircle(
      const Offset(385, 80),
      38,
      Paint()..color = const Color(0xFFF4D3A0),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 300)
        ..lineTo(180, 100)
        ..lineTo(340, 300)
        ..close(),
      Paint()..color = const Color(0xFF34343C),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(500, 300);
    sourcePng = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    image.dispose();
    picture.dispose();
    avatar = await prepareProfileImage(sourcePng, ProfileImageSlot.avatar);
    cover = await prepareProfileImage(sourcePng, ProfileImageSlot.cover);
    background = await prepareProfileImage(
      sourcePng,
      ProfileImageSlot.background,
    );
  });

  test(
    'picture preparation center-crops, bounds bytes and drops original encoding',
    () {
      for (final entry in [
        (avatar, ProfileImageSlot.avatar),
        (cover, ProfileImageSlot.cover),
        (background, ProfileImageSlot.background),
      ]) {
        expect(entry.$1.bytes.length, lessThanOrEqualTo(ProfileImage.maxBytes));
        final header = ByteData.sublistView(entry.$1.bytes);
        expect(
          header.getUint32(16) / header.getUint32(20),
          closeTo(entry.$2.width / entry.$2.height, .05),
        );
        expect(identical(sourcePng, entry.$1.bytes), isFalse);
        expect(
          ProfileImage.tryDecode(entry.$1.encoded)?.encoded,
          entry.$1.encoded,
        );
      }
      expect(() => avatar.bytes[0] = 0, throwsUnsupportedError);
    },
  );

  test(
    'invalid and oversized images fail without a stored replacement',
    () async {
      for (final input in [
        Uint8List(0),
        Uint8List.fromList([1, 2, 3]),
        Uint8List(8 * 1024 * 1024 + 1),
      ]) {
        await expectLater(
          prepareProfileImage(input, ProfileImageSlot.cover),
          throwsA(isA<ProfileFailure>()),
        );
      }
      for (final value in [
        'https://example.com/image.png',
        'not base64',
        42,
        'A' * 90000,
      ]) {
        expect(ProfileImage.tryDecode(value), isNull);
      }
      final huge = Uint8List.fromList(avatar.bytes);
      ByteData.sublistView(huge).setUint32(16, 9000);
      expect(() => ProfileImage.fromPng(huge), throwsFormatException);
      expect(
        ProfileAppearance.fromMap(null).sameAs(const ProfileAppearance()),
        isTrue,
      );
      expect(
        ProfileAppearance.fromMap({
          'avatar': 'bad',
          'cover': cover.encoded,
        }).cover?.encoded,
        cover.encoded,
      );
    },
  );

  testWidgets(
    'save waits for acknowledgement, prevents duplicates and preserves health fields',
    (tester) async {
      final repo = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
      );
      final before = repo.currentProfile!;
      final picker = Picker();
      final container = await openEditor(tester, repo: repo, picker: picker);
      await tester.enterText(
        find.byKey(const ValueKey('identity-name')),
        'Nguyễn An',
      );
      for (final slot in ProfileImageSlot.values) {
        await tapVisible(tester, 'identity-pick-${slot.name}');
      }
      expect(repo.updateIdentityCalls, 0);
      expect(repo.currentProfile!.appearance.avatar, isNull);
      repo.pending = Completer<void>();
      await tester.tap(find.byKey(const ValueKey('save-profile-identity')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('save-profile-identity')),
            )
            .onPressed,
        isNull,
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('save-profile-identity'))),
      );
      await tester.pump();
      expect(repo.updateIdentityCalls, 1);
      expect(find.byType(ProfileIdentityDialog), findsOneWidget);
      repo.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ProfileIdentityDialog), findsNothing);
      expect(repo.currentProfile!.displayName, 'Nguyễn An');
      expect(repo.currentProfile!.appearance.cover?.encoded, cover.encoded);
      expect(repo.currentProfile!.heightCm, before.heightCm);
      expect(repo.currentProfile!.healthGoal, before.healthGoal);
      expect(repo.currentProfile!.birthDate, before.birthDate);
      expect(repo.currentProfile!.targetWeightKg, before.targetWeightKg);
      expect(find.byKey(const ValueKey('profile-cover-image')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-background-image')),
        findsOneWidget,
      );
      container.read(appRouterProvider).go(AppRoutes.dashboard);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('profile-avatar-image')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancel, invalid name and picker failure preserve the original profile',
    (tester) async {
      final repo = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
      );
      final picker = Picker()..cancel = true;
      await openEditor(tester, repo: repo, picker: picker);
      await tapVisible(tester, 'identity-pick-avatar');
      expect(
        find.byKey(const ValueKey('identity-preview-avatar')),
        findsNothing,
      );
      picker.cancel = false;
      picker.failure = const ProfileFailure('Không mở được thư viện');
      await tapVisible(tester, 'identity-pick-cover');
      expect(find.text('Không mở được thư viện'), findsOneWidget);
      tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(ProfileIdentityDialog),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .jumpTo(0);
      await tester.enterText(find.byKey(const ValueKey('identity-name')), 'A');
      await tester.tap(find.byKey(const ValueKey('save-profile-identity')));
      await tester.pumpAndSettle();
      expect(repo.updateIdentityCalls, 0);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileIdentityDialog), findsNothing);
      expect(
        repo.currentProfile!.displayName,
        FakeHealthProfileRepository.testProfile.displayName,
      );
    },
  );

  testWidgets(
    'failed save keeps images for retry and allows removing each photo',
    (tester) async {
      final repo = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
      );
      await openEditor(tester, repo: repo, picker: Picker());
      await tapVisible(tester, 'identity-pick-cover');
      repo.failure = const ProfileFailure('Mạng lỗi');
      await tester.tap(find.byKey(const ValueKey('save-profile-identity')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileIdentityDialog), findsOneWidget);
      expect(
        find.byKey(const ValueKey('identity-preview-cover')),
        findsOneWidget,
      );
      expect(repo.currentProfile!.appearance.cover, isNull);
      repo.failure = null;
      await tester.tap(find.byKey(const ValueKey('save-profile-identity')));
      await tester.pumpAndSettle();
      expect(repo.updateIdentityCalls, 2);
      await tapVisible(tester, 'edit-profile-identity');
      await tapVisible(tester, 'identity-remove-cover');
      await tester.tap(find.byKey(const ValueKey('save-profile-identity')));
      await tester.pumpAndSettle();
      expect(repo.currentProfile!.appearance.cover, isNull);
      expect(find.byKey(const ValueKey('profile-cover-image')), findsNothing);
    },
  );

  testWidgets(
    'account change discards picker result and closes the old account draft',
    (tester) async {
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final repo = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
      );
      final picker = Picker()..pending = Completer<ProfileImage?>();
      await openEditor(tester, repo: repo, picker: picker, auth: auth);
      await tester.ensureVisible(
        find.byKey(const ValueKey('identity-pick-avatar')),
      );
      await tester.tap(find.byKey(const ValueKey('identity-pick-avatar')));
      await tester.pump();
      final old = FakeHealthProfileRepository.testProfile;
      repo.emitProfile(
        UserProfile(
          uid: 'other',
          displayName: 'Tài khoản khác',
          email: 'other@example.com',
          heightCm: old.heightCm,
          birthDate: old.birthDate,
          healthGoal: old.healthGoal,
          targetWeightKg: old.targetWeightKg,
          onboardingCompletedAt: old.onboardingCompletedAt,
          createdAt: old.createdAt,
          updatedAt: old.updatedAt,
          schemaVersion: old.schemaVersion,
        ),
      );
      auth.emitUser(
        const AuthUser(
          uid: 'other',
          email: 'other@example.com',
          emailVerified: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      picker.pending!.complete(avatar);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileIdentityDialog), findsNothing);
      expect(find.byKey(const ValueKey('profile-avatar-image')), findsNothing);
      expect(repo.updateIdentityCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('identity editor and profile fit ${mode.name} text x$scale', (
        tester,
      ) async {
        final repo = FakeHealthProfileRepository(
          profile: FakeHealthProfileRepository.testProfile,
        );
        final key = GlobalKey();
        await openEditor(
          tester,
          repo: repo,
          picker: Picker(),
          mode: mode,
          scale: scale,
          captureKey: key,
        );
        for (final slot in ProfileImageSlot.values) {
          await tapVisible(tester, 'identity-pick-${slot.name}');
        }
        if (scale == 1) {
          final scrollable = find
              .descendant(
                of: find.byType(ProfileIdentityDialog),
                matching: find.byType(Scrollable),
              )
              .first;
          tester.state<ScrollableState>(scrollable).position.jumpTo(0);
          await tester.pumpAndSettle();
          await capture(tester, key, 'editor-${mode.name}');
        }
        await tester.tap(find.byKey(const ValueKey('save-profile-identity')));
        await tester.pumpAndSettle();
        if (scale == 1) await capture(tester, key, 'profile-${mode.name}');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
