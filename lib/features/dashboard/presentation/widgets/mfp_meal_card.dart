import '../../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_card.dart';

class MfpMealCard extends StatelessWidget {
  const MfpMealCard({
    required this.icon,
    required this.mealName,
    required this.onLogTap,
    this.accent,
    this.summary,
    this.recentMealHint,
    this.onQuickAddTap,
    this.onView,
    this.embedded = false,
    super.key,
  });
  final IconData icon;
  final Color? accent;
  final String mealName;
  final String? summary, recentMealHint;
  final VoidCallback? onLogTap, onQuickAddTap, onView;
  final bool embedded;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Row(
      children: [
        Icon(icon, color: accent ?? theme.colorScheme.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: onView ?? onLogTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary ?? 'Chưa ghi món',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          color: accent,
          onPressed: onLogTap,
          tooltip: 'Thêm ${mealName.toLowerCase()}',
          icon: const Icon(AppIcons.circlePlus),
        ),
        if (recentMealHint != null && onQuickAddTap != null)
          PopupMenuButton<String>(
            tooltip: 'Tùy chọn $mealName',
            onSelected: (_) => onQuickAddTap!(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'copy',
                child: Text('Ghi lại bữa hôm trước: $recentMealHint'),
              ),
            ],
          ),
      ],
    );
    const padding = EdgeInsets.fromLTRB(14, 8, 6, 8);
    return embedded
        ? Padding(padding: padding, child: content)
        : AppCard(padding: padding, child: content);
  }
}
