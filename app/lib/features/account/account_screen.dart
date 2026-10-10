import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets/settings.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/visuals.dart';
import '../../data/models.dart';
import 'account_sheets.dart';

/// Everything about the signed-in account: the public look (emoji, alias), the private identity
/// used for verification (phone, NID, date of birth), sign-in security and deletion.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final profile = ref.watch(myProfileProvider);
    final account = ref.watch(myAccountProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.accountSettings)),
      body: switch ((profile, account)) {
        (AsyncData(value: final p), AsyncData(value: final a)) => _Body(profile: p, account: a),
        (AsyncError(:final error), _) ||
        (_, AsyncError(:final error)) => ErrorView(error: error, onRetry: () => refreshMe(ref)),
        _ => const _AccountSkeleton(),
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.profile, required this.account});
  final Profile profile;
  final AccountInfo account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final locked = account.aliasLockedUntil;
    final verified = account.verification == 'verified';

    void emoji() => showAccountSheet<void>(context, EmojiAvatarSheet(profile: profile));
    void alias() => showAccountSheet<void>(context, AliasSheet(current: profile.alias, lockedUntil: locked));
    void identity() => showAccountSheet<void>(context, IdentitySheet(currentDob: account.dob));

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 32),
      children: [
        Center(
          child: EditableAvatar(profile: profile, size: 96, onTap: emoji),
        ),
        const SizedBox(height: 14),
        Text(profile.alias, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(l.publicProfileHint, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        const SizedBox(height: 28),

        SectionTitle(l.publicProfileSection),
        const SizedBox(height: 12),
        SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.emoji_emotions_rounded,
              tint: SajagColors.gold,
              title: l.avatarLabel,
              onTap: emoji,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AliasAvatar(alias: profile.alias, seed: profile.avatarSeed, emoji: profile.avatarEmoji, size: 32),
                  Icon(Icons.chevron_right_rounded, color: theme.textTheme.bodySmall?.color),
                ],
              ),
            ),
            SettingsRow(
              icon: Icons.alternate_email_rounded,
              tint: const Color(0xFF3A6EA5),
              title: l.aliasLabel,
              subtitle: locked == null
                  ? profile.alias
                  : '${profile.alias} · ${l.aliasLockedUntil(formatDate(context, locked))}',
              onTap: alias,
            ),
          ],
        ),
        const SizedBox(height: 28),

        SectionTitle(l.identitySection),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Row(
            children: [
              Icon(Icons.lock_rounded, size: 14, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 6),
              Expanded(child: Text(l.identityHint, style: theme.textTheme.bodySmall)),
            ],
          ),
        ),
        SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.phone_iphone_rounded,
              tint: SajagColors.brand,
              title: l.phoneLabel,
              subtitle: formatPhone(context, account.phone),
              onTap: () => showAccountSheet<void>(context, const PhoneChangeSheet()),
            ),
            SettingsRow(
              icon: Icons.badge_rounded,
              tint: const Color(0xFF8338EC),
              title: l.nidLabel,
              subtitle: account.nidLast4 == null ? '—' : localDigits(context, '•••• •••• ${account.nidLast4}'),
              onTap: identity,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _VerificationChip(verified: verified),
                  Icon(Icons.chevron_right_rounded, color: theme.textTheme.bodySmall?.color),
                ],
              ),
            ),
            SettingsRow(
              icon: Icons.cake_rounded,
              tint: const Color(0xFFD9506A),
              title: l.dobLabel,
              subtitle: account.dob == null ? '—' : formatDate(context, account.dob!),
              onTap: identity,
            ),
          ],
        ),
        const SizedBox(height: 28),

        SectionTitle(l.securitySection),
        const SizedBox(height: 12),
        SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.password_rounded,
              tint: const Color(0xFF2A9D8F),
              title: account.hasPassword ? l.changePassword : l.setPassword,
              subtitle: account.hasPassword ? l.passwordIsSet : l.passwordNotSet,
              onTap: () => showAccountSheet<void>(
                context,
                PasswordSheet(phone: account.phone, hasPassword: account.hasPassword),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        SettingsGroup(
          children: [
            SettingsRow(
              icon: Icons.delete_forever_rounded,
              tint: SajagColors.accent,
              title: l.deleteAccount,
              titleColor: SajagColors.accent,
              subtitle: l.deleteAccountHint,
              onTap: () => _delete(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  static Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await confirmDeleteAccount(context) || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final done = context.l10n.accountDeleted;
    try {
      // The auth stage turns signedOut and the router returns to the welcome flow.
      await ref.read(repositoryProvider).deleteAccount();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class _VerificationChip extends StatelessWidget {
  const _VerificationChip({required this.verified});
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = verified ? SajagColors.resolved : SajagColors.progress;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(verified ? Icons.verified_rounded : Icons.schedule_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            verified ? l.idVerified : l.idPending,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Avatar with a small pencil badge; tapping opens the emoji picker.
class EditableAvatar extends StatelessWidget {
  const EditableAvatar({required this.profile, required this.onTap, super.key, this.size = 84, this.ring});
  final Profile profile;
  final VoidCallback onTap;
  final double size;

  /// Optional backdrop behind the avatar (the profile hero draws a progress ring there).
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      button: true,
      label: l.chooseEmoji,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, color: ring ?? Theme.of(context).cardTheme.color),
              child: AliasAvatar(
                alias: profile.alias,
                seed: profile.avatarSeed,
                emoji: profile.avatarEmoji,
                size: size,
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SajagColors.brand,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: const Icon(Icons.edit_rounded, size: 15, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSkeleton extends StatelessWidget {
  const _AccountSkeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: const [
        Center(child: SkeletonBox(width: 104, height: 104, radius: 52)),
        SizedBox(height: 16),
        Center(child: SkeletonBox(width: 180, height: 20)),
        SizedBox(height: 32),
        SkeletonBox(width: 140, height: 20),
        SizedBox(height: 14),
        SkeletonBox(height: 130, radius: 26),
        SizedBox(height: 32),
        SkeletonBox(width: 160, height: 20),
        SizedBox(height: 14),
        SkeletonBox(height: 190, radius: 26),
      ],
    ),
  );
}
