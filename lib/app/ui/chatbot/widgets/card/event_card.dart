import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

class EventCard extends StatefulWidget {
  final String title;
  final String startTime;
  final String endTime;
  final String? description;
  final VoidCallback? onConfirm;

  const EventCard({
    super.key,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.onConfirm,
  });

  factory EventCard.fromJson(Map<String, dynamic> json) {
    return EventCard(
      title: json['title'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      description: json['description'],
    );
  }

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  String _formatTimeRange(String start, String end) {
    try {
      final startDate = DateTime.parse(start).toLocal();
      final endDate = DateTime.parse(end).toLocal();
      final formatter = DateFormat('yyyy-MM-dd HH:mm');
      return '${formatter.format(startDate)} - ${DateFormat('HH:mm').format(endDate)}';
    } catch (e) {
      return '$start - $end';
    }
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
            Text(
              widget.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildDetailRow(
              context,
              icon: Icons.access_time,
              label: _formatTimeRange(widget.startTime, widget.endTime),
            ),
            if (widget.description != null && widget.description!.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingS),
              _buildDetailRow(
                context,
                icon: Icons.description_outlined,
                label: widget.description!,
              ),
            ],
            const SizedBox(height: AppConstants.spacingXL),
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
      constraints: const BoxConstraints(minHeight: 48),
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
          if (trailing != null)
            Transform.scale(
              scale: 0.8,
              child: trailing,
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: widget.onConfirm,
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text('确认添加'),
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
  runApp(const EventCardTestApp());
}

class EventCardTestApp extends StatelessWidget {
  const EventCardTestApp({super.key});

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
        appBar: AppBar(title: const Text('EVENT 卡片展示'), centerTitle: true),
        backgroundColor: Colors.grey[100],
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              EventCard(
                title: "项目周会",
                startTime: "2024-03-15T10:00:00.000Z",
                endTime: "2024-03-15T11:30:00.000Z",
                description: "讨论下周开发计划与任务分配",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
