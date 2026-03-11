import 'package:get/get.dart';
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
    _loadUserFromSettings();
  }

  void _loadUserFromSettings() {
    if (settings.isLoggedIn) {
      user.value = User(
        username: settings.username ?? 'Guest',
        isLoggedIn: true,
      );
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _authService.login(
        username: username,
        password: password,
      );

      // Check for success - assuming a successful login returns a token or at least the username
      if (response.statusCode == 200) {
        // Extract token - prioritize 'token' or 'access_token' or whatever is available
        // User's example didn't have it, but they asked to save it.
        final token = response.data['token'] ?? response.data['access_token'];
        if (token != null) {
          await _storage.write(key: 'auth_token', value: token);
        }

        await _updateUser(username, true);
        showSnackBar('loginSuccess'.tr);

        // Navigate to settings tab (index 4)
        Get.find<HomeController>().changeTabIndex(4);
        Get.back(); // Close the Login modal

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

  Future<bool> register(String username, String password) async {
    try {
      final response = await _authService.register(
        username: username,
        password: password,
      );

      if (response.statusCode == 200 && response.data['code'] == 200) {
        showSnackBar('registerSuccess'.tr);
        // Navigate to Login page (it's already the previous page if we came from Login)
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
    await _updateUser('Guest', false);
    await _storage.delete(key: 'auth_token');
    showSnackBar('logoutSuccess'.tr);
  }

  Future<void> _updateUser(String username, bool isLoggedIn) async {
    user.value = User(username: username, isLoggedIn: isLoggedIn);

    await isar.writeTxn(() async {
      settings.username = isLoggedIn ? username : null;
      settings.isLoggedIn = isLoggedIn;
      await isar.settings.put(settings);
    });
  }
}
