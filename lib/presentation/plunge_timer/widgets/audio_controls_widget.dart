import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AudioControlsWidget extends StatefulWidget {
  final bool isPlaying;
  final String currentTrack;
  final double volume;
  final VoidCallback? onPlayPause;
  final Function(String)? onTrackChange;
  final Function(double)? onVolumeChange;

  const AudioControlsWidget({
    super.key,
    this.isPlaying = false,
    this.currentTrack = 'Ocean Waves',
    this.volume = 0.7,
    this.onPlayPause,
    this.onTrackChange,
    this.onVolumeChange,
  });

  @override
  State<AudioControlsWidget> createState() => _AudioControlsWidgetState();
}

class _AudioControlsWidgetState extends State<AudioControlsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  bool _isExpanded = false;

  final List<Map<String, dynamic>> _soundscapes = [
    {
      'name': 'Ocean Waves',
      'icon': 'waves',
      'description': 'Calming ocean sounds',
      'duration': '∞',
    },
    {
      'name': 'Rain Sounds',
      'icon': 'grain',
      'description': 'Gentle rainfall',
      'duration': '∞',
    },
    {
      'name': 'Guided Breathing',
      'icon': 'air',
      'description': '4-7-8 breathing pattern',
      'duration': '10:00',
    },
    {
      'name': 'Forest Ambience',
      'icon': 'park',
      'description': 'Birds and nature sounds',
      'duration': '∞',
    },
    {
      'name': 'White Noise',
      'icon': 'graphic_eq',
      'description': 'Pure white noise',
      'duration': '∞',
    },
  ];

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact controls
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  // Play/Pause button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onPlayPause?.call();
                    },
                    child: Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: widget.isPlaying
                            ? colorScheme.primary
                            : colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: widget.isPlaying ? 'pause' : 'play_arrow',
                        color: widget.isPlaying
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),

                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.currentTrack,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.isPlaying ? 'Playing' : 'Paused',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Volume indicator
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: widget.volume > 0.5
                              ? 'volume_up'
                              : widget.volume > 0
                                  ? 'volume_down'
                                  : 'volume_off',
                          color: colorScheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${(widget.volume * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expand indicator
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: CustomIconWidget(
                      iconName: 'keyboard_arrow_down',
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded controls
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
              child: Column(
                children: [
                  Divider(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  SizedBox(height: 3.h),

                  // Volume slider
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'volume_down',
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      Expanded(
                        child: Slider(
                          value: widget.volume,
                          onChanged: (value) {
                            widget.onVolumeChange?.call(value);
                            HapticFeedback.selectionClick();
                          },
                          activeColor: colorScheme.primary,
                          inactiveColor:
                              colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      CustomIconWidget(
                        iconName: 'volume_up',
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),

                  // Soundscape selection
                  Text(
                    'Choose Soundscape',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Soundscape grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 3.w,
                      mainAxisSpacing: 2.h,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _soundscapes.length,
                    itemBuilder: (context, index) {
                      final soundscape = _soundscapes[index];
                      final isSelected =
                          widget.currentTrack == soundscape['name'];

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onTrackChange?.call(soundscape['name']);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary.withValues(alpha: 0.1)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline.withValues(alpha: 0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary
                                          .withValues(alpha: 0.2)
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CustomIconWidget(
                                  iconName: soundscape['icon'],
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      soundscape['name'],
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.onSurface,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      soundscape['duration'],
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
