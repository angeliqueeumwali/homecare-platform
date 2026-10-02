import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/models/service_request_model.dart';
import 'package:mobile/providers/service_provider.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';

/// The customer's real requests, from `GET /service-requests/me`, with a
/// client-side search and status filter.
class ServiceRequestHistoryScreen extends StatefulWidget {
  const ServiceRequestHistoryScreen({super.key, this.statusFilter});

  /// Optional filter to apply on open, used when arriving from elsewhere.
  final String? statusFilter;

  @override
  State<ServiceRequestHistoryScreen> createState() =>
      _ServiceRequestHistoryScreenState();
}

class _ServiceRequestHistoryScreenState
    extends State<ServiceRequestHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ServiceRequestViewModel>();
      if (widget.statusFilter != null) {
        vm.setStatusFilter(widget.statusFilter!);
      }
      if (!vm.hasLoadedOnce) vm.fetchMyRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ServiceRequestViewModel>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('My requests'),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoading ? null : vm.fetchMyRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AppSearchBar(
              hintText: 'Search by address or notes',
              onChanged: vm.setQuery,
            ),
          ),
          FilterChipRow(
            options: const [
              ServiceRequestViewModel.allRequestsFilter,
              ServiceRequestStatus.pending,
              ServiceRequestStatus.inProgress,
              ServiceRequestStatus.completed,
              ServiceRequestStatus.cancelled,
            ],
            selected: vm.statusFilter,
            onSelected: vm.setStatusFilter,
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildBody(vm)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/service-request'),
        backgroundColor: AppColors.darkNavyBlue,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('New request'),
      ),
    );
  }

  Widget _buildBody(ServiceRequestViewModel vm) {
    if (vm.isLoading && !vm.hasLoadedOnce) {
      return const AppLoadingIndicator(message: 'Loading your requests');
    }

    if (vm.errorMessage != null && vm.requests.isEmpty) {
      return ErrorView(message: vm.errorMessage!, onRetry: vm.fetchMyRequests);
    }

    if (vm.requests.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        message:
            'You have not made any requests yet.\n'
            'Request a service and providers will send you quotes.',
        actionLabel: 'Request a service',
        onAction: () => Navigator.pushNamed(context, '/service-request'),
      );
    }

    final results = vm.filteredRequests;
    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.filter_alt_off_outlined,
        message: 'No requests match your search or filter.',
        actionLabel: 'Clear filters',
        onAction: () {
          vm.setQuery('');
          vm.setStatusFilter(ServiceRequestViewModel.allRequestsFilter);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: vm.fetchMyRequests,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          96,
        ),
        itemCount: results.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _RequestTile(request: results[index]),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final ServiceRequestModel request;

  const _RequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final itemCount = request.items.length;

    return AppCard(
      margin: EdgeInsets.zero,
      onTap: () => Navigator.pushNamed(context, '/request/${request.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainText,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.checklist_rtl,
                size: 15,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 4),
              Text(
                '$itemCount service${itemCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
              if (request.createdAt != null) ...[
                const SizedBox(width: AppSpacing.md),
                const Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  _relativeDate(request.createdAt!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _relativeDate(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    final now = DateTime.now();
    final days = now.difference(parsed.toLocal()).inDays;
    if (days <= 0) {
      final hours = now.difference(parsed.toLocal()).inHours;
      if (hours <= 0) return 'Just now';
      return '${hours}h ago';
    }
    if (days == 1) return 'Yesterday';
    if (days < 30) return '$days days ago';
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }
}
