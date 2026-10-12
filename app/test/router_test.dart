import 'package:flutter_test/flutter_test.dart';
import 'package:sajag/core/location.dart';
import 'package:sajag/core/router.dart';
import 'package:sajag/data/models.dart';

void main() {
  String? go(
    String location, {
    bool splash = true,
    bool onboarded = true,
    AuthStage stage = AuthStage.ready,
    LocationAccess? access = LocationAccess.granted,
  }) => decideRedirect(
    location: location,
    splashDone: splash,
    onboarded: onboarded,
    stage: stage,
    locationAccess: access,
  );

  test('splash is shown until it completes', () {
    expect(go('/feed', splash: false), '/splash');
    expect(go('/splash', splash: false), isNull);
  });

  test('first run goes through onboarding', () {
    expect(go('/splash', onboarded: false), '/welcome');
    expect(go('/welcome', onboarded: false), isNull);
  });

  test('signed-out users can only use the phone + OTP steps', () {
    expect(go('/feed', stage: AuthStage.signedOut), '/auth/phone');
    expect(go('/auth/phone', stage: AuthStage.signedOut), isNull);
    expect(go('/auth/otp', stage: AuthStage.signedOut), isNull);
    expect(go('/reports/x', stage: AuthStage.signedOut), '/auth/phone');
  });

  test('identity verification is required before using the app', () {
    expect(go('/feed', stage: AuthStage.needsIdentity), '/auth/identity');
    expect(go('/auth/otp', stage: AuthStage.pendingReview), '/auth/pending');
  });

  test('after identity, a password is created before anything else (location comes next)', () {
    expect(go('/feed', stage: AuthStage.needsPassword), '/auth/password');
    expect(go('/location', stage: AuthStage.needsPassword, access: LocationAccess.denied), '/auth/password');
    expect(go('/auth/password', stage: AuthStage.needsPassword), isNull);
    expect(go('/auth/password'), '/feed', reason: 'done: ready users leave the step');
    expect(go('/auth/password', access: LocationAccess.denied), '/location');
  });

  test('location permission is mandatory once verified', () {
    expect(go('/feed', access: LocationAccess.denied), '/location');
    expect(go('/map', access: LocationAccess.deniedForever), '/location');
    expect(go('/location', access: LocationAccess.serviceOff), isNull);
  });

  test('ready users leave the entry screens for the feed, and stay put elsewhere', () {
    expect(go('/location'), '/feed');
    expect(go('/auth/identity'), '/feed');
    expect(go('/map'), isNull);
    expect(go('/reports/abc'), isNull);
  });
}
