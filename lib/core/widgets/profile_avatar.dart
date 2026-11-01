import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../router/app_routes.dart';

class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({this.onTap, this.size = 48, super.key});
  final VoidCallback? onTap;
  final double size;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userProfileProvider).value?.displayName.trim() ?? '';
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Mở không gian cá nhân',
      child: Semantics(
        label: 'Mở không gian cá nhân',
        button: true,
        child: InkResponse(
          key: const ValueKey('profile-avatar'),
          onTap: onTap ?? () => context.go(AppRoutes.profile),
          radius: 28,
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: CircleAvatar(
                radius: size / 2 - 2,
                backgroundColor: scheme.primary.withValues(alpha: .10),
                foregroundColor: scheme.primary,
                child: Text(
                  name.isEmpty ? 'H' : name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
