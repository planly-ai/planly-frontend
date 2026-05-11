import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:isar_community/isar.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/app/services/api/planly_api_client.dart';
import 'package:planly_ai/main.dart';
import 'package:uuid/uuid.dart';

class SyncService {
  static final StreamController<void> _queueChangeController =
      StreamController<void>.broadcast();
  static const String _timeZone = 'Asia/Shanghai';
  static final Uuid _uuid = Uuid();

  static Stream<void> get queueChanges => _queueChangeController.stream;

  Future<void> enqueueTask(Tasks task, SyncAction action) async {
    await _enqueue(
      entityType: SyncEntityType.task,
      entityUuid: task.uuidv7,
      action: action,
      payload: _taskPayload(task),
    );
    _notifyQueueChanged();
  }

  Future<void> enqueueEvent(Todos todo, SyncAction action) async {
    await todo.task.load();
    await _enqueue(
      entityType: SyncEntityType.event,
      entityUuid: todo.uuidv7,
      action: action,
      payload: _eventPayload(todo),
    );
    _notifyQueueChanged();
  }

  Future<int> pendingCount() async {
    return await isar.syncQueueItems.count();
  }

  Future<bool> syncPending({bool force = false}) async {
    if (!settings.isLoggedIn) {
      debugPrint('[Sync] Skipped because user is not logged in');
      return false;
    }

    final allItems = await isar.syncQueueItems
        .where()
        .sortByCreatedAt()
        .findAll();
    final items = force ? allItems : allItems.where(_isReadyForRetry).toList();
    if (items.isEmpty) return true;

    final body = {
      'requestId':
          'sync-${DateFormat('yyyy-MM-dd').format(DateTime.now())}-${_uuid.v7()}',
      'tasks': items
          .where((item) => item.entityType == SyncEntityType.task)
          .map(_requestPayload)
          .toList(),
      'events': items
          .where((item) => item.entityType == SyncEntityType.event)
          .map(_requestPayload)
          .toList(),
    };

    try {
      final response = await PlanlyApiClient.instance.dio.post(
        '/api/v1.1/sync',
        data: body,
      );

      final success =
          response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          (response.data is! Map ||
              response.data['code'] == null ||
              response.data['code'] == 200);

      if (!success) {
        await _markFailed(items, 'Unexpected sync response: ${response.data}');
        return false;
      }

      return await _applyItemResults(items, response.data);
    } catch (e) {
      final message = e is DioException
          ? e.message ?? e.toString()
          : e.toString();
      await _markFailed(items, message);
      return false;
    }
  }

  void _notifyQueueChanged() {
    if (!_queueChangeController.isClosed) {
      _queueChangeController.add(null);
    }
  }

  bool _isReadyForRetry(SyncQueueItem item) {
    if (item.lastError == null || item.lastError!.isEmpty) return true;

    final cooldown = _retryCooldown(item.attemptCount);
    return DateTime.now().difference(item.updatedAt) >= cooldown;
  }

  Duration _retryCooldown(int attemptCount) {
    final effectiveAttempt = attemptCount.clamp(0, 10);
    final seconds = 30 * (1 << effectiveAttempt);
    return Duration(seconds: seconds > 1800 ? 1800 : seconds);
  }

  Future<void> _enqueue({
    required SyncEntityType entityType,
    required String entityUuid,
    required SyncAction action,
    required Map<String, dynamic> payload,
  }) async {
    if (entityUuid.trim().isEmpty) return;

    final existing = await isar.syncQueueItems
        .filter()
        .entityTypeEqualTo(entityType)
        .entityUuidEqualTo(entityUuid)
        .findFirst();

    final now = DateTime.now();

    await isar.writeTxn(() async {
      if (existing == null) {
        await isar.syncQueueItems.put(
          SyncQueueItem(
            entityType: entityType,
            entityUuid: entityUuid,
            action: action,
            payloadJson: jsonEncode(payload),
            createdAt: now,
            updatedAt: now,
          ),
        );
        return;
      }

      if (existing.action == SyncAction.create && action == SyncAction.delete) {
        await isar.syncQueueItems.delete(existing.id);
        return;
      }

      existing.action = existing.action == SyncAction.create
          ? SyncAction.create
          : action;
      existing.payloadJson = jsonEncode(payload);
      existing.updatedAt = now;
      existing.lastError = null;
      await isar.syncQueueItems.put(existing);
    });
  }

  Future<void> _markFailed(List<SyncQueueItem> items, String error) async {
    final now = DateTime.now();
    await isar.writeTxn(() async {
      for (final item in items) {
        item.attemptCount += 1;
        item.lastError = error;
        item.updatedAt = now;
      }
      await isar.syncQueueItems.putAll(items);
    });
    debugPrint('[Sync] Failed: $error');
  }

  Future<bool> _applyItemResults(
    List<SyncQueueItem> queuedItems,
    dynamic responseData,
  ) async {
    final data = _asMap(responseData)?['data'];
    final typeResults = _asMap(data)?['typeResults'];
    if (typeResults is! List) {
      await _markFailed(queuedItems, 'Missing sync item results');
      return false;
    }

    final successfulUuids = <String>{};
    final failedErrors = <String, String>{};

    for (final typeResult in typeResults) {
      final typeResultMap = _asMap(typeResult);
      final items = typeResultMap?['items'];
      if (items is! List) continue;

      for (final result in items) {
        final resultMap = _asMap(result);
        final uuid = resultMap?['uuid'];
        if (uuid is! String || uuid.isEmpty) continue;

        if (resultMap?['success'] == true) {
          successfulUuids.add(uuid);
        } else {
          final errorMessage = resultMap?['errorMessage'];
          failedErrors[uuid] = errorMessage is String && errorMessage.isNotEmpty
              ? errorMessage
              : 'Sync item failed';
        }
      }
    }

    final now = DateTime.now();
    final idsToDelete = <int>[];
    final failedItems = <SyncQueueItem>[];

    for (final item in queuedItems) {
      if (successfulUuids.contains(item.entityUuid)) {
        idsToDelete.add(item.id);
        continue;
      }

      item.attemptCount += 1;
      item.updatedAt = now;
      item.lastError =
          failedErrors[item.entityUuid] ?? 'No sync result returned';
      failedItems.add(item);
    }

    await isar.writeTxn(() async {
      if (idsToDelete.isNotEmpty) {
        await isar.syncQueueItems.deleteAll(idsToDelete);
      }
      if (failedItems.isNotEmpty) {
        await isar.syncQueueItems.putAll(failedItems);
      }
    });

    return failedItems.isEmpty;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Map<String, dynamic> _requestPayload(SyncQueueItem item) {
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
    payload['action'] = _actionName(item.action);
    return payload;
  }

  Map<String, dynamic> _taskPayload(Tasks task) {
    return {
      'uuid': task.uuidv7,
      'taskType': 'TASK',
      'title': task.title,
      'description': task.description,
      'status': task.archive ? 'ARCHIVED' : 'UNSTARTED',
      'priority': 2,
      'deadline': _formatDateTime(task.taskEndTime),
      'estimatedDuration': 0,
      'category': task.category.name,
      'parentUuid': null,
    };
  }

  Map<String, dynamic> _eventPayload(Todos todo) {
    return {
      'uuid': todo.uuidv7,
      'title': todo.name,
      'startTime': _formatDateTime(todo.todoStartTime),
      'endTime': _formatDateTime(todo.todoCompletedTime),
      'timeZone': _timeZone,
      'taskUuid': todo.task.value?.uuidv7,
    };
  }

  String _actionName(SyncAction action) {
    switch (action) {
      case SyncAction.create:
        return 'CREATE';
      case SyncAction.update:
        return 'UPDATE';
      case SyncAction.delete:
        return 'DELETE';
    }
  }

  String? _formatDateTime(DateTime? value) {
    if (value == null) return null;
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(value.toLocal());
  }
}
