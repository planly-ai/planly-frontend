import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:planly_ai/app/ui/chatbot/controller/chatbot_controller.dart';
import 'package:planly_ai/app/constants/app_constants.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final ChatbotController controller = Get.find<ChatbotController>();
  bool _isTextEmpty = true;

  @override
  void initState() {
    super.initState();
    controller.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    controller.textController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final isEmpty = controller.textController.text.trim().isEmpty;
    if (isEmpty != _isTextEmpty) {
      setState(() => _isTextEmpty = isEmpty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.spacingM,
        right: AppConstants.spacingM,
        top: AppConstants.spacingS,
        bottom: AppConstants.spacingS + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(IconsaxPlusLinear.attach_circle),
            color: colorScheme.onSurfaceVariant,
            onPressed: () {
              // TODO: Implement image picker logic using file_selector
            },
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller.textController,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message...'.tr,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingL,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          _isTextEmpty
              ? GestureDetector(
                  onLongPress: () {
                    // TODO: Implement voice recording UI and Logic
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconsaxPlusLinear.microphone_2,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(IconsaxPlusBold.send_1),
                  color: colorScheme.primary,
                  iconSize: 28,
                  onPressed: () => controller.sendMessage(),
                ),
        ],
      ),
    );
  }
}
