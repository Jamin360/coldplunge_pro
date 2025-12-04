import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ChallengeFilterWidget extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const ChallengeFilterWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filters = [
      {'key': 'all', 'label': 'All', 'icon': 'apps'},
      {'key': 'active', 'label': 'Active', 'icon': 'play_circle'},
      {'key': 'upcoming', 'label': 'Upcoming', 'icon': 'schedule'},
      {'key': 'completed', 'label': 'Completed', 'icon': 'check_circle'},
    ];

    return Container(
      height: 6.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['key'];

          return GestureDetector(
            onTap: () => onFilterChanged(filter['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: filter['icon'] as String,
                    size: 18,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    filter['label'] as String,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
