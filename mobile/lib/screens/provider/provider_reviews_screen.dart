import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/notification_model.dart';
import 'package:mobile/providers/review_viewmodel.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/widgets/rating_stars.dart';

class ProviderReviewsScreen extends StatefulWidget {
  const ProviderReviewsScreen({super.key});

  @override
  State<ProviderReviewsScreen> createState() => _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState extends State<ProviderReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ReviewViewModel>().fetchMyProviderReviews(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReviewViewModel>();
    final reviews = vm.myProviderReviews;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoadingMyReviews ? null : vm.fetchMyProviderReviews,
          ),
        ],
      ),
      body: _buildBody(vm, reviews),
    );
  }

  Widget _buildBody(ReviewViewModel vm, List<ReviewModel> reviews) {
    if (vm.isLoadingMyReviews && reviews.isEmpty) {
      return const AppLoadingIndicator(message: 'Loading your reviews');
    }

    if (vm.errorMessage != null && reviews.isEmpty) {
      return ErrorView(
        message: vm.errorMessage!,
        onRetry: vm.fetchMyProviderReviews,
      );
    }

    if (reviews.isEmpty) {
      return const EmptyState(
        icon: Icons.reviews_outlined,
        message:
            'No reviews yet.\n'
            'Customers can review completed work, and their ratings will '
            'appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: vm.fetchMyProviderReviews,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: reviews.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _ReviewCard(review: reviews[index]),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingStars(rating: review.rating.toDouble(), size: 16),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${review.rating}/5',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainText,
                ),
              ),
              const Spacer(),
              if (review.createdAt != null)
                Text(
                  _formatDate(review.createdAt!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                  ),
                ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              review.comment!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mainText,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)}';
  }
}
