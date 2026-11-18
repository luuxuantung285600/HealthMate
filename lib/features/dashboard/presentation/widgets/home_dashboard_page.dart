import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/home_palette.dart';

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({
    required this.header,
    required this.hero,
    required this.children,
    super.key,
  });
  final Widget header, hero;
  final List<Widget> children;

  Widget _content(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpacing.contentWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: child,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Material(
    color: HomePalette.background(context),
    child: CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: HomePalette.background(context),
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          toolbarHeight: 60 * MediaQuery.textScalerOf(context).scale(1),
          titleSpacing: 0,
          title: _content(header),
        ),
        SliverToBoxAdapter(
          child: _content(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                hero,
                const SizedBox(height: 24),
                ...children,
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
