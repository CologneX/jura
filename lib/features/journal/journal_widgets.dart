import 'package:jura/core/models/transaction.dart';
import 'package:jura/core/utils/formatters.dart';
import 'package:jura/core/services/user_service.dart';
import 'package:jura/core/widgets/toast.dart';
import 'package:get_it/get_it.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Summary card widget for income and expenses
class SummaryCard extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String title;
  final double amount;
  final bool isExpense;
  final String currency;

  const SummaryCard({
    super.key,
    required this.theme,
    required this.icon,
    required this.title,
    required this.amount,
    required this.isExpense,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? theme.colorScheme.destructive : Colors.green;
    return Card(
      padding: const EdgeInsets.all(16),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.foreground.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      borderColor: color.withValues(alpha: 0.39),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const Gap(12),
              Text(title).small().muted().semiBold(),
            ],
          ),
          const Gap(12),
          Text(
            formatCurrency(amount, currencyCode: currency),
            style: TextStyle(color: color),
          ).h4().bold(),
        ],
      ),
    );
  }
}

/// Transaction details bottom sheet
class TransactionDetailsSheet extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailsSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.type.toLowerCase() == 'expense';
    final color = isExpense ? theme.colorScheme.destructive : Colors.green;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transaction Details', style: theme.typography.h4),
              GhostButton(
                density: ButtonDensity.icon,
                onPressed: () => closeDrawer(context),
                child: const Icon(LucideIcons.x, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Card(
            borderColor: color.withValues(alpha: 0.31),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.foreground.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge and category
                Row(
                  children: [
                    PrimaryBadge(
                      style: ButtonStyle.primary(
                        density: ButtonDensity.dense,
                        size: ButtonSize.small,
                      ).withBackgroundColor(color: color),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpense
                                ? LucideIcons.arrowDownRight
                                : LucideIcons.arrowUpRight,
                            size: 20,
                            color: theme.colorScheme.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(transaction.displayType).semiBold,
                        ],
                      ),
                    ),
                    if (transaction.category != null) ...[
                      const SizedBox(width: 8),
                      SecondaryBadge(
                        style: ButtonStyle.outline(
                          density: ButtonDensity.dense,
                          size: ButtonSize.small,
                        ),
                        child: Text(transaction.category!).semiBold,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Amount
                Text(
                  formatCurrency(
                    transaction.amount,
                    currencyCode: transaction.currency,
                  ),
                  style: TextStyle(color: color),
                ).bold.xLarge,
                const SizedBox(height: 4),
                Text(
                  transaction.formattedDate,
                  style: theme.typography.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),

          // Additional details
          if (transaction.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            DetailRow(
              theme: theme,
              icon: LucideIcons.fileText,
              label: 'Notes',
              value: transaction.notes,
            ),
          ],
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final String value;

  const DetailRow({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(theme.radius),
      ),
      child: Row(
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
                  style: theme.typography.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value, style: theme.typography.base),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter sheet widget for filtering transactions
class FilterSheet extends StatefulWidget {
  final ListTransactionRequest? initialFilter;
  final Function(ListTransactionRequest?) onApplyFilters;

  const FilterSheet({
    super.key,
    this.initialFilter,
    required this.onApplyFilters,
  });

  @override
  State<FilterSheet> createState() => FilterSheetState();
}

class FilterSheetState extends State<FilterSheet> {
  String? _selectedType;
  TransactionCategory? _selectedCategory;
  late TextEditingController _notesController;
  DateTime? _startDate;
  DateTime? _endDate;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    _selectedType = filter?.type;
    _selectedCategory = filter?.category;
    _notesController = TextEditingController(text: filter?.notes);
    _startDate = filter?.startDate;
    _endDate = filter?.endDate;
    _minAmountController = TextEditingController(
      text: filter?.minAmount?.toString(),
    );
    _maxAmountController = TextEditingController(
      text: filter?.maxAmount?.toString(),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filter = ListTransactionRequest(
      type: _selectedType,
      category: _selectedCategory,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      startDate: _startDate,
      endDate: _endDate,
      minAmount: double.tryParse(_minAmountController.text),
      maxAmount: double.tryParse(_maxAmountController.text),
    );

    widget.onApplyFilters(filter);
    closeDrawer(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedType = null;
      _selectedCategory = null;
      _notesController.clear();
      _startDate = null;
      _endDate = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
    widget.onApplyFilters(null);
    closeDrawer(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Transactions', style: theme.typography.h4),
              GhostButton(
                density: ButtonDensity.icon,
                onPressed: () => closeDrawer(context),
                child: const Icon(LucideIcons.x, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Type selector
          Text(
            'Type',
            style: theme.typography.small.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ButtonGroup(
            children: [
              Button(
                onPressed: () {
                  setState(() {
                    _selectedType = null;
                  });
                },
                style: _selectedType == null
                    ? ButtonStyle.primary()
                    : ButtonStyle.outline(),
                child: Text("All"),
              ).expanded(),
              Button(
                onPressed: () {
                  setState(() {
                    _selectedType = 'income';
                  });
                },
                style: ButtonStyle.outline()
                    .withBackgroundColor(
                      color: _selectedType == 'income' ? Colors.green : null,
                    )
                    .withForegroundColor(
                      color: _selectedType == 'income'
                          ? theme.colorScheme.accent
                          : null,
                    ),
                child: Text("Income"),
              ).expanded(),
              Button(
                onPressed: () {
                  setState(() {
                    _selectedType = 'expense';
                  });
                },
                style: _selectedType == 'expense'
                    ? ButtonStyle.destructive()
                    : ButtonStyle.outline(),
                child: Text("Expense"),
              ).expanded(),
            ],
          ),
          const SizedBox(height: 16),

          // Category selector
          Text(
            'Category',
            style: theme.typography.small.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Select<TransactionCategory?>(
            value: _selectedCategory,
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            itemBuilder: (context, item) {
              if (item == null) return const Text('All Categories');
              return Text(item.name.toUpperCase());
            },
            placeholder: const Text('Select category'),
            popup: SelectPopup.builder(
              builder: (context, searchQuery) {
                return SelectItemList(
                  children: [
                    SelectItemButton<TransactionCategory?>(
                      value: null,
                      child: const Text('All Categories'),
                    ),
                    ...TransactionCategory.values.map(
                      (cat) => SelectItemButton<TransactionCategory?>(
                        value: cat,
                        child: Text(cat.name.toUpperCase()),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Notes input
          Text(
            'Notes',
            style: theme.typography.small.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            placeholder: const Text('Search in notes'),
          ),
          const SizedBox(height: 16),

          // Date range
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Date',
                      style: theme.typography.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // OutlineButton(
                    //   onPressed: () async {
                    //     final date = await DatePicker(
                    //       context: context,
                    //       initialDate: _startDate ?? DateTime.now(),
                    //       firstDate: DateTime(2000),
                    //       lastDate: DateTime.now(),
                    //     );
                    //     if (date != null) {
                    //       setState(() {
                    //         _startDate = date;
                    //       });
                    //     }
                    //   },
                    //   child: Text(
                    //     _startDate != null
                    //         ? _formatSimpleDate(_startDate!)
                    //         : 'Select date',
                    //   ),
                    // ),
                    DatePicker(
                      value: _startDate,
                      onChanged: (value) {
                        setState(() {
                          _startDate = value;
                        });
                      },
                      placeholder: const Text('Select date'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Date',
                      style: theme.typography.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DatePicker(
                      value: _endDate,
                      onChanged: (value) {
                        setState(() {
                          _endDate = value;
                        });
                      },
                      placeholder: const Text('Select date'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount range
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Min Amount',
                      style: theme.typography.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _minAmountController,
                      placeholder: const Text('0.00'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Max Amount',
                      style: theme.typography.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _maxAmountController,
                      placeholder: const Text('0.00'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlineButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  onPressed: _applyFilters,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  final Future<void> Function(CreateTransaction transaction) onSubmit;
  final BuildContext toastContext;

  const AddTransactionSheet({
    super.key,
    required this.onSubmit,
    required this.toastContext,
  });

  @override
  State<AddTransactionSheet> createState() => AddTransactionSheetState();
}

class AddTransactionSheetState extends State<AddTransactionSheet> {
  String? _selectedType;
  TransactionCategory? _selectedCategory;
  late final TextEditingController _amountController;
  late DateTime _date;
  late final TextEditingController _notesController;
  late final TextEditingController _paymentMethodController;

  final UserService _userService = GetIt.I<UserService>();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _date = DateTime.now();
    _notesController = TextEditingController();
    _paymentMethodController = TextEditingController(text: 'cash');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final parsedAmount = double.tryParse(_amountController.text.trim());
    final paymentMethod = _paymentMethodController.text.trim();

    if (_selectedType == null) {
      showAppToast(
        title: 'Please select a transaction type.',
        subtitle: 'Income or Expense',
        type: ToastType.destructive,
      );
      return;
    }
    if (parsedAmount == null || parsedAmount <= 0) {
      showAppToast(
        title: 'Please enter a valid amount.',
        type: ToastType.destructive,
      );
      return;
    }

    if (paymentMethod.isEmpty) {
      showAppToast(
        title: 'Please enter a payment method.',
        type: ToastType.destructive,
      );
      return;
    }

    final currency = _userService.currentUser?.primaryCurrency;
    if (currency == null || currency.isEmpty) {
      showAppToast(
        title: 'User currency not available.',
        subtitle: 'Please try again.',
        type: ToastType.destructive,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(
        CreateTransaction(
          type: _selectedType!,
          amount: parsedAmount,
          date: _date,
          currency: currency,
          category: _selectedCategory?.name,
          notes: _notesController.text,
          paymentMethod: paymentMethod,
        ),
      );

      if (mounted) {
        closeDrawer(context);
      }
    } catch (e) {
      if (!mounted) return;

      // Show toast error instead of closing sheet
      showAppToast(
        title: 'Error creating transaction',
        subtitle: e.toString(),
        type: ToastType.destructive,
      );

      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Transaction', style: theme.typography.h4),
                GhostButton(
                  density: ButtonDensity.icon,
                  onPressed: _isSubmitting ? null : () => closeDrawer(context),
                  child: const Icon(LucideIcons.x),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Type', style: theme.typography.small),
            const SizedBox(height: 8),
            // Expanded(
            ButtonGroup(
              children: [
                Button(
                  onPressed: () {
                    setState(() {
                      _selectedType = 'income';
                    });
                  },
                  style: ButtonStyle.outline()
                      .withBackgroundColor(
                        color: _selectedType == 'income' ? Colors.green : null,
                      )
                      .withForegroundColor(
                        color: _selectedType == 'income'
                            ? theme.colorScheme.accent
                            : null,
                      ),
                  child: Text("Income"),
                ).expanded(),
                Button(
                  onPressed: () {
                    setState(() {
                      _selectedType = 'expense';
                    });
                  },
                  style: _selectedType == 'expense'
                      ? ButtonStyle.destructive()
                      : ButtonStyle.outline(),
                  child: Text("Expense"),
                ).expanded(),
              ],
            ),
            const SizedBox(height: 16),
            Text('Amount', style: theme.typography.small),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              placeholder: const Text('0'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            Text('Date', style: theme.typography.small),
            const SizedBox(height: 8),
            DatePicker(
              value: _date,
              onChanged: (value) => setState(() => _date = value!),
              placeholder: const Text('Select a date'),
            ),
            const SizedBox(height: 16),
            Text('Category', style: theme.typography.small),
            const SizedBox(height: 8),
            Select<TransactionCategory>(
              value: _selectedCategory,
              placeholder: const Text('Optional'),
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() => _selectedCategory = value),
              itemBuilder: (context, item) => Text(_labelCategory(item)),
              popup: SelectPopup(
                items: SelectItemList(
                  children: TransactionCategory.values
                      .map(
                        (c) => SelectItemButton(
                          value: c,
                          child: Text(_labelCategory(c)),
                        ),
                      )
                      .toList(),
                ),
              ).call,
            ),
            const SizedBox(height: 16),
            Text('Payment Method', style: theme.typography.small),
            const SizedBox(height: 8),
            TextField(
              controller: _paymentMethodController,
              placeholder: const Text('cash'),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            Text('Notes', style: theme.typography.small),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              placeholder: const Text('Optional notes'),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlineButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => closeDrawer(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    enabled: !_isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                    child: Text(_isSubmitting ? 'Adding…' : 'Add'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }

  String _labelCategory(TransactionCategory category) {
    return category.name[0].toUpperCase() + category.name.substring(1);
  }
}
