import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SessionHistoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SessionHistoryCardWidget({
    super.key,
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = difference.inDays ~/ 30;
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = difference.inDays ~/ 365;
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  String _formatTime(String dateString) {
    final date = DateTime.parse(dateString);
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s Duration';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}m Duration';
      }
      return '${minutes}m ${remainingSeconds}s Duration';
    }
  }

  IconData _getMoodIcon(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'euphoric':
        return Icons.sentiment_very_satisfied;
      case 'calm':
      case 'focused':
        return Icons.sentiment_satisfied;
      case 'energized':
        return Icons.bolt;
      case 'neutral':
        return Icons.sentiment_neutral;
      case 'tired':
      case 'stressed':
      case 'anxious':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.mood;
    }
  }

  Color _getMoodColor(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'euphoric':
        return const Color(0xFF10B981); // Green
      case 'energized':
        return const Color(0xFF10B981); // Green
      case 'calm':
        return const Color(0xFF3B82F6); // Blue
      case 'focused':
        return const Color(0xFF8B5CF6); // Purple
      case 'neutral':
        return const Color(0xFF6B7280); // Gray
      case 'tired':
        return const Color(0xFFF59E0B); // Orange
      case 'stressed':
      case 'anxious':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final location = session['location'] as String;
    final duration = session['duration'] as int;
    final temperature = session['temperature'] as int;
    final createdAt = session['created_at'] as String;
    final postMood = session['post_mood'] as String?;

    return Dismissible(
      key: Key(session['id'] as String),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.errorLight,
          borderRadius: BorderRadius.circular(12.0),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        child: const CustomIconWidget(
          iconName: 'delete',
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Session'),
            content: Text('Delete session from $location?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorLight,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (shouldDelete == true) {
          onDelete();
        }

        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Location with icon and mood badge
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'ac_unit',
                    color: AppTheme.accentLight,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      location,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (postMood != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.6.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getMoodColor(postMood),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        postMood.toLowerCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: 0.8.h),

              // Timestamp
              Text(
                _formatDate(createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                  fontSize: 13.sp,
                ),
              ),

              SizedBox(height: 2.h),

              // Bottom row: Duration and Temperature
              Row(
                children: [
                  // Duration
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'timer',
                        color: const Color(0xFF6B7280),
                        size: 16,
                      ),
                      SizedBox(width: 1.5.w),
                      Text(
                        _formatDuration(duration),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF374151),
                          fontWeight: FontWeight.w500,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(width: 5.w),

                  // Temperature
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'thermostat',
                        color: const Color(0xFF6B7280),
                        size: 16,
                      ),
                      SizedBox(width: 1.5.w),
                      Text(
                        '$temperature°F Temperature',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF374151),
                          fontWeight: FontWeight.w500,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
