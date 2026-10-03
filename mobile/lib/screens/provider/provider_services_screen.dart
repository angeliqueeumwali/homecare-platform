import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/service_request_model.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/providers/service_provider.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/widgets/approval_status_banner.dart';
import 'package:mobile/widgets/service_category_widgets.dart';

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> {
  @override
  void initState() {
    super.initState();
    final providerViewModel = context.read<ProviderViewModel>();
    final categoryViewModel = context.read<ServiceCategoryViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      providerViewModel.fetchServices();
      categoryViewModel.fetchCategories();
    });
  }

  Future<void> _addService() async {
    final categoryState = context.read<ServiceCategoryViewModel>();
    final providerState = context.read<ProviderViewModel>();
    final alreadyOffered = providerState.services
        .map((s) => s.serviceCategoryId)
        .toSet();

    final available = categoryState.categories
        .where((c) => c.isActive && !alreadyOffered.contains(c.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already offer every service.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<ServiceCategoryModel>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Text(
              'Add a service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavyBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final category in available)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ServiceCategoryImage(
                  category: category,
                  size: 44,
                  borderRadius: 10,
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainText,
                  ),
                ),
                subtitle: category.description == null
                    ? null
                    : Text(
                        category.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                onTap: () => Navigator.pop(context, category),
              ),
          ],
        ),
      ),
    );

    if (selected == null || !mounted) return;

    final ok = await providerState.addService(selected.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${selected.name} added to your services'
              : providerState.errorMessage ?? 'Could not add the service',
        ),
        backgroundColor: ok ? AppColors.successGreen : AppColors.errorRed,
      ),
    );
  }

  Future<void> _removeService(ServiceCategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove service'),
        content: Text(
          'Remove ${category.name} from the services you offer? '
          'Existing assignments are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final vm = context.read<ProviderViewModel>();
    final ok = await vm.removeService(category.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '${category.name} removed'
              : vm.errorMessage ?? 'Could not remove the service',
        ),
        backgroundColor: ok ? AppColors.successGreen : AppColors.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerState = context.watch<ProviderViewModel>();
    final categories = context.watch<ServiceCategoryViewModel>().categories;
    final byId = {for (final c in categories) c.id: c};

    final offered = providerState.services
        .map((s) => byId[s.serviceCategoryId])
        .whereType<ServiceCategoryModel>()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('My Services'),
        backgroundColor: AppColors.white,
      ),
      body: _buildBody(providerState, offered),
      floatingActionButton: providerState.isApprovedProvider
          ? FloatingActionButton.extended(
              onPressed: _addService,
              backgroundColor: AppColors.darkNavyBlue,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add service'),
            )
          : null,
    );
  }

  Widget _buildBody(
    ProviderViewModel providerState,
    List<ServiceCategoryModel> offered,
  ) {
    if (!providerState.isApprovedProvider &&
        providerState.accountState != ProviderAccountState.none &&
        !providerState.isCheckingAccount) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ApprovalStatusBanner(
            state: providerState.accountState,
            businessName: providerState.profile?.businessName,
          ),
          const AppCard(
            child: Text(
              'The services you offer are managed once an administrator '
              'approves this account.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      );
    }

    if (providerState.isLoading && offered.isEmpty) {
      return const AppLoadingIndicator(message: 'Loading your services');
    }

    if (providerState.errorMessage != null && offered.isEmpty) {
      return ErrorView(
        message: providerState.errorMessage!,
        onRetry: providerState.fetchServices,
      );
    }

    if (offered.isEmpty) {
      return EmptyState(
        message:
            'No services added yet.\n'
            'Add the services you offer so an administrator can match you to '
            'customer requests.',
        actionLabel: 'Add a service',
        onAction: _addService,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: offered.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final category = offered[index];
        return AppCard(
          margin: const EdgeInsets.only(bottom: 0),
          child: Row(
            children: [
              ServiceCategoryImage(
                category: category,
                size: 52,
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
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
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
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove ${category.name}',
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.errorRed,
                ),
                onPressed: () => _removeService(category),
              ),
            ],
          ),
        );
      },
    );
  }
}
