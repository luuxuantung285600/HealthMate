import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/router/app_router.dart';
import 'package:healthmate/core/router/app_routes.dart';
import 'package:healthmate/core/theme/app_feature_visuals.dart';
import 'package:healthmate/core/theme/app_icons.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/core/widgets/feature_icon_badge.dart';
import 'package:healthmate/features/nutrition/presentation/meal_form_dialog.dart';

import 'support/load_icon_font.dart';
import 'support/test_app.dart';

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final picture = await boundary.toImage(pixelRatio: 2);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/icon-system/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
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
  });

  test(
    'feature icons retain at least 3:1 contrast on tinted light and dark surfaces',
    () {
      for (final brightness in Brightness.values) {
        final canvas = brightness == Brightness.dark
            ? Colors.black
            : Colors.white;
        for (final feature in AppFeatureVisual.values) {
          final background = Color.alphaBlend(
            feature.background(brightness),
            canvas,
          );
          final a = feature.foreground(brightness).computeLuminance();
          final b = background.computeLuminance();
          final ratio = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
          expect(
            ratio,
            greaterThanOrEqualTo(3),
            reason: '${feature.name} $brightness',
          );
        }
      }
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'navigation preserves selection, labels and actions ${mode.name} x$scale',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            final key = GlobalKey();
            final container = await pumpApp(
              tester,
              size: Size(scale == 2 ? 320 : 390, 844),
              textScale: scale,
              initialThemeMode: mode,
              dashboardNow: DateTime(2026, 11, 10, 12),
              captureKey: key,
            );
            for (final tab in [
              (
                'nav-journal',
                'Nhật ký',
                AppRoutes.journal,
                AppIcons.journalSelected,
              ),
              (
                'nav-workouts',
                'Tập luyện',
                AppRoutes.workouts,
                AppIcons.workoutSelected,
              ),
              (
                'nav-progress',
                'Tiến độ',
                AppRoutes.progress,
                AppIcons.progressSelected,
              ),
              (
                'nav-dashboard',
                'Trang chủ',
                AppRoutes.dashboard,
                AppIcons.homeSelected,
              ),
            ]) {
              final button = find.byKey(ValueKey(tab.$1));
              expect(
                tester.getSize(button).shortestSide,
                greaterThanOrEqualTo(48),
              );
              await tester.tap(button);
              await tester.pumpAndSettle();
              expect(
                container
                    .read(appRouterProvider)
                    .routeInformationProvider
                    .value
                    .uri
                    .path,
                tab.$3,
              );
              expect(
                tester.getSemantics(button).flagsCollection.isSelected,
                ui.Tristate.isTrue,
              );
              final icon = tester.widget<Icon>(
                find.descendant(of: button, matching: find.byType(Icon)),
              );
              expect(icon.icon, tab.$4);
              final indicator = tester.widget<AnimatedContainer>(
                find.byKey(ValueKey('navigation-indicator-${tab.$2}')),
              );
              expect(
                (indicator.decoration! as BoxDecoration).color!.a,
                greaterThan(0),
              );
              expect(tester.takeException(), isNull);
            }
            if (scale == 1) {
              await capture(tester, key, 'home-${mode.name}');
              await tester.tap(find.byKey(const ValueKey('profile-avatar')));
              await tester.pumpAndSettle();
              await capture(tester, key, 'profile-${mode.name}');
              await tester.ensureVisible(
                find.byKey(const ValueKey('open-workouts')),
              );
              await capture(tester, key, 'profile-features-${mode.name}');
            }
            await tester.tap(find.byKey(const ValueKey('quick-add-menu')));
            await tester.pumpAndSettle();
            expect(find.byType(MealFormDialog), findsOneWidget);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }

    testWidgets('render recognizable feature and action glyphs ${mode.name}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 810);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final dark = mode == ThemeMode.dark;
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              backgroundColor: dark ? Colors.black : Colors.white,
              body: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HealthMate',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: dark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Bộ icon mới · Tabler',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 12,
                      runSpacing: 22,
                      children: [
                        for (final entry in const [
                          (AppFeatureVisual.nutrition, 'Dinh dưỡng'),
                          (AppFeatureVisual.water, 'Nước uống'),
                          (AppFeatureVisual.workout, 'Tập luyện'),
                          (AppFeatureVisual.chatbot, 'AI Chatbot'),
                          (AppFeatureVisual.scanner, 'Quét món'),
                          (AppFeatureVisual.weight, 'Cân nặng'),
                          (AppFeatureVisual.goals, 'Mục tiêu'),
                          (AppFeatureVisual.quest, 'Nhiệm vụ'),
                          (AppFeatureVisual.profile, 'Hồ sơ'),
                          (AppFeatureVisual.report, 'Báo cáo'),
                          (AppFeatureVisual.premium, 'Premium'),
                          (AppFeatureVisual.support, 'Hỗ trợ'),
                          (AppFeatureVisual.steps, 'Bước chân'),
                          (AppFeatureVisual.sleep, 'Giấc ngủ'),
                          (AppFeatureVisual.activity, 'Vận động'),
                          (AppFeatureVisual.wellness, 'Thói quen'),
                        ])
                          SizedBox(
                            width: 126,
                            child: Column(
                              children: [
                                FeatureIconBadge(entry.$1, size: 58),
                                const SizedBox(height: 9),
                                Text(
                                  entry.$2,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 18),
                    const Text(
                      'Thao tác quen thuộc',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final icon in [
                          AppIcons.plus,
                          AppIcons.squarePen,
                          AppIcons.trash2,
                          AppIcons.search,
                          AppIcons.camera,
                          AppIcons.settings2,
                          AppIcons.check,
                          AppIcons.x,
                        ])
                          Icon(icon, size: 24),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final icon in [
                          AppIcons.home,
                          AppIcons.journal,
                          AppIcons.workout,
                          AppIcons.progress,
                        ])
                          Icon(icon, size: 26),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await capture(tester, key, 'icons-${mode.name}');
      expect(tester.takeException(), isNull);
    });
  }
}
