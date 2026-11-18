import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/information_button.dart';
import '../models/daily_log_failure.dart';

class DailyLogSectionCard<T> extends StatelessWidget {
  const DailyLogSectionCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.description,
    required this.addKey,
    required this.addLabel,
    required this.state,
    required this.action,
    required this.onAdd,
    required this.onRetry,
    required this.onDismissError,
    required this.emptyText,
    required this.children,
    this.entryActions,
    this.accent,
    super.key,
  });

  final IconData icon;
  final Color? accent;
  final String title;
  final String summary;
  final String description;
  final Key addKey;
  final String addLabel;
  final AsyncValue<List<T>> state;
  final AsyncValue<void> action;
  final VoidCallback onAdd;
  final VoidCallback onRetry;
  final VoidCallback onDismissError;
  final String emptyText;
  final List<Widget> children;
  final Widget? entryActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: accent ?? theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                InformationButton(title: 'Về $title', message: description),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(summary, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: addKey,
              style: accent == null
                  ? null
                  : FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: theme.brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    ),
              onPressed: action.isLoading ? null : onAdd,
              icon: const Icon(AppIcons.plus),
              label: Text(addLabel),
            ),
            if (action.isLoading) ...[
              const SizedBox(height: AppSpacing.sm),
              const LinearProgressIndicator(),
            ],
            if (action.error case final DailyLogFailure error) ...[
              const SizedBox(height: AppSpacing.sm),
              Material(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                child: ListTile(
                  leading: const Icon(AppIcons.circleAlert),
                  title: Text(error.message),
                  trailing: IconButton(
                    onPressed: onDismissError,
                    tooltip: 'Đóng',
                    icon: const Icon(AppIcons.x),
                  ),
                ),
              ),
            ],
            const Divider(height: AppSpacing.xl),
            if (state.isLoading)
              const Row(
                children: [
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('Đang tải nhật ký…')),
                ],
              )
            else if (state.hasError)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.error is DailyLogFailure
                        ? (state.error! as DailyLogFailure).message
                        : 'Chưa thể tải nhật ký.',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(AppIcons.refreshCw),
                    label: const Text('Thử lại'),
                  ),
                ],
              )
            else ...[
              ?entryActions,
              if (children.isEmpty) Text(emptyText),
              ...children,
            ],
          ],
        ),
      ),
    );
  }
}

class DailyLogEntryMenu extends StatelessWidget {
  const DailyLogEntryMenu({
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'edit', child: Text('Sửa')),
      PopupMenuItem(value: 'delete', child: Text('Xóa')),
    ],
  );
}
