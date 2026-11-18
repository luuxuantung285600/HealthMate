import 'package:flutter/services.dart';

/// Load the bundled font so widget captures exercise real glyphs, not boxes.
Future<void> loadIconFont() =>
    (FontLoader('HealthMateIcons')..addFont(
          rootBundle.load('assets/fonts/healthmate_icons/HealthMateIcons.ttf'),
        ))
        .load();
