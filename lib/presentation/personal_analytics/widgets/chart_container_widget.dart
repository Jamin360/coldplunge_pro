import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ChartContainerWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget chart;
  final VoidCallback? onTap;

  const ChartContainerWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.chart,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.w),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.fullscreen,
                    color: colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
              ],
            ),
            SizedBox(height: 5.w),
            SizedBox(
              height: 48.w,
              child: Padding(
                padding: EdgeInsets.only(right: 2.w, top: 2.w),
                child: chart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
