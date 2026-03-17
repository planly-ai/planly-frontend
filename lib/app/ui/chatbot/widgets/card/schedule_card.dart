import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

class ScheduleCard extends StatelessWidget {
  final String title;
  final String timeDescription;
  final List<ScheduleEventData> eventList;

  const ScheduleCard({
    super.key,
    required this.title,
    required this.timeDescription,
    required this.eventList,
  });

  factory ScheduleCard.fromJson(Map<String, dynamic> json) {
    final list = json['eventList'] as List? ?? [];
    return ScheduleCard(
      title: json['title'] ?? '',
      timeDescription: json['timeDescription'] ?? '',
      eventList: list.map((e) => ScheduleEventData.fromJson(e)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate busy hours
    double totalBusyMinutes = 0;
    for (var event in eventList) {
      try {
        final start = DateTime.parse(event.startTime);
        final end = DateTime.parse(event.endTime);
        totalBusyMinutes += end.difference(start).inMinutes;
      } catch (_) {}
    }
    int busyHours = (totalBusyMinutes / 60).round();
    int freeHours = 14 - busyHours; // Assume a 14-hour workday (8am - 10pm)
    if (freeHours < 0) freeHours = 0;

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
            _buildIntegratedHeader(context),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              timeDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            _buildStatistics(context, busyHours, freeHours),
            const SizedBox(height: AppConstants.spacingL),
            _buildSegmentedTimeline(context),
            const SizedBox(height: AppConstants.spacingXL),
            ...eventList.map((event) => _buildEventItem(context, event)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegratedHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = colorScheme.primary;

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
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '今日时间轴',
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

  Widget _buildStatistics(BuildContext context, int busyHours, int freeHours) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _buildStatBox(
          context,
          label: '忙碌时段',
          value: '$busyHours',
          unit: '小时',
          color: colorScheme.primary,
          bgColor: colorScheme.primary.withValues(alpha: 0.12),
        ),
        const SizedBox(width: AppConstants.spacingM),
        _buildStatBox(
          context,
          label: '空闲时段',
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
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

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

  Widget _buildEventItem(BuildContext context, ScheduleEventData event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = colorScheme.primary;

    String timeRange = '';
    try {
      final start = DateTime.parse(event.startTime).toLocal();
      final end = DateTime.parse(event.endTime).toLocal();
      timeRange = '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}';
    } catch (_) {
      timeRange = '${event.startTime} - ${event.endTime}';
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
            child: const Icon(
              Icons.event_available,
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
                  event.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
                  ),
                ),
                Text(
                  timeRange,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleEventData {
  final String title;
  final String startTime;
  final String endTime;

  ScheduleEventData({
    required this.title,
    required this.startTime,
    required this.endTime,
  });

  factory ScheduleEventData.fromJson(Map<String, dynamic> json) {
    return ScheduleEventData(
      title: json['title'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }
}

// Preview main function for testing
void main() {
  runApp(const ScheduleCardTestApp());
}

class ScheduleCardTestApp extends StatelessWidget {
  const ScheduleCardTestApp({super.key});

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
        appBar: AppBar(title: const Text('SCHEDULE 卡片展示'), centerTitle: true),
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ScheduleCard(
                title: "高效工作日规划",
                timeDescription: "今天的主要目标是攻克核心模块，注意劳逸结合",
                eventList: [
                  ScheduleEventData(
                    title: "深度工作 - 核心功能开发",
                    startTime: "2024-03-15T09:30:00.000Z",
                    endTime: "2024-03-15T11:30:00.000Z",
                  ),
                  ScheduleEventData(
                    title: "午休与阅读",
                    startTime: "2024-03-15T12:00:00.000Z",
                    endTime: "2024-03-15T13:30:00.000Z",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
