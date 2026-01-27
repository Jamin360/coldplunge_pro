import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle challenge completion notifications
/// Uses a stream to emit completion events that can be listened to globally
class ChallengeCompletionNotifier {
  static ChallengeCompletionNotifier? _instance;
  static ChallengeCompletionNotifier get instance =>
      _instance ??= ChallengeCompletionNotifier._();

  ChallengeCompletionNotifier._();

  final _completionController =
      StreamController<List<ChallengeCompletion>>.broadcast();

  Stream<List<ChallengeCompletion>> get completionStream =>
      _completionController.stream;

  final Set<String> _shownCompletions = {};
  bool _isInitialized = false;

  /// Initialize the notifier by loading previously shown completions
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final shown = prefs.getStringList('shown_challenge_completions') ?? [];
      _shownCompletions.addAll(shown);
      _isInitialized = true;
    } catch (e) {
      print('Failed to load shown completions: $e');
      _isInitialized = true;
    }
  }

  /// Notify about completed challenges
  /// Only emits if not already shown
  Future<void> notifyCompletion(List<ChallengeCompletion> completions) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Filter out already shown completions
    final newCompletions =
        completions.where((c) => !_shownCompletions.contains(c.id)).toList();

    if (newCompletions.isEmpty) return;

    // Mark as shown
    for (final completion in newCompletions) {
      _shownCompletions.add(completion.id);
    }

    // Persist to storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'shown_challenge_completions',
        _shownCompletions.toList(),
      );
    } catch (e) {
      print('Failed to save shown completions: $e');
    }

    // Emit the event
    _completionController.add(newCompletions);
  }

  /// Show the completion dialog
  static Future<void> showCompletionDialog(
    BuildContext context,
    List<ChallengeCompletion> completions,
  ) async {
    if (completions.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => _CompletionBottomSheet(completions: completions),
    );
  }

  void dispose() {
    _completionController.close();
  }
}

/// Data class for challenge completion
class ChallengeCompletion {
  final String id;
  final String challengeId;
  final String name;
  final String? difficulty;
  final DateTime completedAt;

  ChallengeCompletion({
    required this.id,
    required this.challengeId,
    required this.name,
    this.difficulty,
    required this.completedAt,
  });
}

/// Bottom sheet widget for challenge completion
class _CompletionBottomSheet extends StatelessWidget {
  final List<ChallengeCompletion> completions;

  const _CompletionBottomSheet({required this.completions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        top: 3.h,
        left: 5.w,
        right: 5.w,
        bottom: MediaQuery.of(context).padding.bottom + 3.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            padding: EdgeInsets.all(2.h),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              size: 48,
              color: const Color(0xFF10B981),
            ),
          ),
          SizedBox(height: 2.h),

          // Title
          Text(
            'Challenge Complete!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),

          // Challenge names
          if (completions.length == 1)
            Column(
              children: [
                Text(
                  completions.first.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (completions.first.difficulty != null) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    completions.first.difficulty!.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            )
          else
            Column(
              children: [
                Text(
                  completions.first.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (completions.length > 1)
                  Text(
                    '+${completions.length - 1} more',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          SizedBox(height: 1.5.h),

          // Reward text
          Text(
            'Nice work — keep the streak going!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Nice!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to challenges tab
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home_dashboard',
                      (route) => false,
                      arguments: {'initialTab': 2}, // Challenges tab
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'View Challenges',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
