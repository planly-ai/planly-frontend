import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/controller/auth_controller.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

class UserInfoPage extends StatelessWidget {
  const UserInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final padding = ResponsiveUtils.getResponsivePadding(context);

    return Scaffold(
      appBar: AppBar(title: Text('userInfo'.tr), centerTitle: true),
      body: Center(
        child: Obx(() {
          final user = authController.user.value;
          final username = user.username;
          final firstLetter = username.isNotEmpty
              ? username[0].toUpperCase()
              : '?';

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding * 1.5),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      firstLetter,
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: padding * 1.5),
                  Text(
                    username,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: padding * 3),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium,
                      ),
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(IconsaxPlusLinear.user),
                          title: Text('username'.tr),
                          trailing: Text(username),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            IconsaxPlusLinear.logout,
                            color: colorScheme.error,
                          ),
                          title: Text(
                            'logout'.tr,
                            style: TextStyle(color: colorScheme.error),
                          ),
                          onTap: () {
                            authController.logout();
                            Get.back();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
