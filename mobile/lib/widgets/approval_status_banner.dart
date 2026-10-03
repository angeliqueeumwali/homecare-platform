import 'package:flutter/material.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';

class ApprovalStatusBanner extends StatelessWidget {
  final ProviderAccountState state;
  final String? businessName;

  const ApprovalStatusBanner({
    super.key,
    required this.state,
    this.businessName,
  });

  bool get _blocksProviderFeatures =>
      state == ProviderAccountState.pending ||
      state == ProviderAccountState.rejected;

  @override
  Widget build(BuildContext context) {
    if (state == ProviderAccountState.approved ||
        state == ProviderAccountState.none) {
      return const SizedBox.shrink();
    }

    final isBlocked = state == ProviderAccountState.blockedByBackend;
    final isRejected = state == ProviderAccountState.rejected;

    final background = isBlocked || isRejected
        ? AppColors.errorRed.withValues(alpha: 0.08)
        : AppColors.warningAmber.withValues(alpha: 0.12);
    final accent = isBlocked || isRejected
        ? AppColors.errorRed
        : AppColors.warningAmber;
    final icon = isRejected
        ? Icons.cancel_outlined
        : isBlocked
        ? Icons.lock_outline
        : Icons.hourglass_empty;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      backgroundColor: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isBlocked
                      ? 'Provider account not active'
                      : isRejected
                      ? 'Application rejected'
                      : 'Approval pending',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              StatusBadge(
                status: isBlocked
                    ? 'INACTIVE'
                    : ProviderApprovalStatus.rejected,
                customColor: accent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _message(isBlocked, isRejected),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mainText,
              height: 1.4,
            ),
          ),
          if (_blocksProviderFeatures) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Jobs, quotes and availability unlock once an administrator '
              'approves the account.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _message(bool isBlocked, bool isRejected) {
    if (isBlocked) {
      return 'This account is still registered as a customer, so the '
          'provider endpoints refuse it. An administrator has to set the '
          'account role before provider tools can be used.';
    }
    if (isRejected) {
      return 'An administrator did not approve this provider'
          '${businessName == null || businessName!.isEmpty ? '' : ' ($businessName)'}'
          '. The status below is what the backend reports.';
    }
    return 'This provider is waiting for an administrator to approve it. '
        'Nothing else is needed from you right now.';
  }
}
