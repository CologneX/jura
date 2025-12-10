import 'package:flutter/material.dart';
import 'package:jura/models/transaction.dart';
import 'package:jura/utils/formatters.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Reusable transaction list tile used across the app.
class TransactionCard extends StatefulWidget {
  final Transaction transaction;
  final ShadThemeData theme;
  final VoidCallback onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.theme,
    required this.onTap,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
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
