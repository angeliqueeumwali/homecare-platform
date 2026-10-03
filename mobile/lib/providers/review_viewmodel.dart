import 'package:flutter/material.dart';

import 'package:mobile/models/notification_model.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/review_service.dart';

/// Customer-side review state.
///
/// The backend can create a review (`POST /reviews`) and list a provider's
/// reviews (`GET /reviews/provider/{id}`), but it has no endpoint for "reviews
/// this customer wrote". That is deliberately not faked here.
class ReviewViewModel with ChangeNotifier {
  final ReviewService _reviewService;

  bool _isSubmitting = false;
  bool _isLoadingMyReviews = false;
  List<ReviewModel> _myProviderReviews = [];
  String? _errorMessage;
  String? _lastSubmittedAssignmentId;
  bool _isDisposed = false;

  ReviewViewModel(this._reviewService);

  bool get isSubmitting => _isSubmitting;
  bool get isLoadingMyReviews => _isLoadingMyReviews;
  String? get errorMessage => _errorMessage;

  List<ReviewModel> get myProviderReviews => _myProviderReviews;

  /// Assignment ids already reviewed in this session, so the UI does not offer
  /// to review the same assignment twice.
  bool hasSubmitted(String assignmentId) =>
      _lastSubmittedAssignmentId == assignmentId;

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }

  /// Returns the created review, or null when the backend rejected it.
  Future<ReviewModel?> submitReview({
    required String assignmentId,
    required int rating,
    String? comment,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final review = await _reviewService.createReview(
        assignmentId: assignmentId,
        rating: rating,
        comment: (comment == null || comment.trim().isEmpty)
            ? null
            : comment.trim(),
      );
      _lastSubmittedAssignmentId = assignmentId;
      return review;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } finally {
      _isSubmitting = false;
      _safeNotify();
    }
  }

  Future<List<ReviewModel>> reviewsForProvider(String providerId) async {
    try {
      return await _reviewService.getProviderReviews(providerId);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _safeNotify();
      return const [];
    }
  }

  /// Reviews left by customers about the signed-in provider, from
  /// `GET /reviews/me/provider`. The backend has no endpoint for this on the
  /// customer side, which is why [reviewsForProvider] takes an explicit id.
  Future<void> fetchMyProviderReviews() async {
    _isLoadingMyReviews = true;
    _errorMessage = null;
    _safeNotify();
    try {
      _myProviderReviews = await _reviewService.getMyProviderReviews();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _myProviderReviews = const [];
    } finally {
      _isLoadingMyReviews = false;
      _safeNotify();
    }
  }

  void clearMyProviderReviews() {
    _myProviderReviews = const [];
    _errorMessage = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
