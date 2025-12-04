import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class MoodAnalyticsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> moodData;

  const MoodAnalyticsWidget({
    super.key,
    required this.moodData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood Analytics',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.w),
                    Text(
                      'Pre vs post-plunge mood improvement',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'mood',
                      color: colorScheme.primary,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Last 7 Days',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 4.w),

          // Mood improvement stats
          Row(
            children: [
              Expanded(
                child: _buildMoodStat(
                  'Avg Improvement',
                  _calculateAverageImprovement(),
                  colorScheme.secondary,
                  context,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: _buildMoodStat(
                  'Best Day',
                  _getBestImprovementDay(),
                  colorScheme.tertiary,
                  context,
                ),
              ),
            ],
          ),

          SizedBox(height: 4.w),

          // Chart
          if (moodData.isNotEmpty) ...[
            SizedBox(
              height: 45.w,
              child: Semantics(
                label: "Mood Analytics Line Chart",
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 2,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: colorScheme.outline.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        );
                      },
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
                          reservedSize: 30,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < moodData.length) {
                              return Padding(
                                padding: EdgeInsets.only(top: 2.w),
                                child: Text(
                                  moodData[index]['day'] as String,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 2,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                                fontSize: 10.sp,
                              ),
                            );
                          },
                          reservedSize: 32,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    minX: 0,
                    maxX: (moodData.length - 1).toDouble(),
                    minY: 1,
                    maxY: 10,
                    lineBarsData: [
                      // Pre-mood line
                      LineChartBarData(
                        spots: moodData.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            (entry.value['preMood'] as num).toDouble(),
                          );
                        }).toList(),
                        isCurved: true,
                        color: colorScheme.error,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: colorScheme.error,
                              strokeWidth: 2,
                              strokeColor: colorScheme.surface,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(show: false),
                      ),
                      // Post-mood line
                      LineChartBarData(
                        spots: moodData.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            (entry.value['postMood'] as num).toDouble(),
                          );
                        }).toList(),
                        isCurved: true,
                        color: colorScheme.secondary,
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: colorScheme.secondary,
                              strokeWidth: 2,
                              strokeColor: colorScheme.surface,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 3.w),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(
                  'Pre-Plunge',
                  colorScheme.error,
                  context,
                ),
                _buildLegendItem(
                  'Post-Plunge',
                  colorScheme.secondary,
                  context,
                ),
              ],
            ),
          ] else ...[
            Container(
              height: 30.w,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'mood',
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 32,
                    ),
                    SizedBox(height: 2.w),
                    Text(
                      'No mood data available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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

  Widget _buildMoodStat(
    String label,
    String value,
    Color color,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 1.w),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4.w,
          height: 2.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _calculateAverageImprovement() {
    if (moodData.isEmpty) return '+0.0';

    double totalImprovement = 0;
    for (final data in moodData) {
      final pre = (data['preMood'] as num).toDouble();
      final post = (data['postMood'] as num).toDouble();
      totalImprovement += (post - pre);
    }

    final avg = totalImprovement / moodData.length;
    return avg >= 0 ? '+${avg.toStringAsFixed(1)}' : avg.toStringAsFixed(1);
  }

  String _getBestImprovementDay() {
    if (moodData.isEmpty) return '-';

    double bestImprovement = -10;
    String bestDay = '-';

    for (final data in moodData) {
      final pre = (data['preMood'] as num).toDouble();
      final post = (data['postMood'] as num).toDouble();
      final improvement = post - pre;

      if (improvement > bestImprovement) {
        bestImprovement = improvement;
        bestDay = data['day'] as String;
      }
    }

    return bestDay;
  }
}
