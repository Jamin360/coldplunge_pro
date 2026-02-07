import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class MoodSlider extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const MoodSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<MoodSlider> createState() => _MoodSliderState();
}

class _MoodSliderState extends State<MoodSlider> {
  double _sliderValue = 5.0;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.value.toDouble();
  }

  @override
  void didUpdateWidget(MoodSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _sliderValue = widget.value.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Animated pill positioned above slider
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            const pillWidth = 70.0;
            const thumbRadius = 12.0;

            // Calculate position based on slider value
            // Account for thumb radius to align pill center with thumb center
            final effectiveTrackWidth = trackWidth - (thumbRadius * 2);
            final t = (_sliderValue - 1) / (10 - 1); // normalize 1-10 to 0-1
            final thumbCenterX = thumbRadius + (t * effectiveTrackWidth);

            // Calculate pill position (centered on thumb)
            double pillX = thumbCenterX - (pillWidth / 2);

            // Clamp to prevent overflow
            pillX = pillX.clamp(0.0, trackWidth - pillWidth);

            return Stack(
              children: [
                // Pill with animation
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  left: pillX,
                  child: Container(
                    width: pillWidth,
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.8.h,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_sliderValue.round()}/10',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                // Spacer to create vertical space for pill
                SizedBox(height: 5.h),
              ],
            );
          },
        ),

        SizedBox(height: 1.2.h),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withValues(alpha: 0.1),
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 12.0,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 20.0,
            ),
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: _sliderValue,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) {
              setState(() => _sliderValue = value);
              widget.onChanged(value.round());
              HapticFeedback.lightImpact();
            },
          ),
        ),

        // Low/High labels
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'High',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
