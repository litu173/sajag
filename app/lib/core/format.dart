import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// Renders ASCII digits as Bangla digits when the UI is in Bangla.
String localDigits(BuildContext context, String s) {
  if (!isBangla(context)) return s;
  return s.replaceAllMapped(RegExp('[0-9]'), (m) => _bnDigits[int.parse(m[0]!)]);
}

String compactNumber(BuildContext context, int n) => localDigits(context, NumberFormat.compact(locale: 'en').format(n));

String timeAgo(BuildContext context, DateTime t, {DateTime? now}) {
  final l = context.l10n;
  final d = (now ?? DateTime.now()).difference(t);
  final String text;
  if (d.inMinutes < 1) {
    text = l.timeJustNow;
  } else if (d.inHours < 1) {
    text = l.timeMinutes(d.inMinutes);
  } else if (d.inDays < 1) {
    text = l.timeHours(d.inHours);
  } else if (d.inDays < 7) {
    text = l.timeDays(d.inDays);
  } else {
    text = DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(t);
  }
  return localDigits(context, text);
}

/// "Solved in 3 days" for a resolved report, or null.
String? solvedInText(BuildContext context, Report report) {
  final at = report.resolvedAt;
  if (at == null) return null;
  final l = context.l10n;
  final d = at.difference(report.createdAt);
  final duration = d.inHours < 24
      ? l.durationHours(d.inHours < 1 ? 1 : d.inHours)
      : l.durationDays((d.inHours / 24).round());
  return localDigits(context, l.solvedIn(duration));
}

String errorMessage(BuildContext context, Object error) {
  final l = context.l10n;
  if (error is! SajagException) return l.errorGeneric;
  return switch (error.code) {
    SajagErrorCode.invalidOtp => l.errInvalidOtp,
    SajagErrorCode.invalidNid => l.errInvalidNid,
    SajagErrorCode.invalidDob => l.errInvalidDob,
    SajagErrorCode.nidTaken => l.errNidTaken,
    SajagErrorCode.notVerified => l.errNotVerified,
    SajagErrorCode.accountBlocked => l.errBlocked,
    SajagErrorCode.rateLimited => l.errRateLimited,
    SajagErrorCode.staleCapture => l.errStaleCapture,
    SajagErrorCode.ownReport => l.errOwnReport,
    SajagErrorCode.alreadyDone => l.errAlreadyDone,
    SajagErrorCode.invalidAlias => l.errInvalidAlias,
    SajagErrorCode.aliasTaken => l.errAliasTaken,
    SajagErrorCode.aliasCooldown => l.errAliasCooldown,
    SajagErrorCode.phoneTaken => l.errPhoneTaken,
    SajagErrorCode.weakPassword => l.errWeakPassword,
    SajagErrorCode.wrongPassword => l.errWrongPassword,
    SajagErrorCode.network => l.errorNetwork,
    SajagErrorCode.unknown => l.errorGeneric,
  };
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(errorMessage(context, error))));
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
