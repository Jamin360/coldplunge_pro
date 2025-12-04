import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickStatsCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String iconName;
  final Color? accentColor;

  const QuickStatsCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconName,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = accentColor ?? colorScheme.primary;

    return Container(
      width: 40.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: accent,
                  size: 20,
                ),
              ),
              CustomIconWidget(
                iconName: 'trending_up',
                color: AppTheme.successLight,
                size: 16,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
