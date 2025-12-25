import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:jura/core/models/transaction.dart';
import 'package:jura/core/services/user_service.dart';
import 'chat_service.dart';

/// Chat States
abstract class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {}

class ChatReady extends ChatState {
  const ChatReady();
}

class ChatListening extends ChatState {
  final double soundLevel;
  final String recognizedText;

  const ChatListening({
    required this.soundLevel,
    this.recognizedText = '',
  });
}

class ChatProcessing extends ChatState {
  const ChatProcessing();
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});
}

/// Chat Message Model
class ChatMessage {
  final String role; // 'user', 'model', 'loading'
  final String content;
  final ListTransactionRequest? transactionParams;

  const ChatMessage({
    required this.role,
    required this.content,
    this.transactionParams,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'content': content,
      if (transactionParams != null) 'transactionParams': transactionParams,
    };
  }
}

class ChatViewModel extends ChangeNotifier {
  final ChatService _service;
  final stt.SpeechToText _speechToText;
  final UserService _userService;
  
  List<Map<String, dynamic>> _serviceHistory = [];
  List<ChatMessage> _messages = [];
  bool _isSpeechAvailable = false;

  ChatViewModel(this._service, this._speechToText, this._userService) {
    _userService.addListener(_onUserServiceChanged);
  }

  ChatState _state = ChatInitial();
  ChatState get state => _state;

  List<ChatMessage> get messages => _messages;
  bool get isSpeechAvailable => _isSpeechAvailable;
  String? get currency => _userService.currentUser?.primaryCurrency;

  void _onUserServiceChanged() {
    notifyListeners();
  }

  void _updateState(ChatState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> initialize() async {
    try {
      _isSpeechAvailable = await _speechToText.initialize(
        onError: (error) => log('Speech error: $error'),
        onStatus: (status) => log('Speech status: $status'),
      );

      _updateState(const ChatReady());
    } catch (e) {
      log('Failed to initialize speech: $e');
      _isSpeechAvailable = false;
      _updateState(const ChatReady());
    }
  }

  void startListening() {
    if (_state is! ChatReady) return;
    
    _updateState(
      const ChatListening(
        soundLevel: 0.0,
        recognizedText: '',
      ),
    );

    _speechToText.listen(
      onResult: (result) {
        if (_state is ChatListening) {
          final currentState = _state as ChatListening;
          _updateState(
            ChatListening(
              soundLevel: currentState.soundLevel,
              recognizedText: result.recognizedWords,
            ),
          );
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  void stopListening() {
    if (_state is! ChatListening) return;
    _speechToText.stop();
    _updateState(const ChatReady());
  }

  void cancelListening() {
    if (_state is! ChatListening) return;
    _speechToText.cancel();
    _updateState(const ChatReady());
  }

  void updateSoundLevel(double level) {
    if (_state is ChatListening) {
      _updateState(
        ChatListening(
          soundLevel: level,
          recognizedText: (_state as ChatListening).recognizedText,
        ),
      );
    }
  }

  Future<void> sendMessage(String message) async {
    _messages = [
      ..._messages,
      ChatMessage(role: 'user', content: message),
    ];

    _updateState(const ChatProcessing());

    try {
      final response = await _service.processConversation(message, _serviceHistory);

      _messages = [
        ..._messages,
        ChatMessage(
          role: 'model',
          content: response.message,
          transactionParams: response.transactionSearchParameters,
        ),
      ];

      _serviceHistory = response.history.map((msg) => msg.toJson()).toList();

      _updateState(const ChatReady());
    } catch (e) {
      _messages = [
        ..._messages,
        ChatMessage(role: 'model', content: 'Error: ${e.toString()}'),
      ];

      _updateState(ChatError(message: e.toString()));
      
      // After showing error, we can go back to ready so user can try again
      // or just stay in error state if the UI handles it.
      // The previous code was immediately going back to ChatReady.
      _updateState(const ChatReady());
    }
  }

  void clearHistory() {
    _serviceHistory.clear();
    _messages.clear();
    _updateState(const ChatReady());
  }

  Future<void> updateCurrency(String currency) async {
    try {
      log('Updating currency to $currency');
      await _userService.updateCurrency(currency);
      notifyListeners();
    } catch (e) {
      log('Failed to update currency: $e');
      _updateState(ChatError(message: e.toString()));
    }
  }

  stt.SpeechToText get speechToText => _speechToText;
  List<Map<String, dynamic>> get history => _serviceHistory;

  @override
  void dispose() {
    _userService.removeListener(_onUserServiceChanged);
    super.dispose();
  }
}
