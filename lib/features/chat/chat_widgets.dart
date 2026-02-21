import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:jura/core/models/transaction.dart';
import 'package:jura/core/utils/currencies.dart';
import 'package:jura/core/widgets/transaction_card.dart';
import 'package:jura/features/chat/chat_viewmodel.dart';
import 'package:jura/features/chat/chat_service.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  final VoidCallback? onViewTransactions;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.onViewTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ChatBubble(
        alignment: isUser
          ? AxisAlignmentDirectional.end
          : AxisAlignmentDirectional.start,
        color: isUser ? theme.colorScheme.primary : null,
        widthFactor: 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GptMarkdown(
              message.content,
              style: TextStyle(
                color: isUser ? theme.colorScheme.primaryForeground : null,
              ),
            ).small,
            if (!isUser && message.transactionParams != null) ...[
              const SizedBox(height: 12),
              OutlineButton(
                onPressed: onViewTransactions,
                density: ButtonDensity.dense,
                child: const Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text('View Transactions'),
                    Spacer(),
                    Icon(Icons.keyboard_arrow_right, size: 24),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ChatLoadingBubble extends StatelessWidget {
  const ChatLoadingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Card(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('Jura AI is typing...', style: theme.typography.small),
            ],
          ),
        ),
      ),
    );
  }
}

class MicrophoneButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final double soundLevel;
  final double dragOffset;
  final double cancelThreshold;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final Function(double)? onDragUpdate;
  final TickerProvider vsync;

  const MicrophoneButton({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.soundLevel,
    required this.dragOffset,
    required this.cancelThreshold,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.onDragUpdate,
    required this.vsync,
  });

  @override
  State<MicrophoneButton> createState() => _MicrophoneButtonState();
}

class _MicrophoneButtonState extends State<MicrophoneButton> {
  bool _hapticTriggered = false;

  @override
  void didUpdateWidget(MicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dragOffset > 0 && widget.dragOffset == 0) {
      _hapticTriggered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      enabled: !widget.isProcessing,
      onLongPressStart: (_) {
        _hapticTriggered = false;
        widget.onLongPressStart?.call();
      },
      onLongPressEnd: (_) {
        _hapticTriggered = false;
        widget.onLongPressEnd?.call();
      },
      onLongPressMoveUpdate: (details) {
        final offset = (-details.offsetFromOrigin.dy).clamp(
          0.0,
          double.infinity,
        );
        widget.onDragUpdate?.call(offset);

        // Trigger haptic feedback only once when threshold is crossed
        if (offset >= widget.cancelThreshold && !_hapticTriggered) {
          HapticFeedback.heavyImpact();
          _hapticTriggered = true;
        } else if (offset < widget.cancelThreshold) {
          _hapticTriggered = false;
        }
      },
      variance: ButtonStyle.ghostIcon(),
      icon: Icon(
        widget.isListening && widget.dragOffset >= widget.cancelThreshold
            ? Icons.close
            : Icons.mic,
        size: 24,
        color: widget.isListening && widget.dragOffset >= widget.cancelThreshold
            ? theme.colorScheme.destructive
            : theme.colorScheme.primary,
      ),
    );
  }
}

class TransactionDrawer extends StatefulWidget {
  final ListTransactionRequest params;
  final ChatService aiService;

  const TransactionDrawer({
    super.key,
    required this.params,
    required this.aiService,
  });

  @override
  State<TransactionDrawer> createState() => _TransactionDrawerState();
}

class _TransactionDrawerState extends State<TransactionDrawer> {
  late TransactionResponse _transactionResponse;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final response = await widget.aiService.fetchTransactions(
        filter: widget.params,
      );
      log('Fetched ${response.transactions.length} transactions');
      setState(() {
        _transactionResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Transactions', style: theme.typography.h4),
              Spacer(),
              Button.link(
                style: ButtonStyle.linkIcon(density: ButtonDensity.dense),
                child: const Icon(Icons.close),
                onPressed: () => closeDrawer(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildTransactionContent(theme)),
        ],
      ),
    );
  }

  Widget _buildTransactionContent(ThemeData theme) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Failed to load transactions: $_error',
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
      );
    }

    final transactions = _transactionResponse.transactions;

    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No transactions found for this request.',
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
      );
    }

    return SizedBox(
      height: 420,
      child: ListView.separated(
        padding: const EdgeInsets.all(6),
        itemCount: transactions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => TransactionCard(
          transaction: transactions[index],
          theme: theme,
          onTap: () {},
        ),
      ),
    );
  }
}

class CurrencyDropdown extends StatelessWidget {
  final String? currentCurrency;
  final Function(String) onChanged;

  const CurrencyDropdown({
    super.key,
    required this.currentCurrency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Select<String>(
      padding: EdgeInsets.all(8),
      itemBuilder: (context, item) {
        final selectedMap = currenciesMap[item]!;
        return Row(
          children: [
            Text(selectedMap.$1),
            const SizedBox(width: 8),
            Text(item),
          ],
        );
      },
      popup: SelectPopup.builder(
        searchPlaceholder: const Text('Search Currency by code or country'),
        builder: (context, searchQuery) {
          final filteredCurrency = currenciesMap.entries.where((entry) {
            return entry.key.toLowerCase().contains(
              searchQuery?.toLowerCase() ?? '',
            );
          });

          return SelectItemList(
            children: [
              for (final value in filteredCurrency)
                SelectItemButton(
                  value: value.key,
                  child: Row(
                    children: [
                      Text(value.value.$1),
                      const SizedBox(width: 8),
                      Expanded(child: Text("${value.value.$2} (${value.key})")),
                    ],
                  ),
                ),
            ],
          );
        },
      ).call,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      value: currentCurrency,
    );
  }
}

class DeleteHistoryButton extends StatelessWidget {
  const DeleteHistoryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
