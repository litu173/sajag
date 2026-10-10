import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
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
  bool _busy = false;
  bool _showError = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
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
        onPressed: _busy ? null : _submit,
        child: BusyLabel(busy: _busy, label: l.sendCode),
      ),
      child: TextField(
        controller: _phone,
        autofocus: true,
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumberNational],
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 1.5),
        onChanged: (_) => _showError ? setState(() => _showError = false) : null,
        onSubmitted: (_) => _submit(),
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
      ),
    );
  }
}
