import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:maternal_infant_care/core/constants/env.dart';
import 'package:maternal_infant_care/core/theme/app_theme.dart';
import 'package:maternal_infant_care/core/utils/notification_service.dart';
import 'package:maternal_infant_care/core/utils/reminder_bootstrap_service.dart';
import 'package:maternal_infant_care/data/local/hive_adapters.dart';
import 'package:maternal_infant_care/presentation/pages/splash_page.dart';
import 'package:maternal_infant_care/presentation/viewmodels/language_provider.dart';
import 'package:maternal_infant_care/core/services/centralized_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Handle Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack: ${details.stack}');
  };

  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Platform Error: $error');
    print('Stack: $stack');
    return true;
  };

  try {
    await dotenv.load(fileName: '.env');
    if (Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
      );
    } else {
      print('Supabase env missing. Check SUPABASE_URL and SUPABASE_ANON_KEY.');
    }

    await Hive.initFlutter();
    await HiveAdapters.registerAdapters();

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      print('Main: timezone initialized to Asia/Kolkata');
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
      print('Main: timezone fallback to UTC. Error: $e');
    }

    try {
      await NotificationService.initialize();
      await ReminderBootstrapService.restorePendingSchedules();
    } catch (e) {
      print('Notification service initialization failed: $e');
      // Continue without notifications
    }

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e, stackTrace) {
    print('Initialization error: $e');
    print('Stack trace: $stackTrace');
    // Still run the app even if initialization fails
  }

  // Preload translations before building UI
  await AppTranslations.loadTranslations();

  runApp(
    const ProviderScope(
      child: VatsalyaApp(),
    ),
  );
}

class VatsalyaApp extends ConsumerWidget {
  const VatsalyaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // Watch app language (but don't set device locale)
    ref.watch(languageProvider);

    return MaterialApp(
      title: 'Vatsalya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Don't set locale - keep device language intact
      // Only use language provider for content translation
      supportedLocales:
          AppLanguage.values.map((lang) => Locale(lang.code)).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashPage(),
    );
  }
}
