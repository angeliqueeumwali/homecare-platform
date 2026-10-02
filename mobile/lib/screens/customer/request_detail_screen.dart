import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/models/service_request_model.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/screens/customer/quote_detail_screen.dart';
import 'package:mobile/providers/service_provider.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/widgets/service_category_widgets.dart';
import 'package:mobile/widgets/status_timeline.dart';

/// Details of one request: what was asked, where it has got to, and any quotes
/// providers have sent.
class ServiceRequestDetailScreen extends StatefulWidget {
  final String requestId;

  const ServiceRequestDetailScreen({super.key, required this.requestId});

  @override
  State<ServiceRequestDetailScreen> createState() =>
      _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState
    extends State<ServiceRequestDetailScreen> {
  ServiceRequestModel? _request;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant ServiceRequestDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestId != widget.requestId) _load();
  }

  Future<void> _load() async {
    final requestVm = context.read<ServiceRequestViewModel>();
    requestVm.clearError();
    final loaded = await requestVm.getRequestById(widget.requestId);

    if (!mounted) return;

    setState(() {
      _request = loaded;
      _error = loaded == null ? requestVm.errorMessage : null;
    });

    // Quotes belong to this request only.
    if (loaded != null) {
      await context.read<QuoteViewModel>().fetchRequestQuotes(loaded.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Request details'),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_request == null && _error == null) {
      return const AppLoadingIndicator(message: 'Loading request');
    }

    if (_request == null) {
      return ErrorView(
        message: _error ?? 'Could not load this request',
        onRetry: _load,
      );
    }

    final request = _request!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.address,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepNavyBlue,
                      ),
                    ),
                  ),
                  StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              InfoRow(
                label: 'Reference',
                value: request.id.length > 8
                    ? request.id.substring(0, 8).toUpperCase()
                    : request.id,
              ),
              if (request.createdAt != null)
                InfoRow(
                  label: 'Created',
                  value: _formatIso(request.createdAt!),
                ),
              if (request.preferredDate != null)
                InfoRow(
                  label: 'Preferred',
                  value: _formatIso(request.preferredDate!),
                ),
              InfoRow(
                label: 'Coordinates',
                value:
                    '${request.latitude.toStringAsFixed(5)}, '
                    '${request.longitude.toStringAsFixed(5)}',
              ),
              if (request.notes != null && request.notes!.isNotEmpty)
                InfoRow(label: 'Notes', value: request.notes),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepNavyBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              StatusTimeline(
                currentStatus: _timelineStatus(request),
                steps: serviceRequestTimelineSteps,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Shown from the current status the backend reports.',
                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildItems(request),
        const SizedBox(height: AppSpacing.md),
        _buildQuotes(request),
      ],
    );
  }

  Widget _buildItems(ServiceRequestModel request) {
    // The backend's item response only carries a category id, so the name and
    // image are resolved from the categories already loaded in the app.
    final categories = {
      for (final c in context.watch<ServiceCategoryViewModel>().categories)
        c.id: c,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavyBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in request.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ServiceCategoryImage(
                    category: categories[item.serviceCategoryId],
                    size: 38,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categories[item.serviceCategoryId]?.name ?? 'Service',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainText,
                          ),
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.notes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        StatusBadge(status: item.status, fontSize: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuotes(ServiceRequestModel request) {
    final quoteVm = context.watch<QuoteViewModel>();
    // Ignore quotes left over from a different request.
    final quotes = quoteVm.activeRequestId == request.id
        ? quoteVm.quotes
        : const [];

    if (quoteVm.isLoading && quoteVm.activeRequestId == request.id) {
      return const AppCard(
        child: AppLoadingIndicator(inline: true, message: 'Loading quotes'),
      );
    }

    if (quoteVm.errorMessage != null && quotes.isEmpty) {
      return AppCard(
        child: Text(
          'Could not load quotes: ${quoteVm.errorMessage}',
          style: const TextStyle(fontSize: 13, color: AppColors.errorRed),
        ),
      );
    }

    if (quotes.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quotes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.deepNavyBlue,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'No providers have sent quotes for this request yet.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quotes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavyBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final quote in quotes)
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      QuoteDetailScreen(quote: quote, requestId: request.id),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${quote.currency} ${quote.amount}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavyBlue,
                            ),
                          ),
                          if (quote.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              quote.description!,
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
                    const SizedBox(width: AppSpacing.sm),
                    StatusBadge(status: quote.status, fontSize: 10),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The backend stores one status per request and per item. The item status
  /// is the more specific one, so it drives the timeline when available.
  String _timelineStatus(ServiceRequestModel request) {
    if (request.items.isNotEmpty) {
      return request.items.first.status;
    }
    return request.status;
  }

  static String _formatIso(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final local = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
