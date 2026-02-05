import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/challenge_timing_helper.dart';
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
      // Log full error for debugging
      print('Challenge progress loading error: $e');

      setState(() {
        _error = 'Unable to load challenge progress. Please try again later.';
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
    if (_userChallengeData == null) return 'Unknown';

    final joinedAtStr = _userChallengeData!['joined_at'] as String?;
    final durationDays = _challengeData?['duration_days'] as int?;

    if (joinedAtStr != null && durationDays != null) {
      try {
        final joinedAt = DateTime.parse(joinedAtStr).toLocal();
        return ChallengeTimingHelper.getTimeLeftString(
          joinedAt: joinedAt,
          durationDays: durationDays,
        );
      } catch (e) {
        return 'Unknown';
      }
    }

    return 'No deadline';
  }

  String _getChallengeStatus() {
    if (_userChallengeData == null) return 'Not Joined';

    final isCompleted = _userChallengeData!['is_completed'] as bool? ?? false;
    if (isCompleted) return 'Completed';

    final joinedAtStr = _userChallengeData!['joined_at'] as String?;
    final durationDays = _challengeData?['duration_days'] as int?;

    if (joinedAtStr != null && durationDays != null) {
      try {
        final joinedAt = DateTime.parse(joinedAtStr).toLocal();
        if (ChallengeTimingHelper.isChallengeExpired(
          joinedAt: joinedAt,
          durationDays: durationDays,
        )) {
          return 'Failed';
        }
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
              challengeTitle: _challengeData?['title'] as String? ?? '',
              durationDays: _challengeData?['duration_days'] as int? ?? 0,
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.all(24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: Text(
          'Leave Challenge',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Leaving will reset your progress for this challenge.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'warning',
                    size: 16,
                    color: const Color(0xFFF57C00),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You can rejoin later, but progress will start over.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5D4037),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  backgroundColor: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _leaveChallenge();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Leave Challenge',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
      // Log full error for debugging
      print('Rejoin challenge error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Unable to rejoin challenge. Please try again later.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
