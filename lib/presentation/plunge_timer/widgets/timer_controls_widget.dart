import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class TimerControlsWidget extends StatefulWidget {
  final bool isRunning;
  final bool isPaused;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onReset;

  const TimerControlsWidget({
    super.key,
    this.isRunning = false,
    this.isPaused = false,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onStop,
    this.onReset,
  });

  @override
  State<TimerControlsWidget> createState() => _TimerControlsWidgetState();
}

class _TimerControlsWidgetState extends State<TimerControlsWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _animatePress() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTapDown: (_) => _animatePress(),
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed?.call();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: isPrimary ? 20.w : 16.w,
              height: isPrimary ? 20.w : 16.w,
              decoration: BoxDecoration(
                color: isPrimary ? color : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: isPrimary ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isPrimary
                    ? null
                    : Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1,
                      ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: _getIconName(icon),
                    color: isPrimary ? colorScheme.onPrimary : color,
                    size: isPrimary ? 28 : 24,
                  ),
                  if (!isPrimary) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 8.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getIconName(IconData icon) {
    if (icon == Icons.play_arrow) return 'play_arrow';
    if (icon == Icons.pause) return 'pause';
    if (icon == Icons.stop) return 'stop';
    if (icon == Icons.refresh) return 'refresh';
    return 'play_arrow';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!widget.isRunning) {
      // Start state
      return Container(
        padding: EdgeInsets.only(
          left: 8.w,
          right: 8.w,
          top: 4.h,
          bottom: 4.h + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            _buildControlButton(
              label: 'START',
              icon: Icons.play_arrow,
              color: colorScheme.primary,
              onPressed: widget.onStart,
              isPrimary: true,
            ),
            SizedBox(height: 3.h),
            Text(
              'Tap to begin your cold plunge session',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Running/Paused state
    return Container(
      padding: EdgeInsets.only(
        left: 6.w,
        right: 6.w,
        top: 3.h,
        bottom: 3.h + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          // Primary control (pause/resume)
          _buildControlButton(
            label: widget.isPaused ? 'RESUME' : 'PAUSE',
            icon: widget.isPaused ? Icons.play_arrow : Icons.pause,
            color: colorScheme.primary,
            onPressed: widget.isPaused ? widget.onResume : widget.onPause,
            isPrimary: true,
          ),
          SizedBox(height: 3.h),

          // Finish Plunge button (full width)
          SizedBox(
            width: double.infinity,
            height: 70,
            child: ElevatedButton(
              onPressed: widget.onStop,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706), // Muted amber
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Text(
                'Finish Plunge',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Reset button (subtle text button)
          TextButton(
            onPressed: widget.onReset,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 16, color: Colors.white),
                SizedBox(width: 1.w),
                Text(
                  'Reset',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),

          // Status text
          Text(
            widget.isPaused
                ? 'Session paused - tap resume to continue'
                : 'Session in progress - stay strong!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: widget.isPaused
                  ? colorScheme.onSurfaceVariant
                  : const Color(0xFFD97706), // Muted amber
              fontWeight: widget.isPaused ? FontWeight.w400 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
