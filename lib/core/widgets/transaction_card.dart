import 'package:jura/core/models/transaction.dart';
import 'package:jura/core/utils/formatters.dart';
import 'package:jura/core/utils/string_extension.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Reusable transaction list tile used across the app.
class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final ThemeData theme;
  final VoidCallback onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type.toLowerCase() == 'expense';
    final color = isExpense ? theme.colorScheme.destructive : Colors.green;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                borderRadius: BorderRadius.circular(theme.radius),
              ),
              child: Icon(
                isExpense
                    ? LucideIcons.arrowDownRight
                    : LucideIcons.arrowUpRight,
                size: 20,
                color: color,
              ),
            ),
            Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    transaction.category.toSentenceCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).semiBold().foreground(),
                  Gap(4),
                  Text(
                    transaction.formattedDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).small().muted().semiBold(),
                  if (transaction.notes.isNotEmpty) ...[
                    Gap(2),
                    Text(
                      transaction.notes,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ).small().muted(),
                  ],
                ],
              ),
            ),
            Gap(16),
            Text(
              '${isExpense ? '−' : '+'}${formatCurrency(transaction.amount, currencyCode: transaction.currency)}',
              style: TextStyle(color: color),
              textAlign: TextAlign.right,
            ).semiBold(),
          ],
        ),
      ),
    );
  }
}
