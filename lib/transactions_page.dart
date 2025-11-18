import 'package:flutter/material.dart';
import 'package:jura/models/transaction.dart';
import 'package:jura/utils/formatters.dart';
import 'package:jura/services/transaction_service.dart';
import 'package:jura/state/transaction_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
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
    return Scaffold(
      // appBar: AppBar(
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh),
      //       onPressed: _loadTransactions,
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _transactionState,
          builder: (context, child) {
            if (_transactionState.isLoading) {
              return Skeletonizer(
                child: Column(
                  children: [
                    // Skeleton Summary cards
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Income',
                              amount: 0.0,
                              isExpense: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Expenses',
                              amount: 0.0,
                              isExpense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Skeleton transactions list
                    Expanded(
                      child: ListView.builder(
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.trending_down),
                            ),
                            title: const Text('Transaction Category'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                SizedBox(height: 4),
                                Text('Date'),
                              ],
                            ),
                            trailing: const Text('-\$0.00'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            if (_transactionState.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading transactions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _transactionState.error ?? 'Unknown error occurred',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadTransactions,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (_transactionState.transactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      color: Theme.of(context).colorScheme.outline,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Summary cards
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Income',
                          amount: _transactionState.totalIncome,
                          isExpense: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Expenses',
                          amount: _transactionState.totalExpenses,
                          isExpense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                // Transactions list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadTransactions,
                    child: ListView.builder(
                      itemCount: _transactionState.transactions.length,
                      itemBuilder: (context, index) {
                        return _TransactionTile(
                          transaction: _transactionState.transactions[index],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Navigate to create transaction page
      //     MotionToast.info(
      //       title: const Text('Coming Soon'),
      //       description: const Text('Create transaction feature coming soon'),
      //     ).show(context);
      //   },
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final bool isExpense;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpense
        ? Theme.of(context).colorScheme.error
        : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency(amount, currencyCode: 'USD'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type.toLowerCase() == 'expense';
    final color = isExpense
        ? Theme.of(context).colorScheme.error
        : Colors.green;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isExpense ? Icons.trending_down : Icons.trending_up,
          color: color,
        ),
      ),
      title: Text(
        transaction.category ?? 'Uncategorized',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            transaction.formattedDate,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (transaction.notes.isNotEmpty)
            Text(
              transaction.notes,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Text(
        '${isExpense ? '-' : '+'}${formatCurrency(transaction.amount.abs(), currencyCode: transaction.currency)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        // Show transaction details
        showDialog(
          context: context,
          builder: (context) =>
              _TransactionDetailsDialog(transaction: transaction),
        );
      },
    );
  }
}

class _TransactionDetailsDialog extends StatelessWidget {
  final Transaction transaction;

  const _TransactionDetailsDialog({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(transaction.category ?? 'Transaction'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Type', value: transaction.displayType),
              _DetailRow(label: 'Amount', value: transaction.formattedAmount),
              _DetailRow(label: 'Date', value: transaction.formattedDate),
              if (transaction.subcategory != null)
                _DetailRow(
                  label: 'Subcategory',
                  value: transaction.subcategory!,
                ),
              _DetailRow(
                label: 'Payment Method',
                value: transaction.paymentMethod,
              ),
              if (transaction.notes.isNotEmpty)
                _DetailRow(label: 'Notes', value: transaction.notes),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
