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
import 'package:planly_ai/app/services/sync_service.dart';
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
  final _syncService = SyncService();

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
        taskEndTime: widget.data.deadline,
        category: widget.data.category,
        color: taskColor,
        index: allTasks.length,
      );
      await _syncService.enqueueTask(rootTask, SyncAction.create);

      var nextIndex = (await _todoRepository.getAll()).length;
      for (final event in widget.data.events) {
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

        if (eventTodo.todoStartTime != null) {
          await _notificationService.scheduleForTodo(eventTodo);
        }
        await _syncService.enqueueEvent(eventTodo, SyncAction.create);
      }

      for (final phase in widget.data.subTasks) {
        if (phase.events.isEmpty) {
          final eventTodo = await _todoRepository.create(
            name: phase.title,
            description: phase.description,
            startTime: phase.effectiveStartTime,
            completedTime: phase.effectiveEndTime,
            fix: false,
            priority: phase.priority,
            tags: const [],
            index: nextIndex++,
            task: rootTask,
          );

          if (eventTodo.todoStartTime != null) {
            await _notificationService.scheduleForTodo(eventTodo);
          }
          await _syncService.enqueueEvent(eventTodo, SyncAction.create);
          continue;
        }

        for (final event in phase.events) {
          final eventTodo = await _todoRepository.create(
            name: event.title,
            description: event.description,
            subtask: phase.title,
            startTime: event.startTime,
            completedTime: event.endTime,
            fix: false,
            priority: event.priority,
            tags: const [],
            index: nextIndex++,
            task: rootTask,
          );

          if (eventTodo.todoStartTime != null) {
            await _notificationService.scheduleForTodo(eventTodo);
          }
          await _syncService.enqueueEvent(eventTodo, SyncAction.create);
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
    final groups = _displayGroups();

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
            _buildSummaryRow(context, groups.length),
            const SizedBox(height: AppConstants.spacingS),
            ...groups.asMap().entries.map(
              (entry) => _buildEventGroup(context, entry.key, entry.value),
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildConfirmButton(context),
          ],
        ),
      ),
    );
  }

  List<TaskProposalEventGroup> _displayGroups() {
    final groups = <TaskProposalEventGroup>[];
    final standaloneEvents = <TaskProposalEvent>[
      ...widget.data.events,
      ...widget.data.subTasks
          .where((phase) => phase.events.isEmpty)
          .map(TaskProposalEvent.fromPhase),
    ];

    if (standaloneEvents.isNotEmpty) {
      groups.add(
        TaskProposalEventGroup(
          title: 'taskProposalTodoList'.tr,
          description: '',
          events: standaloneEvents,
        ),
      );
    }

    for (final phase in widget.data.subTasks) {
      if (phase.events.isEmpty) continue;
      groups.add(
        TaskProposalEventGroup(
          title: phase.title,
          description: phase.description,
          events: phase.events,
        ),
      );
    }

    return groups;
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

  Widget _buildSummaryRow(BuildContext context, int groupCount) {
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
                  'count': groupCount.toString(),
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

  Widget _buildEventGroup(
    BuildContext context,
    int groupIndex,
    TaskProposalEventGroup group,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpanded = _expandedPhaseIndexes.contains(groupIndex);
    final previewEvents = isExpanded
        ? group.events
        : group.events.take(2).toList();
    final hiddenCount = group.events.length - previewEvents.length;

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
                  group.title,
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
                  'count': group.events.length.toString(),
                }),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 11),
                ),
              ),
            ],
          ),
          if (group.description.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingXS),
            Text(
              group.description,
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
                    _expandedPhaseIndexes.add(groupIndex);
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
            else if (isExpanded && group.events.length > 2)
              InkWell(
                onTap: () {
                  setState(() {
                    _expandedPhaseIndexes.remove(groupIndex);
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
  final List<TaskProposalEvent> events;
  final bool isActionDone;

  const TaskProposalData({
    required this.title,
    required this.description,
    required this.deadline,
    required this.category,
    required this.priority,
    required this.subTasks,
    required this.events,
    required this.isActionDone,
  });

  int get totalEventCount {
    return events.length +
        subTasks.fold<int>(
          0,
          (sum, phase) =>
              sum + (phase.events.isEmpty ? 1 : phase.events.length),
        );
  }

  factory TaskProposalData.fromJson(Map<String, dynamic> json) {
    final subTasks = (json['subTasks'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => TaskProposalPhase.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    final events = (json['events'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => TaskProposalEvent.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    return TaskProposalData(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      deadline: _parseDateTime(json['deadline']),
      category: _parseTaskCategory(json['category']),
      priority: _parsePriority(json['priority']),
      subTasks: subTasks,
      events: events,
      isActionDone: json['isActionDone'] == true,
    );
  }
}

class TaskProposalPhase {
  final String title;
  final String description;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? deadline;
  final int estimatedDuration;
  final Priority priority;
  final List<TaskProposalEvent> events;

  const TaskProposalPhase({
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.deadline,
    required this.estimatedDuration,
    required this.priority,
    required this.events,
  });

  DateTime? get effectiveEndTime {
    return endTime ?? deadline;
  }

  DateTime? get effectiveStartTime {
    if (startTime != null) return startTime;
    final end = effectiveEndTime;
    if (end == null) return null;
    if (estimatedDuration <= 0) return end;
    return end.subtract(Duration(minutes: estimatedDuration));
  }

  String get formattedDate {
    final start = effectiveStartTime;
    if (start == null) return '';
    return DateFormat('MM-dd HH:mm').format(start);
  }

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
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      deadline: _parseDateTime(json['deadline']),
      estimatedDuration: _parseInt(json['estimatedDuration']),
      priority: _parsePriority(json['priority']),
      events: events,
    );
  }
}

class TaskProposalEventGroup {
  final String title;
  final String description;
  final List<TaskProposalEvent> events;

  const TaskProposalEventGroup({
    required this.title,
    required this.description,
    required this.events,
  });
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

  factory TaskProposalEvent.fromPhase(TaskProposalPhase phase) {
    return TaskProposalEvent(
      title: phase.title,
      description: phase.description,
      startTime: phase.effectiveStartTime,
      endTime: phase.effectiveEndTime,
      priority: phase.priority,
    );
  }

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

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
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
