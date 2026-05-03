import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/app/data/repositories/task_repository.dart';
import 'package:planly_ai/app/data/repositories/todo_repository.dart';
import 'package:planly_ai/app/services/notification_service.dart';
import 'package:planly_ai/app/services/sync_service.dart';
import 'package:planly_ai/app/utils/show_snack_bar.dart';

class TaskService {
  final TaskRepository _taskRepo;
  final TodoRepository _todoRepo;
  final NotificationService _notificationService;
  final SyncService _syncService = SyncService();

  TaskService({
    required TaskRepository taskRepo,
    required TodoRepository todoRepo,
    required NotificationService notificationService,
  }) : _taskRepo = taskRepo,
       _todoRepo = todoRepo,
       _notificationService = notificationService;

  // ==================== CREATE ====================

  Future<Tasks?> createTask({
    required String title,
    required String description,
    DateTime? taskEndTime,
    required TaskCategory category,
    required Color color,
    required int currentTaskCount,
  }) async {
    if (await _taskRepo.existsByTitle(title)) {
      showSnackBar('duplicateCategory'.tr, isError: true);
      return null;
    }

    final task = await _taskRepo.create(
      title: title,
      description: description,
      taskEndTime: taskEndTime,
      category: category,
      color: color,
      index: currentTaskCount,
    );

    showSnackBar('createCategory'.tr);
    await _syncService.enqueueTask(task, SyncAction.create);
    return task;
  }

  // ==================== UPDATE ====================

  Future<void> updateTask({
    required Tasks task,
    required String title,
    required String description,
    DateTime? taskEndTime,
    required TaskCategory category,
    required Color color,
  }) async {
    await _taskRepo.updateFields(
      task: task,
      title: title,
      description: description,
      taskEndTime: taskEndTime,
      category: category,
      color: color,
    );

    showSnackBar('editCategory'.tr);
    await _syncService.enqueueTask(task, SyncAction.update);
  }

  Future<void> archiveTasks(List<Tasks> tasks) async {
    if (tasks.isEmpty) return;

    final tasksCopy = List<Tasks>.from(tasks);

    final allTodos = <Todos>[];
    for (final task in tasksCopy) {
      final todos = await _todoRepo.getByTaskId(task.id);
      allTodos.addAll(todos);
    }

    await _notificationService.cancelForTask(allTodos);
    await _taskRepo.updateArchiveStatusBatch(tasksCopy, true);
    for (final task in tasksCopy) {
      await _syncService.enqueueTask(task, SyncAction.update);
    }

    showSnackBar('categoryArchive'.tr);
  }

  Future<void> unarchiveTasks(List<Tasks> tasks) async {
    if (tasks.isEmpty) return;

    final tasksCopy = List<Tasks>.from(tasks);

    final allTodos = <Todos>[];
    for (final task in tasksCopy) {
      final todos = await _todoRepo.getByTaskId(task.id);
      allTodos.addAll(todos);
    }
    await _notificationService.scheduleForTask(allTodos);
    await _taskRepo.updateArchiveStatusBatch(tasksCopy, false);
    for (final task in tasksCopy) {
      await _syncService.enqueueTask(task, SyncAction.update);
    }

    showSnackBar('noCategoryArchive'.tr);
  }

  // ==================== DELETE ====================

  Future<void> deleteTasks(List<Tasks> tasks) async {
    if (tasks.isEmpty) return;

    final tasksCopy = List<Tasks>.from(tasks);

    for (final task in tasksCopy) {
      final todos = await _todoRepo.getByTaskId(task.id);
      await _notificationService.cancelForTask(todos);
      await _syncService.enqueueTask(task, SyncAction.delete);
      await _deleteAllTodosForTask(todos);
      await _taskRepo.delete(task);
    }

    showSnackBar('categoryDelete'.tr);
  }

  Future<void> _deleteAllTodosForTask(List<Todos> todos) async {
    if (todos.isEmpty) return;

    final todosCopy = List<Todos>.from(todos);
    final allIds = <int>{};

    for (final root in todosCopy) {
      final subtreeIds = await _collectSubtreeIds(root);
      allIds.addAll(subtreeIds);
    }

    if (allIds.isNotEmpty) {
      for (final id in allIds) {
        final todo = await _todoRepo.getById(id);
        if (todo != null) {
          await _syncService.enqueueEvent(todo, SyncAction.delete);
        }
      }
      await _todoRepo.deleteBatch(allIds);
    }
  }

  Future<Set<int>> _collectSubtreeIds(Todos root) async {
    final ids = <int>{};
    final stack = <Todos>[root];

    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      if (!ids.add(node.id)) continue;

      final children = await _todoRepo.getChildren(node.id);
      for (final child in children) {
        if (!ids.contains(child.id)) {
          stack.add(child);
        }
      }
    }

    return ids;
  }

  // ==================== REORDER ====================

  Future<void> reorderTasks({
    required List<Tasks> allTasks,
    required List<Tasks> filteredTasks,
  }) async {
    if (filteredTasks.isEmpty) return;

    final filteredIds = filteredTasks.map((t) => t.id).toSet();
    int position = 0;

    for (
      int i = 0;
      i < allTasks.length && position < filteredTasks.length;
      i++
    ) {
      if (filteredIds.contains(allTasks[i].id)) {
        allTasks[i] = filteredTasks[position++];
      }
    }

    await _taskRepo.updateIndexes(allTasks);
  }

  // ==================== FILTERS ====================

  List<Tasks> filterTasks({
    required List<Tasks> tasks,
    required bool archived,
    String searchQuery = '',
    TaskCategory? category,
  }) {
    final query = searchQuery.trim().toLowerCase();

    return tasks.where((task) {
      if (task.archive != archived) return false;
      if (category != null && task.category != category) return false;
      if (query.isEmpty) return true;

      final titleMatch = task.title.toLowerCase().contains(query);
      final descMatch = task.description.toLowerCase().contains(query);

      return titleMatch || descMatch;
    }).toList();
  }
}
