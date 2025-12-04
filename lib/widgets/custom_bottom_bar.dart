import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom bottom navigation bar implementing Arctic Clarity design principles
/// with gesture-first navigation optimized for cold plunge wellness app
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                route: '/home-dashboard',
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.timer_outlined,
                activeIcon: Icons.timer,
                label: 'Timer',
                route: '/plunge-timer',
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Community',
                route: '/community-feed',
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events,
                label: 'Challenges',
                route: '/challenges',
              ),
              _buildNavItem(
                context: context,
                index: 4,
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics,
                label: 'Analytics',
                route: '/personal-analytics',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Haptic feedback for touch confirmation
          HapticFeedback.lightImpact();

          if (!isSelected) {
            onTap(index);
            Navigator.pushNamed(context, route);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 24,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
