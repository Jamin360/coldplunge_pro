import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class LoadingIndicatorWidget extends StatefulWidget {
  final String loadingText;
  final bool showProgress;
  final double progress;

  const LoadingIndicatorWidget({
    super.key,
    this.loadingText = 'Initializing...',
    this.showProgress = false,
    this.progress = 0.0,
  });

  @override
  State<LoadingIndicatorWidget> createState() => _LoadingIndicatorWidgetState();
}

class _LoadingIndicatorWidgetState extends State<LoadingIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.showProgress
            ? _buildProgressIndicator()
            : _buildPulsingIndicator(),
        SizedBox(height: 2.h),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _pulseAnimation.value,
              child: Text(
                widget.loadingText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      width: 60.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(2.h),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.h),
        child: LinearProgressIndicator(
          value: widget.progress,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.lightTheme.colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
