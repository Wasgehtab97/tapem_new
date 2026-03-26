import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/gym_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/workout_lifecycle_service.dart';
import 'core/utils/logger.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/features/profile/providers/theme_provider.dart';
import 'presentation/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(
    AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty,
    'SUPABASE_URL and SUPABASE_ANON_KEY must be set via --dart-define',
  );

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    debug: false,
  );

  final prefs = await SharedPreferences.getInstance();
  AppLogger.init();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const TapemApp(),
    ),
  );
}

class TapemApp extends ConsumerWidget {
  const TapemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the sync service alive for the entire app lifetime so it retries
    // pending/failed sessions every 30 s regardless of which screen is shown.
    ref.watch(syncNotifierProvider);

    // Keep the lifecycle observer alive for the entire app lifetime so it
    // can detect foreground returns and auto-finish stale workout sessions.
    ref.watch(workoutLifecycleProvider);

    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(activeThemeProvider);
    final locale = ref.watch(localeNotifierProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
