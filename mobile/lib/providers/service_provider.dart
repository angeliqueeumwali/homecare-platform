import 'package:flutter/material.dart';

import 'package:mobile/models/service_request_model.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/service_category_service.dart';
import 'package:mobile/services/service_request_service.dart';

class ServiceCategoryViewModel with ChangeNotifier {
  final ServiceCategoryService _categoryService;
  List<ServiceCategoryModel> _categories = [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  String _query = '';
  String? _errorMessage;

  List<ServiceCategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;
  String get query => _query;
  String? get errorMessage => _errorMessage;

  /// Only services the customer can actually book.
  List<ServiceCategoryModel> get activeCategories =>
      _categories.where((c) => c.isActive).toList();

  /// Search runs on the client because the backend lists every category with
  /// no filtering parameters.
  List<ServiceCategoryModel> get filteredCategories {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return activeCategories;
    return activeCategories
        .where(
          (c) =>
              c.name.toLowerCase().contains(needle) ||
              (c.description ?? '').toLowerCase().contains(needle),
        )
        .toList();
  }

  ServiceCategoryViewModel(this._categoryService);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _categories = await _categoryService.getAllCategories();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _hasLoadedOnce = true;
      _setLoading(false);
    }
  }
}

class ServiceRequestViewModel with ChangeNotifier {
  final ServiceRequestService _requestService;
  List<ServiceRequestModel> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoadedOnce = false;
  String _query = '';
  String _statusFilter = allRequestsFilter;

  /// Sentinel for "no status filter", kept out of the backend status values.
  static const String allRequestsFilter = 'ALL';

  List<ServiceRequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// False until the first fetch resolves, so screens can tell "loading" from
  /// "genuinely empty".
  bool get hasLoadedOnce => _hasLoadedOnce;
  String get query => _query;
  String get statusFilter => _statusFilter;

  ServiceRequestViewModel(this._requestService);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Requests matching the current search text and status filter. Filtering
  /// happens here because the backend returns every request with no query
  /// parameters.
  List<ServiceRequestModel> get filteredRequests {
    final needle = _query.trim().toLowerCase();
    return _requests.where((request) {
      if (_statusFilter != allRequestsFilter &&
          request.status.toUpperCase() != _statusFilter) {
        return false;
      }
      if (needle.isEmpty) return true;
      if (request.address.toLowerCase().contains(needle)) return true;
      if ((request.notes ?? '').toLowerCase().contains(needle)) return true;
      return request.id.toLowerCase().contains(needle);
    }).toList();
  }

  /// Requests that are not finished, used on the home dashboard.
  List<ServiceRequestModel> get activeRequests {
    const finished = {'COMPLETED', 'CANCELLED'};
    return _requests
        .where((r) => !finished.contains(r.status.toUpperCase()))
        .toList();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setStatusFilter(String value) {
    _statusFilter = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchMyRequests() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _requests = await _requestService.getMyRequests();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _hasLoadedOnce = true;
      _setLoading(false);
    }
  }

  Future<ServiceRequestModel?> createRequest({
    required String address,
    required double latitude,
    required double longitude,
    DateTime? preferredDate,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    _setLoading(true);
    try {
      final request = await _requestService.createRequest(
        address: address,
        latitude: latitude,
        longitude: longitude,
        preferredDate: preferredDate,
        notes: notes,
        items: items,
      );
      _requests.insert(0, request);
      notifyListeners();
      return request;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<ServiceRequestModel?> getRequestById(String id) async {
    try {
      return await _requestService.getRequestById(id);
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    }
  }
}
