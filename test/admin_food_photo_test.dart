import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/nutrition/models/catalog_food_reader.dart';
import 'package:healthmate/features/nutrition/models/nutrition_models.dart';
import 'package:healthmate/features/nutrition/providers/food_photo_provider.dart';
import 'package:healthmate/features/nutrition/providers/nutrition_providers.dart';
import 'package:healthmate/features/nutrition/presentation/food_photo_thumbnail.dart';
import 'package:healthmate/features/nutrition/presentation/food_selection_card.dart';

const custom = {
  'mode': 'custom',
  'url': 'https://example.com/pho.webp',
  'title': 'Phở fixture',
  'author': 'Fixture owner',
  'sourceUrl': 'https://example.com/pho',
  'license': 'CC0',
  'licenseUrl': 'https://creativecommons.org/publicdomain/zero/1.0/',
};
FoodCatalogItem food([Object? photo]) => readCatalogFood('vn-pho-bo', {
  'name': 'Phở bò',
  'category': 'Món Việt',
  'kcalPer100g': 100,
  'proteinGPer100g': 10,
  'carbsGPer100g': 12,
  'fatGPer100g': 2,
  'sourceLabel': 'Test fixture',
  'isEstimated': true,
  'photo': ?photo,
});

void main() {
  test('catalog photo parsing fails closed without altering nutrition', () {
    final valid = food(custom);
    expect(valid.photo?.imageUrl, custom['url']);
    final snapshot = MealItemSnapshot.fromCatalog(valid, 200);
    for (final raw in [
      {...custom, 'url': 'javascript:alert(1)'},
      {...custom, 'url': 'http://example.com/pho'},
      {...custom, 'url': 'https://user:password@example.com/pho'},
      {'mode': 'custom'},
      {'mode': 'invalid'},
      'damaged',
    ]) {
      final parsed = food(raw);
      expect(parsed.photo, isNull);
      expect(parsed.photoMode, isNot('default'));
      expect(parsed.nutritionPer100g.kcal, 100);
    }
    expect(snapshot.nutrition.kcal, 200);
    expect(snapshot.toData().containsKey('photo'), isFalse);
  });

  test(
    'URL-only custom photo uses the food name and does not invent credits',
    () {
      final parsed = food({'mode': 'custom', 'url': custom['url']});
      expect(parsed.photo?.imageUrl, custom['url']);
      expect(parsed.photo?.title, 'Phở bò');
      expect(parsed.photo?.author, isEmpty);
      expect(parsed.photo?.sourceUrl, isEmpty);
      expect(parsed.photo?.license, isEmpty);
      expect(parsed.photo?.licenseUrl, isEmpty);
      expect(parsed.nutritionPer100g.kcal, 100);
      final legacy = food(custom).photo!;
      expect(legacy.author, custom['author']);
      expect(legacy.sourceUrl, custom['sourceUrl']);
      expect(legacy.license, custom['license']);
      expect(legacy.licenseUrl, custom['licenseUrl']);
      final damagedOptional = food({
        'mode': 'custom',
        'url': custom['url'],
        'sourceUrl': 'javascript:alert(1)',
        'licenseUrl': 'http://example.com',
      }).photo!;
      expect(damagedOptional.sourceUrl, isEmpty);
      expect(damagedOptional.licenseUrl, isEmpty);
    },
  );

  testWidgets(
    'open food card and attribution receive custom, remove and restore without reopening',
    (tester) async {
      final stream = StreamController<List<FoodCatalogItem>>();
      addTearDown(stream.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [foodCatalogProvider.overrideWith((ref) => stream.stream)],
          child: const MaterialApp(
            home: Scaffold(
              body: FoodSelectionCard(
                foodId: 'vn-pho-bo',
                name: 'Phở bò',
                quantityLabel: '100 g',
                isEstimated: true,
                nutrition: NutritionTotals(kcal: 100),
              ),
            ),
          ),
        ),
      );
      stream.add([food()]);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<ResizeImage>(),
      );
      await tester.tap(find.byKey(const ValueKey('food-photo-vn-pho-bo')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      stream.add([food(custom)]);
      await tester.pumpAndSettle();
      expect(find.textContaining('Fixture owner'), findsOneWidget);
      final photos = tester.widgetList<FoodPhotoImage>(
        find.byType(FoodPhotoImage),
      );
      expect(
        photos.every((image) => image.photo.imageUrl == custom['url']),
        isTrue,
      );
      expect(find.text('Ảnh chưa khả dụng'), findsOneWidget);
      stream.add([
        food({'mode': 'custom', 'url': 'https://example.com/apple.jpg'}),
      ]);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Fixture owner'), findsNothing);
      expect(find.textContaining('Giấy phép:'), findsNothing);
      expect(find.text('Trang ảnh gốc'), findsNothing);
      expect(find.text('Xem giấy phép'), findsNothing);
      expect(
        tester
            .widgetList<FoodPhotoImage>(find.byType(FoodPhotoImage))
            .every(
              (image) =>
                  image.photo.imageUrl == 'https://example.com/apple.jpg',
            ),
        isTrue,
      );
      stream.add([
        food({'mode': 'hidden'}),
      ]);
      await tester.pumpAndSettle();
      expect(
        find.text('Ảnh món này đã được gỡ hoặc thay đổi.'),
        findsOneWidget,
      );
      expect(find.byType(FoodPhotoThumbnail), findsNothing);
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      stream.add([
        food({'mode': 'default'}),
      ]);
      await tester.pumpAndSettle();
      expect(find.byType(FoodPhotoThumbnail), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'shared resolver hides invalid custom photos and cannot reuse one after rename',
    () async {
      final container = ProviderContainer(
        overrides: [
          foodCatalogProvider.overrideWith(
            (ref) => Stream.value([
              food({'mode': 'hidden'}),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(foodCatalogProvider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(foodCatalogProvider.future);
      expect(
        container.read(foodPhotoProvider(('vn-pho-bo', 'Phở bò'))),
        isNull,
      );
      expect(
        container.read(foodPhotoProvider(('vn-pho-bo', 'Tên món khác'))),
        isNull,
      );
    },
  );
}
