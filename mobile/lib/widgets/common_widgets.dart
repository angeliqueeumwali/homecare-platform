import 'package:flutter/material.dart';

import 'package:mobile/constants/status_constants.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';

/// Rounded search input used on the dashboards. Filtering happens in the
/// ViewModel, this widget only reports what the user typed.
class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onFilterTap;
  final int? activeFilterCount;

  const AppSearchBar({
    super.key,
    this.hintText = 'Search services',
    this.onChanged,
    this.controller,
    this.onFilterTap,
    this.activeFilterCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14, color: AppColors.mainText),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.secondaryText,
                size: 20,
              ),
              isDense: true,
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                borderSide: const BorderSide(color: AppColors.borderGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                borderSide: const BorderSide(color: AppColors.borderGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.medium),
                borderSide: const BorderSide(
                  color: AppColors.darkNavyBlue,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: AppSpacing.sm),
          _FilterButton(onTap: onFilterTap!, count: activeFilterCount ?? 0),
        ],
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  final int count;

  const _FilterButton({required this.onTap, required this.count});

  @override
  Widget build(BuildContext context) {
    final hasFilters = count > 0;
    return Semantics(
      button: true,
      label: hasFilters ? 'Filters, $count active' : 'Filters',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        child: Ink(
          height: AppConstants.minTouchTarget,
          width: AppConstants.minTouchTarget,
          decoration: BoxDecoration(
            color: hasFilters ? AppColors.darkNavyBlue : AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            border: Border.all(
              color: hasFilters ? AppColors.darkNavyBlue : AppColors.borderGrey,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune,
                size: 20,
                color: hasFilters ? AppColors.white : AppColors.darkNavyBlue,
              ),
              if (hasFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.errorRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal row of selectable chips, used for status filters.
class FilterChipRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final double height;

  const FilterChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selected;
          return ChoiceChip(
            label: Text(
              getStatusDisplayName(option),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.white : AppColors.mainText,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            showCheckmark: false,
            backgroundColor: AppColors.white,
            selectedColor: AppColors.darkNavyBlue,
            side: BorderSide(
              color: isSelected ? AppColors.darkNavyBlue : AppColors.borderGrey,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}

/// Centred spinner with an optional caption, used instead of bare
/// CircularProgressIndicator so loading states look consistent.
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  final bool inline;

  const AppLoadingIndicator({super.key, this.message, this.inline = false});

  @override
  Widget build(BuildContext context) {
    final spinner = SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: AppColors.darkNavyBlue,
      ),
    );

    if (inline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          spinner,
          if (message != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              message!,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
              ),
            ),
          ],
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            spinner,
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Title + optional "see all" action, used above every list section.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavyBlue,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(64, AppConstants.minTouchTarget),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  color: AppColors.darkNavyBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Read-only label/value row for detail screens.
class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final IconData? icon;
  final Widget? trailing;

  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.secondaryText),
            const SizedBox(width: AppSpacing.sm),
          ],
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child:
                trailing ??
                Text(
                  (value == null || value!.isEmpty) ? 'Not provided' : value!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mainText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Small count badge, e.g. unread notifications.
class AppCountBadge extends StatelessWidget {
  final int count;
  final Color? color;

  const AppCountBadge({super.key, required this.count, this.color});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final badgeColor = color ?? AppColors.errorRed;
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Thin divider that matches the border grey.
class AppDivider extends StatelessWidget {
  final double height;

  const AppDivider({super.key, this.height = 1});

  @override
  Widget build(BuildContext context) {
    return Container(height: height, color: AppColors.borderGrey);
  }
}
