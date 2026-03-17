import 'package:planly_ai/app/data/db.dart';
import 'package:isar_community/isar.dart';
import 'package:planly_ai/main.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:planly_ai/app/constants/debug_config.dart';

/// 创建一个包含所有类型卡片的示例聊天会话
///
/// 是否自动创建由 [DebugConfig.createSampleChatSession] 控制
///
/// 使用方法：
/// 1. 在 lib/app/constants/debug_config.dart 中设置 createSampleChatSession = true
/// 2. 在 main.dart 的 initializeApp() 函数中调用此函数
///
/// 示例：
/// ```dart
/// if (DebugConfig.createSampleChatSession) {
///   await createSampleChatSessionWithAllCards();
/// }
/// ```
Future<void> createSampleChatSessionWithAllCards() async {
  // 如果调试配置关闭了此功能，则直接返回
  if (!DebugConfig.createSampleChatSession) {
    debugPrint('[Sample Data] 示例聊天会话功能已禁用');
    return;
  }
  // 创建会话
  final session = ChatSession(
    title: '卡片展示示例',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    sessionId: 'sample_session_${DateTime.now().millisecondsSinceEpoch}',
  );

  await isar.writeTxn(() async {
    await isar.chatSessions.put(session);

    // 1. 欢迎消息
    final welcomeMsg = ChatMessage(
      text: '你好！这是一个展示所有类型卡片的示例会话。',
      createdAt: DateTime.now().add(const Duration(seconds: 0)),
      sender: SenderType.bot,
      type: MessageType.text,
    );
    await isar.chatMessages.put(welcomeMsg);
    session.messages.add(welcomeMsg);

    // 2. EVENT 卡片 - 日程确认
    final eventCardMsg = ChatMessage(
      text: '',
      createdAt: DateTime.now().add(const Duration(seconds: 10)),
      sender: SenderType.bot,
      type: MessageType.cardEvent,
      cardContent: jsonEncode({
        'title': '项目周会',
        'startTime': '2026-03-17T18:00:00.000Z',
        'endTime': '2026-03-17T19:00:00.000Z',
        'description': '每周例行项目同步会议',
      }),
    );
    await isar.chatMessages.put(eventCardMsg);
    session.messages.add(eventCardMsg);

    // 3. TASK 卡片 - AI 任务拆解
    final taskCardMsg = ChatMessage(
      text: '',
      createdAt: DateTime.now().add(const Duration(seconds: 20)),
      sender: SenderType.bot,
      type: MessageType.cardTask,
      cardContent: jsonEncode({
        'title': '编写 API 文档',
        'description': '完成 Sync 接口的对接文档编写',
        'taskEnum': 'WORK',
        'isCompleted': 0.5,
        'spentTime': 60,
      }),
    );
    await isar.chatMessages.put(taskCardMsg);
    session.messages.add(taskCardMsg);

    // 4. ALERT 卡片 - 提醒
    final alertCardMsg = ChatMessage(
      text: '',
      createdAt: DateTime.now().add(const Duration(seconds: 30)),
      sender: SenderType.bot,
      type: MessageType.cardAlert,
      cardContent: jsonEncode({
        'title': '喝水提醒',
        'alertTime': '2026-03-17T15:00:00.000Z',
        'message': '工作很久了，起来喝杯水活动一下吧！保持水分对身体好哦~',
        'repeatStrategy': 'DAILY',
      }),
    );
    await isar.chatMessages.put(alertCardMsg);
    session.messages.add(alertCardMsg);

    // 5. SCHEDULE 卡片 - 今日时间轴
    final scheduleCardMsg = ChatMessage(
      text: '',
      createdAt: DateTime.now().add(const Duration(seconds: 40)),
      sender: SenderType.bot,
      type: MessageType.cardSchedule,
      cardContent: jsonEncode({
        'title': '今日工作日规划',
        'timeDescription': '今天的主要目标是攻克核心模块',
        'eventList': [
          {
            'title': '团队站会',
            'startTime': '2026-03-17T09:00:00.000Z',
            'endTime': '2026-03-17T10:00:00.000Z'
          },
          {
            'title': '深度工作',
            'startTime': '2026-03-17T10:00:00.000Z',
            'endTime': '2026-03-17T12:00:00.000Z'
          },
        ],
      }),
    );
    await isar.chatMessages.put(scheduleCardMsg);
    session.messages.add(scheduleCardMsg);

    // 6. GRAPH 卡片 - 专注时长统计
    final graphCardMsg = ChatMessage(
      text: '',
      createdAt: DateTime.now().add(const Duration(seconds: 50)),
      sender: SenderType.bot,
      type: MessageType.cardGraph,
      cardContent: jsonEncode({
        'title': '本周专注时长统计',
        'graph': {
          'chartType': 'line',
          'xAxis': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
          'data': [4.5, 6, 3, 5.5, 4.5],
          'unit': 'h'
        },
      }),
    );
    await isar.chatMessages.put(graphCardMsg);
    session.messages.add(graphCardMsg);

    // 7. EVENT_LIST 卡片 - 待办事项列表
    final eventListCardMsg = ChatMessage(
      text: '',
      createdAt: DateTime.now().add(const Duration(seconds: 60)),
      sender: SenderType.bot,
      type: MessageType.cardEventList,
      cardContent: jsonEncode({
        'title': '今日待办事项',
        'eventCards': [
          {
            'title': '晨会',
            'startTime': '2026-03-17T09:00:00.000Z',
            'endTime': '2026-03-17T09:30:00.000Z',
            'description': '全员同步今日工作计划',
          },
          {
            'title': '代码评审',
            'startTime': '2026-03-17T14:00:00.000Z',
            'endTime': '2026-03-17T15:00:00.000Z',
            'description': 'Review PR #1024',
          },
          {
            'title': '产品需求讨论',
            'startTime': '2026-03-17T16:00:00.000Z',
            'endTime': '2026-03-17T17:00:00.000Z',
            'description': '与产品经理讨论新功能需求讨论',
          },
        ],
      }),
    );
    await isar.chatMessages.put(eventListCardMsg);
    session.messages.add(eventListCardMsg);

    // 8. 结束消息
    final endMsg = ChatMessage(
      text: '以上就是所有类型的卡片展示！你可以在聊天列表中看到这个完整的示例会话。',
      createdAt: DateTime.now().add(const Duration(seconds: 70)),
      sender: SenderType.bot,
      type: MessageType.text,
    );
    await isar.chatMessages.put(endMsg);
    session.messages.add(endMsg);

    // 保存会话
    session.updatedAt = DateTime.now();
    await isar.chatSessions.put(session);
    await session.messages.save();
  });

  debugPrint('[Sample Data] 示例聊天会话创建成功！');
}

/// 清除示例数据（可选）
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
  debugPrint('[Sample Data] 示例聊天会话已删除！');
}
