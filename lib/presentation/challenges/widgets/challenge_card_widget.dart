import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ChallengeCardWidget extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final VoidCallback? onTap;

  const ChallengeCardWidget({
    super.key,
    required this.challenge,
    this.onTap,
  });

  // Map difficulty to icon and color
  Map<String, dynamic> _getDifficultyConfig(String difficulty) {
    // Consistent dark gray/slate background for all icons
    const Color iconBackgroundColor = Color(0xFF1E3A5A);
    // Consistent dark navy badge color for all difficulty levels
    const Color badgeColor = Color(0xFF1E3A5A);

    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'beginner':
        return {
          'icon': 'ac_unit',
          'iconColor': Colors.white,
          'backgroundColor': iconBackgroundColor,
          'badgeColor': badgeColor,
          'label': 'BEGINNER'
        };
      case 'medium':
      case 'intermediate':
        return {
          'icon': 'local_fire_department',
          'iconColor': Colors.white,
          'backgroundColor': iconBackgroundColor,
          'badgeColor': badgeColor,
          'label': 'INTERMEDIATE'
        };
      case 'hard':
      case 'advanced':
        return {
          'icon': 'emoji_events',
          'iconColor': Colors.white,
          'backgroundColor': iconBackgroundColor,
          'badgeColor': badgeColor,
          'label': 'ADVANCED'
        };
      default:
        return {
          'icon': 'whatshot',
          'iconColor': Colors.white,
          'backgroundColor': iconBackgroundColor,
          'badgeColor': badgeColor,
          'label': 'BEGINNER'
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = challenge['isActive'] as bool? ?? false;
    final isJoined = challenge['isJoined'] as bool? ?? false;
    final isCompleted = challenge['isCompleted'] as bool? ?? false;
    final progress = (challenge['progress'] as num?)?.toDouble() ?? 0.0;
    final difficulty = challenge['difficulty'] as String? ?? 'beginner';
    final difficultyConfig = _getDifficultyConfig(difficulty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon badge and difficulty badge row
              Row(
                children: [
                  // Colored circular icon badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: difficultyConfig['backgroundColor'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: difficultyConfig['icon'] as String,
                        size: 28,
                        color: difficultyConfig['iconColor'] as Color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Completed badge (if completed)
                  if (isCompleted) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 3.w, vertical: 0.8.h),
                      decoration: BoxDecoration(
                        color: AppTheme.successLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.successLight,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppTheme.successLight,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'COMPLETED',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.successLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.sp,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 2.w),
                  ],
                  // Difficulty badge
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                    decoration: BoxDecoration(
                      color: (difficultyConfig['badgeColor'] as Color)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (difficultyConfig['badgeColor'] as Color)
                            .withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      difficultyConfig['label'] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: difficultyConfig['badgeColor'] as Color,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              // Challenge Title
              Text(
                challenge['title'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 1.5.h),

              // Challenge Description
              Text(
                challenge['description'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 2.h),

              // Goal/Duration
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'flag',
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${challenge['target_value'] ?? 7}-day streak',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Progress Bar (if joined)
              if (isJoined) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor:
                              colorScheme.outline.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                          minHeight: 6,
                        ),
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

              // Removed participants count section

              SizedBox(height: 3.h),

              // Join/Status Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted
                        ? AppTheme.successLight.withValues(alpha: 0.15)
                        : isJoined
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : colorScheme.primary,
                    foregroundColor: isCompleted
                        ? AppTheme.successLight
                        : isJoined
                            ? colorScheme.primary
                            : Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isCompleted
                          ? BorderSide(color: AppTheme.successLight, width: 1.5)
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    isCompleted
                        ? 'View Achievement'
                        : isJoined
                            ? 'View Progress'
                            : 'Join Challenge',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? AppTheme.successLight
                          : isJoined
                              ? colorScheme.primary
                              : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
