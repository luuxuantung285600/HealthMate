import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../auth/providers/auth_providers.dart';
import '../../food_library/models/food_library_models.dart';
import '../../food_library/presentation/meal_food_sources.dart';
import '../../food_library/providers/food_library_providers.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/models/food_diet.dart';
import '../../nutrition/models/food_avoidance.dart';
import '../../profile/providers/profile_providers.dart';
import '../../nutrition/models/nutrition_failure.dart';
import '../../nutrition/presentation/meal_form_dialog.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../meal_templates/presentation/meal_template_panel.dart';
import '../../meal_drafts/data/meal_draft_store.dart';
import '../../meal_drafts/presentation/draft_picker.dart';
import '../providers/journal_date_provider.dart';

// Shared confirmed entry flow, including account guards and durable draft IDs.
Future<void> openJournalMealForm(
  BuildContext context,
  WidgetRef ref,
  List<FoodCatalogItem> catalog, {
  MealLog? meal,
  FoodCatalogItem? suggestedFood,
  double suggestedGrams = 100,
  String initialSearch = '',
  bool aiAssisted = false,
  DateTime? initialConsumedAt,
  MealLog? duplicateFrom,
  MealType? initialType,
  MealEntryMode initialEntryMode = MealEntryMode.manual,
}) async {
  final uid = ref.read(authSessionProvider).value?.uid;
  if (uid == null) return;
  // Do not silently disable a saved avoidance filter while the profile loads.
  final profile = await ref
      .read(userProfileProvider.future)
      .timeout(const Duration(seconds: 15))
      .catchError((Object _) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Chưa tải được hồ sơ và thực phẩm cần tránh. Hãy thử mở lại bữa ăn.',
              ),
            ),
          );
        }
        return null;
      });
  if (profile == null ||
      !context.mounted ||
      ref.read(authSessionProvider).value?.uid != uid) {
    return;
  }
  final store = ref.read(mealDraftStoreProvider);
  final localSupported = ref.read(privateLocalDataProvider).supported;
  SavedMealDraft? restored;
  if (localSupported) {
    try {
      final saved = (await store.list(
        uid,
      )).where((d) => meal == null || d.mealId == meal.id).toList();
      if (!context.mounted || ref.read(authSessionProvider).value?.uid != uid) {
        return;
      }
      if (saved.isNotEmpty) {
        final choice = await chooseMealDraft(context, saved);
        if (!context.mounted ||
            ref.read(authSessionProvider).value?.uid != uid ||
            choice == null) {
          return;
        }
        restored = saved.where((d) => d.operationId == choice).firstOrNull;
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa đọc được nháp cũ. Dừng mở form để tránh ghi đè; hãy thử lại.',
            ),
          ),
        );
      }
      return;
    }
  }
  final editingId = restored?.mealId ?? meal?.id;
  final operationId =
      restored?.operationId ??
      (editingId == null
          ? ref.read(nutritionRepositoryProvider).newMealId()
          : 'edit-$editingId');
  bool current() =>
      context.mounted &&
      ref.read(authSessionProvider).value?.uid == uid &&
      ref.read(authRepositoryProvider).currentUid == uid;
  Future<void> keep(MealDraft value) async {
    if (!current()) throw StateError('Phiên tài khoản đã thay đổi.');
    await store.put(
      uid,
      SavedMealDraft(
        operationId: operationId,
        mealId: editingId,
        draft: value,
        updatedAt: DateTime.now(),
      ),
    );
  }

  final copy = duplicateFrom?.copyDraft(
    day: initialConsumedAt ?? ref.read(journalDateProvider),
    now: ref.read(currentLocalTimeProvider)(),
  );
  final draft = await showDialog<MealDraft>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AccountBoundDialog(
      child: MealFormDialog(
        initialEntryMode: initialEntryMode,
        initialDraft: restored?.draft,
        onDraftChanged: localSupported ? keep : null,
        onDiscardDraft: localSupported
            ? () => store.remove(uid, operationId)
            : null,
        draftNotice: localSupported
            ? null
            : 'Thiết bị này chưa hỗ trợ giữ nháp khi đóng form.',
        libraryErrorMessage: () =>
            switch (ref.read(foodLibraryControllerProvider).error) {
              FoodLibraryFailure e => e.message,
              _ => null,
            },
        newLibraryId: () => ref.read(foodLibraryRepositoryProvider).newId(),
        onSavePersonalFood: (food) => ref
            .read(foodLibraryControllerProvider.notifier)
            .save(food, create: true),
        saveErrorMessage: () =>
            switch (ref.read(nutritionControllerProvider).error) {
              NutritionFailure failure => failure.message,
              _ => null,
            },
        catalog: catalog,
        initialDiet: FoodDietPreference.fromAnswer(
          profile.personalization?['diet'],
        ),
        avoidance: FoodAvoidance.fromText(
          profile.personalization?['avoidFoods'],
        ),
        templatesBuilder: (items, onUse) =>
            MealTemplatePanel(items: items, onUse: onUse),
        sourcesBuilder: (add, recent, custom, diet, avoidance) =>
            MealFoodSources(
              diet: diet,
              avoidance: avoidance,
              onCatalog: add,
              onRecent: recent,
              onCustom: custom,
              initialSearch: initialSearch,
            ),
        meal: meal,
        initialConsumedAt: copy?.consumedAt ?? initialConsumedAt,
        initialType: copy?.type ?? initialType,
        initialItems: copy?.items ?? const [],
        suggestedFood: suggestedFood,
        suggestedGrams: suggestedGrams,
        initialSearch: initialSearch,
        aiAssisted: aiAssisted || copy?.source == MealSource.aiAssisted,
        onSave: (draft) async {
          if (!context.mounted ||
              ref.read(authSessionProvider).value?.uid != uid) {
            return false;
          }
          // Durable operation ID + payload must reach local disk before Firestore.
          if (localSupported) await keep(draft);
          if (!current()) return false;
          final controller = ref.read(nutritionControllerProvider.notifier);
          final saved = editingId == null
              ? controller.addMeal(draft, operationId: operationId)
              : controller.updateMeal(mealId: editingId, draft: draft);
          final acknowledged = await saved;
          if (acknowledged && localSupported) {
            try {
              await store.remove(uid, operationId);
            } catch (_) {
              // Retained ID makes a stale draft retry safe after an acknowledged create.
              if (context.mounted && current()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Bữa đã lưu; chưa dọn được nháp trên thiết bị. Khôi phục và thử lại giữ cùng mã thao tác.',
                    ),
                  ),
                );
              }
            }
          }
          return acknowledged && current();
        },
      ),
    ),
  );
  if (draft == null ||
      !context.mounted ||
      ref.read(authSessionProvider).value?.uid != uid) {
    return;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(meal == null ? 'Đã lưu bữa ăn.' : 'Đã cập nhật bữa ăn.'),
      ),
    );
  }
}
