import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../services/dashboard_repository.dart';
import '../../services/persistent_cache_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/quick_stats_card_widget.dart';
import './widgets/recent_session_card_widget.dart';
import './widgets/streak_counter_widget.dart';
import './widgets/weather_widget.dart';
import './widgets/weekly_progress_chart_widget.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isLoading = false;

  // Data from Supabase
  List<Map<String, dynamic>> _recentSessions = [];
  List<Map<String, dynamic>> _weeklyData = [];
  Map<String, dynamic> _userStats = {};
  int _currentStreak = 0;
  bool _hasPlungedToday = false;

  late final DashboardRepository _dashboardRepository;
  late final PersistentCacheService _persistentCacheService;

  @override
  void initState() {
    super.initState();
    _persistentCacheService = PersistentCacheService();
    _dashboardRepository =
        DashboardRepository(persistentCacheService: _persistentCacheService);
    _loadDashboardData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    if (!AuthService.instance.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dashboardData = await _dashboardRepository.getDashboardData(
        key: 'main',
        forceRefresh: forceRefresh,
        fetcher: () async {
          final results = await Future.wait([
            SessionService.instance.getRecentSessions(),
            SessionService.instance.getWeeklyProgress(),
            AuthService.instance.getUserStats(),
            AuthService.instance.hasSessionToday(),
          ]);
          return {
            'recentSessions': results[0],
            'weeklyData': results[1],
            'userStats': results[2],
            'hasPlungedToday': results[3],
          };
        },
      );

      if (mounted) {
        setState(() {
          _recentSessions = List<Map<String, dynamic>>.from(
              dashboardData['recentSessions'] ?? []);
          _weeklyData = List<Map<String, dynamic>>.from(
              dashboardData['weeklyData'] ?? []);
          _userStats =
              Map<String, dynamic>.from(dashboardData['userStats'] ?? {});
          _hasPlungedToday = dashboardData['hasPlungedToday'] ?? false;
          _currentStreak = _userStats['streak_count'] ?? 0;
        });
      }
    } catch (error) {
      print('Dashboard data load error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn\'t refresh. Showing cached data.'),
            backgroundColor: AppTheme.errorLight,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await _loadDashboardData(forceRefresh: true);
  }

  void _startPlunge() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/plunge-timer');
  }

  void _navigateToSettings() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRoutes.settings);
  }

  void _viewSessionDetails(Map<String, dynamic> session) {
    _showSessionDetails(session);
  }

  Future<void> _deleteSession(Map<String, dynamic> session) async {
    HapticFeedback.mediumImpact();
    _showDeleteConfirmation(session);
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Details',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 3.h),
                    _buildDetailRow(
                      'Location',
                      session['location'] as String,
                    ),
                    _buildDetailRow(
                      'Date',
                      _formatDetailDate(
                        DateTime.parse(session['created_at']).toLocal(),
                      ),
                    ),
                    _buildDetailRow(
                      'Duration',
                      _formatDuration(session['duration'] as int),
                    ),
                    _buildDetailRow(
                      'Temperature',
                      '${session['temperature']}°F',
                    ),
                    if (session['rating'] != null)
                      _buildDetailRow(
                        'Rating',
                        '${session['rating']}/5 stars',
                      ),
                    if (session['pre_mood'] != null)
                      _buildDetailRow(
                        'Pre-Mood',
                        session['pre_mood'] as String,
                      ),
                    if (session['post_mood'] != null)
                      _buildDetailRow(
                        'Post-Mood',
                        session['post_mood'] as String,
                      ),
                    if (session['notes'] != null &&
                        (session['notes'] as String).isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'Notes',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 1.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          session['notes'] as String,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDetailDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

  void _showDeleteConfirmation(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text(
          'Are you sure you want to delete this session from ${session['location']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await SessionService.instance.deleteSession(session['id']);
                await _loadDashboardData(); // Refresh data
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.successLight,
                  ),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete session: $error'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppTheme.errorLight,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorLight,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              iconName: 'account_circle',
              color: colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _navigateToSettings,
            tooltip: 'Account Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _isLoading
              ? _buildLoadingState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Hero Section with Streak Counter
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        children: [
                          StreakCounterWidget(
                            streakCount: _currentStreak,
                            hasPlungedToday: _hasPlungedToday,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _hasPlungedToday
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

                    // Start Plunge Button (moved from floating position)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Container(
                        width: double.infinity,
                        height: 8.5.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706), // Solid muted amber
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD97706)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _startPlunge,
                            borderRadius: BorderRadius.circular(16.0),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomIconWidget(
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
                      ),
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
                              value: '${_userStats['week_sessions'] ?? 0}',
                              subtitle: 'Sessions completed',
                              iconName: 'calendar_today',
                              accentColor: colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: QuickStatsCardWidget(
                              title: 'Avg Duration',
                              value: _formatDuration(
                                  (_userStats['avg_duration'] ?? 0.0) is String
                                      ? double.parse(
                                              _userStats['avg_duration'] ??
                                                  '0.0')
                                          .round()
                                      : (_userStats['avg_duration'] ?? 0.0)
                                          .round()),
                              subtitle:
                                  'Personal best: ${_formatDuration(_userStats['personal_best_duration'] ?? 0)}',
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
                          weeklyData: _weeklyData,
                        ),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Weather Widget (now handles its own data)
                    Center(child: const WeatherWidget()),

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
                      child: _recentSessions.isEmpty
                          ? _buildEmptySessionsState()
                          : Column(
                              children: _recentSessions.take(5).map((session) {
                                return RecentSessionCardWidget(
                                  session: session,
                                  onView: () => _viewSessionDetails(session),
                                  onDelete: () => _deleteSession(session),
                                );
                              }).toList(),
                            ),
                    ),

                    SizedBox(height: 3.h),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 60.h,
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
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
