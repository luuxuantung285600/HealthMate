import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:healthmate/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:healthmate/features/food_scanner/data/barcode_product_service.dart';
import 'package:healthmate/features/food_scanner/models/barcode_product_models.dart';
import 'package:healthmate/features/food_scanner/presentation/barcode_product_detail_sheet.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';

const product = BarcodeProduct(
  barcode: '3017620422003',
  name: 'Món thử',
  source: 'Open Food Facts',
  servingSizeG: 15,
  nutrition: NutritionTotals(
    kcal: 500,
    proteinG: 10,
    carbsG: 50,
    fatG: 20,
    fiberG: 4,
    fiberKnown: true,
  ),
);

void main() {
  test(
    'per-100-g bounds reject non-finite, negative and extreme direct data',
    () {
      for (final value in [double.nan, double.infinity, -1.0, 100.01, 500.0]) {
        for (final nutrients in [
          NutritionTotals(kcal: 100, proteinG: value),
          NutritionTotals(kcal: 100, carbsG: value),
          NutritionTotals(kcal: 100, fatG: value),
          NutritionTotals(kcal: 100, fiberG: value, fiberKnown: true),
        ]) {
          final invalid = BarcodeProduct(
            barcode: '123',
            name: 'Fixture',
            source: 'Fixture',
            nutrition: nutrients,
          );
          // A small portion must not hide invalid per-100-g data.
          expect(
            () => BarcodeMealSelection(
              product: invalid,
              quantity: 1,
            ).toSnapshot(),
            throwsFormatException,
          );
        }
      }
      for (final kcal in [
        double.nan,
        double.infinity,
        -1.0,
        1000.01,
        10000.0,
      ]) {
        final invalid = BarcodeProduct(
          barcode: '123',
          name: 'Fixture',
          source: 'Fixture',
          nutrition: NutritionTotals(kcal: kcal),
        );
        expect(
          () =>
              BarcodeMealSelection(product: invalid, quantity: 1).toSnapshot(),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'mass validation does not cap whole portions at 100 or double-count fiber',
    () {
      const source = BarcodeProduct(
        barcode: '123',
        name: 'Fixture',
        source: 'Fixture',
        nutrition: NutritionTotals(
          kcal: 300,
          proteinG: 30,
          carbsG: 60,
          fatG: 5,
          fiberG: 20,
          fiberKnown: true,
        ),
      );
      final portion = const BarcodeMealSelection(
        product: source,
        quantity: 500,
      ).toSnapshot();
      expect(portion.nutrition.proteinG, 150);
      expect(portion.nutrition.carbsG, 300);
      expect(portion.nutrition.fiberG, 100);
      expect(portion.nutrition.kcal, 1500);
      expect(source.nutrition!.proteinG, 30);
    },
  );

  test(
    'unknown basis cannot save, volume stays ml and cannot override known mass',
    () {
      const source = BarcodeProduct(
        barcode: '123',
        name: 'Volume fixture',
        source: 'Fixture',
        basis: BarcodeNutritionBasis.unconfirmed,
        servingSizeMl: 250,
        nutrition: NutritionTotals(
          kcal: 450,
          carbsG: 110,
          proteinKnown: false,
          fatKnown: false,
        ),
      );
      expect(
        () => const BarcodeMealSelection(
          product: source,
          quantity: 100,
        ).toSnapshot(),
        throwsFormatException,
      );
      expect(
        () => const BarcodeMealSelection(
          product: source,
          quantity: 100,
          confirmedBasis: BarcodeNutritionBasis.per100g,
        ).toSnapshot(),
        throwsFormatException,
      );
      final saved = const BarcodeMealSelection(
        product: source,
        quantity: 150,
        confirmedBasis: BarcodeNutritionBasis.per100ml,
      ).toSnapshot();
      expect(saved.toData()['grams'], isNull);
      expect(saved.toData()['quantityUnit'], 'ml');
      expect(saved.quantity, 150);
      expect(saved.nutrition.carbsG, 165);
      expect(saved.nutrition.kcal, 675);
      expect(saved.toData()['proteinG'], isNull);
      expect(saved.withQuantity(300).nutrition.carbsG, 330);
      final restored = MealItemSnapshot.fromCompactData(
        Map.from(saved.toCompactData()),
      );
      expect(restored.quantityUnit, 'ml');
      expect(restored.quantity, 150);
      expect(
        () => const BarcodeMealSelection(
          product: product,
          quantity: 100,
          confirmedBasis: BarcodeNutritionBasis.per100ml,
        ).toSnapshot(),
        throwsFormatException,
      );
    },
  );

  test(
    'invalid extras are rejected, never silently discarded or converted twice',
    () {
      for (final extras in [
        {'sugar': 101.0},
        {'saturatedFat': -1.0},
        {'sodium': double.nan},
        {'iron': double.infinity},
        {'unknown': 1.0},
        {'calcium': 100001.0},
      ]) {
        final source = BarcodeProduct(
          barcode: '123',
          name: 'Fixture',
          source: 'Fixture',
          nutrition: NutritionTotals(kcal: 100, extraNutrients: extras),
        );
        expect(
          () => BarcodeMealSelection(product: source, quantity: 1).toSnapshot(),
          throwsFormatException,
        );
      }
      const source = BarcodeProduct(
        barcode: '123',
        name: 'Fixture',
        source: 'Fixture',
        nutrition: NutritionTotals(kcal: 100, extraNutrients: {'iron': 6000}),
      );
      expect(
        () => const BarcodeMealSelection(
          product: source,
          quantity: 200,
        ).toSnapshot(),
        throwsFormatException,
      );
    },
  );

  test(
    'OFF invalid numbers fail as data errors; missing energy stays unavailable',
    () async {
      for (final value in ['NaN', 'Infinity', '-Infinity', 'bad', -1, 10001]) {
        final service = BarcodeProductService(
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'status': 1,
                'product': {
                  'product_name': 'Fixture',
                  'nutriments': {'energy-kcal_100g': value},
                },
              }),
              200,
            ),
          ),
        );
        addTearDown(service.dispose);
        await expectLater(
          service.lookupBarcode('123'),
          throwsA(
            isA<BarcodeLookupFailure>().having(
              (e) => e.message,
              'message',
              contains('Dữ liệu dinh dưỡng'),
            ),
          ),
        );
      }
      final service = BarcodeProductService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Fixture',
                'nutriments': {'proteins_100g': 0},
              },
            }),
            200,
          ),
        ),
      );
      addTearDown(service.dispose);
      expect((await service.lookupBarcode('123'))!.nutrition, isNull);
    },
  );

  test(
    'zero energy and macros stay known zero; units never inferred from packaging',
    () async {
      final service = BarcodeProductService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Fixture',
                'nutrition_data_per': '100g',
                'product_quantity_unit': 'g',
                'serving_quantity': 25,
                'nutriments': {
                  'energy-kcal_100g': '0',
                  'proteins_100g': '0',
                  'carbohydrates_100g': 0,
                  'fat_100g': 0,
                  'fiber_100g': 0,
                },
              },
            }),
            200,
          ),
        ),
      );
      addTearDown(service.dispose);
      final source = (await service.lookupBarcode('123'))!;
      expect(source.basis, BarcodeNutritionBasis.unconfirmed);
      expect(source.servingSizeG, isNull);
      final item = BarcodeMealSelection(
        product: source,
        quantity: 25,
        confirmedBasis: BarcodeNutritionBasis.per100g,
      ).toSnapshot();
      expect(item.nutrition.kcal, 0);
      expect(item.nutrition.hasCompleteMacros, isTrue);
      expect(item.nutrition.fiberKnown, isTrue);
      expect(item.toData()['fiberG'], 0);
    },
  );
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/Inter-Regular.ttf'))).load();
  });

  test(
    'rejects 500 g protein per confirmed 100 g from OFF before snapshot',
    () async {
      final service = BarcodeProductService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Invalid protein',
                'nutrition_data_per': '100g',
                'product_quantity_unit': 'g',
                'nutriments': {'energy-kcal_100g': 100, 'proteins_100g': 500},
              },
            }),
            200,
          ),
        ),
      );
      addTearDown(service.dispose);
      final found = (await service.lookupBarcode('123'))!;
      expect(found.basis, BarcodeNutritionBasis.unconfirmed);
      expect(
        () => BarcodeMealSelection(
          product: found,
          quantity: 100,
          confirmedBasis: BarcodeNutritionBasis.per100g,
        ).toSnapshot(),
        throwsFormatException,
      );
    },
  );

  test('direct barcode model cannot bypass per-100-g validation', () {
    const invalid = BarcodeProduct(
      barcode: '123',
      name: 'Invalid protein',
      source: 'Fixture',
      nutrition: NutritionTotals(kcal: 100, proteinG: 500),
    );
    expect(
      () => const BarcodeMealSelection(
        product: invalid,
        quantity: 100,
      ).toSnapshot(),
      throwsFormatException,
    );
  });

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('barcode app-theme layout $width text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Scaffold(
              body: BarcodeProductDetailSheet(
                product: BarcodeProduct(
                  barcode: '3017620422003',
                  name:
                      'Sản phẩm có tên dài để kiểm tra hiển thị trên màn hình nhỏ',
                  brand: 'Thương hiệu có tên dài dùng trong kiểm thử',
                  source:
                      'Open Food Facts · Nhãn dinh dưỡng do cộng đồng đóng góp',
                  servingSizeG: 150,
                  nutrition: NutritionTotals(
                    kcal: 100,
                    proteinG: 10,
                    carbsG: 5,
                    fatG: 2,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final scroll = find
            .descendant(
              of: find.byType(BarcodeProductDetailSheet),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('barcode-confirm')),
          150,
          scrollable: scroll,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('barcode-confirm')),
              )
              .onPressed,
          isNotNull,
        );
      });
    }
  }

  test('OFF normalized grams convert minerals to mg exactly once', () async {
    final service = BarcodeProductService(
      client: MockClient(
        (r) async => http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name': 'Label fixture',
              'nutriments': {
                'energy-kcal_100g': 100,
                'proteins_100g': 10,
                'carbohydrates_100g': 10,
                'fat_100g': 2,
                'sodium_100g': .12,
                'iron_100g': .00125,
                'sugars_100g': 0,
                'saturated-fat_100g': 1,
              },
            },
          }),
          200,
        ),
      ),
    );
    final product = (await service.lookupBarcode('1234567890123'))!;
    final snapshot = BarcodeMealSelection(
      product: product,
      quantity: 150,
      confirmedBasis: BarcodeNutritionBasis.per100g,
    ).toSnapshot();
    expect(snapshot.nutrition.extraNutrients['sodium'], 180);
    expect(snapshot.nutrition.extraNutrients['iron'], closeTo(1.875, 1e-9));
    expect(snapshot.nutrition.extraNutrients['sugar'], 0);
    expect(snapshot.nutrition.extraNutrients.containsKey('vitaminC'), false);
  });
  test(
    'selected quantity scales every nutrient once and preserves snapshot',
    () {
      final item = const BarcodeMealSelection(
        product: product,
        quantity: 30,
      ).toSnapshot();
      expect(item.grams, 30);
      expect(item.nutrition.kcal, 150);
      expect(item.nutrition.proteinG, 3);
      expect(item.nutrition.carbsG, 15);
      expect(item.nutrition.fatG, 6);
      expect(item.nutrition.fiberG, closeTo(1.2, .0001));
      final roundTrip = MealItemSnapshot.fromData(
        Map.from(item.toData()),
        allowPartial: true,
      );
      expect(roundTrip.nutrition.kcal, 150);
      expect(roundTrip.withQuantity(60).nutrition.kcal, 300);
      for (final grams in [0.0, -1.0, 2001.0, double.nan, double.infinity]) {
        expect(
          () => BarcodeMealSelection(
            product: product,
            quantity: grams,
          ).toSnapshot(),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'lookup preserves missing macros and fiber, and uses kJ conversion',
    () async {
      final service = BarcodeProductService(
        client: MockClient((request) async {
          expect(request.headers['User-Agent'], contains('HealthMate'));
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Món thử',
                'serving_quantity': 250,
                'serving_quantity_unit': 'ml',
                'nutriments': {'energy_100g': 418.4, 'proteins_100g': 0},
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(service.dispose);
      final found = (await service.lookupBarcode('123'))!;
      expect(found.nutrition!.kcal, closeTo(100, .0001));
      expect(found.nutrition!.proteinKnown, isTrue);
      expect(found.nutrition!.carbsKnown, isFalse);
      expect(found.nutrition!.fatKnown, isFalse);
      expect(found.nutrition!.fiberKnown, isFalse);
      expect(
        found.servingSizeG,
        isNull,
      ); // ml is never silently treated as grams.
      final data = BarcodeMealSelection(
        product: found,
        quantity: 50,
        confirmedBasis: BarcodeNutritionBasis.per100ml,
      ).toSnapshot().toData();
      expect(data['grams'], isNull);
      expect(data['quantity'], 50);
      expect(data['quantityUnit'], 'ml');
      expect(data['proteinG'], 0);
      expect(data['carbsG'], isNull);
      expect(data['fatG'], isNull);
      expect(data.containsKey('fiberG'), isFalse);
    },
  );

  test(
    'lookup distinguishes not found from network, quota and invalid data',
    () async {
      for (final response in [
        http.Response('{"status":0}', 200),
        http.Response('', 404),
      ]) {
        final service = BarcodeProductService(
          client: MockClient((_) async => response),
        );
        expect(await service.lookupBarcode('123'), isNull);
        service.dispose();
      }
      for (final response in [
        http.Response('', 429),
        http.Response('', 503),
        http.Response('bad json', 200),
        http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name': 'Món thử',
              'nutriments': {'energy-kcal_100g': -10},
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ]) {
        final service = BarcodeProductService(
          client: MockClient((_) async => response),
        );
        await expectLater(
          service.lookupBarcode('123'),
          throwsA(isA<BarcodeLookupFailure>()),
        );
        service.dispose();
      }
      final service = BarcodeProductService(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.lookupBarcode('123'),
        throwsA(isA<BarcodeLookupFailure>()),
      );
    },
  );

  testWidgets(
    'barcode review returns edited decimal grams; invalid input cannot confirm',
    (tester) async {
      BarcodeMealSelection? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showModalBottomSheet<BarcodeMealSelection>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        const BarcodeProductDetailSheet(product: product),
                  );
                },
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      final grams = find.byKey(const ValueKey('barcode-grams'));
      await tester.enterText(grams, '30,5');
      await tester.pumpAndSettle();
      expect(find.text('153 kcal'), findsOneWidget);
      await tester.enterText(grams, '');
      await tester.pumpAndSettle();
      final confirm = find.byKey(const ValueKey('barcode-confirm'));
      await tester.scrollUntilVisible(
        confirm,
        150,
        scrollable: find
            .descendant(
              of: find.byType(BarcodeProductDetailSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.scrollUntilVisible(
        grams,
        -150,
        scrollable: find
            .descendant(
              of: find.byType(BarcodeProductDetailSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(grams, '30');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        confirm,
        150,
        scrollable: find
            .descendant(
              of: find.byType(BarcodeProductDetailSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(confirm);
      await tester.pumpAndSettle();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(result!.quantity, 30);
      expect(result!.toSnapshot().nutrition.kcal, 150);
      expect(product.nutrition!.kcal, 500);
    },
  );

  for (final basis in [
    BarcodeNutritionBasis.per100g,
    BarcodeNutritionBasis.per100ml,
  ]) {
    testWidgets(
      'OFF label confirmation saves correct unit $basis at 320px text 2',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        BarcodeMealSelection? result;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Mở'),
                  onPressed: () async {
                    result = await showModalBottomSheet<BarcodeMealSelection>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const BarcodeProductDetailSheet(
                        product: BarcodeProduct(
                          barcode: '3017620422003',
                          name: 'Nhãn sản phẩm',
                          source: 'Open Food Facts',
                          basis: BarcodeNutritionBasis.unconfirmed,
                          servingSizeG: 30,
                          servingSizeMl: 250,
                          nutrition: NutritionTotals(
                            kcal: 100,
                            proteinG: 5,
                            carbsG: 10,
                            fatG: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Mở'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final scroll = find
            .descendant(
              of: find.byType(BarcodeProductDetailSheet),
              matching: find.byType(Scrollable),
            )
            .first;
        final confirm = find.byKey(const ValueKey('barcode-confirm'));
        await tester.scrollUntilVisible(confirm, 120, scrollable: scroll);
        expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
        final selector = find.byKey(const ValueKey('barcode-basis'));
        await tester.scrollUntilVisible(selector, -120, scrollable: scroll);
        await tester.tap(selector);
        await tester.pumpAndSettle();
        await tester.tap(
          find
              .text(basis == BarcodeNutritionBasis.per100g ? '100 g' : '100 ml')
              .last,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final input = find.byKey(const ValueKey('barcode-grams'));
        await tester.scrollUntilVisible(input, 120, scrollable: scroll);
        expect(
          tester.widget<TextField>(input).controller!.text,
          basis == BarcodeNutritionBasis.per100g ? '30' : '250',
        );
        await tester.enterText(input, '150');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(confirm, 120, scrollable: scroll);
        expect(tester.takeException(), isNull);
        expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
        await tester.ensureVisible(confirm);
        await tester.pumpAndSettle();
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        final snapshot = result!.toSnapshot();
        expect(
          snapshot.quantityUnit,
          basis == BarcodeNutritionBasis.per100g ? 'g' : 'ml',
        );
        expect(snapshot.quantity, 150);
        expect(snapshot.nutrition.kcal, 150);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
