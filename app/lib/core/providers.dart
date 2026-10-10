import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../data/models.dart';
import '../data/repository.dart';
import 'location.dart';

// Overridden in main() once async initialisation is done.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('prefsProvider'));
final catalogProvider = Provider<Catalog>((ref) => throw UnimplementedError('catalogProvider'));
final repositoryProvider = Provider<SajagRepository>((ref) => throw UnimplementedError('repositoryProvider'));
final locationServiceProvider = Provider<LocationService>((ref) => const LocationService());

final authStageProvider = StreamProvider<AuthStage>((ref) async* {
  final repo = ref.watch(repositoryProvider);
  yield repo.currentStage;
  yield* repo.authStage;
});

// ---------------------------------------------------------------- user settings
class SettingsState {
  const SettingsState({
    required this.locale,
    required this.textScale,
    required this.onboarded,
    this.themeMode = ThemeMode.system,
  });
  final Locale locale;
  final double textScale;
  final bool onboarded;
  final ThemeMode themeMode;

  SettingsState copyWith({Locale? locale, double? textScale, bool? onboarded, ThemeMode? themeMode}) => SettingsState(
    locale: locale ?? this.locale,
    textScale: textScale ?? this.textScale,
    onboarded: onboarded ?? this.onboarded,
    themeMode: themeMode ?? this.themeMode,
  );
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _kLocale = 'settings.locale';
  static const _kScale = 'settings.textScale';
  static const _kOnboarded = 'settings.onboarded';
  static const _kTheme = 'settings.theme';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  SettingsState build() {
    final prefs = ref.watch(prefsProvider);
    return SettingsState(
      locale: Locale(prefs.getString(_kLocale) ?? 'bn'),
      textScale: prefs.getDouble(_kScale) ?? 1.0,
      onboarded: prefs.getBool(_kOnboarded) ?? false,
      themeMode: ThemeMode.values.asNameMap()[prefs.getString(_kTheme)] ?? ThemeMode.system,
    );
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
    unawaited(_prefs.setString(_kLocale, locale.languageCode));
  }

  void setTextScale(double scale) {
    state = state.copyWith(textScale: scale);
    unawaited(_prefs.setDouble(_kScale, scale));
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    unawaited(_prefs.setString(_kTheme, mode.name));
  }

  void completeOnboarding() {
    state = state.copyWith(onboarded: true);
    unawaited(_prefs.setBool(_kOnboarded, true));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

// ---------------------------------------------------------------- location
final locationAccessProvider = FutureProvider<LocationAccess>((ref) => ref.watch(locationServiceProvider).check());

/// Approximate position for centring the feed and map. Null while unavailable.
final approximateFixProvider = FutureProvider<Fix?>((ref) async {
  final access = await ref.watch(locationAccessProvider.future);
  if (access != LocationAccess.granted) return null;
  try {
    return await ref.read(locationServiceProvider).approximate();
  } on Exception {
    return null;
  }
});

// ---------------------------------------------------------------- shared user data
final myProfileProvider = FutureProvider<Profile>((ref) {
  ref.watch(authStageProvider);
  return ref.watch(repositoryProvider).myProfile();
});

final myBadgesProvider = FutureProvider<List<EarnedBadge>>((ref) {
  ref.watch(myProfileProvider);
  return ref.watch(repositoryProvider).myBadges();
});

final myReportsProvider = FutureProvider<List<Report>>((ref) {
  ref.watch(authStageProvider);
  return ref.watch(repositoryProvider).myReports();
});

final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) => ref.watch(repositoryProvider).notifications(),
);

final awarenessProvider = FutureProvider<List<AwarenessPost>>((ref) => ref.watch(repositoryProvider).awareness());

class FollowingNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ref.watch(repositoryProvider).myFollowing();

  Future<void> toggle(String aliasId) async {
    final current = state.value ?? const <String>{};
    final follow = !current.contains(aliasId);
    state = AsyncData(follow ? {...current, aliasId} : ({...current}..remove(aliasId)));
    try {
      await ref.read(repositoryProvider).setFollowing(aliasId, following: follow);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final followingProvider = AsyncNotifierProvider<FollowingNotifier, Set<String>>(FollowingNotifier.new);

/// Called after anything that changes the user's stats (posting, confirming, ...).
final myAccountProvider = FutureProvider.autoDispose<AccountInfo>((ref) {
  ref.watch(authStageProvider);
  return ref.watch(repositoryProvider).myAccount();
});

void refreshMe(WidgetRef ref) {
  ref
    ..invalidate(myProfileProvider)
    ..invalidate(myAccountProvider)
    ..invalidate(myReportsProvider)
    ..invalidate(notificationsProvider);
}
