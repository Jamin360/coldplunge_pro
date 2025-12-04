import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActiveChallengeWidget extends StatelessWidget {
  final Map<String, dynamic>? activeChallenge;
  final VoidCallback? onTap;

  const ActiveChallengeWidget({
    super.key,
    this.activeChallenge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (activeChallenge == null) {
      return _buildEmptyState(context);
    }

    final progress = (activeChallenge!['progress'] as num?)?.toDouble() ?? 0.0;
    final currentStreak = activeChallenge!['currentStreak'] as int? ?? 0;
    final targetStreak = activeChallenge!['targetStreak'] as int? ?? 7;
    final position = activeChallenge!['leaderboardPosition'] as int? ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ACTIVE CHALLENGE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                if (position > 0)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: 'emoji_events',
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '#$position',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            SizedBox(height: 3.h),

            // Challenge Title
            Text(
              activeChallenge!['title'] as String,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 2.h),

            // Progress Section
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor:
                            colorScheme.onPrimary.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.accentLight,
                        ),
                        minHeight: 8,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '${progress.toInt()}% Complete',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$currentStreak',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppTheme.accentLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Day Streak',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        'of $targetStreak',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Time Remaining
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'schedule',
                  size: 20,
                  color: colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
                SizedBox(width: 2.w),
                Text(
                  '${activeChallenge!['timeLeft']} remaining',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                CustomIconWidget(
                  iconName: 'arrow_forward_ios',
                  size: 16,
                  color: colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'emoji_events_outlined',
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'No Active Challenge',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Join a challenge below to start your cold plunge journey',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
