import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/models/service_request_model.dart';
import 'package:mobile/providers/service_provider.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/widgets/service_category_widgets.dart';

/// One line in a request being reviewed before it is sent.
class RequestDraftItem {
  final ServiceCategoryModel category;
  final String? notes;

  const RequestDraftItem({required this.category, this.notes});
}

/// Everything the customer entered, held while they review it. Passing one of
/// these between screens keeps the review step in sync with the form.
class RequestDraft {
  final String address;
  final double latitude;
  final double longitude;
  final DateTime? preferredDate;
  final String? notes;
  final List<RequestDraftItem> items;

  const RequestDraft({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.preferredDate,
    this.notes,
    required this.items,
  });

  List<Map<String, dynamic>> toItemsPayload() => items
      .map(
        (item) => {
          'service_category_id': item.category.id,
          if (item.notes != null && item.notes!.isNotEmpty) 'notes': item.notes,
        },
      )
      .toList();
}

/// Shows the full request for a last check, then submits it. The confirmation
/// screen is only reached once the backend has actually created the request.
class RequestReviewScreen extends StatefulWidget {
  final RequestDraft draft;

  const RequestReviewScreen({super.key, required this.draft});

  @override
  State<RequestReviewScreen> createState() => _RequestReviewScreenState();
}

class _RequestReviewScreenState extends State<RequestReviewScreen> {
  Future<void> _submit() async {
    final draft = widget.draft;
    final vm = context.read<ServiceRequestViewModel>();
    vm.clearError();

    final created = await vm.createRequest(
      address: draft.address,
      latitude: draft.latitude,
      longitude: draft.longitude,
      preferredDate: draft.preferredDate,
      notes: draft.notes,
      items: draft.toItemsPayload(),
    );

    if (!mounted) return;

    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Could not submit your request'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // Only reached after a real success response from POST /service-requests.
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RequestConfirmationScreen(request: created),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final vm = context.watch<ServiceRequestViewModel>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Review request'),
        backgroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const _ReviewNotice(),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Services requested',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavyBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final item in draft.items)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ServiceCategoryImage(
                                  category: item.category,
                                  size: 40,
                                  borderRadius: 8,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.category.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.mainText,
                                        ),
                                      ),
                                      if (item.notes != null &&
                                          item.notes!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.notes!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.secondaryText,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Text(
                              '${draft.items.length} '
                              'service${draft.items.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: vm.isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.darkNavyBlue,
                                minimumSize: const Size(
                                  64,
                                  AppConstants.minTouchTarget,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Where and when',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavyBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        InfoRow(
                          label: 'Address',
                          value: draft.address,
                          icon: Icons.location_on_outlined,
                        ),
                        InfoRow(
                          label: 'Coordinates',
                          value:
                              '${draft.latitude.toStringAsFixed(5)}, '
                              '${draft.longitude.toStringAsFixed(5)}',
                          icon: Icons.my_location_outlined,
                        ),
                        InfoRow(
                          label: 'Preferred',
                          value: draft.preferredDate == null
                              ? 'Any available date'
                              : _formatDate(draft.preferredDate!),
                          icon: Icons.event_outlined,
                        ),
                        if (draft.notes != null && draft.notes!.isNotEmpty)
                          InfoRow(
                            label: 'Notes',
                            value: draft.notes,
                            icon: Icons.notes_outlined,
                          ),
                        const Divider(height: AppSpacing.lg),
                        const Text(
                          'Providers will send you quotes. You choose who to '
                          'work with, then pay for the quote you approve.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                text: 'Submit request',
                icon: Icons.check_circle_outline,
                width: double.infinity,
                isLoading: vm.isLoading,
                onPressed: vm.isLoading ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$month-$day at $hour:$minute';
  }
}

class _ReviewNotice extends StatelessWidget {
  const _ReviewNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkNavyBlue,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      child: const Row(
        children: [
          Icon(Icons.fact_check_outlined, color: AppColors.white, size: 22),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Check everything is right before you send this request.',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Success screen, shown only for a request the backend really created.
class RequestConfirmationScreen extends StatelessWidget {
  final ServiceRequestModel request;

  const RequestConfirmationScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 44,
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Request sent',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavyBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your request for ${request.items.length} '
                'service${request.items.length == 1 ? '' : 's'} is now '
                '${getStatusDisplayName(request.status).toLowerCase()}. '
                'We will notify you when providers send quotes.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                child: Column(
                  children: [
                    InfoRow(label: 'Reference', value: _shortId(request.id)),
                    InfoRow(
                      label: 'Status',
                      trailing: StatusBadge(status: request.status),
                    ),
                    InfoRow(label: 'Address', value: request.address),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                text: 'View my requests',
                width: double.infinity,
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/request/${request.id}',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                text: 'Back to home',
                outlined: true,
                width: double.infinity,
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/customer',
                  (route) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortId(String id) =>
      id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
}
