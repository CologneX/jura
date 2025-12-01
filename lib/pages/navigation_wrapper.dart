import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:jura/services/tab_navigation_service.dart';

class BottomNavigationWrapper extends StatelessWidget {
  const BottomNavigationWrapper({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24, top: 8),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.card,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: theme.colorScheme.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.list,
                label: 'Journal',
                index: 0,
                theme: theme,
              ),
              _buildCenterNavItem(context: context, theme: theme),
              _buildNavItem(
                context: context,
                icon: Icons.settings,
                label: 'Settings',
                index: 2,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required ShadThemeData theme,
  }) {
    final isSelected = navigationShell.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(context, index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.mutedForeground,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.small.copyWith(
                  fontSize: 12,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNavItem({
    required BuildContext context,
    required ShadThemeData theme,
  }) {
    final isSelected = navigationShell.currentIndex == 1;

    return GestureDetector(
      onTap: () => _onTap(context, 1),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.muted,
        ),
        child: Icon(
          Icons.chat_bubble_rounded,
          size: 28,
          color: isSelected
              ? theme.colorScheme.primaryForeground
              : theme.colorScheme.mutedForeground,
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    GetIt.I<TabNavigationService>().switchTab(index);
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
