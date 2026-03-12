import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/main.dart'; // To access the global `isar` instance
import 'package:planly_ai/app/services/asr_service.dart';
import 'package:planly_ai/app/services/audio_recording_service.dart';
import 'package:planly_ai/app/utils/show_snack_bar.dart';
import 'package:planly_ai/app/controller/auth_controller.dart';

import 'package:file_selector/file_selector.dart';
import 'package:dio/dio.dart' as dio_lib;
import 'package:planly_ai/app/constants/app_constants.dart';

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
  Future<void> createNewSession() async {
    final session = ChatSession(
      title: 'New Chat'.tr,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await isar.writeTxn(() async {
      await isar.chatSessions.put(session);
    });
    await loadSessions();
    selectSession(session.id);
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
      await createNewSession();
    }

    final session = await isar.chatSessions.get(currentSessionId.value!);
    if (session == null) return;

    final userMsg = ChatMessage(
      text: text,
      createdAt: DateTime.now(),
      sender: SenderType.user,
      type: hasAttachment ? MessageType.image : MessageType.text,
      attachmentPath: uploadedUrl.value,
    );

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

    await _simulateAiResponse();
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
      final dio = dio_lib.Dio();
      final authController = Get.find<AuthController>();
      final token = await authController.getToken();

      debugPrint('[Upload] Token: ${token != null ? "Bearer ${token.substring(0, 20)}..." : "null"}');

      final formData = dio_lib.FormData.fromMap({
        'file': await dio_lib.MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ),
      });

      final url = '${AppConstants.planlyBaseUrl}/resource/oss/upload';
      debugPrint('[Upload] Request URL: $url');
      debugPrint('[Upload] Request headers: Authorization: ${token != null ? "Bearer $token" : "null"}');

      final response = await dio.post(
        url,
        data: formData,
        options: dio_lib.Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
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
        debugPrint('[Upload] Upload failed with code: ${response.data['code']}, msg: ${response.data['msg']}');
        showSnackBar('upload_failed'.tr, isError: true);
        removeSelectedFile();
      }
    } catch (e) {
      debugPrint('[Upload] Exception caught: $e');
      if (e is dio_lib.DioException) {
        debugPrint('[Upload] DioException type: ${e.type}');
        debugPrint('[Upload] DioException message: ${e.message}');
        debugPrint('[Upload] DioException response: ${e.response?.data}');
        debugPrint('[Upload] DioException status code: ${e.response?.statusCode}');
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

  Future<void> _simulateAiResponse() async {
    isTyping.value = true;
    _scrollToBottom();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final session = await isar.chatSessions.get(currentSessionId.value!);
    if (session == null) {
      isTyping.value = false;
      return;
    }

    // 一次性发送所有 4 种卡片用于预览
    final messages = [
      ChatMessage(
        text: "这是您的日程安排，请确认",
        createdAt: DateTime.now(),
        sender: SenderType.bot,
        type: MessageType.scheduleConfirmation,
      ),
      ChatMessage(
        text: "这是您今天的专注时长统计",
        createdAt: DateTime.now(),
        sender: SenderType.bot,
        type: MessageType.focusDuration,
      ),
      ChatMessage(
        text: "这是为您拆解的任务清单",
        createdAt: DateTime.now(),
        sender: SenderType.bot,
        type: MessageType.scheduleBreakdown,
      ),
      ChatMessage(
        text: "这是您今天的时间轴安排",
        createdAt: DateTime.now(),
        sender: SenderType.bot,
        type: MessageType.timelineSchedule,
      ),
    ];

    await isar.writeTxn(() async {
      for (final msg in messages) {
        await isar.chatMessages.put(msg);
        session.messages.add(msg);
        await session.messages.save();
      }

      session.updatedAt = DateTime.now();
      await isar.chatSessions.put(session);
    });

    messages.forEach((msg) => this.messages.add(msg));
    isTyping.value = false;
    _scrollToBottom();
    loadSessions();
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
