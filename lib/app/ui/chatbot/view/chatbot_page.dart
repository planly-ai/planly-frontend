import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:planly_ai/app/ui/chatbot/controller/chatbot_controller.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/chat_bubble.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/chat_input_bar.dart';

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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Chat History'.tr, style: theme.textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(IconsaxPlusLinear.add_square),
                      onPressed: () {
                        Navigator.pop(context);
                        controller.createNewSession();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Obx(() {
                  if (controller.sessions.isEmpty) {
                    return Center(child: Text('No history'.tr));
                  }
                  return ListView.builder(
                    itemCount: controller.sessions.length,
                    itemBuilder: (context, index) {
                      final session = controller.sessions[index];
                      final isSelected =
                          session.id == controller.currentSessionId.value;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: colorScheme.primaryContainer
                            .withValues(alpha: 0.5),
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(IconsaxPlusLinear.trash),
                          onPressed: () => controller.deleteSession(session.id),
                        ),
                        onTap: () {
                          controller.selectSession(session.id);
                          Navigator.pop(context);
                        },
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
              if (controller.messages.isEmpty) {
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
                    controller.messages.length +
                    (controller.isRecognizing.value ? 1 : 0) +
                    (controller.isTyping.value ? 1 : 0),
                itemBuilder: (context, index) {
                  // Message bubbles
                  if (index < controller.messages.length) {
                    final msg = controller.messages[index];
                    return ChatBubble(message: msg);
                  }

                  // ASR Recognition state (User side)
                  if (controller.isRecognizing.value &&
                      index == controller.messages.length) {
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.smart_toy,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Generating...'.tr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontStyle: FontStyle.italic,
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
