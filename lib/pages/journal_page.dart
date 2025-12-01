import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:jura/services/tab_navigation_service.dart';
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
  late ScrollController _scrollController;
  StreamSubscription? _tabSubscription;

  @override
  void initState() {
    super.initState();
    _transactionState = TransactionState(TransactionService());
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadTransactions();

    _tabSubscription = GetIt.I<TabNavigationService>().onTabChanged.listen((index) {
      if (index == 0 && mounted) {
        _loadTransactions();
      }
    });
  }

  @override
  void dispose() {
    _tabSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions({ListTransactionRequest? filter}) async {
    await _transactionState.fetchTransactions(filter: filter);
  }

  void _onScroll() {
    final currentIndex = (_scrollController.position.pixels /
            (_scrollController.position.maxScrollExtent /
                _transactionState.transactions.length))
        .floor();

    // Check if we've reached a multiple of 10 and there's more data to fetch
    if (currentIndex > 0 &&
        currentIndex % 10 == 0 &&
        _transactionState.hasMoreData &&
        !_transactionState.isLoadingMore) {
      _transactionState.fetchMoreTransactions();
    }
  }

  void _showFilterSheet(BuildContext context, ShadThemeData theme) {
    showShadSheet(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (context) => _FilterSheet(
        theme: theme,
        onApplyFilters: (filter) => _loadTransactions(filter: filter),
      ),
    );
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

            // Content with transactions (or empty state with summary cards)
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
        controller: _scrollController,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transactions', style: theme.textTheme.h4),
                  ShadIconButton.ghost(
                    icon: Icon(LucideIcons.settings),
                    onPressed: () => _showFilterSheet(context, theme),
                  ),
                ],
              ),
            ),
          ),
          // Transactions list or empty state
          if (transactions.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
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
                ),
              ),
            )
          else
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
          // Loading indicator for pagination
          if (_transactionState.isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ShadTheme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
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

class _FilterSheet extends StatefulWidget {
  final ShadThemeData theme;
  final Function(ListTransactionRequest?) onApplyFilters;

  const _FilterSheet({
    required this.theme,
    required this.onApplyFilters,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _selectedType;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _minAmountText;
  String? _maxAmountText;

  void _applyFilters() {
    final filter = ListTransactionRequest(
      type: _selectedType,
      category: _selectedCategory,
      startDate: _startDate,
      endDate: _endDate,
      minAmount: _minAmountText != null ? double.tryParse(_minAmountText!) : null,
      maxAmount: _maxAmountText != null ? double.tryParse(_maxAmountText!) : null,
    );

    widget.onApplyFilters(filter);
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _selectedType = null;
      _selectedCategory = null;
      _startDate = null;
      _endDate = null;
      _minAmountText = null;
      _maxAmountText = null;
    });
    widget.onApplyFilters(null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ShadSheet(
      title: const Text('Filters'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              // Type filter
              Text('Type', style: widget.theme.textTheme.small),
              ShadSelect<String>(
                placeholder: const Text('All types'),
                initialValue: _selectedType,
                options: const [
                  ShadOption(value: 'income', child: Text('Income')),
                  ShadOption(value: 'expense', child: Text('Expense')),
                ],
                selectedOptionBuilder: (context, value) => Text(value),
                onChanged: (value) => setState(() => _selectedType = value),
              ),
              const SizedBox(height: 4),
              // Category filter
              Text('Category', style: widget.theme.textTheme.small),
              ShadInput(
                placeholder: const Text('Filter by category'),
                onChanged: (value) => setState(() => _selectedCategory = value.isEmpty ? null : value),
              ),
              const SizedBox(height: 4),
              // Date range
              Text('Date Range', style: widget.theme.textTheme.small),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      child: Text(
                        _startDate != null
                            ? 'From: ${_startDate!.toString().split(' ')[0]}'
                            : 'From',
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ShadButton.outline(
                      child: Text(
                        _endDate != null
                            ? 'To: ${_endDate!.toString().split(' ')[0]}'
                            : 'To',
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Amount range
              Text('Amount Range', style: widget.theme.textTheme.small),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: ShadInput(
                      placeholder: const Text('Min'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() => _minAmountText = value.isEmpty ? null : value),
                    ),
                  ),
                  Expanded(
                    child: ShadInput(
                      placeholder: const Text('Max'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() => _maxAmountText = value.isEmpty ? null : value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      child: const Text('Reset'),
                      onPressed: _resetFilters,
                    ),
                  ),
                  Expanded(
                    child: ShadButton(
                      child: const Text('Apply'),
                      onPressed: _applyFilters,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
