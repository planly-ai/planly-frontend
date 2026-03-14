import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/main.dart'; // To access the global `isar` instance
import 'package:planly_ai/app/services/asr_service.dart';
import 'package:planly_ai/app/services/audio_recording_service.dart';
import 'package:planly_ai/app/utils/show_snack_bar.dart';

import 'package:file_selector/file_selector.dart';
import 'package:dio/dio.dart' as dio_lib;
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/services/api/planly_api_client.dart';
import 'package:planly_ai/app/services/chat_service.dart';
import 'package:image_picker/image_picker.dart';

class ChatbotController extends GetxController {
  // Observables
  var sessions = <ChatSession>[].obs;
  var currentSessionId = Rxn<int>();
  var messages = <ChatMessage>[].obs;

  var textController = TextEditingController();
  var scrollController = ScrollController();
  var isTyping = false.obs;
  var isRecognizing = false.obs;

  // File Upload State
  var selectedFile = Rxn<XFile>();
  var isUploading = false.obs;
  var uploadedUrl = RxnString();
  var uploadedFileName = RxnString();
  var uploadedOssId = RxnString();

  // Services
  final AsrService _asrService = AsrService();
  final AudioRecordingService _audioService = AudioRecordingService();
  final ChatService _chatService = ChatService();

  // Voice Recording State
  var isRecording = false.obs;
  var isCancellingRecording = false.obs;
  double _startRecordDy = 0;
  dio_lib.CancelToken? _uploadCancelToken;

  @override
  void onInit() {
    super.onInit();
    loadSessions();
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    _audioService.dispose();
    super.onClose();
  }

  // Load all sessions ordered by updated time
  Future<void> loadSessions() async {
    final allSessions = await isar.chatSessions
        .where()
        .sortByUpdatedAtDesc()
        .findAll();
    sessions.assignAll(allSessions);
    if (sessions.isNotEmpty && currentSessionId.value == null) {
      selectSession(sessions.first.id);
    } else if (sessions.isEmpty) {
      await createNewSession();
    }
  }

  // Create a new session
  Future<bool> createNewSession() async {
    String? sessionId;
    try {
      final response = await _chatService.createSession();
      
      debugPrint('[Session] Response status: ${response.statusCode}');
      debugPrint('[Session] Response data: ${response.data}');

      var responseData = response.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (e) {
          debugPrint('[Session] Failed to parse response data as JSON: $e');
        }
      }

      if (response.statusCode == 200 && responseData is Map && responseData['code'] == 200) {
        sessionId = responseData['data'];
        debugPrint('[Session] Created session ID: $sessionId');
      } else {
        debugPrint('[Session] Failed to create session. Status: ${response.statusCode}, Data: $responseData');
        showSnackBar('session_creation_failed'.tr, isError: true);
        return false;
      }
    } catch (e) {
      debugPrint('[Session] Exception creating session: $e');
      if (e is dio_lib.DioException) {
        debugPrint('[Session] Dio error: ${e.response?.data}');
      }
      showSnackBar('session_creation_failed'.tr, isError: true);
      return false;
    }

    final session = ChatSession(
      title: 'New Chat'.tr,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sessionId: sessionId,
    );
    await isar.writeTxn(() async {
      await isar.chatSessions.put(session);
    });
    await loadSessions();
    await selectSession(session.id);
    return true;
  }

  // Delete a session
  Future<void> deleteSession(int sessionId) async {
    await isar.writeTxn(() async {
      final session = await isar.chatSessions.get(sessionId);
      if (session != null) {
        await session.messages.load();
        for (final msg in session.messages) {
          await isar.chatMessages.delete(msg.id);
        }
        await isar.chatSessions.delete(sessionId);
      }
    });

    if (currentSessionId.value == sessionId) {
      currentSessionId.value = null;
      messages.clear();
    }
    await loadSessions();
  }

  // Switch to a specific session
  Future<void> selectSession(int sessionId) async {
    currentSessionId.value = sessionId;
    await loadMessages(sessionId);
  }

  // Load messages for a session
  Future<void> loadMessages(int sessionId) async {
    final session = await isar.chatSessions.get(sessionId);
    if (session != null) {
      await session.messages.load();
      final loadedMessages = session.messages.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      messages.assignAll(loadedMessages);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Send a message
  Future<void> sendMessage() async {
    final text = textController.text.trim();
    final hasAttachment = uploadedUrl.value != null;

    if (text.isEmpty && !hasAttachment) return;

    textController.clear();

    if (currentSessionId.value == null) {
      final success = await createNewSession();
      if (!success) return;
    }

    final session = await isar.chatSessions.get(currentSessionId.value!);
    if (session == null) return;

    MessageType msgType = MessageType.text;
    if (hasAttachment) {
      final fileName = uploadedFileName.value?.toLowerCase() ?? '';
      if (fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.png') ||
          fileName.endsWith('.gif') ||
          fileName.endsWith('.webp')) {
        msgType = MessageType.image;
      } else {
        msgType = MessageType.file;
      }
    }

    final userMsg = ChatMessage(
      text: text,
      createdAt: DateTime.now(),
      sender: SenderType.user,
      type: msgType,
      attachmentPath: uploadedUrl.value,
      attachmentName: uploadedFileName.value,
      ossId: uploadedOssId.value,
    );

    final currentOssId = uploadedOssId.value;

    // Reset upload state
    selectedFile.value = null;
    uploadedUrl.value = null;
    uploadedFileName.value = null;
    uploadedOssId.value = null;

    await isar.writeTxn(() async {
      await isar.chatMessages.put(userMsg);
      session.messages.add(userMsg);
      await session.messages.save();

      session.updatedAt = DateTime.now();
      await session.messages.load();
      if (session.messages.length == 1 || session.title == 'New Chat'.tr) {
        final displayTitle = text.isNotEmpty
            ? text
            : (userMsg.attachmentPath?.split('/').last ?? 'File');
        session.title = displayTitle.length > 20
            ? '${displayTitle.substring(0, 20)}...'
            : displayTitle;
      }
      await isar.chatSessions.put(session);
    });

    messages.add(userMsg);
    _scrollToBottom();
    loadSessions();

    await _handleBotResponse(text, currentOssId, session.sessionId!);
  }

  Future<void> _handleBotResponse(String text, String? ossId, String sessionId) async {
    isTyping.value = true;
    _scrollToBottom();

    try {
      final response = await _chatService.chat(
        message: text,
        ossIds: ossId != null ? [ossId] : null,
        sessionId: sessionId,
      );

      debugPrint('[Chat] Response status: ${response.statusCode}');
      debugPrint('[Chat] Response data: ${response.data}');

      var responseData = response.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (e) {
          debugPrint('[Chat] Failed to parse response data as JSON: $e');
        }
      }

      if (response.statusCode == 200 && responseData is Map && responseData['code'] == 200) {
        final data = responseData['data'];
        final type = data['type'];
        final content = data['content'] ?? '';

        if (type == 'TEXT') {
          final botMsg = ChatMessage(
            text: content,
            createdAt: DateTime.now(),
            sender: SenderType.bot,
            type: MessageType.text,
          );

          final session = await isar.chatSessions.get(currentSessionId.value!);
          if (session != null) {
            await isar.writeTxn(() async {
              await isar.chatMessages.put(botMsg);
              session.messages.add(botMsg);
              await session.messages.save();

              session.updatedAt = DateTime.now();
              await isar.chatSessions.put(session);
            });
            messages.add(botMsg);
          }
        } else {
          // Handle card types which we were told to ignore for now but we'll log it
          debugPrint('[Chat] Received card response type: $type. Content: $content');
        }
      } else {
        debugPrint('[Chat] Failed to get response. Status: ${response.statusCode}, Data: $responseData');
        showSnackBar('error'.tr, isError: true);
      }
    } catch (e) {
      debugPrint('[Chat] Exception in response handling: $e');
      if (e is dio_lib.DioException) {
        debugPrint('[Chat] Dio error: ${e.response?.data}');
      }
      showSnackBar('error'.tr, isError: true);
    } finally {
      isTyping.value = false;
      _scrollToBottom();
    }
  }

  Future<void> pickAndUploadFile() async {
    const XTypeGroup typeGroup = XTypeGroup(label: 'files');
    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
    );

    if (file == null) {
      debugPrint('[Upload] User cancelled file selection');
      return;
    }

    await _uploadFile(file);
  }

  Future<void> takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo == null) {
      debugPrint('[Upload] User cancelled camera');
      return;
    }

    await _uploadFile(photo);
  }

  Future<void> _uploadFile(XFile file) async {
    debugPrint('[Upload] Selected file: ${file.name}, path: ${file.path}');

    final length = await file.length();
    debugPrint('[Upload] File size: $length bytes');

    if (length > 50 * 1024 * 1024) {
      debugPrint('[Upload] File too large, rejecting');
      showSnackBar('file_too_large'.tr, isError: true);
      return;
    }

    selectedFile.value = file;
    isUploading.value = true;
    _uploadCancelToken = dio_lib.CancelToken();

    try {
      final dio = PlanlyApiClient.instance.dio;
      final formData = dio_lib.FormData.fromMap({
        'file': await dio_lib.MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ),
      });

      final url = '${AppConstants.planlyBaseUrl}/resource/oss/upload';
      debugPrint('[Upload] Request URL: $url');

      final response = await dio.post(
        url,
        data: formData,
        cancelToken: _uploadCancelToken,
      );

      debugPrint('[Upload] Response status code: ${response.statusCode}');
      debugPrint('[Upload] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data['code'] == 200) {
        final data = response.data['data'];
        debugPrint('[Upload] Upload successful: ${data['url']}');
        uploadedUrl.value = data['url'];
        uploadedFileName.value = data['fileName'];
        uploadedOssId.value = data['ossId'];
      } else {
        debugPrint(
            '[Upload] Upload failed with code: ${response.data['code']}, msg: ${response.data['msg']}');
        showSnackBar('upload_failed'.tr, isError: true);
        removeSelectedFile();
      }
    } catch (e) {
      debugPrint('[Upload] Exception caught: $e');
      if (e is dio_lib.DioException) {
        debugPrint('[Upload] DioException type: ${e.type}');
        debugPrint('[Upload] DioException message: ${e.message}');
        debugPrint('[Upload] DioException response: ${e.response?.data}');
        debugPrint(
            '[Upload] DioException status code: ${e.response?.statusCode}');
      }
      if (e is dio_lib.DioException &&
          e.type != dio_lib.DioExceptionType.cancel) {
        showSnackBar('upload_failed'.tr, isError: true);
        removeSelectedFile();
      }
    } finally {
      isUploading.value = false;
    }
  }

  void removeSelectedFile() {
    _uploadCancelToken?.cancel();
    selectedFile.value = null;
    uploadedUrl.value = null;
    uploadedFileName.value = null;
    uploadedOssId.value = null;
    isUploading.value = false;
  }



  void startRecording(double startDy) async {
    if (await _audioService.hasPermission()) {
      isRecording.value = true;
      isCancellingRecording.value = false;
      _startRecordDy = startDy;
      await _audioService.start();
    } else {
      showSnackBar('voice_permission_denied'.tr, isError: true);
    }
  }

  void updateRecordingPointer(double dy) {
    if (!isRecording.value) return;
    // If user slides up by 50 pixels, mark as cancelling
    if (_startRecordDy - dy > 50) {
      isCancellingRecording.value = true;
    } else {
      isCancellingRecording.value = false;
    }
  }

  void endRecording() async {
    if (!isRecording.value) return;
    isRecording.value = false;

    final path = await _audioService.stop();

    if (isCancellingRecording.value) {
      // Cancelled
      isCancellingRecording.value = false;
      // Optionally delete the file if needed
    } else if (path != null) {
      // Show loading or typing state while ASR is working
      isRecognizing.value = true;
      _scrollToBottom();

      final recognizedText = await _asrService.recognize(path);

      isRecognizing.value = false;

      if (recognizedText != null && recognizedText.isNotEmpty) {
        textController.text = recognizedText;
        await sendMessage();
      } else {
        showSnackBar('voice_recognition_failed'.tr, isError: true);
      }
    }
  }
}
