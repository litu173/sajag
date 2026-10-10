import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import 'auth_scaffold.dart';

bool isValidNid(String s) => const {10, 13, 17}.contains(s.replaceAll(RegExp(r'\D'), '').length);

class IdentityScreen extends ConsumerStatefulWidget {
  const IdentityScreen({super.key});

  @override
  ConsumerState<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends ConsumerState<IdentityScreen> {
  final _nid = TextEditingController();
  DateTime? _dob;
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
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: context.l10n.dobPick,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!isValidNid(_nid.text) || _dob == null) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).submitIdentity(nid: _nid.text, dob: _dob!);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final dobText = _dob == null
        ? l.dobPick
        : localDigits(context, DateFormat.yMMMMd(Localizations.localeOf(context).languageCode).format(_dob!));

    return AuthScaffold(
      title: l.nidTitle,
      subtitle: l.nidSubtitle,
      icon: Icons.badge_outlined,
      action: FilledButton(
        onPressed: _busy ? null : _submit,
        child: BusyLabel(busy: _busy, label: l.verifyIdentity),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nid,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(17)],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1.2),
            onChanged: (_) => _showErrors ? setState(() {}) : null,
            decoration: InputDecoration(
              labelText: l.nidLabel,
              helperText: l.nidHelper,
              prefixIcon: const Icon(Icons.credit_card),
              errorText: _showErrors && !isValidNid(_nid.text) ? l.errInvalidNid : null,
              errorMaxLines: 2,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDob,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l.dobLabel,
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon: const Icon(Icons.calendar_month),
                errorText: _showErrors && _dob == null ? l.dobPick : null,
              ),
              child: Text(dobText, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(l.privacyPromise, style: theme.textTheme.titleSmall)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
