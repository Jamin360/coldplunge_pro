import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityService {
  static CommunityService? _instance;
  static CommunityService get instance => _instance ??= CommunityService._();

  CommunityService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Get community posts with user information
  Future<List<Map<String, dynamic>>> getCommunityPosts({
    int limit = 20,
    int offset = 0,
    String? activityType,
  }) async {
    try {
      var query = _client.from('community_posts').select('''
            *,
            user_profiles:user_id (
              id,
              full_name,
              avatar_url
            ),
            plunge_sessions:related_session_id (
              location,
              duration,
              temperature
            ),
            challenges:related_challenge_id (
              title
            )
          ''');

      if (activityType != null) {
        query = query.eq('activity_type', activityType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Transform response to match expected format
      final posts = <Map<String, dynamic>>[];

      for (final item in response) {
        final userProfile = item['user_profiles'] as Map<String, dynamic>?;
        final session = item['plunge_sessions'] as Map<String, dynamic>?;
        final challenge = item['challenges'] as Map<String, dynamic>?;

        posts.add({
          'id': item['id'],
          'userName': userProfile?['full_name'] ?? 'Unknown User',
          'userAvatar': userProfile?['avatar_url'] ?? '',
          'userAvatarSemanticLabel':
              'Profile picture of ${userProfile?['full_name'] ?? 'user'}',
          'activityType': item['activity_type'],
          'content': item['content'],
          'timestamp': DateTime.parse(item['created_at']),
          'likes': item['likes_count'] ?? 0,
          'imageUrl': item['image_url'],
          'relatedSession': session != null
              ? {
                  'location': session['location'],
                  'duration': session['duration'],
                  'temperature': session['temperature'],
                }
              : null,
          'relatedChallenge': challenge != null
              ? {
                  'title': challenge['title'],
                }
              : null,
        });
      }

      return posts;
    } catch (error) {
      throw Exception('Failed to get community posts: $error');
    }
  }

  /// Create a new community post
  Future<Map<String, dynamic>> createPost({
    required String content,
    String? imageUrl,
    String? photoPath,
    String activityType = 'plunge',
    String? relatedSessionId,
    String? relatedChallengeId,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final postData = {
        'user_id': currentUser.id,
        'content': content,
        'activity_type': activityType,
        'image_url': imageUrl,
        'photo_path': photoPath,
        'related_session_id': relatedSessionId,
        'related_challenge_id': relatedChallengeId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _client.from('community_posts').insert(postData).select('''
            *,
            user_profiles:user_id (
              full_name,
              avatar_url
            )
          ''').single();

      return response;
    } catch (error) {
      throw Exception('Failed to create post: $error');
    }
  }

  /// Like or unlike a post
  Future<void> togglePostLike(String postId) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check if user already liked the post
      final existingLike = await _client
          .from('post_likes')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('post_id', postId)
          .limit(1);

      if (existingLike.isNotEmpty) {
        // Remove like
        await _client
            .from('post_likes')
            .delete()
            .eq('user_id', currentUser.id)
            .eq('post_id', postId);
      } else {
        // Add like
        await _client.from('post_likes').insert({
          'user_id': currentUser.id,
          'post_id': postId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (error) {
      throw Exception('Failed to toggle post like: $error');
    }
  }

  /// Check if current user liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return false;

    try {
      final response = await _client
          .from('post_likes')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('post_id', postId)
          .limit(1);

      return response.isNotEmpty;
    } catch (error) {
      return false;
    }
  }

  /// Get user's own posts
  Future<List<Map<String, dynamic>>> getUserPosts({
    String? userId,
    int limit = 20,
  }) async {
    final currentUser = _client.auth.currentUser;
    final targetUserId = userId ?? currentUser?.id;

    if (targetUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await _client
          .from('community_posts')
          .select('''
            *,
            user_profiles:user_id (
              full_name,
              avatar_url
            ),
            plunge_sessions:related_session_id (
              location,
              duration,
              temperature
            ),
            challenges:related_challenge_id (
              title
            )
          ''')
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get user posts: $error');
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('community_posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', currentUser.id);
    } catch (error) {
      throw Exception('Failed to delete post: $error');
    }
  }

  /// Get community highlights (popular/recent posts)
  Future<List<Map<String, dynamic>>> getCommunityHighlights(
      {int limit = 5}) async {
    try {
      final response = await _client
          .from('community_posts')
          .select('''
            *,
            user_profiles:user_id (
              full_name,
              avatar_url
            )
          ''')
          .order('likes_count', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      // Transform to match expected format
      final highlights = <Map<String, dynamic>>[];

      for (final item in response) {
        final userProfile = item['user_profiles'] as Map<String, dynamic>?;

        highlights.add({
          'userName': userProfile?['full_name'] ?? 'Unknown User',
          'userAvatar': userProfile?['avatar_url'] ?? '',
          'userAvatarSemanticLabel':
              'Profile picture of ${userProfile?['full_name'] ?? 'user'}',
          'activityType': item['activity_type'],
          'content': item['content'],
          'timestamp': DateTime.parse(item['created_at']),
          'likes': item['likes_count'] ?? 0,
        });
      }

      return highlights;
    } catch (error) {
      throw Exception('Failed to get community highlights: $error');
    }
  }

  /// Get post statistics for analytics
  Future<Map<String, dynamic>> getPostStats() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get user's posts count
      final postsCount = await _client
          .from('community_posts')
          .select('id')
          .eq('user_id', currentUser.id)
          .count();

      // Get total likes received
      final likesResponse = await _client
          .from('community_posts')
          .select('likes_count')
          .eq('user_id', currentUser.id);

      final totalLikes = likesResponse.fold<int>(
          0, (sum, post) => sum + (post['likes_count'] as int? ?? 0));

      // Get most popular post
      final popularPosts = await _client
          .from('community_posts')
          .select('content, likes_count')
          .eq('user_id', currentUser.id)
          .order('likes_count', ascending: false)
          .limit(1);

      final mostPopularPost =
          popularPosts.isNotEmpty ? popularPosts.first : null;

      return {
        'total_posts': postsCount.count,
        'total_likes_received': totalLikes,
        'most_popular_post': mostPopularPost?['content'] ?? 'N/A',
        'most_popular_likes': mostPopularPost?['likes_count'] ?? 0,
      };
    } catch (error) {
      throw Exception('Failed to get post stats: $error');
    }
  }

  /// Subscribe to real-time post updates
  RealtimeChannel subscribeToPosts() {
    return _client
        .channel('community_posts_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'community_posts',
          callback: (payload) {
            // Handle real-time updates here
            print('Post updated: ${payload.newRecord}');
          },
        )
        .subscribe();
  }

  /// Subscribe to real-time like updates
  RealtimeChannel subscribeToLikes() {
    return _client
        .channel('post_likes_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_likes',
          callback: (payload) {
            // Handle real-time like updates here
            print('Like updated: ${payload.newRecord}');
          },
        )
        .subscribe();
  }
}
