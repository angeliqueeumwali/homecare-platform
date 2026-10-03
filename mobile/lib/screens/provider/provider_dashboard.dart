import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/models/assignment_model.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/providers/service_provider.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/screens/provider/provider_assignments_screen.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/approval_status_banner.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/widgets/service_category_widgets.dart';
import 'package:mobile/models/service_request_model.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ProviderViewModel>();
      if (!vm.hasLoadedOnce) vm.loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProviderViewModel>();
    final profile = vm.profile;
    final user = context.watch<AuthProvider>().user;
    final isApproved = vm.isApprovedProvider;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: vm.isApprovedProvider
              ? vm.loadDashboard
              : vm.refreshAccountState,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              _ProviderWelcomeHeader(
                firstName: user?.firstName ?? '',
                businessName: profile?.businessName,
                approvalStatus: profile?.approvalStatus,
                isAvailable: profile?.isAvailable,
                onNotifications: () =>
                    Navigator.pushNamed(context, '/provider/notifications'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ApprovalStatusBanner(
                      state: vm.accountState,
                      businessName: profile?.businessName,
                    ),
                    if (isApproved) ...[
                      if (vm.isLoadingAssignments &&
                          vm.assignments.isEmpty &&
                          !vm.hasLoadedAssignments)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: AppLoadingIndicator(
                            message: 'Loading your assignments',
                          ),
                        )
                      else if (vm.assignmentErrorMessage != null &&
                          vm.assignments.isEmpty)
                        ErrorView(
                          message: vm.assignmentErrorMessage!,
                          onRetry: vm.fetchAssignments,
                        )
                      else ...[
                        _AssignmentSummaryRow(vm: vm),
                        const SizedBox(height: AppSpacing.md),
                        _QuickLinks(),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      _NextJobsSection(vm: vm),
                      const SizedBox(height: AppSpacing.lg),
                      const _ServicesSummary(),
                    ] else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: AppCard(
                          child: Text(
                            'Your assigned jobs, services and quotes appear '
                            'here once an administrator approves the account.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentSummaryRow extends StatelessWidget {
  final ProviderViewModel vm;

  const _AssignmentSummaryRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Open jobs',
            value: '${vm.openAssignments.length}',
            icon: Icons.work_outline,
            onTap: () => Navigator.pushNamed(context, '/provider/assignments'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            label: 'Needs reply',
            value: '${vm.pendingAssignments.length}',
            icon: Icons.mark_email_unread_outlined,
            onTap: () {
              vm.setAssignmentStatusFilter(AssignmentStatus.pending);
              Navigator.pushNamed(context, '/provider/assignments');
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryTile(
            label: 'Completed',
            value: '${_completedCount(vm.assignments)}',
            icon: Icons.check_circle_outline,
            onTap: () {
              vm.setAssignmentStatusFilter(AssignmentStatus.completed);
              Navigator.pushNamed(context, '/provider/assignments');
            },
          ),
        ),
      ],
    );
  }

  static int _completedCount(List<AssignmentModel> assignments) => assignments
      .where((a) => a.status.toUpperCase() == AssignmentStatus.completed)
      .length;
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.darkNavyBlue),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavyBlue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickLink(
            icon: Icons.assignment_outlined,
            label: 'Assignments',
            onTap: () => Navigator.pushNamed(context, '/provider/assignments'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickLink(
            icon: Icons.storefront_outlined,
            label: 'My services',
            onTap: () => Navigator.pushNamed(context, '/provider/services'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _QuickLink(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: () => Navigator.pushNamed(context, '/provider/profile'),
          ),
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.darkNavyBlue),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mainText,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextJobsSection extends StatelessWidget {
  final ProviderViewModel vm;

  const _NextJobsSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final pending = vm.pendingAssignments.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Waiting for your reply',
          actionLabel: 'See all',
          onAction: () {
            vm.setAssignmentStatusFilter(AssignmentStatus.pending);
            Navigator.pushNamed(context, '/provider/assignments');
          },
        ),
        if (pending.isEmpty)
          AppCard(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.successGreen,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Nothing needs a reply right now.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final assignment in pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: ProviderAssignmentCard(assignment: assignment),
            ),
      ],
    );
  }
}

class _ServicesSummary extends StatelessWidget {
  const _ServicesSummary();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProviderViewModel>();
    final categories = context.watch<ServiceCategoryViewModel>().categories;
    final byId = {for (final c in categories) c.id: c};
    final offered = vm.services
        .map((s) => byId[s.serviceCategoryId])
        .whereType<ServiceCategoryModel>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Services you offer',
          actionLabel: 'Manage',
          onAction: () => Navigator.pushNamed(context, '/provider/services'),
        ),
        if (offered.isEmpty)
          AppCard(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: const Text(
              'You have not added any services yet. Add the services you '
              'provide so the admin can match you to requests.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final category in offered.take(6))
                  _ServiceChip(category: category),
                if (offered.length > 6) _MoreChip(count: offered.length - 6),
              ],
            ),
          ),
      ],
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final ServiceCategoryModel category;

  const _ServiceChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ServiceCategoryImage(category: category, size: 20, borderRadius: 5),
          const SizedBox(width: 8),
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mainText,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  final int count;

  const _MoreChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.darkNavyBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Text(
        '+$count more',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.darkNavyBlue,
        ),
      ),
    );
  }
}

class _ProviderWelcomeHeader extends StatelessWidget {
  final String firstName;
  final String? businessName;
  final String? approvalStatus;
  final bool? isAvailable;
  final VoidCallback onNotifications;

  const _ProviderWelcomeHeader({
    required this.firstName,
    required this.businessName,
    required this.approvalStatus,
    required this.isAvailable,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final hasName = businessName != null && businessName!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkNavyBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName.isEmpty ? 'Provider' : 'Hello, $firstName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasName ? businessName! : 'No business name yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: onNotifications,
                icon: const Icon(
                  Icons.notifications_none,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (approvalStatus != null)
                StatusBadge(status: approvalStatus!, invert: true),
              if (approvalStatus != null && isAvailable != null)
                const SizedBox(width: AppSpacing.sm),
              if (isAvailable != null)
                StatusBadge(
                  status: isAvailable! ? 'AVAILABLE' : 'UNAVAILABLE',
                  customColor: isAvailable!
                      ? AppColors.successGreen
                      : AppColors.secondaryText,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
