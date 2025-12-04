import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StreakCounterWidget extends StatefulWidget {
  final int streakCount;
  final bool hasPlungedToday;

  const StreakCounterWidget({
    super.key,
    required this.streakCount,
    required this.hasPlungedToday,
  });

  @override
  State<StreakCounterWidget> createState() => _StreakCounterWidgetState();
}

class _StreakCounterWidgetState extends State<StreakCounterWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Current Streak',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),

          // Static counter circle (removed pulsing animation)
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${widget.streakCount}',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ),

          SizedBox(height: 2.h),
          Text(
            widget.streakCount == 1 ? 'Day' : 'Days',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: widget.hasPlungedToday
                  ? AppTheme.successLight.withValues(alpha: 0.1)
                  : AppTheme.warningLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.hasPlungedToday
                    ? AppTheme.successLight.withValues(alpha: 0.3)
                    : AppTheme.warningLight.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName:
                      widget.hasPlungedToday ? 'check_circle' : 'schedule',
                  color: widget.hasPlungedToday
                      ? AppTheme.successLight
                      : AppTheme.warningLight,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  widget.hasPlungedToday ? 'Completed Today' : 'Pending Today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.hasPlungedToday
                        ? AppTheme.successLight
                        : AppTheme.warningLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
