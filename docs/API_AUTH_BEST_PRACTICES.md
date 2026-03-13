# Planly API 认证最佳实践

## 概述

本项目使用 **Dio 拦截器** 模式来统一管理所有 Planly 后端请求的认证信息（`Authorization: Bearer {token}` 和 `clientId` header）。

## 架构设计

```
lib/app/services/
├── api/
│   └── planly_api_client.dart    # 统一的 API 客户端（单例）
├── interceptors/
│   └── auth_interceptor.dart     # 认证拦截器
└── auth_service.dart             # 认证服务（使用统一客户端）
```

## 核心组件

### 1. `AuthInterceptor` (认证拦截器)

**位置**: `lib/app/services/interceptors/auth_interceptor.dart`

**职责**:
- 自动从 `FlutterSecureStorage` 读取 `auth_token`
- 为所有请求添加 `Authorization: Bearer {token}` header
- 为所有请求添加 `clientId` header
- 处理 401 未授权错误（可扩展 token 刷新逻辑）

**关键代码**:
```dart
@override
void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
  final token = await _storage.read(key: 'auth_token');
  
  if (token != null && token.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  
  options.headers['clientId'] = AppConstants.clientId;
  handler.next(options);
}
```

### 2. `PlanlyApiClient` (统一 API 客户端)

**位置**: `lib/app/services/api/planly_api_client.dart`

**职责**:
- 提供单例模式的 Dio 实例
- 配置统一的 baseUrl、timeout 等
- 注册 `AuthInterceptor` 和其他拦截器
- 所有 Planly 后端请求都应该使用这个客户端

**使用方式**:
```dart
final dio = PlanlyApiClient.instance.dio;
await dio.get('/some/endpoint');
```

### 3. `AuthService` (认证服务)

**更新后**:
```dart
class AuthService {
  final Dio _dio;

  AuthService() : _dio = PlanlyApiClient.instance.dio;

  // 不再需要手动传递 token
  Future<Response> getProfile() async {
    return await _dio.get('/system/user/profile');
  }

  Future<Response> logout() async {
    return await _dio.post('/auth/logout');
  }
}
```

## 使用指南

### ✅ 正确做法

**所有新的 Planly 后端请求都应该使用统一的客户端**:

```dart
import 'package:planly_ai/app/services/api/planly_api_client.dart';

class MyService {
  final Dio _dio = PlanlyApiClient.instance.dio;

  Future<void> fetchData() async {
    // token 和 clientId 会自动添加，无需手动处理
    final response = await _dio.get('/api/v1/data');
  }
}
```

### ❌ 错误做法

**不要**在每个请求中手动添加 header：

```dart
// ❌ 避免这样做
final token = await getToken();
await dio.post(
  '/api/endpoint',
  options: Options(headers: {
    'Authorization': 'Bearer $token',
    'clientId': AppConstants.clientId,
  }),
);
```

**不要**创建新的 Dio 实例：

```dart
// ❌ 避免这样做
final dio = Dio(BaseOptions(baseUrl: AppConstants.planlyBaseUrl));
```

## 优势

1. **减少重复代码**: 一处管理，处处使用
2. **易于维护**: 修改认证逻辑只需改拦截器
3. **自动处理**: 开发者无需关心 token 的读取和添加
4. **安全性**: token 统一从 `FlutterSecureStorage` 读取
5. **可扩展性**: 可轻松添加 token 刷新、错误处理等逻辑

## 未来扩展

### Token 自动刷新

在 `AuthInterceptor` 的 `onError` 方法中可以添加自动刷新逻辑：

```dart
@override
void onError(DioException err, ErrorInterceptorHandler handler) async {
  if (err.response?.statusCode == 401) {
    // 1. 检查是否有刷新 token
    // 2. 调用刷新接口获取新 token
    // 3. 更新存储
    // 4. 重试原请求
  }
  handler.next(err);
}
```

### 统一错误处理

可以添加另一个拦截器来统一处理 API 错误：

```dart
class ErrorHandlingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 500) {
      // 显示服务器错误提示
    }
    handler.next(err);
  }
}
```

## 相关文件

- `lib/app/services/api/planly_api_client.dart` - API 客户端
- `lib/app/services/interceptors/auth_interceptor.dart` - 认证拦截器
- `lib/app/services/auth_service.dart` - 认证服务
- `lib/app/controller/auth_controller.dart` - 认证控制器
- `lib/app/ui/chatbot/controller/chatbot_controller.dart` - 使用示例
