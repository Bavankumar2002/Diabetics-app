import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/activity_model.dart';

class ChatProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<ChatMessage> _messages = [];
  List<String> _suggestedQuestions = [
    'What is the Rule of 15 for low blood sugar?',
    'What should my fasting blood sugar be?',
    'What South Indian foods are diabetes-friendly?',
    'How does walking after meals help?',
    'What is a healthy HbA1c target?'
  ];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ChatMessage> get messages => _messages;
  List<String> get suggestedQuestions => _suggestedQuestions;

  Future<void> loadChatHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.get(ApiConstants.getChatHistory);
      _isLoading = false;

      if (res['success'] == true && res['data'] != null) {
        final list = res['data']['history'] as List? ?? [];
        _messages = list.map((e) => ChatMessage.fromJson(e)).toList();

        // If history is empty, add friendly welcome message
        if (_messages.isEmpty) {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              message: "Hello! 👋 I am your Diacare AI Diabetes Health Assistant.\n\nI can assist you with nutritional guidance, understanding glucose readings, safe exercise tips, and healthy lifestyle habits.\n\nHow can I support your diabetes care today?",
              time: 'Now',
            ),
          );
        }
      }
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      if (_messages.isEmpty) {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            message: "Hello! 👋 I am your Diacare AI Diabetes Health Assistant.\n\nI can assist you with nutritional guidance, understanding glucose readings, safe exercise tips, and healthy lifestyle habits.\n\nHow can I support your diabetes care today?",
            time: 'Now',
          ),
        );
      }
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 1. Add user message locally
    _messages.add(ChatMessage(
      role: 'user',
      message: trimmed,
      time: 'Just now',
    ));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.post(ApiConstants.sendChatMessage, {
        'message': trimmed,
      });

      _isLoading = false;
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final replyText = data['reply'] ?? '';
        final isEmerg = data['is_emergency'] == true;

        if (data['suggested_questions'] is List) {
          _suggestedQuestions = List<String>.from(data['suggested_questions']);
        }

        _messages.add(ChatMessage(
          role: 'assistant',
          message: replyText,
          time: 'Just now',
          isEmergency: isEmerg,
        ));
      } else {
        _errorMessage = res['message'] ?? 'Failed to receive AI response';
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _messages.add(ChatMessage(
        role: 'assistant',
        message: "I am having trouble connecting to the network right now. Please ensure your connection is active and try again.\n\n*If you are feeling unwell, experiencing dizziness, confusion, or extreme thirst, please seek medical care immediately.*",
        time: 'Just now',
      ));
      notifyListeners();
    }
  }

  Future<void> clearHistory() async {
    try {
      await ApiService.post(ApiConstants.clearChatHistory, {});
      _messages = [
        ChatMessage(
          role: 'assistant',
          message: "Chat history has been cleared. How can I assist you today?",
          time: 'Now',
        ),
      ];
      notifyListeners();
    } catch (_) {}
  }
}
