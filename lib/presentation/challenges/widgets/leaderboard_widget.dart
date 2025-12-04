import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LeaderboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboardData;
  final int? currentUserPosition;

  const LeaderboardWidget({
    super.key,
    required this.leaderboardData,
    this.currentUserPosition,
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
          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'leaderboard',
                  size: 24,
                  color: colorScheme.primary,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Leaderboard',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (currentUserPosition != null)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'You: #$currentUserPosition',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Top 3 Podium
          if (leaderboardData.length >= 3) _buildPodium(context),

          // Remaining positions
          if (leaderboardData.length > 3)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              itemCount: leaderboardData.length - 3,
              separatorBuilder: (context, index) => SizedBox(height: 1.h),
              itemBuilder: (context, index) {
                final participant = leaderboardData[index + 3];
                final position = index + 4;
                return _buildLeaderboardItem(context, participant, position);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPodium(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (leaderboardData.length >= 2)
            _buildPodiumPosition(context, leaderboardData[1], 2, 12.h),

          // 1st Place
          _buildPodiumPosition(context, leaderboardData[0], 1, 16.h),

          // 3rd Place
          if (leaderboardData.length >= 3)
            _buildPodiumPosition(context, leaderboardData[2], 3, 10.h),
        ],
      ),
    );
  }

  Widget _buildPodiumPosition(BuildContext context,
      Map<String, dynamic> participant, int position, double height) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCurrentUser = participant['isCurrentUser'] as bool? ?? false;

    Color positionColor;
    switch (position) {
      case 1:
        positionColor = const Color(0xFFFFD700); // Gold
        break;
      case 2:
        positionColor = const Color(0xFFC0C0C0); // Silver
        break;
      case 3:
        positionColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        positionColor = colorScheme.primary;
    }

    return Column(
      children: [
        // Avatar with crown/medal
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: EdgeInsets.only(top: 1.h),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentUser ? colorScheme.primary : positionColor,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: CustomImageWidget(
                  imageUrl: participant['avatar'] as String,
                  width: 15.w,
                  height: 15.w,
                  fit: BoxFit.cover,
                  semanticLabel: participant['avatarSemanticLabel'] as String,
                ),
              ),
            ),
            if (position == 1)
              CustomIconWidget(
                iconName: 'emoji_events',
                size: 24,
                color: positionColor,
              ),
          ],
        ),

        SizedBox(height: 1.h),

        // Name
        Text(
          participant['name'] as String,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isCurrentUser ? colorScheme.primary : colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // Score
        Text(
          '${participant['score']} days',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        SizedBox(height: 1.h),

        // Podium base
        Container(
          width: 20.w,
          height: height,
          decoration: BoxDecoration(
            color: positionColor.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: positionColor.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(
              '$position',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: positionColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(
      BuildContext context, Map<String, dynamic> participant, int position) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCurrentUser = participant['isCurrentUser'] as bool? ?? false;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colorScheme.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: colorScheme.primary.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          // Position
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          SizedBox(width: 3.w),

          // Avatar
          ClipOval(
            child: CustomImageWidget(
              imageUrl: participant['avatar'] as String,
              width: 10.w,
              height: 10.w,
              fit: BoxFit.cover,
              semanticLabel: participant['avatarSemanticLabel'] as String,
            ),
          ),

          SizedBox(width: 3.w),

          // Name and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant['name'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCurrentUser
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${participant['score']} day streak',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Friend indicator
          if (participant['isFriend'] as bool? ?? false)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: AppTheme.successLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Friend',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.successLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
