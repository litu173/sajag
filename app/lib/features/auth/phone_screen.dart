import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import 'auth_scaffold.dart';

final _bdMobile = RegExp(r'^01[3-9]\d{8}$');

bool isValidBdMobile(String s) => _bdMobile.hasMatch(s);

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showError = false;
  bool _usePassword = false;
  bool _obscure = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signInWithPassword() async {
    final phone = _phone.text.trim();
    if (!isValidBdMobile(phone)) {
      setState(() => _showError = true);
      return;
    }
    if (_password.text.isEmpty) return;
    setState(() => _busy = true);
    try {
      // On success the auth stage changes and the router moves on by itself.
      await ref.read(repositoryProvider).signInWithPassword(phone, _password.text);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final phone = _phone.text.trim();
    if (!isValidBdMobile(phone)) {
      setState(() => _showError = true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).requestOtp(phone);
      if (mounted) await context.push('/auth/otp?phone=$phone');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthScaffold(
      title: l.phoneTitle,
      subtitle: l.phoneSubtitle,
      action: FilledButton(
        onPressed: _busy ? null : (_usePassword ? _signInWithPassword : _submit),
        child: BusyLabel(busy: _busy, label: _usePassword ? l.signIn : l.sendCode),
      ),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _phoneField(l),
            if (_usePassword) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _password,
                autofocus: true,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signInWithPassword(),
                decoration: InputDecoration(
                  labelText: l.passwordLabel,
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? l.showPassword : l.hidePassword,
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _busy ? null : () => setState(() => _usePassword = !_usePassword),
                icon: Icon(_usePassword ? Icons.sms_rounded : Icons.password_rounded, size: 19),
                label: Text(_usePassword ? l.signInWithCode : l.signInWithPassword),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneField(AppLocalizations l) {
    return TextField(
      controller: _phone,
      autofocus: true,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      textInputAction: TextInputAction.done,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 1.5),
      onChanged: (_) => _showError ? setState(() => _showError = false) : null,
      onSubmitted: (_) => _usePassword ? null : _submit(),
      decoration: InputDecoration(
        labelText: l.phoneLabel,
        hintText: '01XXXXXXXXX',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 8),
          child: Text('🇧🇩 +88', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        errorText: _showError ? l.phoneInvalid : null,
        errorMaxLines: 2,
      ),
    );
  }
}
