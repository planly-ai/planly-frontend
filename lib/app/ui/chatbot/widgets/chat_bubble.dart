import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/ai_schedule_confirmation_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/ai_focus_duration_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/ai_schedule_breakdown_card.dart';
import 'package:planly_ai/app/ui/chatbot/widgets/card/ai_timeline_schedule_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == SenderType.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 卡片类型消息的渲染
    if (!isUser && message.type == MessageType.scheduleConfirmation) {
      return _buildCardWithAvatar(
        context,
        colorScheme,
        ScheduleConfirmationCard(
          title: "季度工作汇报会议",
          time: "2026 年 3 月 10 日 下午 3:00",
          location: "3 楼会议室 A",
          reminder: "提前 15 分钟",
          onConfirm: () {
            debugPrint('日程确认按钮被点击');
          },
        ),
      );
    }

    if (!isUser && message.type == MessageType.focusDuration) {
      return _buildCardWithAvatar(
        context,
        colorScheme,
        AiFocusDurationCard(
          totalDuration: "4 小时 5 分钟",
          comparisonText: "+65 分钟",
          comparisonPercentage: "36%",
          longestSession: "90 分钟",
          chartData: const [
            FlSpot(0, 45),
            FlSpot(2, 60),
            FlSpot(4, 30),
            FlSpot(6, 55),
            FlSpot(8, 45),
            FlSpot(10, 15),
          ],
          insight: "今天的专注时间超过 3 小时，保持得非常好！",
        ),
      );
    }

    if (!isUser && message.type == MessageType.scheduleBreakdown) {
      return _buildCardWithAvatar(
        context,
        colorScheme,
        ScheduleBreakdownCard(
          title: '准备季度总结报告',
          subTasks: [
            AiSubTask(title: '收集本季度各项目数据', durationMinutes: 30),
            AiSubTask(title: '分析数据并制作图表', durationMinutes: 45),
            AiSubTask(title: '撰写报告初稿', durationMinutes: 60),
            AiSubTask(title: '审核并修改报告内容', durationMinutes: 30),
          ],
          onConfirm: () {
            debugPrint('任务拆解确认按钮被点击');
          },
        ),
      );
    }

    if (!isUser && message.type == MessageType.timelineSchedule) {
      return _buildCardWithAvatar(
        context,
        colorScheme,
        TimelineScheduleCard(
          date: "2026 年 3 月 10 日 星期二",
          busyHours: 7,
          freeHours: 7,
          events: [
            {
              "title": "团队站会",
              "time": "09:00 - 10:00",
              "tag": "会议",
              "icon": Icons.groups,
            },
            {
              "title": "深度工作时间",
              "time": "10:00 - 12:00",
              "tag": "专注",
              "icon": Icons.menu_book,
            },
            {
              "title": "处理邮件和消息",
              "time": "14:00 - 15:00",
              "tag": "忙碌",
              "icon": Icons.business_center,
            },
            {
              "title": "客户需求评审",
              "time": "15:00 - 17:00",
              "tag": "会议",
              "icon": Icons.groups,
            },
            {
              "title": "项目复盘会",
              "time": "19:00 - 20:00",
              "tag": "会议",
              "icon": Icons.groups,
            },
          ],
        ),
      );
    }

    // 普通文本消息的渲染
    return _buildTextBubble(context, isUser, colorScheme, theme);
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
            child: Icon(
              Icons.smart_toy,
              color: colorScheme.onPrimaryContainer,
            ),
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
                    _buildAttachment(context, message, isUser, colorScheme, theme),
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
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
