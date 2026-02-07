import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import 'mood_slider.dart';

class SessionCompletionWidget extends StatefulWidget {
  final int duration;
  final double? temperature;
  final String tempUnit; // 'C' or 'F'
  final Function(int mood, String notes) onSaveSession;
  final VoidCallback onDiscardSession;

  const SessionCompletionWidget({
    super.key,
    required this.duration,
    this.temperature,
    this.tempUnit = 'F',
    required this.onSaveSession,
    required this.onDiscardSession,
  });

  @override
  State<SessionCompletionWidget> createState() =>
      _SessionCompletionWidgetState();
}

class _SessionCompletionWidgetState extends State<SessionCompletionWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;
  double _selectedMood = 5.0; // Default to middle (5/10)

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}m ${remainingSeconds}s';
    }
    return '${seconds}s';
  }

  void _handleSaveSession() {
    HapticFeedback.mediumImpact();
    widget.onSaveSession(_selectedMood.round(), _notesController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final keyboardInsets = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 24,
                        bottom: 24 + keyboardInsets,
                      ),
                      children: [
                        // Session Complete header
                        Text(
                          'Session Complete!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Great job! How was your plunge?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 4.h),

                        // Session stats - inline card layout
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Duration',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      _formatDuration(widget.duration),
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.temperature != null) ...[
                                Container(
                                  width: 1,
                                  height: 5.h,
                                  color: colorScheme.outlineVariant,
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Temperature',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        widget.tempUnit == 'C'
                                            ? '${((widget.temperature! - 32) * 5 / 9).round()}°C'
                                            : '${widget.temperature!.round()}°F',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 4.h),

                        // Post-session mood selector
                        Text(
                          'Post-Plunge Mood',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        // Mood slider with animated pill
                        MoodSlider(
                          value: _selectedMood.round(),
                          onChanged: (value) {
                            setState(() => _selectedMood = value.toDouble());
                          },
                        ),
                        SizedBox(height: 4.h),

                        // Session notes
                        Text(
                          'Add notes (optional)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          scrollPadding:
                              EdgeInsets.only(bottom: keyboardInsets + 140),
                          decoration: InputDecoration(
                            hintText: 'How was the experience?',
                          ),
                        ),
                        SizedBox(height: 4.h),

                        // Full-width Save Session button
                        SizedBox(
                          width: double.infinity,
                          height: 70,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _handleSaveSession,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text('Save Session'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
