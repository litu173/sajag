import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/location.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/visuals.dart';
import '../../data/catalog.dart';
import '../../data/models.dart';
import '../feed/feed_controller.dart';
import '../map/map_screen.dart';
import 'camera_page.dart';
import 'community_rules.dart';

/// Camera -> review -> details. The GPS fix starts as soon as the flow opens so it's
/// usually ready by the time the photo is taken.
class CreateReportFlow extends ConsumerStatefulWidget {
  const CreateReportFlow({super.key});

  @override
  ConsumerState<CreateReportFlow> createState() => _CreateReportFlowState();
}

class _CreateReportFlowState extends ConsumerState<CreateReportFlow> {
  String? _photo;
  DateTime? _capturedAt;
  bool _reviewed = false;
  late Future<(Fix, Place)> _location = _locate();

  @override
  void initState() {
    super.initState();
    // Before someone's first post, they read and accept the community rules.
    if (!rulesAccepted(ref)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final agreed = await showCommunityRules(context, ref, requireAgree: true);
        if (!agreed && mounted) context.pop();
      });
    }
  }

  Future<(Fix, Place)> _locate() async {
    final service = ref.read(locationServiceProvider);
    final fix = await service.current();
    return (fix, await service.describe(fix.position));
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    if (photo == null) {
      return CameraPage(
        onCaptured: (path, at) => setState(() {
          _photo = path;
          _capturedAt = at;
        }),
      );
    }
    if (!_reviewed) {
      return _ReviewPage(
        photo: photo,
        onRetake: () => setState(() => _photo = null),
        onUse: () => setState(() => _reviewed = true),
      );
    }
    return _ComposePage(
      photo: photo,
      capturedAt: _capturedAt!,
      location: _location,
      onRetryLocation: () => setState(() => _location = _locate()),
      onRetake: () => setState(() {
        _photo = null;
        _reviewed = false;
      }),
    );
  }
}

class _ReviewPage extends StatelessWidget {
  const _ReviewPage({required this.photo, required this.onRetake, required this.onUse});
  final String photo;
  final VoidCallback onRetake;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(child: Center(child: Image.file(File(photo)))),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      onPressed: onRetake,
                      icon: const Icon(Icons.refresh),
                      label: Text(l.retake),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(onPressed: onUse, icon: const Icon(Icons.check), label: Text(l.usePhoto)),
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

class _ComposePage extends ConsumerStatefulWidget {
  const _ComposePage({
    required this.photo,
    required this.capturedAt,
    required this.location,
    required this.onRetryLocation,
    required this.onRetake,
  });

  final String photo;
  final DateTime capturedAt;
  final Future<(Fix, Place)> location;
  final VoidCallback onRetryLocation;
  final VoidCallback onRetake;

  @override
  ConsumerState<_ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends ConsumerState<_ComposePage> {
  final _description = TextEditingController();
  final _plate = TextEditingController();
  String? _category;
  bool _traffic = false;
  String? _vehicle;
  final _violations = <String>{};
  bool _showAlias = true;
  bool _busy = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _description.dispose();
    _plate.dispose();
    super.dispose();
  }

  bool get _descriptionOk => _description.text.trim().length >= AppConfig.descriptionMinLength;

  String? get _missing {
    final l = context.l10n;
    if (_traffic) {
      if (_vehicle == null) return l.pickVehicle;
      if (_violations.isEmpty) return l.pickViolation;
    } else if (_category == null) {
      return l.pickCategory;
    }
    if (!_descriptionOk) return l.descriptionTooShort;
    return null;
  }

  /// Warns before posting text the content policy would hold. Returns true to go ahead.
  Future<bool> _passesPolicy() async {
    final issue = ref.read(catalogProvider).policy.check(_description.text);
    if (issue == null) return true;
    final l = context.l10n;
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.gpp_maybe_rounded, color: SajagColors.accent, size: 34),
        title: Text(l.policyWarnTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(policyIssueText(context, issue), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(l.policyWarnBody),
          ],
        ),
        actionsOverflowDirection: VerticalDirection.up,
        actionsOverflowButtonSpacing: 4,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.sendForReview)),
          FilledButton(
            key: const Key('edit-description'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.editDescription),
          ),
        ],
      ),
    );
    return send ?? false;
  }

  Future<void> _submit((Fix, Place)? located) async {
    final missing = _missing;
    if (missing != null || located == null) {
      setState(() => _showErrors = true);
      // The inline errors may be scrolled out of view; say what's missing where the user is looking.
      if (missing != null) showMessage(context, missing);
      return;
    }
    if (!await _passesPolicy() || !mounted) return;
    if (DateTime.now().difference(widget.capturedAt) > AppConfig.maxCaptureAge) {
      showError(context, const SajagException(SajagErrorCode.staleCapture));
      widget.onRetake();
      return;
    }
    final (fix, place) = located;
    setState(() => _busy = true);
    try {
      final created = await ref
          .read(repositoryProvider)
          .createReport(
            NewReport(
              photoPath: widget.photo,
              categoryId: _traffic ? trafficCategory : _category!,
              vehicleType: _traffic ? _vehicle : null,
              violations: _traffic ? _violations.toList() : const [],
              plateNumber: _traffic && _plate.text.trim().isNotEmpty ? _plate.text.trim() : null,
              description: _description.text.trim(),
              lat: fix.position.latitude,
              lng: fix.position.longitude,
              accuracy: fix.accuracy,
              capturedAt: widget.capturedAt,
              showAlias: _showAlias,
              address: place.address,
              areaName: place.area,
              districtId: place.districtId,
              city: place.city,
            ),
          );
      refreshMe(ref);
      ref
        ..invalidate(feedProvider)
        ..invalidate(mapReportsProvider);
      if (!mounted) return;
      showMessage(context, created.isPublished ? context.l10n.posted : context.l10n.sentForReview);
      context.pop();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Widget> _trafficFields(BuildContext context, Catalog catalog) {
    final l = context.l10n;
    final theme = Theme.of(context);
    const tint = Color(0xFFC2185B);
    Widget error(String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: TextStyle(color: theme.colorScheme.error)),
    );
    return [
      Text(l.vehicleTypeLabel, style: theme.textTheme.titleMedium),
      if (_showErrors && _vehicle == null) error(l.pickVehicle),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in catalog.vehicles)
            ChoiceChip(
              key: ValueKey('vehicle-${v.id}'),
              avatar: Icon(vehicleIcon(v.id), size: 18, color: _vehicle == v.id ? Colors.white : tint),
              label: Text(v.name(context)),
              selected: _vehicle == v.id,
              showCheckmark: false,
              selectedColor: tint,
              labelStyle: TextStyle(color: _vehicle == v.id ? Colors.white : null, fontWeight: FontWeight.w500),
              onSelected: (_) => setState(() => _vehicle = v.id),
            ),
        ],
      ),
      const SizedBox(height: 22),
      Text(l.violationsLabel, style: theme.textTheme.titleMedium),
      if (_showErrors && _violations.isEmpty) error(l.pickViolation),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in catalog.violations)
            FilterChip(
              key: ValueKey('violation-${v.id}'),
              label: Text(v.name(context)),
              selected: _violations.contains(v.id),
              selectedColor: tint,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: _violations.contains(v.id) ? Colors.white : null,
                fontWeight: FontWeight.w500,
              ),
              onSelected: (on) => setState(() => on ? _violations.add(v.id) : _violations.remove(v.id)),
            ),
        ],
      ),
      const SizedBox(height: 22),
      Text(l.plateLabel, style: theme.textTheme.titleMedium),
      const SizedBox(height: 10),
      TextField(
        key: const Key('plate-field'),
        controller: _plate,
        maxLength: 40,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.4),
        decoration: InputDecoration(
          hintText: 'ঢাকা মেট্রো-গ ১২-৩৪৫৬',
          helperText: l.plateHelper,
          helperMaxLines: 2,
          prefixIcon: const Icon(Icons.pin_outlined),
          counterText: '',
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SajagColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.health_and_safety_rounded, color: SajagColors.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(l.trafficSafety, style: theme.textTheme.bodySmall?.copyWith(height: 1.45))),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final catalog = ref.watch(catalogProvider);
    final categories = catalog.categories.where((c) => c.id != trafficCategory).toList();
    final me = ref.watch(myProfileProvider).value;
    final alias = me?.alias ?? '';

    return FutureBuilder<(Fix, Place)>(
      future: widget.location,
      builder: (context, snap) {
        final located = snap.data;
        final mocked = located?.$1.mocked ?? false;
        return Scaffold(
          appBar: AppBar(title: Text(l.composeTitle)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(File(widget.photo), width: 108, height: 108, fit: BoxFit.cover, cacheWidth: 324),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LocationCard(snapshot: snap, onRetry: widget.onRetryLocation),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _TypeSwitch(
                traffic: _traffic,
                onChanged: (t) => setState(() {
                  _traffic = t;
                  _showErrors = false;
                }),
              ),
              const SizedBox(height: 20),
              if (_traffic)
                ..._trafficFields(context, catalog)
              else ...[
                Text(l.categoryLabel, style: theme.textTheme.titleMedium),
                if (_showErrors && _category == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(l.pickCategory, style: TextStyle(color: theme.colorScheme.error)),
                  ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 130,
                    mainAxisExtent: 96,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    return _CategoryTile(
                      category: c,
                      selected: _category == c.id,
                      onTap: () => setState(() => _category = c.id),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              Text(l.descriptionLabel, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLength: AppConfig.descriptionMaxLength,
                buildCounter: (context, {required currentLength, required isFocused, required maxLength}) =>
                    Text(localDigits(context, '$currentLength/$maxLength'), style: theme.textTheme.bodySmall),
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _showErrors ? setState(() {}) : null,
                decoration: InputDecoration(
                  hintText: l.descriptionHint,
                  errorText: _showErrors && !_descriptionOk ? l.descriptionTooShort : null,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  value: _showAlias,
                  onChanged: (v) => setState(() => _showAlias = v),
                  title: Text(l.showAlias),
                  subtitle: Text(_showAlias ? l.showAliasOn(alias) : l.showAliasOff),
                  secondary: AliasAvatar(
                    alias: _showAlias ? alias : null,
                    seed: me?.avatarSeed ?? 0,
                    emoji: _showAlias ? me?.avatarEmoji : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.identityNeverShown, style: theme.textTheme.bodySmall)),
                ],
              ),
              const SizedBox(height: 12),
              _PolicyNote(onRules: () => showCommunityRules(context, ref)),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: SajagColors.accent,
                  foregroundColor: SajagColors.onAccent,
                ),
                onPressed: _busy || located == null || mocked ? null : () => _submit(located),
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: SajagColors.onAccent),
                      )
                    : const Icon(Icons.send),
                label: Text(l.submitReport),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "Hazard | Traffic violation" — what kind of report this is.
class _TypeSwitch extends StatelessWidget {
  const _TypeSwitch({required this.traffic, required this.onChanged});
  final bool traffic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    Widget option(bool value, IconData icon, String label) {
      final on = traffic == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            key: ValueKey(value ? 'type-traffic' : 'type-hazard'),
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? theme.cardTheme.color : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                boxShadow: on ? SajagColors.softShadow(theme.brightness) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 19, color: on ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: on ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          option(false, Icons.warning_amber_rounded, l.reportTypeHazard),
          option(true, Icons.local_police_outlined, l.reportTypeTraffic),
        ],
      ),
    );
  }
}

class _PolicyNote extends StatelessWidget {
  const _PolicyNote({required this.onRules});
  final VoidCallback onRules;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: SajagColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.gpp_good_rounded, color: SajagColors.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(l.policyNote, style: theme.textTheme.bodySmall?.copyWith(height: 1.45))),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onRules, child: Text(l.communityRules)),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.snapshot, required this.onRetry});
  final AsyncSnapshot<(Fix, Place)> snapshot;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final Widget content;
    if (snapshot.hasError) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.errorGeneric, style: TextStyle(color: theme.colorScheme.error)),
          TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l.retry)),
        ],
      );
    } else if (!snapshot.hasData) {
      content = Row(
        children: [
          const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10),
          Expanded(child: Text(l.locating)),
        ],
      );
    } else {
      final (fix, place) = snapshot.data!;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            place.area ??
                place.city ??
                '${fix.position.latitude.toStringAsFixed(5)}, ${fix.position.longitude.toStringAsFixed(5)}',
            style: theme.textTheme.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (place.address != null)
            Text(place.address!, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            fix.mocked ? l.mockLocation : localDigits(context, l.locationAccuracy(fix.accuracy.round())),
            style: theme.textTheme.bodySmall?.copyWith(
              color: fix.mocked ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (fix.substituted)
            Text(l.demoLocationNote, style: theme.textTheme.bodySmall?.copyWith(color: SajagColors.progress)),
        ],
      );
    }
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.place, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(l.locationLabel, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 6),
          content,
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.selected, required this.onTap});
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? category.color.withValues(alpha: 0.14) : theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? category.color : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(categoryIcon(category), color: category.color, size: 30),
                const SizedBox(height: 6),
                Text(
                  category.name(context),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
