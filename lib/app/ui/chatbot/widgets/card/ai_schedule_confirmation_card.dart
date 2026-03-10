import 'package:flutter/material.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

class ScheduleConfirmationCard extends StatefulWidget {
  final String title;
  final String time;
  final String location;
  final String reminder;
  final VoidCallback? onConfirm;

  const ScheduleConfirmationCard({
    super.key,
    required this.title,
    required this.time,
    required this.location,
    required this.reminder,
    this.onConfirm,
  });

  @override
  State<ScheduleConfirmationCard> createState() => _ScheduleConfirmationCardState();
}

class _ScheduleConfirmationCardState extends State<ScheduleConfirmationCard> {
  bool _isReminderEnabled = true;

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
            // Integrated Header: Icon + Title (StatsCard Style)
            _buildIntegratedHeader(context),
            
            const SizedBox(height: AppConstants.spacingM),

            // Title Area
            Text(
              widget.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),

            // Detail Rows
            _buildDetailRow(
              context,
              icon: Icons.access_time,
              label: widget.time,
            ),
            const SizedBox(height: AppConstants.spacingS),
            _buildDetailRow(
              context,
              icon: Icons.location_on_outlined,
              label: widget.location,
            ),
            const SizedBox(height: AppConstants.spacingS),
            _buildDetailRow(
              context,
              icon: Icons.notifications_none,
              label: widget.reminder,
              trailing: Switch(
                value: _isReminderEnabled,
                onChanged: (value) {
                  setState(() {
                    _isReminderEnabled = value;
                  });
                },
                activeColor: const Color(0xFF9C27B0),
              ),
            ),

            const SizedBox(height: AppConstants.spacingXL),

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
    final color = Colors.green; // Confirmation primary color

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Icon(
            Icons.calendar_today,
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
                '日程确认',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '请核对以下任务详情',
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

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    Widget? trailing,
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
      child: Row(
        children: [
          Icon(
            icon,
            size: AppConstants.iconSizeMedium,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: widget.onConfirm,
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text('确认添加'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green,
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
  runApp(const ScheduleConfirmationTestApp());
}

class ScheduleConfirmationTestApp extends StatelessWidget {
  const ScheduleConfirmationTestApp({super.key});

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
        appBar: AppBar(title: const Text('日程确认卡片展示'), centerTitle: true),
        backgroundColor: Colors.grey[100],
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              ScheduleConfirmationCard(
                title: "季度工作汇报会议",
                time: "2026年3月10日 下午 3:00",
                location: "3楼会议室A",
                reminder: "提前 15 分钟",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
