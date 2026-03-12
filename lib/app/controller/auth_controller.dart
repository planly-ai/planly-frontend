import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/app/data/models/user.dart';
import 'package:planly_ai/app/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:planly_ai/app/controller/home_controller.dart';
import 'package:planly_ai/app/utils/show_snack_bar.dart';
import 'package:planly_ai/main.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Rx<User> user = User.guest().obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    final isLoggedInStr = await _storage.read(key: 'is_logged_in');
    final isLoggedIn = isLoggedInStr == 'true';

    if (isLoggedIn) {
      final username = await _storage.read(key: 'username');
      final userId = await _storage.read(key: 'user_id');
      final userType = await _storage.read(key: 'user_type');
      final tenantId = await _storage.read(key: 'tenant_id');
      final loginDate = await _storage.read(key: 'login_date');

      user.value = User(
        username: username ?? 'Guest',
        isLoggedIn: true,
        userId: userId,
        userType: userType,
        tenantId: tenantId,
        loginDate: loginDate,
      );
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _authService.login(
        username: username,
        password: password,
      );

      final responseData = response.data;
      final bool isSuccess = response.statusCode == 200 &&
          (responseData['code'] == null || responseData['code'] == 200);

      if (isSuccess) {
        // Token 可能在根字段或 data 字段中
        final token = responseData['token'] 
            ?? responseData['access_token'] 
            ?? responseData['data']?['token'] 
            ?? responseData['data']?['access_token'];
        
        debugPrint('[Login] Response token: ${token != null ? "exists" : "null"}');
        debugPrint('[Login] Response data keys: ${responseData.keys.toList()}');
        if (responseData['data'] != null) {
          debugPrint('[Login] Response data keys: ${responseData['data'].keys.toList()}');
        }

        if (token != null) {
          await _storage.write(key: 'auth_token', value: token);
          debugPrint('[Login] Token saved to secure storage');

          // Fetch detailed profile
          try {
            final profileResponse = await _authService.getProfile(token);
            if (profileResponse.statusCode == 200 && profileResponse.data['code'] == 200) {
              final userData = profileResponse.data['data']['user'];
              debugPrint('[Login] Profile fetched successfully, userId: ${userData['userId']}');
              await _updateUser(
                username: userData['userName'] ?? username,
                isLoggedIn: true,
                userId: userData['userId'],
                userType: userData['userType'],
                tenantId: userData['tenantId'],
                loginDate: userData['loginDate'],
                authToken: token,
              );
            } else {
              debugPrint('[Login] Profile fetch failed, status: ${profileResponse.statusCode}');
              await _updateUser(username: username, isLoggedIn: true, authToken: token);
            }
          } catch (e) {
            debugPrint('[Login] Profile fetch exception: $e');
            await _updateUser(username: username, isLoggedIn: true, authToken: token);
          }
        } else {
          debugPrint('[Login] No token in response');
          await _updateUser(username: username, isLoggedIn: true);
        }

        showSnackBar('loginSuccess'.tr);

        Get.find<HomeController>().changeTabIndex(4);
        Get.back();

        return true;
      } else {
        final errorMsg =
            responseData['msg'] ?? responseData['message'] ?? 'error'.tr;
        showSnackBar(errorMsg, isError: true);
        return false;
      }
    } catch (e) {
      debugPrint('[Login] Exception: $e');
      showSnackBar('error'.tr, isError: true);
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      final response = await _authService.register(
        username: username,
        password: password,
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        showSnackBar('registerSuccess'.tr);
        Get.back();
        return true;
      } else {
        showSnackBar(response.data['msg'] ?? 'error'.tr, isError: true);
        return false;
      }
    } catch (e) {
      showSnackBar('error'.tr, isError: true);
      return false;
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await _authService.logout(token);
      } catch (e) {
        // Ignored
      }
    }
    await _updateUser(username: 'Guest', isLoggedIn: false);
    await _storage.delete(key: 'auth_token');
    showSnackBar('logoutSuccess'.tr);
  }

  Future<void> _updateUser({
    required String username,
    required bool isLoggedIn,
    String? userId,
    String? userType,
    String? tenantId,
    String? loginDate,
    String? authToken,
  }) async {
    user.value = User(
      username: username,
      isLoggedIn: isLoggedIn,
      userId: userId,
      userType: userType,
      tenantId: tenantId,
      loginDate: loginDate,
    );

    // Save to secure storage
    if (isLoggedIn) {
      await _storage.write(key: 'is_logged_in', value: 'true');
      await _storage.write(key: 'username', value: username);
      if (userId != null) await _storage.write(key: 'user_id', value: userId);
      if (userType != null) await _storage.write(key: 'user_type', value: userType);
      if (tenantId != null) await _storage.write(key: 'tenant_id', value: tenantId);
      if (loginDate != null) await _storage.write(key: 'login_date', value: loginDate);
      // Save auth token if provided
      if (authToken != null) {
        await _storage.write(key: 'auth_token', value: authToken);
        debugPrint('[Auth] Token saved in _updateUser: ${authToken.substring(0, 20)}...');
      }
    } else {
      await _storage.delete(key: 'is_logged_in');
      await _storage.delete(key: 'username');
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'user_type');
      await _storage.delete(key: 'tenant_id');
      await _storage.delete(key: 'login_date');
      await _storage.delete(key: 'auth_token');
    }

    // Also update Isar settings for consistency if other parts of the app use it
    await isar.writeTxn(() async {
      settings.username = isLoggedIn ? username : null;
      settings.isLoggedIn = isLoggedIn;
      settings.userId = isLoggedIn ? userId : null;
      settings.userType = isLoggedIn ? userType : null;
      settings.tenantId = isLoggedIn ? tenantId : null;
      settings.loginDate = isLoggedIn ? loginDate : null;
      await isar.settings.put(settings);
    });
  }
}
