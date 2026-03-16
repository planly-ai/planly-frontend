import 'package:dio/dio.dart';
import 'package:planly_ai/app/services/api/planly_api_client.dart';

class ChatService {
  final Dio _dio;

  ChatService() : _dio = PlanlyApiClient.instance.dio;

  /// Create a new session for the chatbot
  Future<Response> createSession() async {
    return await _dio.post('/api/v1/sessions/create');
  }

  /// Send a chat message to the agent
  /// 
  /// [message] - the text message to send
  /// [ossIds] - list of optional OSS IDs for file attachments
  /// [sessionId] - the session ID for the conversation
  Future<Response> chat({
    required String message,
    List<String>? ossIds,
    required String sessionId,
  }) async {
    return await _dio.post(
      '/api/v1/agent/chat',
      data: {
        "message": message,
        "ossIds": ossIds ?? [],
        "sessionId": sessionId,
      },
    );
  }

  /// Get the chat response stream using SSE
  /// 
  /// [sessionId] - the session ID for the conversation
  Future<Response<ResponseBody>> getChatStream(String sessionId) async {
    return await _dio.get<ResponseBody>(
      '/api/v1/chat/stream/$sessionId',
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
        receiveTimeout: const Duration(minutes: 5), // Long timeout for streaming
      ),
    );
  }
}
