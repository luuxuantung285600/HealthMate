import 'journal_meal_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/config/app_feature_flags.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/feature_page.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../auth/providers/auth_providers.dart';
import '../../activity/models/activity_log.dart';
import '../../activity/presentation/activity_log_dialog.dart';
import '../../activity/presentation/activity_log_section.dart';
import '../../activity/providers/activity_providers.dart';
import '../../nutrition/presentation/meal_form_dialog.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/presentation/meal_log_section.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../water/models/water_log.dart';
import '../../water/presentation/water_log_dialog.dart';
import '../../water/presentation/water_log_section.dart';
import '../../water/providers/water_providers.dart';
import '../providers/journal_date_provider.dart';
import '../providers/journal_quick_action_provider.dart';
import 'journal_date_selector.dart';
import 'journal_nutrition_overview.dart';
import '../../../core/widgets/details_disclosure.dart';
import '../../reports/presentation/day_review_controls.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  DateTime _timeOnSelectedDate(DateTime selectedDate, {DateTime? source}) {
    final time = source ?? DateTime.now();
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _quickAddWater(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    int amountMl,
  ) async {
    final saved = await ref
        .read(waterControllerProvider.notifier)
        .add(
          WaterLogDraft(
            amountMl: amountMl,
            consumedAt: _timeOnSelectedDate(selectedDate),
          ),
        );
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã ghi nhanh $amountMl ml nước.')),
      );
    }
  }

  Future<void> _scanFood(
    BuildContext context,
    WidgetRef ref,
    List<FoodCatalogItem> catalog,
    DateTime selectedDate,
  ) async {
    if (!ref.read(appFeatureFlagsProvider).foodScannerEnabled) return;
    await openJournalMealForm(
      context,
      ref,
      catalog,
      initialEntryMode: MealEntryMode.photo,
      initialConsumedAt: _timeOnSelectedDate(selectedDate),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    MealLog meal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bữa ăn?'),
        content: Text(
          'Bữa ${meal.type.label.toLowerCase()} này sẽ bị xóa khỏi nhật ký.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await ref
        .read(nutritionControllerProvider.notifier)
        .deleteMeal(meal.id);
    if (deleted && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa bữa ăn.')));
    }
  }

  Future<void> _openWaterForm(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate, {
    WaterLog? log,
  }) async {
    final uid = ref.read(authSessionProvider).value?.uid;
    final draft = await showDialog<WaterLogDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccountBoundDialog(
        child: WaterLogDialog(
          selectedDate: selectedDate,
          log: log,
          onSave: (draft) {
            if (!context.mounted ||
                ref.read(authSessionProvider).value?.uid != uid) {
              return Future.value(false);
            }
            final controller = ref.read(waterControllerProvider.notifier);
            return log == null
                ? controller.add(draft)
                : controller.update(log.id, draft);
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
          content: Text(
            log == null ? 'Đã ghi nước uống.' : 'Đã cập nhật nước uống.',
          ),
        ),
      );
    }
  }

  Future<void> _openActivityForm(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate, {
    ActivityLog? log,
  }) async {
    final uid = ref.read(authSessionProvider).value?.uid;
    final draft = await showDialog<ActivityLogDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccountBoundDialog(
        child: ActivityLogDialog(
          selectedDate: selectedDate,
          log: log,
          onSave: (draft) {
            if (!context.mounted ||
                ref.read(authSessionProvider).value?.uid != uid) {
              return Future.value(false);
            }
            final controller = ref.read(activityControllerProvider.notifier);
            return log == null
                ? controller.add(draft)
                : controller.update(log.id, draft);
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
          content: Text(
            log == null ? 'Đã ghi hoạt động.' : 'Đã cập nhật hoạt động.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String title,
    Future<bool> Function() action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Dữ liệu này sẽ bị xóa khỏi nhật ký.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) await action();
  }

  Future<void> _pickJournalDate(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Ngày nhật ký',
    );
    if (date != null) ref.read(journalDateProvider.notifier).select(date);
  }

  Future<void> _openQuickAction(
    BuildContext context,
    WidgetRef ref,
    JournalQuickAction action,
    List<FoodCatalogItem> catalog,
    DateTime selectedDate,
  ) async {
    switch (action) {
      case JournalQuickAction.addMeal:
        await openJournalMealForm(
          context,
          ref,
          catalog,
          initialConsumedAt: _timeOnSelectedDate(selectedDate),
        );
      case JournalQuickAction.scanFood:
        await _scanFood(context, ref, catalog, selectedDate);
      case JournalQuickAction.addWater:
        await _openWaterForm(context, ref, selectedDate);
      case JournalQuickAction.addActivity:
        await _openActivityForm(context, ref, selectedDate);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final selectedDate = ref.watch(journalDateProvider);
    final catalogState = ref.watch(foodCatalogProvider);
    final mealsState = ref.watch(mealLogsProvider(selectedDate));
    final action = ref.watch(nutritionControllerProvider);
    final dateKey = localDateKey(selectedDate);
    final waterState = ref.watch(waterLogsProvider(dateKey));
    final waterAction = ref.watch(waterControllerProvider);
    final activityState = ref.watch(activityLogsProvider(dateKey));
    final activityAction = ref.watch(activityControllerProvider);
    final catalog = catalogState.value ?? const <FoodCatalogItem>[];
    final meals = mealsState.value ?? const <MealLog>[];
    ref.listen<JournalQuickAction?>(journalQuickActionProvider, (
      previous,
      next,
    ) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final action = ref.read(journalQuickActionProvider.notifier).take();
        if (action == null) return;
        _openQuickAction(context, ref, action, catalog, selectedDate);
      });
    });

    return FeaturePage(
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      headerGap: 19,
      showProfileAvatar: true,
      key: const ValueKey('journal-screen'),
      title: 'Nhật ký',
      headerAction: IconButton(
        key: const ValueKey('open-meal-drafts'),
        tooltip: 'Bản nháp bữa ăn',
        onPressed: () => openJournalMealForm(
          context,
          ref,
          catalog,
          initialConsumedAt: _timeOnSelectedDate(selectedDate),
        ),
        icon: const Icon(Icons.drafts_outlined),
      ),
      subtitle: '',
      compactHeader: true,
      children: [
        JournalDateSelector(
          date: selectedDate,
          onPrevious: ref.read(journalDateProvider.notifier).previousDay,
          onNext: selectedDate.isBefore(localDateOnly(DateTime.now()))
              ? ref.read(journalDateProvider.notifier).nextDay
              : null,
          onPick: () => _pickJournalDate(context, ref, selectedDate),
        ),
        const SizedBox(height: AppSpacing.md),
        if (action.isLoading ||
            waterAction.isLoading ||
            activityAction.isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Text('Đang lưu thay đổi…'),
          ),
        JournalNutritionOverview(
          day: selectedDate,
          meals: mealsState,
          compact: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          key: const ValueKey('journal-add-meal'),
          onPressed: action.isLoading
              ? null
              : () => openJournalMealForm(
                  context,
                  ref,
                  catalog,
                  initialConsumedAt: _timeOnSelectedDate(selectedDate),
                ),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm bữa ăn'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ghi cho ngày ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
          key: const ValueKey('journal-entry-date'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        MealLogSection(
          compact: true,
          onOpenDrafts: () => openJournalMealForm(
            context,
            ref,
            catalog,
            initialConsumedAt: _timeOnSelectedDate(selectedDate),
          ),
          onAddForType: (type) => openJournalMealForm(
            context,
            ref,
            catalog,
            initialType: type,
            initialConsumedAt: _timeOnSelectedDate(selectedDate),
          ),
          showScanner: ref.watch(appFeatureFlagsProvider).foodScannerEnabled,
          catalogState: catalogState,
          mealsState: mealsState,
          catalog: catalog,
          meals: meals,
          action: action,
          onAdd: action.isLoading
              ? null
              : () => openJournalMealForm(
                  context,
                  ref,
                  catalog,
                  initialConsumedAt: _timeOnSelectedDate(selectedDate),
                ),
          onScan: action.isLoading
              ? null
              : () => _scanFood(context, ref, catalog, selectedDate),
          onEdit: (meal) =>
              openJournalMealForm(context, ref, catalog, meal: meal),
          onDuplicate: (meal) => openJournalMealForm(
            context,
            ref,
            catalog,
            initialConsumedAt: _timeOnSelectedDate(
              selectedDate,
              source: meal.consumedAt,
            ),
            duplicateFrom: meal,
          ),
          onDelete: (meal) => _delete(context, ref, meal),
          onRetry: () {
            ref.invalidate(foodCatalogProvider);
            ref.invalidate(mealLogsProvider(selectedDate));
          },
          onDismissError: ref
              .read(nutritionControllerProvider.notifier)
              .clearError,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('open-day-review'),
            onPressed: () => openDayReview(context, selectedDate),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Hoàn tất nhật ký'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        WaterLogSection(
          state: waterState,
          action: waterAction,
          onAdd: () => _openWaterForm(context, ref, selectedDate),
          onQuickAdd: (amount) =>
              _quickAddWater(context, ref, selectedDate, amount),
          onEdit: (log) => _openWaterForm(context, ref, selectedDate, log: log),
          onDelete: (log) => _confirmDelete(
            context,
            'Xóa lần uống nước?',
            () => ref.read(waterControllerProvider.notifier).delete(log.id),
          ),
          onRetry: () => ref.invalidate(waterLogsProvider(dateKey)),
          onDismissError: ref.read(waterControllerProvider.notifier).clearError,
        ),
        const SizedBox(height: AppSpacing.md),
        DetailsDisclosure(
          key: const ValueKey('journal-activity-details'),
          title: 'Vận động',
          builder: (_) => ActivityLogSection(
            state: activityState,
            action: activityAction,
            onAdd: () => _openActivityForm(context, ref, selectedDate),
            onEdit: (log) =>
                _openActivityForm(context, ref, selectedDate, log: log),
            onDelete: (log) => _confirmDelete(
              context,
              'Xóa hoạt động?',
              () =>
                  ref.read(activityControllerProvider.notifier).delete(log.id),
            ),
            onRetry: () => ref.invalidate(activityLogsProvider(dateKey)),
            onDismissError: ref
                .read(activityControllerProvider.notifier)
                .clearError,
          ),
        ),
      ],
    );
  }
}
