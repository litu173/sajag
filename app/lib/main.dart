import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/catalog.dart';
import 'data/demo_repository.dart';
import 'data/repository.dart';
import 'data/supabase_repository.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final catalog = await Catalog.load();

  final SajagRepository repository;
  if (AppConfig.isDemo) {
    repository = await DemoRepository.create(prefs, catalog);
  } else {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseKey);
    final supabase = SupabaseRepository(Supabase.instance.client);
    await supabase.init();
    repository = supabase;
  }

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        catalogProvider.overrideWithValue(catalog),
        repositoryProvider.overrideWithValue(repository),
      ],
      child: const SajagApp(),
    ),
  );
}

class SajagApp extends ConsumerWidget {
  const SajagApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // The in-app text size setting multiplies the system setting, capped to keep layouts intact.
        final media = MediaQuery.of(context);
        final scale = (media.textScaler.scale(1) * settings.textScale).clamp(0.85, 2.0);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
    );
  }
}
