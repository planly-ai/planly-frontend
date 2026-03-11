import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

class AiSubTask {
  final String title;
  final int durationMinutes;
  final bool isCompleted;

  const AiSubTask({
    required this.title,
    required this.durationMinutes,
    this.isCompleted = false,
  });

  AiSubTask copyWith({bool? isCompleted}) {
    return AiSubTask(
      title: title,
      durationMinutes: durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ScheduleBreakdownCard extends StatefulWidget {
  final String title;
  final List<AiSubTask> subTasks;
  final VoidCallback? onConfirm;

  const ScheduleBreakdownCard({
    super.key,
    required this.title,
    required this.subTasks,
    this.onConfirm,
  });

  @override
  State<ScheduleBreakdownCard> createState() => _ScheduleBreakdownCardState();
}

class _ScheduleBreakdownCardState extends State<ScheduleBreakdownCard> {
  late List<AiSubTask> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.subTasks);
  }

  @override
  Widget build(BuildContext context) {
    int totalMinutes = _tasks.fold(
      0,
      (sum, item) => sum + item.durationMinutes,
    );
    int completedMinutes = _tasks
        .where((t) => t.isCompleted)
        .fold(0, (sum, item) => sum + item.durationMinutes);

    return Card(
      elevation: AppConstants.elevationLow,
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

            const SizedBox(height: AppConstants.spacingM),

            ..._tasks.asMap().entries.map((entry) {
              return _buildTaskItem(context, entry.value, entry.key);
            }),
            const SizedBox(height: AppConstants.spacingM),

            // Progress Section
            _buildProgressSection(context, completedMinutes, totalMinutes),

            const SizedBox(height: AppConstants.spacingL),

            // Confirm Button
            _buildConfirmButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegratedHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = colorScheme.primary; // Subtask primary color

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Icon(
            Icons.auto_awesome,
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
                widget.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'subtask_ai_suggestion'.tr,
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

  Widget _buildTaskItem(BuildContext context, AiSubTask task, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                setState(() {
                  _tasks[index] = task.copyWith(isCompleted: value ?? false);
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: task.isCompleted
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      14,
                    ),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.durationMinutes} ${'unit_minute'.tr}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
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
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, int completed, int total) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'total_progress'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              '${completed} / ${total} ${'unit_minute'.tr}',
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
            value: total > 0 ? completed / total : 0,
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            minHeight: 4,
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
        onPressed: widget.onConfirm,
        icon: const Icon(Icons.check, size: 18),
        label: Text('confirm_add'.tr),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          ),
        ),
      ),
    );
  }
}

// Preview main function for testing
void main() {
  runApp(const ScheduleBreakdownTestApp());
}

class ScheduleBreakdownTestApp extends StatelessWidget {
  const ScheduleBreakdownTestApp({super.key});

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
        appBar: AppBar(title: const Text('子任务清单卡片展示'), centerTitle: true),
        backgroundColor: Colors.grey[100],
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              ScheduleBreakdownCard(
                title: '准备季度总结报告',
                subTasks: [
                  AiSubTask(title: '收集本季度各项目数据', durationMinutes: 30),
                  AiSubTask(title: '分析数据并制作图表', durationMinutes: 45),
                  AiSubTask(title: '撰写报告初稿', durationMinutes: 60),
                  AiSubTask(title: '审核并修改报告内容', durationMinutes: 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
