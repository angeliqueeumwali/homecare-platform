import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/models/assignment_model.dart';
import 'package:mobile/models/quote_model.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/screens/provider/provider_assignments_screen.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/widgets/status_timeline.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) =>
          context.read<ProviderViewModel>().loadAssignment(widget.assignmentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProviderViewModel>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Assignment'),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoadingAssignment
                ? null
                : () => vm.refreshSelectedAssignment(),
          ),
        ],
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(ProviderViewModel vm) {
    if (vm.isLoadingAssignment && vm.selectedAssignment == null) {
      return const AppLoadingIndicator(message: 'Loading assignment');
    }

    if (vm.selectedAssignment == null) {
      return ErrorView(
        message:
            vm.assignmentErrorMessage ?? 'This assignment could not be loaded.',
        onRetry: () => vm.loadAssignment(widget.assignmentId),
      );
    }

    final assignment = vm.selectedAssignment!;

    return RefreshIndicator(
      onRefresh: vm.refreshSelectedAssignment,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _StatusHeader(assignment: assignment),
          const SizedBox(height: AppSpacing.md),
          _ReferenceCard(assignment: assignment),
          const SizedBox(height: AppSpacing.md),
          _StatusTimelineCard(assignment: assignment),
          const SizedBox(height: AppSpacing.md),
          _UnavailableRequestNotice(),
          const SizedBox(height: AppSpacing.md),
          if (assignmentStatusActions(assignment.status).isNotEmpty)
            _ActionCard(
              assignment: assignment,
              isUpdating: vm.isUpdatingAssignment,
              onAction: (status) => _runStatusAction(vm, assignment, status),
            ),
          if (assignmentStatusActions(assignment.status).isNotEmpty)
            const SizedBox(height: AppSpacing.md),
          _QuotesCard(vm: vm),
        ],
      ),
    );
  }

  Future<void> _runStatusAction(
    ProviderViewModel vm,
    AssignmentModel assignment,
    String status,
  ) async {
    final vmBefore = vm;
    if (assignmentStatusNeedsConfirmation(status)) {
      final confirmed = await _confirm(
        title: assignmentStatusActionLabel(status),
        message:
            '${assignmentStatusActionLabel(status)} for request '
            '${shortReference(assignment.serviceRequestId)}?',
        confirmLabel: assignmentStatusActionLabel(status),
        isDestructive:
            status == AssignmentStatus.declined ||
            status == AssignmentStatus.cancelled,
      );
      if (confirmed != true) return;
    }

    final error = await vmBefore.changeAssignmentStatus(assignment.id, status);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Status updated to ${getStatusDisplayName(status)}',
        ),
        backgroundColor: error == null
            ? AppColors.successGreen
            : AppColors.errorRed,
      ),
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDestructive
                    ? AppColors.errorRed
                    : AppColors.darkNavyBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final AssignmentModel assignment;

  const _StatusHeader({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkNavyBlue,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT STATUS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xB3FFFFFF),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            getStatusDisplayName(assignment.status),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StatusBadge(status: assignment.status, invert: true),
        ],
      ),
    );
  }
}

class _ReferenceCard extends StatelessWidget {
  final AssignmentModel assignment;

  const _ReferenceCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'References',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavyBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(label: 'Assignment', value: shortReference(assignment.id)),
          _DetailRow(
            label: 'Service request',
            value: shortReference(assignment.serviceRequestId),
          ),
          _DetailRow(
            label: 'Request item',
            value: shortReference(assignment.serviceRequestItemId),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.mainText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimelineCard extends StatelessWidget {
  final AssignmentModel assignment;

  const _StatusTimelineCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final index = timelineStepIndex(assignment.status, assignmentTimelineSteps);
    final isTerminal = isFinishedAssignmentStatus(assignment.status);

    return AppCard(
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
          if (isTerminal)
            Text(
              'This assignment is ${getStatusDisplayName(assignment.status).toLowerCase()} and will not change again.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            )
          else if (index == -1)
            Text(
              'The backend reported "${assignment.status}", which is not part of the normal job flow.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            )
          else
            StatusTimeline(
              currentStatus: assignment.status,
              steps: assignmentTimelineSteps,
            ),
        ],
      ),
    );
  }
}

class _UnavailableRequestNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.lightGrey,
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
              'The service address, customer details and request notes are not '
              'shown: the backend returns 403 when a provider opens a '
              'service request. Quote from the request reference and confirm '
              'the location with the customer directly.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final AssignmentModel assignment;
  final bool isUpdating;
  final ValueChanged<String> onAction;

  const _ActionCard({
    required this.assignment,
    required this.isUpdating,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final actions = assignmentStatusActions(assignment.status);
    final isDeclineOnly =
        actions.length == 1 && actions.first == AssignmentStatus.declined;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isDeclineOnly ? 'Respond' : 'Next steps',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavyBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Only the actions below are offered for this status.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _ActionButton(
              status: actions[i],
              isPrimary: i == 0,
              isUpdating: isUpdating,
              onTap: () => onAction(actions[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String status;
  final bool isPrimary;
  final bool isUpdating;
  final VoidCallback onTap;

  const _ActionButton({
    required this.status,
    required this.isPrimary,
    required this.isUpdating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDecline = status == AssignmentStatus.declined;
    final isCancel = status == AssignmentStatus.cancelled;
    final destructive = isDecline || isCancel;

    return AppButton(
      text: assignmentStatusActionLabel(status),
      isLoading: isUpdating && isPrimary,
      outlined: destructive,
      backgroundColor: destructive
          ? AppColors.errorRed
          : AppColors.darkNavyBlue,
      textColor: destructive ? AppColors.errorRed : AppColors.white,
      onPressed: isUpdating ? null : onTap,
    );
  }
}

class _QuotesCard extends StatelessWidget {
  final ProviderViewModel vm;

  const _QuotesCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final canQuote =
        vm.selectedAssignment != null &&
        !isFinishedAssignmentStatus(vm.selectedAssignment!.status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quotes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepNavyBlue,
                  ),
                ),
              ),
              TextButton(
                onPressed: canQuote && !vm.isLoadingQuotes
                    ? () => _openQuoteSheet(context, vm)
                    : null,
                child: Text(
                  canQuote ? 'Add quote' : 'Job closed',
                  style: const TextStyle(
                    color: AppColors.darkNavyBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (vm.isLoadingQuotes)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: AppLoadingIndicator(message: 'Loading quotes'),
            )
          else if (vm.errorMessage != null && vm.quotes.isEmpty)
            ErrorView(
              message: vm.errorMessage!,
              onRetry: () async {
                await vm.loadAssignment(vm.selectedAssignment!.id);
              },
            )
          else if (vm.quotes.isEmpty)
            const Text(
              'No quotes have been sent for this request yet.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            )
          else ...[
            if (vm.myQuotes.isNotEmpty) ...[
              const Text(
                'Your quotes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainText,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final quote in vm.myQuotes)
                ProviderQuoteTile(quote: quote, isMine: true),
            ],
            if (vm.quotes.length != vm.myQuotes.length) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Other quotes on this request (${vm.quotes.length - vm.myQuotes.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainText,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final quote in vm.quotes)
                if (!vm.myQuotes.any((mine) => mine.id == quote.id))
                  ProviderQuoteTile(quote: quote, isMine: false),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _openQuoteSheet(
    BuildContext context,
    ProviderViewModel vm,
  ) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ProviderQuoteForm(vm: vm),
      ),
    );

    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote sent'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }
}

class ProviderQuoteTile extends StatelessWidget {
  final QuoteModel quote;
  final bool isMine;

  const ProviderQuoteTile({
    super.key,
    required this.quote,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.darkNavyBlue.withValues(alpha: 0.05)
              : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${quote.amount} ${quote.currency}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepNavyBlue,
                    ),
                  ),
                  if (quote.description != null &&
                      quote.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      quote.description!,
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
    );
  }
}

class ProviderQuoteForm extends StatefulWidget {
  final ProviderViewModel vm;

  const ProviderQuoteForm({super.key, required this.vm});

  @override
  State<ProviderQuoteForm> createState() => _ProviderQuoteFormState();
}

class _ProviderQuoteFormState extends State<ProviderQuoteForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _currency = 'RWF';

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final error = await widget.vm.createQuoteForSelectedAssignment(
      amount: _amountController.text.trim(),
      currency: _currency,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: AppColors.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Send a quote',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepNavyBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Request ${shortReference(vm.quotesRequestId ?? '')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Amount',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.payments_outlined,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Enter an amount';
                    final amount = double.tryParse(text);
                    if (amount == null) return 'Enter a number';
                    if (amount <= 0) return 'Amount must be above zero';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Currency',
                  controller: TextEditingController(text: _currency),
                  readOnly: true,
                  prefixIcon: Icons.currency_exchange,
                  onTap: _pickCurrency,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Description (optional)',
                  controller: _descriptionController,
                  maxLines: 3,
                  prefixIcon: Icons.notes_outlined,
                  validator: (_) => null,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  text: 'Send quote',
                  isLoading: vm.isCreatingQuote,
                  onPressed: vm.isCreatingQuote ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickCurrency() async {
    const options = ['RWF', 'USD', 'EUR', 'KES'];
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Currency'),
        children: [
          for (final option in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option),
              child: Text(option),
            ),
        ],
      ),
    );
    if (picked != null && mounted) {
      setState(() => _currency = picked);
    }
  }
}
