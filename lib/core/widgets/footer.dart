import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class Footer extends StatelessWidget {
  const Footer({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _onNavItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              icon: Icons.book_rounded,
              label: 'Journal',
              index: 0,
              theme: theme,
            ),
            _buildCenterNavItem(context: context, theme: theme),
            _buildNavItem(
              context: context,
              icon: Icons.person_rounded,
              label: 'Profile',
              index: 2,
              theme: theme,
            ),
          ],
        ).withPadding(top: 8),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = navigationShell.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavItemTapped(index),
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
                style: TextStyle(
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
    required ThemeData theme,
  }) {
    final isSelected = navigationShell.currentIndex == 1;

    return GestureDetector(
      onTap: () => _onNavItemTapped(1),
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
}
