import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/controller/todo_controller.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';
import 'package:planly_ai/main.dart';

class EventCard extends StatefulWidget {
  final String title;
  final String startTime;
  final String endTime;
  final String? description;
  final VoidCallback? onConfirm;
  final ChatMessage message;
  final bool isActionDone;

  const EventCard({
    super.key,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.message,
    this.isActionDone = false,
    this.description,
    this.onConfirm,
  });

  factory EventCard.fromJson(
    Map<String, dynamic> json, {
    required ChatMessage message,
  }) {
    return EventCard(
      title: json['title'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      description: json['description'],
      message: message,
      isActionDone: json['isActionDone'] ?? false,
    );
  }

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  late bool _isAdded;

  @override
  void initState() {
    super.initState();
    _isAdded = widget.isActionDone;
  }

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

  Future<void> _handleAddTodo() async {
    if (_isAdded) return;

    final todoController = Get.find<TodoController>();

    try {
      await todoController.addTodo(
        task: null,
        title: widget.title,
        description: widget.description ?? '',
        startTime: widget.startTime,
        time: widget.endTime,
        pinned: false,
        priority: Priority.none,
        tags: [],
      );

      // Persist the action status in the message cardContent JSON
      await isar.writeTxn(() async {
        final data = jsonDecode(widget.message.cardContent ?? '{}');
        data['isActionDone'] = true;
        widget.message.cardContent = jsonEncode(data);
        await isar.chatMessages.put(widget.message);
      });

      if (mounted) {
        setState(() {
          _isAdded = true;
        });
      }
    } catch (e) {
      debugPrint('Error adding todo from EventCard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: AppConstants.elevationLow,
      color: colorScheme.primaryContainer.withValues(alpha: 0.26),
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildDetailRow(
              context,
              icon: Icons.access_time,
              label: _formatTimeRange(widget.startTime, widget.endTime),
            ),
            if (widget.description != null &&
                widget.description!.isNotEmpty) ...[
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
                'schedule_confirmation_title'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'schedule_confirmation_subtitle'.tr,
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
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (trailing != null) Transform.scale(scale: 0.8, child: trailing),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: _isAdded ? null : _handleAddTodo,
        icon: const Icon(Icons.check, size: 18),
        label: Text(
          'confirm_add'.tr,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusMedium,
            ),
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
        appBar: AppBar(title: Text('event_card_preview'.tr), centerTitle: true),
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              EventCard(
                title: "项目周会",
                startTime: "2024-03-15T10:00:00.000Z",
                endTime: "2024-03-15T11:30:00.000Z",
                description: "讨论下周开发计划与任务分配",
                message: ChatMessage(
                  text: '',
                  createdAt: DateTime.now(),
                  sender: SenderType.bot,
                  type: MessageType.cardEvent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
