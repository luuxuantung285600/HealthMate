import 'dart:typed_data';

import 'exercise_background_profiles.dart';

/// Removes border-connected and reviewed enclosed backdrop white, then feathers
/// the alpha matte. Unreviewed images retain their interior white highlights.
/// Contracts the silhouette
/// by one source pixel to suppress the white antialiasing baked into GIF edges.
/// Edge colors are decontaminated from their original white matte; interior
/// colors and detail are not blurred.
/// Input/output use premultiplied RGBA, as required by Flutter's rgba8888 codec.
Uint8List clearExerciseGifBackground(
  Uint8List rgba,
  int width,
  int height, {
  String? sourceId,
}) {
  if (width <= 0 || height <= 0 || rgba.length != width * height * 4) {
    throw ArgumentError('Invalid RGBA frame dimensions.');
  }
  final output = Uint8List.fromList(rgba);
  final visited = Uint8List(width * height);
  final queue = Uint32List(width * height);
  var head = 0, tail = 0;
  void enqueue(int pixel) {
    if (visited[pixel] != 0) return;
    visited[pixel] = 1;
    final offset = pixel * 4;
    if (rgba[offset + 3] < 250 ||
        rgba[offset] + rgba[offset + 1] + rgba[offset + 2] < 750) {
      return;
    }
    queue[tail++] = pixel;
  }

  for (var x = 0; x < width; x++) {
    enqueue(x);
    enqueue((height - 1) * width + x);
  }
  for (var y = 0; y < height; y++) {
    enqueue(y * width);
    enqueue(y * width + width - 1);
  }
  // Reviewed seeds open enclosed background holes. Guards distinguish moving
  // limbs from backdrop at the same coordinate in a different animation pose.
  if (width == exerciseBackgroundWidth && height == exerciseBackgroundHeight) {
    for (final region in exerciseBackgroundProfiles[sourceId] ?? const []) {
      final guards = region['guards'] as List<List<num>>;
      final matches = guards.every((guard) {
        final offset = (guard[1].toInt() * width + guard[0].toInt()) * 4;
        if (rgba[offset + 3] < 250) return false;
        final above =
            rgba[offset] + rgba[offset + 1] + rgba[offset + 2] >= guard[3];
        return above == (guard[2] == 1);
      });
      if (matches) {
        final seed = region['seed'] as List<int>;
        enqueue(seed[1] * width + seed[0]);
      }
    }
  }
  while (head < tail) {
    final pixel = queue[head++], x = pixel % width, y = pixel ~/ width;
    final offset = pixel * 4;
    output.fillRange(offset, offset + 4, 0);
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final nx = x + dx, ny = y + dy;
        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
          enqueue(ny * width + nx);
        }
      }
    }
  }
  if (tail == 0) return output;
  // GIF edges were antialiased against white before encoding. Clearing only
  // pure white leaves a bright stair-step fringe on a black surface. Contract
  // the silhouette by one source pixel, then feather this matte (not the RGB).
  final contracted = Uint8List(width * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      var alpha = output[(y * width + x) * 4 + 3];
      for (var dy = -1; dy <= 1 && alpha > 0; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final nx = x + dx, ny = y + dy;
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
          final neighbor = output[(ny * width + nx) * 4 + 3];
          if (neighbor < alpha) alpha = neighbor;
        }
      }
      contracted[y * width + x] = alpha;
    }
  }
  // Five-tap Gaussian, sigma ~= 0.8 source pixels. The wider transition
  // smooths diagonal steps; decontamination below prevents a pale blur halo.
  const weights = [0.0219296, 0.2285121, 0.4991166, 0.2285121, 0.0219296];
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final offset = (y * width + x) * 4;
      if (output[offset + 3] == 0) continue;
      var alpha = 0.0;
      for (var dy = -2; dy <= 2; dy++) {
        for (var dx = -2; dx <= 2; dx++) {
          final nx = (x + dx).clamp(0, width - 1);
          final ny = (y + dy).clamp(0, height - 1);
          alpha +=
              contracted[ny * width + nx] * weights[dy + 2] * weights[dx + 2];
        }
      }
      final oldAlpha = output[offset + 3];
      final coverage = (alpha * oldAlpha / 255).round();
      // Remove the lost coverage's white contribution, rather than multiplying
      // the already-white-contaminated RGB by alpha again. This is inverse
      // compositing against white, in premultiplied space, not a body blur.
      final whiteContribution = oldAlpha - coverage;
      for (var channel = 0; channel < 3; channel++) {
        output[offset + channel] =
            (output[offset + channel] - whiteContribution).clamp(0, coverage);
      }
      output[offset + 3] = coverage;
      if (coverage == 0) output.fillRange(offset, offset + 4, 0);
    }
  }
  return output;
}
