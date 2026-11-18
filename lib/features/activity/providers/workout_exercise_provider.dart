import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exercise_library_entry.dart';
import 'exercise_library_providers.dart';

/// Reviewed exact variants only. Similar names can describe different movements.
const workoutExerciseIds = {
  'wall_push': 'edb-NCmbLCw',
  'glute_bridge': 'edb-u0cNiij',
};

final workoutExerciseProvider = Provider.autoDispose
    .family<ExerciseLibraryEntry?, String>((ref, movementId) {
      final id = workoutExerciseIds[movementId];
      if (id == null) return null;
      // The confirmed library includes admin overrides and removes archived rows.
      return ref
          .watch(exerciseLibraryProvider)
          .value
          ?.where((entry) => entry.id == id && entry.isActive)
          .firstOrNull;
    });
