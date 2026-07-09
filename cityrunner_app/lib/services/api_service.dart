import 'package:dio/dio.dart';

import '../core/constants/app_constants.dart';

class ApiService {
  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.apiBaseUrl,
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 12),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;

  Future<Map<String, dynamic>> get(String path, {String? token}) async {
    final response = await _dio.get<dynamic>(path, options: _options(token));
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> post(String path, {Object? data, String? token}) async {
    final response = await _dio.post<dynamic>(path, data: data, options: _options(token));
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> delete(String path, {Object? data, String? token}) async {
    final response = await _dio.delete<dynamic>(path, data: data, options: _options(token));
    return _asMap(response.data);
  }

  Options _options(String? token) {
    return Options(headers: token == null ? null : {'Authorization': 'Bearer $token'});
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected API response format.');
  }
}
