import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:saveforge/core/logging/app_logger.dart';

class ApiClient {
  late final Dio _dio;
  String baseUrl;
  
  final networkLogger = CategoryLogger(LoggerCategory.network);

  ApiClient({ this.baseUrl='https://api.example.com'}) {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl, // Replace with your API base URL
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Request interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          networkLogger.debug('REQUEST: ${options.method} ${options.path}');
          networkLogger.debug('Headers: ${options.headers}');
          if (options.data != null) {
            networkLogger.debug('Data: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          networkLogger.info('RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
          networkLogger.debug('Response data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          networkLogger.error('ERROR: ${error.response?.statusCode} ${error.requestOptions.path}');
          networkLogger.error('Error message: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  Future<bool> checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      networkLogger.error('Error checking connectivity: $e');
      return false;
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (!await checkConnectivity()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
        );
      }

      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      networkLogger.error('GET request failed: $path', e);
      rethrow;
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (!await checkConnectivity()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
        );
      }

      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      networkLogger.error('POST request failed: $path', e);
      rethrow;
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (!await checkConnectivity()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
        );
      }

      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      networkLogger.error('PUT request failed: $path', e);
      rethrow;
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      if (!await checkConnectivity()) {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          error: 'No internet connection',
        );
      }

      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      networkLogger.error('DELETE request failed: $path', e);
      rethrow;
    }
  }

  void dispose() {
    _dio.close();
  }
} 