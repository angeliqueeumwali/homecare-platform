import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/service_request_model.dart';
import 'package:mobile/providers/service_provider.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/widgets/service_category_widgets.dart';

/// Browsable list of the services the backend offers, with client-side search.
class ServiceCategoriesScreen extends StatefulWidget {
  const ServiceCategoriesScreen({super.key, this.categoryId});

  /// When set, the screen opens straight onto that service's details.
  final String? categoryId;

  @override
  State<ServiceCategoriesScreen> createState() =>
      _ServiceCategoriesScreenState();
}

class _ServiceCategoriesScreenState extends State<ServiceCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ServiceCategoryViewModel>();
      if (!vm.hasLoadedOnce) vm.fetchCategories();
    });
  }

  Future<void> _openDetails(ServiceCategoryModel category) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ServiceDetailsScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ServiceCategoryViewModel>();
    final results = vm.filteredCategories;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Services'),
        backgroundColor: AppColors.white,
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
              hintText: 'Search services',
              onChanged: vm.setQuery,
            ),
          ),
          Expanded(child: _buildBody(vm, results)),
        ],
      ),
    );
  }

  Widget _buildBody(
    ServiceCategoryViewModel vm,
    List<ServiceCategoryModel> results,
  ) {
    if (vm.isLoading && !vm.hasLoadedOnce) {
      return const AppLoadingIndicator(message: 'Loading services');
    }

    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        message: vm.query.isEmpty
            ? 'No services are available right now.'
            : 'No services match "${vm.query}".',
        actionLabel: vm.query.isEmpty ? null : 'Clear search',
        onAction: vm.query.isEmpty ? null : () => vm.setQuery(''),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final category = results[index];
        return AppCard(
          margin: EdgeInsets.zero,
          onTap: () => _openDetails(category),
          child: Row(
            children: [
              ServiceCategoryImage(
                category: category,
                size: 56,
                borderRadius: 12,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainText,
                      ),
                    ),
                    if (category.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        category.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.secondaryText),
            ],
          ),
        );
      },
    );
  }
}

/// Single service view with a booking action. Tapping "Request this service"
/// opens the request form with this category already chosen.
class ServiceDetailsScreen extends StatelessWidget {
  final ServiceCategoryModel category;

  const ServiceDetailsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Service details'),
        backgroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppBorderRadius.large),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: ServiceCategoryImage(
                        category: category,
                        fill: true,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavyBlue,
                    ),
                  ),
                  if (category.description != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      category.description!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.borderGrey)),
              ),
              child: AppButton(
                text: 'Request this service',
                icon: Icons.assignment_outlined,
                width: double.infinity,
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/service-request',
                  arguments: category,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
