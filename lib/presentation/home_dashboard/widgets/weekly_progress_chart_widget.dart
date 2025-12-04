import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class WeeklyProgressChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;

  const WeeklyProgressChartWidget({super.key, required this.weeklyData});

  // Calculate dynamic maxY based on data to prevent overflow
  double _calculateMaxY() {
    if (weeklyData.isEmpty) return 10.0;

    final maxDuration = weeklyData
        .map((data) => (data['duration'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    // Add 20% padding and round to nearest 5
    final paddedMax = maxDuration * 1.2;
    return (paddedMax / 5).ceil() * 5.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
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
              Text(
                'Weekly Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              CustomIconWidget(
                iconName: 'show_chart',
                color: colorScheme.primary,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 3.h),
          // Fixed: Constrained chart container to prevent overflow
          Container(
            height: 20.h,
            width: double.infinity,
            child: Semantics(
              label: "Weekly Cold Plunge Progress Bar Chart",
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxY(), // Dynamic maxY based on data
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: colorScheme.inverseSurface,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (group.x.toInt() >= weeklyData.length) return null;
                        final day =
                            weeklyData[group.x.toInt()]['day'] as String;
                        final duration = rod.toY.toInt();
                        return BarTooltipItem(
                          '$day\n$duration min',
                          theme.textTheme.bodySmall!.copyWith(
                            color: colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() < weeklyData.length) {
                            return Padding(
                              padding: EdgeInsets.only(top: 1.h),
                              child: Text(
                                weeklyData[value.toInt()]['day'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _calculateMaxY() / 5, // Dynamic interval
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: EdgeInsets.only(right: 1.w),
                            child: Text(
                              '${value.toInt()}m',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                                fontSize:
                                    10.sp, // Smaller font to prevent overflow
                              ),
                            ),
                          );
                        },
                        reservedSize: 35,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups:
                      weeklyData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final duration = (data['duration'] as num).toDouble();
                        final hasPlunge = data['hasPlunge'] as bool;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: duration,
                              color:
                                  hasPlunge
                                      ? colorScheme.primary
                                      : colorScheme.outline.withValues(
                                        alpha: 0.3,
                                      ),
                              width:
                                  3.5.w, // Slightly narrower bars for better fit
                              borderRadius: BorderRadius.circular(4),
                              gradient:
                                  hasPlunge
                                      ? LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          colorScheme.primary,
                                          colorScheme.secondary,
                                        ],
                                      )
                                      : null,
                            ),
                          ],
                        );
                      }).toList(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateMaxY() / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(context, 'Completed', colorScheme.primary),
              _buildLegendItem(
                context,
                'Missed',
                colorScheme.outline.withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 2.w),
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
}
