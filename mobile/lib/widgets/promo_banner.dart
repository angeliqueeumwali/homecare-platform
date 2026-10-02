import 'package:flutter/material.dart';

import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';

/// Full-width navy banner used for promotions and short announcements on the
/// dashboards. Flat navy only, no gradients, to match the design system.
class PromoBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const PromoBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkNavyBlue,
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondaryNavyBlue,
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              ),
              child: Icon(icon, color: AppColors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(64, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.darkNavyBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
