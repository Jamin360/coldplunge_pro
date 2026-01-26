import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StatsSectionWidget extends StatelessWidget {
  final double currentProgress;
  final int targetValue;
  final String challengeType;
  final String daysRemaining;
  final String? dateJoined;

  const StatsSectionWidget({
    super.key,
    required this.currentProgress,
    required this.targetValue,
    required this.challengeType,
    required this.daysRemaining,
    this.dateJoined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentValue = (currentProgress * targetValue / 100).round();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Stats',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: 'trending_up',
                  label: 'Current / Goal',
                  value: '$currentValue / $targetValue',
                  subtitle: _getChallengeTypeLabel(),
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: 'schedule',
                  label: 'Remaining',
                  value: daysRemaining,
                  subtitle: 'Until deadline',
                  color: AppTheme.warningLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.w),
          if (dateJoined != null)
            _buildStatCard(
              context,
              icon: 'calendar_today',
              label: 'Date Joined',
              value: _formatDate(dateJoined!),
              subtitle: _calculateDaysActive(),
              color: AppTheme.accentLight,
              isFullWidth: true,
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    bool isFullWidth = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
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
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: icon,
                  size: 20,
                  color: color,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getChallengeTypeLabel() {
    switch (challengeType) {
      case 'streak':
        return 'Day streak';
      case 'duration':
        return 'Seconds';
      case 'temperature':
        return 'Temperature (°F)';
      case 'consistency':
        return 'Sessions';
      default:
        return 'Progress';
    }
  }

  String _formatDate(String dateStr) {
    try {
      // Parse UTC timestamp from database and convert to local time
      final date = DateTime.parse(dateStr).toLocal();
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
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _calculateDaysActive() {
    if (dateJoined == null) return '';

    try {
      final joined = DateTime.parse(dateJoined!);
      final now = DateTime.now();
      final days = now.difference(joined).inDays;

      if (days == 0) return 'Joined today';
      if (days == 1) return '1 day active';
      return '$days days active';
    } catch (e) {
      return '';
    }
  }
}
