import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/updates.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/visuals.dart';
import '../../data/models.dart';
import '../shell/home_shell.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final profile = ref.watch(myProfileProvider);
    final reports = ref.watch(myReportsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => refreshMe(ref),
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 12, 20, navClearance(context)),
          children: [
            profile.when(
              loading: () => const HeroSkeleton(),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myProfileProvider)),
              data: (p) => _ProfileHero(profile: p),
            ),
            const SizedBox(height: 32),
            _SectionTitle(l.myReports),
            const SizedBox(height: 14),
            reports.when(
              loading: () => Shimmer(
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SkeletonBox(width: 112, height: 150, radius: 20),
                      ),
                  ],
                ),
              ),
              error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myReportsProvider)),
              data: (list) => list.isEmpty ? const _NoReports() : _ReportStrip(reports: list),
            ),
            const SizedBox(height: 32),
            _SectionTitle(l.settings),
            const SizedBox(height: 14),
            const _Settings(),
            const SizedBox(height: 18),
            _Group(
              children: [
                _Row(
                  icon: Icons.logout_rounded,
                  tint: SajagColors.accent,
                  title: l.signOut,
                  titleColor: SajagColors.accent,
                  onTap: () => _signOut(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(child: Text('Sajag · সজাগ', style: theme.textTheme.bodySmall)),
          ],
        ),
      ),
    );
  }

  static Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.signOutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SajagColors.accent,
              foregroundColor: SajagColors.onAccent,
              minimumSize: const Size(0, 48),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.signOut),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(repositoryProvider).signOut();
  }
}

// ------------------------------------------------------------------ hero
class _ProfileHero extends ConsumerWidget {
  const _ProfileHero({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final catalog = ref.watch(catalogProvider);
    final level = catalog.levelFor(profile.level);
    final next = catalog.nextLevel(profile.level);
    final progress = next == null ? 1.0 : ((profile.xp - level.minXp) / (next.minXp - level.minXp)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: SajagColors.heroGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: SajagColors.brand.withValues(alpha: 0.35), blurRadius: 34, offset: const Offset(0, 16)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft decorative light, purely visual.
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          Column(
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress.toDouble(),
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        color: const Color(0xFFF0CF95),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.9)),
                      child: AliasAvatar(alias: profile.alias, seed: profile.avatarSeed, size: 84),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                profile.alias,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _GlassPill(
                    icon: Icons.auto_awesome_rounded,
                    text: localDigits(context, '${l.levelLabel(level.level)} · ${level.name(context)}'),
                  ),
                  if (profile.verified) _GlassPill(icon: Icons.verified_rounded, text: l.verifiedCitizen),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _GlassStat(value: profile.reportsCount, label: l.statReports),
                  const SizedBox(width: 10),
                  _GlassStat(value: profile.followersCount, label: l.followers),
                  const SizedBox(width: 10),
                  _GlassStat(value: profile.followingCount, label: l.followingLabel),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFFF0CF95)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

class _GlassStat extends StatelessWidget {
  const _GlassStat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(
            compactNumber(context, value),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------------ reports strip
class _ReportStrip extends ConsumerWidget {
  const _ReportStrip({required this.reports});
  final List<Report> reports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: reports.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final r = reports[i];
          final category = catalog.category(r.categoryId);
          return GestureDetector(
            onTap: () => context.push('/reports/${r.id}'),
            child: SizedBox(
              width: 112,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ReportPhoto(report: r, category: category, iconSize: 28),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC000000)],
                          stops: [0.45, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusChip(r.status),
                          const SizedBox(height: 6),
                          Text(
                            r.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoReports extends StatelessWidget {
  const _NoReports();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Group(
      children: [
        _Row(
          icon: Icons.photo_camera_rounded,
          tint: SajagColors.accent,
          title: l.noReportsYet,
          subtitle: l.reportAction,
          onTap: () => context.push('/report/new'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ settings
class _Settings extends ConsumerWidget {
  const _Settings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return _Group(
      children: [
        _Row(
          icon: Icons.translate_rounded,
          tint: const Color(0xFF3A6EA5),
          title: l.language,
          trailing: _PillToggle<String>(
            value: settings.locale.languageCode,
            options: const {'bn': 'বাংলা', 'en': 'EN'},
            onChanged: (v) => notifier.setLocale(Locale(v)),
          ),
        ),
        _Row(
          icon: Icons.format_size_rounded,
          tint: SajagColors.gold,
          title: l.textSize,
          trailing: _PillToggle<double>(
            value: settings.textScale,
            options: {1.0: 'অ', 1.2: 'অ', 1.4: 'অ'},
            optionStyle: (v) => TextStyle(fontSize: 13 + (v - 1) * 20, fontWeight: FontWeight.w600),
            semanticLabels: {1.0: l.textNormal, 1.2: l.textLarge, 1.4: l.textExtraLarge},
            onChanged: notifier.setTextScale,
          ),
        ),
        _Row(
          icon: Icons.shield_rounded,
          tint: SajagColors.brand,
          title: l.privacy,
          onTap: () => _info(context, l.privacy, l.privacyBody),
        ),
        _AboutRow(onOpen: () => _about(context)),
      ],
    );
  }

  static Future<void> _about(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) {
      final l = context.l10n;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SajagLogo(size: 52),
                  const SizedBox(width: 14),
                  Expanded(child: Text(l.about, style: Theme.of(context).textTheme.headlineSmall)),
                ],
              ),
              const SizedBox(height: 16),
              Text(l.aboutBody, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              const _VersionPanel(),
            ],
          ),
        ),
      );
    },
  );

  static Future<void> _info(BuildContext context, String title, String body) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 14),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    ),
  );
}

/// "About Sajag" row, with a "New" badge when a newer version is available.
class _AboutRow extends ConsumerWidget {
  const _AboutRow({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final available = ref.watch(updateStatusProvider).value?.available ?? false;
    return _Row(
      icon: Icons.info_rounded,
      tint: const Color(0xFF8338EC),
      title: l.about,
      onTap: onOpen,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (available)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: SajagColors.accent, borderRadius: BorderRadius.circular(12)),
              child: Text(
                l.newBadge,
                style: const TextStyle(color: SajagColors.onAccent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          Icon(Icons.chevron_right_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
        ],
      ),
    );
  }
}

/// Installed version, update status and a direct download of the newest release.
class _VersionPanel extends ConsumerWidget {
  const _VersionPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final status = ref.watch(updateStatusProvider);
    final isIos = theme.platform == TargetPlatform.iOS;
    final available = status.value?.available ?? false;
    final subtitle = status.when(
      loading: () => l.checkingUpdate,
      error: (_, _) => l.updateCheckFailed,
      data: (s) => s.available ? l.updateAvailable(s.latest) : l.upToDate(s.current),
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                available ? Icons.system_update_rounded : Icons.verified_rounded,
                color: available ? SajagColors.accent : SajagColors.resolved,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.versionTitle, style: theme.textTheme.titleSmall),
                    Text(localDigits(context, subtitle), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              if (status.hasError)
                IconButton(
                  tooltip: l.retry,
                  onPressed: () => ref.invalidate(updateStatusProvider),
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: available
                ? FilledButton.styleFrom(backgroundColor: SajagColors.accent, foregroundColor: SajagColors.onAccent)
                : null,
            onPressed: () => launchUrl(
              Uri.parse(isIos ? Releases.iosIpa : Releases.androidApk),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.download_rounded),
            label: Text(l.downloadLatest),
          ),
          if (isIos) ...[const SizedBox(height: 10), Text(l.iosInstallNote, style: theme.textTheme.bodySmall)],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ building blocks
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

/// A rounded panel of rows, separated by spacing instead of divider lines.
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(26),
        boxShadow: SajagColors.softShadow(theme.brightness),
      ),
      child: Column(children: children),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.tint,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: tint.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: tint, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(color: titleColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: theme.textTheme.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}

/// Compact segmented pill used for language and text size.
class _PillToggle<T> extends StatelessWidget {
  const _PillToggle({
    required this.value,
    required this.options,
    required this.onChanged,
    this.optionStyle,
    this.semanticLabels,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final TextStyle Function(T)? optionStyle;
  final Map<T, String>? semanticLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in options.entries)
            Semantics(
              button: true,
              selected: e.key == value,
              label: semanticLabels?[e.key] ?? e.value,
              child: GestureDetector(
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 34),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: e.key == value ? theme.cardTheme.color : Colors.transparent,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: e.key == value ? SajagColors.softShadow(theme.brightness) : null,
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      e.value,
                      style: (optionStyle?.call(e.key) ?? const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))
                          .copyWith(color: e.key == value ? theme.colorScheme.primary : null),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small report row used by the public profile list.
class CompactReportTile extends ConsumerWidget {
  const CompactReportTile({required this.report, super.key});
  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(catalogProvider).category(report.categoryId);
    return InkWell(
      onTap: () => unawaited(context.push('/reports/${report.id}')),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 60,
                height: 60,
                child: ReportPhoto(report: report, category: category, iconSize: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.name(context)} · ${timeAgo(context, report.createdAt)}',
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(report.status),
          ],
        ),
      ),
    );
  }
}
