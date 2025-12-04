import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SessionCompletionWidget extends StatefulWidget {
  final Duration sessionDuration;
  final double temperature;
  final String location;
  final Function(int mood, String notes) onComplete;
  final VoidCallback onSkip;

  const SessionCompletionWidget({
    super.key,
    required this.sessionDuration,
    required this.temperature,
    required this.location,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<SessionCompletionWidget> createState() =>
      _SessionCompletionWidgetState();
}

class _SessionCompletionWidgetState extends State<SessionCompletionWidget>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _slideController;
  late Animation<double> _celebrationAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _notesController = TextEditingController();
  int _postMood = 4;
  bool _showPhotoOption = false;

  final List<Map<String, dynamic>> _moodOptions = [
    {'emoji': '😫', 'label': 'Exhausted', 'value': 1},
    {'emoji': '😮‍💨', 'label': 'Relieved', 'value': 2},
    {'emoji': '😊', 'label': 'Good', 'value': 3},
    {'emoji': '🤩', 'label': 'Amazing', 'value': 4},
    {'emoji': '🔥', 'label': 'Incredible', 'value': 5},
  ];

  final List<String> _achievements = [
    '🏆 Cold Warrior',
    '❄️ Ice Breaker',
    '💪 Endurance Master',
    '🧘 Mindful Plunger',
  ];

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _celebrationController.forward();
    _slideController.forward();

    // Auto-generate encouraging note
    _notesController.text = _generateEncouragingNote();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _slideController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generateEncouragingNote() {
    final minutes = widget.sessionDuration.inMinutes;
    final seconds = widget.sessionDuration.inSeconds % 60;
    final tempCelsius = widget.temperature;
    final tempFahrenheit = (tempCelsius * 9 / 5 + 32).toStringAsFixed(
      1,
    ); // Convert to Fahrenheit

    final notes = [
      'Conquered ${minutes}m ${seconds}s at ${tempFahrenheit}°F! Feeling stronger already 💪',
      'Another successful plunge at ${tempFahrenheit}°F. Mind over matter! 🧠❄️',
      'Pushed through ${minutes}m ${seconds}s of cold therapy. Growth mindset activated! 🚀',
      'Cold exposure complete! ${tempFahrenheit}°F couldn\'t break my focus 🎯',
      'Session done at ${widget.location}. Every plunge builds resilience! 🏔️',
    ];

    return notes[DateTime.now().millisecond % notes.length];
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _handleComplete() {
    HapticFeedback.mediumImpact();
    widget.onComplete(_postMood, _notesController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        height: 90.h,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(6.w),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 4.h),

                // Celebration animation
                AnimatedBuilder(
                  animation: _celebrationAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _celebrationAnimation.value,
                      child: Container(
                        width: 25.w,
                        height: 25.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.2),
                              colorScheme.primary.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text('🎉', style: TextStyle(fontSize: 40.sp)),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 3.h),

                // Completion message
                Text(
                  'Session Complete!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'You conquered the cold! 💪',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4.h),

                // Session stats
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            context,
                            'Duration',
                            _formatDuration(widget.sessionDuration),
                            Icons.timer,
                          ),
                          _buildStatItem(
                            context,
                            'Temperature',
                            '${(widget.temperature * 9 / 5 + 32).toStringAsFixed(1)}°F', // Changed: Display in Fahrenheit
                            Icons.thermostat,
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      _buildStatItem(
                        context,
                        'Location',
                        widget.location,
                        Icons.location_on,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),

                // Achievements
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievements Unlocked',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Wrap(
                        spacing: 2.w,
                        runSpacing: 1.h,
                        children:
                            _achievements.take(2).map((achievement) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: colorScheme.tertiary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  achievement,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: colorScheme.tertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),

                // Post-session mood
                Text(
                  'How do you feel now?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      _moodOptions.map((mood) {
                        final isSelected = _postMood == mood['value'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _postMood = mood['value']);
                            HapticFeedback.lightImpact();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.5.w,
                              vertical: 1.5.h,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      )
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outline.withValues(
                                          alpha: 0.3,
                                        ),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  mood['emoji'],
                                  style: TextStyle(fontSize: 18.sp),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  mood['label'],
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        isSelected
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
                SizedBox(height: 4.h),

                // Notes section
                Text(
                  'Session Notes (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'How did this session feel? Any insights?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onSkip,
                        child: Text('Skip'),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _handleComplete,
                        child: Text('Save Session'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool fullWidth = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: fullWidth ? double.infinity : null,
      child: Column(
        children: [
          CustomIconWidget(
            iconName: _getIconName(icon),
            color: colorScheme.primary,
            size: 24,
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getIconName(IconData icon) {
    if (icon == Icons.timer) return 'timer';
    if (icon == Icons.thermostat) return 'thermostat';
    if (icon == Icons.location_on) return 'location_on';
    return 'info';
  }
}
