import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

@riverpod
Dio dio(DioRef ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.1.230:9999/api', // 替换为你的API地址
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // 添加拦截器（可选）
  dio.interceptors.add(LogInterceptor(
    request: true,
    responseBody: true,
    error: true,
  ));

  return dio;
}
