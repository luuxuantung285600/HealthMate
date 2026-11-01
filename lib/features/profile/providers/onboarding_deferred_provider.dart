import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';

/// Skip is a navigation choice, never a fabricated completed health profile.
/// Changing UID or logging out resets the in-memory choice.
final onboardingDeferredProvider = NotifierProvider<OnboardingDeferred, bool>(
  OnboardingDeferred.new,
);

class OnboardingDeferred extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(authSessionProvider.select((session) => session.value?.uid));
    return false;
  }

  void defer() => state = true;
}
