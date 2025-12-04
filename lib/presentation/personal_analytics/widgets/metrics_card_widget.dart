import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class MetricsCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final bool isHighlighted;

  const MetricsCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 42.w,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.primary.withValues(alpha: 0.05)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? colorScheme.primary.withValues(alpha: 0.2)
              : colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color:
                      (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: icon.codePoint.toString(),
                  color: iconColor ?? colorScheme.primary,
                  size: 5.w,
                ),
              ),
              const Spacer(),
              if (isHighlighted)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Best',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 3.w),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.w),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.w),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
