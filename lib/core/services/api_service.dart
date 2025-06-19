import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiConfig.getUrl(endpoint)),
            headers: headers ?? ApiConfig.getHeaders(),
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } on TimeoutException {
      return ApiResponse.error(ApiConfig.timeoutError);
    } on SocketException {
      return ApiResponse.error(ApiConfig.networkError);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }


  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final data = json.decode(response.body);
        if (fromJson != null) {
          return ApiResponse.success(fromJson(data));
        }
        return ApiResponse.success(data as T);
      } catch (e) {
        return ApiResponse.error('Invalid response format');
      }
    } else {
      return ApiResponse.error(
        'Server error: ${response.statusCode} ${response.reasonPhrase}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
} 