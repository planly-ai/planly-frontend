import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:planly_ai/app/ui/chatbot/controller/chatbot_controller.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/voice_recording_overlay.dart';

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

  void _handlePresetPrompt(String prompt) {
    controller.textController.text = prompt;
  }

  Widget _buildPresetPromptChip(String label, ThemeData theme) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _handlePresetPrompt(label),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.5,
      ),
      labelStyle: TextStyle(color: theme.colorScheme.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.transparent),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        Container(
          padding: EdgeInsets.only(
            left: AppConstants.spacingM,
            right: AppConstants.spacingM,
            top: AppConstants.spacingXS,
            bottom:
                AppConstants.spacingS + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preset Prompts Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetPromptChip('query_tomorrow_schedule'.tr, theme),
                    const SizedBox(width: 8),
                    _buildPresetPromptChip('generate_weekly_report'.tr, theme),
                    const SizedBox(width: 8),
                    _buildPresetPromptChip('summarize_today_tasks'.tr, theme),
                    const SizedBox(width: 8),
                    _buildPresetPromptChip('create_new_event'.tr, theme),
                    const SizedBox(width: 8),
                    _buildPresetPromptChip('set_reminder'.tr, theme),
                    const SizedBox(width: 8),
                    _buildPresetPromptChip('view_week_overview'.tr, theme),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Input Row
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(32),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left Camera Icon
                    IconButton(
                      icon: const Icon(IconsaxPlusLinear.camera),
                      iconSize: 28,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ), // 增大点击区域
                      color: colorScheme.onSurfaceVariant,
                      onPressed: () {
                        // TODO: Implement camera functionality
                      },
                    ),
                    // Middle Text Field
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          controller: controller.textController,
                          maxLines: 5,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => controller.sendMessage(),
                          decoration: InputDecoration(
                            hintText: '发消息或按住说话...'.tr,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none, // 启用状态
                            focusedBorder: InputBorder.none, // 聚焦状态
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Right Icons
                    _isTextEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onLongPressStart: (details) {
                                  controller.startRecording(
                                    details.globalPosition.dy,
                                  );
                                },
                                onLongPressMoveUpdate: (details) {
                                  controller.updateRecordingPointer(
                                    details.globalPosition.dy,
                                  );
                                },
                                onLongPressEnd: (details) {
                                  controller.endRecording();
                                },
                                child: IconButton(
                                  icon: const Icon(
                                    IconsaxPlusLinear.voice_cricle,
                                  ),
                                  color: colorScheme.onSurfaceVariant,
                                  iconSize: 28, // 增大图标
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ), // 增大点击区域
                                  padding: EdgeInsets.zero, // 移除默认内边距避免挤压
                                  onPressed: () {},
                                ),
                              ),
                              IconButton(
                                icon: const Icon(IconsaxPlusLinear.add_circle),
                                color: colorScheme.onSurfaceVariant,
                                iconSize: 28,
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ), // 增大点击区域
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  // TODO: Implement Add File functionality
                                },
                              ),
                            ],
                          )
                        : IconButton(
                            icon: const Icon(IconsaxPlusBold.send_1),
                            color: colorScheme.primary,
                            iconSize: 28,
                            onPressed: () => controller.sendMessage(),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Overlay layer handled conditionally by Obx
        Obx(() {
          if (!controller.isRecording.value) return const SizedBox.shrink();

          return const Positioned.fill(child: VoiceRecordingOverlay());
        }),
      ],
    );
  }
}
