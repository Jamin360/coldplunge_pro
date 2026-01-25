import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white, // Clean white card
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF64748B)
              .withValues(alpha: 0.2), // Subtle slate border (replaced teal)
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Streak',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1E3A5A), // Navy text
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),

          // Circular streak counter with navy to slate gradient
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E3A5A), // Navy blue
                  Color(0xFF475569), // Slate blue (replaced teal)
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A5A)
                      .withValues(alpha: 0.3), // Navy shadow (replaced teal)
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
              color: const Color(0xFF1E3A5A), // Navy text
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: widget.hasPlungedToday
                  ? const Color(
                      0xFFDCFCE7) // Light green background (replaced teal)
                  : const Color(0xFFD97706)
                      .withValues(alpha: 0.1), // Muted amber for pending
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.hasPlungedToday
                    ? const Color(0xFF22C55E).withValues(
                        alpha: 0.3) // Soft green border (replaced teal)
                    : const Color(0xFFD97706).withValues(alpha: 0.3),
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
                      ? const Color(
                          0xFF22C55E) // Soft green icon (replaced teal)
                      : const Color(0xFFD97706),
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  widget.hasPlungedToday ? 'Completed Today' : 'Pending Today',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: widget.hasPlungedToday
                        ? const Color(
                            0xFF22C55E) // Soft green text (replaced teal)
                        : const Color(0xFFD97706),
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
