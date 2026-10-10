import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Where installers are published. GitHub's "latest/download" links always resolve to the newest
/// release file, so the app can download updates directly without opening the release page.
abstract final class Releases {
  static const _repo = 'litu173/sajag';
  static const latestApi = 'https://api.github.com/repos/$_repo/releases/latest';
  static const androidApk = 'https://github.com/$_repo/releases/latest/download/sajag-android-arm64.apk';
  static const iosIpa = 'https://github.com/$_repo/releases/latest/download/sajag-ios-unsigned.ipa';
}

/// True when [latest] (e.g. "1.2.0" or "v1.2.0") is a higher semantic version than [current].
bool isNewerVersion(String latest, String current) {
  List<int> parse(String v) =>
      v.replaceFirst(RegExp('^v'), '').split('+').first.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final a = parse(latest);
  final b = parse(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

class UpdateStatus {
  const UpdateStatus({required this.current, required this.latest});
  final String current;
  final String latest;
  bool get available => isNewerVersion(latest, current);
}

Future<String> _fetchLatestTag() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(Uri.parse(Releases.latestApi));
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'sajag-app');
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw HttpException('GitHub responded ${response.statusCode}');
    final body = jsonDecode(await response.transform(utf8.decoder).join()) as Map<String, dynamic>;
    return (body['tag_name'] as String).replaceFirst(RegExp('^v'), '');
  } finally {
    client.close();
  }
}

final updateStatusProvider = FutureProvider.autoDispose<UpdateStatus>((ref) async {
  final results = await Future.wait([PackageInfo.fromPlatform().then((i) => i.version), _fetchLatestTag()]);
  return UpdateStatus(current: results[0], latest: results[1]);
});
