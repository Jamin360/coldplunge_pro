import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}m ${remainingSeconds}s';
    }
  }

  Color _getMoodColor(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'euphoric':
      case 'energized':
        return AppTheme.successLight;
      case 'focused':
      case 'calm':
        return AppTheme.primaryLight;
      case 'neutral':
        return AppTheme.warningLight;
      case 'tired':
      case 'stressed':
      case 'anxious':
        return AppTheme.errorLight;
      default:
        return AppTheme.primaryLight;
    }
  }

  void _shareSession() {
    final location = session['location'] as String;
    final duration = session['duration'] as int;
    final temperature = session['temperature'] as int;
    final postMood = session['post_mood'] as String?;
    final notes = session['notes'] as String?;

    final shareText = '🧊 Cold Plunge Complete!\n\n'
        '📍 Location: $location\n'
        '⏱️ Duration: ${duration}s\n'
        '🌡️ Temperature: ${temperature}°F\n'
        '💭 Mood: ${postMood ?? 'Not recorded'}\n'
        '${notes != null && notes.isNotEmpty ? '📝 Notes: $notes\n\n' : '\n'}'
        'Tracked with ColdPlunge Pro 💪';

    Share.share(shareText);
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
    final notes = session['notes'] as String?;

    return Dismissible(
      key: Key(session['id'] as String),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.warningLight,
          borderRadius: BorderRadius.circular(16.0),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 4.w),
        child: const CustomIconWidget(
          iconName: 'share',
          color: Colors.white,
          size: 24,
        ),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.errorLight,
          borderRadius: BorderRadius.circular(16.0),
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
        if (direction == DismissDirection.startToEnd) {
          // Share action
          _shareSession();
          return false;
        } else {
          // Delete action
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
        }
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
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
              // Top row: Snowflake icon, location/date, and mood badge
              Row(
                children: [
                  // Snowflake icon in blue circular badge
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'ac_unit',
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Location name and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatDate(createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mood badge in top-right
                  if (postMood != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getMoodColor(postMood).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getMoodColor(postMood).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        postMood,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getMoodColor(postMood),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 2.h),

              // Duration and Temperature in two-column layout with icons above values
              Row(
                children: [
                  // Duration column
                  Expanded(
                    child: Column(
                      children: [
                        CustomIconWidget(
                          iconName: 'timer',
                          color: colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _formatDuration(duration),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Duration',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    height: 4.h,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  // Temperature column
                  Expanded(
                    child: Column(
                      children: [
                        CustomIconWidget(
                          iconName: 'thermostat',
                          color: colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '${temperature}°F',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Temperature',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Notes in italic gray text at bottom if present
              if (notes != null && notes.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notes,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
