/// Central HTTP client for the Glide China backend API.
library;

import 'package:dio/dio.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Configure a local or deployed backend at build time with
  /// `--dart-define=GLIDE_API_BASE_URL=https://example.invalid`.
  static String baseUrl = const String.fromEnvironment(
    'GLIDE_API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  Dio? _dio;

  Dio get _client {
    _dio ??= Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    return _dio!;
  }

  /// Change the base URL (e.g. for cross-device demo on LAN).
  /// Resets the Dio instance so the new URL takes effect.
  void setBaseUrl(String url) {
    baseUrl = url;
    _dio = null; // force re-creation with new URL
  }

  String? _token;

  void setToken(String token) { _token = token; }
  void clearToken() { _token = null; }

  Future<Response> get(String path, {Map<String, dynamic>? params}) {
    return _client.get(path, queryParameters: params, options: _authOptions());
  }

  Future<Response> post(String path, {dynamic data}) {
    return _client.post(path, data: data, options: _authOptions());
  }

  Future<Response> put(String path, {dynamic data}) {
    return _client.put(path, data: data, options: _authOptions());
  }

  Future<Response> delete(String path) {
    return _client.delete(path, options: _authOptions());
  }

  Options _authOptions() {
    if (_token != null) {
      return Options(headers: {'Authorization': 'Bearer $_token'});
    }
    return Options();
  }
}
