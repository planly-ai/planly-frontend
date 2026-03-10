import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
    final color = const Color(0xFF2962FF); // Timeline primary color

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
                '今日时间轴',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 10),
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
    return Row(
      children: [
        _buildStatBox(
          context,
          label: '忙碌时段',
          value: '$busyHours',
          unit: '小时',
          color: Colors.red,
          bgColor: const Color(0xFFFFEBEE),
        ),
        const SizedBox(width: AppConstants.spacingM),
        _buildStatBox(
          context,
          label: '空闲时段',
          value: '$freeHours',
          unit: '小时',
          color: const Color(0xFF00C853),
          bgColor: const Color(0xFFE8F5E9),
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
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
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
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      24,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      14,
                    ),
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
    // Colors derived from the image
    final List<Color?> segments = [
      null,
      const Color(0xFF2979FF),
      const Color(0xFFAA00FF),
      const Color(0xFFD500F9),
      null,
      null,
      const Color(0xFFFF1744),
      const Color(0xFF2979FF),
      const Color(0xFF2979FF),
      null,
      null,
      const Color(0xFF2979FF),
      null,
      null,
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: segments.map((color) {
            return _buildTimelineBar(color);
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

  Widget _buildTimelineBar(Color? color) {
    return Expanded(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color ?? const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildTimeLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: const Color(0xFF9E9E9E),
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, Map<String, dynamic> event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color color;
    switch (event['tag']) {
      case '会议':
        color = const Color(0xFF2979FF);
        break;
      case '专注':
        color = const Color(0xFFAA00FF);
        break;
      case '忙碌':
        color = const Color(0xFFFF1744);
        break;
      default:
        color = colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
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
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                Text(
                  event['time'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF757575),
                    fontSize: 13,
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
              event['tag'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
