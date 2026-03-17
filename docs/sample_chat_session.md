# 示例聊天会话数据

这个文件包含了一个示例聊天会话，展示了所有类型的聊天卡片。

## 包含的卡片类型

示例会话包含以下 7 种卡片类型：

1. **EVENT 卡片** (`EventCard`) - 日程确认卡片
   - 显示日程标题、时间、地点、提醒设置
   - 示例：项目周会

2. **TASK 卡片** (`TaskCard`) - AI 任务拆解卡片
   - 显示任务列表和子任务进度
   - 示例：编写 API 文档（包含 4 个子任务）

3. **ALERT 卡片** (`AlertCard`) - 提醒卡片
   - 显示提醒标题、时间、消息和重复策略
   - 示例：喝水提醒

4. **SCHEDULE 卡片** (`ScheduleCard`) - 时间轴卡片
   - 显示日期、忙碌/空闲时段统计和时间轴事件
   - 示例：今日时间轴

5. **GRAPH 卡片** (`GraphCard`) - 统计图表卡片
   - 显示专注时长统计、对比数据和时段分布图表
   - 示例：专注时长统计

6. **EVENT_LIST 卡片** (`EventListCard`) - 事件列表卡片
   - 显示多个待办事项的列表
   - 示例：今日待办事项（包含 3 个事件）

7. **SESSION 卡片** (`SessionCard`) - 会话列表卡片
   - 用于侧边栏会话列表，不在此示例中展示

## 使用方法

### 方法一：统一配置开关（推荐）

所有调试功能都在 `lib/app/constants/debug_config.dart` 中统一管理。

1. 打开 `lib/app/constants/debug_config.dart`
2. 修改配置：
   ```dart
   class DebugConfig {
     /// 是否启动时自动创建示例聊天会话
     static const bool createSampleChatSession = true;  // 改为 true 启用
   }
   ```
3. 在 `lib/main.dart` 的 `initializeApp()` 中已经配置好了自动调用逻辑

**优势：**
- 所有调试开关集中管理
- 生产/开发环境切换方便
- 无需注释/取消注释代码

### 方法二：手动调用

在任何需要的地方导入并调用：

```dart
import 'package:planly_ai/app/data/sample_chat_session.dart';
import 'package:planly_ai/app/constants/debug_config.dart';

// 创建示例数据
if (DebugConfig.createSampleChatSession) {
  await createSampleChatSessionWithAllCards();
}

// 删除示例数据（可选）
await removeSampleChatSessions();
```

### 方法三：在设置页面添加测试按钮

可以在设置页面添加一个调试按钮：

```dart
ElevatedButton(
  onPressed: () async {
    await createSampleChatSessionWithAllCards();
    // 显示成功提示
  },
  child: const Text('创建示例聊天会话'),
)
```

## 示例数据结构

每个卡片的 JSON 数据结构如下：

### EVENT 卡片
```json
{
  "title": "项目周会",
  "time": "2026-03-17 18:00",
  "startTime": "2026-03-17 18:00",
  "endTime": "2026-03-17 19:00",
  "location": "3 楼会议室 A",
  "reminder": "提前 15 分钟",
  "description": "每周例行项目同步会议"
}
```

### TASK 卡片
```json
{
  "title": "编写 API 文档",
  "subTasks": [
    {"title": "整理接口清单", "durationMinutes": 20, "isCompleted": false},
    {"title": "补充请求参数说明", "durationMinutes": 30, "isCompleted": false},
    {"title": "输出示例代码", "durationMinutes": 40, "isCompleted": false},
    {"title": "审核并发布", "durationMinutes": 15, "isCompleted": true}
  ]
}
```

### ALERT 卡片
```json
{
  "title": "喝水提醒",
  "alertTime": "2026-03-17 15:00",
  "message": "工作很久了，起来喝杯水活动一下吧！",
  "repeatStrategy": "DAILY"
}
```

### SCHEDULE 卡片
```json
{
  "date": "2026 年 3 月 17 日 星期二",
  "busyHours": 7,
  "freeHours": 7,
  "events": [
    {"title": "团队站会", "time": "09:00 - 10:00", "tag": "会议"},
    {"title": "深度工作时间", "time": "10:00 - 12:00", "tag": "专注"}
  ]
}
```

### GRAPH 卡片
```json
{
  "totalDuration": "4 小时 5 分钟",
  "comparisonText": "+65 分钟",
  "comparisonPercentage": "36%",
  "longestSession": "90 分钟",
  "chartData": [
    {"x": 0, "y": 45},
    {"x": 2, "y": 60}
  ],
  "insight": "今天的专注时间超过 3 小时，保持得非常好！"
}
```

### EVENT_LIST 卡片
```json
{
  "title": "今日待办事项",
  "eventCards": [
    {
      "title": "晨会",
      "startTime": "2026-03-17 09:00",
      "endTime": "2026-03-17 09:30",
      "description": "全员同步今日工作计划"
    }
  ]
}
```

## 注意事项

1. 示例数据仅用于开发和测试目的
2. 示例会话的 `sessionId` 以 `sample_session_` 开头，便于识别和清理
3. 使用 `removeSampleChatSessions()` 函数可以清除所有示例数据
4. 建议在调试模式下使用，生产环境请禁用

## 相关文件

- 创建脚本：`lib/app/data/sample_chat_session.dart`
- 主入口：`lib/main.dart`
- 卡片组件：`lib/app/ui/chatbot/widgets/card/`
- 聊天泡泡：`lib/app/ui/chatbot/widgets/chat_bubble.dart`
- 数据库模型：`lib/app/data/db.dart`
