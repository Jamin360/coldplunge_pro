import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AnimatedLogoWidget extends StatefulWidget {
  const AnimatedLogoWidget({super.key});

  @override
  State<AnimatedLogoWidget> createState() => _AnimatedLogoWidgetState();
}

class _AnimatedLogoWidgetState extends State<AnimatedLogoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(30.w),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'ac_unit',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 48.sp,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'ColdPlunge',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                  Text(
                    'Pro',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
