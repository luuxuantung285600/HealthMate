import '../../../core/utils/subscription_stream.dart';
import '../../../core/data/user_data_revision.dart';
import '../../../core/data/private_data_changes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/food_library_repository.dart';
import '../data/firebase_food_library_repository.dart';
import '../models/food_library_models.dart';

final foodLibraryRepositoryProvider = Provider<FoodLibraryRepository>(
  (ref) => FirebaseFoodLibraryRepository(FirebaseFirestore.instance),
);
final foodLibraryProvider = StreamProvider.autoDispose
    .family<LibraryPage, ({FoodSourceKind kind, int limit})>((ref, key) {
      final uid = ref.watch(authSessionProvider.select((s) => s.value?.uid));
      if (uid == null) {
        return Stream.error(
          const FoodLibraryFailure('Hãy đăng nhập để xem thư viện.'),
        );
      }
      return subscriptionStream(
        ref
            .watch(foodLibraryRepositoryProvider)
            .watch(uid, key.kind, limit: key.limit),
      );
    }, retry: (_, _) => null);
final libraryEntryProvider = FutureProvider.autoDispose
    .family<LibraryEntry?, ({FoodSourceKind kind, String id})>((ref, key) {
      final source = switch (key.kind) {
        FoodSourceKind.custom => 'custom_foods',
        FoodSourceKind.recipe => 'recipes',
        FoodSourceKind.catalog => null,
      };
      if (source != null) {
        watchPrivateScope(ref, privateLibraryScope(source, key.id));
        ref.watch(
          userDataRevisionProvider.select((state) => state.value?[source]),
        );
      }
      final uid = ref.watch(authSessionProvider.select((s) => s.value?.uid));
      if (uid == null) {
        throw const FoodLibraryFailure('Hãy đăng nhập để xem nguồn món.');
      }
      return ref
          .watch(foodLibraryRepositoryProvider)
          .load(uid, key.kind, key.id);
    }, retry: (_, _) => null);
final foodLibraryControllerProvider =
    NotifierProvider<FoodLibraryController, AsyncValue<void>>(
      FoodLibraryController.new,
    );

class FoodLibraryController extends Notifier<AsyncValue<void>> {
  int _generation = 0;
  @override
  AsyncValue<void> build() {
    ref.watch(authSessionProvider.select((s) => s.value?.uid));
    _generation++;
    return const AsyncData(null);
  }

  Future<bool> _run(
    Future<void> Function(FoodLibraryRepository repository, String uid)
    operation,
  ) async {
    if (state.isLoading) return false;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return false;
    final generation = _generation;
    bool current() =>
        ref.mounted &&
        generation == _generation &&
        ref.read(authSessionProvider).value?.uid == uid;
    state = const AsyncLoading();
    try {
      await operation(ref.read(foodLibraryRepositoryProvider), uid);
      if (!current()) return false;
      ref.invalidate(libraryEntryProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      if (current()) {
        state = AsyncError(
          e is FoodLibraryFailure ? e : const FoodLibraryFailure(),
          stack,
        );
      }
      return false;
    }
  }

  Future<bool> save(LibraryEntry entry, {required bool create}) =>
      _run((repository, uid) => repository.save(uid, entry, create: create));
  Future<bool> delete(LibraryEntry entry) =>
      _run((repository, uid) => repository.delete(uid, entry.kind, entry.id));
}
