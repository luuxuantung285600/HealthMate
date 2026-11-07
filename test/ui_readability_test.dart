import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:healthmate/core/widgets/tracking_page.dart';
import 'package:healthmate/features/food_library/presentation/food_portion_dialog.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';

const food = FoodCatalogItem(
  id: 'readability-fixture',
  category: 'Kiểm thử',
  name: 'Cơm gạo lứt với đậu, rau và nấm theo khẩu phần đã chọn',
  originalName: 'Brown rice, beans and vegetables',
  servingBasis: ServingBasis.per100g,
  sourceLabel: 'Nguồn kiểm thử giao diện',
  isEstimated: true,
  servingLabel: 'chén tham khảo',
  servingGrams: 200,
  per100g: NutritionTotals(kcal: 150, proteinG: 8, carbsG: 26, fatG: 4),
);

Future<void> capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  await tester.runAsync(() async {
    final picture =
        await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    final folder = Directory('build/ui-readability');
    await folder.create(recursive: true);
    await File(
      '${folder.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/Inter-Regular.ttf'))).load();
  });

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'portion readable and editable at $width, font $scale, keyboard',
        (tester) async {
          tester.view.physicalSize = Size(width, 850);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          double? saved;
          final boundary = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: scale == 2 ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  viewInsets: const EdgeInsets.only(bottom: 260),
                ),
                child: RepaintBoundary(key: boundary, child: child!),
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    child: const Text('Chọn món'),
                    onPressed: () async {
                      saved = await askFoodGrams(
                        context,
                        food: food,
                        initial: 150,
                      );
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Chọn món'));
          await tester.pumpAndSettle();
          final amount = find.byKey(const ValueKey('meal-grams'));
          await tester.ensureVisible(amount);
          await tester.pumpAndSettle();
          await capture(tester, boundary, 'portion-${width.toInt()}-$scale');
          expect(find.text(food.originalName!), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.enterText(amount, '200');
          await tester.pumpAndSettle();
          final portions = find.byKey(const ValueKey('portion-unit'));
          await tester.ensureVisible(portions);
          await tester.pumpAndSettle();
          await tester.tap(portions);
          await tester.pumpAndSettle();
          expect(
            double.parse(tester.widget<TextFormField>(amount).controller!.text),
            1,
          );
          await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
          await tester.pumpAndSettle();
          expect(saved, 200);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('scrolling content cannot paint over fixed header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RepaintBoundary(
            key: boundary,
            child: TrackingPage(
              showProfileAvatar: false,
              header: const Text('Hôm nay\nThứ Ba, 27 tháng 10'),
              children: [
                for (var i = 0; i < 12; i++)
                  Container(
                    height: 140,
                    color: i.isEven ? Colors.red : Colors.green,
                    child: Text('Nội dung $i'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.getRect(find.text('Hôm nay\nThứ Ba, 27 tháng 10'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -430));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Hôm nay\nThứ Ba, 27 tháng 10')), before);
    await tester.runAsync(() async {
      final picture =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = (await picture.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      // The list's red/green cards are under this corner after the scroll.
      // Its pixel must still be the opaque header surface.
      final offset = (30 * picture.width + 2) * 4;
      final surface = AppTheme.light.colorScheme.surface;
      expect(bytes.getUint8(offset), (surface.r * 255).round());
      expect(bytes.getUint8(offset + 1), (surface.g * 255).round());
      expect(bytes.getUint8(offset + 2), (surface.b * 255).round());
      picture.dispose();
    });
    await capture(tester, boundary, 'header-after-scroll');
    expect(tester.takeException(), isNull);
  });
}
