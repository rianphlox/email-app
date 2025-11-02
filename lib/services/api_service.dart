import 'package:dio/dio.dart';
import 'package:email_mobile_application/constants/strings.dart';
import 'package:email_mobile_application/models/email.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<ApiResponse<bool>> authenticate({
    required String email,
    required Map<String, dynamic> gmailPayload,
  }) async {
    try {
      final response = await _dio.post(
        '/authenticate',
        data: {
          'email': email,
          'gmail_payload': gmailPayload,
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Authentication failed');
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<List<Email>>> getEmails({
    required String email,
    required int reqType,
  }) async {
    try {
      final response = await _dio.post(
        '/get-emails',
        data: {
          'email': email,
          'req_type': reqType,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final emails = data.map((e) => Email.fromJson(e)).toList();
        return ApiResponse.success(emails);
      } else {
        return ApiResponse.error('Failed to fetch emails');
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<bool>> sendEmail({
    required String fromEmail,
    required String toEmail,
    required String subject,
    required String body,
  }) async {
    try {
      final response = await _dio.put(
        '/send-email',
        data: {
          'email': fromEmail,
          'to_email': toEmail,
          'subject': subject,
          'body': body,
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to send email');
      }
    } on DioException catch (e) {
      return ApiResponse.error(_handleDioError(e));
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server response timeout. Please try again.';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      default:
        return 'Network error occurred.';
    }
  }
}

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;

  ApiResponse.success(this.data)
      : isSuccess = true,
        error = null;

  ApiResponse.error(this.error)
      : isSuccess = false,
        data = null;
}