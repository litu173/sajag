import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../data/models.dart';
import 'auth_scaffold.dart';

/// Sign-up step after identity verification: create the password that later confirms changes to
/// the mobile number, NID, date of birth or password (and can be used to sign in).
class PasswordSetupScreen extends ConsumerStatefulWidget {
  const PasswordSetupScreen({super.key});

  @override
  ConsumerState<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends ConsumerState<PasswordSetupScreen> {
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
      // On success the auth stage moves on and the router continues (location access next).
      await ref.read(repositoryProvider).createPassword(_password.text);
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
    return AuthScaffold(
      title: l.passwordSetupTitle,
      subtitle: l.passwordSetupBody,
      icon: Icons.lock_outline_rounded,
      action: FilledButton(
        key: const Key('password-setup-continue'),
        onPressed: _busy ? null : _save,
        child: BusyLabel(busy: _busy, label: l.continueLabel),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('password-setup-new'),
              controller: _password,
              autofocus: true,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
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
            const SizedBox(height: 16),
            TextField(
              key: const Key('password-setup-confirm'),
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
    );
  }
}
