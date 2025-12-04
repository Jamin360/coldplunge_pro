import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../services/session_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/community_highlights_widget.dart';
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
    with TickerProviderStateMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  bool _isLoading = false;

  // Data from Supabase
  List<Map<String, dynamic>> _recentSessions = [];
  List<Map<String, dynamic>> _weeklyData = [];
  List<Map<String, dynamic>> _communityHighlights = [];
  Map<String, dynamic> _userStats = {};
  int _currentStreak = 0;
  bool _hasPlungedToday = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _fabAnimationController.forward();

    _loadDashboardData();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!AuthService.instance.isAuthenticated) {
      // User not authenticated, redirect to login
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Load all dashboard data in parallel (weather is now handled by WeatherWidget)
      final results = await Future.wait([
        SessionService.instance.getRecentSessions(),
        SessionService.instance.getWeeklyProgress(),
        CommunityService.instance.getCommunityHighlights(),
        AuthService.instance.getUserStats(),
        AuthService.instance.hasSessionToday(),
      ]);

      setState(() {
        _recentSessions = results[0] as List<Map<String, dynamic>>;
        _weeklyData = results[1] as List<Map<String, dynamic>>;
        _communityHighlights = results[2] as List<Map<String, dynamic>>;
        _userStats = results[3] as Map<String, dynamic>;
        _hasPlungedToday = results[4] as bool;
        _currentStreak = _userStats['streak_count'] ?? 0;
      });
    } catch (error) {
      print('Dashboard data load error: $error');
      // Show error but don't break the UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await _loadDashboardData();
  }

  void _startPlunge() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/plunge-timer');
  }

  void _viewSessionDetails(Map<String, dynamic> session) {
    _showSessionDetails(session);
  }

  void _shareSession(Map<String, dynamic> session) {
    HapticFeedback.lightImpact();
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing session from ${session['location']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editSession(Map<String, dynamic> session) {
    HapticFeedback.lightImpact();
    // TODO: Navigate to edit session screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit session functionality coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                        DateTime.parse(session['created_at']),
                      ),
                    ),
                    _buildDetailRow(
                      'Duration',
                      '${session['duration']} minutes',
                    ),
                    _buildDetailRow(
                      'Temperature',
                      '${session['temperature']}°C',
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

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorLight,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        await AuthService.instance.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.loginScreen,
            (route) => false,
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $error'),
              backgroundColor: AppTheme.errorLight,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'ColdPlunge Pro',
        showBackButton: false,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 2.w),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.successLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.successLight.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'local_fire_department',
                  color: AppTheme.successLight,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  '$_currentStreak',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.successLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'logout',
              color: colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _handleLogout,
            tooltip: 'Logout',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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

                    // Quick Stats Cards
                    Container(
                      height: 20.h,
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: QuickStatsCardWidget(
                              title: 'This Week',
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
                              value: '${_userStats['avg_duration'] ?? '0.0'}m',
                              subtitle:
                                  'Personal best: ${_userStats['personal_best_duration'] ?? 0}m',
                              iconName: 'timer',
                              accentColor: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Weekly Progress Chart
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: WeeklyProgressChartWidget(
                        weeklyData: _weeklyData,
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Weather Widget (now handles its own data)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: const WeatherWidget(),
                    ),

                    SizedBox(height: 3.h),

                    // Community Highlights
                    if (_communityHighlights.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: CommunityHighlightsWidget(
                          highlights: _communityHighlights,
                        ),
                      ),
                      SizedBox(height: 3.h),
                    ],

                    // Recent Sessions
                    Padding(
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
                              '/personal-analytics',
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

                    SizedBox(height: 2.h),

                    // Recent Sessions List
                    _recentSessions.isEmpty
                        ? _buildEmptySessionsState()
                        : Column(
                            children: _recentSessions.map((session) {
                              return RecentSessionCardWidget(
                                session: session,
                                onView: () => _viewSessionDetails(session),
                                onShare: () => _shareSession(session),
                                onEdit: () => _editSession(session),
                                onDelete: () => _deleteSession(session),
                              );
                            }).toList(),
                          ),

                    SizedBox(height: 10.h), // Bottom padding for FAB
                  ],
                ),
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: _startPlunge,
              backgroundColor: AppTheme.accentLight,
              foregroundColor: Colors.white,
              elevation: 6,
              icon: CustomIconWidget(
                iconName: 'play_arrow',
                color: Colors.white,
                size: 24,
              ),
              label: Text(
                'Start Plunge',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
