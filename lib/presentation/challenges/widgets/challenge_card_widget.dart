import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ChallengeCardWidget extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final VoidCallback? onTap;

  const ChallengeCardWidget({
    super.key,
    required this.challenge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = challenge['isActive'] as bool? ?? false;
    final isJoined = challenge['isJoined'] as bool? ?? false;
    final progress = (challenge['progress'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75.w,
        margin: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: colorScheme.primary, width: 2)
              : Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CustomImageWidget(
                imageUrl: challenge['image'] as String,
                width: double.infinity,
                height: 20.h,
                fit: BoxFit.cover,
                semanticLabel: challenge['semanticLabel'] as String,
              ),
            ),

            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Challenge Title and Difficulty
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          challenge['title'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildDifficultyBadge(
                          context, challenge['difficulty'] as String),
                    ],
                  ),

                  SizedBox(height: 2.h),

                  // Challenge Description
                  Text(
                    challenge['description'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 3.h),

                  // Progress Bar (if joined)
                  if (isJoined) ...[
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor:
                                colorScheme.outline.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${progress.toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                  ],

                  // Challenge Stats
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'people',
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${challenge['participants']} joined',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      CustomIconWidget(
                        iconName: 'schedule',
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        challenge['timeLeft'] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Join/Status Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isJoined
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : colorScheme.primary,
                        foregroundColor: isJoined
                            ? colorScheme.primary
                            : colorScheme.onPrimary,
                        elevation: isJoined ? 0 : 2,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                      ),
                      child: Text(
                        isJoined ? 'View Progress' : 'Join Challenge',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(BuildContext context, String difficulty) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color badgeColor;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        badgeColor = AppTheme.successLight;
        break;
      case 'medium':
        badgeColor = AppTheme.warningLight;
        break;
      case 'hard':
        badgeColor = AppTheme.errorLight;
        break;
      default:
        badgeColor = colorScheme.primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 10.sp,
        ),
      ),
    );
  }
}
