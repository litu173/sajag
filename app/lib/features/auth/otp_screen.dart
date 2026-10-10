import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import 'auth_scaffold.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({required this.phone, super.key});
  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _resendAfter = 45;
  final _code = TextEditingController();
  Timer? _timer;
  int _secondsLeft = _resendAfter;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendAfter);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // On success the auth stage changes and the router moves on by itself.
      await ref.read(repositoryProvider).verifyOtp(widget.phone, _code.text);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(repositoryProvider).requestOtp(widget.phone);
      _startTimer();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthScaffold(
      title: l.otpTitle,
      subtitle: l.otpSubtitle(localDigits(context, '+88 ${widget.phone}')),
      icon: Icons.sms_outlined,
      action: FilledButton(
        onPressed: _busy ? null : _verify,
        child: BusyLabel(busy: _busy, label: l.verify),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 14),
            decoration: InputDecoration(hintText: '••••••', errorText: _error, errorMaxLines: 2),
            onChanged: (v) {
              if (v.length == 6) unawaited(_verify());
            },
          ),
          if (AppConfig.isDemo) ...[
            const SizedBox(height: 12),
            Text(
              l.otpDemoHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: () => context.pop(), child: Text(l.changeNumber)),
              TextButton(
                onPressed: _secondsLeft > 0 ? null : _resend,
                child: Text(_secondsLeft > 0 ? localDigits(context, l.resendIn(_secondsLeft)) : l.resend),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
