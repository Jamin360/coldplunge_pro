import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/performance_logger.dart';
import '../../services/auth_service.dart';
import '../../services/data_cache_service.dart';
import '../../services/session_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/skeleton_loader.dart';
import './widgets/quick_stats_card_widget.dart';
import './widgets/recent_session_card_widget.dart';
import './widgets/streak_counter_widget.dart';
import './widgets/weather_widget.dart';
import './widgets/weekly_progress_chart_widget.dart';

/// Optimized Home Dashboard Tab with caching and performance improvements
class HomeDashboardTab extends StatefulWidget {
  const HomeDashboardTab({super.key});

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  bool get wantKeepAlive => true; // Preserve state when switching tabs

  // Cached futures to prevent rebuilds from recreating them
  Future<List<Map<String, dynamic>>>? _recentSessionsFuture;
  Future<List<Map<String, dynamic>>>? _weeklyDataFuture;
  Future<Map<String, dynamic>>? _userStatsFuture;
  Future<bool>? _hasPlungedTodayFuture;

  @override
  void initState() {
    super.initState();
    PerformanceLogger.start('HomeDashboardTab.initState');

    _loadDashboardData();

    PerformanceLogger.end('HomeDashboardTab.initState');

    // Load heavy widgets after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PerformanceLogger.log('HomeDashboardTab first frame rendered');
    });
  }

  void _loadDashboardData({bool forceRefresh = false}) {
    if (!AuthService.instance.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      });
      return;
    }

    final cache = DataCacheService.instance;
    const cacheDuration = Duration(minutes: 5);

    // Use cached futures or create new ones
    if (forceRefresh || !cache.has('recent_sessions')) {
      _recentSessionsFuture =
          SessionService.instance.getRecentSessions(limit: 5);
      _recentSessionsFuture!.then((data) {
        cache.set('recent_sessions', data, cacheDuration);
      });
    } else {
      _recentSessionsFuture = Future.value(
          cache.get<List<Map<String, dynamic>>>('recent_sessions'));
    }

    if (forceRefresh || !cache.has('weekly_data')) {
      _weeklyDataFuture = SessionService.instance.getWeeklyProgress();
      _weeklyDataFuture!.then((data) {
        cache.set('weekly_data', data, cacheDuration);
      });
    } else {
      _weeklyDataFuture =
          Future.value(cache.get<List<Map<String, dynamic>>>('weekly_data'));
    }

    if (forceRefresh || !cache.has('user_stats')) {
      _userStatsFuture = AuthService.instance.getUserStats();
      _userStatsFuture!.then((data) {
        cache.set('user_stats', data, cacheDuration);
      });
    } else {
      _userStatsFuture =
          Future.value(cache.get<Map<String, dynamic>>('user_stats'));
    }

    if (forceRefresh || !cache.has('has_plunged_today')) {
      _hasPlungedTodayFuture = AuthService.instance.hasSessionToday();
      _hasPlungedTodayFuture!.then((data) {
        cache.set('has_plunged_today', data, const Duration(minutes: 10));
      });
    } else {
      _hasPlungedTodayFuture =
          Future.value(cache.get<bool>('has_plunged_today'));
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    PerformanceLogger.start('HomeDashboardTab.refresh');

    // Clear cache and reload
    DataCacheService.instance.clearAll();
    setState(() {
      _loadDashboardData(forceRefresh: true);
    });

    // Wait for all futures to complete
    await Future.wait([
      _recentSessionsFuture!,
      _weeklyDataFuture!,
      _userStatsFuture!,
      _hasPlungedTodayFuture!,
    ]);

    PerformanceLogger.end('HomeDashboardTab.refresh');
  }

  void _startPlunge() {
    HapticFeedback.mediumImpact();
    // Navigate to timer tab (index 1) in the main navigation
    if (mounted) {
      final scaffold = context.findAncestorStateOfType<State>();
      if (scaffold != null && scaffold.mounted) {
        // Use callback to parent to switch tab instead of navigation
        Navigator.pushNamed(context, '/plunge-timer');
      }
    }
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'ColdPlunge Pro',
        showBackButton: false,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'logout',
              color: colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              // Handle logout
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        child: FutureBuilder<List<dynamic>>(
          // Combine all futures for efficient loading
          future: Future.wait([
            _recentSessionsFuture ?? Future.value([]),
            _weeklyDataFuture ?? Future.value([]),
            _userStatsFuture ?? Future.value({}),
            _hasPlungedTodayFuture ?? Future.value(false),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !DataCacheService.instance.has('user_stats')) {
              return _buildLoadingState();
            }

            final recentSessions =
                snapshot.data?[0] as List<Map<String, dynamic>>? ?? [];
            final weeklyData =
                snapshot.data?[1] as List<Map<String, dynamic>>? ?? [];
            final userStats = snapshot.data?[2] as Map<String, dynamic>? ?? {};
            final hasPlungedToday = snapshot.data?[3] as bool? ?? false;
            final currentStreak = userStats['streak_count'] as int? ?? 0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hero Section with Streak Counter
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        StreakCounterWidget(
                          streakCount: currentStreak,
                          hasPlungedToday: hasPlungedToday,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          hasPlungedToday
                              ? 'Great job! You\'ve completed today\'s plunge.'
                              : 'Ready for today\'s cold plunge challenge?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Start Plunge Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: _StartPlungeButton(onTap: _startPlunge),
                  ),

                  SizedBox(height: 3.h),

                  // Quick Stats Cards
                  Container(
                    width: double.infinity,
                    height: 20.h,
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: QuickStatsCardWidget(
                            title: 'Last 7 Days',
                            value: '${userStats['week_sessions'] ?? 0}',
                            subtitle: 'Sessions completed',
                            iconName: 'calendar_today',
                            accentColor: colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: QuickStatsCardWidget(
                            title: 'Avg Duration',
                            value: _formatDuration((userStats['avg_duration'] ??
                                    0.0) is String
                                ? double.parse(
                                        userStats['avg_duration'] ?? '0.0')
                                    .round()
                                : (userStats['avg_duration'] ?? 0.0).round()),
                            subtitle:
                                'Personal best: ${_formatDuration(userStats['personal_best_duration'] ?? 0)}',
                            iconName: 'timer',
                            accentColor: colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Weekly Progress Chart
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: WeeklyProgressChartWidget(
                        weeklyData: weeklyData,
                      ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Weather Widget (handles its own data + caching)
                  const Center(child: WeatherWidget()),

                  SizedBox(height: 3.h),

                  // Recent Sessions
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Sessions',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.sessionHistory,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View All',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 1.w),
                                CustomIconWidget(
                                  iconName: 'arrow_forward_ios',
                                  color: colorScheme.primary,
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Recent Sessions List
                  Center(
                    child: recentSessions.isEmpty
                        ? _buildEmptySessionsState()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            itemCount: recentSessions.length,
                            itemBuilder: (context, index) {
                              final session = recentSessions[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 2.h),
                                child: RecentSessionCardWidget(
                                  session: session,
                                  onView: () {
                                    // View session details
                                  },
                                  onDelete: null, // Disable delete from home
                                ),
                              );
                            },
                          ),
                  ),

                  SizedBox(height: 10.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero Section Skeleton
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            child: const SkeletonStreakCounter(),
          ),

          SizedBox(height: 2.h),

          // Start Button Skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: SkeletonLoader(
              width: double.infinity,
              height: 6.h,
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          SizedBox(height: 3.h),

          // Quick Stats Cards Skeleton
          Container(
            width: double.infinity,
            height: 20.h,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                const Expanded(child: SkeletonMetricCard()),
                SizedBox(width: 4.w),
                const Expanded(child: SkeletonMetricCard()),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Chart Skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: const SkeletonChart(),
          ),

          SizedBox(height: 3.h),

          // Weather Widget Skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: SkeletonLoader(
              width: double.infinity,
              height: 15.h,
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          SizedBox(height: 3.h),

          // Recent Sessions Header Skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonLoader(
                  width: 35.w,
                  height: 2.h,
                  borderRadius: BorderRadius.circular(4),
                ),
                SkeletonLoader(
                  width: 15.w,
                  height: 2.h,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Recent Sessions List Skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: List.generate(
                3,
                (index) => const SkeletonSessionCard(),
              ),
            ),
          ),

          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildEmptySessionsState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.w),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'ac_unit',
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            'No Sessions Yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Start your cold plunge journey today!',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Extracted widget to avoid rebuilds
class _StartPlungeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartPlungeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 8.5.h,
      decoration: BoxDecoration(
        color: const Color(0xFFD97706),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CustomIconWidget(
                  iconName: 'play_arrow',
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Start Plunge',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
