import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:planly_ai/app/constants/app_constants.dart';

/// 认证拦截器：自动为所有 Planly 后端请求添加认证信息
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 从安全存储中读取 token
    final token = await _storage.read(key: 'auth_token');
    
    if (token != null && token.isNotEmpty) {
      // 添加 Authorization header
      options.headers['Authorization'] = 'Bearer $token';
      debugPrint('[AuthInterceptor] Added token: ${token.substring(0, 20)}...');
    }

    // 添加 clientId header (如果请求体中没有包含)
    options.headers['clientId'] = AppConstants.clientId;
    debugPrint('[AuthInterceptor] Added clientId: ${AppConstants.clientId}');

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 处理 401 未授权错误 (token 过期或无效)
    if (err.response?.statusCode == 401) {
      debugPrint('[AuthInterceptor] 401 Unauthorized - Token may be expired');
      // 这里可以添加自动刷新 token 的逻辑，或者跳转到登录页
      // await _handleTokenRefresh(err);
    }
    
    handler.next(err);
  }
}
