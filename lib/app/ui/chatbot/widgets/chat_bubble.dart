import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:planly_ai/app/ui/chatbot/widgets/card/alert_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/event_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/event_list_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/graph_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/schedule_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/task_card.dart';

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
      default:
        return _buildTextBubble(context, isUser, colorScheme, theme);
    }
  }

  Widget _buildEventCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    return EventCard(
      title: data['title'] ?? '',
      time: data['time'] ?? '${data['startTime'] ?? ''} - ${data['endTime'] ?? ''}',
      location: data['location'] ?? data['description'] ?? '',
      reminder: data['reminder'] ?? 'None',
    );
  }

  Widget _buildTaskCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    final subtasksData = data['subTasks'] as List? ?? [];
    final subTasks = subtasksData.map((s) {
      return AiSubTask(
        title: s['title'] ?? '',
        durationMinutes: s['durationMinutes'] ?? 0,
        isCompleted: s['isCompleted'] ?? false,
      );
    }).toList();

    return TaskCard(
      title: data['title'] ?? '',
      subTasks: subTasks,
    );
  }

  Widget _buildAlertCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    return AlertCard(
      title: data['title'] ?? '',
      alertTime: data['alertTime'] ?? data['startTime'] ?? '',
      message: data['message'] ?? data['description'] ?? '',
      repeatStrategy: data['repeatStrategy'] ?? 'ONCE',
    );
  }

  Widget _buildGraphCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    final chartDataJson = data['chartData'] as List? ?? [];
    final chartData = chartDataJson.map((s) {
      return FlSpot(
        (s['x'] ?? 0).toDouble(),
        (s['y'] ?? 0).toDouble(),
      );
    }).toList();

    return GraphCard(
      totalDuration: data['totalDuration'] ?? '',
      comparisonText: data['comparisonText'] ?? '',
      comparisonPercentage: data['comparisonPercentage'] ?? '',
      longestSession: data['longestSession'] ?? '',
      chartData: chartData,
      insight: data['insight'] ?? '',
    );
  }

  Widget _buildScheduleCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    final eventsData = data['events'] as List? ?? [];
    final events = eventsData.map((e) {
      return {
        'title': e['title'] ?? '',
        'time': e['time'] ?? '',
        'tag': e['tag'] ?? '',
        'icon': _getIconForTag(e['tag']),
      };
    }).toList();

    return ScheduleCard(
      date: data['date'] ?? '',
      busyHours: data['busyHours'] ?? 0,
      freeHours: data['freeHours'] ?? 0,
      events: events,
    );
  }

  IconData _getIconForTag(String? tag) {
    switch (tag) {
      case '会议': return Icons.groups;
      case '专注': return Icons.menu_book;
      case '忙碌': return Icons.business_center;
      default: return Icons.event;
    }
  }

  Widget _buildEventListCard() {
    final data = jsonDecode(message.cardContent ?? '{}');
    final eventCardsData = data['eventCards'] as List? ?? [];
    final eventCards = eventCardsData.map((e) => Map<String, String>.from(e)).toList();

    return EventListCard(
      title: data['title'] ?? '',
      eventCards: eventCards,
    );
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
