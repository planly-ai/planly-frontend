import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

class AlertCard extends StatelessWidget {
  final String title;
  final String alertTime;
  final String message;
  final String repeatStrategy;
  final VoidCallback? onAction;

  const AlertCard({
    super.key,
    required this.title,
    required this.alertTime,
    required this.message,
    required this.repeatStrategy,
    this.onAction,
  });

  factory AlertCard.fromJson(Map<String, dynamic> json) {
    return AlertCard(
      title: json['title'] ?? '',
      alertTime: json['alertTime'] ?? '',
      message: json['message'] ?? '',
      repeatStrategy: json['repeatStrategy'] ?? 'ONCE',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String formattedTime = alertTime;
    try {
      final dateTime = DateTime.parse(alertTime).toLocal();
      formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } catch (_) {}

    return Card(
      elevation: AppConstants.elevationLow,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingXS),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusSmall),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    size: AppConstants.iconSizeMedium,
                    color: colorScheme.primary,
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
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 16),
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '提醒时间 $formattedTime',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 12),
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusSmall),
                  ),
                  child: Text(
                    '重复 $repeatStrategy',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('已完成'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Preview main function for testing
void main() {
  runApp(const AlertCardTestApp());
}

class AlertCardTestApp extends StatelessWidget {
  const AlertCardTestApp({super.key});

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
        appBar: AppBar(title: const Text('ALERT 卡片展示'), centerTitle: true),
        backgroundColor: Colors.grey[100],
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              AlertCard(
                title: "喝水提醒",
                alertTime: "2024-03-15T15:00:00.000Z",
                message: "工作很久了，起来喝杯水活动一下吧！",
                repeatStrategy: "DAILY",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
