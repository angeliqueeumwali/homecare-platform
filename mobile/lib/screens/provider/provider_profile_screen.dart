import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/widgets/approval_status_banner.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _businessNameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ProviderViewModel>();
      if (vm.profile == null) vm.fetchProfile();
    });
  }

  void _seed(String? businessName, String? bio) {
    if (_seeded) return;
    _seeded = true;
    _businessNameController.text = businessName ?? '';
    _bioController.text = bio ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProviderViewModel>();
    final profile = vm.profile;
    _seed(profile?.businessName, profile?.bio);

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Provider Profile'),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoading ? null : vm.fetchProfile,
          ),
        ],
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(ProviderViewModel vm) {
    if (vm.isCheckingAccount || (vm.isLoading && vm.profile == null)) {
      return const AppLoadingIndicator(message: 'Loading your profile');
    }

    if (vm.profile == null) {
      return ErrorView(
        message:
            vm.errorMessage ?? 'Your provider profile could not be loaded.',
        onRetry: vm.fetchProfile,
      );
    }

    final profile = vm.profile!;
    final isApproved = vm.isApprovedProvider;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ApprovalStatusBanner(
          state: vm.accountState,
          businessName: profile.businessName,
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.darkNavyBlue,
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.medium,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(profile.businessName),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.businessName?.isNotEmpty == true
                              ? profile.businessName!
                              : 'No business name',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StatusBadge(status: profile.approvalStatus),
                            const SizedBox(width: 6),
                            StatusBadge(
                              status: profile.isAvailable
                                  ? 'AVAILABLE'
                                  : 'UNAVAILABLE',
                              customColor: profile.isAvailable
                                  ? AppColors.successGreen
                                  : AppColors.secondaryText,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (profile.averageRating != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 18,
                      color: AppColors.warningAmber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      profile.averageRating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'average rating from customers',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isApproved) ...[
          _AvailabilityCard(vm: vm),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Business details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavyBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Business name',
                controller: _businessNameController,
                prefixIcon: Icons.business_outlined,
                validator: (value) {
                  if (value != null && value.length > 255) {
                    return 'Use 255 characters or fewer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'About your work',
                controller: _bioController,
                maxLines: 4,
                prefixIcon: Icons.info_outline,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'Save changes',
                isLoading: vm.isLoading,
                onPressed: vm.isLoading ? null : () => _save(vm),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ProfileLinkTile(
          icon: Icons.storefront_outlined,
          title: 'Services I offer',
          subtitle: 'Add or remove the services customers can match you on',
          onTap: () => Navigator.pushNamed(context, '/provider/services'),
        ),
        _ProfileLinkTile(
          icon: Icons.location_on_outlined,
          title: 'Business location',
          subtitle: 'Where you work from, used for provider matching',
          onTap: () => Navigator.pushNamed(context, '/provider/location'),
        ),
        _ProfileLinkTile(
          icon: Icons.reviews_outlined,
          title: 'Customer reviews',
          subtitle: 'Ratings customers left about your completed work',
          onTap: () => Navigator.pushNamed(context, '/provider/reviews'),
        ),
        _ProfileLinkTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Account details, session and logout',
          onTap: () => Navigator.pushNamed(context, '/provider/settings'),
        ),
        if (!isApproved)
          const AppCard(
            backgroundColor: AppColors.lightGrey,
            child: Text(
              'Services, availability and location are available once an '
              'administrator approves this account.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _save(ProviderViewModel vm) async {
    final businessName = _businessNameController.text.trim();
    final bio = _bioController.text.trim();

    final ok = await vm.updateProfile(
      businessName: businessName.isEmpty ? null : businessName,
      bio: bio.isEmpty ? null : bio,
    );
    if (!mounted) return;

    final message = ok
        ? 'Profile updated'
        : (vm.errorMessage ?? 'Could not save the profile');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ok ? AppColors.successGreen : AppColors.errorRed,
      ),
    );
  }

  static String _initials(String? name) {
    final text = (name ?? '').trim();
    if (text.isEmpty) return '?';
    final parts = text.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _AvailabilityCard extends StatelessWidget {
  final ProviderViewModel vm;

  const _AvailabilityCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final isAvailable = vm.profile?.isAvailable ?? false;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Availability',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavyBlue,
                  ),
                ),
              ),
              Switch(
                value: isAvailable,
                activeThumbColor: AppColors.darkNavyBlue,
                onChanged: vm.isLoading
                    ? null
                    : (value) => _toggle(context, vm, value),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAvailable
                ? 'You are marked as available for new work.'
                : 'You are not being offered new work.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    ProviderViewModel vm,
    bool value,
  ) async {
    final ok = await vm.updateProfile(isAvailable: value);
    if (!context.mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vm.errorMessage ?? 'The backend refused the availability change.',
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'You are now available' : 'You are unavailable'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }
}

class _ProfileLinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileLinkTile({
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
            Icon(icon, color: AppColors.darkNavyBlue, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainText,
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
            const Icon(Icons.chevron_right, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }
}
