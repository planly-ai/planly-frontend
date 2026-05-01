import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/main.dart';
import 'package:planly_ai/app/constants/debug_config.dart';
import 'package:uuid/uuid.dart';

final Uuid _uuid = Uuid();

/// Generates sample todo data for a college student's daily life.
/// 
/// The data is generated for a period of 14 days before and after today.
/// Each day contains 2-5 schedule items.
Future<void> createSampleTodoData() async {
  if (!DebugConfig.createSampleTodoData) {
    debugPrint('[Sample Todo] Sample todo data feature is disabled');
    return;
  }

  if (DebugConfig.autoRemoveOldSampleTodos) {
    await removeSampleTodoData();
  }

  // Ensure categories (Tasks) exist
  final categoriesMap = await _ensureCategoriesExist();

  final now = DateTime.now();
  final startDate = now.subtract(const Duration(days: 14));

  final random = Random();

  await isar.writeTxn(() async {
    for (int i = 0; i <= 28; i++) {
      final day = startDate.add(Duration(days: i));
      final itemCount = 2 + random.nextInt(4); // 2 to 5 items

      for (int j = 0; j < itemCount; j++) {
        final activity = _getRandomActivity(random);
        final category = categoriesMap[activity['category']] ?? categoriesMap['Uncategorized']!;
        
        // Random time during the day (8:00 to 22:00)
        final hour = 8 + random.nextInt(14);
        final minute = random.nextInt(4) * 15; // 0, 15, 30, 45
        final scheduledTime = DateTime(day.year, day.month, day.day, hour, minute);

        // Past items are more likely to be completed, future items are active
        final isPast = scheduledTime.isBefore(now);
        final status = isPast 
            ? (random.nextDouble() > 0.2 ? TodoStatus.done : TodoStatus.active)
            : TodoStatus.active;

        final todo = Todos(
          uuidv7: _uuid.v7(),
          name: activity['name'] as String,
          description: activity['description'] as String,
          createdTime: day.subtract(const Duration(days: 1)),
          todoCompletedTime: scheduledTime, // This field is used for calendar display
          todoCompletionTime: status == TodoStatus.done ? scheduledTime.add(const Duration(minutes: 30)) : null,
          status: status,
          priority: _getRandomPriority(random),
        );

        todo.task.value = category;
        await isar.todos.put(todo);
        await todo.task.save();
      }
    }
  });

  debugPrint('[Sample Todo] Sample todo data created successfully!');
}

Future<void> removeSampleTodoData() async {
  await isar.writeTxn(() async {
    // We only remove todos that match our sample naming or categories if needed, 
    // but for debug purposes, we might just clear everything or use a tag.
    // For now, let's just clear all todos and non-archived tasks to start fresh if autoRemove is true.
    await isar.todos.clear();
    // Keep categories but we could also clear them if we want a completely fresh state.
    // await isar.tasks.clear(); 
  });
  debugPrint('[Sample Todo] Old todo data removed!');
}

Future<Map<String, Tasks>> _ensureCategoriesExist() async {
  final categoryNames = ['Study', 'Social', 'Work', 'Fitness', 'Personal', 'Uncategorized'];
  final Map<String, Tasks> categoriesMap = {};

  await isar.writeTxn(() async {
    for (final name in categoryNames) {
      var task = await isar.tasks.filter().titleEqualTo(name).findFirst();
      if (task == null) {
        task = Tasks(
          uuidv7: _uuid.v7(),
          title: name,
          taskColor: _getCategoryColor(name).value,
          description: '$name related tasks and schedules',
        );
        await isar.tasks.put(task);
      }
      categoriesMap[name] = task;
    }
  });

  return categoriesMap;
}

Color _getCategoryColor(String name) {
  switch (name) {
    case 'Study': return const Color(0xFF2196F3); // Blue
    case 'Social': return const Color(0xFFFF9800); // Orange
    case 'Work': return const Color(0xFFF44336); // Red
    case 'Fitness': return const Color(0xFF4CAF50); // Green
    case 'Personal': return const Color(0xFF9C27B0); // Purple
    default: return const Color(0xFF9E9E9E); // Grey
  }
}

Priority _getRandomPriority(Random random) {
  final val = random.nextInt(4);
  switch (val) {
    case 0: return Priority.none;
    case 1: return Priority.low;
    case 2: return Priority.medium;
    case 3: return Priority.high;
    default: return Priority.none;
  }
}

Map<String, String> _getRandomActivity(Random random) {
  final activities = [
    {'name': 'Computer Science Lecture', 'category': 'Study', 'description': 'Main building, Room 302.'},
    {'name': 'Organic Chemistry Lab', 'category': 'Study', 'description': 'Wear lab coat and goggles.'},
    {'name': 'Intro to Psychology Seminar', 'category': 'Study', 'description': 'Discuss chapter 4.'},
    {'name': 'Study Group: Math', 'category': 'Study', 'description': 'Library 2nd floor.'},
    {'name': 'Library Research Session', 'category': 'Study', 'description': 'Work on final paper.'},
    {'name': 'Prepare for Exam', 'category': 'Study', 'description': 'Focus on calculus.'},
    {'name': 'Write Essay Draft', 'category': 'Study', 'description': 'Philosophy essay due Friday.'},
    {'name': 'Meeting with Professor', 'category': 'Study', 'description': 'Office hours.'},
    
    {'name': 'Club Meeting: Debate', 'category': 'Social', 'description': 'Prepare for next week\'s competition.'},
    {'name': 'Lunch with friends', 'category': 'Social', 'description': 'Campus cafeteria.'},
    {'name': 'Dinner with Roommates', 'category': 'Social', 'description': 'Cooking pasta tonight.'},
    {'name': 'Inter-campus Sports Game', 'category': 'Social', 'description': 'Support the university team.'},
    
    {'name': 'Part-time Job at Cafe', 'category': 'Work', 'description': 'Afternoon shift.'},
    {'name': 'Online Freelance Task', 'category': 'Work', 'description': 'Design update.'},
    
    {'name': 'Gym: Cardio', 'category': 'Fitness', 'description': 'Treadmill for 30 mins.'},
    {'name': 'Morning Run', 'category': 'Fitness', 'description': 'Run around the park.'},
    {'name': 'Swimming Session', 'category': 'Fitness', 'description': 'University pool.'},
    {'name': 'Yoga at home', 'category': 'Fitness', 'description': 'Follow the 20-min video.'},
    
    {'name': 'Grocery Shopping', 'category': 'Personal', 'description': 'Need milk and eggs.'},
    {'name': 'Laundry Day', 'category': 'Personal', 'description': 'Wash bedding.'},
    {'name': 'Watch Netflix', 'category': 'Personal', 'description': 'Catch up on the new series.'},
    {'name': 'Clean Apartment', 'category': 'Personal', 'description': 'Bedroom and kitchen.'},
    
    {'name': 'Check Emails', 'category': 'Uncategorized', 'description': 'Process unread messages from professor and club.'},
    {'name': 'Water Plants', 'category': 'Uncategorized', 'description': 'Maintenance for the balcony garden.'},
    {'name': 'Call Home', 'category': 'Uncategorized', 'description': 'Weekly catch-up with parents.'},
  ];

  return activities[random.nextInt(activities.length)];
}
