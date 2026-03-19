/// 应用调试配置
///
/// 统一管理所有的调试功能和示例数据开关
///
/// 使用方法：
/// 修改对应配置项的值即可（true 启用，false 禁用）
class DebugConfig {
  const DebugConfig._();

  // ==================== 示例数据 ====================

  /// 是否启动时自动创建示例聊天会话
  /// 启用后会在应用启动时创建一个包含所有类型卡片的示例会话
  static const bool createSampleChatSession = false;

  /// 是否自动删除旧的示例会话
  /// 启用后会在创建新示例数据前先清理旧的示例数据
  static const bool autoRemoveOldSampleSessions = false;

  // ==================== Todo 示例数据 ====================

  /// 是否启动时自动创建示例日程数据
  /// 按照运行日期生成前后两周的时间段中的大学生日常日程
  static const bool createSampleTodoData = false;

  /// 是否自动删除旧的示例日程数据
  static const bool autoRemoveOldSampleTodos = false;
}
