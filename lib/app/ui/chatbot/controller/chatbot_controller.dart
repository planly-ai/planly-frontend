import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar_community/isar.dart';
import 'package:planly_ai/app/data/db.dart';
import 'package:planly_ai/main.dart'; // To access the global `isar` instance
import 'package:planly_ai/app/services/asr_service.dart';
import 'package:planly_ai/app/services/audio_recording_service.dart';
import 'package:planly_ai/app/utils/show_snack_bar.dart';

class ChatbotController extends GetxController {
  // Observables
  var sessions = <ChatSession>[].obs;
  var currentSessionId = Rxn<int>();
  var messages = <ChatMessage>[].obs;

  var textController = TextEditingController();
  var scrollController = ScrollController();
  var isTyping = false.obs;
  var isRecognizing = false.obs;

  // Services
  final AsrService _asrService = AsrService();
  final AudioRecordingService _audioService = AudioRecordingService();

  // Voice Recording State
  var isRecording = false.obs;
  var isCancellingRecording = false.obs;
  double _startRecordDy = 0;

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

  // Send a text message
  Future<void> sendMessage() async {
    if (textController.text.trim().isEmpty) return;

    final text = textController.text.trim();
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
    );

    await isar.writeTxn(() async {
      await isar.chatMessages.put(userMsg);
      session.messages.add(userMsg);
      await session.messages.save();

      session.updatedAt = DateTime.now();
      await session.messages.load();
      if (session.messages.length == 1 || session.title == 'New Chat'.tr) {
        session.title = text.length > 20 ? '${text.substring(0, 20)}...' : text;
      }
      await isar.chatSessions.put(session);
    });

    messages.add(userMsg);
    _scrollToBottom();
    loadSessions();

    await _simulateAiResponse();
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

    // TODO: Backend AI response integration here
    final aiMsg = ChatMessage(
      text: "TODO: This is a placeholder for the actual AI response.",
      createdAt: DateTime.now(),
      sender: SenderType.bot,
    );

    await isar.writeTxn(() async {
      await isar.chatMessages.put(aiMsg);
      session.messages.add(aiMsg);
      await session.messages.save();

      session.updatedAt = DateTime.now();
      await isar.chatSessions.put(session);
    });

    messages.add(aiMsg);
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
      showSnackBar(
        'voice_permission_denied'.tr,
        isError: true,
      );
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
        showSnackBar(
          'voice_recognition_failed'.tr,
          isError: true,
        );
      }
    }
  }
}
