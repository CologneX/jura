import 'package:jura/core/models/user.dart';
import 'package:jura/core/utils/currencies.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class UserProfileCard extends StatelessWidget {
  final User user;

  const UserProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.foreground.withAlpha(30),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      borderColor: theme.colorScheme.primary,
      child: Row(
        children: [
          AvatarBadge(
            color: theme.colorScheme.primary,
            size: 56,
            child: Center(
              child: Text(
                user.username[0].toUpperCase(),
                style: TextStyle(color: Colors.white),
              ).xLarge.semiBold,
            ),
          ),
          // Container(
          //   width: 48,
          //   height: 48,
          //   alignment: Alignment.center,
          //   decoration: BoxDecoration(
          //     shape: BoxShape.circle,
          //     gradient: LinearGradient(
          //       colors: [
          //         theme.colorScheme.primary.withValues(alpha: 0.3),
          //         theme.colorScheme.primary.withValues(alpha: 0.3),
          //       ],
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //     ),
          //   ),
          //   child: Text(user.username[0].toUpperCase()).large,
          // ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username).large,
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (user.isPremium)
                      PrimaryBadge(child: Text("Premium").small)
                    else
                      OutlineBadge(child: Text("Free").small),
                    const SizedBox(width: 8),
                    OutlineBadge(
                      child: Row(
                        children: [
                          if (currenciesMap.containsKey(user.primaryCurrency))
                            Text(currenciesMap[user.primaryCurrency]!.$1),
                          const SizedBox(width: 8),
                          Text(user.primaryCurrency).small,
                        ],
                      ),
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

class CurrencySelector extends StatelessWidget {
  final String currentCurrency;
  final Function(String) onCurrencyChanged;

  const CurrencySelector({
    super.key,
    required this.currentCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Main Currency').small().muted(),
        const SizedBox(height: 8),
        Select<String>(
          itemBuilder: (context, item) {
            final selectedMap = currenciesMap[item]!;
            return Row(
              children: [
                Text(selectedMap.$1),
                const SizedBox(width: 8),
                Expanded(child: Text("${selectedMap.$2} ($item)")),
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
                          Expanded(
                            child: Text("${value.value.$2} (${value.key})"),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ).call,
          onChanged: (value) {
            if (value != null) {
              onCurrencyChanged(value);
            }
          },
          value: currentCurrency,
        ),
      ],
    );
  }
}

class LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const LogoutButton({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(onPressed: onLogout, child: const Text('Logout'));
  }
}
