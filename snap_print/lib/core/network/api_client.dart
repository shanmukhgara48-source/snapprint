import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'api_endpoints.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  AppException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException()
    : super('No internet connection. Please check your network.');
}

class ServerException extends AppException {
  ServerException([super.message = 'Something went wrong. Please try again.']);
}

class UnauthorizedException extends AppException {
  UnauthorizedException()
    : super('Session expired. Please login again.', statusCode: 401);
}

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _ErrorInterceptor(),
      if (kDebugMode)
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          responseHeader: false,
          error: true,
          compact: true,
        ),
    ]);
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _dio.post<T>(
    path,
    data: data,
    queryParameters: queryParameters,
    options: options,
  );

  Future<Response<T>> put<T>(String path, {dynamic data, Options? options}) =>
      _dio.put<T>(path, data: data, options: options);

  Future<Response<T>> patch<T>(String path, {dynamic data, Options? options}) =>
      _dio.patch<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(String path, {Options? options}) =>
      _dio.delete<T>(path, options: options);
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Our own application access token (minted by POST /auth/verify after a
    // one-time Firebase ID token check) is the session — the raw Firebase
    // token is never sent to the backend again after that exchange.
    if (_devAuthToken != null) {
      options.headers['Authorization'] = 'Bearer $_devAuthToken';
    } else if (_appAuthToken != null) {
      options.headers['Authorization'] = 'Bearer $_appAuthToken';
    }
    // If neither is set, proceed without a token; server will return 401.
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: NetworkException(),
            type: err.type,
          ),
        );
        return;
      default:
        break;
    }

    final statusCode = err.response?.statusCode;
    if (statusCode == 401) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: UnauthorizedException(),
          type: err.type,
          response: err.response,
        ),
      );
      return;
    }

    final responseData = err.response?.data;
    String message = 'Something went wrong.';
    if (responseData is Map) {
      final detail = responseData['detail'];
      final msg = responseData['message'];
      // detail can itself be a List (FastAPI validation errors) — stringify it
      if (detail != null) {
        message = detail is String ? detail : detail.toString();
      } else if (msg is String) {
        message = msg;
      }
    }
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ServerException(message),
        type: err.type,
        response: err.response,
      ),
    );
  }
}

// Dev bypass token (null = not in dev mode)
String? _devAuthToken;

void setDevAuthToken(String? token) => _devAuthToken = token;

String? getDevAuthToken() => _devAuthToken;

// Application access token minted by POST /auth/verify (null = not signed in)
String? _appAuthToken;

void setAppAuthToken(String? token) => _appAuthToken = token;

String? getAppAuthToken() => _appAuthToken;

// Riverpod provider
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
