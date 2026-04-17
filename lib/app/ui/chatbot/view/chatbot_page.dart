import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/app/ui/chatbot/controller/chatbot_controller.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/chat_bubble.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/chat_input_bar.dart';

import 'package:planly_ai/app/ui/chatbot/widgets/card/session_card.dart';
import 'package:planly_ai/app/constants/app_constants.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late final ChatbotController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ChatbotController());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final session = controller.sessions.firstWhereOrNull(
            (s) => s.id == controller.currentSessionId.value,
          );
          return Text(session?.title ?? 'Chatbot'.tr);
        }),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(IconsaxPlusLinear.menu_1),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chat History'.tr,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(IconsaxPlusLinear.close_circle),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          controller.createNewSession();
                        },
                        label: Text(
                          'New Chat'.tr,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              const SizedBox(height: AppConstants.spacingS),
              Expanded(
                child: Obx(() {
                  if (controller.sessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconsaxPlusLinear.message_question,
                            size: 48,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No history'.tr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: controller.sessions.length,
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.spacingXL,
                    ),
                    itemBuilder: (context, index) {
                      final session = controller.sessions[index];
                      final isSelected =
                          session.id == controller.currentSessionId.value;
                      return SessionCard(
                        title: session.title,
                        isSelected: isSelected,
                        onTap: () {
                          controller.selectSession(session.id);
                          Navigator.pop(context);
                        },
                        onDelete: () => controller.deleteSession(session.id),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final currentMessages = controller.messages;
              final isRecognizing = controller.isRecognizing.value;
              final isTyping = controller.isTyping.value;
              final streamingId = controller.currentStreamingBotMessageId.value;
              final isReasoning = controller.isReasoning.value;
              final reasoningText = controller.liveReasoningText.value;

              if (currentMessages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        IconsaxPlusLinear.message_2,
                        size: 64,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Start a conversation'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount:
                    currentMessages.length +
                    (isRecognizing ? 1 : 0) +
                    (isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  // Message bubbles
                  if (index < currentMessages.length) {
                    final msg = currentMessages[index];
                    final isStreamingMsg =
                        streamingId != null &&
                        msg.id == streamingId &&
                        msg.sender == SenderType.bot &&
                        msg.type == MessageType.text;

                    return ChatBubble(
                      message: msg,
                      showStreamingStatus: isStreamingMsg,
                      isReasoning: isReasoning,
                      reasoningText: reasoningText,
                    );
                  }

                  // ASR Recognition state (User side)
                  if (isRecognizing && index == currentMessages.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'voice_recognizing'.tr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.person,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Bot Typing state
                  final hasStreamingMessage = streamingId != null;
                  if (hasStreamingMessage) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.smart_toy,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (isReasoning ||
                                          reasoningText.trim().isNotEmpty)
                                      ? 'Thinking...'
                                      : 'Generating...',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (reasoningText.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    reasoningText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          const ChatInputBar(),
        ],
      ),
    );
  }
}
