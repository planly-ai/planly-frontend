import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      color: colorScheme.primaryContainer.withValues(alpha: 0.26),
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
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusSmall,
                    ),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            16,
                          ),
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'alert_time_label'.trParams({'time': formattedTime}),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            12,
                          ),
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
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusSmall,
                    ),
                  ),
                  child: Text(
                    'repeat_label'.trParams({'strategy': repeatStrategy}),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        11,
                      ),
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      'ready'.tr,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          14,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.borderRadiusMedium,
                        ),
                      ),
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
        appBar: AppBar(title: Text('alert_card_preview'.tr), centerTitle: true),
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
