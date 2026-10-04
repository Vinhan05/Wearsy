import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final token = await TokenStorage.getToken();
    final headers = <String, String>{};

    if (isJson) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<dynamic> get(String endpoint,
      {Map<String, dynamic>? queryParameters}) async {
    var url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final qp = Map<String, String>.from(url.queryParameters);
      queryParameters.forEach((k, v) {
        if (v != null) qp[k] = v.toString();
      });
      url = url.replace(queryParameters: qp);
    }
    try {
      final headers = await _getHeaders();
      final response = await _client.get(url, headers: headers);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 503,
        message:
            'Không thể kết nối đến máy chủ WEARSY. Vui lòng kiểm tra mạng.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          statusCode: 500, message: 'Đã xảy ra lỗi không xác định: $e');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 503,
        message:
            'Không thể kết nối đến máy chủ WEARSY. Vui lòng kiểm tra mạng.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
          statusCode: 500, message: 'Đã xảy ra lỗi không xác định: $e');
    }
  }

  Future<dynamic> postMultipart(
    String endpoint,
    File file, {
    String fieldName = 'image',
    Map<String, String>? fields,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final token = await TokenStorage.getToken();
      final request = http.MultipartRequest('POST', url);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (fields != null) {
        request.fields.addAll(fields);
      }
      request.files
          .add(await http.MultipartFile.fromPath(fieldName, file.path));
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 503,
        message:
            'Không thể kết nối đến máy chủ WEARSY. Vui lòng kiểm tra mạng.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 500, message: 'Đã xảy ra lỗi: $e');
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final headers = await _getHeaders();
      final response = await _client.put(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 503,
        message: 'Không thể kết nối đến máy chủ WEARSY.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 500, message: 'Đã xảy ra lỗi: $e');
    }
  }

  Future<dynamic> delete(String endpoint,
      {Map<String, dynamic>? queryParameters}) async {
    var url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final qp = Map<String, String>.from(url.queryParameters);
      queryParameters.forEach((k, v) {
        if (v != null) qp[k] = v.toString();
      });
      url = url.replace(queryParameters: qp);
    }
    try {
      final headers = await _getHeaders();
      final response = await _client.delete(url, headers: headers);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 503,
        message: 'Không thể kết nối đến máy chủ WEARSY.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 500, message: 'Đã xảy ra lỗi: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonResponseBody;
    try {
      jsonResponseBody = jsonDecode(response.body);
    } catch (_) {
      jsonResponseBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (jsonResponseBody != null &&
          jsonResponseBody is Map<String, dynamic>) {
        if (jsonResponseBody.containsKey('data')) {
          return jsonResponseBody['data'];
        }
        return jsonResponseBody;
      }
      return jsonResponseBody;
    }

    // Extract error message from standard WEARSY error response
    String errorMessage = 'Thao tác không thành công (${response.statusCode})';
    dynamic errorDetails;

    if (jsonResponseBody != null && jsonResponseBody is Map<String, dynamic>) {
      if (jsonResponseBody['error'] != null) {
        final err = jsonResponseBody['error'];
        if (err is Map<String, dynamic>) {
          errorMessage = err['message'] ?? errorMessage;
          errorDetails = err['details'];
        } else if (err is String) {
          errorMessage = err;
        }
      } else if (jsonResponseBody['message'] != null) {
        if (jsonResponseBody['message'] is List) {
          errorMessage = (jsonResponseBody['message'] as List).join(', ');
        } else {
          errorMessage = jsonResponseBody['message'].toString();
        }
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
      details: errorDetails,
    );
  }
}
