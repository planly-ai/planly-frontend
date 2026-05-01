import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';
import 'package:planly_ai/app/ui/chatbot/utils/form_submission_formatter.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/agent_block_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/alert_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/event_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/event_list_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/graph_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/schedule_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/task_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/task_proposal_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/form_card.dart';
import 'package:planly_ai/app/ui/chatbot/controller/chatbot_controller.dart';
import 'package:planly_ai/main.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreamingBlock;

  const ChatBubble({
    super.key,
    required this.message,
    this.isStreamingBlock = false,
  });

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
        return _buildCardWithAvatar(
          context,
          colorScheme,
          _buildEventListCard(),
        );
      case MessageType.cardForm:
        return _buildCardWithAvatar(context, colorScheme, _buildFormCard());
      case MessageType.reasoning:
        return _buildAgentBlockWithAvatar(
          context,
          colorScheme,
          _buildReasoningBlock(context),
        );
      case MessageType.toolCall:
        return _buildAgentBlockWithAvatar(
          context,
          colorScheme,
          _buildToolCallBlock(context),
        );
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
    if (data is Map<String, dynamic> &&
        (data['subTasks'] is List || data['events'] is List)) {
      return TaskProposalCard.fromJson(data, message: message);
    }
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
    return FormCard.fromJson(
      data,
      onSubmit: (formData) => _handleFormSubmit(formData, controller),
    );
  }

  Widget _buildReasoningBlock(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AgentBlockCard(
      title: 'Thinking',
      content: message.text,
      isStreaming: isStreamingBlock,
      style: AgentBlockCardStyle.thinking(colorScheme),
      contentTextStyle: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.66),
        fontSize: 11,
        height: 1.35,
      ),
    );
  }

  Widget _buildToolCallBlock(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metadata = _decodeToolCallMetadata();
    final name = metadata['name']?.toString();
    final title = name == null || name.isEmpty
        ? 'Tool call'
        : 'Tool call: $name';

    return AgentBlockCard(
      title: title,
      content: _formatToolArguments(message.text),
      isStreaming: isStreamingBlock,
      style: AgentBlockCardStyle.toolCall(colorScheme),
      contentTextStyle: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.76),
        fontSize: 11,
        fontFamily: 'monospace',
        height: 1.35,
      ),
    );
  }

  Map<String, dynamic> _decodeToolCallMetadata() {
    try {
      final decoded = jsonDecode(message.cardContent ?? '{}');
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }

  String _formatToolArguments(String value) {
    try {
      final decoded = jsonDecode(value);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return value;
    }
  }

  void _handleFormSubmit(
    Map<String, dynamic> formData,
    ChatbotController controller,
  ) async {
    // 流程：FORM -> 用户提交 -> AI 继续 -> GOAL/TASK
    debugPrint('[FormCard] Form submitted: $formData');
    final formCardData = FormSubmissionFormatter.decodeCardData(
      message.cardContent,
    );

    // 1. 持久化表单状态到当前消息
    try {
      message.cardContent = FormSubmissionFormatter.markSubmitted(
        cardContent: message.cardContent,
        values: formData,
      );

      // 保存到数据库
      await isar.writeTxn(() async {
        await isar.chatMessages.put(message);
      });

      // 刷新控制器以更新 UI
      controller.messages.refresh();
    } catch (e) {
      debugPrint('[ChatBubble] Error persisting form state: $e');
    }

    // 2. 发送消息给 AI
    final submissionMessage = FormSubmissionFormatter.formatSubmissionMessage(
      cardData: formCardData,
      values: formData,
    );
    controller.textController.text = submissionMessage;
    controller.sendMessage();
  }

  Widget _buildCardWithAvatar(
    BuildContext context,
    ColorScheme colorScheme,
    Widget card,
  ) {
    return _buildBotMessageShell(colorScheme: colorScheme, child: card);
  }

  Widget _buildAgentBlockWithAvatar(
    BuildContext context,
    ColorScheme colorScheme,
    Widget child,
  ) {
    return _buildBotMessageShell(colorScheme: colorScheme, child: child);
  }

  Widget _buildBotMessageShell({
    required ColorScheme colorScheme,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(colorScheme: colorScheme, isUser: false),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildAvatar({
    required ColorScheme colorScheme,
    required bool isUser,
  }) {
    return CircleAvatar(
      backgroundColor: isUser
          ? colorScheme.secondaryContainer
          : colorScheme.primaryContainer,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: isUser
            ? colorScheme.onSecondaryContainer
            : colorScheme.onPrimaryContainer,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(colorScheme: colorScheme, isUser: false),
            const SizedBox(width: AppConstants.spacingS),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary
                    : colorScheme.primaryContainer.withValues(alpha: 0.32),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    isUser ? AppConstants.borderRadiusLarge : 4,
                  ),
                  topRight: Radius.circular(
                    isUser ? 4 : AppConstants.borderRadiusLarge,
                  ),
                  bottomLeft: const Radius.circular(
                    AppConstants.borderRadiusLarge,
                  ),
                  bottomRight: const Radius.circular(
                    AppConstants.borderRadiusLarge,
                  ),
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
                              : colorScheme.onPrimaryContainer,
                        ),
                        strong: theme.textTheme.bodyMedium?.copyWith(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        listBullet: theme.textTheme.bodyMedium?.copyWith(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onPrimaryContainer,
                        ),
                        h1: theme.textTheme.headlineMedium?.copyWith(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onPrimaryContainer,
                        ),
                        h2: theme.textTheme.headlineSmall?.copyWith(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onPrimaryContainer,
                        ),
                        h3: theme.textTheme.titleLarge?.copyWith(
                          color: isUser
                              ? colorScheme.onPrimary
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isUser
                          ? colorScheme.onPrimary.withValues(alpha: 0.7)
                          : colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.68,
                            ),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppConstants.spacingS),
            _buildAvatar(colorScheme: colorScheme, isUser: true),
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
