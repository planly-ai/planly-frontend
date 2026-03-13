import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/services/interceptors/auth_interceptor.dart';

/// Planly API 客户端
/// 
/// 提供统一的 Dio 实例，自动处理认证 header (token + clientId)
/// 所有需要访问 Planly 后端的服务都应该使用这个客户端
class PlanlyApiClient {
  static PlanlyApiClient? _instance;
  late final Dio _dio;

  PlanlyApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.planlyBaseUrl,
        contentType: 'application/json',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // 添加认证拦截器
    _dio.interceptors.add(AuthInterceptor());

    // 添加日志拦截器 (开发环境)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('[PlanlyAPI] $obj'),
      ),
    );
  }

  /// 获取单例实例
  static PlanlyApiClient get instance {
    _instance ??= PlanlyApiClient._internal();
    return _instance!;
  }

  /// 获取 Dio 实例
  Dio get dio => _dio;

  /// 清除认证信息 (登出时调用)
  Future<void> clearAuth() async {
    // 可以在这里清除缓存的 token 等
    debugPrint('[PlanlyApiClient] Auth cleared');
  }
}
