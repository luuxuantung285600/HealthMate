import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/models/auth_user.dart';
import '../../features/auth/models/account_action_failure.dart';
import '../../features/profile/models/user_profile.dart';
import 'app_routes.dart';

// Only app-owned destinations are accepted, never URLs supplied by a caller.
String _destination(Uri uri) {
  const allowed = {
    AppRoutes.dashboard,
    AppRoutes.journal,
    AppRoutes.quest,
    AppRoutes.chat,
    AppRoutes.profile,
    AppRoutes.premium,
    AppRoutes.support,
    AppRoutes.progress,
    AppRoutes.foodLibrary,
    AppRoutes.personalization,
    AppRoutes.about,
    AppRoutes.privacy,
    AppRoutes.disclaimer,
  };
  final candidate = uri.queryParameters['from'] ?? uri.path;
  return allowed.contains(candidate) ? candidate : AppRoutes.dashboard;
}

String? authRedirect(
  AsyncValue<AuthUser?> session,
  Uri uri, [
  AsyncValue<UserProfile?>? profile,
  AsyncValue<void>? accountAction,
  bool onboardingDeferred = false,
]) {
  final isAuth = uri.path == AppRoutes.auth;
  final isSession = uri.path == AppRoutes.session;
  final isOnboarding = uri.path == AppRoutes.onboarding;
  final isVerification = uri.path == AppRoutes.verifyEmail;
  final destination = _destination(uri);
  if (session.isLoading || session.hasError) {
    return isSession
        ? null
        : Uri(
            path: AppRoutes.session,
            queryParameters: {'from': destination},
          ).toString();
  }
  if (session.value == null) {
    return isAuth
        ? null
        : Uri(
            path: AppRoutes.auth,
            queryParameters: {'from': destination},
          ).toString();
  }
  if (!session.value!.emailVerified) {
    return isVerification
        ? null
        : Uri(
            path: AppRoutes.verifyEmail,
            queryParameters: {'from': destination},
          ).toString();
  }
  if (profile != null) {
    if (profile.isLoading || profile.hasError) {
      return isSession
          ? null
          : Uri(
              path: AppRoutes.session,
              queryParameters: {'from': destination},
            ).toString();
    }
    final currentProfile = profile.value;
    if (currentProfile == null || currentProfile.uid != session.value!.uid) {
      final deletionInProgress = accountAction?.isLoading == true;
      final deletionError = accountAction?.error;
      final deletionNeedsRetry =
          deletionError is AccountActionFailure &&
          deletionError.dataMayBeDeleted;
      if ((deletionInProgress || deletionNeedsRetry) &&
          uri.path == AppRoutes.profile) {
        return null;
      }
      return isSession
          ? null
          : Uri(
              path: AppRoutes.session,
              queryParameters: {'from': destination},
            ).toString();
    }
    if (!currentProfile.isOnboardingComplete) {
      if (isOnboarding) return null;
      if (!onboardingDeferred) {
        return Uri(
          path: AppRoutes.onboarding,
          queryParameters: {'from': destination},
        ).toString();
      }
    }
  }
  return isAuth || isSession || isOnboarding || isVerification
      ? destination
      : null;
}
