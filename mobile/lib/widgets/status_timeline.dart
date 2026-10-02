import 'package:flutter/material.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';

/// Vertical progress timeline for a service request or assignment.
///
/// The backend only stores the *current* status, so this renders progress from
/// that single value against the documented happy path. A status that is not on
/// the happy path (CANCELLED, DECLINED) is shown as a single failure step
/// rather than pretending progress happened.
class StatusTimeline extends StatelessWidget {
  final String currentStatus;
  final List<String> steps;
  final String? completedLabel;

  const StatusTimeline({
    super.key,
    required this.currentStatus,
    required this.steps,
    this.completedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final status = currentStatus.toUpperCase();
    final failed = isTerminalFailureStatus(status);
    final currentIndex = timelineStepIndex(status, steps);

    if (failed || currentIndex < 0) {
      return _FailureStep(status: status);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(
            label: getStatusDisplayName(steps[i]),
            isDone: i < currentIndex,
            isCurrent: i == currentIndex,
            showConnector: i < steps.length - 1,
            isLast: i == steps.length - 1,
            completedLabel: i == steps.length - 1 ? completedLabel : null,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool showConnector;
  final bool isLast;
  final String? completedLabel;

  const _TimelineRow({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.showConnector,
    required this.isLast,
    this.completedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? AppColors.successGreen
        : isCurrent
        ? AppColors.darkNavyBlue
        : AppColors.borderGrey;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.successGreen
                      : isCurrent
                      ? AppColors.darkNavyBlue
                      : AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: isCurrent ? 2 : 1.5),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: AppColors.white)
                    : isCurrent
                    ? const Icon(Icons.circle, size: 8, color: AppColors.white)
                    : null,
              ),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone
                        ? AppColors.successGreen
                        : AppColors.borderGrey,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isDone || isCurrent
                          ? AppColors.mainText
                          : AppColors.secondaryText,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'Current status',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                  if (isLast && completedLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      completedLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureStep extends StatelessWidget {
  final String status;

  const _FailureStep({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDeclined =
        status == AssignmentStatus.declined || status == QuoteStatus.rejected;
    final color = AppColors.errorRed;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(
            isDeclined ? Icons.close : Icons.cancel_outlined,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getStatusDisplayName(status),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isDeclined
                    ? 'This did not go ahead.'
                    : 'This was stopped before completion.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
