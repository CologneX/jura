import 'package:flutter/material.dart';
import 'package:jura/models/transaction.dart';
import 'package:jura/utils/formatters.dart';
import 'package:jura/services/transaction_service.dart';
import 'package:jura/state/transaction_state.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  late TransactionState _transactionState;

  @override
  void initState() {
    super.initState();
    _transactionState = TransactionState(TransactionService());
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    await _transactionState.fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _transactionState,
          builder: (context, child) {
            // Loading state with skeleton
            if (_transactionState.isLoading) {
              return Skeletonizer(
                child: _buildContent(
                  theme: theme,
                  totalIncome: 0.0,
                  totalExpenses: 0.0,
                  transactions: [],
                  isLoading: true,
                ),
              );
            }

            // Error state
            if (_transactionState.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.destructive.withAlpha(20),
                        borderRadius: theme.radius,
                      ),
                      child: Icon(
                        LucideIcons.info,
                        size: 48,
                        color: theme.colorScheme.destructive,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: theme.textTheme.h4,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _transactionState.error ??
                            'Unable to load transactions',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShadButton(
                      onPressed: _loadTransactions,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            // Empty state
            if (_transactionState.transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.mutedForeground.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.inbox,
                        size: 56,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('No transactions yet', style: theme.textTheme.h4),
                    const SizedBox(height: 8),
                    Text(
                      'Start by adding your first transaction',
                      style: theme.textTheme.muted,
                    ),
                  ],
                ),
              );
            }

            // Content with transactions
            return _buildContent(
              theme: theme,
              totalIncome: _transactionState.totalIncome,
              totalExpenses: _transactionState.totalExpenses,
              transactions: _transactionState.transactions,
              isLoading: false,
              onRefresh: _loadTransactions,
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent({
    required ShadThemeData theme,
    required double totalIncome,
    required double totalExpenses,
    required List<Transaction> transactions,
    required bool isLoading,
    Future<void> Function()? onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: CustomScrollView(
        slivers: [
          // Summary cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overview', style: theme.textTheme.h3),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          theme: theme,
                          icon: LucideIcons.trendingUp,
                          title: 'Income',
                          amount: totalIncome,
                          isExpense: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          theme: theme,
                          icon: LucideIcons.trendingDown,
                          title: 'Expenses',
                          amount: totalExpenses,
                          isExpense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Transactions list header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text('Transactions', style: theme.textTheme.h4),
            ),
          ),
          // Transactions list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TransactionCard(
                    transaction: transactions[index],
                    theme: theme,
                    onTap: () => _showTransactionDetails(
                      context,
                      transactions[index],
                      theme,
                    ),
                  ),
                );
              }, childCount: transactions.length),
            ),
          ),
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    Transaction transaction,
    ShadThemeData theme,
  ) {
    showShadSheet(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (context) =>
          _TransactionDetailsSheet(transaction: transaction, theme: theme),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ShadThemeData theme;
  final IconData icon;
  final String title;
  final double amount;
  final bool isExpense;

  const _SummaryCard({
    required this.theme,
    required this.icon,
    required this.title,
    required this.amount,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? theme.colorScheme.destructive : Colors.green;
    // final bgColor = color.withAlpha(20);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: theme.radius,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  // color: bgColor,
                  borderRadius: theme.radius,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatCurrency(amount, currencyCode: 'USD'),
            style: theme.textTheme.h4.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatefulWidget {
  final Transaction transaction;
  final ShadThemeData theme;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.transaction,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.transaction.type.toLowerCase() == 'expense';
    final color = isExpense
        ? widget.theme.colorScheme.destructive
        : Colors.green;
    final bgColor = color.withAlpha(15);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: () {
        // Visual feedback for long press
        setState(() => _isPressed = true);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _isPressed = false);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: widget.theme.colorScheme.card,
          border: Border.all(
            color: _isPressed
                ? widget.theme.colorScheme.ring
                : widget.theme.colorScheme.border,
            width: _isPressed ? 2 : 1,
          ),
          borderRadius: widget.theme.radius,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: color.withAlpha(30),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon with background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: widget.theme.radius,
              ),
              child: Icon(
                isExpense ? LucideIcons.arrowDown : LucideIcons.arrowUp,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.transaction.category ?? 'Uncategorized',
                    style: widget.theme.textTheme.muted.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.theme.colorScheme.foreground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        widget.transaction.formattedDate,
                        style: widget.theme.textTheme.small.copyWith(
                          color: widget.theme.colorScheme.mutedForeground,
                        ),
                      ),
                      if (widget.transaction.notes.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: widget.theme.colorScheme.mutedForeground,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.transaction.notes,
                            style: widget.theme.textTheme.small.copyWith(
                              color: widget.theme.colorScheme.mutedForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Amount
            Text(
              '${isExpense ? '−' : '+'}${formatCurrency(widget.transaction.amount.abs(), currencyCode: widget.transaction.currency)}',
              style: widget.theme.textTheme.muted.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionDetailsSheet extends StatelessWidget {
  final Transaction transaction;
  final ShadThemeData theme;

  const _TransactionDetailsSheet({
    required this.transaction,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type.toLowerCase() == 'expense';
    final color = isExpense ? theme.colorScheme.destructive : Colors.green;

    return ShadSheet(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: theme.radius,
            ),
            child: Icon(
              isExpense ? LucideIcons.arrowDown : LucideIcons.arrowUp,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transaction.category ?? 'Transaction',
                  style: theme.textTheme.h4,
                ),
                Text(
                  transaction.displayType,
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(
              formatCurrency(transaction.amount, currencyCode: transaction.currency),
              style: theme.textTheme.h3.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            _DetailItem(
              theme: theme,
              icon: LucideIcons.calendar,
              label: 'Date',
              value: transaction.formattedDate,
            ),
            _DetailItem(
              theme: theme,
              icon: LucideIcons.creditCard,
              label: 'Payment Method',
              value: transaction.paymentMethod,
            ),
            if (transaction.subcategory != null)
              _DetailItem(
                theme: theme,
                icon: LucideIcons.tag,
                label: 'Subcategory',
                value: transaction.subcategory!,
              ),
            if (transaction.notes.isNotEmpty) ...[
              SizedBox(
                height: 1,
                child: Container(color: theme.colorScheme.border),
              ),
              _DetailItem(
                theme: theme,
                icon: LucideIcons.fileText,
                label: 'Notes',
                value: transaction.notes,
                isLast: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final ShadThemeData theme;
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailItem({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.mutedForeground),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.muted.copyWith(
                  color: theme.colorScheme.foreground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
