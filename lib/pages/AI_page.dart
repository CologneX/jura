import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:jura/services/transaction_service.dart';
import 'package:jura/services/user_service.dart';
import 'package:jura/models/transaction.dart';
import 'package:jura/widgets/transaction_card.dart';
import 'package:jura/utils/currencies.dart';
import 'package:jura/main.dart';
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
  final List<Map<String, dynamic>> _messages = [];
  String _currencySearchValue = '';

  UserService get _userService => getIt<UserService>();

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

  Map<String, String> get _filteredCurrencies {
    return {
      for (final entry in currenciesMap.entries)
        if (entry.key.toLowerCase().contains(
              _currencySearchValue.toLowerCase(),
            ) ||
            entry.value.$2.toLowerCase().contains(
              _currencySearchValue.toLowerCase(),
            ))
          entry.key: entry.key,
    };
  }

  Future<void> _saveCurrency(String currency) async {
    try {
      if (!mounted) return;
      await _userService.updateCurrency(currency);
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('Success'),
          description: Text('Currency changed to $currency'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Error'),
          description: Text('Error: $e'),
        ),
      );
    }
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
        _messages.add({
          'role': 'model',
          'content': response.message,
          'transactionParams': response.transactionSearchParameters,
        });
        _history = response.history.map((msg) => msg.toJson()).toList();
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

  void _openTransactionsSheet(ListTransactionRequest params) {
    final fetchFuture = _transactionService.fetchTransactions(filter: params);

    showShadSheet(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (context) {
        final theme = ShadTheme.of(context);
        return ShadSheet(
          title: const Text('Transactions'),
          child: FutureBuilder<TransactionResponse>(
            future: fetchFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Failed to load transactions: ${snapshot.error}',
                    style: theme.textTheme.muted,
                  ),
                );
              }

              final transactions = snapshot.data?.transactions ?? [];

              if (transactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No transactions found for this request.',
                    style: theme.textTheme.muted,
                  ),
                );
              }

              return SizedBox(
                height: 420,
                child: ListView.separated(
                  padding: const EdgeInsets.all(6),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => TransactionCard(
                    transaction: transactions[index],
                    theme: theme,
                    onTap: () {},
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _rippleController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _chatBubble(
    Map<String, dynamic> msg,
    bool isUser,
    ShadThemeData theme,
  ) {
    final content = msg['content'] as String? ?? '';
    final params = msg['transactionParams'] as ListTransactionRequest?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: ShadCard(
            backgroundColor: isUser ? theme.colorScheme.primary : null,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GptMarkdown(content),
                if (!isUser && params != null) ...[
                  const SizedBox(height: 12),
                  ShadButton.outline(
                    onPressed: () => _openTransactionsSheet(params),
                    child: const Text('View transactions'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chatLoadingBubble(ShadThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: const ShadCard(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
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
                  Text('Jura AI', style: theme.textTheme.h3),
                  Spacer(),
                  SizedBox(
                    width: 60,
                    child: ShadSelect<String>.withSearch(
                      minWidth: 0,
                      placeholder: const Text('Currency'),
                      searchPlaceholder: const Text('Search...'),
                      onSearchChanged: (value) =>
                          setState(() => _currencySearchValue = value),
                      options: [
                        if (_filteredCurrencies.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('No currency found'),
                          ),
                        ..._filteredCurrencies.entries.map((entry) {
                          final currencyCode = entry.key;
                          final (flag, name) = currenciesMap[currencyCode]!;
                          return Offstage(
                            offstage: !_filteredCurrencies.containsKey(
                              currencyCode,
                            ),
                            child: ShadOption(
                              value: currencyCode,
                              child: Text('$flag $currencyCode - $name'),
                            ),
                          );
                        }),
                      ],
                      selectedOptionBuilder: (context, value) {
                        final (flag, _) = currenciesMap[value]!;
                        return Text(flag);
                      },
                      onChanged: (value) {
                        if (value != null) {
                          _saveCurrency(value);
                        }
                      },
                      initialValue: _userService.currentUser?.primaryCurrency,
                    ),
                  ),
                  SizedBox(width: 12),
                  ShadButton.outline(
                    height: 36,
                    leading: const Icon(Icons.replay_outlined),
                    onPressed: _messages.isEmpty ? null : _clearHistory,
                    enabled: _messages.isNotEmpty,
                    child: const Text('Reset Chat'),
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
                          return _chatLoadingBubble(theme);
                        } else {
                          return _chatBubble(msg, isUser, theme);
                        }
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
                        onLongPressStart: !_isProcessing
                            ? (_) => _startListening()
                            : null,
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
                                  _dragOffset = details.offsetFromOrigin.dy
                                      .clamp(0.0, double.infinity);
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
                                    ? theme.colorScheme.destructive.withOpacity(
                                        0.1,
                                      )
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
                                    _isListening &&
                                        _dragOffset >= _cancelThreshold
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
                        enabled: !_isProcessing,
                        onPressed: _isProcessing ? null : _sendMessage,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
