import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/features/auth/models/auth_user.dart';
import 'package:healthmate/features/journal/models/daily_log_failure.dart';
import 'package:healthmate/features/water/models/water_log.dart';
import 'package:healthmate/features/water/providers/water_providers.dart';
import 'package:healthmate/features/water/presentation/water_log_section.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_health_profile_repository.dart';
import 'support/fake_water_repository.dart';
import 'support/load_icon_font.dart';
import 'support/test_app.dart';
import 'nutrition_targets_test.dart' show profileForUid;

class _ControlledWater extends FakeWaterRepository {
  Completer<void>? pendingAdd, pendingUndo;
  DailyLogFailure? addFailure, undoFailure;
  int attempts = 0;
  final undoOwners = <String>[];

  @override
  Future<String> add({
    required String uid,
    required WaterLogDraft draft,
  }) async {
    attempts++;
    await pendingAdd?.future;
    if (addFailure != null) throw addFailure!;
    return super.add(uid: uid, draft: draft);
  }

  @override
  Future<void> undoAdd({
    required String uid,
    required String logId,
    required WaterLogDraft draft,
  }) async {
    undoOwners.add(uid);
    await pendingUndo?.future;
    if (undoFailure != null) throw undoFailure!;
    await super.undoAdd(uid: uid, logId: logId, draft: draft);
  }
}

Future<void> _tap(WidgetTester tester, String key, {bool settle = true}) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.tap(target);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  final today = DateTime(2026, 11, 10, 9, 30);
  setUpAll(() async {
    await loadIconFont();
    final font = FontLoader('Public Sans');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(
        rootBundle.load('assets/fonts/public_sans/PublicSans-$weight.ttf'),
      );
    }
    await font.load();
  });

  testWidgets('failed or pending water reads never claim a measured zero', (
    tester,
  ) async {
    for (final state in <AsyncValue<List<WaterLog>>>[
      const AsyncLoading(),
      AsyncError(DailyLogFailure.fromCode('unavailable'), StackTrace.current),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: WaterLogSection(
                state: state,
                action: const AsyncData(null),
                onAdd: () {},
                onQuickAdd: (_) {},
                onEdit: (_) {},
                onDelete: (_) {},
                onRetry: () {},
                onDismissError: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('0 ml'), findsNothing);
      expect(find.byKey(const ValueKey('quick-water-250')), findsNothing);
      expect(
        find.text(state.isLoading ? 'Đang tải…' : 'Chưa tải được lượng nước'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('empty day shows quick amounts and an honest empty state', (
    tester,
  ) async {
    await pumpApp(tester, dashboardNow: today);
    await _tap(tester, 'nav-journal');
    await tester.ensureVisible(find.byKey(const ValueKey('quick-water-250')));
    await tester.pumpAndSettle();
    expect(
      find.text('Chưa có lần uống nước nào trong ngày này.'),
      findsOneWidget,
    );
    for (final amount in [250, 350, 500]) {
      expect(
        tester
            .widget<ActionChip>(find.byKey(ValueKey('quick-water-$amount')))
            .onPressed,
        isNotNull,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'home undo removes only the acknowledged addition and refreshes both tabs',
    (tester) async {
      final water = FakeWaterRepository();
      await pumpApp(tester, dashboardNow: today, waterRepository: water);
      await _tap(tester, 'dashboard-quick-water');
      expect(water.logs.single.amountMl, 250);
      expect(find.text('Đã ghi nhanh 250 ml nước.'), findsOneWidget);
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(water.undoCalls, 1);
      expect(water.logs, isEmpty);
      expect(find.text('Đã hoàn tác lần ghi nước.'), findsOneWidget);
      await _tap(tester, 'nav-journal');
      expect(
        find.text('Chưa có lần uống nước nào trong ngày này.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'journal quick add uses the selected past day and undo never touches another entry',
    (tester) async {
      final water = FakeWaterRepository();
      await pumpApp(tester, dashboardNow: today, waterRepository: water);
      await _tap(tester, 'nav-journal');
      await _tap(tester, 'journal-previous-day');
      await _tap(tester, 'quick-water-350');
      final first = water.logs.single;
      expect(first.dateKey, '2026-11-09');
      expect(first.amountMl, 350);
      await _tap(tester, 'quick-water-500');
      expect(water.logs.length, 2);
      expect(find.text('Đã ghi nhanh 500 ml nước.'), findsOneWidget);
      expect(find.text('Đã ghi nhanh 350 ml nước.'), findsNothing);
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(water.logs.single.id, first.id);
      expect(totalWaterMl(water.logs), 350);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pending quick addition blocks repeats and exposes no undo before confirmation',
    (tester) async {
      final water = _ControlledWater()..pendingAdd = Completer<void>();
      await pumpApp(tester, dashboardNow: today, waterRepository: water);
      await _tap(tester, 'nav-journal');
      await _tap(tester, 'quick-water-250', settle: false);
      expect(water.attempts, 1);
      expect(find.text('Hoàn tác'), findsNothing);
      expect(
        tester
            .widget<ActionChip>(find.byKey(const ValueKey('quick-water-500')))
            .onPressed,
        isNull,
      );
      water.pendingAdd!.complete();
      await tester.pumpAndSettle();
      expect(water.logs.length, 1);
      expect(find.text('Hoàn tác'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed addition never displays a success receipt or undo action',
    (tester) async {
      final water = _ControlledWater()
        ..addFailure = DailyLogFailure.fromCode('unavailable');
      await pumpApp(tester, dashboardNow: today, waterRepository: water);
      await _tap(tester, 'dashboard-quick-water');
      expect(water.logs, isEmpty);
      expect(find.text('Hoàn tác'), findsNothing);
      expect(find.text('Đã ghi nhanh 250 ml nước.'), findsNothing);
      expect(find.text('Chưa thể ghi nước. Hãy thử lại.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'undo failure offers retry and waits for acknowledgement before claiming success',
    (tester) async {
      final water = _ControlledWater();
      await pumpApp(tester, dashboardNow: today, waterRepository: water);
      await _tap(tester, 'dashboard-quick-water');
      water.undoFailure = DailyLogFailure.fromCode('unavailable');
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(water.logs.length, 1);
      expect(find.text('Đã hoàn tác lần ghi nước.'), findsNothing);
      water.undoFailure = null;
      water.pendingUndo = Completer<void>();
      await tester.tap(find.text('Thử lại'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(water.undoOwners.length, 2);
      expect(water.logs.length, 1);
      expect(find.text('Đã hoàn tác lần ghi nước.'), findsNothing);
      water.pendingUndo!.complete();
      await tester.pumpAndSettle();
      expect(water.logs, isEmpty);
      expect(find.text('Đã hoàn tác lần ghi nước.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'undo preserves an entry edited elsewhere even when edited back to the same values',
    (tester) async {
      final water = FakeWaterRepository();
      await pumpApp(tester, dashboardNow: today, waterRepository: water);
      await _tap(tester, 'dashboard-quick-water');
      final log = water.logs.single;
      await water.update(uid: 'test-uid', logId: log.id, draft: log.toDraft());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(water.logs.single.id, log.id);
      expect(
        find.textContaining('Lần ghi này đã được chỉnh sửa'),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsNothing);
      expect(find.text('Đã hoàn tác lần ghi nước.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'already deleted entry can be undone repeatedly without deleting anything else',
    (tester) async {
      final water = FakeWaterRepository();
      final container = await pumpApp(
        tester,
        dashboardNow: today,
        waterRepository: water,
      );
      final controller = container.read(waterControllerProvider.notifier);
      final receipt = (await controller.addWithReceipt(
        WaterLogDraft(amountMl: 250, consumedAt: today),
      ))!;
      await water.delete(uid: receipt.uid, logId: receipt.logId);
      await controller.add(WaterLogDraft(amountMl: 500, consumedAt: today));
      expect(await controller.undoAdd(receipt), isTrue);
      expect(await controller.undoAdd(receipt), isTrue);
      expect(water.logs.single.amountMl, 500);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'switching accounts dismisses the undo and invalidates receipts, including after signing back in',
    (tester) async {
      final water = _ControlledWater();
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      final profile = FakeHealthProfileRepository(
        profile: FakeHealthProfileRepository.testProfile,
      );
      final container = await pumpApp(
        tester,
        dashboardNow: today,
        waterRepository: water,
        repository: auth,
        profileRepository: profile,
      );
      final controller = container.read(waterControllerProvider.notifier);
      final receipt = (await controller.addWithReceipt(
        WaterLogDraft(amountMl: 500, consumedAt: today),
      ))!;
      await tester.pumpAndSettle();
      await _tap(tester, 'dashboard-quick-water');
      auth.emitUser(
        const AuthUser(
          uid: 'second-uid',
          email: 'second@example.test',
          emailVerified: true,
        ),
      );
      profile.emitProfile(profileForUid('second-uid'));
      await tester.pumpAndSettle();
      expect(find.text('Hoàn tác'), findsNothing);
      expect(
        await container.read(waterControllerProvider.notifier).undoAdd(receipt),
        isFalse,
      );
      auth.emitUser(FakeAuthRepository.testUser);
      profile.emitProfile(FakeHealthProfileRepository.testProfile);
      await tester.pumpAndSettle();
      expect(
        await container.read(waterControllerProvider.notifier).undoAdd(receipt),
        isFalse,
      );
      expect(water.undoOwners, isEmpty);
      expect(water.logs.length, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late quick add after logout does not expose a receipt in the new session',
    (tester) async {
      final water = _ControlledWater()..pendingAdd = Completer<void>();
      final auth = FakeAuthRepository(user: FakeAuthRepository.testUser);
      await pumpApp(
        tester,
        dashboardNow: today,
        waterRepository: water,
        repository: auth,
      );
      await _tap(tester, 'dashboard-quick-water', settle: false);
      auth.emitUser(null);
      await tester.pumpAndSettle();
      water.pendingAdd!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Hoàn tác'), findsNothing);
      expect(find.text('Đã ghi nhanh 250 ml nước.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0]) {
      testWidgets(
        'water presets, custom volume and date fit $mode width=$width',
        (tester) async {
          final water = FakeWaterRepository();
          final captureKey = GlobalKey();
          await pumpApp(
            tester,
            dashboardNow: today,
            waterRepository: water,
            initialThemeMode: mode,
            size: Size(width, 844),
            textScale: width == 320 ? 2 : 1,
            captureKey: captureKey,
          );
          await _tap(tester, 'nav-journal');
          await _tap(tester, 'add-water');
          expect(
            find.byKey(const ValueKey('water-entry-date')),
            findsOneWidget,
          );
          expect(find.text('Ngày ghi: 10/11/2026'), findsOneWidget);
          await _tap(tester, 'water-preset-750');
          final input = find.byKey(const ValueKey('water-amount'));
          expect(tester.widget<TextFormField>(input).controller!.text, '750');
          expect(
            tester
                .widget<ChoiceChip>(
                  find.byKey(const ValueKey('water-preset-750')),
                )
                .selected,
            isTrue,
          );
          await tester.enterText(input, '420');
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<ChoiceChip>(
                  find.byKey(const ValueKey('water-preset-750')),
                )
                .selected,
            isFalse,
          );
          if (width == 390) {
            await tester.runAsync(() async {
              final boundary =
                  captureKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final shot = await boundary.toImage(pixelRatio: 2);
              final bytes = await shot.toByteData(
                format: ui.ImageByteFormat.png,
              );
              shot.dispose();
              final target = File(
                'build/water-quick-entry-20261116/form-${mode.name}.png',
              );
              await target.parent.create(recursive: true);
              await target.writeAsBytes(bytes!.buffer.asUint8List());
            });
          }
          await _tap(tester, 'save-water');
          expect(water.logs.single.amountMl, 420);
          expect(water.logs.single.dateKey, '2026-11-10');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
