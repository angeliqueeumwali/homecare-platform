import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/customer/service_categories_screen.dart';
import 'package:mobile/providers/service_provider.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/widgets/promo_banner.dart';
import 'package:mobile/widgets/service_category_widgets.dart';

/// Customer home: welcome, search, banner, service categories from the
/// backend, active requests, and a prominent way to start a new request.
class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = context.read<ServiceCategoryViewModel>();
      final requests = context.read<ServiceRequestViewModel>();
      if (!categories.hasLoadedOnce) categories.fetchCategories();
      if (!requests.hasLoadedOnce) requests.fetchMyRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final categoryVm = context.watch<ServiceCategoryViewModel>();
    final requestVm = context.watch<ServiceRequestViewModel>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              categoryVm.fetchCategories(),
              requestVm.fetchMyRequests(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              _WelcomeHeader(
                firstName: user?.firstName ?? '',
                onNotifications: () =>
                    Navigator.pushNamed(context, '/notifications'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppSearchBar(
                  hintText: 'Search services',
                  onChanged: categoryVm.setQuery,
                  onFilterTap: () =>
                      Navigator.pushNamed(context, '/categories'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PromoBanner(
                title: 'Care you can count on',
                subtitle: 'Verified providers, clear quotes and no surprises.',
                icon: Icons.verified_outlined,
                actionLabel: 'Request a service',
                onAction: () =>
                    Navigator.pushNamed(context, '/service-request'),
              ),
              const SectionHeader(title: 'Services'),
              _buildCategories(categoryVm),
              const SectionHeader(
                title: 'Your active requests',
                actionLabel: 'See all',
              ),
              _ActiveSection(
                onViewAll: () => Navigator.pushNamed(context, '/request-list'),
              ),
              if (requestVm.requests.isNotEmpty)
                SectionHeader(
                  title: 'Recently completed',
                  actionLabel: 'See all',
                  onAction: () {
                    requestVm.setStatusFilter(ServiceRequestStatus.completed);
                    Navigator.pushNamed(context, '/request-list');
                  },
                ),
              if (requestVm.requests.isNotEmpty) _buildCompleted(requestVm),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: AppButton(
                  text: 'Request a Service',
                  icon: Icons.add_circle_outline,
                  width: double.infinity,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/service-request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories(ServiceCategoryViewModel vm) {
    if (vm.isLoading && !vm.hasLoadedOnce) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: AppLoadingIndicator(message: 'Loading services'),
      );
    }

    if (vm.errorMessage != null && vm.categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ErrorView(
          message: vm.errorMessage!,
          onRetry: vm.fetchCategories,
        ),
      );
    }

    final results = vm.filteredCategories;
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: EmptyState(
          icon: Icons.search_off,
          message: vm.query.isEmpty
              ? 'No services available yet.'
              : 'No services match "${vm.query}".',
          actionLabel: vm.query.isEmpty ? null : 'Clear search',
          onAction: vm.query.isEmpty ? null : () => vm.setQuery(''),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final category = results[index];
        return AppCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ServiceDetailsScreen(category: category),
            ),
          ),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ServiceCategoryImage(
                  category: category,
                  fill: true,
                  borderRadius: 0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  category.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainText,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompleted(ServiceRequestViewModel vm) {
    final completed = vm.requests
        .where((r) => r.status.toUpperCase() == ServiceRequestStatus.completed)
        .take(3)
        .toList();

    return Column(
      children: [
        for (final request in completed)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AppCard(
              margin: EdgeInsets.zero,
              onTap: () =>
                  Navigator.pushNamed(context, '/request/${request.id}'),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.successGreen,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainText,
                          ),
                        ),
                        Text(
                          '${request.items.length} service'
                          '${request.items.length == 1 ? '' : 's'} completed',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.reviews_outlined,
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String firstName;
  final VoidCallback onNotifications;

  const _WelcomeHeader({
    required this.firstName,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello${firstName.isEmpty ? '' : ', $firstName'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepNavyBlue,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'What can we help you with today?',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
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
              color: AppColors.deepNavyBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveSection extends StatelessWidget {
  final VoidCallback onViewAll;

  const _ActiveSection({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ServiceRequestViewModel>();
    final active = vm.activeRequests.take(3).toList();

    if (vm.isLoading && !vm.hasLoadedOnce) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: AppLoadingIndicator(message: 'Loading your requests'),
      );
    }

    if (vm.errorMessage != null && vm.requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ErrorView(
          message: vm.errorMessage!,
          onRetry: vm.fetchMyRequests,
        ),
      );
    }

    if (active.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No active requests',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'When you book a service it will show here so you can follow '
                'quotes and payment.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final request in active)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AppCard(
              margin: EdgeInsets.zero,
              onTap: () =>
                  Navigator.pushNamed(context, '/request/${request.id}'),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.darkNavyBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.medium,
                      ),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.darkNavyBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainText,
                          ),
                        ),
                        Text(
                          '${request.items.length} service'
                          '${request.items.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: request.status, fontSize: 10),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
