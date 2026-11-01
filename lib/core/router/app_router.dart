import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/email_verification_screen.dart';
import '../../features/auth/presentation/session_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/chatbot/presentation/chat_screen.dart';
import '../../features/daily_quest/presentation/quest_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/support/presentation/support_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/food_library/presentation/food_library_screen.dart';
import '../../features/wellness/presentation/wellness_screen.dart';
import '../../features/profile/presentation/account_information_screen.dart';
import '../../features/profile/presentation/onboarding_screen.dart';
import '../../features/profile/providers/profile_providers.dart';
import '../../features/profile/providers/onboarding_deferred_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/route_error_screen.dart';
import '../config/app_feature_flags.dart';
import 'app_routes.dart';
import 'auth_redirect.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh();
  ref.listen(authSessionProvider, (previous, next) => refresh.refresh());
  ref.listen(userProfileProvider, (previous, next) => refresh.refresh());
  ref.listen(onboardingDeferredProvider, (previous, next) => refresh.refresh());
  ref.listen(appFeatureFlagsProvider, (previous, next) => refresh.refresh());
  ref.listen(
    accountSecurityControllerProvider,
    (previous, next) => refresh.refresh(),
  );
  final router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final authDestination = authRedirect(
        ref.read(authSessionProvider),
        state.uri,
        ref.read(userProfileProvider),
        ref.read(accountSecurityControllerProvider),
        ref.read(onboardingDeferredProvider),
      );
      if (authDestination != null) return authDestination;
      if (!ref.read(appFeatureFlagsProvider).chatbotEnabled &&
          (state.uri.path == AppRoutes.chat ||
              state.uri.path.startsWith('${AppRoutes.chat}/'))) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.session,
        builder: (context, state) => const SessionScreen(),
      ),
      GoRoute(path: '/', redirect: (context, state) => AppRoutes.dashboard),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.journal,
                builder: (context, state) => const JournalScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.quest,
                builder: (context, state) => const QuestScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: AppRoutes.premium,
                builder: (context, state) => const PremiumScreen(),
              ),
              GoRoute(
                path: AppRoutes.support,
                builder: (context, state) => const SupportScreen(),
              ),
              GoRoute(
                path: AppRoutes.foodLibrary,
                builder: (context, state) => const FoodLibraryScreen(),
              ),
              GoRoute(
                path: AppRoutes.personalization,
                builder: (context, state) =>
                    const OnboardingScreen(isEditing: true),
              ),
              GoRoute(
                path: AppRoutes.about,
                builder: (context, state) => const AccountInformationScreen(
                  page: AccountInformationPage.about,
                ),
              ),
              GoRoute(
                path: AppRoutes.privacy,
                builder: (context, state) => const AccountInformationScreen(
                  page: AccountInformationPage.privacy,
                ),
              ),
              GoRoute(
                path: AppRoutes.disclaimer,
                builder: (context, state) => const AccountInformationScreen(
                  page: AccountInformationPage.disclaimer,
                ),
              ),
            ],
          ),
          // Append to preserve existing Quest/Chat/Profile branch indices.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.wellness,
                builder: (context, state) => WellnessScreen(
                  initialTab:
                      int.tryParse(state.uri.queryParameters['tab'] ?? '') ??
                      -1,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const RouteErrorScreen(),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class _AuthRouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}
