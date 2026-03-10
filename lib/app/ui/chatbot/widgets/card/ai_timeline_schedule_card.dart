import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

class TimelineScheduleCard extends StatelessWidget {
  final String date;
  final int busyHours;
  final int freeHours;
  final List<Map<String, dynamic>> events;

  const TimelineScheduleCard({
    super.key,
    required this.date,
    required this.busyHours,
    required this.freeHours,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.elevationLow,
      margin: EdgeInsets.all(ResponsiveUtils.getResponsiveCardMargin(context)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Integrated Header: Icon + Title (StatsCard Style)
            _buildIntegratedHeader(context),

            const SizedBox(height: AppConstants.spacingL),

            // Statistics Section
            _buildStatistics(context),
            const SizedBox(height: AppConstants.spacingL),

            // Segmented Timeline Bar
            _buildSegmentedTimeline(context),
            const SizedBox(height: AppConstants.spacingXL),

            // Event List
            ...events.map((event) => _buildEventItem(context, event)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegratedHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = colorScheme.primary; // Timeline primary color

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Icon(
            Icons.access_time_filled,
            size: AppConstants.iconSizeMedium,
            color: color,
          ),
        ),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'timeline_title'.tr,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _buildStatBox(
          context,
          label: 'timeline_busy'.tr,
          value: '$busyHours',
          unit: '小时',
          color: colorScheme.primary,
          bgColor: colorScheme.primary.withValues(alpha: 0.12),
        ),
        const SizedBox(width: AppConstants.spacingM),
        _buildStatBox(
          context,
          label: 'timeline_free'.tr,
          value: '$freeHours',
          unit: '小时',
          color: colorScheme.onSurfaceVariant,
          bgColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildStatBox(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required Color color,
    required Color bgColor,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      16,
                    ),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      12,
                    ),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedTimeline(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

    // Derived from primary theme with varying opacities
    final List<Color?> segments = [
      null,
      primary,
      primary.withValues(alpha: 0.7),
      primary.withValues(alpha: 0.4),
      null,
      null,
      primary.withValues(alpha: 0.8),
      primary,
      primary,
      null,
      null,
      primary,
      null,
      null,
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: segments.map((color) {
            return _buildTimelineBar(context, color);
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTimeLabel(context, '8:00'),
            _buildTimeLabel(context, '14:00'),
            _buildTimeLabel(context, '21:00'),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineBar(BuildContext context, Color? color) {
    return Expanded(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildTimeLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, Map<String, dynamic> event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String tag;
    Color color;
    switch (event['tag']) {
      case '会议':
        tag = 'tag_meeting'.tr;
        color = colorScheme.primary;
        break;
      case '专注':
        tag = 'tag_focus'.tr;
        color = colorScheme.primary.withValues(alpha: 0.8);
        break;
      case '忙碌':
        tag = 'tag_busy'.tr;
        color = colorScheme.primary.withValues(alpha: 0.6);
        break;
      default:
        tag = event['tag'] as String;
        color = colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              event['icon'] as IconData,
              color: Colors.white,
              size: AppConstants.iconSizeMedium,
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] as String,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      14,
                    ),
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  event['time'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      12,
                    ),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Preview main function for testing
void main() {
  runApp(const TimelineScheduleTestApp());
}

class TimelineScheduleTestApp extends StatelessWidget {
  const TimelineScheduleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('时间轴进度卡片展示'), centerTitle: true),
        backgroundColor: Colors.grey[100],
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TimelineScheduleCard(
                date: "2026年3月10日 星期二",
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
            ],
          ),
        ),
      ),
    );
  }
}
