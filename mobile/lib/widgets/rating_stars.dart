import 'package:flutter/material.dart';

import 'package:mobile/theme/colors.dart';

/// Read-only star rating, e.g. a provider's average rating.
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final int? reviewCount;
  final bool showValue;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.reviewCount,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(_iconForStar(i), size: size, color: AppColors.warningAmber),
        if (showValue) ...[
          const SizedBox(width: 6),
          Text(
            rating == 0 ? 'New' : rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size - 2,
              fontWeight: FontWeight.w600,
              color: rating == 0 ? AppColors.secondaryText : AppColors.mainText,
            ),
          ),
        ],
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size - 2,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ],
    );
  }

  IconData _iconForStar(int position) {
    if (rating >= position) return Icons.star;
    if (rating >= position - 0.5) return Icons.star_half;
    return Icons.star_border;
  }
}

/// Tappable 1-5 star picker used by the review screen.
class RatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const RatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            label: '$i star${i == 1 ? '' : 's'}',
            selected: value == i,
            child: InkWell(
              onTap: () => onChanged(i),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  value >= i ? Icons.star : Icons.star_border,
                  size: size,
                  color: value >= i
                      ? AppColors.warningAmber
                      : AppColors.borderGrey,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
