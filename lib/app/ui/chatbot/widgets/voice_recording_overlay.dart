import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:planly_ai/app/ui/chatbot/controller/chatbot_controller.dart';

class VoiceRecordingOverlay extends StatelessWidget {
  const VoiceRecordingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = Get.find<ChatbotController>();

    return Obx(() {
      final isCancelling = controller.isCancellingRecording.value;

      return Container(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(60),
            topRight: Radius.circular(60),
          ),
        ),
        child: IgnorePointer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCancelling
                    ? IconsaxPlusBold.trash
                    : IconsaxPlusLinear.voice_cricle,
                size: 36,
                color: isCancelling
                    ? colorScheme.error
                    : colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 16),
              Text(
                isCancelling ? '松开手指，取消发送'.tr : '上滑取消 或 松开发送'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isCancelling
                      ? colorScheme.error
                      : colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
