import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CommentBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onCommentAdded;

  const CommentBottomSheetWidget({
    super.key,
    required this.post,
    this.onCommentAdded,
  });

  @override
  State<CommentBottomSheetWidget> createState() =>
      _CommentBottomSheetWidgetState();
}

class _CommentBottomSheetWidgetState extends State<CommentBottomSheetWidget>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;

  // Mock comments data
  final List<Map<String, dynamic>> _comments = [
    {
      "id": 1,
      "userName": "Sarah Chen",
      "userAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1af54ceb1-1763295330262.png",
      "userAvatarSemanticLabel":
          "Asian woman with long black hair smiling at camera wearing white top",
      "comment": "Amazing dedication! That water looks freezing 🥶",
      "timeAgo": "2h ago",
      "likesCount": 12,
      "isLiked": false,
    },
    {
      "id": 2,
      "userName": "Mike Rodriguez",
      "userAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_13539cf1a-1763294982283.png",
      "userAvatarSemanticLabel":
          "Hispanic man with beard wearing blue shirt outdoors",
      "comment":
          "I've been trying to build up to 5 minutes. Any tips for beginners?",
      "timeAgo": "1h ago",
      "likesCount": 8,
      "isLiked": true,
    },
    {
      "id": 3,
      "userName": "Emma Thompson",
      "userAvatar":
          "https://images.unsplash.com/photo-1511373800525-05da6d924ef2",
      "userAvatarSemanticLabel":
          "Blonde woman in casual clothing smiling in natural lighting",
      "comment":
          "The mental clarity after cold plunges is incredible! Keep it up 💪",
      "timeAgo": "45m ago",
      "likesCount": 15,
      "isLiked": false,
    },
    {
      "id": 4,
      "userName": "David Kim",
      "userAvatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_182106f63-1763294687350.png",
      "userAvatarSemanticLabel":
          "Asian man with glasses wearing dark sweater in professional setting",
      "comment":
          "What's your breathing technique? I struggle with the initial shock.",
      "timeAgo": "30m ago",
      "likesCount": 6,
      "isLiked": false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimationController.forward();

    // Auto-focus comment input after animation
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _commentFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();

    // Here you would typically add the comment to your backend
    // For now, we'll just simulate success

    _commentController.clear();
    widget.onCommentAdded?.call();

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Comment added successfully!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleCommentLike(int commentId) {
    HapticFeedback.lightImpact();
    setState(() {
      final commentIndex = _comments.indexWhere((c) => c['id'] == commentId);
      if (commentIndex != -1) {
        final comment = _comments[commentIndex];
        final isLiked = comment['isLiked'] as bool;
        comment['isLiked'] = !isLiked;
        comment['likesCount'] =
            (comment['likesCount'] as int) + (isLiked ? -1 : 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(theme, colorScheme),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    return _buildCommentItem(
                        _comments[index], theme, colorScheme);
                  },
                ),
              ),
              _buildCommentInput(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  child: CustomIconWidget(
                    iconName: 'keyboard_arrow_down',
                    color: colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Comments',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 10.w), // Balance the close button
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(
    Map<String, dynamic> comment,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isLiked = comment['isLiked'] as bool;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl: comment['userAvatar'] as String,
                width: 10.w,
                height: 10.w,
                fit: BoxFit.cover,
                semanticLabel: comment['userAvatarSemanticLabel'] as String,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['userName'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      comment['timeAgo'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  comment['comment'] as String,
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleCommentLike(comment['id'] as int),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: isLiked ? 'favorite' : 'favorite_border',
                            color: isLiked
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${comment['likesCount']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isLiked
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight:
                                  isLiked ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 4.w),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _commentController.text = '@${comment['userName']} ';
                        _commentFocusNode.requestFocus();
                      },
                      child: Text(
                        'Reply',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'person',
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 2.h,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _addComment(),
            ),
          ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: _addComment,
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: _commentController.text.trim().isNotEmpty
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'send',
                  color: _commentController.text.trim().isNotEmpty
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
