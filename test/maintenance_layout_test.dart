import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/core/widgets/metric_tile.dart';
import 'package:healthmate/features/journal/presentation/daily_summary_card.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final name in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/inter/Inter-$name.ttf'));
    }
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final width in [360.0, 390.0, 412.0, 900.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('F05/F06 width=$width scale=$scale dark=$dark', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final boundary = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: RepaintBoundary(
                  key: boundary,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          DailySummaryCard(
                            date: DateTime(2026, 10, 17),
                            mealsState: const AsyncData([]),
                            waterState: const AsyncData([]),
                            activityState: const AsyncData([]),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.topLeft,
                            child: SizedBox(
                              width:
                                  (width - 48) /
                                  (width - 48 >= 680 || scale < 1.4 ? 2 : 1),
                              child: MetricTile(
                                title: 'Nước',
                                icon: Icons.water_drop_outlined,
                                value: '1.250',
                                unit: 'ml',
                                subtitle: 'Đã ghi hôm nay',
                                accentBackground: Colors.blue.shade50,
                                accentForeground: Colors.blue.shade900,
                                action: ActionChip(
                                  label: const Text('+250 ml'),
                                  onPressed: () {},
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final kcal = tester.getTopLeft(
            find.byKey(const ValueKey('summary-kcal')),
          );
          final macros = tester.getTopLeft(
            find.byKey(const ValueKey('summary-macros')),
          );
          if (scale == 1) {
            expect(kcal.dy, macros.dy);
            expect(macros.dx, greaterThan(kcal.dx));
          }
          final label = find.text('Đã ghi hôm nay');
          final text = tester.widget<Text>(label);
          expect(text.maxLines, isNull);
          expect(text.overflow, isNot(TextOverflow.ellipsis));
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: label, matching: find.byType(RichText)),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final screenshot =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 1);
            final bytes = await screenshot.toByteData(
              format: ui.ImageByteFormat.png,
            );
            screenshot.dispose();
            final folder = Directory('build/maintenance-layout');
            await folder.create(recursive: true);
            await File(
              '${folder.path}/${width.toInt()}-$scale-${dark ? 'dark' : 'light'}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
          });
        });
      }
    }
  }
}
