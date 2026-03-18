import 'package:planly_ai/app/data/db.dart';
import 'package:isar_community/isar.dart';
import 'package:planly_ai/main.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:planly_ai/app/constants/debug_config.dart';

/// Creates a sample chat session containing all types of cards.
///
/// Automatic creation is controlled by [DebugConfig.createSampleChatSession].
///
/// Usage:
/// 1. Set createSampleChatSession = true in lib/app/constants/debug_config.dart
/// 2. Call this function in the initializeApp() function in main.dart
///
/// Example:
/// ```dart
/// if (DebugConfig.createSampleChatSession) {
///   await createSampleChatSessionWithAllCards();
/// }
/// ```
Future<void> createSampleChatSessionWithAllCards() async {
  // Return immediately if this feature is disabled in debug config
  if (!DebugConfig.createSampleChatSession) {
    debugPrint('[Sample Data] Sample chat session feature is disabled');
    return;
  }

  // Create session
  final session = ChatSession(
    title: 'Card Showcase Example',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    sessionId: 'sample_session_${DateTime.now().millisecondsSinceEpoch}',
  );

  await isar.writeTxn(() async {
    await isar.chatSessions.put(session);

    // 1. Welcome message
    final welcomeMsg = ChatMessage(
      text: 'Hello! This is a sample session showcasing all types of cards.',
      createdAt: DateTime.now().add(const Duration(seconds: 0)),
      sender: SenderType.bot,
      type: MessageType.text,
    );
    await isar.chatMessages.put(welcomeMsg);
    session.messages.add(welcomeMsg);

    // 2. EVENT card - Schedule confirmation
    final eventCardMsg = ChatMessage(
      text: '',
      createdAt: DateTime.now().add(const Duration(seconds: 10)),
      sender: SenderType.bot,
      type: MessageType.cardEvent,
      cardContent: jsonEncode({
        'title': 'Weekly Project Meeting',
        'startTime': '2026-03-17T18:00:00.000Z',
        'endTime': '2026-03-17T19:00:00.000Z',
        'description': 'Weekly routine project sync meeting',
      }),
    );
    await isar.chatMessages.put(eventCardMsg);
    session.messages.add(eventCardMsg);

    // 3. TASK card - AI task breakdown
    final taskCardMsg = ChatMessage(
      text: '',
      createdAt: DateTime.now().add(const Duration(seconds: 20)),
      sender: SenderType.bot,
      type: MessageType.cardTask,
      cardContent: jsonEncode({
        'title': 'Write API Documentation',
        'description':
            'Complete the documentation for the Sync interface integration',
        'taskEnum': 'WORK',
        'isCompleted': 0.5,
        'spentTime': 60,
      }),
    );
    await isar.chatMessages.put(taskCardMsg);
    session.messages.add(taskCardMsg);

    // 4. ALERT card - Reminder
    final alertCardMsg = ChatMessage(
      text: '',
      createdAt: DateTime.now().add(const Duration(seconds: 30)),
      sender: SenderType.bot,
      type: MessageType.cardAlert,
      cardContent: jsonEncode({
        'title': 'Hydration Reminder',
        'alertTime': '2026-03-17T15:00:00.000Z',
        'message':
            'You\'ve been working for a long time. Get up, drink some water, and stretch! Staying hydrated is good for your health.',
        'repeatStrategy': 'DAILY',
      }),
    );
    await isar.chatMessages.put(alertCardMsg);
    session.messages.add(alertCardMsg);

    // 5. SCHEDULE card - Today's timeline
    final scheduleCardMsg = ChatMessage(
      text: '',
      createdAt: DateTime.now().add(const Duration(seconds: 40)),
      sender: SenderType.bot,
      type: MessageType.cardSchedule,
      cardContent: jsonEncode({
        'title': 'Today\'s Workday Plan',
        'timeDescription': 'Today\'s main goal is to tackle the core modules',
        'eventList': [
          {
            'title': 'Team Stand-up',
            'startTime': '2026-03-17T09:00:00.000Z',
            'endTime': '2026-03-17T10:00:00.000Z',
          },
          {
            'title': 'Deep Work',
            'startTime': '2026-03-17T10:00:00.000Z',
            'endTime': '2026-03-17T12:00:00.000Z',
          },
        ],
      }),
    );
    await isar.chatMessages.put(scheduleCardMsg);
    session.messages.add(scheduleCardMsg);

    // 6. GRAPH card - Focus duration statistics
    final graphCardMsg = ChatMessage(
      text: '',
      createdAt: DateTime.now().add(const Duration(seconds: 50)),
      sender: SenderType.bot,
      type: MessageType.cardGraph,
      cardContent: jsonEncode({
        'title': 'Weekly Focus Duration Statistics',
        'graph': {
          'chartType': 'line',
          'xAxis': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
          'data': [4.5, 6, 3, 5.5, 4.5],
          'unit': 'h',
        },
      }),
    );
    await isar.chatMessages.put(graphCardMsg);
    session.messages.add(graphCardMsg);

    // 7. EVENT_LIST card - To-do list
    final eventListCardMsg = ChatMessage(
      text: '',
      createdAt: DateTime.now().add(const Duration(seconds: 60)),
      sender: SenderType.bot,
      type: MessageType.cardEventList,
      cardContent: jsonEncode({
        'title': 'Today\'s To-Do List',
        'eventCards': [
          {
            'title': 'Morning Meeting',
            'startTime': '2026-03-17T09:00:00.000Z',
            'endTime': '2026-03-17T09:30:00.000Z',
            'description': 'Team sync on today\'s work plan',
          },
          {
            'title': 'Code Review',
            'startTime': '2026-03-17T14:00:00.000Z',
            'endTime': '2026-03-17T15:00:00.000Z',
            'description': 'Review PR #1024',
          },
          {
            'title': 'Product Requirement Discussion',
            'startTime': '2026-03-17T16:00:00.000Z',
            'endTime': '2026-03-17T17:00:00.000Z',
            'description':
                'Discuss new feature requirements with the product manager',
          },
        ],
      }),
    );
    await isar.chatMessages.put(eventListCardMsg);
    session.messages.add(eventListCardMsg);

    // 8. Closing message
    final endMsg = ChatMessage(
      text:
          'That covers all types of cards! You can see this complete example session in your chat list.',
      createdAt: DateTime.now().add(const Duration(seconds: 70)),
      sender: SenderType.bot,
      type: MessageType.text,
    );
    await isar.chatMessages.put(endMsg);
    session.messages.add(endMsg);

    // Save session
    session.updatedAt = DateTime.now();
    await isar.chatSessions.put(session);
    await session.messages.save();
  });

  debugPrint('[Sample Data] Sample chat session created successfully!');
}

/// Clears sample data (optional)
Future<void> removeSampleChatSessions() async {
  await isar.writeTxn(() async {
    final sessions = await isar.chatSessions.where().findAll();
    for (final session in sessions) {
      if (session.sessionId?.startsWith('sample_session_') ?? false) {
        await session.messages.load();
        for (final msg in session.messages) {
          await isar.chatMessages.delete(msg.id);
        }
        await isar.chatSessions.delete(session.id);
      }
    }
  });
  debugPrint('[Sample Data] Sample chat sessions deleted!');
}
