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
  final List<ChatMessage> history;
  final bool isSpeechAvailable;
  final String? currency;

  const ChatReady({
    required this.history,
    required this.isSpeechAvailable,
    this.currency,
  });
}

class ChatListening extends ChatState {
  final List<ChatMessage> history;
  final double soundLevel;
  final String recognizedText;

  const ChatListening({
    required this.history,
    required this.soundLevel,
    this.recognizedText = '',
  });
}

class ChatProcessing extends ChatState {
  final List<ChatMessage> history;

  const ChatProcessing({required this.history});
}

class ChatError extends ChatState {
  final String message;
  final List<ChatMessage> history;

  const ChatError({required this.message, required this.history});
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
  List<Map<String, dynamic>> _history = [];

  ChatViewModel(this._service, this._speechToText, this._userService) {
    _userService.addListener(_onUserServiceChanged);
  }

  ChatState _state = ChatInitial();
  ChatState get state => _state;

  void _onUserServiceChanged() {
    if (_state is ChatReady) {
      final currentState = _state as ChatReady;
      _updateState(
        ChatReady(
          history: currentState.history,
          isSpeechAvailable: currentState.isSpeechAvailable,
          currency: _userService.currentUser?.primaryCurrency,
        ),
      );
    }
  }

  void _updateState(ChatState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> initialize() async {
    try {
      final isAvailable = await _speechToText.initialize(
        onError: (error) => log('Speech error: $error'),
        onStatus: (status) => log('Speech status: $status'),
      );

      final userCurrency = _userService.currentUser?.primaryCurrency;

      _updateState(
        ChatReady(
          history: const [],
          isSpeechAvailable: isAvailable,
          currency: userCurrency,
        ),
      );
    } catch (e) {
      log('Failed to initialize speech: $e');
      _updateState(
        ChatReady(
          history: const [],
          isSpeechAvailable: false,
          currency: _userService.currentUser?.primaryCurrency,
        ),
      );
    }
  }

  void startListening() {
    if (_state is! ChatReady) return;
    final currentState = _state as ChatReady;
    _updateState(
      ChatListening(
        history: currentState.history,
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
              history: currentState.history,
              soundLevel: currentState.soundLevel,
              recognizedText: result.recognizedWords,
            ),
          );
        }
      },
      // listenMode: stt.ListenMode.dictation,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  void stopListening() {
    if (_state is! ChatListening) return;
    final currentState = _state as ChatListening;
    _speechToText.stop();
    _updateState(
      ChatReady(
        history: currentState.history,
        isSpeechAvailable: true,
        currency: _userService.currentUser?.primaryCurrency,
      ),
    );
  }

  void cancelListening() {
    if (_state is! ChatListening) return;
    final currentState = _state as ChatListening;
    _speechToText.cancel();
    _updateState(
      ChatReady(
        history: currentState.history,
        isSpeechAvailable: true,
        currency: _userService.currentUser?.primaryCurrency,
      ),
    );
  }

  void updateSoundLevel(double level) {
    if (_state is ChatListening) {
      final currentState = _state as ChatListening;
      _updateState(
        ChatListening(history: currentState.history, soundLevel: level),
      );
    }
  }

  Future<void> sendMessage(String message) async {
    List<ChatMessage> currentHistory = [];

    if (_state is ChatReady) {
      currentHistory = (_state as ChatReady).history;
    } else if (_state is ChatError) {
      currentHistory = (_state as ChatError).history;
    }

    final updatedHistory = [
      ...currentHistory,
      ChatMessage(role: 'user', content: message),
    ];

    _updateState(ChatProcessing(history: updatedHistory));

    try {
      final response = await _service.processConversation(message, _history);

      final finalHistory = [
        ...updatedHistory,
        ChatMessage(
          role: 'model',
          content: response.message,
          transactionParams: response.transactionSearchParameters,
        ),
      ];

      _history = response.history.map((msg) => msg.toJson()).toList();

      _updateState(
        ChatReady(
          history: finalHistory,
          isSpeechAvailable: true,
          currency: _userService.currentUser?.primaryCurrency,
        ),
      );
    } catch (e) {
      _updateState(ChatError(message: e.toString(), history: updatedHistory));

      final errorHistory = [
        ...updatedHistory,
        ChatMessage(role: 'model', content: 'Error: ${e.toString()}'),
      ];

      _updateState(
        ChatReady(
          history: errorHistory,
          isSpeechAvailable: true,
          currency: _userService.currentUser?.primaryCurrency,
        ),
      );
    }
  }

  void clearHistory() {
    _history.clear();
    _updateState(
      ChatReady(
        history: const [],
        isSpeechAvailable: true,
        currency: _userService.currentUser?.primaryCurrency,
      ),
    );
  }

  Future<void> updateCurrency(String currency) async {
    try {
      log('Updating currency to $currency');
      await _userService.updateCurrency(currency);
      if (_state is ChatReady) {
        final currentState = _state as ChatReady;
        _updateState(
          ChatReady(
            history: currentState.history,
            isSpeechAvailable: currentState.isSpeechAvailable,
            currency: _userService.currentUser?.primaryCurrency,
          ),
        );
      }
    } catch (e) {
      log('Failed to update currency: $e');
      _updateState(ChatError(message: e.toString(), history: const []));
    }
  }

  stt.SpeechToText get speechToText => _speechToText;
  List<Map<String, dynamic>> get history => _history;

  @override
  void dispose() {
    _userService.removeListener(_onUserServiceChanged);
    super.dispose();
  }
}
