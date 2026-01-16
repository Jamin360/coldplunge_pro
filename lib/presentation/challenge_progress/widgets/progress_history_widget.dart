import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProgressHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final String challengeType;

  const ProgressHistoryWidget({
    super.key,
    required this.sessions,
    required this.challengeType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sessions.length > 10 ? 10 : sessions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _buildSessionItem(context, session);
        },
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, Map<String, dynamic> session) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final duration = session['duration'] as int? ?? 0;
    final temperature = session['temperature'] as int? ?? 0;
    final createdAt = session['created_at'] as String?;
    final location = session['location'] as String? ?? 'Unknown';

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      leading: Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: 'check_circle',
            size: 24,
            color: colorScheme.primary,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              _formatDate(createdAt),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: AppTheme.successLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Qualified',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.successLight,
                fontWeight: FontWeight.w600,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 1.h),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'schedule',
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 1.w),
            Text(
              _formatDuration(duration),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(width: 3.w),
            CustomIconWidget(
              iconName: 'thermostat',
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 1.w),
            Text(
              '${temperature}°F',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(width: 3.w),
            CustomIconWidget(
              iconName: 'location_on',
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 1.w),
            Expanded(
              child: Text(
                location,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown date';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return '${months[date.month - 1]} ${date.day}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes == 0) {
      return '${remainingSeconds}s';
    } else if (remainingSeconds == 0) {
      return '${minutes}m';
    } else {
      return '${minutes}m ${remainingSeconds}s';
    }
  }
}
