import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';
import 'package:planly_ai/app/ui/chatbot/widgets/card/alert_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/event_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/event_list_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/graph_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/schedule_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/task_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/form_card.dart';
import 'package:planly_ai/app/ui/chatbot/controller/chatbot_controller.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == SenderType.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (message.type) {
      case MessageType.cardEvent:
        return _buildCardWithAvatar(context, colorScheme, _buildEventCard());
      case MessageType.cardTask:
        return _buildCardWithAvatar(context, colorScheme, _buildTaskCard());
      case MessageType.cardAlert:
        return _buildCardWithAvatar(context, colorScheme, _buildAlertCard());
      case MessageType.cardGraph:
        return _buildCardWithAvatar(context, colorScheme, _buildGraphCard());
      case MessageType.cardSchedule:
        return _buildCardWithAvatar(context, colorScheme, _buildScheduleCard());
      case MessageType.cardEventList:
        return _buildCardWithAvatar(context, colorScheme, _buildEventListCard());
      case MessageType.cardForm:
        return _buildCardWithAvatar(context, colorScheme, _buildFormCard());
      default:
        return _buildTextBubble(context, isUser, colorScheme, theme);
    }
  }

  Widget _buildEventCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    return EventCard.fromJson(data, message: message);
  }

  Widget _buildTaskCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    return TaskCard.fromJson(data);
  }

  Widget _buildAlertCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    return AlertCard.fromJson(data);
  }

  Widget _buildGraphCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    return GraphCard.fromJson(data);
  }

  Widget _buildScheduleCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    return ScheduleCard.fromJson(data);
  }

  Widget _buildEventListCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    return EventListCard.fromJson(data);
  }

  Widget _buildFormCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    // 获取控制器实例用于提交表单
    final controller = Get.find<ChatbotController>();
    return FormCard.fromJson(data, onSubmit: (formData) => _handleFormSubmit(formData, controller));
  }

  void _handleFormSubmit(Map<String, dynamic> formData, ChatbotController controller) {
    // 将表单数据格式化为消息发送给后端
    // 流程：FORM -> 用户提交 -> AI 继续 -> GOAL/TASK
    debugPrint('[FormCard] Form submitted: $formData');
    
    // 将表单数据转换为 JSON 字符串作为消息发送
    final formDataJson = const JsonEncoder.withIndent('  ').convert(formData);
    
    // 调用控制器的 sendMessage 方法
    // 注意：这里需要临时设置 textController 的值然后发送
    controller.textController.text = '表单已提交：$formDataJson';
    controller.sendMessage();
  }

  Widget _buildCardWithAvatar(
    BuildContext context,
    ColorScheme colorScheme,
    Widget card,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.smart_toy, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(child: card),
        ],
      ),
    );
  }

  Widget _buildTextBubble(
    BuildContext context,
    bool isUser,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(
                    AppConstants.borderRadiusLarge,
                  ),
                  topRight: const Radius.circular(
                    AppConstants.borderRadiusLarge,
                  ),
                  bottomLeft: isUser
                      ? const Radius.circular(AppConstants.borderRadiusLarge)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(AppConstants.borderRadiusLarge),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.attachmentPath != null)
                    _buildAttachment(
                      context,
                      message,
                      isUser,
                      colorScheme,
                      theme,
                    ),
                  if (message.text.isNotEmpty)
                    MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        p: theme.textTheme.bodyMedium?.copyWith(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                        strong: theme.textTheme.bodyMedium?.copyWith(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        listBullet: theme.textTheme.bodyMedium?.copyWith(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                        h1: theme.textTheme.headlineMedium?.copyWith(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                        h2: theme.textTheme.headlineSmall?.copyWith(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                        h3: theme.textTheme.titleLarge?.copyWith(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isUser
                          ? colorScheme.onPrimary.withValues(alpha: 0.7)
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppConstants.spacingS),
            CircleAvatar(
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachment(
    BuildContext context,
    ChatMessage message,
    bool isUser,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    if (message.attachmentPath == null) return const SizedBox.shrink();

    final isImage = message.type == MessageType.image;

    return Container(
      margin: message.text.isNotEmpty
          ? const EdgeInsets.only(bottom: AppConstants.spacingS)
          : EdgeInsets.zero,
      constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: isUser
              ? colorScheme.onPrimary.withValues(alpha: 0.2)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: isImage
          ? Image.network(
              message.attachmentPath!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 150,
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                width: 200,
                height: 150,
                color: colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, color: colorScheme.error),
                    const SizedBox(height: 4),
                    Text(
                      'image_load_failed'.tr,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingS,
              ),
              color: isUser
                  ? colorScheme.onPrimary.withValues(alpha: 0.1)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    color: isUser ? colorScheme.onPrimary : colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Flexible(
                    child: Text(
                      message.attachmentName ?? 'File',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isUser
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
