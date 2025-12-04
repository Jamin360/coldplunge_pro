import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TimerDisplayWidget extends StatefulWidget {
  final Duration duration;
  final bool isRunning;
  final bool isPaused;
  final VoidCallback? onTap;

  const TimerDisplayWidget({
    super.key,
    required this.duration,
    this.isRunning = false,
    this.isPaused = false,
    this.onTap,
  });

  @override
  State<TimerDisplayWidget> createState() => _TimerDisplayWidgetState();
}

class _TimerDisplayWidgetState extends State<TimerDisplayWidget>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _pulseController;
  late Animation<double> _rippleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isRunning && !widget.isPaused) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(TimerDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning && !widget.isPaused && !oldWidget.isRunning) {
      _startAnimations();
    } else if (!widget.isRunning || widget.isPaused) {
      _stopAnimations();
    }
  }

  void _startAnimations() {
    _rippleController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _stopAnimations() {
    _rippleController.stop();
    _pulseController.stop();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 80.w,
        height: 80.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple effects
            if (widget.isRunning && !widget.isPaused) ...[
              AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80.w * (0.8 + 0.4 * _rippleAnimation.value),
                    height: 80.w * (0.8 + 0.4 * _rippleAnimation.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(
                          alpha: 0.3 * (1 - _rippleAnimation.value),
                        ),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80.w * (0.9 + 0.3 * _rippleAnimation.value),
                    height: 80.w * (0.9 + 0.3 * _rippleAnimation.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.secondary.withValues(
                          alpha: 0.2 * (1 - _rippleAnimation.value),
                        ),
                        width: 1,
                      ),
                    ),
                  );
                },
              ),
            ],

            // Main timer circle
            AnimatedBuilder(
              animation: widget.isRunning && !widget.isPaused
                  ? _pulseAnimation
                  : const AlwaysStoppedAnimation(1.0),
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isRunning && !widget.isPaused
                      ? _pulseAnimation.value
                      : 1.0,
                  child: Container(
                    width: 70.w,
                    height: 70.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colorScheme.surface,
                          colorScheme.surface.withValues(alpha: 0.9),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: widget.isRunning && !widget.isPaused
                              ? colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          blurRadius: 30,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatDuration(widget.duration),
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: widget.isRunning && !widget.isPaused
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [
                                const FontFeature.tabularFigures()
                              ],
                              letterSpacing: -2,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isRunning && !widget.isPaused
                                  ? colorScheme.primary.withValues(alpha: 0.1)
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.isPaused
                                  ? 'PAUSED'
                                  : widget.isRunning
                                      ? 'ACTIVE'
                                      : 'READY',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: widget.isRunning && !widget.isPaused
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
