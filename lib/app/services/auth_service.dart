import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:planly_ai/app/constants/app_constants.dart';

class AuthService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.planlyBaseUrl,
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

  Future<Response> getProfile(String token) async {
    return await _dio.get(
      '/system/user/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response> logout(String token) async {
    return await _dio.post(
      '/auth/logout',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
