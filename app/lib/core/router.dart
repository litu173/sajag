import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/auth/identity_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/pending_screen.dart';
import '../features/auth/phone_screen.dart';
import '../features/create/create_report_flow.dart';
import '../features/feed/feed_screen.dart';
import '../features/map/map_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/location_gate_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/public_profile_screen.dart';
import '../features/report/report_detail_screen.dart';
import '../features/shell/home_shell.dart';
import 'location.dart';
import 'providers.dart';

class SplashDone extends Notifier<bool> {
  @override
  bool build() => false;
  void complete() => state = true;
}

final splashDoneProvider = NotifierProvider<SplashDone, bool>(SplashDone.new);

const _authFlow = {'/auth/phone', '/auth/otp'};
const _entryRoutes = {
  '/splash',
  '/welcome',
  '/auth/phone',
  '/auth/otp',
  '/auth/identity',
  '/auth/pending',
  '/location',
};

/// Pure routing decision, unit-tested in test/router_test.dart.
String? decideRedirect({
  required String location,
  required bool splashDone,
  required bool onboarded,
  required AuthStage stage,
  required LocationAccess? locationAccess,
}) {
  String? goTo(String target) => location == target ? null : target;

  if (!splashDone) return goTo('/splash');
  if (!onboarded) return goTo('/welcome');
  switch (stage) {
    case AuthStage.signedOut:
      return _authFlow.contains(location) ? null : '/auth/phone';
    case AuthStage.needsIdentity:
      return goTo('/auth/identity');
    case AuthStage.pendingReview:
      return goTo('/auth/pending');
    case AuthStage.ready:
      if (locationAccess != null && locationAccess != LocationAccess.granted) return goTo('/location');
      return _entryRoutes.contains(location) ? '/feed' : null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  void bump(Object? _, Object? _) => refresh.value++;
  ref
    ..listen(splashDoneProvider, bump)
    ..listen(settingsProvider.select((s) => s.onboarded), bump)
    ..listen(authStageProvider, bump)
    ..listen(locationAccessProvider, bump);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => decideRedirect(
      location: state.matchedLocation,
      splashDone: ref.read(splashDoneProvider),
      onboarded: ref.read(settingsProvider).onboarded,
      stage: ref.read(authStageProvider).value ?? ref.read(repositoryProvider).currentStage,
      locationAccess: ref.read(locationAccessProvider).value,
    ),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/auth/phone', builder: (_, _) => const PhoneScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) => OtpScreen(phone: state.uri.queryParameters['phone'] ?? ''),
      ),
      GoRoute(path: '/auth/identity', builder: (_, _) => const IdentityScreen()),
      GoRoute(path: '/auth/pending', builder: (_, _) => const PendingScreen()),
      GoRoute(path: '/location', builder: (_, _) => const LocationGateScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/feed', builder: (_, _) => const FeedScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/map', builder: (_, _) => const MapScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/achievements', builder: (_, _) => const AchievementsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/report/new',
        pageBuilder: (_, _) => const MaterialPage(fullscreenDialog: true, child: CreateReportFlow()),
      ),
      GoRoute(
        path: '/reports/:id',
        builder: (_, state) => ReportDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/citizens/:aliasId',
        builder: (_, state) => PublicProfileScreen(aliasId: state.pathParameters['aliasId']!),
      ),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
