import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/feature_flags.dart';
import '../../services/session_service.dart';
import '../../services/challenge_service.dart';
import './widgets/audio_controls_widget.dart';
import './widgets/breathing_exercise_widget.dart';
import './widgets/session_completion_widget.dart';
import './widgets/session_setup_widget.dart';
import './widgets/timer_controls_widget.dart';
import './widgets/timer_display_widget.dart';

class PlungeTimer extends StatefulWidget {
  const PlungeTimer({super.key});

  @override
  State<PlungeTimer> createState() => _PlungeTimerState();
}

class _PlungeTimerState extends State<PlungeTimer>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Timer state
  Timer? _timer;
  Timer? _countdownTimer;
  Duration _sessionDuration = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isCountingDown = false;
  int _countdownValue = 5;

  // Session data
  double _temperature = 15.0;
  String _tempUnit = 'F'; // 'C' or 'F' - unit user selected in Session Setup
  String _location = 'Home Ice Bath';
  int _preMood = 5; // Default to middle (5/10)
  int _postMood = 5; // Default to middle (5/10)
  String _sessionNotes = '';
  String? _breathingTechnique;

  // UI state
  bool _showCompletionWidget = false;
  Duration _completedDuration = Duration.zero;

  // Audio state
  bool _isAudioPlaying = false;
  String _currentTrack = 'Ocean Waves';
  double _audioVolume = 0.7;

  // Breathing exercise state
  bool _showBreathingExercise = false;
  bool _isBreathingActive = false;

  // Animation controllers
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _backgroundAnimation = ColorTween(
      begin: AppTheme.lightTheme.scaffoldBackgroundColor,
      end: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
    ).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Keep screen awake during sessions
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _countdownTimer?.cancel();
    _backgroundController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app backgrounding during active session
    if (state == AppLifecycleState.paused && _isRunning && !_isPaused) {
      _showBackgroundNotification();
    }
  }

  void _showBackgroundNotification() {
    // In a real app, this would show a rich notification
    // with elapsed time and session controls
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cold plunge session continues in background'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startCountdown() {
    // Cancel existing countdown timer if any
    _countdownTimer?.cancel();

    setState(() {
      _isCountingDown = true;
      _countdownValue = 5;
    });

    HapticFeedback.mediumImpact();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 1) {
        setState(() => _countdownValue--);
        HapticFeedback.lightImpact();
      } else {
        timer.cancel();
        _countdownTimer = null;
        setState(() => _isCountingDown = false);
        _startSession();
      }
    });
  }

  void _startSession() {
    // Cancel existing timer if any to prevent duplicates
    _timer?.cancel();

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _sessionDuration = Duration.zero;
      _isAudioPlaying = true; // Auto-start soundscape playback
    });

    _backgroundController.forward();
    HapticFeedback.heavyImpact();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _sessionDuration = Duration(seconds: _sessionDuration.inSeconds + 1);
        });
      }
    });
  }

  void _pauseSession() {
    setState(() => _isPaused = true);
    HapticFeedback.mediumImpact();
  }

  void _resumeSession() {
    setState(() => _isPaused = false);
    HapticFeedback.mediumImpact();
  }

  void _stopSession() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });

    HapticFeedback.heavyImpact();

    if (_sessionDuration.inSeconds > 10) {
      _showSessionCompletion();
    } else {
      _backgroundController.reverse();
      _resetSession();
    }
  }

  void _resetSession() {
    _timer?.cancel();
    _timer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;

    setState(() {
      _sessionDuration = Duration.zero;
      _isRunning = false;
      _isPaused = false;
    });
    _backgroundController.reset();
    HapticFeedback.lightImpact();

    // Reopen Session Setup modal after clearing state
    _showSessionSetup();
  }

  void _showSessionSetup() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => SessionSetupWidget(
        onSetupComplete: (temperature, location, mood, tempUnit) {
          Navigator.pop(context);
          _handleSetupComplete(temperature, location, mood, tempUnit);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _handleSetupComplete(
      double temperature, String location, int mood, String tempUnit) {
    // Temperature is already in Fahrenheit from session_setup_widget conversion
    setState(() {
      _temperature = temperature; // Already Fahrenheit - stored directly
      _tempUnit = tempUnit; // Store selected unit for display
      _location = location;
      _preMood = mood;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _startCountdown();
    });
  }

  void _showSessionCompletion() {
    _backgroundController.reverse();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => SessionCompletionWidget(
        duration: _sessionDuration.inSeconds,
        temperature: _temperature,
        tempUnit: _tempUnit,
        onSaveSession: (mood, notes) {
          Navigator.pop(context);
          _handleSessionComplete(mood, notes);
        },
        onDiscardSession: () {
          Navigator.pop(context);
          _resetSession();
        },
      ),
    );
  }

  void _handleSessionComplete(int mood, String notes) async {
    // Update state
    setState(() {
      _postMood = mood;
      _sessionNotes = notes;
    });

    // Save session and detect challenge completions
    await _saveSessionWithChallengeDetection();

    // Reset session state
    _timer?.cancel();
    _timer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;

    setState(() {
      _sessionDuration = Duration.zero;
      _isRunning = false;
      _isPaused = false;
    });
    _backgroundController.reset();

    // Navigate back to home dashboard
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeDashboard,
        (route) => false,
      );
    }
  }

  Future<void> _saveSessionWithChallengeDetection() async {
    try {
      // Validate and prepare session data
      final preMoodString = _getMoodString(_preMood);
      final postMoodString = _getMoodString(_postMood);

      if (!_validateMoodString(preMoodString) ||
          !_validateMoodString(postMoodString)) {
        print(
          'Invalid mood values detected: pre=$preMoodString, post=$postMoodString',
        );
        if (mounted) {
          _showErrorMessage('Invalid session data');
        }
        return;
      }

      final sessionData = {
        'location': _location,
        'duration': _sessionDuration.inSeconds,
        'temperature': _temperature.round(),
        'temp_unit': _tempUnit,
        'pre_mood': preMoodString,
        'post_mood': postMoodString,
        'notes': _sessionNotes.isEmpty ? null : _sessionNotes,
        'breathing_technique': _breathingTechnique,
      };

      // Save session to database first
      print('💾 DEBUG: Saving session to database...');
      await SessionService.instance
          .createSessionUltraOptimized(sessionData)
          .timeout(const Duration(seconds: 8));
      print('💾 DEBUG: Session saved successfully');

      // Update challenge progress only if challenges feature is enabled
      // This will trigger detection and emit events
      // The stream listener in main.dart will show the popup
      if (kEnableChallenges) {
        print('🎯 DEBUG: Calling updateUserChallengeProgress()...');
        await ChallengeService.instance.updateUserChallengeProgress();
        print('🎯 DEBUG: updateUserChallengeProgress() completed');
      }

      if (mounted) {
        // Show success message
        _showOptimisticSuccessMessage();
      }
    } catch (error) {
      print('Session save failed: $error');
      if (mounted) {
        _showErrorMessage(error);
      }
    }
  }

  // Convert 1-10 mood scale to database enum values
  // Maps numeric mood to closest semantic mood state
  String _getMoodString(int mood) {
    // Map 1-10 scale to mood enum values
    // 1-3: Low moods (stressed, anxious, tired)
    // 4-6: Neutral/calm moods
    // 7-10: High moods (energized, focused, euphoric)
    if (mood <= 2) {
      return 'stressed';
    } else if (mood <= 4) {
      return 'anxious';
    } else if (mood <= 6) {
      return 'neutral';
    } else if (mood <= 8) {
      return 'energized';
    } else {
      return 'euphoric';
    }
  }

  // Enhanced mood validation to ensure correct database storage
  bool _validateMoodString(String mood) {
    const validMoods = [
      'anxious',
      'neutral',
      'energized',
    ];
    return validMoods.contains(mood);
  }

  void _showErrorMessage(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 2.w),
            Expanded(child: Text('Save failed. Retrying...')),
          ],
        ),
        backgroundColor: AppTheme.errorLight, // Keep error red
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _saveSessionWithChallengeDetection(),
        ),
      ),
    );
  }

  void _showOptimisticSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 2.w),
            Text('Session completed! 🎉'),
          ],
        ),
        backgroundColor: const Color(0xFF14B8A6), // Success teal
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleAudio() {
    setState(() => _isAudioPlaying = !_isAudioPlaying);
    HapticFeedback.lightImpact();
  }

  void _changeTrack(String track) {
    setState(() => _currentTrack = track);
  }

  void _changeVolume(double volume) {
    setState(() => _audioVolume = volume);
  }

  void _toggleBreathingExercise() {
    setState(() => _isBreathingActive = !_isBreathingActive);
    HapticFeedback.mediumImpact();
  }

  void _closeBreathingExercise() {
    setState(() {
      _showBreathingExercise = false;
      _isBreathingActive = false;
    });
    HapticFeedback.lightImpact();
  }

  void _openBreathingExercise() {
    setState(() => _showBreathingExercise = true);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: _backgroundAnimation.value ?? colorScheme.surface,
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // Main content
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRoutes.homeDashboard,
                                  (route) => false,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface.withValues(
                                    alpha: 0.9,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.shadow.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CustomIconWidget(
                                  iconName: 'arrow_back_ios',
                                  color: colorScheme.onSurface,
                                  size: 20,
                                ),
                              ),
                            ),
                            Text(
                              'Cold Plunge Timer',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Transparent placeholder to balance the back button
                            SizedBox(
                              width: 44,
                              height: 44,
                            ),
                          ],
                        ),
                      ),

                      // Countdown overlay
                      if (_isCountingDown) ...[
                        Container(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height * 0.6,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Ready!',
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Container(
                                  width: 30.w,
                                  height: 30.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    border: Border.all(
                                      color: colorScheme.primary,
                                      width: 3,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$_countdownValue',
                                      style: theme.textTheme.displayLarge
                                          ?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Timer display
                        Container(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: Center(
                            child: TimerDisplayWidget(
                              duration: _sessionDuration,
                              isRunning: _isRunning,
                              isPaused: _isPaused,
                              onTap: _isRunning ? null : _showSessionSetup,
                            ),
                          ),
                        ),

                        // Breathing exercise toggle button (available pre-session and during session)
                        if (!_showBreathingExercise)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: TextButton.icon(
                              onPressed: _openBreathingExercise,
                              icon: Icon(
                                Icons.air,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              label: Text(
                                'Breathing Guide',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 1.h,
                                ),
                                backgroundColor:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                        // Breathing exercise (available pre-session and during session)
                        if (_showBreathingExercise)
                          BreathingExerciseWidget(
                            isActive: _isBreathingActive,
                            onToggle: _toggleBreathingExercise,
                            onClose: _closeBreathingExercise,
                          ),

                        // Audio controls
                        AudioControlsWidget(
                          isPlaying: _isAudioPlaying,
                          currentTrack: _currentTrack,
                          volume: _audioVolume,
                          onPlayPause: _toggleAudio,
                          onTrackChange: _changeTrack,
                          onVolumeChange: _changeVolume,
                        ),

                        // Timer controls
                        TimerControlsWidget(
                          isRunning: _isRunning,
                          isPaused: _isPaused,
                          onStart: _showSessionSetup,
                          onPause: _pauseSession,
                          onResume: _resumeSession,
                          onStop: _stopSession,
                          onReset: _resetSession,
                        ),

                        // Bottom safe area filler
                        Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).padding.bottom,
                          color: colorScheme.surface,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (_showCompletionWidget)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: SessionCompletionWidget(
                      duration: _completedDuration.inSeconds,
                      temperature: _temperature,
                      onSaveSession: (int mood, String notes) async {
                        try {
                          await SessionService.instance.saveSession(
                            duration: _completedDuration.inSeconds,
                            temperature: _temperature,
                            moodBefore: _getMoodString(_preMood),
                            moodAfter: _getMoodString(mood),
                            notes: notes,
                            location: _location,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Session saved successfully!')),
                            );
                            setState(() {
                              _showCompletionWidget = false;
                              _completedDuration = Duration.zero;
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error saving session: $e')),
                            );
                          }
                        }
                      },
                      onDiscardSession: () {
                        setState(() {
                          _showCompletionWidget = false;
                          _completedDuration = Duration.zero;
                        });
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
