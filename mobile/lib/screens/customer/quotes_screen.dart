import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/screens/customer/quote_detail_screen.dart';

/// Quotes for one request, from `GET /quotes/request/{request_id}`.
///
/// This is the list of competing provider offers for a request. Accepting one
/// is what unlocks payment, because the backend only accepts a payment for an
/// APPROVED quote.
class QuotesScreen extends StatefulWidget {
  final String? requestId;

  const QuotesScreen({super.key, this.requestId});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.requestId;
      if (id != null) {
        context.read<QuoteViewModel>().fetchRequestQuotes(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<QuoteViewModel>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Quotes'),
        backgroundColor: AppColors.white,
        actions: [
          if (widget.requestId != null)
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: vm.isLoading
                  ? null
                  : () => context.read<QuoteViewModel>().fetchRequestQuotes(
                      widget.requestId!,
                    ),
            ),
        ],
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(QuoteViewModel vm) {
    if (widget.requestId == null) {
      return const EmptyState(
        icon: Icons.request_quote_outlined,
        message: 'Open a request to see the quotes providers have sent.',
      );
    }

    if (vm.isLoading) {
      return const AppLoadingIndicator(message: 'Loading quotes');
    }

    if (vm.errorMessage != null && vm.quotes.isEmpty) {
      return ErrorView(
        message: vm.errorMessage!,
        onRetry: () => context.read<QuoteViewModel>().fetchRequestQuotes(
          widget.requestId!,
        ),
      );
    }

    if (vm.quotes.isEmpty) {
      return const EmptyState(
        icon: Icons.request_quote_outlined,
        message:
            'No quotes yet.\n'
            'Providers will send offers once they see your request.',
      );
    }

    final pending = vm.quotes
        .where((q) => q.status.toUpperCase() == QuoteStatus.pending)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (pending.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.darkNavyBlue,
                borderRadius: BorderRadius.circular(AppBorderRadius.large),
              ),
              child: Text(
                'Accept one quote to go ahead with that provider. You can only '
                'pay for a quote you have accepted.',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
        for (final quote in vm.quotes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              margin: EdgeInsets.zero,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => QuoteDetailScreen(
                    quote: quote,
                    requestId: widget.requestId!,
                  ),
                ),
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavyBlue,
                          ),
                        ),
                        if (quote.description != null &&
                            quote.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            quote.description!,
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
                  const SizedBox(width: AppSpacing.sm),
                  StatusBadge(status: quote.status, fontSize: 10),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
