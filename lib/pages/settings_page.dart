import 'package:flutter/material.dart';
import 'package:jura/main.dart';
import 'package:jura/services/auth_service.dart';
import 'package:jura/services/user_service.dart';
import 'package:jura/utils/currencies.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AuthService get _authService => getIt<AuthService>();
  UserService get _userService => getIt<UserService>();
  String _searchValue = '';
  bool _isSaving = false;

  Future<void> _saveCurrency(String currency) async {
    setState(() => _isSaving = true);

    try {
      if (!mounted) return;

      // Update user currency via API and secure storage
      await _userService.updateCurrency(currency);

      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('Success'),
          description: Text('Currency saved: $currency'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Error'),
          description: Text('Error: $e'),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Map<String, String> get _filteredCurrencies {
    return {
      for (final entry in currenciesMap.entries)
        if (entry.key.toLowerCase().contains(_searchValue.toLowerCase()) ||
            entry.value.$2.toLowerCase().contains(_searchValue.toLowerCase()))
          entry.key: entry.key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: theme.textTheme.h3),
                  const SizedBox(height: 16),
                  userProfileCard(),
                  const SizedBox(height: 24),
                  currencySelector(),
                  const SizedBox(height: 24),
                  logoutButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget userProfileCard() {
    final theme = ShadTheme.of(context);
    final user = _userService.currentUser;

    final tierLabel = (user?.isPremium ?? false) ? 'Premium' : 'Free';
    final tierBadge = (user?.isPremium ?? false)
        ? ShadBadge(child: Text(tierLabel))
        : ShadBadge.outline(child: Text(tierLabel));

    return ShadCard(
      // title: Text('Profile', style: theme.textTheme.h4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(
              user?.username.isNotEmpty == true
                  ? user!.username[0].toUpperCase()
                  : '?',
              style: theme.textTheme.large,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${user?.username ?? '—'}', style: theme.textTheme.large),
                const SizedBox(height: 6),
                Row(
                  children: [
                    tierBadge,
                    const SizedBox(width: 8),
                    Text(
                      user?.primaryCurrency ?? '—',
                      style: theme.textTheme.muted,
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

  Widget currencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Main Currency'),
        const SizedBox(height: 8),
        ShadSelect<String>.withSearch(
          minWidth: 250,
          placeholder: const Text('Search currencies...'),
          searchPlaceholder: const Text('Search by code or name...'),
          onSearchChanged: (value) => setState(() => _searchValue = value),
          options: [
            if (_filteredCurrencies.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No currency found'),
              ),
            ..._filteredCurrencies.entries.map((entry) {
              final currencyCode = entry.key;
              final (flag, name) = currenciesMap[currencyCode]!;
              return Offstage(
                offstage: !_filteredCurrencies.containsKey(currencyCode),
                child: ShadOption(
                  value: currencyCode,
                  child: Text('$flag $currencyCode - $name'),
                ),
              );
            }),
          ],
          selectedOptionBuilder: (context, value) {
            final (flag, name) = currenciesMap[value]!;
            return Text('$flag $value - $name');
          },
          onChanged: (value) {
            if (value != null && !_isSaving) {
              _saveCurrency(value);
            }
          },
          initialValue: _userService.currentUser?.primaryCurrency,
        ),
      ],
    );
  }

  Widget logoutButton() {
    return ShadButton(
      onPressed: () => _authService.logout(),
      child: const Text('Logout'),
    );
  }
}
