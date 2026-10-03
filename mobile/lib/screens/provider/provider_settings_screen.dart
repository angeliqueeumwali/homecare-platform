import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/user_model.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';

class ProviderSettingsScreen extends StatelessWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final provider = context.watch<ProviderViewModel>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (user != null) _AccountCard(user: user),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Account'),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Password',
            subtitle:
                'Password changes are not available: the backend has no '
                'endpoint for it.',
            onTap: null,
          ),
          _SettingsTile(
            icon: Icons.mail_outline,
            title: 'Email',
            subtitle: user?.email ?? 'Not available',
            onTap: null,
          ),
          _SettingsTile(
            icon: Icons.phone_outlined,
            title: 'Phone number',
            subtitle: user?.phoneNumber ?? 'Not available',
            onTap: null,
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Provider'),
          _SettingsTile(
            icon: Icons.storefront_outlined,
            title: 'Services I offer',
            subtitle: 'Choose the services you provide',
            onTap: () => Navigator.pushNamed(context, '/provider/services'),
          ),
          _SettingsTile(
            icon: Icons.location_on_outlined,
            title: 'Business location',
            subtitle: 'Where you work from',
            onTap: () => Navigator.pushNamed(context, '/provider/location'),
          ),
          _SettingsTile(
            icon: Icons.reviews_outlined,
            title: 'Customer reviews',
            subtitle: 'Ratings from completed work',
            onTap: () => Navigator.pushNamed(context, '/provider/reviews'),
          ),
          _SettingsTile(
            icon: Icons.notifications_none,
            title: 'Notification preferences',
            subtitle:
                'Not available: the backend has no notification preferences.',
            onTap: null,
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionLabel('Session'),
          AppCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  user == null
                      ? 'Sign out of this device'
                      : 'Signed in as ${user.email}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  text: 'Log out',
                  backgroundColor: AppColors.errorRed,
                  onPressed: () => _confirmLogout(context, auth, provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AuthProvider auth,
    ProviderViewModel provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('You will need to sign in again to see your jobs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    provider.clearError();
    await auth.logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}

class _AccountCard extends StatelessWidget {
  final UserModel user;

  const _AccountCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.darkNavyBlue,
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            alignment: Alignment.center,
            child: Text(
              '${user.firstName.substring(0, 1)}${user.lastName.substring(0, 1)}'
                  .toUpperCase(),
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainText,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge(status: user.role, fontSize: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryText,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        margin: EdgeInsets.zero,
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              icon,
              color: onTap == null
                  ? AppColors.secondaryText
                  : AppColors.darkNavyBlue,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onTap == null
                          ? AppColors.secondaryText
                          : AppColors.mainText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }
}
