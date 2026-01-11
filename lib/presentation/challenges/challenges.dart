import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/challenge_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/active_challenge_widget.dart';
import './widgets/challenge_card_widget.dart';
import './widgets/challenge_filter_widget.dart';
import './widgets/leaderboard_widget.dart';

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
  Map<String, dynamic>? _activeChallenge;
  List<Map<String, dynamic>> _leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all challenges and user challenges in parallel
      final results = await Future.wait([
        _challengeService.getActiveChallenges(),
        _challengeService.getUserActiveChallenges(),
        _challengeService.getGlobalLeaderboard(),
      ]);

      final allChallenges = results[0];
      final userChallenges = results[1];
      final leaderboard = results[2];

      setState(() {
        _allChallenges = allChallenges;
        _userChallenges = userChallenges;
        _leaderboardData = leaderboard;

        // Find active challenge (first user challenge with highest progress)
        if (userChallenges.isNotEmpty) {
          final activeUserChallenge = userChallenges.first;
          final challengeData =
              activeUserChallenge['challenges'] as Map<String, dynamic>;

          final progress =
              (activeUserChallenge['progress'] as num?)?.toDouble() ?? 0.0;
          final targetValue = challengeData['target_value'] as int? ?? 1;
          final currentValue = (progress * targetValue / 100).round();
          final daysLeft = _calculateDaysLeft(challengeData['end_date']);

          _activeChallenge = {
            'id': challengeData['id'],
            'title': challengeData['title'],
            'progress': progress,
            'currentStreak': currentValue,
            'targetStreak': targetValue,
            'timeLeft': daysLeft,
            'description': challengeData['description'],
            'image': challengeData['image_url'],
          };
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load challenges: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _calculateDaysLeft(String? endDateStr) {
    if (endDateStr == null) return 'No deadline';

    try {
      final endDate = DateTime.parse(endDateStr);
      final now = DateTime.now();
      final difference = endDate.difference(now).inDays;

      if (difference < 0) return 'Expired';
      if (difference == 0) return 'Today';
      if (difference == 1) return '1 day';
      return '$difference days';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredChallenges {
    final userChallengeIds = _userChallenges
        .map((uc) => (uc['challenges'] as Map<String, dynamic>)['id'])
        .toSet();

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
            'timeLeft': _calculateDaysLeft(challenge['end_date']),
          };
        }).toList();

      case 'upcoming':
        return _allChallenges
            .where((c) => !userChallengeIds.contains(c['id']))
            .map((c) => {
                  ...c,
                  'isJoined': false,
                  'isActive': false,
                  'progress': 0.0,
                  'participants': c['participants_count'] ?? 0,
                  'timeLeft': _calculateDaysLeft(c['end_date']),
                })
            .toList();

      case 'completed':
        return _userChallenges
            .where((uc) => uc['is_completed'] as bool? ?? false)
            .map((uc) {
          final challenge = uc['challenges'] as Map<String, dynamic>;
          return {
            ...challenge,
            'progress': 100.0,
            'isJoined': true,
            'isActive': false,
            'participants': challenge['participants_count'] ?? 0,
            'timeLeft': 'Completed',
          };
        }).toList();

      default: // 'all'
        final joined = _userChallenges.map((uc) {
          final challenge = uc['challenges'] as Map<String, dynamic>;
          return {
            ...challenge,
            'progress': (uc['progress'] as num?)?.toDouble() ?? 0.0,
            'isJoined': true,
            'isActive': !(uc['is_completed'] as bool? ?? false),
            'participants': challenge['participants_count'] ?? 0,
            'timeLeft': _calculateDaysLeft(challenge['end_date']),
          };
        }).toList();

        final notJoined = _allChallenges
            .where((c) => !userChallengeIds.contains(c['id']))
            .map((c) => {
                  ...c,
                  'isJoined': false,
                  'isActive': false,
                  'progress': 0.0,
                  'participants': c['participants_count'] ?? 0,
                  'timeLeft': _calculateDaysLeft(c['end_date']),
                })
            .toList();

        return [...joined, ...notJoined];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Challenges',
        showBackButton: false,
        actions: [
          IconButton(
            onPressed: _showCreateChallengeDialog,
            icon: CustomIconWidget(
              iconName: 'add_circle_outline',
              size: 24,
              color: colorScheme.primary,
            ),
          ),
          IconButton(
            onPressed: _showSearchDialog,
            icon: CustomIconWidget(
              iconName: 'search',
              size: 24,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Tab Bar
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Challenges'),
                          Tab(text: 'Leaderboard'),
                        ],
                        labelStyle: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle:
                            theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                        indicator: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        padding: EdgeInsets.all(1.w),
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
              _error ?? 'Unknown error occurred',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
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
                            : _selectedFilter == 'upcoming'
                                ? 'Upcoming Challenges'
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

            // Challenges List
            _filteredChallenges.isEmpty
                ? _buildEmptyState()
                : SizedBox(
                    height: 55.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 4.w),
                      itemCount: _filteredChallenges.length,
                      itemBuilder: (context, index) {
                        final challenge = _filteredChallenges[index];
                        return ChallengeCardWidget(
                          challenge: challenge,
                          onTap: () => _showChallengeDetails(challenge),
                        );
                      },
                    ),
                  ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 2.h),
            LeaderboardWidget(
              leaderboardData: _leaderboardData,
              currentUserPosition: _leaderboardData.indexWhere(
                    (entry) => entry['isCurrentUser'] == true,
                  ) +
                  1,
            ),
            SizedBox(height: 4.h),
          ],
        ),
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

  void _showChallengeDetails([Map<String, dynamic>? challenge]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChallengeDetailsModal(challenge),
    );
  }

  Widget _buildChallengeDetailsModal(Map<String, dynamic>? challenge) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedChallenge = challenge ?? _activeChallenge!;

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

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedChallenge['title'] as String,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
                  // Challenge image if available
                  if (selectedChallenge['image'] != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomImageWidget(
                        imageUrl: selectedChallenge['image'] as String,
                        width: double.infinity,
                        height: 25.h,
                        fit: BoxFit.cover,
                        semanticLabel:
                            selectedChallenge['semanticLabel'] as String? ??
                                'Challenge image',
                      ),
                    ),
                    SizedBox(height: 3.h),
                  ],

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

                  SizedBox(height: 3.h),

                  // Rewards
                  Text(
                    'Rewards',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  _buildRewardItem('Arctic Warrior Badge', 'emoji_events'),
                  _buildRewardItem('500 XP Points', 'stars'),
                  _buildRewardItem('Exclusive Community Access', 'group'),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),

          // Action Button
          Container(
            padding: EdgeInsets.all(4.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showJoinConfirmation(selectedChallenge);
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

  Widget _buildRewardItem(String reward, String iconName) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            size: 16,
            color: AppTheme.accentLight,
          ),
          SizedBox(width: 2.w),
          Text(
            reward,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinConfirmation(Map<String, dynamic> challenge) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Join Challenge?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'re about to join "${challenge['title']}"',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Text(
              'By joining, you commit to:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              '• Complete daily sessions as required\n• Follow all challenge rules\n• Maintain respectful community interaction',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
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
              _joinChallenge(challenge);
            },
            child: const Text('Join Challenge'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join challenge: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCreateChallengeDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create Custom Challenge',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Create your own challenge and invite friends to join you in your cold plunge journey.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to create challenge screen
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Challenges',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Search by name, difficulty, or type...',
            prefixIcon: CustomIconWidget(
              iconName: 'search',
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
