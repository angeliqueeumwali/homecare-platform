import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/models/assignment_model.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/approval_status_banner.dart';
import 'package:mobile/widgets/common_widgets.dart';

class ProviderAssignmentsScreen extends StatefulWidget {
  const ProviderAssignmentsScreen({super.key});

  @override
  State<ProviderAssignmentsScreen> createState() =>
      _ProviderAssignmentsScreenState();
}

class _ProviderAssignmentsScreenState extends State<ProviderAssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ProviderViewModel>();
      if (!vm.hasLoadedAssignments) vm.fetchAssignments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProviderViewModel>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('My Assignments'),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoadingAssignments ? null : vm.fetchAssignments,
          ),
        ],
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(ProviderViewModel vm) {
    if (vm.isCheckingAccount && !vm.hasLoadedOnce) {
      return const AppLoadingIndicator(message: 'Checking your account');
    }

    if (!vm.isApprovedProvider) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ApprovalStatusBanner(
            state: vm.accountState,
            businessName: vm.profile?.businessName,
          ),
          AppCard(
            child: Text(
              vm.accountState == ProviderAccountState.none
                  ? 'This account has no service provider profile, so the '
                        'backend refuses assignment requests for it.'
                  : 'Assignments are only available to approved providers.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      );
    }

    if (vm.isLoadingAssignments &&
        vm.assignments.isEmpty &&
        !vm.hasLoadedAssignments) {
      return const AppLoadingIndicator(message: 'Loading your assignments');
    }

    if (vm.assignmentErrorMessage != null && vm.assignments.isEmpty) {
      return ErrorView(
        message: vm.assignmentErrorMessage!,
        onRetry: vm.fetchAssignments,
      );
    }

    if (vm.assignments.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        message:
            'You have no assignments yet.\n'
            'An administrator assigns jobs here after a customer request '
            'matches your services.',
      );
    }

    final visible = vm.filteredAssignments;

    return Column(
      children: [
        _AssignmentFilters(vm: vm),
        Expanded(
          child: visible.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  message:
                      'No assignments match "${vm.assignmentQuery ?? ''}".',
                  actionLabel: 'Clear filters',
                  onAction: () {
                    vm.setAssignmentQuery(null);
                    vm.setAssignmentStatusFilter(null);
                  },
                )
              : RefreshIndicator(
                  onRefresh: vm.fetchAssignments,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) =>
                        ProviderAssignmentCard(assignment: visible[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _AssignmentFilters extends StatelessWidget {
  final ProviderViewModel vm;

  const _AssignmentFilters({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AppSearchBar(
              hintText: 'Search request reference',
              onChanged: vm.setAssignmentQuery,
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: vm.assignmentStatusFilter == null,
                  onTap: () => vm.setAssignmentStatusFilter(null),
                ),
                for (final status in assignmentStatusFilters)
                  _FilterChip(
                    label: getStatusDisplayName(status),
                    isSelected:
                        vm.assignmentStatusFilter?.toUpperCase() ==
                        status.toUpperCase(),
                    onTap: () => vm.setAssignmentStatusFilter(status),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.darkNavyBlue : AppColors.lightGrey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.white : AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}

class ProviderAssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;

  const ProviderAssignmentCard({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final actions = assignmentStatusActions(assignment.status);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () =>
          Navigator.pushNamed(context, '/provider/assignment/${assignment.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request reference',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shortReference(assignment.serviceRequestId),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavyBlue,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: assignment.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 15,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                'Item ${shortReference(assignment.serviceRequestItemId)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: assignmentStatusActionLabel(actions.first),
                    icon: _iconFor(actions.first),
                    height: 38,
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/provider/assignment/${assignment.id}',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: 'View details',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/provider/assignment/${assignment.id}',
                  ),
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static IconData _iconFor(String status) {
    switch (status.toUpperCase()) {
      case AssignmentStatus.accepted:
        return Icons.check;
      case AssignmentStatus.onTheWay:
        return Icons.directions_car_outlined;
      case AssignmentStatus.inProgress:
        return Icons.play_arrow;
      case AssignmentStatus.completed:
        return Icons.task_alt;
      default:
        return Icons.arrow_forward;
    }
  }
}

String shortReference(String id) {
  if (id.isEmpty) return '—';
  return id.length <= 8 ? id : id.substring(0, 8).toUpperCase();
}
