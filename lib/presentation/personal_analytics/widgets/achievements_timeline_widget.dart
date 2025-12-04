import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AchievementsTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;

  const AchievementsTimelineWidget({
    super.key,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
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
              CustomIconWidget(
                iconName: 'emoji_events',
                color: colorScheme.tertiary,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievements Timeline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Your milestone celebrations',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 4.w),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: achievements.length > 3 ? 3 : achievements.length,
            separatorBuilder: (context, index) => SizedBox(height: 3.w),
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _buildAchievementItem(context, achievement);
            },
          ),
          if (achievements.length > 3) ...[
            SizedBox(height: 3.w),
            GestureDetector(
              onTap: () {
                // Navigate to full achievements screen
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 3.w),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View All ${achievements.length} Achievements',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    CustomIconWidget(
                      iconName: 'arrow_forward_ios',
                      color: colorScheme.primary,
                      size: 3.w,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementItem(
      BuildContext context, Map<String, dynamic> achievement) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUnlocked = achievement['isUnlocked'] as bool;

    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: isUnlocked
                ? colorScheme.tertiary.withValues(alpha: 0.1)
                : colorScheme.outline.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnlocked
                  ? colorScheme.tertiary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: achievement['icon'] as String,
              color: isUnlocked
                  ? colorScheme.tertiary
                  : colorScheme.outline.withValues(alpha: 0.5),
              size: 6.w,
            ),
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement['title'] as String,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isUnlocked
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.w),
              Text(
                achievement['description'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isUnlocked) ...[
                SizedBox(height: 1.w),
                Text(
                  'Unlocked ${achievement['unlockedDate'] as String}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.w500,
                    fontSize: 10.sp,
                  ),
                ),
              ] else ...[
                SizedBox(height: 1.w),
                LinearProgressIndicator(
                  value: (achievement['progress'] as num).toDouble(),
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.1),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.tertiary),
                  minHeight: 1.w,
                ),
                SizedBox(height: 1.w),
                Text(
                  '${((achievement['progress'] as num) * 100).toInt()}% complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
