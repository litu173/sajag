import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/visuals.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_scaffold.dart';
import '../auth/identity_screen.dart' show isValidNid;
import '../auth/phone_screen.dart' show isValidBdMobile;

/// Opens one of the account editors as a bottom sheet above the tab bar.
Future<T?> showAccountSheet<T>(BuildContext context, Widget sheet) =>
    showModalBottomSheet<T>(context: context, useRootNavigator: true, isScrollControlled: true, builder: (_) => sheet);

String formatPhone(BuildContext context, String? phone) =>
    phone == null ? '—' : localDigits(context, phone.length == 11 ? '+88 $phone' : phone);

String formatDate(BuildContext context, DateTime d) =>
    localDigits(context, DateFormat.yMMMMd(Localizations.localeOf(context).languageCode).format(d));

/// Title, body and a primary action, lifted above the keyboard.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.children, required this.action, this.subtitle});
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),
              ],
              const SizedBox(height: 22),
              ...children,
              const SizedBox(height: 22),
              action,
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tint.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tint),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({required this.controller, required this.label, this.error, this.onChanged});
  final TextEditingController controller;
  final String label;
  final String? error;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: true,
    keyboardType: TextInputType.number,
    autofillHints: const [AutofillHints.oneTimeCode],
    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: 8),
    onChanged: onChanged,
    decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.sms_rounded), errorText: error),
  );
}

// ================================================================ emoji avatar
const _emojiCategories = <String, List<String>>{
  'animals': [
    '🐯', '🦁', '🐘', '🦌', '🐬', '🐳', '🦦', '🐢', '🦉', '🦅', '🦚', '🦜', '🐦', '🐤', '🦩', '🦢', //
    '🕊️', '🐟', '🐠', '🦋', '🐝', '🐞', '🐼', '🐨', '🦊', '🐺', '🐱', '🐶', '🐰', '🐿️', '🦔', '🐸',
  ],
  'nature': [
    '🌸', '🌺', '🌻', '🌼', '🌷', '🪷', '🌹', '🍀', '🌿', '🌱', '🌳', '🌴', '🌾', '🍁', '🍃', '🌵', //
    '🌙', '⭐', '🌟', '☀️', '🌈', '⛅', '🌊', '💧', '🔥', '❄️', '⚡', '🌍', '🏔️', '🌋', '🪐', '☄️',
  ],
  'faces': [
    '😀', '😃', '😄', '😊', '🙂', '😉', '😎', '🤓', '🧐', '🤗', '🤩', '🥳', '😇', '🤠', '🥸', '😌', //
    '🤔', '🫡', '😺', '🤖', '👻', '👽', '🎃', '🦸', '🧙', '🧑‍🚀', '🧑‍🌾', '🧑‍🏫', '🧑‍🔬', '🧑‍🎨', '🧑‍🚒', '🥷',
  ],
  'food': [
    '🥭', '🍌', '🍉', '🍍', '🥥', '🍊', '🍋', '🍎', '🍇', '🍓', '🫐', '🥑', '🌶️', '🌽', '🥕', '🍆', //
    '🍚', '🍛', '🍜', '🥘', '🍲', '🫓', '🍞', '🧁', '🍩', '🍪', '🍫', '🍯', '🍵', '☕', '🥤', '🧃',
  ],
  'activity': [
    '🏏', '⚽', '🏀', '🏐', '🏸', '🏓', '🎾', '🏑', '♟️', '🎯', '🎮', '🎲', '🧩', '🎨', '🎭', '🎤', //
    '🎧', '🎸', '🥁', '🪕', '🎻', '🪁', '🛶', '🚴', '🏊', '🧗', '🏃', '🤸', '🥇', '🏆', '🎖️', '🎉',
  ],
  'places': [
    '🏠', '🏡', '🏘️', '🏙️', '🌆', '🌃', '🏞️', '🏝️', '🏖️', '⛰️', '🕌', '🛕', '⛪', '🏛️', '🏟️', '🗼', //
    '🛺', '🚲', '🛵', '🚌', '🚆', '🚇', '⛵', '🚤', '🛳️', '✈️', '🚁', '🚀', '🛰️', '🗺️', '🧭', '⛺',
  ],
  'objects': [
    '📷', '📸', '🔦', '💡', '🔭', '🔬', '📚', '📖', '✏️', '🖊️', '📝', '📌', '📎', '🔑', '🗝️', '🛠️', //
    '🧰', '🧲', '⚖️', '🪴', '🎒', '☂️', '⌚', '📱', '💻', '🎁', '🪔', '🏮', '🧿', '🔔', '📣', '🛡️',
  ],
  'symbols': [
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🤍', '🖤', '💯', '✨', '💫', '🔆', '♻️', '☮️', '☯️', '✅', //
    '⚜️', '🔱', '💠', '🔷', '🔶', '🟢', '🔵', '🟣', '🟡', '🟠', '🔴', '⚪', '🏳️', '🚩', '🎌', '🔰',
  ],
};

class EmojiAvatarSheet extends ConsumerStatefulWidget {
  const EmojiAvatarSheet({required this.profile, super.key});
  final Profile profile;

  @override
  ConsumerState<EmojiAvatarSheet> createState() => _EmojiAvatarSheetState();
}

class _EmojiAvatarSheetState extends ConsumerState<EmojiAvatarSheet> {
  late String? _emoji = widget.profile.avatarEmoji;
  late int _color = widget.profile.avatarSeed.abs() % AliasAvatar.palette.length;
  String _category = 'animals';
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).updateAvatar(emoji: _emoji, colorIndex: _color);
      refreshMe(ref);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _categoryName(AppLocalizations l, String id) => switch (id) {
    'animals' => l.emojiCatAnimals,
    'nature' => l.emojiCatNature,
    'faces' => l.emojiCatFaces,
    'food' => l.emojiCatFood,
    'activity' => l.emojiCatActivity,
    'places' => l.emojiCatPlaces,
    'objects' => l.emojiCatObjects,
    _ => l.emojiCatSymbols,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.84;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(l.chooseEmoji, style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: 18),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: AliasAvatar(
                  key: ValueKey('$_emoji$_color'),
                  alias: widget.profile.alias,
                  seed: _color,
                  emoji: _emoji,
                  size: 104,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  for (var i = 0; i < AliasAvatar.palette.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Semantics(
                        button: true,
                        selected: i == _color,
                        label: '${l.emojiBackground} ${i + 1}',
                        child: GestureDetector(
                          onTap: () => setState(() => _color = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AliasAvatar.palette[i],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: i == _color ? theme.colorScheme.primary : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _CategoryPill(
                    label: l.emojiUseAlias,
                    icon: _emoji == null ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
                    selected: _emoji == null,
                    tint: SajagColors.gold,
                    onTap: () => setState(() => _emoji = null),
                  ),
                  for (final id in _emojiCategories.keys)
                    _CategoryPill(
                      label: _categoryName(l, id),
                      selected: _category == id,
                      onTap: () => setState(() => _category = id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 56,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: _emojiCategories[_category]!.length,
                itemBuilder: (context, i) {
                  final e = _emojiCategories[_category]![i];
                  final selected = e == _emoji;
                  return Semantics(
                    button: true,
                    selected: selected,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _emoji = e);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.14) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 28), textScaler: TextScaler.noScaling),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: BusyLabel(busy: _busy, label: l.saveChanges),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.selected, required this.onTap, this.icon, this.tint});
  final String label;
  final bool selected;
  final IconData? icon;
  final Color? tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = selected;
    final fill = tint ?? theme.colorScheme.primary;
    final fg = active ? (tint == null ? theme.colorScheme.onPrimary : Colors.white) : null;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? fill : theme.cardTheme.color,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 17, color: fg ?? fill), const SizedBox(width: 6)],
                Text(label, style: theme.textTheme.labelLarge?.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================ alias
class AliasSheet extends ConsumerStatefulWidget {
  const AliasSheet({required this.current, required this.lockedUntil, super.key});
  final String current;
  final DateTime? lockedUntil;

  @override
  ConsumerState<AliasSheet> createState() => _AliasSheetState();
}

class _AliasSheetState extends ConsumerState<AliasSheet> {
  late final _alias = TextEditingController(text: widget.current);
  bool _busy = false;
  bool _showError = false;

  static const _adj = [
    'Brave',
    'Bright',
    'Calm',
    'Kind',
    'Swift',
    'Wise',
    'Bold',
    'Quiet',
    'Sharp',
    'Gentle',
    'Steady',
  ];
  static const _ani = ['Kingfisher', 'Doel', 'Tiger', 'Dolphin', 'Myna', 'Heron', 'Otter', 'Falcon', 'Owl', 'Bulbul'];

  @override
  void dispose() {
    _alias.dispose();
    super.dispose();
  }

  void _suggest() {
    final r = Random();
    _alias.text = '${_adj[r.nextInt(_adj.length)]} ${_ani[r.nextInt(_ani.length)]} ${1000 + r.nextInt(9000)}';
    setState(() => _showError = false);
  }

  Future<void> _save() async {
    if (aliasProblem(_alias.text) != null) {
      setState(() => _showError = true);
      return;
    }
    if (_alias.text.trim() == widget.current) {
      Navigator.pop(context);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).changeAlias(_alias.text);
      refreshMe(ref);
      if (mounted) {
        showMessage(context, context.l10n.savedMessage);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locked = widget.lockedUntil;
    return _SheetFrame(
      title: l.changeAlias,
      subtitle: locked == null ? l.aliasOncePerWeek : l.aliasLockedUntil(formatDate(context, locked)),
      action: FilledButton(
        onPressed: _busy || locked != null ? null : _save,
        child: BusyLabel(busy: _busy, label: l.saveChanges),
      ),
      children: [
        TextField(
          controller: _alias,
          enabled: locked == null,
          autofocus: locked == null,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          onChanged: (_) => _showError ? setState(() => _showError = false) : null,
          decoration: InputDecoration(
            labelText: l.aliasLabel,
            helperText: l.aliasHelper,
            errorText: _showError ? l.errInvalidAlias : null,
            errorMaxLines: 2,
            prefixIcon: const Icon(Icons.alternate_email_rounded),
            suffixIcon: locked != null
                ? null
                : IconButton(tooltip: l.suggestAlias, onPressed: _suggest, icon: const Icon(Icons.casino_rounded)),
          ),
        ),
        const SizedBox(height: 12),
        _Note(icon: Icons.visibility_off_rounded, text: l.aliasWarning, color: SajagColors.gold),
      ],
    );
  }
}

// ================================================================ phone
class PhoneChangeSheet extends ConsumerStatefulWidget {
  const PhoneChangeSheet({super.key});

  @override
  ConsumerState<PhoneChangeSheet> createState() => _PhoneChangeSheetState();
}

class _PhoneChangeSheetState extends ConsumerState<PhoneChangeSheet> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() body) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await body();
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (!isValidBdMobile(_phone.text)) {
      setState(() => _error = context.l10n.phoneInvalid);
      return;
    }
    await _run(() async {
      await ref.read(repositoryProvider).requestPhoneChange(_phone.text);
      if (mounted) setState(() => _codeSent = true);
    });
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) return;
    await _run(() async {
      await ref.read(repositoryProvider).confirmPhoneChange(_phone.text, _code.text);
      refreshMe(ref);
      if (mounted) {
        showMessage(context, context.l10n.phoneChanged);
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _SheetFrame(
      title: l.changePhone,
      subtitle: _codeSent ? l.codeSentTo(formatPhone(context, _phone.text)) : l.phoneSubtitle,
      action: FilledButton(
        onPressed: _busy ? null : (_codeSent ? _verify : _send),
        child: BusyLabel(busy: _busy, label: _codeSent ? l.verifyAndSave : l.sendCode),
      ),
      children: [
        if (!_codeSent)
          TextField(
            controller: _phone,
            autofocus: true,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1.2),
            onChanged: (_) => _error != null ? setState(() => _error = null) : null,
            decoration: InputDecoration(
              labelText: l.newPhoneLabel,
              hintText: '01XXXXXXXXX',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Text('🇧🇩 +88', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              errorText: _error,
              errorMaxLines: 2,
            ),
          )
        else ...[
          _CodeField(
            controller: _code,
            label: l.codeLabel,
            error: _error,
            onChanged: (v) => v.length == 6 ? _verify() : null,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _busy ? null : () => setState(() => _codeSent = false),
              child: Text(l.changeNumber),
            ),
          ),
        ],
      ],
    );
  }
}

// ================================================================ NID + date of birth
class IdentitySheet extends ConsumerStatefulWidget {
  const IdentitySheet({required this.currentDob, super.key});
  final DateTime? currentDob;

  @override
  ConsumerState<IdentitySheet> createState() => _IdentitySheetState();
}

class _IdentitySheetState extends ConsumerState<IdentitySheet> {
  final _nid = TextEditingController();
  late DateTime? _dob = widget.currentDob;
  bool _busy = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _nid.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: context.l10n.dobPick,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!isValidNid(_nid.text) || _dob == null) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).submitIdentity(nid: _nid.text, dob: _dob!);
      refreshMe(ref);
      if (mounted) {
        showMessage(context, context.l10n.identityUpdated);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _SheetFrame(
      title: l.updateIdentity,
      subtitle: l.updateIdentityBody,
      action: FilledButton(
        onPressed: _busy ? null : _save,
        child: BusyLabel(busy: _busy, label: l.saveChanges),
      ),
      children: [
        TextField(
          controller: _nid,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(17)],
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, letterSpacing: 1.2),
          onChanged: (_) => _showErrors ? setState(() {}) : null,
          decoration: InputDecoration(
            labelText: l.nidLabel,
            helperText: l.nidHelper,
            prefixIcon: const Icon(Icons.credit_card_rounded),
            errorText: _showErrors && !isValidNid(_nid.text) ? l.errInvalidNid : null,
            errorMaxLines: 2,
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: _pickDob,
          borderRadius: BorderRadius.circular(18),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l.dobLabel,
              prefixIcon: const Icon(Icons.cake_rounded),
              suffixIcon: const Icon(Icons.calendar_month_rounded),
              errorText: _showErrors && _dob == null ? l.dobPick : null,
            ),
            child: Text(_dob == null ? l.dobPick : formatDate(context, _dob!), style: const TextStyle(fontSize: 17)),
          ),
        ),
        const SizedBox(height: 14),
        _Note(icon: Icons.info_rounded, text: l.identityReviewNote, color: SajagColors.gold),
      ],
    );
  }
}

// ================================================================ confirm it's you
/// Asks for proof the person is present before a sensitive change. Skipped when they verified in
/// the last few minutes. Returns true once verified.
Future<bool> ensureVerified(BuildContext context, WidgetRef ref, AccountInfo account) async {
  if (ref.read(repositoryProvider).recentlyVerified) return true;
  final ok = await showAccountSheet<bool>(context, VerifySheet(account: account));
  return ok ?? false;
}

class VerifySheet extends ConsumerStatefulWidget {
  const VerifySheet({required this.account, super.key});
  final AccountInfo account;

  @override
  ConsumerState<VerifySheet> createState() => _VerifySheetState();
}

class _VerifySheetState extends ConsumerState<VerifySheet> {
  final _password = TextEditingController();
  final _code = TextEditingController();
  late bool _usePassword = widget.account.hasPassword;
  bool _codeSent = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() body) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await body();
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final repo = ref.read(repositoryProvider);
    if (_usePassword) {
      if (_password.text.isEmpty) return;
      await _run(() async {
        await repo.verifyPassword(_password.text);
        if (mounted) Navigator.pop(context, true);
      });
    } else if (!_codeSent) {
      await _run(() async {
        await repo.sendVerificationCode();
        if (mounted) setState(() => _codeSent = true);
      });
    } else {
      if (_code.text.length != 6) return;
      await _run(() async {
        await repo.verifyCode(_code.text);
        if (mounted) Navigator.pop(context, true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final phone = formatPhone(context, widget.account.phone);
    return _SheetFrame(
      title: l.verifyTitle,
      subtitle: _usePassword ? l.verifyPasswordBody : (_codeSent ? l.codeSentTo(phone) : l.verifyCodeBody(phone)),
      action: FilledButton(
        key: const Key('verify-continue'),
        onPressed: _busy ? null : _submit,
        child: BusyLabel(busy: _busy, label: !_usePassword && !_codeSent ? l.sendCode : l.verifyContinue),
      ),
      children: [
        if (_usePassword)
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(),
            onChanged: (_) => _error != null ? setState(() => _error = null) : null,
            decoration: InputDecoration(
              labelText: l.currentPassword,
              prefixIcon: const Icon(Icons.lock_rounded),
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: _obscure ? l.showPassword : l.hidePassword,
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
              ),
            ),
          )
        else if (_codeSent)
          _CodeField(
            controller: _code,
            label: l.codeLabel,
            error: _error,
            onChanged: (v) => v.length == 6 ? _submit() : null,
          )
        else
          _Note(
            icon: Icons.shield_rounded,
            text: _error ?? l.identityHint,
            color: _error == null ? null : SajagColors.accent,
          ),
        if (widget.account.hasPassword)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _usePassword = !_usePassword;
                      _error = null;
                    }),
              icon: Icon(_usePassword ? Icons.sms_rounded : Icons.password_rounded, size: 18),
              label: Text(_usePassword ? l.useCodeInstead : l.usePasswordInstead),
            ),
          ),
      ],
    );
  }
}

// ================================================================ password
class PasswordSheet extends ConsumerStatefulWidget {
  const PasswordSheet({required this.hasPassword, super.key});
  final bool hasPassword;

  @override
  ConsumerState<PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends ConsumerState<PasswordSheet> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!isStrongPassword(_password.text) || _password.text != _confirm.text) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).setPassword(_password.text);
      refreshMe(ref);
      if (mounted) {
        showMessage(context, context.l10n.passwordSaved);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final toggle = IconButton(
      tooltip: _obscure ? l.showPassword : l.hidePassword,
      onPressed: () => setState(() => _obscure = !_obscure),
      icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
    );
    return _SheetFrame(
      title: widget.hasPassword ? l.changePassword : l.setPassword,
      subtitle: l.passwordChooseIntro,
      action: FilledButton(
        onPressed: _busy ? null : _save,
        child: BusyLabel(busy: _busy, label: l.saveChanges),
      ),
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _password,
                autofocus: true,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => _showErrors ? setState(() {}) : null,
                decoration: InputDecoration(
                  labelText: l.newPassword,
                  helperText: l.passwordRule,
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: toggle,
                  errorText: _showErrors && !isStrongPassword(_password.text) ? l.errWeakPassword : null,
                  errorMaxLines: 2,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirm,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => _showErrors ? setState(() {}) : null,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: l.confirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  errorText: _showErrors && _password.text != _confirm.text ? l.passwordMismatch : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================ delete account
Future<bool> confirmDeleteAccount(BuildContext context) async {
  final ok = await showDialog<bool>(context: context, builder: (_) => const _DeleteDialog());
  return ok ?? false;
}

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog();

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ready = _typed.text.trim().toUpperCase() == 'DELETE';
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: SajagColors.accent, size: 36),
      title: Text(l.deleteAccountConfirm),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.deleteAccountBody),
          const SizedBox(height: 16),
          TextField(
            controller: _typed,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: l.deleteAccountType),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SajagColors.accent,
            foregroundColor: SajagColors.onAccent,
            minimumSize: const Size(0, 48),
          ),
          onPressed: ready ? () => Navigator.pop(context, true) : null,
          child: Text(l.deleteAccount),
        ),
      ],
    );
  }
}
