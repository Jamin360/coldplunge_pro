import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/challenge_timing_helper.dart';
import '../../services/challenge_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/active_challenge_widget.dart';
import './widgets/challenge_card_widget.dart';
import './widgets/challenge_filter_widget.dart';

class Challenges extends StatefulWidget {
  const Challenges({super.key});

  @override
  State<Challenges> createState() => _ChallengesState();
}

class _ChallengesState extends State<Challenges> with TickerProviderStateMixin {
  int _currentBottomIndex = 2;
  String _selectedFilter = 'all';
  late TabController _tabController;

  final _challengeService = ChallengeService.instance;

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _allChallenges = [];
  List<Map<String, dynamic>> _userChallenges = [];
  List<Map<String, dynamic>> _completedChallenges = [];
  Map<String, dynamic>? _activeChallenge;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Trigger rebuild when tab changes
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all challenges, user challenges, and completed challenges in parallel
      final results = await Future.wait([
        _challengeService.getActiveChallenges(),
        _challengeService.getUserActiveChallenges(),
        _challengeService.getUserCompletedChallenges(),
      ]);

      final allChallenges = results[0];
      final userChallenges = results[1];
      final completedChallenges = results[2];

      setState(() {
        _allChallenges = allChallenges;
        _userChallenges = userChallenges;
        _completedChallenges = completedChallenges;

        // Find active challenge (first user challenge with highest progress)
        if (userChallenges.isNotEmpty) {
          final activeUserChallenge = userChallenges.first;
          final challengeData =
              activeUserChallenge['challenges'] as Map<String, dynamic>;

          final progress =
              (activeUserChallenge['progress'] as num?)?.toDouble() ?? 0.0;
          final targetValue = challengeData['target_value'] as int? ?? 1;
          final currentValue = (progress * targetValue / 100).round();
          final daysLeft = _calculateUserChallengeTimeLeft(activeUserChallenge);

          _activeChallenge = {
            'id': challengeData['id'],
            'title': challengeData['title'],
            'progress': progress,
            'currentStreak': currentValue,
            'targetStreak': targetValue,
            'timeLeft': daysLeft,
            'description': challengeData['description'],
            'image': challengeData['image_url'],
            'isJoined': true, // Mark as joined since it's from userChallenges
          };
        }

        _isLoading = false;
      });
    } catch (e) {
      // Log full error for debugging
      print('Challenge loading error: $e');

      setState(() {
        _error = 'Unable to load challenges. Please try again later.';
        _isLoading = false;
      });
    }
  }

  /// Calculate time left for a user's joined challenge using joined_at + duration
  String _calculateUserChallengeTimeLeft(Map<String, dynamic> userChallenge) {
    final joinedAtStr = userChallenge['joined_at'] as String?;
    final challenge = userChallenge['challenges'] as Map<String, dynamic>?;
    final durationDays = challenge?['duration_days'] as int?;

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

  /// Calculate time left for unjoined challenges (show full duration)
  String _calculateUnjoinedChallengeTimeLeft(Map<String, dynamic> challenge) {
    final durationDays = challenge['duration_days'] as int?;

    if (durationDays == null) return 'No duration';

    return ChallengeTimingHelper.getDurationString(durationDays);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredChallenges {
    switch (_selectedFilter) {
      case 'active':
        return _userChallenges
            .where((uc) => !(uc['is_completed'] as bool? ?? false))
            .map((uc) {
          final challenge = uc['challenges'] as Map<String, dynamic>;
          return {
            ...challenge,
            'progress': (uc['progress'] as num?)?.toDouble() ?? 0.0,
            'isJoined': true,
            'isActive': true,
            'participants': challenge['participants_count'] ?? 0,
            'timeLeft': _calculateUserChallengeTimeLeft(uc),
            'image': challenge['image_url'] ?? '',
            'semanticLabel': _generateSemanticLabel(challenge),
          };
        }).toList();

      case 'completed':
        return _completedChallenges.map((uc) {
          final challenge = uc['challenges'] as Map<String, dynamic>;
          final completedAt = uc['completed_at'] as String?;
          String completedDate = 'Completed';
          if (completedAt != null) {
            try {
              final date = DateTime.parse(completedAt).toLocal();
              final now = DateTime.now();
              final diff = now.difference(date).inDays;
              if (diff == 0) {
                completedDate = 'Completed today';
              } else if (diff == 1) {
                completedDate = 'Completed yesterday';
              } else if (diff < 7) {
                completedDate = 'Completed $diff days ago';
              } else {
                completedDate =
                    'Completed on ${date.month}/${date.day}/${date.year}';
              }
            } catch (e) {
              completedDate = 'Completed';
            }
          }
          return {
            ...challenge,
            'progress': 100.0,
            'isJoined': true,
            'isCompleted': true,
            'isActive': false,
            'participants': challenge['participants_count'] ?? 0,
            'timeLeft': completedDate,
            'image': challenge['image_url'] ?? '',
            'semanticLabel': _generateSemanticLabel(challenge),
          };
        }).toList();

      default: // 'all'
        final userChallengeIds = <String>{};

        final activeJoined = _userChallenges.map((uc) {
          final challenge = uc['challenges'] as Map<String, dynamic>;
          userChallengeIds.add(challenge['id']);
          return {
            ...challenge,
            'progress': (uc['progress'] as num?)?.toDouble() ?? 0.0,
            'isJoined': true,
            'isCompleted': false,
            'isActive': true,
            'participants': challenge['participants_count'] ?? 0,
            'timeLeft': _calculateUserChallengeTimeLeft(uc),
            'image': challenge['image_url'] ?? '',
            'semanticLabel': _generateSemanticLabel(challenge),
          };
        }).toList();

        final completedJoined = _completedChallenges.map((uc) {
          final challenge = uc['challenges'] as Map<String, dynamic>;
          userChallengeIds.add(challenge['id']);
          final completedAt = uc['completed_at'] as String?;
          String completedDate = 'Completed';
          if (completedAt != null) {
            try {
              final date = DateTime.parse(completedAt).toLocal();
              completedDate =
                  'Completed ${date.month}/${date.day}/${date.year}';
            } catch (e) {
              completedDate = 'Completed';
            }
          }
          return {
            ...challenge,
            'progress': 100.0,
            'isJoined': true,
            'isCompleted': true,
            'isActive': false,
            'participants': challenge['participants_count'] ?? 0,
            'timeLeft': completedDate,
            'image': challenge['image_url'] ?? '',
            'semanticLabel': _generateSemanticLabel(challenge),
          };
        }).toList();

        final notJoined = _allChallenges
            .where((c) => !userChallengeIds.contains(c['id']))
            .map(
              (c) => {
                ...c,
                'isJoined': false,
                'isCompleted': false,
                'isActive': false,
                'progress': 0.0,
                'participants': c['participants_count'] ?? 0,
                'timeLeft': _calculateUnjoinedChallengeTimeLeft(c),
                'image': c['image_url'] ?? '',
                'semanticLabel': _generateSemanticLabel(c),
              },
            )
            .toList();

        return [...activeJoined, ...completedJoined, ...notJoined];
    }
  }

  String _generateSemanticLabel(Map<String, dynamic> challenge) {
    final title = challenge['title'] as String? ?? 'Challenge';
    final difficulty = challenge['difficulty'] as String? ?? 'normal';
    return '$title challenge - $difficulty difficulty level';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar(
        title: 'Challenges',
        showBackButton: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    SizedBox(height: 2.h), // Add margin from header

                    // Tab Toggle - Simplified design
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      padding: EdgeInsets.all(0.5.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              context,
                              'Challenges',
                              _tabController.index == 0,
                              () {
                                _tabController.animateTo(0);
                                setState(() {}); // Force UI update
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildTabButton(
                              context,
                              'Leaderboard',
                              _tabController.index == 1,
                              () {
                                _tabController.animateTo(1);
                                setState(() {}); // Force UI update
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 2.h),

                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildChallengesTab(),
                          _buildLeaderboardTab()
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomIndex,
        onTap: (index) => setState(() => _currentBottomIndex = index),
      ),
    );
  }

  Widget _buildTabButton(
      BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
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
            'Failed to load challenges',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              'Please check your connection and try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Challenge Hero Section
            ActiveChallengeWidget(
              activeChallenge: _activeChallenge,
              onTap: _activeChallenge != null
                  ? () => _showChallengeDetails(_activeChallenge)
                  : null,
            ),

            SizedBox(height: 3.h),

            // Filter Section
            ChallengeFilterWidget(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) =>
                  setState(() => _selectedFilter = filter),
            ),

            SizedBox(height: 2.h),

            // Available Challenges Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Text(
                    _selectedFilter == 'all'
                        ? 'All Challenges'
                        : _selectedFilter == 'active'
                            ? 'Active Challenges'
                            : 'Completed Challenges',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${_filteredChallenges.length} challenges',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),

            // Challenges List - Changed to vertical scrolling
            _filteredChallenges.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    itemCount: _filteredChallenges.length,
                    itemBuilder: (context, index) {
                      final challenge = _filteredChallenges[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 2.h),
                        child: ChallengeCardWidget(
                          challenge: challenge,
                          onTap: () => _showChallengeDetails(challenge),
                        ),
                      );
                    },
                  ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Grayed out trophy icon
          CustomIconWidget(
            iconName: 'emoji_events',
            size: 80,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          SizedBox(height: 3.h),

          // Heading
          Text(
            'Leaderboard Coming Soon',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.5.h),

          // Subtext
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              'Compete with other cold plungers and see how you rank!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 40.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 2.h),
            Text(
              'No challenges found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your filter or create a new challenge',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Map difficulty to icon and color
  Map<String, dynamic> _getDifficultyConfig(String difficulty) {
    // Consistent dark gray/slate background for all icons
    const Color iconBackgroundColor = Color(0xFF1E3A5A);
    // Consistent dark navy badge color for all difficulty levels
    const Color badgeColor = Color(0xFF1E3A5A);

    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'beginner':
        return {
          'icon': 'ac_unit',
          'iconColor': Colors.white,
          'backgroundColor': iconBackgroundColor,
          'badgeColor': badgeColor,
          'label': 'BEGINNER'
        };
      case 'medium':
      case 'intermediate':
        return {
          'icon': 'local_fire_department',
          'iconColor': Colors.white,
          'backgroundColor': iconBackgroundColor,
          'badgeColor': badgeColor,
          'label': 'INTERMEDIATE'
        };
      case 'hard':
      case 'advanced':
        return {
          'icon': 'emoji_events',
          'iconColor': Colors.white,
          'backgroundColor': iconBackgroundColor,
          'badgeColor': badgeColor,
          'label': 'ADVANCED'
        };
      default:
        return {
          'icon': 'whatshot',
          'iconColor': Colors.white,
          'backgroundColor': iconBackgroundColor,
          'badgeColor': badgeColor,
          'label': 'BEGINNER'
        };
    }
  }

  void _showChallengeDetails([Map<String, dynamic>? challenge]) {
    final selectedChallenge = challenge ?? _activeChallenge;

    // Check if user has joined this challenge
    final isJoined = selectedChallenge?['isJoined'] as bool? ?? false;

    if (isJoined) {
      // Navigate to Challenge Progress page
      Navigator.pushNamed(
        context,
        AppRoutes.challengeProgress,
        arguments: {'challengeId': selectedChallenge!['id'] as String},
      ).then((_) => _loadData()); // Reload data when returning
    } else {
      // Show challenge details modal for joining
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildChallengeDetailsModal(selectedChallenge),
      );
    }
  }

  Widget _buildChallengeDetailsModal(Map<String, dynamic>? challenge) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedChallenge = challenge ?? _activeChallenge!;
    final difficulty = selectedChallenge['difficulty'] as String? ?? 'beginner';
    final difficultyConfig = _getDifficultyConfig(difficulty);

    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with close button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    size: 24,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge and difficulty badge row
                  Row(
                    children: [
                      // Colored circular icon badge
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: difficultyConfig['backgroundColor'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: difficultyConfig['icon'] as String,
                            size: 28,
                            color: difficultyConfig['iconColor'] as Color,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Difficulty badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 0.8.h),
                        decoration: BoxDecoration(
                          color: (difficultyConfig['badgeColor'] as Color)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (difficultyConfig['badgeColor'] as Color)
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          difficultyConfig['label'] as String,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: difficultyConfig['badgeColor'] as Color,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.sp,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  // Challenge Title
                  Text(
                    selectedChallenge['title'] as String,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Description
                  Text(
                    'Challenge Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    selectedChallenge['description'] as String? ??
                        'Complete this challenge to improve your cold exposure tolerance and build mental resilience.',
                    style: theme.textTheme.bodyMedium,
                  ),

                  SizedBox(height: 3.h),

                  // Rules
                  Text(
                    'Rules & Requirements',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildRuleItem('Complete daily cold plunge sessions'),
                  _buildRuleItem('Minimum 2 minutes per session'),
                  _buildRuleItem('Water temperature below 60°F (15°C)'),
                  _buildRuleItem('Log sessions within 24 hours'),

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),

          // Action Button
          Container(
            padding: EdgeInsets.only(
              left: 4.w,
              right: 4.w,
              top: 2.h,
              bottom: 4.h + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _joinChallenge(selectedChallenge);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: Text(
                  selectedChallenge['isJoined'] as bool? ?? false
                      ? 'View Progress'
                      : 'Join Challenge',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String rule) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: 'check_circle',
            size: 16,
            color: AppTheme.successLight,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              rule,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinChallenge(Map<String, dynamic> challenge) async {
    try {
      await _challengeService.joinChallenge(challenge['id'] as String);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined "${challenge['title']}"!'),
            backgroundColor: AppTheme.successLight,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Reload data to show updated challenges
        await _loadData();
      }
    } catch (e) {
      // Log full error for debugging
      print('Join challenge error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Unable to join challenge. Please try again later.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
