import 'package:get_it/get_it.dart';
import 'package:jura/core/models/transaction.dart';
import 'package:jura/core/widgets/transaction_card.dart';
import 'package:jura/features/journal/journal_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'journal_viewmodel.dart';

class JournalView extends StatefulWidget {
  const JournalView({super.key});

  @override
  State<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<JournalView> {
  late final ScrollController _scrollController;
  final GlobalKey<RefreshTriggerState> _refreshTriggerKey =
      GlobalKey<RefreshTriggerState>();
  late JournalViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _viewModel = GetIt.I<JournalViewModel>();
    _viewModel.addListener(_onStateChanged);
    _viewModel.loadTransactions();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onStateChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final state = _viewModel.state;

    if (state is! JournalLoaded || !state.hasMoreData) {
      return;
    }

    if (state is JournalLoadingMore) {
      return;
    }

    const paginationTriggerThresholdPx = 240.0;
    final extentAfter = _scrollController.position.extentAfter;

    if (extentAfter < paginationTriggerThresholdPx) {
      _viewModel.loadMoreTransactions();
    }
  }

  void _showFilterSheet(BuildContext context) {
    final currentState = _viewModel.state;
    final currentFilter = currentState is JournalLoaded
        ? currentState.currentFilter
        : null;

    openDrawer(
      context: context,
      transformBackdrop: false,
      builder: (context) => FilterSheet(
        initialFilter: currentFilter,
        onApplyFilters: (filter) {
          _viewModel.loadTransactions(filter: filter);
        },
      ),
      position: OverlayPosition.bottom,
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    openDrawer(
      context: context,
      transformBackdrop: false,
      builder: (drawerContext) => AddTransactionSheet(
        toastContext: context,
        onSubmit: (createTransaction) async {
          await _viewModel.createTransaction(createTransaction);
        },
      ),
      position: OverlayPosition.bottom,
    );
  }

  void _showTransactionDetails(BuildContext context, Transaction transaction) {
    openDrawer(
      transformBackdrop: false,
      context: context,
      builder: (context) => TransactionDetailsSheet(transaction: transaction),
      position: OverlayPosition.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = _viewModel.state;

    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Journal').h3,
          trailing: [
            OutlineButton(
              density: ButtonDensity.icon,
              onPressed: () => _showFilterSheet(context),
              child: const Icon(LucideIcons.slidersHorizontal),
            ),
            PrimaryButton(
              density: ButtonDensity.icon,
              child: const Icon(LucideIcons.plus),
              onPressed: () => _showAddTransactionSheet(context),
            ),
          ],
        ),
        Divider(),
      ],
      child: Stack(children: [_buildBody(context, state, theme)]),
    );
  }

  Widget _buildBody(BuildContext context, JournalState state, ThemeData theme) {
    if (state is JournalLoading || state is JournalInitial) {
      return _buildLoadingState(theme);
    }

    if (state is JournalError) {
      return _buildErrorState(context, state, theme);
    }

    final transactions = state is JournalLoaded
        ? state.transactions
        : state is JournalLoadingMore
        ? state.existingTransactions
        : <Transaction>[];

    final totalIncome = state is JournalLoaded
        ? state.totalIncome
        : state is JournalLoadingMore
        ? state.totalIncome
        : 0.0;

    final totalExpenses = state is JournalLoaded
        ? state.totalExpenses
        : state is JournalLoadingMore
        ? state.totalExpenses
        : 0.0;

    final currency = state is JournalLoaded
        ? state.currency
        : state is JournalLoadingMore
        ? state.currency
        : 'USD';

    final isLoadingMore = state is JournalLoadingMore;

    return _buildContent(
      context: context,
      theme: theme,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      transactions: transactions,
      currency: currency,
      isLoadingMore: isLoadingMore,
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return RefreshTrigger(
      key: _refreshTriggerKey,
      child: CustomScrollView(
        controller: _scrollController,
        scrollBehavior: const ShadcnScrollBehavior(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Skeletonizer(
                    child: Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            theme: theme,
                            icon: LucideIcons.trendingUp,
                            title: 'Income',
                            amount: 5000.0,
                            isExpense: false,
                            currency: 'USD',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            theme: theme,
                            icon: LucideIcons.trendingDown,
                            title: 'Expenses',
                            amount: 3000.0,
                            isExpense: true,
                            currency: 'USD',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text('Transactions', style: theme.typography.h4),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverSkeletonizer(
              child: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TransactionCard(
                      transaction: Transaction(
                        id: 'skeleton-\$index',
                        type: 'expense',
                        amount: 100.0,
                        currency: 'USD',
                        date: DateTime.now(),
                        notes: '',
                        paymentMethod: 'cash',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                      theme: theme,
                      onTap: () {},
                    ),
                  ),
                  childCount: 5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    JournalError state,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.circleAlert,
            size: 64,
            color: theme.colorScheme.destructive,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: theme.typography.h4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.mutedForeground),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            onPressed: () {
              _viewModel.loadTransactions();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required ThemeData theme,
    required double totalIncome,
    required double totalExpenses,
    required List<Transaction> transactions,
    required String currency,
    required bool isLoadingMore,
  }) {
    return RefreshTrigger(
      onRefresh: () async {
        _viewModel.refresh();
      },
      key: _refreshTriggerKey,
      child: CustomScrollView(
        controller: _scrollController,
        scrollBehavior: const ShadcnScrollBehavior(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          theme: theme,
                          icon: LucideIcons.trendingUp,
                          title: 'Income',
                          amount: totalIncome,
                          isExpense: false,
                          currency: currency,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          theme: theme,
                          icon: LucideIcons.trendingDown,
                          title: 'Expenses',
                          amount: totalExpenses,
                          isExpense: true,
                          currency: currency,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text('Transactions', style: theme.typography.h4),
            ),
          ),
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
                          color: theme.colorScheme.mutedForeground.withValues(
                            alpha: 0.08,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.inbox,
                          size: 56,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('No transactions yet', style: theme.typography.h4),
                      const SizedBox(height: 8),
                      Text(
                        'Start by adding your first transaction',
                        style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                        ),
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
                    child: TransactionCard(
                      transaction: transactions[index],
                      theme: theme,
                      onTap: () =>
                          _showTransactionDetails(context, transactions[index]),
                    ),
                  );
                }, childCount: transactions.length),
              ),
            ),
          if (isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
