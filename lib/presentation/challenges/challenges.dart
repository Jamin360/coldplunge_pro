import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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
  int _currentBottomIndex = 3;
  String _selectedFilter = 'all';
  late TabController _tabController;

  // Mock data for active challenge
  final Map<String, dynamic>? _activeChallenge = {
    'title': '7-Day Cold Plunge Streak',
    'progress': 71.0,
    'currentStreak': 5,
    'targetStreak': 7,
    'timeLeft': '2 days',
    'leaderboardPosition': 3,
  };

  // Mock data for available challenges
  final List<Map<String, dynamic>> _allChallenges = [
    {
      'id': '1',
      'title': 'Arctic Warrior Challenge',
      'description':
          'Complete 30 cold plunges in 30 days with temperatures below 50°F',
      'difficulty': 'Hard',
      'participants': 1247,
      'timeLeft': '12 days',
      'progress': 0.0,
      'isActive': false,
      'isJoined': false,
      'image':
          'https://images.unsplash.com/photo-1677774362179-22ee6d120308',
      'semanticLabel':
          'Person in winter clothing standing in snowy mountain landscape with frozen lake',
    },
    {
      'id': '2',
      'title': 'Ice Bath Beginner',
      'description':
          'Start your cold therapy journey with 7 consecutive days of ice baths',
      'difficulty': 'Easy',
      'participants': 3421,
      'timeLeft': '5 days',
      'progress': 85.0,
      'isActive': true,
      'isJoined': true,
      'image':
          'https://images.unsplash.com/photo-1635214831754-b0e2b1292a82',
      'semanticLabel':
          'Modern bathroom with white bathtub filled with ice and water for cold therapy',
    },
    {
      'id': '3',
      'title': 'Temperature Drop Master',
      'description':
          'Gradually decrease water temperature by 5°F each week for 4 weeks',
      'difficulty': 'Medium',
      'participants': 892,
      'timeLeft': '18 days',
      'progress': 45.0,
      'isActive': false,
      'isJoined': true,
      'image':
          'https://images.unsplash.com/photo-1615486511473-4e83867c9516',
      'semanticLabel':
          'Digital thermometer showing cold temperature reading in ice water bath',
    },
    {
      'id': '4',
      'title': 'Winter Solstice Special',
      'description':
          'Join thousands in a global cold plunge event this winter solstice',
      'difficulty': 'Medium',
      'participants': 5678,
      'timeLeft': '45 days',
      'progress': 0.0,
      'isActive': false,
      'isJoined': false,
      'image':
          'https://images.unsplash.com/photo-1619707284867-922f30e176e5',
      'semanticLabel':
          'Group of people in winter gear preparing for outdoor cold water swimming event',
    },
    {
      'id': '5',
      'title': 'Mindful Cold Exposure',
      'description':
          'Combine meditation with cold therapy for enhanced mental resilience',
      'difficulty': 'Easy',
      'participants': 2156,
      'timeLeft': 'Completed',
      'progress': 100.0,
      'isActive': false,
      'isJoined': true,
      'image':
          'https://images.unsplash.com/photo-1643184012410-0d0c9070e575',
      'semanticLabel':
          'Person meditating peacefully beside natural cold water spring in forest setting',
    },
  ];

  // Mock leaderboard data
  final List<Map<String, dynamic>> _leaderboardData = [
    {
      'name': 'Sarah Chen',
      'score': 28,
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_19dc77a7e-1762274545448.png',
      'avatarSemanticLabel':
          'Professional headshot of Asian woman with long black hair smiling',
      'isCurrentUser': false,
      'isFriend': true,
    },
    {
      'name': 'Marcus Johnson',
      'score': 25,
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1f8f2e5bd-1762249046974.png',
      'avatarSemanticLabel':
          'Professional headshot of African American man with beard in business attire',
      'isCurrentUser': false,
      'isFriend': false,
    },
    {
      'name': 'You',
      'score': 23,
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1584b53a9-1762273471611.png',
      'avatarSemanticLabel':
          'Professional headshot of young man with brown hair in casual shirt',
      'isCurrentUser': true,
      'isFriend': false,
    },
    {
      'name': 'Emma Rodriguez',
      'score': 21,
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1beb9fc75-1762273370028.png',
      'avatarSemanticLabel':
          'Professional headshot of Hispanic woman with curly hair smiling',
      'isCurrentUser': false,
      'isFriend': true,
    },
    {
      'name': 'David Kim',
      'score': 19,
      'avatar':
          'https://img.rocket.new/generatedImages/rocket_gen_img_117f45e37-1762273829255.png',
      'avatarSemanticLabel':
          'Professional headshot of Asian man with glasses in formal wear',
      'isCurrentUser': false,
      'isFriend': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredChallenges {
    switch (_selectedFilter) {
      case 'active':
        return _allChallenges.where((c) => c['isActive'] as bool).toList();
      case 'upcoming':
        return _allChallenges
            .where(
                (c) => !(c['isJoined'] as bool) && c['timeLeft'] != 'Completed')
            .toList();
      case 'completed':
        return _allChallenges
            .where((c) => c['timeLeft'] == 'Completed')
            .toList();
      default:
        return _allChallenges;
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
      body: Column(
        children: [
          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
              unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
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
                _buildLeaderboardTab(),
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

  Widget _buildChallengesTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Challenge Hero Section
          ActiveChallengeWidget(
            activeChallenge: _activeChallenge,
            onTap: _showChallengeDetails,
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
    );
  }

  Widget _buildLeaderboardTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 2.h),
          LeaderboardWidget(
            leaderboardData: _leaderboardData,
            currentUserPosition: 3,
          ),
          SizedBox(height: 4.h),
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

  void _joinChallenge(Map<String, dynamic> challenge) {
    // Simulate joining challenge
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully joined "${challenge['title']}"!'),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
