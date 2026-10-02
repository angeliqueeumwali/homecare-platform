import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/notification_model.dart';
import 'package:mobile/providers/review_viewmodel.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/common_widgets.dart';
import 'package:mobile/widgets/rating_stars.dart';

/// Leaves a rating for a completed assignment, using `POST /reviews`.
///
/// The backend requires an `assignment_id`, so this screen is opened from a
/// completed assignment. The customer cannot list reviews they have written
/// because no such endpoint exists.
class SubmitReviewScreen extends StatefulWidget {
  final String assignmentId;

  /// Optional context, e.g. the service name, shown to the customer.
  final String? serviceLabel;

  const SubmitReviewScreen({
    super.key,
    required this.assignmentId,
    this.serviceLabel,
  });

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a star rating')),
      );
      return;
    }

    final vm = context.read<ReviewViewModel>();
    final review = await vm.submitReview(
      assignmentId: widget.assignmentId,
      rating: _rating,
      comment: _commentController.text,
    );

    if (!mounted) return;

    if (review == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Could not save your review'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: const Text('Thank you'),
        content: const Text(
          'Your review has been sent. Thanks for helping other customers '
          'choose with confidence.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, review);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReviewViewModel>();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Rate the service'),
        backgroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (widget.serviceLabel != null) ...[
              AppCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.work_outline,
                      color: AppColors.darkNavyBlue,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        widget.serviceLabel!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppCard(
              child: Column(
                children: [
                  const Text(
                    'How would you rate this service?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RatingInput(
                    value: _rating,
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_rating > 0)
                    RatingStars(rating: _rating.toDouble(), showValue: false)
                  else
                    const Text(
                      'Tap a star to rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Your review (optional)',
              hintText: 'Tell others about your experience',
              controller: _commentController,
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'Submit review',
              isLoading: vm.isSubmitting,
              onPressed: vm.isSubmitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

/// Read-only reviews for a provider, from
/// `GET /reviews/provider/{providerId}`.
class ProviderReviewsScreen extends StatefulWidget {
  final String providerId;
  final String? providerLabel;

  const ProviderReviewsScreen({
    super.key,
    required this.providerId,
    this.providerLabel,
  });

  @override
  State<ProviderReviewsScreen> createState() => _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState extends State<ProviderReviewsScreen> {
  List<ReviewModel>? _reviews;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final reviews = await context.read<ReviewViewModel>().reviewsForProvider(
      widget.providerId,
    );
    if (!mounted) return;
    setState(() {
      _reviews = reviews;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: AppColors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoadingIndicator(message: 'Loading reviews');
    }

    final reviews = _reviews ?? const <ReviewModel>[];

    if (reviews.isEmpty) {
      return const EmptyState(
        icon: Icons.reviews_outlined,
        message:
            'No reviews yet.\n'
            'Reviews from completed services will appear here.',
      );
    }

    final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
    final average = total / reviews.length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppCard(
          child: Row(
            children: [
              Text(
                average.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavyBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingStars(rating: average, showValue: false, size: 20),
                  const SizedBox(height: 2),
                  Text(
                    '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final review in reviews)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingStars(
                    rating: review.rating.toDouble(),
                    showValue: false,
                    size: 15,
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
            ),
          ),
      ],
    );
  }
}
