import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecentSessionCardWidget extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback? onView;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const RecentSessionCardWidget({
    super.key,
    required this.session,
    this.onView,
    this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Slidable(
      key: ValueKey(session['id']),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _shareSession(),
            backgroundColor: AppTheme.warningLight,
            foregroundColor: Colors.white,
            icon: Icons.share,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onDelete?.call(),
            backgroundColor: AppTheme.errorLight,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onView,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(4.w),
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
                  Expanded(
                    child: Row(
                      children: [
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session['location'] as String? ??
                                    'Unknown Location',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _formatDate(
                                  DateTime.parse(
                                    session['created_at'] as String,
                                  ),
                                ),
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
                  ),
                  if (session['post_mood'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getMoodColor(
                          session['post_mood'] as String,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getMoodColor(
                            session['post_mood'] as String,
                          ).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        session['post_mood'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getMoodColor(session['post_mood'] as String),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Duration',
                      _formatDuration((session['duration'] ?? 0) as int),
                      'timer',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 4.h,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Temperature',
                      '${session['temperature'] ?? 0}°F',
                      'thermostat',
                    ),
                  ),
                ],
              ),
              if (session['notes'] != null &&
                  (session['notes'] as String).isNotEmpty) ...[
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
                    session['notes'] as String,
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

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    String iconName,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: colorScheme.onSurfaceVariant,
          size: 16,
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
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

  String _formatDate(DateTime date) {
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

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'visibility',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                onView?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: AppTheme.warningLight,
                size: 24,
              ),
              title: const Text('Share Session'),
              onTap: () {
                Navigator.pop(context);
                _shareSession();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.errorLight,
                size: 24,
              ),
              title: const Text('Delete Session'),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
