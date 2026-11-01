import 'package:flutter/material.dart';
import '../../../../core/widgets/app_card.dart';

class MfpMealCard extends StatelessWidget {
  const MfpMealCard({
    required this.icon,
    required this.mealName,
    required this.onLogTap,
    this.summary,
    this.recentMealHint,
    this.onQuickAddTap,
    this.onView,
    super.key,
  });
  final IconData icon;
  final String mealName;
  final String? summary, recentMealHint;
  final VoidCallback? onLogTap, onQuickAddTap, onView;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
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
            onPressed: onLogTap,
            tooltip: 'Thêm ${mealName.toLowerCase()}',
            icon: const Icon(Icons.add_circle_outline_rounded),
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
      ),
    );
  }
}
