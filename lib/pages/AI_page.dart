import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:jura/services/transaction_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> with TickerProviderStateMixin {
  late stt.SpeechToText _speechToText;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isListening = false;
  double _soundLevel = 0.0;
  bool _isProcessing = false;
  late AnimationController _rippleController;
  final TransactionService _transactionService = TransactionService();
  double _dragOffset = 0.0;
  final double _cancelThreshold = 100.0;
  String _textBeforeListening = '';

  List<Map<String, dynamic>> _history = [];
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      await _speechToText.initialize(
        onError: (error) {
          log('Error: $error');
          setState(() => _isListening = false);
        },
        onStatus: (status) {
          log('Status: $status');
        },
      );
    } catch (e) {
      log('Failed to initialize speech to text: $e');
    }
  }

  void _startListening() async {
    if (!_isListening && _speechToText.isAvailable) {
      HapticFeedback.heavyImpact();
      _textBeforeListening = _controller.text;

      setState(() => _isListening = true);

      _speechToText.listen(
        onResult: (result) {
          setState(() {
            String newText = result.recognizedWords;
            if (_textBeforeListening.isNotEmpty) {
              _controller.text = "$_textBeforeListening $newText";
            } else {
              _controller.text = newText;
            }
          });
        },
        onSoundLevelChange: (level) {
          setState(() {
            _soundLevel = level;
          });
          _rippleController.forward(from: 0.0);
        },
        localeId: 'en_US',
      );
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      HapticFeedback.mediumImpact();
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
        _dragOffset = 0.0;
      });
    }
  }

  void _cancelListening() async {
    if (_isListening) {
      await _speechToText.cancel();
      HapticFeedback.heavyImpact();
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
        _dragOffset = 0.0;
        _controller.text = _textBeforeListening; // Revert text
      });
    }
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
      _messages.clear();
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _messages.add({'role': 'loading', 'content': ''});
      _isProcessing = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final response = await _transactionService.processConversation(
        text,
        _history,
      );

      setState(() {
        _messages.removeLast();
        _messages.add({'role': 'model', 'content': response['message']});
        _history = List<Map<String, dynamic>>.from(response['history']);
        _isProcessing = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add({'role': 'model', 'content': 'Error: ${e.toString()}'});
        _isProcessing = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _rippleController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Jura AI', style: theme.textTheme.h4),
                ShadIconButton.ghost(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _messages.isEmpty ? null : _clearHistory,
                ),
              ],
            ),
          ),
          // Chat Area
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Start a conversation with Jura AI',
                      style: theme.textTheme.muted,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      final isLoading = msg['role'] == 'loading';

                      if (isLoading) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.8,
                              ),
                              child: const ShadCard(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Align(
                          alignment:
                              isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                            ),
                            child: ShadCard(
                              backgroundColor: isUser
                                  ? theme.colorScheme.primary
                                  : null,
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                msg['content']!,
                                style: theme.textTheme.p.copyWith(
                                  color: isUser
                                      ? theme.colorScheme.primaryForeground
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: ShadTextarea(
                      controller: _controller,
                      placeholder: const Text('Type your message...'),
                      resizable: false,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mic Button
                    GestureDetector(
                      onLongPressStart:
                          !_isProcessing ? (_) => _startListening() : null,
                      onLongPressEnd: !_isProcessing
                          ? (_) {
                              if (_dragOffset >= _cancelThreshold) {
                                _cancelListening();
                              } else {
                                _stopListening();
                              }
                            }
                          : null,
                      onLongPressMoveUpdate: _isListening
                          ? (details) {
                              setState(() {
                                _dragOffset = details.offsetFromOrigin.dy.clamp(
                                  0.0,
                                  double.infinity,
                                );
                              });

                              if (_dragOffset >= _cancelThreshold &&
                                  details.offsetFromOrigin.dy <
                                      _cancelThreshold + 5) {
                                HapticFeedback.heavyImpact();
                              }
                            }
                          : null,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isListening)
                            AnimatedBuilder(
                              animation: _rippleController,
                              builder: (context, child) {
                                final rippleOpacity =
                                    (1.0 - _rippleController.value).clamp(
                                      0.0,
                                      1.0,
                                    );
                                final rippleScale =
                                    1.0 +
                                    (_rippleController.value * 0.5) +
                                    (_soundLevel / 100.0 * 0.3);
                                return Opacity(
                                  opacity: rippleOpacity,
                                  child: Transform.scale(
                                    scale: rippleScale,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _dragOffset >= _cancelThreshold
                                  ? theme.colorScheme.destructive
                                      .withOpacity(0.1)
                                  : theme.colorScheme.primary.withOpacity(
                                      0.1,
                                    ),
                            ),
                            child: Icon(
                              _isListening && _dragOffset >= _cancelThreshold
                                  ? Icons.close
                                  : Icons.mic,
                              size: 24,
                              color:
                                  _isListening && _dragOffset >= _cancelThreshold
                                      ? theme.colorScheme.destructive
                                      : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Send Button
                    ShadIconButton(
                      onPressed: _isProcessing ? null : _sendMessage,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
