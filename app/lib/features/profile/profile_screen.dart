import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/updates.dart';
import '../../core/widgets/visuals.dart';
import '../../data/models.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.signOutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.signOut)),
        ],
      ),
    );
    if (ok == true) await ref.read(repositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final profile = ref.watch(myProfileProvider);
    final reports = ref.watch(myReportsProvider);
    final settings = ref.watch(settingsProvider);
    final catalog = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.navProfile)),
      body: RefreshIndicator(
        onRefresh: () async => refreshMe(ref),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            profile.when(
              loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myProfileProvider)),
              data: (p) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      AliasAvatar(alias: p.alias, seed: p.avatarSeed, size: 80),
                      const SizedBox(height: 12),
                      Text(p.alias, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(
                        localDigits(context, '${l.levelLabel(p.level)} · ${catalog.levelFor(p.level).name(context)}'),
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (p.verified) ...[
                        const SizedBox(height: 8),
                        Chip(
                          avatar: Icon(Icons.verified, color: theme.colorScheme.primary, size: 18),
                          label: Text(l.verifiedCitizen),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _Count(value: p.reportsCount, label: l.statReports),
                          _Count(value: p.followersCount, label: l.followers),
                          _Count(value: p.followingCount, label: l.followingLabel),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l.myReports, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            reports.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myReportsProvider)),
              data: (list) => list.isEmpty
                  ? Card(
                      child: ListTile(
                        leading: const Icon(Icons.photo_camera_outlined),
                        title: Text(l.noReportsYet),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/report/new'),
                      ),
                    )
                  : Card(
                      child: Column(children: [for (final r in list.take(20)) CompactReportTile(report: r)]),
                    ),
            ),
            const SizedBox(height: 24),
            Text(l.settings, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.translate),
                    title: Text(l.language),
                    trailing: SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      segments: const [
                        ButtonSegment(value: 'bn', label: Text('বাংলা')),
                        ButtonSegment(value: 'en', label: Text('EN')),
                      ],
                      selected: {settings.locale.languageCode},
                      onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setLocale(Locale(s.first)),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.text_fields),
                            const SizedBox(width: 16),
                            Text(l.textSize, style: theme.textTheme.bodyLarge),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<double>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(value: 1.0, label: Text(l.textNormal)),
                              ButtonSegment(value: 1.2, label: Text(l.textLarge)),
                              ButtonSegment(value: 1.4, label: Text(l.textExtraLarge)),
                            ],
                            selected: {settings.textScale},
                            onSelectionChanged: (s) => ref.read(settingsProvider.notifier).setTextScale(s.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ExpansionTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: Text(l.privacy),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [Text(l.privacyBody, style: theme.textTheme.bodyMedium)],
                  ),
                  const Divider(height: 1),
                  ExpansionTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l.about),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [Text(l.aboutBody, style: theme.textTheme.bodyMedium)],
                  ),
                  const Divider(height: 1),
                  const _UpdateTile(),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: theme.colorScheme.error),
                    title: Text(l.signOut, style: TextStyle(color: theme.colorScheme.error)),
                    onTap: () => _signOut(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(compactNumber(context, value), style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    ),
  );
}

class CompactReportTile extends ConsumerWidget {
  const CompactReportTile({required this.report, super.key});
  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(catalogProvider).category(report.categoryId);
    return ListTile(
      onTap: () => context.push('/reports/${report.id}'),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 52,
          height: 52,
          child: ReportPhoto(report: report, category: category, iconSize: 22),
        ),
      ),
      title: Text(report.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${category.name(context)} · ${timeAgo(context, report.createdAt)}', maxLines: 1),
      trailing: StatusChip(report.status),
    );
  }
}

/// Shows the installed version and, when GitHub has a newer release, downloads it directly.
class _UpdateTile extends ConsumerWidget {
  const _UpdateTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final status = ref.watch(updateStatusProvider);
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final subtitle = status.when(
      loading: () => l.checkingUpdate,
      error: (_, _) => l.updateCheckFailed,
      data: (s) => s.available ? l.updateAvailable(s.latest) : l.upToDate(s.current),
    );
    final available = status.value?.available ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(available ? Icons.system_update : Icons.verified_outlined),
            title: Text(l.latestVersion),
            subtitle: Text(localDigits(context, subtitle)),
            trailing: status.hasError
                ? IconButton(
                    tooltip: l.retry,
                    onPressed: () => ref.invalidate(updateStatusProvider),
                    icon: const Icon(Icons.refresh),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: available
                ? FilledButton.icon(
                    onPressed: () => _download(isIos),
                    icon: const Icon(Icons.download),
                    label: Text(l.downloadLatest),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _download(isIos),
                    icon: const Icon(Icons.download),
                    label: Text(l.downloadLatest),
                  ),
          ),
          if (isIos)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(l.iosInstallNote, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }

  /// Opens the direct file link in the system browser, which downloads it immediately.
  static Future<bool> _download(bool isIos) =>
      launchUrl(Uri.parse(isIos ? Releases.iosIpa : Releases.androidApk), mode: LaunchMode.externalApplication);
}
