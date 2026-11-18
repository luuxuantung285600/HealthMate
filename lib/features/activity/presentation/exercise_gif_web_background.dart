import 'dart:js_interop';

import 'exercise_background_profiles.dart';

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element createElement(String tag);
  external _Element createElementNS(String namespace, String tag);
  external _Element? getElementById(String id);
  external _Element get head;
  external _Element get body;
}

extension type _Element(JSObject _) implements JSObject {
  external void setAttribute(String name, String value);
  external set innerHTML(String value);
  external set textContent(String value);
  external _Element appendChild(_Element element);
  external _Element? closest(String selector);
  external void remove();
}

_Element? _style;
bool? _dark;
int? _installedRevision;
const _revision = 4;
const _svgId = 'healthmate-exercise-background-defs';
const _styleId = 'healthmate-exercise-background-style';
const _filterId = 'healthmate-exercise-background-v4';

/// HTML-backed cross-origin GIFs cannot be read by CanvasKit. A declarative
/// SVG mask performs border-seeded white-region growth without reading pixels,
/// changing URLs, proxying requests, downloading assets or inverting colors.
/// The app uses one root theme; this rule targets only ExerciseDB GIF images.
void configureExerciseGifWebBackground(bool dark) {
  final installed =
      _document.getElementById(_svgId) != null &&
      _document.getElementById(_styleId) != null;
  if (_dark == dark && _installedRevision == _revision && installed) return;
  if (!dark && _style == null && !installed) {
    _dark = false;
    return;
  }
  if (_style == null || _installedRevision != _revision || !installed) {
    // Flutter hot restart can reset Dart state while leaving injected DOM
    // nodes alive. Replace our old definitions instead of reusing a stale ID.
    _style?.remove();
    _document.getElementById(_styleId)?.remove();
    _document.getElementById(_svgId)?.remove();
    _document
        .getElementById('healthmate-exercise-background')
        ?.closest('svg')
        ?.remove();
    const namespace = 'http://www.w3.org/2000/svg';
    final svg = _document.createElementNS(namespace, 'svg');
    svg.setAttribute('id', _svgId);
    svg.setAttribute('aria-hidden', 'true');
    svg.setAttribute(
      'style',
      'position:absolute;width:0;height:0;pointer-events:none',
    );
    final growth = StringBuffer();
    // GIFs are 180p; one source-pixel step preserves thin figure outlines.
    for (var index = 0; index < 180; index++) {
      growth.write(
        '<feMorphology in="bg$index" operator="dilate" radius="0.00556" result="grow$index"/><feComposite in="grow$index" in2="white" operator="in" result="bg${index + 1}"/>',
      );
    }
    String filter(String id, List<Map<String, Object>> regions) =>
        '<filter id="$id" x="-5%" y="-5%" width="110%" height="110%" primitiveUnits="objectBoundingBox" color-interpolation-filters="sRGB">'
        '<feColorMatrix in="SourceGraphic" type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 100 100 100 0 -293" result="white"/>'
        '<feMorphology in="SourceAlpha" operator="erode" radius="0.00556" result="inner"/>'
        '<feComposite in="SourceAlpha" in2="inner" operator="out" result="border"/>'
        '${_seedMarkup(regions)}'
        '$growth<feComposite in="SourceAlpha" in2="bg180" operator="out" result="subject"/>'
        // Smooth the alpha transition, then unmatte the white-contaminated
        // edge colors. More blur alone would reintroduce a pale outer halo.
        '<feMorphology in="subject" operator="erode" radius="0.00556" result="trim"/>'
        '<feGaussianBlur in="trim" stdDeviation="0.00444" result="smooth"/>'
        '<feComposite in="smooth" in2="subject" operator="in" result="matte"/>'
        '<feColorMatrix in="matte" type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 1 0" result="whiteMatte"/>'
        '<feComposite in="SourceGraphic" in2="whiteMatte" operator="arithmetic" k2="1" k3="1" k4="-1"/>'
        '</filter>';
    svg.innerHTML =
        '<defs>${filter(_filterId, const [])}'
        '${exerciseBackgroundProfiles.entries.map((entry) => filter("$_filterId-${entry.key}", entry.value)).join()}'
        '</defs>';
    _document.body.appendChild(svg);
    _style = _document.createElement('style');
    _style!.setAttribute('id', _styleId);
    _document.head.appendChild(_style!);
  }
  _style!.textContent = dark
      ? 'img[src^="https://static.exercisedb.dev/media/"] { filter: url(#$_filterId); image-rendering: auto; }'
            '${exerciseBackgroundProfiles.keys.map((id) => 'img[src^="https://static.exercisedb.dev/media/$id.gif"] { filter: url(#$_filterId-$id); }').join()}'
      : '';
  _dark = dark;
  _installedRevision = _revision;
}

String _seedMarkup(List<Map<String, Object>> regions) {
  String u(num n) => (n / 180).toStringAsFixed(8);
  final markup = StringBuffer();
  final inputs = <String>['border'];
  for (var i = 0; i < regions.length; i++) {
    final seed = regions[i]['seed'] as List<int>;
    final guards = regions[i]['guards'] as List<List<num>>;
    var previous = 'seed$i';
    markup.write(
      '<feFlood flood-color="white" x="${u(seed[0])}" y="${u(seed[1])}" width="${u(1)}" height="${u(1)}" result="$previous"/>',
    );
    for (var j = 0; j < guards.length; j++) {
      final guard = guards[j];
      final k = guard[2] == 1 ? 100 : -100;
      final offset = .5 - k * guard[3] / 255;
      final name = 'guard${i}x$j';
      markup.write(
        '<feColorMatrix in="SourceGraphic" type="matrix" values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 $k $k $k 0 $offset" x="${u(guard[0])}" y="${u(guard[1])}" width="${u(1)}" height="${u(1)}" result="$name"/><feTile in="$name" result="${name}tile"/><feComposite in="$previous" in2="${name}tile" operator="in" result="${name}seed"/>',
      );
      previous = '${name}seed';
    }
    inputs.add(previous);
  }
  return '$markup<feMerge result="seeds">${inputs.map((name) => '<feMergeNode in="$name"/>').join()}</feMerge><feComposite in="seeds" in2="white" operator="in" result="bg0"/>';
}
