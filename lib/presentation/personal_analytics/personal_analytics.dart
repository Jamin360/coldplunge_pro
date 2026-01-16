import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/utils/chart_utils.dart';
import '../../services/analytics_service.dart';
import './widgets/chart_container_widget.dart';
import './widgets/metrics_card_widget.dart';
import './widgets/progress_goal_widget.dart';

class PersonalAnalytics extends StatefulWidget {
  const PersonalAnalytics({super.key});

  @override
  State<PersonalAnalytics> createState() => _PersonalAnalyticsState();
}

class _PersonalAnalyticsState extends State<PersonalAnalytics> {
  String _selectedPeriod = 'Month';
  final List<String> _periods = ['Week', 'Month', 'Quarter', 'Year'];
  final AnalyticsService _analyticsService = AnalyticsService();

  // Real data from Supabase
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _keyMetrics = [];
  List<Map<String, dynamic>> _sessionFrequencyData = [];
  List<Map<String, dynamic>> _temperatureProgressData = [];
  Map<String, dynamic> _moodData = {};
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _userStats = {};

  // Static achievements data (can be moved to database later)
  final List<Map<String, dynamic>> _achievements = [
    {
      'title': 'Ice Warrior',
      'description': 'Complete 100 cold plunge sessions',
      'icon': 'military_tech',
      'isUnlocked': false,
      'progress': 0.0,
    },
    {
      'title': 'Consistency Master',
      'description': 'Maintain a 30-day streak',
      'icon': 'trending_up',
      'isUnlocked': false,
      'progress': 0.0,
    },
    {
      'title': 'Temperature Champion',
      'description': 'Reach 35°F (1.7°C) water temperature',
      'icon': 'ac_unit',
      'isUnlocked': false,
      'progress': 0.0,
    },
    {
      'title': 'Duration Expert',
      'description': 'Complete a 10-minute session',
      'icon': 'timer',
      'isUnlocked': false,
      'progress': 0.0,
    },
    {
      'title': 'Community Leader',
      'description': 'Share 50 session posts',
      'icon': 'share',
      'isUnlocked': false,
      'progress': 0.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load main analytics data
      final analyticsData = await _analyticsService.getUserAnalytics(
        _selectedPeriod,
      );
      final keyMetrics = _analyticsService.calculateKeyMetrics(analyticsData);

      // Load chart data
      final frequencyData = await _analyticsService.getSessionFrequencyData(
        _selectedPeriod,
      );
      final temperatureData =
          await _analyticsService.getTemperatureProgressData();
      final moodData = await _analyticsService.getMoodAnalytics();

      setState(() {
        _analyticsData = analyticsData;
        _sessionFrequencyData = frequencyData;
        _temperatureProgressData = temperatureData;
        _moodData = moodData;
        _keyMetrics = _buildKeyMetricsFromData(keyMetrics);
        _updateAchievements(keyMetrics);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _buildKeyMetricsFromData(
    Map<String, dynamic> metrics,
  ) {
    // Extract real session count from Supabase user_profiles.total_sessions
    final totalSessions = metrics['totalSessions'] ?? 0;
    final currentStreak = metrics['currentStreak'] ?? 0;
    final avgDuration = metrics['avgDuration'] ?? 0.0;
    final coldestTemp = metrics['coldestTemp'];

    // Format average duration as seconds (rounded to integer)
    final avgDurationSeconds = avgDuration.round();
    final avgDurationStr = _formatDuration(avgDurationSeconds);

    // Format temperature
    String tempStr = 'N/A';
    if (coldestTemp != null) {
      final fahrenheit = ((coldestTemp * 9 / 5) + 32).round();
      tempStr = '${fahrenheit}°F';
    }

    // Get personal best duration from metrics (longest plunge)
    final personalBestDuration = (metrics['personalBestDuration'] ?? 0) as int;
    final personalBestStr = _formatDuration(personalBestDuration);

    return [
      {
        'title': 'Total Sessions',
        'value': totalSessions.toString(), // Real data from Supabase
        'subtitle': 'completed sessions',
        'icon': Icons.timer,
        'isHighlighted': false,
      },
      {
        'title': 'Current Streak',
        'value': currentStreak.toString(),
        'subtitle': 'days in a row',
        'icon': Icons.local_fire_department,
        'iconColor': Colors.orange,
        'isHighlighted': currentStreak >= 7,
      },
      {
        'title': 'Avg Duration',
        'value': avgDurationStr,
        'subtitle': 'Personal best: $personalBestStr',
        'icon': Icons.access_time,
        'isHighlighted': false,
      },
      {
        'title': 'Coldest Temp',
        'value': tempStr,
        'subtitle':
            coldestTemp != null ? '${coldestTemp}°C achieved' : 'No data yet',
        'icon': Icons.ac_unit,
        'iconColor': Colors.blue,
        'isHighlighted': false,
      },
    ];
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}m ${remainingSeconds}s';
    }
  }

  void _updateAchievements(Map<String, dynamic> metrics) {
    final totalSessions = metrics['totalSessions'] ?? 0;
    final currentStreak = metrics['currentStreak'] ?? 0;
    final coldestTemp = metrics['coldestTemp'];
    final avgDuration = metrics['avgDuration'] ?? 0.0;

    // Update achievement progress
    for (var achievement in _achievements) {
      switch (achievement['title']) {
        case 'Ice Warrior':
          achievement['progress'] = (totalSessions / 100.0).clamp(0.0, 1.0);
          achievement['isUnlocked'] = totalSessions >= 100;
          break;
        case 'Consistency Master':
          achievement['progress'] = (currentStreak / 30.0).clamp(0.0, 1.0);
          achievement['isUnlocked'] = currentStreak >= 30;
          break;
        case 'Temperature Champion':
          if (coldestTemp != null) {
            // Target is 1.7°C (35°F)
            achievement['progress'] = ((50 - coldestTemp) / (50 - 1.7)).clamp(
              0.0,
              1.0,
            );
            achievement['isUnlocked'] = coldestTemp <= 1.7;
          }
          break;
        case 'Duration Expert':
          // Target is 10 minutes (600 seconds)
          achievement['progress'] = (avgDuration / 600.0).clamp(0.0, 1.0);
          achievement['isUnlocked'] = avgDuration >= 600;
          break;
        case 'Community Leader':
          // For now, set to 0 as we don't have post data
          achievement['progress'] = 0.0;
          achievement['isUnlocked'] = false;
          break;
      }
    }
  }

  // Updated: Calculate optimal interval for session frequency chart
  double _calculateSessionFrequencyInterval() {
    if (_sessionFrequencyData.isEmpty) return 1.0;

    final counts = _sessionFrequencyData
        .map<double>((data) => (data['sessions'] as num).toDouble())
        .toList();

    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    return ChartUtils.calculateOptimalInterval(0, maxCount * 1.2);
  }

  // Updated: Calculate optimal interval for temperature chart
  double _calculateTemperatureInterval() {
    final validTemps = _temperatureProgressData
        .map<double>((data) => (data['temp'] as num).toDouble())
        .toList();

    if (validTemps.isEmpty) return 10.0;

    final minTemp = ChartUtils.calculateMinTemperature(validTemps);
    final maxTemp = ChartUtils.calculateMaxTemperature(validTemps);

    return ChartUtils.calculateOptimalInterval(minTemp, maxTemp);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F5F5), // Light gray background matching Home page
      appBar: AppBar(
        title: Text(
          'Personal Analytics',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.homeDashboard,
            (route) => false,
          ),
          child: Container(
            margin: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CustomIconWidget(
              iconName: 'arrow_back_ios_new',
              color: colorScheme.onSurface,
              size: 5.w,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              _showExportBottomSheet(context);
            },
            child: Container(
              margin: EdgeInsets.all(2.w),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: 'file_download',
                color: colorScheme.primary,
                size: 5.w,
              ),
            ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  SizedBox(height: 4.w),
                  Text(
                    'Loading analytics...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 12.w,
                        color: colorScheme.error,
                      ),
                      SizedBox(height: 4.w),
                      Text(
                        'Failed to load analytics',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      SizedBox(height: 2.w),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4.w),
                      ElevatedButton(
                        onPressed: _loadAnalyticsData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 3.w),

                      // Time Period Selector - Styled like Challenges filter tabs
                      // TimePeriodSelectorWidget(
                      //   selectedPeriod: _selectedPeriod,
                      //   onPeriodChanged: (period) {
                      //     setState(() {
                      //       _selectedPeriod = period;
                      //     });
                      //     _loadAnalyticsData();
                      //   },
                      //   periods: _periods,
                      // ),

                      // Key Metrics Cards - 2x2 Grid Layout
                      SizedBox(height: 3.w),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 3.w,
                            mainAxisSpacing: 3.w,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: _keyMetrics.length,
                          itemBuilder: (context, index) {
                            final metric = _keyMetrics[index];
                            return MetricsCardWidget(
                              title: metric['title'] as String,
                              value: metric['value'] as String,
                              subtitle: metric['subtitle'] as String,
                              icon: metric['icon'] as IconData,
                              isHighlighted: metric['isHighlighted'] as bool,
                            );
                          },
                        ),
                      ),

                      // Progress Goals
                      if (_analyticsData['weeklyGoal'] != null) ...[
                        SizedBox(height: 3.w),
                        ProgressGoalWidget(
                          title: 'Weekly Goal Progress',
                          currentValue: _analyticsData['weeklyGoal']
                                      ['currentSessions']
                                  ?.toString() ??
                              '0',
                          targetValue: _analyticsData['weeklyGoal']
                                      ['targetSessions']
                                  ?.toString() ??
                              '0',
                          progress: _analyticsData['weeklyGoal']
                                          ['currentSessions'] !=
                                      null &&
                                  _analyticsData['weeklyGoal']
                                          ['targetSessions'] !=
                                      null
                              ? (_analyticsData['weeklyGoal']
                                          ['currentSessions'] /
                                      _analyticsData['weeklyGoal']
                                          ['targetSessions'])
                                  .clamp(0.0, 1.0)
                              : 0.0,
                          motivationalMessage: _getMotivationalMessage(),
                          icon: Icons.flag,
                        ),
                      ],

                      // Session Frequency Chart
                      SizedBox(height: 3.w),
                      if (_sessionFrequencyData.isNotEmpty)
                        ChartContainerWidget(
                          title: 'Session Frequency',
                          subtitle: _selectedPeriod == 'Week'
                              ? 'Sessions per day this week'
                              : 'Sessions per week',
                          chart: Semantics(
                            label: "Session Frequency Bar Chart",
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _getMaxSessionCount().toDouble(),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipBgColor: colorScheme.surface,
                                    tooltipBorder: BorderSide(
                                      color: colorScheme.outline.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                    getTooltipItem: (
                                      group,
                                      groupIndex,
                                      rod,
                                      rodIndex,
                                    ) {
                                      return BarTooltipItem(
                                        '${_sessionFrequencyData[group.x.toInt()]['sessions']} sessions',
                                        TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
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
                                      reservedSize: 30,
                                      getTitlesWidget: (
                                        double value,
                                        TitleMeta meta,
                                      ) {
                                        final index = value.toInt();
                                        if (index >= 0 &&
                                            index <
                                                _sessionFrequencyData.length) {
                                          final label =
                                              _selectedPeriod == 'Week'
                                                  ? _sessionFrequencyData[index]
                                                      ['day'] as String
                                                  : _sessionFrequencyData[index]
                                                      ['week'] as String;
                                          return Padding(
                                            padding: EdgeInsets.only(top: 2.w),
                                            child: Text(
                                              label,
                                              style: TextStyle(
                                                color: colorScheme
                                                    .onSurfaceVariant,
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
                                      reservedSize: 28,
                                      interval:
                                          _calculateSessionFrequencyInterval(),
                                      getTitlesWidget:
                                          (double value, TitleMeta meta) {
                                        return Padding(
                                          padding: EdgeInsets.only(right: 2.w),
                                          child: Text(
                                            ChartUtils.formatCountLabel(value),
                                            style: TextStyle(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups:
                                    _sessionFrequencyData.asMap().entries.map((
                                  entry,
                                ) {
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: (entry.value['sessions'] as num)
                                            .toDouble(),
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.primary.withValues(
                                              alpha: 0.8,
                                            ),
                                            colorScheme.primary,
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                        width: 8.w,
                                        borderRadius: BorderRadius.circular(
                                          4,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval:
                                      _calculateSessionFrequencyInterval(),
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: colorScheme.outline.withValues(
                                        alpha: 0.1,
                                      ),
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Temperature Progress Chart
                      SizedBox(height: 3.w),
                      if (_temperatureProgressData.isNotEmpty)
                        Builder(
                          builder: (context) {
                            // Check if we have actual temperature data
                            final hasActualData =
                                _temperatureProgressData.isNotEmpty;

                            if (!hasActualData) {
                              return Container(
                                margin: EdgeInsets.all(4.w),
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.shadow
                                          .withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.ac_unit,
                                          color: Colors.blue,
                                          size: 6.w,
                                        ),
                                        SizedBox(width: 3.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Temperature Progress',
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  color: colorScheme.onSurface,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(height: 1.w),
                                              Text(
                                                'No temperature data yet',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.w),
                                    Container(
                                      padding: EdgeInsets.all(4.w),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: colorScheme.primary,
                                            size: 5.w,
                                          ),
                                          SizedBox(width: 3.w),
                                          Expanded(
                                            child: Text(
                                              'Complete your first cold plunge session to see your temperature progress over time',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Show actual chart when data exists
                            return ChartContainerWidget(
                              title: 'Temperature Progress',
                              subtitle:
                                  'Last ${_temperatureProgressData.length} sessions',
                              chart: Semantics(
                                label:
                                    "Temperature Progress Line Chart - Last 10 Sessions",
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval:
                                          _calculateTemperatureInterval(),
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: colorScheme.outline
                                              .withValues(alpha: 0.1),
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          getTitlesWidget: (
                                            double value,
                                            TitleMeta meta,
                                          ) {
                                            final index = value.toInt();
                                            if (index >= 0 &&
                                                index <
                                                    _temperatureProgressData
                                                        .length) {
                                              return Padding(
                                                padding:
                                                    EdgeInsets.only(top: 2.w),
                                                child: Text(
                                                  _temperatureProgressData[
                                                          index]['session']
                                                      as String,
                                                  style: TextStyle(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
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
                                          reservedSize: 40,
                                          interval:
                                              _calculateTemperatureInterval(),
                                          getTitlesWidget:
                                              (double value, TitleMeta meta) {
                                            return Padding(
                                              padding:
                                                  EdgeInsets.only(right: 2.w),
                                              child: Text(
                                                ChartUtils
                                                    .formatTemperatureLabel(
                                                        value),
                                                style: TextStyle(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 10.sp,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                        color: colorScheme.outline
                                            .withValues(alpha: 0.1),
                                      ),
                                    ),
                                    minX: 0,
                                    maxX: (_temperatureProgressData.length - 1)
                                        .toDouble(),
                                    minY: _getMinTemperature().toDouble(),
                                    maxY: _getMaxTemperature().toDouble(),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _temperatureProgressData
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          return FlSpot(
                                            entry.key.toDouble(),
                                            (entry.value['temp'] as num)
                                                .toDouble(),
                                          );
                                        }).toList(),
                                        isCurved: true,
                                        color: colorScheme.primary,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: const FlDotData(show: true),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipBgColor: colorScheme.surface,
                                        tooltipBorder: BorderSide(
                                          color: colorScheme.outline
                                              .withValues(alpha: 0.2),
                                        ),
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            final index = spot.x.toInt();
                                            if (index >= 0 &&
                                                index <
                                                    _temperatureProgressData
                                                        .length) {
                                              final temp =
                                                  (_temperatureProgressData[
                                                          index]['temp'] as num)
                                                      .toInt();
                                              return LineTooltipItem(
                                                '$temp°F',
                                                TextStyle(
                                                  color: colorScheme.onSurface,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              );
                                            }
                                            return null;
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      // Bottom spacing only - removed all content below Temperature chart to prevent scrolling
                      SizedBox(height: 4.w),
                    ],
                  ),
                ),
    );
  }

  String _getMotivationalMessage() {
    final weeklyGoal = _analyticsData['weeklyGoal'];
    if (weeklyGoal != null) {
      final current = weeklyGoal['currentSessions'] ?? 0;
      final target = weeklyGoal['targetSessions'] ?? 0;
      final remaining = target - current;

      if (remaining <= 0) {
        return 'Congratulations! You\'ve achieved your weekly goal!';
      } else {
        return 'Just $remaining more sessions to reach your weekly goal!';
      }
    }
    return 'Keep up the great work with your cold plunge journey!';
  }

  int _getMaxSessionCount() {
    if (_sessionFrequencyData.isEmpty) return 6;
    return _sessionFrequencyData
            .map<int>((data) => data['sessions'] as int)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1, 100) +
        1;
  }

  int _getMinTemperature() {
    if (_temperatureProgressData.isEmpty) return 30;

    // Get all temperatures and convert to integers
    final validTemps = _temperatureProgressData
        .map<int>((data) => (data['temp'] as num).toInt())
        .toList();

    if (validTemps.isEmpty) return 30;

    final minTemp = validTemps.reduce((a, b) => a < b ? a : b);
    // Temperature is already in Fahrenheit from database, add padding
    return (minTemp - 10).clamp(0, 150);
  }

  int _getMaxTemperature() {
    if (_temperatureProgressData.isEmpty) return 70;

    // Get all temperatures and convert to integers
    final validTemps = _temperatureProgressData
        .map<int>((data) => (data['temp'] as num).toInt())
        .toList();

    if (validTemps.isEmpty) return 70;

    final maxTemp = validTemps.reduce((a, b) => a > b ? a : b);
    // Temperature is already in Fahrenheit from database, add padding
    return (maxTemp + 10).clamp(40, 150);
  }

  void _showExportBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 1.w,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 4.w),
              Text(
                'Export Analytics',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.w),
              Text(
                'Choose your preferred export format',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 6.w),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _exportPDF();
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            CustomIconWidget(
                              iconName: 'picture_as_pdf',
                              color: colorScheme.primary,
                              size: 8.w,
                            ),
                            SizedBox(height: 2.w),
                            Text(
                              'PDF Report',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 1.w),
                            Text(
                              'Visual analytics with charts',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _exportCSV();
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.secondary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            CustomIconWidget(
                              iconName: 'table_chart',
                              color: colorScheme.secondary,
                              size: 8.w,
                            ),
                            SizedBox(height: 2.w),
                            Text(
                              'CSV Data',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 1.w),
                            Text(
                              'Raw session data for analysis',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.w),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportPDF() async {
    try {
      final message = await _analyticsService.exportToPDF();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _exportCSV() async {
    try {
      final message = await _analyticsService.exportToCSV();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}
