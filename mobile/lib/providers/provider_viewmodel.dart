import 'package:flutter/material.dart';

import 'package:mobile/models/assignment_model.dart';
import 'package:mobile/models/quote_model.dart';
import 'package:mobile/models/provider_model.dart';
import 'package:mobile/models/payment_model.dart';
import 'package:mobile/models/notification_model.dart';
import 'package:mobile/services/assignment_service.dart';
import 'package:mobile/services/quote_service.dart';
import 'package:mobile/services/provider_service.dart';
import 'package:mobile/services/payment_service.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/constants/status_constants.dart';

/// Where the signed-in user stands in the provider application flow.
///
/// [blockedByBackend] means the app asked the backend for a provider profile
/// and was refused, which happens today because registration always creates a
/// CUSTOMER while every /providers endpoint requires the SERVICE_PROVIDER role.
enum ProviderAccountState {
  none,
  pending,
  approved,
  rejected,
  blockedByBackend,
}

class ProviderViewModel with ChangeNotifier {
  final ProviderService _providerService;
  final AssignmentService _assignmentService;
  final QuoteService _quoteService;

  ProviderProfileModel? _profile;
  List<AssignmentModel> _assignments = [];
  List<QuoteModel> _quotes = [];
  List<ProviderServiceModel> _services = [];
  bool _isLoading = false;
  bool _isCheckingAccount = false;
  ProviderAccountState _accountState = ProviderAccountState.none;
  String? _errorMessage;
  String? _assignmentErrorMessage;
  bool _isUpdatingAssignment = false;
  bool _isLoadingAssignment = false;
  bool _isLoadingQuotes = false;
  bool _isCreatingQuote = false;
  AssignmentModel? _selectedAssignment;
  String? _assignmentQuery;
  String? _assignmentStatusFilter;
  bool _hasLoadedOnce = false;
  bool _hasLoadedAssignments = false;
  bool _isDisposed = false;

  ProviderViewModel(
    this._providerService,
    this._assignmentService,
    this._quoteService,
  );

  ProviderProfileModel? get profile => _profile;
  List<AssignmentModel> get assignments => _assignments;
  List<QuoteModel> get quotes => _quotes;
  List<ProviderServiceModel> get services => _services;
  bool get isLoading => _isLoading;
  bool get isCheckingAccount => _isCheckingAccount;
  ProviderAccountState get accountState => _accountState;
  String? get errorMessage => _errorMessage;

  /// Only an approved provider may see provider-only screens.
  bool get isApprovedProvider => _accountState == ProviderAccountState.approved;

  /// Provider tabs are shown for an approved provider, and for a user with a
  /// pending or rejected application so they can track it.
  bool get shouldShowProviderUi =>
      _accountState == ProviderAccountState.approved ||
      _accountState == ProviderAccountState.pending ||
      _accountState == ProviderAccountState.rejected;

  // --- Assignment list state -------------------------------------------------

  bool get isLoadingAssignments => _isLoading;
  bool get isUpdatingAssignment => _isUpdatingAssignment;
  String? get assignmentErrorMessage => _assignmentErrorMessage;
  String? get assignmentQuery => _assignmentQuery;

  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get hasLoadedAssignments => _hasLoadedAssignments;

  /// `null` means no status filter is applied.
  String? get assignmentStatusFilter => _assignmentStatusFilter;

  /// Assignments left open, which is what a provider works on today.
  List<AssignmentModel> get openAssignments =>
      _assignments.where((a) => isAssignmentOpen(a.status)).toList();

  List<AssignmentModel> get pendingAssignments => _assignments
      .where((a) => a.status.toUpperCase() == AssignmentStatus.pending)
      .toList();

  List<AssignmentModel> get filteredAssignments {
    final query = _assignmentQuery?.trim().toLowerCase() ?? '';
    return _assignments.where((assignment) {
      if (_assignmentStatusFilter != null &&
          assignment.status.toUpperCase() !=
              _assignmentStatusFilter!.toUpperCase()) {
        return false;
      }
      if (query.isEmpty) return true;
      return assignment.id.toLowerCase().contains(query) ||
          assignment.serviceRequestId.toLowerCase().contains(query) ||
          assignment.serviceRequestItemId.toLowerCase().contains(query) ||
          assignment.status.toLowerCase().contains(query);
    }).toList();
  }

  void setAssignmentQuery(String? query) {
    _assignmentQuery = query;
    _safeNotify();
  }

  void setAssignmentStatusFilter(String? status) {
    _assignmentStatusFilter = status;
    _safeNotify();
  }

  void clearAssignmentError() {
    _assignmentErrorMessage = null;
    _safeNotify();
  }

  // --- Assignment detail state -----------------------------------------------

  AssignmentModel? get selectedAssignment => _selectedAssignment;
  bool get isLoadingAssignment => _isLoadingAssignment;
  bool get isLoadingQuotes => _isLoadingQuotes;
  bool get isCreatingQuote => _isCreatingQuote;

  String? get quotesRequestId => _selectedAssignment?.serviceRequestId;

  List<QuoteModel> get myQuotes {
    final providerId = _selectedAssignment?.providerId ?? _profile?.id;
    if (providerId == null) return const [];
    return _quotes.where((q) => q.providerId == providerId).toList();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _safeNotify();
  }

  Future<void> init() async {
    await refreshAccountState();
    if (_accountState == ProviderAccountState.approved) {
      await fetchProfile();
      await fetchAssignments();
    }
    _hasLoadedOnce = true;
  }

  Future<void> loadDashboard() async {
    await refreshAccountState();
    if (_accountState != ProviderAccountState.approved) {
      _hasLoadedOnce = true;
      return;
    }
    await Future.wait([fetchProfile(), fetchAssignments()]);
    _hasLoadedOnce = true;
  }

  /// Works out whether this user is an approved provider, has an application in
  /// flight, or has never applied. Never throws: a 403 or 404 is an expected
  /// answer, not an error, because a plain customer has no provider profile.
  Future<void> refreshAccountState() async {
    _isCheckingAccount = true;
    _safeNotify();
    try {
      final profile = await _providerService.getMyProfile();
      _profile = profile;
      _accountState = _stateFromApprovalStatus(profile.approvalStatus);
    } on ApiException catch (e) {
      _profile = null;
      // 403 means the backend refused because the account is still a CUSTOMER;
      // 404 means there is simply no profile yet.
      _accountState = e.statusCode == 403
          ? ProviderAccountState.blockedByBackend
          : ProviderAccountState.none;
    } finally {
      _isCheckingAccount = false;
      _safeNotify();
    }
  }

  static ProviderAccountState _stateFromApprovalStatus(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case ProviderApprovalStatus.approved:
        return ProviderAccountState.approved;
      case ProviderApprovalStatus.rejected:
        return ProviderAccountState.rejected;
      case ProviderApprovalStatus.pending:
      default:
        return ProviderAccountState.pending;
    }
  }

  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }

  Future<void> fetchProfile() async {
    _errorMessage = null;
    try {
      _profile = await _providerService.getMyProfile();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    }
    _safeNotify();
  }

  Future<bool> createProfile({String? businessName, String? bio}) async {
    _setLoading(true);
    try {
      _profile = await _providerService.createProfile(
        businessName: businessName,
        bio: bio,
      );
      _accountState = _stateFromApprovalStatus(_profile?.approvalStatus);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? businessName,
    String? bio,
    bool? isAvailable,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _profile = await _providerService.updateProfile(
        businessName: businessName,
        bio: bio,
        isAvailable: isAvailable,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAssignments() async {
    _isLoading = true;
    _assignmentErrorMessage = null;
    _safeNotify();
    try {
      _assignments = await _assignmentService.getMyAssignments();
    } on ApiException catch (e) {
      _assignmentErrorMessage = e.message;
    } finally {
      _isLoading = false;
      _hasLoadedAssignments = true;
      _safeNotify();
    }
  }

  Future<bool> loadAssignment(String id) async {
    _isLoadingAssignment = true;
    _assignmentErrorMessage = null;
    _selectedAssignment = null;
    _quotes = [];
    _safeNotify();
    try {
      final assignment = await _assignmentService.getAssignmentById(id);
      if (assignment == null) {
        _assignmentErrorMessage = 'Assignment not found';
        return false;
      }
      _selectedAssignment = assignment;
      await _loadQuotes(assignment.serviceRequestId);
      return true;
    } on ApiException catch (e) {
      _assignmentErrorMessage = e.message;
      return false;
    } finally {
      _isLoadingAssignment = false;
      _safeNotify();
    }
  }

  Future<void> _loadQuotes(String requestId) async {
    _isLoadingQuotes = true;
    _safeNotify();
    try {
      _quotes = await _quoteService.getRequestQuotes(requestId);
    } on ApiException catch (e) {
      _assignmentErrorMessage = e.message;
      _quotes = [];
    } finally {
      _isLoadingQuotes = false;
      _safeNotify();
    }
  }

  Future<String?> changeAssignmentStatus(String id, String status) async {
    _isUpdatingAssignment = true;
    _assignmentErrorMessage = null;
    _safeNotify();
    try {
      final updated = await _assignmentService.updateStatus(id, status);
      _selectedAssignment = updated;
      // Keep the cached list in step so the dashboard and list do not show a
      // stale status after the change.
      final index = _assignments.indexWhere((a) => a.id == updated.id);
      if (index != -1) _assignments[index] = updated;
      _safeNotify();
      return null;
    } on ApiException catch (e) {
      _assignmentErrorMessage = e.message;
      return e.message;
    } finally {
      _isUpdatingAssignment = false;
      _safeNotify();
    }
  }

  Future<void> updateAssignmentStatus(String id, String status) async {
    await changeAssignmentStatus(id, status);
  }

  Future<void> refreshSelectedAssignment() async {
    final id = _selectedAssignment?.id;
    if (id == null) return;
    _isLoadingAssignment = true;
    _safeNotify();
    try {
      _selectedAssignment = await _assignmentService.getAssignmentById(id);
    } on ApiException catch (e) {
      _assignmentErrorMessage = e.message;
    } finally {
      _isLoadingAssignment = false;
      _safeNotify();
    }
  }

  Future<String?> createQuoteForSelectedAssignment({
    required String amount,
    String currency = 'RWF',
    String? description,
  }) async {
    final assignment = _selectedAssignment;
    if (assignment == null) {
      return 'No assignment is open.';
    }

    _isCreatingQuote = true;
    _assignmentErrorMessage = null;
    _safeNotify();
    try {
      final quote = await _quoteService.createQuote(
        serviceRequestId: assignment.serviceRequestId,
        serviceRequestItemId: assignment.serviceRequestItemId,
        amount: amount,
        currency: currency,
        description: (description == null || description.trim().isEmpty)
            ? null
            : description.trim(),
      );
      _quotes = [quote, ..._quotes];
      _safeNotify();
      return null;
    } on ApiException catch (e) {
      _assignmentErrorMessage = e.message;
      return e.message;
    } finally {
      _isCreatingQuote = false;
      _safeNotify();
    }
  }

  Future<void> fetchQuotes() async {
    _setLoading(true);
    try {
      final profile = await _providerService.getMyProfile();
      _profile = profile;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    }
    _setLoading(false);
  }

  Future<ProviderLocationModel?> saveLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final location = await _providerService.setLocation(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      _safeNotify();
      return location;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<AssignmentModel?> getAssignmentById(String id) async {
    try {
      return await _assignmentService.getAssignmentById(id);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _safeNotify();
      return null;
    }
  }

  Future<void> fetchServices() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _services = await _providerService.getServices();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    }
    _setLoading(false);
  }

  Future<bool> addService(String serviceCategoryId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final created = await _providerService.addService(serviceCategoryId);
      if (!_services.any((s) => s.serviceCategoryId == serviceCategoryId)) {
        _services.add(created);
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeService(String serviceCategoryId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _providerService.removeService(serviceCategoryId);
      _services.removeWhere((s) => s.serviceCategoryId == serviceCategoryId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class PaymentViewModel with ChangeNotifier {
  final PaymentService _paymentService;
  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PaymentViewModel(this._paymentService);

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _safeNotify();
  }

  Future<void> fetchMyPayments() async {
    _setLoading(true);
    try {
      _payments = await _paymentService.getMyPayments();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    }
    _setLoading(false);
  }

  Future<PaymentModel?> createPayment({
    required String serviceRequestId,
    required String quoteId,
    required String amount,
    required String paymentMethod,
    String currency = 'RWF',
  }) async {
    _setLoading(true);
    try {
      final payment = await _paymentService.createPayment(
        PaymentCreateRequest(
          serviceRequestId: serviceRequestId,
          quoteId: quoteId,
          amount: amount,
          currency: currency,
          paymentMethod: paymentMethod,
        ),
      );
      _payments.insert(0, payment);
      _safeNotify();
      return payment;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class NotificationViewModel with ChangeNotifier {
  final NotificationService _notificationService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  NotificationViewModel(this._notificationService);

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _safeNotify();
    try {
      _notifications = await _notificationService.getNotifications();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<NotificationModel?> markAsRead(String id) async {
    try {
      final notification = await _notificationService.markAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = notification;
      }
      _safeNotify();
      return notification;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    }
  }

  void markAllRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    _safeNotify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class QuoteViewModel with ChangeNotifier {
  final QuoteService _quoteService;
  List<QuoteModel> _quotes = [];
  String? _activeRequestId;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  List<QuoteModel> get quotes => _quotes;

  /// Which request the current [quotes] belong to. Screens use this so they
  /// never show one request's quotes on another request's screen.
  String? get activeRequestId => _activeRequestId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  QuoteViewModel(this._quoteService);

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  Future<void> fetchRequestQuotes(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    // Clear immediately: keeping the previous request's quotes here would show
    // them against the new request while loading, and leave them on screen if
    // this fetch fails.
    _quotes = [];
    _activeRequestId = requestId;
    _safeNotify();
    try {
      _quotes = await _quoteService.getRequestQuotes(requestId);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void clearRequestQuotes() {
    _quotes = [];
    _activeRequestId = null;
    _errorMessage = null;
    _safeNotify();
  }

  Future<bool> acceptQuote(String quoteId) async {
    try {
      await _quoteService.updateStatus(quoteId, 'APPROVED');
      final index = _quotes.indexWhere((q) => q.id == quoteId);
      if (index != -1) {
        _quotes[index] = QuoteModel(
          id: _quotes[index].id,
          serviceRequestId: _quotes[index].serviceRequestId,
          serviceRequestItemId: _quotes[index].serviceRequestItemId,
          providerId: _quotes[index].providerId,
          amount: _quotes[index].amount,
          currency: _quotes[index].currency,
          status: 'APPROVED',
          description: _quotes[index].description,
          createdAt: _quotes[index].createdAt,
          updatedAt: _quotes[index].updatedAt,
        );
      }
      _safeNotify();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    }
  }

  Future<bool> rejectQuote(String quoteId) async {
    try {
      await _quoteService.updateStatus(quoteId, 'REJECTED');
      final index = _quotes.indexWhere((q) => q.id == quoteId);
      if (index != -1) {
        _quotes[index] = QuoteModel(
          id: _quotes[index].id,
          serviceRequestId: _quotes[index].serviceRequestId,
          serviceRequestItemId: _quotes[index].serviceRequestItemId,
          providerId: _quotes[index].providerId,
          amount: _quotes[index].amount,
          currency: _quotes[index].currency,
          status: 'REJECTED',
          description: _quotes[index].description,
          createdAt: _quotes[index].createdAt,
          updatedAt: _quotes[index].updatedAt,
        );
      }
      _safeNotify();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
