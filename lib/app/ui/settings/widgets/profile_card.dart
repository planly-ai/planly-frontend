import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/controller/auth_controller.dart';
import 'package:planly_ai/app/ui/auth/login.dart';
import 'package:planly_ai/app/ui/auth/user_info.dart';
import 'package:planly_ai/app/utils/navigation_helper.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final user = authController.user.value;
      final isLoggedIn = user.isLoggedIn;
      final username = user.username;
      final firstLetter = username.isNotEmpty ? username[0].toUpperCase() : '?';

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: AppConstants.borderWidthThin,
          ),
        ),
        child: InkWell(
          onTap: () {
            if (isLoggedIn) {
              NavigationHelper.slideUp(const UserInfoPage());
            } else {
              NavigationHelper.slideUp(const LoginPage());
            }
          },
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    firstLetter,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn ? username : 'notLoggedIn'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoggedIn ? 'userInfo'.tr : 'loginToSync'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
    });
  }
}
