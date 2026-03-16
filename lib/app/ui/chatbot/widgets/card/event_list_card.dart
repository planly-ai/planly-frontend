import 'package:flutter/material.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

class EventListCard extends StatelessWidget {
  final String title;
  final List<Map<String, String>> eventCards;

  const EventListCard({
    super.key,
    required this.title,
    required this.eventCards,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                    Icons.event_note,
                    size: AppConstants.iconSizeMedium,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            ...eventCards.map((e) => _buildEventItem(context, e)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(
      BuildContext context, Map<String, String> e) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
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
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event,
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
                  e['title'] ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 15),
                  ),
                ),
                if ((e['startTime'] ?? '').isNotEmpty &&
                    (e['endTime'] ?? '').isNotEmpty)
                  Text(
                    '${e['startTime']} - ${e['endTime']}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 13),
                    ),
                  ),
                if ((e['description'] ?? '').isNotEmpty)
                  Text(
                    e['description'] ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 12),
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

// Preview main function for testing
void main() {
  runApp(const EventListCardTestApp());
}

class EventListCardTestApp extends StatelessWidget {
  const EventListCardTestApp({super.key});

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
        appBar: AppBar(title: const Text('EVENT_LIST 卡片展示'), centerTitle: true),
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: const [
              EventListCard(
                title: "今日待办事项",
                eventCards: [
                  {
                    "title": "晨会",
                    "startTime": "2024-03-15 09:00",
                    "endTime": "2024-03-15 09:30",
                    "description": "全员同步"
                  },
                  {
                    "title": "代码评审",
                    "startTime": "2024-03-15 14:00",
                    "endTime": "2024-03-15 15:00",
                    "description": "Review PR #1024"
                  }
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
