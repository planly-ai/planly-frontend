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
        'time': '2026-03-17 18:00',
        'startTime': '2026-03-17 18:00',
        'endTime': '2026-03-17 19:00',
        'location': '3 楼会议室 A',
        'reminder': '提前 15 分钟',
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
        'subTasks': [
          {'title': '整理接口清单', 'durationMinutes': 20, 'isCompleted': false},
          {'title': '补充请求参数说明', 'durationMinutes': 30, 'isCompleted': false},
          {'title': '输出示例代码', 'durationMinutes': 40, 'isCompleted': false},
          {'title': '审核并发布', 'durationMinutes': 15, 'isCompleted': true},
        ],
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
        'alertTime': '2026-03-17 15:00',
        'message': '工作很久了，起来喝杯水活动一下吧！保持水分对身体好哦~',
        'repeatStrategy': 'DAILY',
        'description': '定时提醒喝水',
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
        'date': '2026 年 3 月 17 日 星期二',
        'busyHours': 7,
        'freeHours': 7,
        'events': [
          {'title': '团队站会', 'time': '09:00 - 10:00', 'tag': '会议'},
          {'title': '深度工作时间', 'time': '10:00 - 12:00', 'tag': '专注'},
          {'title': '处理邮件和消息', 'time': '14:00 - 15:00', 'tag': '忙碌'},
          {'title': '客户需求评审', 'time': '15:00 - 17:00', 'tag': '会议'},
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
        'totalDuration': '4 小时 5 分钟',
        'comparisonText': '+65 分钟',
        'comparisonPercentage': '36%',
        'longestSession': '90 分钟',
        'chartData': [
          {'x': 0, 'y': 45},
          {'x': 2, 'y': 60},
          {'x': 4, 'y': 30},
          {'x': 6, 'y': 55},
          {'x': 8, 'y': 45},
          {'x': 10, 'y': 15},
        ],
        'insight': '今天的专注时间超过 3 小时，保持得非常好！上午 10 点是你效率最高的时段。',
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
            'startTime': '2026-03-17 09:00',
            'endTime': '2026-03-17 09:30',
            'description': '全员同步今日工作计划',
          },
          {
            'title': '代码评审',
            'startTime': '2026-03-17 14:00',
            'endTime': '2026-03-17 15:00',
            'description': 'Review PR #1024',
          },
          {
            'title': '产品需求讨论',
            'startTime': '2026-03-17 16:00',
            'endTime': '2026-03-17 17:00',
            'description': '与产品经理讨论新功能需求',
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
