import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/models/payment_model.dart';
import 'package:mobile/models/quote_model.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';

/// Payment history from `GET /payments/me`, plus the pay action for an approved
/// quote.
///
/// The backend creates payments as PENDING and only an administrator can move
/// one to PAID (`PATCH /payments/{id}/status` is ADMIN-only). This screen
/// therefore reports exactly what the API returns and never treats a submitted
/// payment as paid.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, this.requestId, this.quote});

  /// When supplied, opens straight onto paying this approved quote.
  final String? requestId;
  final QuoteModel? quote;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentViewModel>().fetchMyPayments();
      final quote = widget.quote;
      if (quote != null) {
        _openPaySheet(quote);
      }
    });
  }

  Future<void> _openPaySheet(QuoteModel quote) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaySheet(requestId: widget.requestId, quote: quote),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PaymentViewModel>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoading ? null : vm.fetchMyPayments,
          ),
        ],
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(PaymentViewModel vm) {
    if (vm.isLoading && vm.payments.isEmpty) {
      return const AppLoadingIndicator(message: 'Loading payments');
    }

    if (vm.errorMessage != null && vm.payments.isEmpty) {
      return ErrorView(message: vm.errorMessage!, onRetry: vm.fetchMyPayments);
    }

    if (vm.payments.isEmpty) {
      return EmptyState(
        icon: Icons.payments_outlined,
        message:
            'You have not made any payments yet.\n'
            'Approve a quote on a request to be able to pay for it.',
        actionLabel: 'View my requests',
        onAction: () => Navigator.pushNamed(context, '/request-list'),
      );
    }

    final paid = vm.payments
        .where((p) => p.status.toUpperCase() == PaymentStatus.paid)
        .fold<double>(0, (sum, p) {
          final value = double.tryParse(p.amount);
          return sum + (value ?? 0);
        });
    final pendingCount = vm.payments
        .where((p) => p.status.toUpperCase() == PaymentStatus.pending)
        .length;

    return RefreshIndicator(
      onRefresh: vm.fetchMyPayments,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            backgroundColor: AppColors.darkNavyBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment summary',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _formatAmount(paid, vm.payments.first.currency),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const Text(
                  'confirmed as paid',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: 'Payments',
                        value: '${vm.payments.length}',
                      ),
                    ),
                    Expanded(
                      child: _SummaryTile(
                        label: 'Awaiting confirmation',
                        value: '$pendingCount',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'A payment stays pending until the backend confirms it. '
            'Nothing here changes on its own.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final payment in vm.payments)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PaymentTile(payment: payment),
            ),
        ],
      ),
    );
  }

  static String _formatAmount(double value, String currency) {
    final text = value.toStringAsFixed(2);
    return currency.isEmpty ? text : '$currency $text';
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavyBlue,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentModel payment;

  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.status.toUpperCase() == PaymentStatus.paid;

    return AppCard(
      margin: EdgeInsets.zero,
      onTap: () =>
          Navigator.pushNamed(context, '/request/${payment.serviceRequestId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${payment.currency} ${payment.amount}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepNavyBlue,
                  ),
                ),
              ),
              StatusBadge(status: payment.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          InfoRow(label: 'Method', value: _methodLabel(payment.paymentMethod)),
          if (payment.transactionReference != null)
            InfoRow(label: 'Reference', value: payment.transactionReference),
          if (payment.createdAt != null)
            InfoRow(label: 'Created', value: _formatIso(payment.createdAt!)),
          if (isPaid) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 15,
                  color: AppColors.successGreen,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Confirmed as paid by the backend.',
                  style: TextStyle(fontSize: 12, color: AppColors.successGreen),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _methodLabel(String method) {
    switch (method.toUpperCase()) {
      case PaymentMethod.mobileMoney:
        return 'Mobile money';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.cash:
        return 'Cash';
      default:
        return method;
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

/// Confirms the amount and method, then creates the payment. The message shown
/// afterwards always comes from the status the API returns.
class _PaySheet extends StatefulWidget {
  final String? requestId;
  final QuoteModel quote;

  const _PaySheet({required this.requestId, required this.quote});

  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  String? _selectedMethod;
  bool _isSubmitting = false;

  static const List<({String value, String label})> _methods = [
    (value: PaymentMethod.mobileMoney, label: 'Mobile money'),
    (value: PaymentMethod.card, label: 'Card'),
    (value: PaymentMethod.cash, label: 'Cash'),
  ];

  Future<void> _submit() async {
    final method = _selectedMethod;
    if (method == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a payment method')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final vm = context.read<PaymentViewModel>();
    final payment = await vm.createPayment(
      serviceRequestId: widget.requestId!,
      quoteId: widget.quote.id,
      amount: widget.quote.amount,
      currency: widget.quote.currency,
      paymentMethod: method,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (payment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Could not create the payment'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    // The sheet route is pushed as `void`, so pop() has no result to await.
    Navigator.pop(context);
    if (!mounted) return;

    // Report the real status. Only PAID from the API counts as paid.
    final isPaid = payment.status.toUpperCase() == PaymentStatus.paid;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Row(
          children: [
            Icon(
              isPaid ? Icons.check_circle : Icons.schedule,
              color: isPaid ? AppColors.successGreen : AppColors.warningAmber,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(isPaid ? 'Payment successful' : 'Payment pending'),
          ],
        ),
        content: Text(
          isPaid
              ? 'The backend confirmed your payment.'
              : 'Your payment was recorded and is waiting for confirmation. '
                    'It will show as paid once the backend reports it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Confirm payment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavyBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                InfoRow(
                  label: 'Amount',
                  value: widget.quote.currency + ' ' + widget.quote.amount,
                ),
                const InfoRow(label: 'Request', value: 'Service request'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Payment method',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.mainText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final method in _methods)
            RadioListTile<String>(
              value: method.value,
              groupValue: _selectedMethod,
              onChanged: (value) => setState(() => _selectedMethod = value),
              title: Text(method.label, style: const TextStyle(fontSize: 14)),
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.darkNavyBlue,
            ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Pay ${widget.quote.currency} ${widget.quote.amount}',
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'You will see the real payment status. It is not marked as paid '
            'automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
