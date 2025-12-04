import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom app bar implementing Arctic Clarity design with contextual actions
/// Optimized for cold plunge wellness app with gesture-first navigation
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: foregroundColor ?? colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: elevation,
      scrolledUnderElevation: elevation > 0 ? elevation + 2 : 2,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: Colors.transparent,
      leading: leading ??
          (canPop && showBackButton ? _buildBackButton(context) : null),
      actions: actions != null
          ? [
              ...actions!,
              const SizedBox(width: 8), // Padding for edge-to-edge content
            ]
          : null,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: theme.brightness,
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (onBackPressed != null) {
          onBackPressed!();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: foregroundColor ?? colorScheme.onSurface,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Specialized app bar for session timer with quick actions
class CustomTimerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String sessionTime;
  final String temperature;
  final VoidCallback? onPause;
  final VoidCallback? onStop;
  final bool isPaused;

  const CustomTimerAppBar({
    super.key,
    required this.sessionTime,
    required this.temperature,
    this.onPause,
    this.onStop,
    this.isPaused = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: Column(
        children: [
          Text(
            sessionTime,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
          Text(
            temperature,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: Colors.transparent,
      leading: _buildTimerAction(
        context: context,
        icon: Icons.close,
        onTap: onStop,
        color: colorScheme.error,
      ),
      actions: [
        _buildTimerAction(
          context: context,
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          onTap: onPause,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTimerAction({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 24,
          color: color,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
