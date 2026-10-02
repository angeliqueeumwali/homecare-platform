import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:mobile/constants/app_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? body;

  ApiException({required this.statusCode, required this.message, this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiError implements Exception {
  final String message;

  ApiError({required this.message});

  @override
  String toString() => message;
}

typedef OnUnauthorized = void Function();

class ApiClient {
  final String _baseUrl;
  final Future<String?> Function()? _getToken;
  final OnUnauthorized? _onUnauthorized;

  ApiClient({
    String? baseUrl,
    Future<String?> Function()? getToken,
    OnUnauthorized? onUnauthorized,
  }) : _baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _getToken = getToken,
       _onUnauthorized = onUnauthorized;

  String _buildUrl(String path) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$_baseUrl/$cleanPath';
  }

  Future<Map<String, String>> _buildHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (includeAuth) {
      final token = await _getToken?.call();
      if (token != null) {
        headers['Authorization'] = '${ApiConfig.bearerPrefix}$token';
      }
    }
    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    final statusCode = response.statusCode;
    final body = response.body;

    if (body.isEmpty) {
      if (statusCode >= 200 && statusCode < 300) return null;
      throw ApiException(statusCode: statusCode, message: 'Empty response');
    }

    dynamic decoded;
    try {
      decoded = json.decode(body);
    } catch (e) {
      if (statusCode >= 200 && statusCode < 300) return body;
      throw ApiException(
        statusCode: statusCode,
        message: 'Invalid JSON response: $body',
      );
    }

    if (statusCode >= 200 && statusCode < 300) return decoded;

    String errorMessage = decoded is Map
        ? (decoded['detail'] ?? 'Unknown error').toString()
        : decoded.toString();

    if (statusCode == 401) {
      _onUnauthorized?.call();
    }

    throw ApiException(
      statusCode: statusCode,
      message: errorMessage,
      body: decoded is Map<String, dynamic> ? decoded : null,
    );
  }

  Future<T> _request<T>(Future<http.Response> Function() requestFn) async {
    try {
      final response = await requestFn().timeout(
        Duration(seconds: ApiConfig.connectTimeout),
        onTimeout: () =>
            throw ApiException(statusCode: 0, message: 'Request timed out'),
      );
      return await _handleResponse(response) as T;
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'No internet connection');
    } on http.ClientException {
      throw ApiException(statusCode: 0, message: 'Network error');
    } on TimeoutException {
      throw ApiException(statusCode: 0, message: 'Request timed out');
    }
  }

  Future<T> get<T>(
    String path, {
    Map<String, String>? queryParameters,
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse(
      _buildUrl(path),
    ).replace(queryParameters: queryParameters);
    final headers = await _buildHeaders(includeAuth: includeAuth);
    return _request<T>(() => http.get(uri, headers: headers));
  }

  Future<T> post<T>(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse(_buildUrl(path));
    final headers = await _buildHeaders(includeAuth: includeAuth);
    return _request<T>(
      () => http.post(uri, headers: headers, body: json.encode(body)),
    );
  }

  Future<T> patch<T>(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse(_buildUrl(path));
    final headers = await _buildHeaders(includeAuth: includeAuth);
    return _request<T>(
      () => http.patch(uri, headers: headers, body: json.encode(body)),
    );
  }

  Future<T> put<T>(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse(_buildUrl(path));
    final headers = await _buildHeaders(includeAuth: includeAuth);
    return _request<T>(
      () => http.put(uri, headers: headers, body: json.encode(body)),
    );
  }

  Future<T> delete<T>(String path, {bool includeAuth = true}) async {
    final uri = Uri.parse(_buildUrl(path));
    final headers = await _buildHeaders(includeAuth: includeAuth);
    return _request<T>(() => http.delete(uri, headers: headers));
  }

  /// Uploads a single file as multipart/form-data.
  ///
  /// Content-Type is intentionally not set here: the http package writes the
  /// multipart boundary itself, and forcing a JSON content type would make the
  /// backend reject the file.
  Future<T> upload<T>(
    String path, {
    required String filePath,
    String fieldName = 'file',
    String? filename,
    bool includeAuth = true,
  }) async {
    final uri = Uri.parse(_buildUrl(path));
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      if (includeAuth) {
        final token = await _getToken?.call();
        if (token != null) {
          request.headers['Authorization'] = '${ApiConfig.bearerPrefix}$token';
        }
      }
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          filePath,
          filename: filename,
        ),
      );

      final streamed = await request.send().timeout(
        Duration(seconds: ApiConfig.receiveTimeout),
        onTimeout: () =>
            throw ApiException(statusCode: 0, message: 'Upload timed out'),
      );
      final response = await http.Response.fromStream(streamed);
      return await _handleResponse(response) as T;
    } on SocketException {
      throw ApiException(statusCode: 0, message: 'No internet connection');
    } on http.ClientException {
      throw ApiException(statusCode: 0, message: 'Network error');
    } on TimeoutException {
      throw ApiException(statusCode: 0, message: 'Upload timed out');
    }
  }
}
