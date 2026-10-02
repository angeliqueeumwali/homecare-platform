import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/providers/service_provider.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';

/// Customer profile. Only the fields `PATCH /users/me` accepts can be edited:
/// first name, last name and phone number. Email is read-only because the
/// backend does not support changing it.
///
/// Saved addresses are deliberately absent: the backend has no addresses
/// resource, each request only stores its own address text.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final requestVm = context.read<ServiceRequestViewModel>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.darkNavyBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 32,
                    color: AppColors.white,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavyBlue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                InfoRow(
                  label: 'Phone',
                  value: user.phoneNumber,
                  icon: Icons.phone_outlined,
                ),
                InfoRow(
                  label: 'Account type',
                  value: user.role == 'CUSTOMER' ? 'Customer' : user.role,
                  icon: Icons.badge_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Edit profile',
            icon: Icons.edit_outlined,
            width: double.infinity,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => EditProfileScreen(
                  firstName: user.firstName,
                  lastName: user.lastName,
                  phoneNumber: user.phoneNumber,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _MenuTile(
            icon: Icons.assignment_outlined,
            title: 'My requests',
            subtitle: '${requestVm.requests.length} total',
            onTap: () => Navigator.pushNamed(context, '/request-list'),
          ),
          _MenuTile(
            icon: Icons.payments_outlined,
            title: 'Payments',
            subtitle: 'Payment history',
            onTap: () => Navigator.pushNamed(context, '/payments'),
          ),
          _MenuTile(
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: const Text(
              'Saved addresses and review history are not shown because the '
              'backend has no endpoints for them yet.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ),
          if (user.isProvider) ...[
            const SectionHeader(title: 'Provider'),
            _buildProviderSection(context),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Logout',
            icon: Icons.logout,
            width: double.infinity,
            backgroundColor: AppColors.errorRed,
            onPressed: () async {
              final confirmed = await AppDialog.showConfirmation(
                context,
                title: 'Log out?',
                message: 'You will need to sign in again to book services.',
                confirmText: 'Log out',
                isDestructive: true,
              );
              if (confirmed != true || !context.mounted) return;
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              await Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Provider tools, shown only to accounts the backend reports as
  /// SERVICE_PROVIDER. The approval status comes from `GET /providers/me`.
  Widget _buildProviderSection(BuildContext context) {
    final accountState = context.watch<ProviderViewModel>().accountState;
    final isApproved = accountState == ProviderAccountState.approved;

    return Column(
      children: [
        AppCard(
          child: Row(
            children: [
              const Text(
                'Account status',
                style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(
                status: switch (accountState) {
                  ProviderAccountState.approved => 'APPROVED',
                  ProviderAccountState.rejected => 'REJECTED',
                  _ => 'PENDING',
                },
              ),
            ],
          ),
        ),
        if (isApproved) ...[
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            text: 'My provider profile',
            outlined: true,
            backgroundColor: AppColors.secondaryNavyBlue,
            width: double.infinity,
            onPressed: () => Navigator.pushNamed(context, '/provider/profile'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            text: 'My services',
            outlined: true,
            backgroundColor: AppColors.secondaryNavyBlue,
            width: double.infinity,
            onPressed: () => Navigator.pushNamed(context, '/provider/services'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            text: 'Set my location',
            outlined: true,
            backgroundColor: AppColors.secondaryNavyBlue,
            width: double.infinity,
            onPressed: () => Navigator.pushNamed(context, '/provider/location'),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Your provider account is not approved yet, so provider tools are '
            'hidden. An administrator handles approval.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainText,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
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

/// Edits the three fields the backend accepts, via `PATCH /users/me`.
class EditProfileScreen extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String phoneNumber;

  const EditProfileScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(
    text: widget.firstName,
  );
  late final _lastNameController = TextEditingController(text: widget.lastName);
  late final _phoneController = TextEditingController(text: widget.phoneNumber);
  bool _isSaving = false;
  String? _error;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    try {
      final updated = await auth.userService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      // Refresh the cached user so the profile screen shows real values.
      await auth.refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      if (updated.role.isEmpty) return;
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Edit profile'),
        backgroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppTextField(
                label: 'First name',
                controller: _firstNameController,
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  if (value.trim().length < 2) return 'Too short';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Last name',
                controller: _lastNameController,
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  if (value.trim().length < 2) return 'Too short';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Please enter your phone number';
                  // The backend requires 7 to 30 characters and enforces
                  // uniqueness across accounts.
                  if (text.length < 7) return 'Too short';
                  if (text.length > 30) return 'Too long';
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'Save changes',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
