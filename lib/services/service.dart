import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static const String baseUrl = 'https://wyapp.inteagle.com/api';

  // 设备相关端点
  static String get devices => '$baseUrl/devices';
  static String device(String id) => '$baseUrl/devices/$id';
}

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // 添加日志拦截器
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }

    // 添加错误处理拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) {
        // 统一错误处理
        if (e.response != null) {
          // 处理服务端错误
          return handler.next(e);
        } else {
          // 处理网络错误
          return handler.next(e);
        }
      },
    ));
  }

  // GET 请求
  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return _dio.get(path, queryParameters: params);
  }

  // POST 请求
  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  // PUT 请求
  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  // DELETE 请求
  Future<Response> delete(String path) async {
    return _dio.delete(path);
  }

  // 其他通用请求方法...
}
