import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../config/constants.dart';

/// A custom exception class for handling API errors
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException: $statusCode - $message';
}

/// A simple logger class for debug output
class _Logger {
  void d(String message) => debugPrint('DEBUG: $message');
  void i(String message) => debugPrint('INFO: $message');
  void w(String message) => debugPrint('WARNING: $message');
  void e(String message) => debugPrint('ERROR: $message');
}

final _logger = _Logger();

/// A service class for making HTTP requests to the API
class ApiService {
  final String baseUrl;
  final Connectivity _connectivity = Connectivity();
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Creates a new ApiService instance with the given base URL
  ApiService({required this.baseUrl});

  /// Checks if the device has an active internet connection
  Future<bool> get isConnected async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      _logger.e('Connection error: $e');
      return false;
    }
  }

  /// Adds the authentication token to the request headers
  Future<void> _addAuthHeader() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.storageTokenKey);
      
      if (token != null && token.isNotEmpty) {
        _headers['Authorization'] = 'Bearer $token';
      } else {
        _headers.remove('Authorization');
      }
    } catch (e) {
      _logger.e('Error adding auth header: $e');
      _headers.remove('Authorization');
    }
  }

  /// Processes the HTTP response and returns the decoded JSON or throws an exception
  dynamic _processResponse(http.Response response) {
    _logger.d('Status: ${response.statusCode}');
    _logger.d('Headers: ${response.headers}');
    _logger.d('Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      
      try {
        return json.decode(response.body);
      } catch (e) {
        _logger.e('Error decoding response: $e');
        return response.body;
      }
    } else {
      _handleErrorResponse(response);
    }
  }

  /// Handles error responses from the API
  void _handleErrorResponse(http.Response response) {
    String message = 'An error occurred';
    
    try {
      if (response.body.isNotEmpty) {
        final errorData = json.decode(response.body);
        message = errorData['message'] ?? errorData['error'] ?? message;
      }
    } catch (e) {
      _logger.e('Error parsing error response: $e');
    }

    _logger.e('API Error ${response.statusCode}: $message');
    throw ApiException(
      statusCode: response.statusCode,
      message: message,
    );
  }

  /// Uploads a file to the specified endpoint
  Future<dynamic> uploadFile(
    String endpoint,
    File file, {
    String fileField = 'file',
    Map<String, String>? fields,
  }) async {
    if (!await isConnected) {
      throw const SocketException('No internet connection');
    }

    await _addAuthHeader();

    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      _logger.d('UPLOAD: $uri');

      var request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll({
        'Authorization': _headers['Authorization'] ?? '',
        'Accept': 'application/json',
      });

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        fileField,
        file.path,
      ));

      // Add additional fields if any
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _processResponse(response);
    } catch (e) {
      _logger.e('File upload error: $e');
      rethrow;
    }
  }

  /// Sends an HTTP request with the specified method, endpoint, and body
  Future<dynamic> _sendRequest(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
  }) async {
    if (!await isConnected) {
      throw const SocketException('No internet connection');
    }

    await _addAuthHeader();

    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams?.map((key, value) => 
          MapEntry(key, value.toString())
        ),
      );
      
      _logger.d('$method: $uri');
      if (body != null) {
        _logger.d('Request body: $body');
      }

      final bodyJson = body != null ? json.encode(body) : null;
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(
            uri,
            headers: _headers,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Request timed out'),
          );
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: _headers,
            body: bodyJson,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Request timed out'),
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: _headers,
            body: bodyJson,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Request timed out'),
          );
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: _headers,
            body: bodyJson,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Request timed out'),
          );
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: _headers,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Request timed out'),
          );
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      return _processResponse(response);
    } on SocketException {
      rethrow;
    } on FormatException catch (e) {
      _logger.e('Format error: $e');
      throw const SocketException('Invalid server response format');
    } on TimeoutException {
      _logger.e('Request timed out');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error: $e');
      rethrow;
    }
  }

  /// Sends a GET request to the specified endpoint
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    return _sendRequest('GET', endpoint, queryParams: queryParams);
  }

  /// Sends a POST request to the specified endpoint with the given body
  Future<dynamic> post(String endpoint, {dynamic body}) async {
    return _sendRequest('POST', endpoint, body: body);
  }

  /// Sends a PUT request to the specified endpoint with the given body
  Future<dynamic> put(String endpoint, {dynamic body}) async {
    return _sendRequest('PUT', endpoint, body: body);
  }

  /// Sends a PATCH request to the specified endpoint with the given body
  Future<dynamic> patch(String endpoint, {dynamic body}) async {
    return _sendRequest('PATCH', endpoint, body: body);
  }

  /// Sends a DELETE request to the specified endpoint
  Future<dynamic> delete(String endpoint) async {
    return _sendRequest('DELETE', endpoint);
  }
}
