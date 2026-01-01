import 'package:get_it/get_it.dart';
import 'package:jura/core/models/transaction.dart' show ListTransactionRequest;
import 'package:jura/features/chat/chat_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'chat_service.dart';
import 'chat_viewmodel.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  late ChatViewModel _viewModel;

  double _dragOffset = 0;
  static const double _cancelThreshold = 120;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _viewModel = GetIt.I<ChatViewModel>();
    _viewModel.addListener(_onStateChanged);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onStateChanged);
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
      final state = _viewModel.state;

      if (state is ChatProcessing || state is ChatReady) {
        _scrollToBottom();
      }

      // Update text controller with recognized speech
      if (state is ChatListening) {
        _textController.text = state.recognizedText;
        // Move cursor to end
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;
    _viewModel.sendMessage(text.trim());
    _textController.clear();
    _scrollToBottom();
  }

  void _handleStartListening() {
    _viewModel.startListening();
    setState(() {
      _dragOffset = 0;
    });
  }

  void _handleStopListening() {
    if (_dragOffset >= _cancelThreshold) {
      _viewModel.cancelListening();
      _textController.clear();
    } else {
      _viewModel.stopListening();
      // Text is already in the controller from state updates
    }
    setState(() {
      _dragOffset = 0;
    });
  }

  void _showTransactionDrawer(
    BuildContext context,
    ListTransactionRequest params,
  ) {
    openDrawer(
      transformBackdrop: false,
      context: context,
      builder: (context) =>
          TransactionDrawer(params: params, aiService: GetIt.I<ChatService>()),
      position: OverlayPosition.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = _viewModel.state;

    final history = _viewModel.messages;
    final currency = _viewModel.currency;

    final isProcessing = state is ChatProcessing;
    final isListening = state is ChatListening;
    final soundLevel = state is ChatListening ? state.soundLevel : 0.0;

    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Chat').h3,
          trailing: [
            CurrencyDropdown(
              currentCurrency: currency,
              onChanged: (currency) {
                _viewModel.updateCurrency(currency);
              },
            ),
            IconButton(
              variance: ButtonVariance.ghost,
              density: ButtonDensity.icon,
              icon: const Icon(RadixIcons.trash),
              onPressed: () {
                _viewModel.clearHistory();
              },
            ),
          ],
        ),
        Divider(),
      ],
      child: Column(
        children: [
          Expanded(
            child: state is ChatInitial
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RadixIcons.chatBubble,
                          size: 64,
                          color: theme.colorScheme.mutedForeground,
                        ),
                        const SizedBox(height: 16),
                        Text('Start a conversation with Jura AI').muted.small,
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    controller: _scrollController,
                    itemCount: history.length + (isProcessing ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == history.length) {
                        return const ChatLoadingBubble();
                      }

                      final message = history[index];
                      final isUser = message.role == 'user';

                      return ChatBubble(
                        message: message,
                        isUser: isUser,
                        onViewTransactions: message.transactionParams != null
                            ? () => _showTransactionDrawer(
                                context,
                                message.transactionParams!,
                              )
                            : null,
                      );
                    },
                  ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: isListening ? null : 0,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _dragOffset >= _cancelThreshold
                  ? theme.colorScheme.destructive.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _dragOffset >= _cancelThreshold ? Icons.cancel : Icons.mic,
                    size: 20,
                    color: _dragOffset >= _cancelThreshold
                        ? theme.colorScheme.destructive
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _dragOffset >= _cancelThreshold
                          ? 'Release to cancel'
                          : 'Listening... Drag up to cancel',
                      style: theme.typography.small.copyWith(
                        color: _dragOffset >= _cancelThreshold
                            ? theme.colorScheme.destructive
                            : theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isListening ? 12 : 0),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.foreground.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
              color: theme.colorScheme.background,
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: TextArea(
                    controller: _textController,
                    focusNode: _focusNode,
                    enabled: !isProcessing && !isListening,
                    onSubmitted: (value) {
                      _handleSendMessage(value);
                    },
                  ),
                ),
                Column(
                  spacing: 10,
                  children: [
                    IconButton(
                      icon: state is ChatProcessing
                          ? CircularProgressIndicator(
                              color: theme.colorScheme.primaryForeground,
                              size: 24,
                            )
                          : const Icon(RadixIcons.paperPlane),
                      variance: ButtonStyle.primaryIcon(),
                      enabled: !isProcessing,
                      onPressed: () => _handleSendMessage(_textController.text),
                    ),
                    MicrophoneButton(
                      isListening: isListening,
                      isProcessing: isProcessing,
                      soundLevel: soundLevel,
                      dragOffset: _dragOffset,
                      cancelThreshold: _cancelThreshold,
                      vsync: this,
                      onLongPressStart: () => _handleStartListening(),
                      onLongPressEnd: () => _handleStopListening(),
                      onDragUpdate: (offset) {
                        setState(() {
                          _dragOffset = offset;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
