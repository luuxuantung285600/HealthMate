import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/reference_palette.dart';
import 'features/profile/providers/profile_providers.dart';
import 'shared/providers/theme_mode_provider.dart';
import 'core/config/admin_runtime.dart';
import 'core/widgets/admin_access_gate.dart';
import 'features/wellness/providers/wellness_providers.dart';
import 'features/premium/providers/play_billing_providers.dart';

class HealthMateApp extends ConsumerWidget {
  const HealthMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps profile creation tied to the authenticated session, not a screen visit.
    ref.watch(profileBootstrapProvider);
    ref.watch(adminDirectorySyncProvider);
    ref.watch(wellnessBootstrapProvider);
    ref.watch(playBillingControllerProvider);
    return MaterialApp.router(
      title: 'HealthMate',
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => AppCanvas(
        child: AdminAccessGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
