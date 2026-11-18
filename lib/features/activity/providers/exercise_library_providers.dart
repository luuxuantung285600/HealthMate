import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/subscription_stream.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/exercise_library_repository.dart';
import '../models/exercise_library_entry.dart';

final exerciseLibraryRepositoryProvider = Provider<ExerciseLibraryRepository>(
  (ref) => FirebaseExerciseLibraryRepository(FirebaseFirestore.instance),
);

final exerciseLibraryProvider =
    StreamProvider.autoDispose<List<ExerciseLibraryEntry>>((ref) {
      final uid = ref.watch(authSessionProvider).value?.uid;
      if (uid == null) return Stream.value(const []);
      return subscriptionStream(
        ref.watch(exerciseLibraryRepositoryProvider).watchEntries(),
      );
    }, retry: (_, _) => null);
