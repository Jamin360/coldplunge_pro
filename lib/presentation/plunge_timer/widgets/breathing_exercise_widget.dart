import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class BreathingExerciseWidget extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onToggle;
  final VoidCallback? onClose;

  const BreathingExerciseWidget({
    super.key,
    this.isActive = false,
    this.onToggle,
    this.onClose,
  });

  @override
  State<BreathingExerciseWidget> createState() =>
      _BreathingExerciseWidgetState();
}

class _BreathingExerciseWidgetState extends State<BreathingExerciseWidget>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _fadeController;
  late Animation<double> _breatheAnimation;
  late Animation<double> _fadeAnimation;

  int _currentCycle = 0;
  int _currentPhase = 0; // 0: inhale, 1: hold, 2: exhale, 3: hold
  String _currentInstruction = 'Breathe in slowly...';

  final List<String> _instructions = [
    'Breathe in slowly...',
    'Hold your breath...',
    'Breathe out slowly...',
    'Hold empty...',
  ];

  final List<int> _phaseDurations = [4, 2, 6, 2]; // seconds for each phase

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      duration: Duration(seconds: _phaseDurations[0]),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _breatheAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breatheController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _startBreathingCycle();
    }
  }

  @override
  void didUpdateWidget(BreathingExerciseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startBreathingCycle();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopBreathingCycle();
    }
  }

  void _startBreathingCycle() {
    _fadeController.forward();
    _runBreathingPhase();
  }

  void _stopBreathingCycle() {
    _breatheController.stop();
    _fadeController.reverse();
    setState(() {
      _currentCycle = 0;
      _currentPhase = 0;
      _currentInstruction = _instructions[0];
    });
  }

  void _runBreathingPhase() {
    if (!widget.isActive || !mounted) return;

    setState(() {
      _currentInstruction = _instructions[_currentPhase];
    });

    _breatheController.duration =
        Duration(seconds: _phaseDurations[_currentPhase]);

    // Set animation direction based on phase
    if (_currentPhase == 0) {
      // Inhale
      _breatheController.forward(from: 0);
    } else if (_currentPhase == 2) {
      // Exhale
      _breatheController.reverse(from: 1);
    } else {
      // Hold phases
      // Keep current position
    }

    Future.delayed(Duration(seconds: _phaseDurations[_currentPhase]), () {
      if (!widget.isActive || !mounted) return;

      _currentPhase = (_currentPhase + 1) % 4;
      if (_currentPhase == 0) {
        _currentCycle++;
        HapticFeedback.lightImpact();
      }

      _runBreathingPhase();
    });
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        padding: EdgeInsets.all(3.w),
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Breathing Exercise',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onClose?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: 'close',
                        color: colorScheme.onSurface,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),

              // Breathing visualization
              AnimatedBuilder(
                animation: _breatheAnimation,
                builder: (context, child) {
                  return Container(
                    width: 35.w,
                    height: 35.w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        Container(
                          width: 35.w * _breatheAnimation.value,
                          height: 35.w * _breatheAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                        ),
                        // Inner circle
                        Container(
                          width: 25.w * _breatheAnimation.value,
                          height: 25.w * _breatheAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.2),
                                colorScheme.primary.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                        // Center dot
                        Container(
                          width: 4.w,
                          height: 4.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 1.5.h),

              // Instruction text
              Text(
                _currentInstruction,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),

              // Cycle counter
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Cycle ${_currentCycle + 1}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),

              // Control button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onToggle?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isActive
                        ? colorScheme.error
                        : colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                  child: Text(
                    widget.isActive ? 'Stop Exercise' : 'Start Exercise',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
