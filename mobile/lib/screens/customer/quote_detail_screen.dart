import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/models/quote_model.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';

/// One quote with its accept and reject actions.
///
/// Accept and reject map to `PATCH /quotes/{id}/status` with APPROVED and
/// REJECTED, which is what the backend supports. The provider's own name and
/// rating are not available for a customer: the quote response has only a
/// `provider_id`, so that is shown as a reference instead of a made-up name.
class QuoteDetailScreen extends StatefulWidget {
  final QuoteModel quote;
  final String requestId;

  const QuoteDetailScreen({
    super.key,
    required this.quote,
    required this.requestId,
  });

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  bool _isWorking = false;

  bool get _isPending =>
      widget.quote.status.toUpperCase() == QuoteStatus.pending;

  Future<void> _decide(bool approve) async {
    final confirmed = await AppDialog.showConfirmation(
      context,
      title: approve ? 'Accept this quote?' : 'Reject this quote?',
      message: approve
          ? 'You will be able to pay ${widget.quote.currency} '
                '${widget.quote.amount} for this service.'
          : 'This provider will not be able to work on your request.',
      confirmText: approve ? 'Accept' : 'Reject',
      isDestructive: !approve,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isWorking = true);
    final vm = context.read<QuoteViewModel>();
    final ok = approve
        ? await vm.acceptQuote(widget.quote.id)
        : await vm.rejectQuote(widget.quote.id);

    if (!mounted) return;
    setState(() => _isWorking = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (approve
                    ? 'Quote accepted. You can now pay for it.'
                    : 'Quote rejected.')
              : vm.errorMessage ?? 'Could not update the quote',
        ),
        backgroundColor: ok ? AppColors.successGreen : AppColors.errorRed,
      ),
    );

    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.quote;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Quote'),
        backgroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        const Text(
                          'Your quote',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${quote.currency} ${quote.amount}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavyBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        StatusBadge(status: quote.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepNavyBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        InfoRow(
                          label: 'Description',
                          value: quote.description,
                          icon: Icons.notes_outlined,
                        ),
                        InfoRow(
                          label: 'Provider',
                          value: quote.providerId.length > 8
                              ? quote.providerId.substring(0, 8).toUpperCase()
                              : quote.providerId,
                          icon: Icons.badge_outlined,
                        ),
                        if (quote.createdAt != null)
                          InfoRow(
                            label: 'Sent',
                            value: _formatIso(quote.createdAt!),
                            icon: Icons.schedule,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.large,
                      ),
                      border: Border.all(color: AppColors.borderGrey),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _statusExplainer(quote.status),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isPending)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.borderGrey)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Reject',
                        outlined: true,
                        backgroundColor: AppColors.errorRed,
                        isLoading: _isWorking,
                        onPressed: _isWorking ? null : () => _decide(false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        text: 'Accept',
                        isLoading: _isWorking,
                        onPressed: _isWorking ? null : () => _decide(true),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _statusExplainer(String status) {
    switch (status.toUpperCase()) {
      case QuoteStatus.approved:
        return 'You accepted this quote. Payment is available from the '
            'request details screen.';
      case QuoteStatus.rejected:
        return 'You rejected this quote.';
      default:
        return 'This quote is waiting for your decision. Accept it to go '
            'ahead with this provider.';
    }
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
