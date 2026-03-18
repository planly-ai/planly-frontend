import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String? description;
  final String? taskEnum;
  final double isCompleted;
  final int spentTime;
  final VoidCallback? onConfirm;

  const TaskCard({
    super.key,
    required this.title,
    this.description,
    this.taskEnum,
    required this.isCompleted,
    required this.spentTime,
    this.onConfirm,
  });

  factory TaskCard.fromJson(Map<String, dynamic> json) {
    return TaskCard(
      title: json['title'] ?? '',
      description: json['description'],
      taskEnum: json['taskEnum'],
      isCompleted: (json['isCompleted'] ?? 0).toDouble(),
      spentTime: json['spentTime'] ?? 0,
    );
  }

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
            _buildIntegratedHeader(context),
            const SizedBox(height: AppConstants.spacingM),
            if (description != null && description!.isNotEmpty) ...[
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
            ],
            _buildDetailRow(
              context,
              icon: Icons.category_outlined,
              label: 'task_type_label'.trParams({'type': taskEnum ?? 'unclassified'.tr}),
            ),
            const SizedBox(height: AppConstants.spacingS),
            _buildDetailRow(
              context,
              icon: Icons.timer_outlined,
              label: 'time_spent_label'.trParams({'minutes': spentTime.toString()}),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildProgressSection(context, isCompleted),
            const SizedBox(height: AppConstants.spacingL),
            _buildConfirmButton(context),
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
            Icons.task_alt,
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'details'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppConstants.iconSizeSmall,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, double progress) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'current_progress'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingXS),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: onConfirm,
        icon: const Icon(Icons.check, size: 18),
        label: Text(
          'confirm_update'.tr,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
        ),
      ),
    );
  }
}

// Preview main function for testing
void main() {
  runApp(const TaskCardTestApp());
}

class TaskCardTestApp extends StatelessWidget {
  const TaskCardTestApp({super.key});

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
        appBar: AppBar(title: Text('task_card_preview'.tr), centerTitle: true),
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TaskCard(
                title: '编写 API 文档',
                description: '完成 Sync 接口的对接文档编写',
                taskEnum: 'WORK',
                isCompleted: 0.5,
                spentTime: 60,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
