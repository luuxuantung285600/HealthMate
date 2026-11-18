import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/exercise_library_entry.dart';
import 'bundled_exercise_library.dart';

abstract interface class ExerciseLibraryRepository {
  Stream<List<ExerciseLibraryEntry>> watchEntries();
}

typedef ExerciseLibrarySnapshot = ({
  bool confirmed,
  Iterable<ExerciseLibraryEntry> entries,
});

/// A partial local cache cannot prove which bundled entries were archived.
/// Keep listening after a first-confirmation timeout so reconnecting recovers.
Stream<List<ExerciseLibraryEntry>> confirmedExerciseLibraryStream(
  Stream<ExerciseLibrarySnapshot> snapshots, {
  Iterable<ExerciseLibraryEntry> bundled = bundledExerciseLibrary,
  Duration initialTimeout = const Duration(seconds: 12),
}) {
  late StreamController<List<ExerciseLibraryEntry>> output;
  StreamSubscription<ExerciseLibrarySnapshot>? subscription;
  Timer? timer;
  var cancelled = false;
  output = StreamController<List<ExerciseLibraryEntry>>(
    onListen: () {
      timer = Timer(initialTimeout, () {
        if (!cancelled) {
          output.addError(
            TimeoutException(
              'Chưa xác nhận được thư viện trên máy chủ. Cần Internet để nhận thay đổi mới.',
              initialTimeout,
            ),
          );
        }
      });
      subscription = snapshots.listen(
        (snapshot) {
          if (cancelled || !snapshot.confirmed) return;
          timer?.cancel();
          try {
            output.add(mergeExerciseLibrary(bundled, snapshot.entries));
          } catch (error, stack) {
            output.addError(error, stack);
          }
        },
        onError: (Object error, StackTrace stack) {
          timer?.cancel();
          if (!cancelled) output.addError(error, stack);
        },
        onDone: () {
          timer?.cancel();
          if (!cancelled) output.close();
        },
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      cancelled = true;
      timer?.cancel();
      try {
        await subscription?.cancel();
      } catch (_) {
        // Only cleanup errors are suppressed after the consumer has left.
      }
    },
  );
  return output.stream;
}

class FirebaseExerciseLibraryRepository implements ExerciseLibraryRepository {
  FirebaseExerciseLibraryRepository(this.firestore);
  final FirebaseFirestore firestore;

  @override
  Stream<List<ExerciseLibraryEntry>> watchEntries() =>
      confirmedExerciseLibraryStream(
        firestore
            .collection('exercise_library')
            .snapshots(includeMetadataChanges: true)
            .map(
              (snapshot) => (
                confirmed:
                    !snapshot.metadata.isFromCache &&
                    !snapshot.metadata.hasPendingWrites,
                entries: snapshot.docs.map(
                  (doc) => ExerciseLibraryEntry.fromMap(doc.id, doc.data()),
                ),
              ),
            ),
      );
}
