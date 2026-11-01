import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Public account layout; it never queries a user's private profile.
class AuthFlowPage extends StatelessWidget {
  const AuthFlowPage({
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = false,
    this.onBack,
    this.scrollController,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;
  final VoidCallback? onBack;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            controller: scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 360
                  ? AppSpacing.md
                  : AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (showBack)
                          IconButton(
                            key: const ValueKey('auth-flow-back'),
                            tooltip: 'Quay lại đăng nhập',
                            onPressed: onBack,
                            icon: const Icon(Icons.arrow_back_rounded),
                          )
                        else
                          ExcludeSemantics(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.spa_outlined,
                                color: colors.onPrimaryContainer,
                                size: 28,
                              ),
                            ),
                          ),
                        Text(
                          'HealthMate',
                          softWrap: false,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthNotice extends StatelessWidget {
  const AuthNotice({required this.message, this.isError = false, super.key});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isError ? colors.errorContainer : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                color: isError ? colors.onErrorContainer : colors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isError
                      ? colors.onErrorContainer
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthEmailAddress extends StatelessWidget {
  const AuthEmailAddress({required this.email, super.key});
  final String email;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.mail_outline_rounded,
          color: Theme.of(context).colorScheme.primary,
          semanticLabel: 'Địa chỉ email',
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(email, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}

class AuthActionLabel extends StatelessWidget {
  const AuthActionLabel({
    required this.label,
    required this.busy,
    this.foregroundColor,
    super.key,
  });
  final String label;
  final bool busy;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: busy,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}
