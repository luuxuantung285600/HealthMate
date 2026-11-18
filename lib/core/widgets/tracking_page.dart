import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'profile_avatar.dart';

/// A pinned, accessible heading shared by tracking and report screens.
class TrackingPage extends StatelessWidget {
  const TrackingPage({
    required this.header,
    required this.children,
    this.headerHeight = 72,
    this.showProfileAvatar = true,
    super.key,
  });
  final Widget header;
  final List<Widget> children;
  final double headerHeight;
  final bool showProfileAvatar;
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          toolbarHeight: headerHeight * scale,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleSpacing: 20,
          title: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentWidth,
              ),
              child: Row(
                children: [
                  if (showProfileAvatar) ...[
                    const ProfileAvatar(),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: DefaultTextStyle.merge(
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      child: header,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.contentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
