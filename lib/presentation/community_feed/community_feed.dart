import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/community_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/comment_bottom_sheet_widget.dart';
import './widgets/create_post_widget.dart';
import './widgets/post_card_widget.dart';
import './widgets/story_highlights_widget.dart';

class CommunityFeed extends StatefulWidget {
  const CommunityFeed({super.key});

  @override
  State<CommunityFeed> createState() => _CommunityFeedState();
}

class _CommunityFeedState extends State<CommunityFeed>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isRefreshing = false;
  bool _isLoading = true;
  int _currentBottomNavIndex = 2; // Community tab

  late AnimationController _refreshAnimationController;
  late Animation<double> _refreshAnimation;

  List<Map<String, dynamic>> _posts = [];

  // Mock data for community feed
  final List<Map<String, dynamic>> _highlights = [
    {
      "id": 1,
      "title": "30-Day Challenge",
      "type": "challenge",
      "isActive": true,
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_179562485-1768447038399.png",
      "imageSemanticLabel": "Ice bath challenge badge with snowflake design",
    },
    {
      "id": 2,
      "title": "Wim Hof Method",
      "type": "highlight",
      "isActive": false,
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1290f1542-1766041961993.png",
      "imageSemanticLabel":
          "Man practicing breathing exercises in cold environment",
    },
    {
      "id": 3,
      "title": "Beginner Tips",
      "type": "highlight",
      "isActive": false,
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_180aa420f-1766260854369.png",
      "imageSemanticLabel": "Instructional guide for cold plunge beginners",
    },
    {
      "id": 4,
      "title": "Weekly Goals",
      "type": "challenge",
      "isActive": true,
      "image":
          "https://img.rocket.new/generatedImages/rocket_gen_img_151565ba0-1768447036376.png",
      "imageSemanticLabel": "Weekly challenge tracker with progress indicators",
    },
  ];

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshAnimationController,
      curve: Curves.easeInOut,
    ));

    _loadPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final posts = await CommunityService.instance.getCommunityPosts(
        limit: 20,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load posts: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.mediumImpact();
    _refreshAnimationController.forward();

    await _loadPosts();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      _refreshAnimationController.reset();
    }
  }

  void _showCreatePost() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePostWidget(),
    ).then((_) {
      _handleRefresh();
    });
  }

  void _showComments(Map<String, dynamic> post) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheetWidget(
        post: post,
        onCommentAdded: () {
          // Update comment count
          setState(() {
            final postIndex = _posts.indexWhere((p) => p['id'] == post['id']);
            if (postIndex != -1) {
              _posts[postIndex]['commentsCount'] =
                  (_posts[postIndex]['commentsCount'] as int) + 1;
            }
          });
        },
      ),
    );
  }

  void _handlePostLike(Map<String, dynamic> post) {
    HapticFeedback.lightImpact();
    setState(() {
      final postIndex = _posts.indexWhere((p) => p['id'] == post['id']);
      if (postIndex != -1) {
        final isLiked = _posts[postIndex]['isLiked'] as bool;
        _posts[postIndex]['isLiked'] = !isLiked;
        _posts[postIndex]['likesCount'] =
            (_posts[postIndex]['likesCount'] as int) + (isLiked ? -1 : 1);
      }
    });
  }

  void _handlePostShare(Map<String, dynamic> post) {
    HapticFeedback.lightImpact();
    // Implement platform-specific sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${post['userName']}\'s post...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(theme, colorScheme),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (_isRefreshing) _buildRefreshIndicator(),
                  if (!_isSearching) _buildHighlightsSection(),
                  _buildPostsList(),
                  _buildBottomPadding(),
                ],
              ),
            ),
      floatingActionButton: _buildFloatingActionButton(colorScheme),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() {
            _currentBottomNavIndex = index;
          });
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: Colors.transparent,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search posts, users, challenges...',
                border: InputBorder.none,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              style: theme.textTheme.bodyMedium,
            )
          : Text(
              'Community',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
      actions: [
        GestureDetector(
          onTap: _toggleSearch,
          child: Container(
            padding: EdgeInsets.all(2.w),
            child: CustomIconWidget(
              iconName: _isSearching ? 'close' : 'search',
              color: colorScheme.onSurface,
              size: 24,
            ),
          ),
        ),
        if (!_isSearching)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // Show notifications or activity
            },
            child: Container(
              padding: EdgeInsets.all(2.w),
              margin: EdgeInsets.only(right: 2.w),
              child: Stack(
                children: [
                  CustomIconWidget(
                    iconName: 'notifications_outlined',
                    color: colorScheme.onSurface,
                    size: 24,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 2.w,
                      height: 2.w,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRefreshIndicator() {
    return SliverToBoxAdapter(
      child: Container(
        height: 8.h,
        child: Center(
          child: AnimatedBuilder(
            animation: _refreshAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshAnimation.value * 2 * 3.14159,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'water_drop',
                      color: Colors.white,
                      size: 4.w,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightsSection() {
    return SliverToBoxAdapter(
      child: StoryHighlightsWidget(
        highlights: _highlights,
        onHighlightTap: (highlight) {
          HapticFeedback.lightImpact();
          // Navigate to challenge or highlight detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${highlight['title']}...'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsList() {
    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = _posts[index];
          return PostCardWidget(
            post: post,
            onLike: () => _handlePostLike(post),
            onComment: () => _showComments(post),
            onShare: () => _handlePostShare(post),
            onTap: () {
              // Navigate to post detail
              HapticFeedback.lightImpact();
            },
          );
        },
        childCount: _posts.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'people_outline',
                  color: colorScheme.primary,
                  size: 15.w,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Welcome to the Community!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                'Share your cold plunge journey, connect with fellow enthusiasts, and discover new challenges.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: _showCreatePost,
              child: Text('Share Your First Plunge'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPadding() {
    return SliverToBoxAdapter(
      child: SizedBox(height: 20.h), // Space for FAB and bottom nav
    );
  }

  Widget _buildFloatingActionButton(ColorScheme colorScheme) {
    return FloatingActionButton(
      onPressed: _showCreatePost,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 6,
      child: CustomIconWidget(
        iconName: 'add',
        color: colorScheme.onPrimary,
        size: 28,
      ),
    );
  }
}
