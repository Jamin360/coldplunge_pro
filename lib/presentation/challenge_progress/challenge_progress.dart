import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/challenge_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/progress_history_widget.dart';
import './widgets/progress_ring_widget.dart';
import './widgets/share_image_widget.dart';
import './widgets/stats_section_widget.dart';

class ChallengeProgress extends StatefulWidget {
  const ChallengeProgress({super.key});

  @override
  State<ChallengeProgress> createState() => _ChallengeProgressState();
}

class _ChallengeProgressState extends State<ChallengeProgress> {
  final _challengeService = ChallengeService.instance;
  final _screenshotController = ScreenshotController();

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _challengeData;
  Map<String, dynamic>? _userChallengeData;
  List<Map<String, dynamic>> _sessionHistory = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChallengeData();
    });
  }

  Future<void> _loadChallengeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

      if (args == null || args['challengeId'] == null) {
        throw Exception('Challenge ID not provided');
      }

      final challengeId = args['challengeId'] as String;

      // Fetch challenge details and user challenge data in parallel
      final results = await Future.wait([
        _challengeService.getChallengeById(challengeId),
        _getUserChallengeData(challengeId),
        _getSessionHistory(challengeId),
      ]);

      setState(() {
        _challengeData = results[0] as Map<String, dynamic>;
        _userChallengeData = results[1] as Map<String, dynamic>?;
        _sessionHistory = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load challenge data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _getUserChallengeData(
      String challengeId) async {
    try {
      final activeChallenges =
          await _challengeService.getUserActiveChallenges();
      final userChallenge = activeChallenges.firstWhere(
        (uc) => (uc['challenges'] as Map<String, dynamic>)['id'] == challengeId,
        orElse: () => <String, dynamic>{},
      );

      if (userChallenge.isEmpty) {
        final completedChallenges =
            await _challengeService.getUserCompletedChallenges();
        final completed = completedChallenges.firstWhere(
          (uc) =>
              (uc['challenges'] as Map<String, dynamic>)['id'] == challengeId,
          orElse: () => <String, dynamic>{},
        );
        return completed.isNotEmpty ? completed : null;
      }

      return userChallenge;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getSessionHistory(
      String challengeId) async {
    try {
      if (_userChallengeData == null) return [];

      final joinedAt = _userChallengeData!['joined_at'] as String;

      return await _challengeService.getChallengeSessionHistory(
        challengeId,
        joinedAt,
      );
    } catch (e) {
      return [];
    }
  }

  String _calculateDaysRemaining() {
    if (_challengeData == null) return 'Unknown';

    final endDate = _challengeData!['end_date'] as String?;
    if (endDate == null) return 'No deadline';

    try {
      final end = DateTime.parse(endDate);
      final now = DateTime.now();
      final difference = end.difference(now).inDays;

      if (difference < 0) return 'Expired';
      if (difference == 0) return 'Last day';
      if (difference == 1) return '1 day left';
      return '$difference days left';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getChallengeStatus() {
    if (_userChallengeData == null) return 'Not Joined';

    final isCompleted = _userChallengeData!['is_completed'] as bool? ?? false;
    if (isCompleted) return 'Completed';

    final endDate = _challengeData?['end_date'] as String?;
    if (endDate != null) {
      try {
        final end = DateTime.parse(endDate);
        if (DateTime.now().isAfter(end)) return 'Failed';
      } catch (e) {
        // Invalid date format
      }
    }

    return 'Active';
  }

  IconData _getChallengeIcon() {
    final challengeType = _challengeData?['challenge_type'] as String? ?? '';

    switch (challengeType.toLowerCase()) {
      case 'consistency':
      case 'streak':
        return Icons.local_fire_department;
      case 'cold_tolerance':
      case 'temperature':
        return Icons.ac_unit;
      case 'duration':
      case 'time':
        return Icons.timer;
      case 'frequency':
        return Icons.calendar_today;
      case 'milestone':
        return Icons.emoji_events;
      default:
        return Icons.stars;
    }
  }

  Color _getIconColor() {
    final difficulty = _challengeData?['difficulty'] as String? ?? 'medium';

    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.successLight;
      case 'medium':
        return AppTheme.warningLight;
      case 'hard':
        return AppTheme.errorLight;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Challenge Progress',
        showBackButton: true,
        actions: [
          PopupMenuButton<String>(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              size: 24,
              color: colorScheme.onSurface,
            ),
            onSelected: (value) {
              if (value == 'leave') {
                _showLeaveConfirmation();
              } else if (value == 'share') {
                _shareProgress();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share Progress'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Leave Challenge',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            size: 64,
            color: colorScheme.error,
          ),
          SizedBox(height: 2.h),
          Text(
            'Failed to load challenge',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              _error ?? 'Unknown error occurred',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _loadChallengeData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = _getChallengeStatus();

    return RefreshIndicator(
      onRefresh: _loadChallengeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 2.h),

            // Challenge Icon Badge
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: _getIconColor().withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getIconColor().withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _getChallengeIcon(),
                size: 10.w,
                color: _getIconColor(),
              ),
            ),
            SizedBox(height: 2.h),

            // Difficulty Badge
            _buildDifficultyBadge(
                _challengeData?['difficulty'] as String? ?? 'medium'),

            SizedBox(height: 3.h),

            // Progress Ring Section
            ProgressRingWidget(
              progress:
                  (_userChallengeData?['progress'] as num?)?.toDouble() ?? 0.0,
              status: status,
              challengeTitle: _challengeData?['title'] as String? ?? '',
            ),

            SizedBox(height: 4.h),

            // Stats Section
            StatsSectionWidget(
              currentProgress:
                  (_userChallengeData?['progress'] as num?)?.toDouble() ?? 0.0,
              targetValue: _challengeData?['target_value'] as int? ?? 0,
              challengeType:
                  _challengeData?['challenge_type'] as String? ?? 'consistency',
              daysRemaining: _calculateDaysRemaining(),
              dateJoined: _userChallengeData?['joined_at'] as String?,
            ),

            SizedBox(height: 4.h),

            // Description Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Challenge Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    _challengeData?['description'] as String? ??
                        'No description available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 4.h),

            // Progress History Section
            if (_sessionHistory.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    Text(
                      'Progress History',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_sessionHistory.length} sessions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              ProgressHistoryWidget(
                sessions: _sessionHistory,
                challengeType: _challengeData?['challenge_type'] as String? ??
                    'consistency',
              ),
              SizedBox(height: 4.h),
            ],

            // Status-specific Action Section
            _buildStatusActionSection(status),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    final theme = Theme.of(context);

    Color badgeColor;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        badgeColor = AppTheme.successLight;
        break;
      case 'medium':
        badgeColor = AppTheme.warningLight;
        break;
      case 'hard':
        badgeColor = AppTheme.errorLight;
        break;
      default:
        badgeColor = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusActionSection(String status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (status) {
      case 'Completed':
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.successLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.successLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'emoji_events',
                      size: 48,
                      color: AppTheme.successLight,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challenge Completed!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.successLight,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'Congratulations on completing this challenge',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _shareProgress,
                  icon: const Icon(Icons.share),
                  label: const Text('Share Achievement'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'Failed':
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info',
                      size: 32,
                      color: colorScheme.error,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Challenge Ended',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.error,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'Time expired - View your progress',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _rejoinChallenge(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'Active':
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.1),
                  colorScheme.secondary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Keep Going!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'You\'re making great progress. Stay consistent to complete this challenge.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _showLeaveConfirmation() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Leave Challenge?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to leave this challenge?',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'warning',
                    size: 20,
                    color: colorScheme.error,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Your progress will be lost and cannot be recovered.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _leaveChallenge();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Leave Challenge'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveChallenge() async {
    try {
      final challengeId = _challengeData!['id'] as String;
      await _challengeService.leaveChallenge(challengeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully left challenge'),
            backgroundColor: AppTheme.successLight,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave challenge: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _shareProgress() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generating shareable image...'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final progress =
          (_userChallengeData?['progress'] as num?)?.toDouble() ?? 0.0;
      final title = _challengeData?['title'] as String? ?? 'Challenge';
      final targetValue = _challengeData?['target_value'] as int? ?? 0;
      final difficulty = _challengeData?['difficulty'] as String? ?? 'medium';
      final challengeType =
          _challengeData?['challenge_type'] as String? ?? 'consistency';

      // Format current and target values based on challenge type
      String currentValue;
      String targetValueStr;

      if (challengeType.toLowerCase().contains('duration') ||
          challengeType.toLowerCase().contains('time')) {
        final currentSeconds = (progress * targetValue / 100).toInt();
        currentValue = currentSeconds >= 60
            ? '${currentSeconds ~/ 60}m ${currentSeconds % 60}s'
            : '${currentSeconds}s';
        targetValueStr = targetValue >= 60
            ? '${targetValue ~/ 60}m ${targetValue % 60}s'
            : '${targetValue}s';
      } else if (challengeType.toLowerCase().contains('temperature') ||
          challengeType.toLowerCase().contains('cold')) {
        final currentTemp = (progress * targetValue / 100).toInt();
        currentValue = '${currentTemp}°F';
        targetValueStr = '${targetValue}°F';
      } else {
        final currentCount = (progress * targetValue / 100).toInt();
        currentValue = currentCount.toString();
        targetValueStr = targetValue.toString();
      }

      // Create the share image widget
      final shareWidget = ShareImageWidget(
        challengeTitle: title,
        progress: progress,
        currentValue: currentValue,
        targetValue: targetValueStr,
        daysRemaining: _calculateDaysRemaining(),
        difficulty: difficulty,
        challengeType: challengeType,
      );

      // Capture the widget as an image
      final imageBytes = await _screenshotController.captureFromWidget(
        shareWidget,
        context: context,
      );

      // Save the image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/challenge_progress_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Join me on my cold plunge journey! I\'m taking the "$title" challenge. #ColdPlungePro #ColdPlunge',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _rejoinChallenge() async {
    try {
      final challengeId = _challengeData!['id'] as String;
      await _challengeService.joinChallenge(challengeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully rejoined challenge!'),
            backgroundColor: AppTheme.successLight,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _loadChallengeData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rejoin: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
