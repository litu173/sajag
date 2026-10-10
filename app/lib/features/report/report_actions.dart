import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../data/models.dart';
import 'confirmations.dart';

Future<void> toggleConfirm(BuildContext context, WidgetRef ref, Report report) async {
  unawaited(HapticFeedback.lightImpact());
  try {
    await ref.read(confirmationsProvider.notifier).toggle(report.id);
    ref.invalidate(myProfileProvider);
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

Future<void> shareReport(BuildContext context, WidgetRef ref, Report report) async {
  final category = ref.read(catalogProvider).category(report.categoryId).name(context);
  final place = report.place.isEmpty
      ? '${report.lat.toStringAsFixed(5)}, ${report.lng.toStringAsFixed(5)}'
      : report.place;
  final text =
      '${context.l10n.shareText(category, place)}\n"${report.description}"\n'
      'https://maps.google.com/?q=${report.lat},${report.lng}';
  await SharePlus.instance.share(ShareParams(text: text));
}

Future<void> flagReport(BuildContext context, WidgetRef ref, Report report) async {
  final result = await showModalBottomSheet<(FlagReason, String)>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _FlagSheet(),
  );
  if (result == null || !context.mounted) return;
  try {
    await ref.read(repositoryProvider).flag(report.id, result.$1, result.$2);
    if (context.mounted) showMessage(context, context.l10n.flagThanks);
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

class _FlagSheet extends StatefulWidget {
  const _FlagSheet();

  @override
  State<_FlagSheet> createState() => _FlagSheetState();
}

class _FlagSheetState extends State<_FlagSheet> {
  FlagReason? _reason;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = {
      FlagReason.falseInfo: l.flagFalse,
      FlagReason.wrongLocation: l.flagLocation,
      FlagReason.wrongCategory: l.flagCategory,
      FlagReason.inappropriate: l.flagInappropriate,
      FlagReason.duplicate: l.flagDuplicate,
      FlagReason.spam: l.flagSpam,
      FlagReason.other: l.flagOther,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.flagTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              RadioGroup<FlagReason>(
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                child: Column(
                  children: [
                    for (final e in labels.entries)
                      RadioListTile<FlagReason>(value: e.key, title: Text(e.value), contentPadding: EdgeInsets.zero),
                  ],
                ),
              ),
              TextField(
                controller: _note,
                maxLength: 300,
                maxLines: 2,
                decoration: InputDecoration(hintText: l.flagNoteHint),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _reason == null ? null : () => Navigator.pop(context, (_reason!, _note.text.trim())),
                child: Text(l.flagSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
