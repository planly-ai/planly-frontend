import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/controller/todo_controller.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/app/data/repositories/task_repository.dart';
import 'package:planly_ai/app/data/repositories/todo_repository.dart';
import 'package:planly_ai/app/services/notification_service.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';
import 'package:planly_ai/app/utils/show_snack_bar.dart';
import 'package:planly_ai/main.dart';

class TaskProposalCard extends StatefulWidget {
  final TaskProposalData data;
  final ChatMessage message;

  const TaskProposalCard({
    super.key,
    required this.data,
    required this.message,
  });

  factory TaskProposalCard.fromJson(
    Map<String, dynamic> json, {
    required ChatMessage message,
  }) {
    return TaskProposalCard(
      data: TaskProposalData.fromJson(json),
      message: message,
    );
  }

  @override
  State<TaskProposalCard> createState() => _TaskProposalCardState();
}

class _TaskProposalCardState extends State<TaskProposalCard> {
  final _taskRepository = TaskRepository();
  final _todoRepository = TodoRepository();
  final _notificationService = NotificationService();

  late bool _isAdded;
  bool _isAdding = false;
  final _expandedPhaseIndexes = <int>{};

  @override
  void initState() {
    super.initState();
    _isAdded = widget.data.isActionDone;
  }

  Future<void> _handleAddPlan() async {
    if (_isAdded || _isAdding) return;

    setState(() {
      _isAdding = true;
    });

    try {
      final taskColor = Theme.of(context).colorScheme.primary;
      final allTasks = await _taskRepository.getAll();
      final rootTask = await _taskRepository.create(
        title: widget.data.title,
        description: widget.data.description,
        category: widget.data.category,
        color: taskColor,
        index: allTasks.length,
      );

      var nextIndex = (await _todoRepository.getAll()).length;
      for (final phase in widget.data.subTasks) {
        final phaseTodo = await _todoRepository.create(
          name: phase.title,
          description: phase.description,
          startTime: null,
          completedTime: phase.deadline,
          fix: false,
          priority: phase.priority,
          tags: const [],
          index: nextIndex++,
          task: rootTask,
        );

        for (final event in phase.events) {
          final eventTodo = await _todoRepository.create(
            name: event.title,
            description: event.description,
            startTime: event.startTime,
            completedTime: event.endTime,
            fix: false,
            priority: event.priority,
            tags: const [],
            index: nextIndex++,
            task: rootTask,
          );

          await isar.writeTxn(() async {
            eventTodo.parent.value = phaseTodo;
            await isar.todos.put(eventTodo);
            await eventTodo.parent.save();
            await eventTodo.task.save();
          });

          if (eventTodo.todoStartTime != null) {
            await _notificationService.scheduleForTodo(eventTodo);
          }
        }
      }

      await isar.writeTxn(() async {
        final data = jsonDecode(widget.message.cardContent ?? '{}');
        if (data is Map<String, dynamic>) {
          data['isActionDone'] = true;
          widget.message.cardContent = jsonEncode(data);
          await isar.chatMessages.put(widget.message);
        }
      });

      if (Get.isRegistered<TodoController>()) {
        final controller = Get.find<TodoController>();
        controller.tasks.assignAll(await _taskRepository.getAll());
        controller.todos.assignAll(await _todoRepository.getAll());
      }

      if (mounted) {
        setState(() {
          _isAdded = true;
        });
      }
      showSnackBar('taskProposalAdded'.tr);
    } catch (e) {
      debugPrint('Error adding task proposal: $e');
      showSnackBar('taskProposalAddFailed'.tr, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final data = widget.data;

    return Card(
      elevation: AppConstants.elevationLow,
      color: colorScheme.primaryContainer.withValues(alpha: 0.26),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            if (data.description.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingS),
              Text(
                data.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: AppConstants.spacingM),
            _buildSummaryRow(context),
            const SizedBox(height: AppConstants.spacingS),
            ...data.subTasks.asMap().entries.map(
              (entry) => _buildPhaseItem(context, entry.key, entry.value),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildConfirmButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingXS),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Icon(
            Icons.account_tree_outlined,
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
                widget.data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                ),
              ),
              Text(
                'taskProposalSubtitle'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context) {
    final data = widget.data;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetric(
                context,
                Icons.flag_outlined,
                data.deadline == null
                    ? 'noDeadline'.tr
                    : DateFormat('yyyy-MM-dd').format(data.deadline!),
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
            Expanded(
              child: _buildMetric(
                context,
                Icons.layers_outlined,
                'taskProposalPhaseCount'.trParams({
                  'count': data.subTasks.length.toString(),
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        Row(
          children: [
            Expanded(
              child: _buildMetric(
                context,
                Icons.event_note_outlined,
                'taskProposalEventCount'.trParams({
                  'count': data.totalEventCount.toString(),
                }),
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
            Expanded(
              child: _buildMetric(
                context,
                Icons.folder_outlined,
                data.category.labelKey.tr,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetric(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppConstants.spacingXS),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 11),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseItem(
    BuildContext context,
    int phaseIndex,
    TaskProposalPhase phase,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpanded = _expandedPhaseIndexes.contains(phaseIndex);
    final previewEvents = isExpanded
        ? phase.events
        : phase.events.take(2).toList();
    final hiddenCount = phase.events.length - previewEvents.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  phase.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      13,
                    ),
                  ),
                ),
              ),
              Text(
                'taskProposalEventCount'.trParams({
                  'count': phase.events.length.toString(),
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 11),
                ),
              ),
            ],
          ),
          if (phase.description.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingXS),
            Text(
              phase.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 11),
                height: 1.3,
              ),
            ),
          ],
          if (previewEvents.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingS),
            ...previewEvents.map((event) => _buildEventPreview(context, event)),
            if (hiddenCount > 0)
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedPhaseIndexes.add(phaseIndex);
                  });
                },
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppConstants.spacingXS),
                  child: Text(
                    'taskProposalMoreEvents'.trParams({
                      'count': hiddenCount.toString(),
                    }),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        11,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else if (isExpanded && phase.events.length > 2)
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedPhaseIndexes.remove(phaseIndex);
                  });
                },
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppConstants.spacingXS),
                  child: Text(
                    'taskProposalCollapseEvents'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        11,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventPreview(BuildContext context, TaskProposalEvent event) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Icon(
              Icons.circle,
              size: 5,
              color: colorScheme.primary.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(
              '${event.formattedDate}  ${event.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 11),
              ),
            ),
          ),
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
        onPressed: _isAdded || _isAdding ? null : _handleAddPlan,
        icon: _isAdding
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_isAdded ? Icons.check : Icons.add, size: 18),
        label: Text(
          _isAdded ? 'taskProposalAddedButton'.tr : 'taskProposalAddButton'.tr,
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

class TaskProposalData {
  final String title;
  final String description;
  final DateTime? deadline;
  final TaskCategory category;
  final Priority priority;
  final List<TaskProposalPhase> subTasks;
  final bool isActionDone;

  const TaskProposalData({
    required this.title,
    required this.description,
    required this.deadline,
    required this.category,
    required this.priority,
    required this.subTasks,
    required this.isActionDone,
  });

  int get totalEventCount {
    return subTasks.fold<int>(0, (sum, phase) => sum + phase.events.length);
  }

  factory TaskProposalData.fromJson(Map<String, dynamic> json) {
    final subTasks = (json['subTasks'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => TaskProposalPhase.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    return TaskProposalData(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      deadline: _parseDateTime(json['deadline']),
      category: _parseTaskCategory(json['category']),
      priority: _parsePriority(json['priority']),
      subTasks: subTasks,
      isActionDone: json['isActionDone'] == true,
    );
  }
}

class TaskProposalPhase {
  final String title;
  final String description;
  final DateTime? deadline;
  final Priority priority;
  final List<TaskProposalEvent> events;

  const TaskProposalPhase({
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    required this.events,
  });

  factory TaskProposalPhase.fromJson(Map<String, dynamic> json) {
    final events = (json['events'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => TaskProposalEvent.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    return TaskProposalPhase(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      deadline: _parseDateTime(json['deadline']),
      priority: _parsePriority(json['priority']),
      events: events,
    );
  }
}

class TaskProposalEvent {
  final String title;
  final String description;
  final DateTime? startTime;
  final DateTime? endTime;
  final Priority priority;

  const TaskProposalEvent({
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.priority,
  });

  String get formattedDate {
    final start = startTime;
    if (start == null) return '';
    return DateFormat('MM-dd HH:mm').format(start);
  }

  factory TaskProposalEvent.fromJson(Map<String, dynamic> json) {
    return TaskProposalEvent(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      priority: _parsePriority(json['priority']),
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  return DateTime.tryParse(value.toString())?.toLocal();
}

TaskCategory _parseTaskCategory(dynamic value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return TaskCategory.uncategorized;

  final normalized = raw.contains('_') ? _snakeToLowerCamel(raw) : raw;
  return TaskCategory.values.firstWhere(
    (category) => category.name.toLowerCase() == normalized.toLowerCase(),
    orElse: () => TaskCategory.uncategorized,
  );
}

Priority _parsePriority(dynamic value) {
  if (value is num) {
    if (value >= 3) return Priority.high;
    if (value == 2) return Priority.medium;
    if (value == 1) return Priority.low;
    return Priority.none;
  }

  switch ((value ?? '').toString().toUpperCase()) {
    case 'URGENT':
    case 'HIGH':
      return Priority.high;
    case 'MEDIUM':
      return Priority.medium;
    case 'LOW':
      return Priority.low;
    default:
      return Priority.none;
  }
}

String _snakeToLowerCamel(String value) {
  final parts = value.toLowerCase().split('_').where((part) => part.isNotEmpty);
  if (parts.isEmpty) return value;

  final buffer = StringBuffer(parts.first);
  for (final part in parts.skip(1)) {
    buffer.write(part[0].toUpperCase());
    if (part.length > 1) buffer.write(part.substring(1));
  }
  return buffer.toString();
}
