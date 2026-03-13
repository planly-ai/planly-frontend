import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/services/api/planly_api_client.dart';

class AuthService {
  final Dio _dio;

  AuthService() : _dio = PlanlyApiClient.instance.dio;

  Future<Response> register({
    required String username,
    required String password,
  }) async {
    return await _dio.post(
      '/auth/register',
      data: {
        "grantType": AppConstants.grantType,
        "clientId": AppConstants.clientId,
        "username": username,
        "password": password,
        "userType": AppConstants.userType,
      },
    );
  }

  Future<Response> login({
    required String username,
    required String password,
  }) async {
    final Map<String, dynamic> data = {
      "tenantId": AppConstants.tenantId,
      "grantType": AppConstants.grantType,
      "clientId": AppConstants.clientId,
      "username": username,
      "password": password,
    };

    final response = await _dio.post(
      '/auth/login',
      options: Options(
        contentType: 'text/plain',
        responseType: ResponseType.plain,
      ),
      data: jsonEncode(data),
    );

    if (response.data is String) {
      try {
        response.data = jsonDecode(response.data);
      } catch (e) {
        // Not a JSON string, keep it as is
      }
    }
    return response;
  }

  Future<Response> getProfile() async {
    // token 会由 AuthInterceptor 自动添加
    return await _dio.get('/system/user/profile');
  }

  Future<Response> logout() async {
    // token 会由 AuthInterceptor 自动添加
    return await _dio.post('/auth/logout');
  }
}
