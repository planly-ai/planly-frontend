import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';

part 'db.g.dart';

@collection
class Settings {
  Id id = Isar.autoIncrement;
  bool onboard = false;
  String? theme = 'system';
  String timeformat = '24';
  bool materialColor = true;
  bool amoledTheme = false;
  bool? isImage = false;
  bool? screenPrivacy = false;
  String? language;
  String firstDay = 'monday';
  String calendarFormat = 'week';
  String defaultScreen = 'categories';
  int snoozeDuration = 10;
  @enumerated
  SortOption allTodosSortOption = SortOption.none;
  @enumerated
  SortOption calendarSortOption = SortOption.none;
  bool autoBackupEnabled = false;
  @enumerated
  AutoBackupFrequency autoBackupFrequency = AutoBackupFrequency.daily;
  DateTime? lastAutoBackupTime;
  int maxAutoBackups = 5;
  String? autoBackupPath;
}

enum SortOption {
  none,
  alphaAsc,
  alphaDesc,
  dateAsc,
  dateDesc,
  dateNotifAsc,
  dateNotifDesc,
  priorityAsc,
  priorityDesc,
  random,
}

enum AutoBackupFrequency { daily, weekly, monthly }

@collection
class Tasks {
  Id id;
  String title;
  String description;
  int taskColor;
  bool archive;
  int? index;
  @enumerated
  SortOption sortOption = SortOption.none;

  @Backlink(to: 'task')
  final todos = IsarLinks<Todos>();

  Tasks({
    this.id = Isar.autoIncrement,
    required this.title,
    this.description = '',
    this.archive = false,
    required this.taskColor,
    this.index,
    this.sortOption = SortOption.none,
  });
}

@collection
class Todos {
  Id id;
  String name;
  String description;
  DateTime? todoCompletedTime;
  DateTime createdTime;
  DateTime? todoCompletionTime;
  @Deprecated('Use status field instead')
  bool done;
  bool fix;
  @enumerated
  Priority priority;
  @enumerated
  TodoStatus status;
  List<String> tags = [];
  int? index;
  @enumerated
  SortOption childrenSortOption = SortOption.none;

  final parent = IsarLink<Todos>();

  @Backlink(to: 'parent')
  final children = IsarLinks<Todos>();

  final task = IsarLink<Tasks>();

  Todos({
    this.id = Isar.autoIncrement,
    required this.name,
    this.description = '',
    this.todoCompletedTime,
    this.todoCompletionTime,
    required this.createdTime,
    this.done = false,
    this.fix = false,
    this.priority = Priority.none,
    this.status = TodoStatus.active,
    this.tags = const [],
    this.index,
  });
}

enum Priority {
  high(name: 'highPriority', color: Colors.red),
  medium(name: 'mediumPriority', color: Colors.orange),
  low(name: 'lowPriority', color: Colors.green),
  none(name: 'noPriority');

  const Priority({required this.name, this.color});

  final String name;
  final Color? color;
}

enum TodoStatus {
  active,
  done,
  cancelled;

  bool get isCompleted =>
      this == TodoStatus.done || this == TodoStatus.cancelled;
}

@collection
class ChatSession {
  Id id = Isar.autoIncrement;
  String title;
  DateTime createdAt;
  DateTime updatedAt;

  @Backlink(to: 'session')
  final messages = IsarLinks<ChatMessage>();

  ChatSession({
    this.id = Isar.autoIncrement,
    this.title = 'New Chat',
    required this.createdAt,
    required this.updatedAt,
  });
}

@collection
class ChatMessage {
  Id id = Isar.autoIncrement;
  String text;
  DateTime createdAt;

  @enumerated
  SenderType sender;

  @enumerated
  MessageType type;

  // Optional: file path for images or audio
  String? attachmentPath;

  final session = IsarLink<ChatSession>();

  ChatMessage({
    this.id = Isar.autoIncrement,
    required this.text,
    required this.createdAt,
    required this.sender,
    this.type = MessageType.text,
    this.attachmentPath,
  });
}

enum SenderType { user, bot }

enum MessageType { text, image, voice }
