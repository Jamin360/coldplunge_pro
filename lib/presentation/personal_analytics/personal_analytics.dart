import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
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
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  String _selectedPeriod = 'Month';
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isInitialized = false;

  // Real data from Supabase
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _keyMetrics = [];
  List<Map<String, dynamic>> _sessionFrequencyData = [];
  List<Map<String, dynamic>> _temperatureProgressData = [];
  bool _isLoading = true;
  String? _errorMessage;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data every time the screen becomes visible
    // (except on first build which is handled by initState)
    if (_isInitialized) {
      _loadAnalyticsData();
    } else {
      _isInitialized = true;
    }
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
      await _analyticsService.getMoodAnalytics();

      setState(() {
        _analyticsData = analyticsData;
        _sessionFrequencyData = frequencyData;
        _temperatureProgressData = temperatureData;
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

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await _loadAnalyticsData();
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
    String tempSubtitle = 'No data yet';
    if (coldestTemp != null) {
      // Temperature is already stored in Fahrenheit in the database
      tempStr = '${coldestTemp}°F';
      // Convert Fahrenheit to Celsius for subtitle
      final celsius = ((coldestTemp - 32) * 5 / 9).round();
      tempSubtitle = '${celsius}°C achieved';
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
        'subtitle': tempSubtitle,
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
            // Target is 35°F (temperature is stored in Fahrenheit)
            // Progress from 70°F down to 35°F
            achievement['progress'] = ((70 - coldestTemp) / (70 - 35)).clamp(
              0.0,
              1.0,
            );
            achievement['isUnlocked'] = coldestTemp <= 35;
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
    return ChartUtils.calculateSessionFrequencyInterval(maxCount);
  }

  // Updated: Calculate optimal interval for temperature chart
  double _calculateTemperatureInterval() {
    final validTemps = _temperatureProgressData
        .map<double>((data) => (data['temp'] as num).toDouble())
        .toList();

    if (validTemps.isEmpty) return 10.0;

    final minTemp = _getMinTemperature().toDouble();
    final maxTemp = _getMaxTemperature().toDouble();

    return ChartUtils.calculateTemperatureInterval(minTemp, maxTemp);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F5F5,
      ), // Light gray background matching Home page
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
            onTap: _exportToPdf,
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
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        child: _isLoading
            ? _buildScrollableLoadingState(colorScheme, theme)
            : _errorMessage != null
                ? _buildScrollableErrorState(colorScheme, theme)
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                      getTooltipItem:
                                          (group, groupIndex, rod, rodIndex) {
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
                                        getTitlesWidget:
                                            (double value, TitleMeta meta) {
                                          final index = value.toInt();
                                          if (index >= 0 &&
                                              index <
                                                  _sessionFrequencyData
                                                      .length) {
                                            final label = _selectedPeriod ==
                                                    'Week'
                                                ? _sessionFrequencyData[index]
                                                    ['day'] as String
                                                : _sessionFrequencyData[index]
                                                    ['week'] as String;
                                            return Padding(
                                              padding:
                                                  EdgeInsets.only(top: 2.w),
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
                                        reservedSize: 45,
                                        interval:
                                            _calculateSessionFrequencyInterval(),
                                        getTitlesWidget:
                                            (double value, TitleMeta meta) {
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            fitInside:
                                                const SideTitleFitInsideData(
                                              enabled: true,
                                              axisPosition: 0,
                                              parentAxisSize: 45,
                                              distanceFromEdge: 0,
                                            ),
                                            child: Text(
                                              ChartUtils.formatCountLabel(
                                                  value),
                                              style: TextStyle(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 9.sp,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barGroups: _sessionFrequencyData
                                      .asMap()
                                      .entries
                                      .map((entry) {
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
                                          borderRadius:
                                              BorderRadius.circular(4),
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
                                        color: colorScheme.shadow.withValues(
                                          alpha: 0.05,
                                        ),
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
                                                    color:
                                                        colorScheme.onSurface,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(height: 1.w),
                                                Text(
                                                  'No temperature data yet',
                                                  style: theme
                                                      .textTheme.bodySmall
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
                                          color: colorScheme.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                            color:
                                                colorScheme.outline.withValues(
                                              alpha: 0.1,
                                            ),
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
                                            getTitlesWidget:
                                                (double value, TitleMeta meta) {
                                              final index = value.toInt();
                                              if (index >= 0 &&
                                                  index <
                                                      _temperatureProgressData
                                                          .length) {
                                                final sessionLabel =
                                                    _temperatureProgressData[
                                                            index]['session']
                                                        as String;
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 2.w,
                                                  ),
                                                  child: Text(
                                                    sessionLabel,
                                                    style: TextStyle(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 10.sp,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 50,
                                            interval:
                                                _calculateTemperatureInterval(),
                                            getTitlesWidget:
                                                (double value, TitleMeta meta) {
                                              final interval =
                                                  _calculateTemperatureInterval();
                                              // Only show labels divisible by interval to prevent overlapping
                                              if (value % interval != 0) {
                                                return const SizedBox.shrink();
                                              }
                                              return SideTitleWidget(
                                                axisSide: meta.axisSide,
                                                fitInside:
                                                    const SideTitleFitInsideData(
                                                  enabled: true,
                                                  axisPosition: 0,
                                                  parentAxisSize: 50,
                                                  distanceFromEdge: 0,
                                                ),
                                                child: Text(
                                                  '${ChartUtils.formatTemperatureLabel(value)}°F',
                                                  style: TextStyle(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 9.sp,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border.all(
                                          color: colorScheme.outline.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                      ),
                                      minX: 0,
                                      maxX:
                                          (_temperatureProgressData.length - 1)
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
                                            color:
                                                colorScheme.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                          ),
                                        ),
                                      ],
                                      lineTouchData: LineTouchData(
                                        touchTooltipData: LineTouchTooltipData(
                                          tooltipBgColor: colorScheme.surface,
                                          tooltipBorder: BorderSide(
                                            color:
                                                colorScheme.outline.withValues(
                                              alpha: 0.2,
                                            ),
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
                                                                index]['temp']
                                                            as num)
                                                        .toInt();
                                                return LineTooltipItem(
                                                  '$temp°F',
                                                  TextStyle(
                                                    color:
                                                        colorScheme.onSurface,
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
    final maxTemp = validTemps.reduce((a, b) => a > b ? a : b);
    final range = maxTemp - minTemp;

    // Use interval of 10 for larger ranges, 5 for smaller ranges
    final interval = range > 20 ? 10 : 5;

    // Round down to nearest interval, with padding
    final roundedMin = ((minTemp - interval) ~/ interval) * interval;
    // Only prevent negative temperatures, don't force 0
    return roundedMin < 0 ? 0 : roundedMin;
  }

  int _getMaxTemperature() {
    if (_temperatureProgressData.isEmpty) return 70;

    // Get all temperatures and convert to integers
    final validTemps = _temperatureProgressData
        .map<int>((data) => (data['temp'] as num).toInt())
        .toList();

    if (validTemps.isEmpty) return 70;

    final minTemp = validTemps.reduce((a, b) => a < b ? a : b);
    final maxTemp = validTemps.reduce((a, b) => a > b ? a : b);
    final range = maxTemp - minTemp;

    // Use interval of 10 for larger ranges, 5 for smaller ranges
    final interval = range > 20 ? 10 : 5;

    // Round up to nearest interval, with padding
    final roundedMax = ((maxTemp + interval) / interval).ceil() * interval;
    // Ensure max is at least 20 degrees above min for readable chart
    final calculatedMin = _getMinTemperature();
    return roundedMax < (calculatedMin + 20) ? calculatedMin + 20 : roundedMax;
  }

  Widget _buildScrollableLoadingState(
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 40.h),
        Center(
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
        ),
      ],
    );
  }

  Widget _buildScrollableErrorState(
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 30.h),
        Center(
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 4.w),
              ElevatedButton(
                onPressed: _loadAnalyticsData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportToPdf() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generating PDF...'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final pdf = pw.Document();

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Personal Analytics',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'ColdPlunge Pro',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    DateTime.now().toString().split(' ')[0],
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Key Metrics Section
            pw.Text(
              'Key Metrics',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _keyMetrics.map((metric) {
                return pw.Container(
                  width: 160,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(
                      color: PdfColors.blue200,
                      width: 1,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        metric['title'] as String,
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        metric['value'] as String,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      if (metric['subtitle'] != null) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          metric['subtitle'] as String,
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 24),

            // Statistics Summary
            pw.Text(
              'Statistics Summary',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 1,
              ),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue50,
                  ),
                  children: [
                    _buildTableCell('Metric', isHeader: true),
                    _buildTableCell('Value', isHeader: true),
                  ],
                ),
                // Data rows
                _buildTableRow('Total Sessions',
                    '${_analyticsData['total_sessions'] ?? 0}'),
                _buildTableRow(
                    'Total Time',
                    _formatTotalDuration(
                        _analyticsData['total_duration'] as int? ?? 0)),
                _buildTableRow(
                    'Average Duration',
                    _formatDuration(
                        _analyticsData['avg_duration'] as int? ?? 0)),
                _buildTableRow('Current Streak',
                    '${_analyticsData['current_streak'] ?? 0} days'),
                _buildTableRow('Longest Streak',
                    '${_analyticsData['longest_streak'] ?? 0} days'),
                _buildTableRow('Average Temperature',
                    '${(_analyticsData['avg_temperature'] as num?)?.toStringAsFixed(1) ?? 'N/A'}°F'),
                _buildTableRow('Coldest Plunge',
                    '${_analyticsData['coldest_plunge'] ?? 'N/A'}°F'),
                _buildTableRow(
                    'Personal Best',
                    _formatDuration(
                        _analyticsData['personal_best'] as int? ?? 0)),
              ],
            ),
            pw.SizedBox(height: 24),

            // Session Frequency (if available)
            if (_sessionFrequencyData.isNotEmpty) ...[
              pw.Text(
                'Session Frequency',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Recent session activity by day of week',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: _sessionFrequencyData.map((data) {
                  final count = data['sessions'] as int? ?? 0;
                  final label = _selectedPeriod == 'Week'
                      ? (data['day'] as String? ?? '')
                      : (data['week'] as String? ?? '');
                  return pw.Column(
                    children: [
                      pw.Container(
                        height: 80,
                        width: 40,
                        child: pw.Stack(
                          children: [
                            pw.Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: pw.Container(
                                height: count > 0
                                    ? (count * 10).toDouble().clamp(5, 80)
                                    : 0,
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.blue400,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        label,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        count.toString(),
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              pw.SizedBox(height: 24),
            ],

            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated by ColdPlunge Pro',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page 1',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      // Save the PDF
      final output = await getTemporaryDirectory();
      final file = File(
          '${output.path}/analytics_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My ColdPlunge Pro Analytics Report',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF generated successfully!'),
            backgroundColor: AppTheme.successLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        _buildTableCell(label),
        _buildTableCell(value),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue900 : PdfColors.grey800,
        ),
      ),
    );
  }

  String _formatTotalDuration(int seconds) {
    if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes min';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  void _showComingSoonDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.all(6.w),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 12.w, color: colorScheme.primary),
              SizedBox(height: 4.w),
              Text(
                'Coming Soon!',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.w),
              Text(
                'Export feature coming soon!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.w),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 3.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
