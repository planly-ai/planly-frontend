import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:planly_ai/app/constants/app_constants.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.authBaseUrl,
      contentType: 'application/json',
    ),
  );

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

    return await _dio.post(
      '/auth/login',
      options: Options(contentType: 'text/plain'),
      data: jsonEncode(data),
    );
  }
}
