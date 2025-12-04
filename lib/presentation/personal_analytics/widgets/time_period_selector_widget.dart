import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TimePeriodSelectorWidget extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final List<String> periods;

  const TimePeriodSelectorWidget({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.periods,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      padding: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = period == selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => onPeriodChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(vertical: 2.w),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
