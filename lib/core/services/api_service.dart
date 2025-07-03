import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../../models/material.dart';

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

  Future<List<MaterialModel>> getMaterials({
    required int teacherId,
    required String className,
    required String batch,
  }) async {
    try {
      var headers = {'Content-Type': 'application/json'};
      var request = http.Request(
          'POST', Uri.parse('http://27.116.52.24:8076/material/getMaterials'));
      request.body = json.encode({
        'teacherId': teacherId,
        'class': className,
        'batch': batch,
      });
      request.headers.addAll(headers);
      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        if (data['data'] is List) {
          return (data['data'] as List)
              .map((item) => MaterialModel.fromJson(item))
              .toList();
        }
        return [];
      } else {
        throw Exception('Failed to load materials: ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<MaterialModel?> uploadMaterialFile({
    required int teacherId,
    required String className,
    required String batch,
    required File file,
    required String fileName,
  }) async {
    var uri = Uri.parse('http://27.116.52.24:8076/material/upload');
    var request = http.MultipartRequest('POST', uri);
    request.fields['teacherId'] = teacherId.toString();
    request.fields['class'] = className;
    request.fields['batch'] = batch;
    request.fields['fileName'] = fileName;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    var streamedResponse = await request.send();
    if (streamedResponse.statusCode == 200) {
      final respStr = await streamedResponse.stream.bytesToString();
      final data = json.decode(respStr);
      if (data['data'] != null) {
        return MaterialModel.fromJson(data['data']);
      }
    }
    return null;
  }

  Future<MaterialModel?> shareVideoLink({
    required int teacherId,
    required String className,
    required String batch,
    required String videoLink,
    required String fileName,
  }) async {
    var headers = {'Content-Type': 'application/json'};
    var request = http.Request('POST', Uri.parse('http://27.116.52.24:8076/material/shareVideo'));
    request.body = json.encode({
      'teacherId': teacherId,
      'class': className,
      'batch': batch,
      'videoLink': videoLink,
      'fileName': fileName,
    });
    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);
      if (data['data'] != null) {
        return MaterialModel.fromJson(data['data']);
      }
    }
    return null;
  }

  void dispose() {
    _client.close();
  }
}
