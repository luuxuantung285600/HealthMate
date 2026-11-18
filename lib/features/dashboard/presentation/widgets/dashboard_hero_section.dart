import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/design_tokens.dart';

/// Hero section với gradient background và smooth animations
class DashboardHeroSection extends StatelessWidget {
  final String greeting;
  final String dateText;
  final Widget child;

  const DashboardHeroSection({
    required this.greeting,
    required this.dateText,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            greeting,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: DesignTokens.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),

          // Date
          Text(
            dateText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Content
          child,
        ],
      ),
    );
  }
}
