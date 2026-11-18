import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/core/theme/reference_palette.dart';
import 'package:healthmate/features/dashboard/models/calorie_ring_data.dart';
import 'package:healthmate/features/dashboard/presentation/widgets/calorie_macro_ring.dart';
import 'package:healthmate/features/dashboard/presentation/widgets/mfp_calories_card.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';

import 'support/load_icon_font.dart';

const macros = NutritionTotals(
  kcal: 1000,
  proteinG: 25,
  carbsG: 50,
  fatG: 100 / 9,
);

CalorieRingData ring({
  double? consumed = 1000,
  double? target = 2000,
  NutritionTotals? totals = macros,
}) => CalorieRingData(consumed: consumed, target: target, totals: totals);

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/neutral-ui-20261116/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
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

  test(
    'macro colors follow energy, while length keeps the recorded calorie goal',
    () {
      final data = ring();
      // 400 kcal from 4/4/9 differs from the 1000 recorded kcal on purpose.
      expect(data.shares, [0.25, 0.5, 0.25]);
      expect(data.progress, 0.5);
      expect(data.hasComposition, isTrue);
      expect(data.hasProgress, isTrue);
    },
  );

  test('zero grams never receives a decorative energy slice', () {
    final data = ring(totals: const NutritionTotals(carbsG: 100));
    expect(data.shares, [0, 1, 0]);
    expect(ring(totals: NutritionTotals.zero).hasComposition, isFalse);
    expect(ring(consumed: 0, totals: NutritionTotals.zero).progress, 0);
  });

  test(
    'incomplete, negative, nonfinite and overflowing macros do not invent ratios',
    () {
      for (final totals in [
        null,
        const NutritionTotals(proteinKnown: false, carbsG: 50),
        const NutritionTotals(carbsKnown: false, proteinG: 25),
        const NutritionTotals(fatKnown: false, proteinG: 25),
        const NutritionTotals(proteinG: -1, carbsG: 50),
        const NutritionTotals(fatG: double.nan),
        const NutritionTotals(carbsG: double.infinity),
        const NutritionTotals(carbsG: 1e308),
      ]) {
        final data = ring(totals: totals);
        expect(data.hasComposition, isFalse);
        expect(data.shares, [0, 0, 0]);
        expect(data.progress, 0.5);
      }
    },
  );

  test(
    'unknown goals or consumption are unavailable; excess saturates without changing colors',
    () {
      for (final target in [null, 0.0, -1.0, double.nan, double.infinity]) {
        expect(ring(target: target).hasProgress, isFalse);
        expect(ring(target: target).progress, 0);
      }
      for (final consumed in [null, -1.0, double.nan, double.infinity]) {
        expect(ring(consumed: consumed).hasProgress, isFalse);
        expect(ring(consumed: consumed).progress, 0);
      }
      expect(ring(consumed: 2200).progress, 1);
      expect(ring(consumed: 2200).shares, ring().shares);
    },
  );

  test(
    'painted arc contains each real macro color and the remaining track',
    () async {
      const track = Color(0xFF353535);
      final recorder = ui.PictureRecorder();
      CalorieMacroRingPainter(
        progress: ring().progress,
        shares: ring().shares,
        track: track,
        fallback: Colors.grey,
      ).paint(Canvas(recorder), const Size(180, 180));
      final picture = recorder.endRecording();
      final image = await picture.toImage(180, 180);
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      Color pixel(double angle) {
        final x = (90 + 84 * math.cos(angle)).round();
        final y = (90 + 84 * math.sin(angle)).round();
        final offset = (y * 180 + x) * 4;
        return Color.fromARGB(
          255,
          bytes.getUint8(offset),
          bytes.getUint8(offset + 1),
          bytes.getUint8(offset + 2),
        );
      }

      expect(pixel(-math.pi * 3 / 8), ReferencePalette.protein);
      expect(pixel(0), ReferencePalette.carb);
      expect(pixel(math.pi * 3 / 8), ReferencePalette.fat);
      expect(pixel(math.pi), track);
      image.dispose();
      picture.dispose();
    },
  );

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'calorie legend, explanation and excess remain readable dark=$dark scale=$scale',
        (tester) async {
          tester.view.physicalSize = Size(scale == 2 ? 320 : 390, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final key = GlobalKey();
          final semantics = tester.ensureSemantics();
          try {
            Widget page({
              double consumed = 1650,
              NutritionTotals? totals = macros,
            }) => MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: RepaintBoundary(
                key: key,
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: MfpCaloriesCard(
                      consumed: consumed,
                      target: 2000,
                      nutritionTotals: totals,
                      exerciseMinutes: 20,
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpWidget(page());
            await tester.pumpAndSettle();
            expect(find.text('350'), findsOneWidget);
            for (final text in ['Đạm', 'Tinh bột', 'Chất béo']) {
              expect(find.text(text), findsOneWidget);
            }
            expect(
              find.bySemanticsLabel(
                RegExp('Tỷ lệ năng lượng dưỡng chất: đạm 25'),
              ),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
            if (scale == 1) {
              await capture(
                tester,
                key,
                dark ? 'calorie-dark' : 'calorie-light',
              );
            }
            final info = find.byTooltip('Cách đọc vòng calo');
            await tester.ensureVisible(info);
            await tester.tap(info);
            await tester.pumpAndSettle();
            expect(find.text('Cách đọc vòng calo'), findsOneWidget);
            Navigator.of(tester.element(find.byType(AlertDialog))).pop();
            await tester.pumpAndSettle();
            await tester.pumpWidget(
              page(
                consumed: 2200,
                totals: const NutritionTotals(proteinKnown: false),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('Calo vượt mục tiêu'), findsOneWidget);
            expect(find.text('200'), findsOneWidget);
            expect(
              find.byKey(const ValueKey('home-calorie-macros-unavailable')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
