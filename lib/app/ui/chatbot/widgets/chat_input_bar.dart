import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:planly_ai/app/ui/chatbot/controller/chatbot_controller.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/voice_recording_overlay.dart';
import 'package:planly_ai/app/utils/show_snack_bar.dart';

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
      backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left Camera Icon / File Thumbnail
                    Obx(() {
                      final hasFile = controller.selectedFile.value != null;
                      final isUploading = controller.isUploading.value;
                      final isImage = controller.uploadedFileName.value
                              ?.toLowerCase()
                              .endsWith('.png') ==
                          true ||
                          controller.uploadedFileName.value
                              ?.toLowerCase()
                              .endsWith('.jpg') ==
                          true ||
                          controller.uploadedFileName.value
                              ?.toLowerCase()
                              .endsWith('.jpeg') ==
                          true;

                      if (!hasFile) {
                        return IconButton(
                          icon: const Icon(IconsaxPlusLinear.camera),
                          iconSize: 28,
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          color: colorScheme.onSurfaceVariant,
                          onPressed: () {
                            // TODO: Implement camera functionality
                          },
                        );
                      }

                      return Container(
                        margin: const EdgeInsets.all(4),
                        width: 36,
                        height: 36,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: colorScheme.outlineVariant,
                                child: Center(
                                  child: isImage
                                      ? Image.network(
                                          controller.uploadedUrl.value!,
                                          fit: BoxFit.cover,
                                          width: 36,
                                          height: 36,
                                          errorBuilder: (c, e, s) => const Icon(
                                            IconsaxPlusLinear.document,
                                            size: 20,
                                          ),
                                        )
                                      : const Icon(IconsaxPlusLinear.document,
                                          size: 20),
                                ),
                              ),
                            ),
                            if (isUploading)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            else if (controller.uploadedUrl.value != null)
                              Positioned.fill(
                                child: Material(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => controller.removeSelectedFile(),
                                    child: const Center(
                                      child: Icon(
                                        IconsaxPlusLinear.close_circle,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
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
                            hintText: 'input_hint'.tr,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
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
                    Obx(() {
                      final hasFile = controller.selectedFile.value != null;
                      final isUploading = controller.isUploading.value;
                      final textNotEmpty = !_isTextEmpty;

                      if (textNotEmpty || hasFile) {
                        return IconButton(
                          icon: const Icon(IconsaxPlusBold.send_1),
                          color: (isUploading)
                              ? colorScheme.outline
                              : colorScheme.primary,
                          iconSize: 28,
                          onPressed: (isUploading)
                              ? null
                              : () => controller.sendMessage(),
                        );
                      }

                      return Row(
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
                              iconSize: 28,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                showSnackBar(
                                  'voice_long_press_hint'.tr,
                                  isInfo: true,
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(IconsaxPlusLinear.add_circle),
                            color: colorScheme.onSurfaceVariant,
                            iconSize: 28,
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => controller.pickAndUploadFile(),
                          ),
                        ],
                      );
                    }),
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
