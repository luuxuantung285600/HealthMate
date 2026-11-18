import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/features/activity/presentation/exercise_gif_background.dart';

void main() {
  Uint8List enclosedFixture() {
    final rgba = Uint8List(180 * 180 * 4)..fillRange(0, 180 * 180 * 4, 255);
    for (var y = 20; y < 160; y++) {
      for (var x = 20; x < 160; x++) {
        rgba.setRange((y * 180 + x) * 4, (y * 180 + x) * 4 + 4, [
          120,
          80,
          60,
          255,
        ]);
      }
    }
    return rgba;
  }

  void whitePatch(Uint8List rgba, int x, int y) {
    for (var dy = -2; dy <= 2; dy++) {
      for (var dx = -2; dx <= 2; dx++) {
        final offset = ((y + dy) * 180 + x + dx) * 4;
        rgba.fillRange(offset, offset + 4, 255);
      }
    }
  }

  test(
    'reviewed enclosed backdrop clears without removing a separate white highlight',
    () {
      final rgba = enclosedFixture();
      whitePatch(rgba, 52, 68);
      whitePatch(rgba, 100, 100);
      final result = clearExerciseGifBackground(
        rgba,
        180,
        180,
        sourceId: 'BCs0G2F',
      );
      expect(result[(68 * 180 + 52) * 4 + 3], 0);
      expect(result[(100 * 180 + 100) * 4 + 3], 255);
      final unknown = clearExerciseGifBackground(
        rgba,
        180,
        180,
        sourceId: 'unknown',
      );
      expect(unknown[(68 * 180 + 52) * 4 + 3], 255);
    },
  );

  test(
    'pose guard preserves the same white location when it belongs to a limb',
    () {
      final rgba = enclosedFixture();
      whitePatch(rgba, 112, 95);
      final protected = clearExerciseGifBackground(
        rgba,
        180,
        180,
        sourceId: 'daBmy1Y',
      );
      expect(protected[(95 * 180 + 112) * 4 + 3], 255);
      whitePatch(rgba, 105, 100);
      final backdrop = clearExerciseGifBackground(
        rgba,
        180,
        180,
        sourceId: 'daBmy1Y',
      );
      expect(backdrop[(95 * 180 + 112) * 4 + 3], 0);
      expect(backdrop[(100 * 180 + 105) * 4 + 3], 255);
    },
  );

  test(
    'clears border-connected white but preserves enclosed highlights and muscle colors',
    () {
      const width = 17, height = 17;
      final pixels = Uint8List(width * height * 4)
        ..fillRange(0, width * height * 4, 255);
      void pixel(int x, int y, List<int> color) =>
          pixels.setRange((y * width + x) * 4, (y * width + x) * 4 + 4, color);
      for (var y = 3; y <= 13; y++) {
        for (var x = 3; x <= 13; x++) {
          if (x == 8 && y == 8) continue;
          pixel(x, y, [170, 170, 170, 255]);
        }
      }
      pixel(7, 8, [215, 65, 50, 255]);
      pixel(2, 8, [253, 253, 253, 255]);
      final original = Uint8List.fromList(pixels);
      final output = clearExerciseGifBackground(pixels, width, height);
      List<int> result(int x, int y) =>
          output.sublist((y * width + x) * 4, (y * width + x) * 4 + 4);
      expect(result(0, 0), [0, 0, 0, 0]);
      expect(result(2, 8), [0, 0, 0, 0]);
      expect(
        result(8, 8),
        [255, 255, 255, 255],
        reason: 'A white highlight inside the figure is not background.',
      );
      expect(result(7, 8), [215, 65, 50, 255]);
      expect(result(8, 7), [170, 170, 170, 255]);
      expect(
        pixels,
        original,
        reason:
            'The source frame is needed again when switching to light mode.',
      );
    },
  );

  test('suppresses a white fringe with soft coverage, not a blurred body', () {
    const width = 13, height = 13;
    final pixels = Uint8List(width * height * 4)
      ..fillRange(0, width * height * 4, 255);
    for (var y = 3; y <= 9; y++) {
      for (var x = 3; x <= 9; x++) {
        final edge = x == 3 || x == 9 || y == 3 || y == 9;
        pixels.setRange(
          (y * width + x) * 4,
          (y * width + x) * 4 + 4,
          edge ? [235, 235, 235, 255] : [180, 65, 50, 255],
        );
      }
    }
    final output = clearExerciseGifBackground(pixels, width, height);
    List<int> pixel(int x, int y) =>
        output.sublist((y * width + x) * 4, (y * width + x) * 4 + 4);
    expect(pixel(2, 6), [0, 0, 0, 0]);
    expect(
      pixel(3, 6)[3],
      inInclusiveRange(35, 85),
      reason: 'The baked-in white fringe must not remain opaque.',
    );
    expect(
      pixel(4, 6)[3],
      inInclusiveRange(170, 220),
      reason: 'Subpixel coverage must soften the contour, not a hard cut.',
    );
    expect(pixel(6, 6), [180, 65, 50, 255]);
    final feathered = pixel(4, 6);
    for (var channel = 0; channel < 3; channel++) {
      expect(
        feathered[channel],
        lessThanOrEqualTo(feathered[3]),
        reason: 'Flutter requires valid premultiplied edge colors.',
      );
    }
    expect(
      pixel(3, 6).take(3),
      everyElement(lessThan(80)),
      reason: 'The white matte must be removed, not only blurred.',
    );
    expect(
      feathered[0],
      greaterThan(feathered[1]),
      reason: 'The muscle edge should retain its red direction.',
    );
  });

  test('preserves an opaque frame with no white backdrop', () {
    final pixels = Uint8List.fromList(
      List.filled(25, [160, 70, 40, 255]).expand((pixel) => pixel).toList(),
    );
    expect(clearExerciseGifBackground(pixels, 5, 5), pixels);
  });

  test('keeps a transparent frame transparent', () {
    final pixels = Uint8List(5 * 5 * 4);
    expect(clearExerciseGifBackground(pixels, 5, 5), pixels);
  });

  test(
    'does not attenuate existing translucent content without a backdrop',
    () {
      final pixels = Uint8List.fromList(
        List.filled(25, [80, 40, 20, 128]).expand((pixel) => pixel).toList(),
      );
      expect(clearExerciseGifBackground(pixels, 5, 5), pixels);
    },
  );

  test('rejects malformed frames before accessing pixel memory', () {
    expect(
      () => clearExerciseGifBackground(Uint8List(3), 1, 1),
      throwsArgumentError,
    );
    expect(
      () => clearExerciseGifBackground(Uint8List(0), 0, 0),
      throwsArgumentError,
    );
  });
}
