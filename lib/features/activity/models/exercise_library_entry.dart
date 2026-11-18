import '../../nutrition/models/food_catalog_search.dart'
    show normalizeFoodSearch;

const exerciseRegions = <String, String>{
  'chest': 'Ngực',
  'back': 'Lưng',
  'legs': 'Chân và mông',
  'shoulders': 'Vai',
  'arms': 'Tay',
  'core': 'Bụng và thân giữa',
  'cardio': 'Tim mạch',
};

const exerciseEquipments = <String, String>{
  'bodyweight': 'Tự trọng',
  'dumbbell': 'Tạ đơn',
  'barbell': 'Tạ đòn',
  'cable': 'Cáp kéo',
  'machine': 'Máy tập',
  'band': 'Dây kháng lực',
  'kettlebell': 'Tạ chuông',
};

/// HealthMate editorial content. Only the stable identifier refers to a provider;
/// rotating provider media URLs and provider instructions are never persisted.
class ExerciseLibraryEntry {
  const ExerciseLibraryEntry({
    required this.id,
    required this.sourceId,
    required this.name,
    required this.region,
    required this.equipment,
    required this.target,
    required this.steps,
    required this.easier,
    this.sourceProvider = 'exercisedb',
    this.isActive = true,
  });

  final String id, sourceId, name, region, equipment, target, easier;
  final String sourceProvider;
  final List<String> steps;
  final bool isActive;

  String get mediaFormat => 'GIF';
  String get mediaCredit => 'ExerciseDB · AscendAPI · 180p · Bản kiểm thử';

  factory ExerciseLibraryEntry.fromMap(String id, Map<String, dynamic> data) {
    String text(String key, int max) {
      final value = data[key];
      if (value is! String || value.trim().isEmpty || value.length > max) {
        throw FormatException('Thông tin bài tập không hợp lệ: $key.');
      }
      return value.trim();
    }

    final sourceProvider = data['sourceProvider'] ?? 'exercisedb';
    final sourceId = text('sourceId', 7);
    final region = text('region', 20), equipment = text('equipment', 20);
    final steps = data['steps'];
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(id) ||
        sourceProvider != 'exercisedb' ||
        !RegExp(r'^[a-zA-Z0-9]{7}$').hasMatch(sourceId) ||
        !exerciseRegions.containsKey(region) ||
        !exerciseEquipments.containsKey(equipment) ||
        data['schemaVersion'] != 1 ||
        data['isActive'] is! bool ||
        steps is! List ||
        steps.length < 2 ||
        steps.length > 6 ||
        steps.any((v) => v is! String || v.trim().isEmpty || v.length > 400)) {
      throw const FormatException('Dữ liệu bài tập không hợp lệ.');
    }
    return ExerciseLibraryEntry(
      id: id,
      sourceId: sourceId,
      sourceProvider: sourceProvider as String,
      name: text('name', 120),
      region: region,
      equipment: equipment,
      target: text('target', 160),
      steps: List<String>.unmodifiable(steps.cast<String>()),
      easier: text('easier', 400),
      isActive: data['isActive'] as bool,
    );
  }
}

/// Includes inactive overrides before filtering, so an archived bundled entry
/// cannot reappear through a fallback. A hard deleted override restores its base.
List<ExerciseLibraryEntry> mergeExerciseLibrary(
  Iterable<ExerciseLibraryEntry> bundled,
  Iterable<ExerciseLibraryEntry> overrides,
) {
  final entries = {for (final e in bundled) e.id: e};
  for (final e in overrides) {
    entries[e.id] = e;
  }
  return List.unmodifiable(
    entries.values.where((e) => e.isActive && e.sourceProvider == 'exercisedb'),
  );
}

List<ExerciseLibraryEntry> filterExerciseLibrary(
  List<ExerciseLibraryEntry> entries, {
  String query = '',
  String? region,
  String? equipment,
}) {
  final terms = normalizeFoodSearch(
    query,
  ).split(' ').where((s) => s.isNotEmpty);
  return entries
      .where((e) {
        if (!e.isActive ||
            e.sourceProvider != 'exercisedb' ||
            (region != null && e.region != region) ||
            (equipment != null && e.equipment != equipment)) {
          return false;
        }
        final text = normalizeFoodSearch(
          '${e.name} ${e.target} ${exerciseRegions[e.region]} ${exerciseEquipments[e.equipment]}',
        );
        return terms.every(text.contains);
      })
      .toList(growable: false);
}
