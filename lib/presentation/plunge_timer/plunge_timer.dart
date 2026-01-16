import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/session_service.dart';
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
  Duration _sessionDuration = Duration.zero;
  Duration _targetDuration = const Duration(minutes: 3);
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isCountingDown = false;
  int _countdownValue = 3;

  // Session data
  double _temperature = 15.0;
  String _location = 'Home Ice Bath';
  int _preMood = 2; // Default to Neutral
  int _postMood = 2; // Default to Neutral
  String _sessionNotes = '';
  String? _breathingTechnique;

  // UI state
  bool _showSetup = false;
  bool _showCompletion = false;
  bool _showBreathing = false;
  bool _isBreathingActive = false;
  bool _isSaving = false;
  bool _isSavingSession = false;
  bool _isSessionComplete = false;
  bool _showCompletionWidget = false;
  Duration _completedDuration = Duration.zero;

  // Audio state
  bool _isAudioPlaying = false;
  String _currentTrack = 'Ocean Waves';
  double _audioVolume = 0.7;

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
    setState(() {
      _isCountingDown = true;
      _countdownValue = 3;
    });

    HapticFeedback.mediumImpact();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 1) {
        setState(() => _countdownValue--);
        HapticFeedback.lightImpact();
      } else {
        timer.cancel();
        setState(() => _isCountingDown = false);
        _startSession();
      }
    });
  }

  void _startSession() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _sessionDuration = Duration.zero;
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

    _backgroundController.reverse();
    HapticFeedback.heavyImpact();

    if (_sessionDuration.inSeconds > 10) {
      _showSessionCompletion();
    } else {
      _resetSession();
    }
  }

  void _resetSession() {
    setState(() {
      _sessionDuration = Duration.zero;
      _isRunning = false;
      _isPaused = false;
    });
    HapticFeedback.lightImpact();
  }

  void _showSessionSetup() {
    setState(() => _showSetup = true);
    HapticFeedback.lightImpact();
  }

  void _hideSessionSetup() {
    setState(() => _showSetup = false);
  }

  void _handleSetupComplete(double temperature, String location, int mood) {
    // Temperature is already in Fahrenheit from session_setup_widget conversion
    setState(() {
      _temperature = temperature; // Already Fahrenheit - stored directly
      _location = location;
      _preMood = mood;
      _showSetup = false;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _startCountdown();
    });
  }

  void _showSessionCompletion() {
    setState(() => _showCompletion = true);
  }

  void _handleSessionComplete(int mood, String notes) async {
    // Optimistic UI update - close modal immediately
    setState(() => _showCompletion = false);

    // Update state optimistically
    setState(() {
      _postMood = mood;
      _sessionNotes = notes;
      _isSaving = false; // Don't show loading - use optimistic pattern
    });

    // Perform background save without blocking UI
    _saveSessionOptimistically();

    // Show immediate success and reset
    _showOptimisticSuccessMessage();
    _resetSession();
  }

  // Cached mood conversion for better performance
  String _getMoodString(int mood) {
    switch (mood) {
      case 1:
        return 'anxious';
      case 2:
        return 'neutral';
      case 3:
        return 'energized';
      default:
        return 'neutral';
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

  // Ultra-fast optimistic save with background processing
  Future<void> _saveSessionOptimistically() async {
    try {
      // Convert mood integers to mood enum strings (cached for performance)
      final preMoodString = _getMoodString(_preMood);
      final postMoodString = _getMoodString(_postMood);

      // Validate mood strings before sending to database
      if (!_validateMoodString(preMoodString) ||
          !_validateMoodString(postMoodString)) {
        print(
          'Invalid mood values detected: pre=$preMoodString, post=$postMoodString',
        );
        return;
      }

      // CRITICAL: Temperature is stored in Fahrenheit in database
      // _temperature already contains Fahrenheit value from session setup conversion
      final sessionData = {
        'location': _location,
        'duration': _sessionDuration.inSeconds,
        'temperature': _temperature.round(), // Already Fahrenheit
        'pre_mood': preMoodString,
        'post_mood': postMoodString,
        'notes': _sessionNotes.isEmpty ? null : _sessionNotes,
        'breathing_technique': _breathingTechnique,
      };

      // Add debug logging for temperature storage
      print(
        'Saving session with temperature: ${_temperature.round()}°F',
      );

      // Non-blocking background save - don't await
      SessionService.instance.saveSessionInBackground(sessionData);
    } catch (error) {
      // Silent fail for optimistic pattern - could implement retry queue
      print('Optimistic save failed: $error');
    }
  }

  // Optimized session saving with timeout and better error handling
  Future<void> _saveSessionDataOptimized() async {
    const saveTimeout = Duration(seconds: 8); // Reduced timeout

    try {
      // Convert mood integers to mood enum strings (cached for performance)
      final preMoodString = _getMoodString(_preMood);
      final postMoodString = _getMoodString(_postMood);

      // Validate mood strings before sending to database
      if (!_validateMoodString(preMoodString) ||
          !_validateMoodString(postMoodString)) {
        throw Exception(
          'Invalid mood values: pre=$preMoodString, post=$postMoodString',
        );
      }

      // CRITICAL: Temperature is stored in Fahrenheit in database
      // _temperature already contains Fahrenheit value from session setup conversion
      final sessionData = {
        'location': _location,
        'duration': _sessionDuration.inSeconds,
        'temperature': _temperature.round(), // Already Fahrenheit
        'pre_mood': preMoodString,
        'post_mood': postMoodString,
        'notes': _sessionNotes.isEmpty ? null : _sessionNotes,
        'breathing_technique': _breathingTechnique,
      };

      // Add debug logging for temperature storage
      print(
        'Saving session with temperature: ${_temperature.round()}°F',
      );

      // Save with ultra-optimized method and timeout
      await SessionService.instance
          .createSessionUltraOptimized(sessionData)
          .timeout(saveTimeout);

      if (mounted) {
        // Single setState for success state
        setState(() => _isSaving = false);

        _showSuccessMessage();
        _resetSession();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorMessage(error);
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 2.w),
            Text('Session saved! 🎉'),
          ],
        ),
        backgroundColor: const Color(0xFF14B8A6), // Success teal
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
          onPressed: () => _saveSessionDataOptimized(),
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

  void _toggleBreathing() {
    setState(() {
      _showBreathing = !_showBreathing;
      if (_showBreathing) {
        _isBreathingActive = true;
        _breathingTechnique =
            'Wim Hof Method'; // Set breathing technique when activated
      } else {
        _breathingTechnique = null;
      }
    });
  }

  void _toggleBreathingActive() {
    setState(() => _isBreathingActive = !_isBreathingActive);
  }

  void _closeBreathing() {
    setState(() {
      _showBreathing = false;
      _isBreathingActive = false;
      _breathingTechnique = null;
    });
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

  Future<void> _saveSession() async {
    setState(() => _isSavingSession = true);

    try {
      await SessionService.instance.saveSession(
        duration: _completedDuration.inSeconds,
        temperature: _temperature,
        moodBefore: _getMoodString(_preMood),
        moodAfter: _getMoodString(_postMood),
        notes: _sessionNotes,
        location: _location,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session saved successfully!')),
        );
        setState(() {
          _isSessionComplete = false;
          _showCompletionWidget = false;
          _completedDuration = Duration.zero;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving session: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingSession = false);
      }
    }
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
                child: Column(
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
                          GestureDetector(
                            onTap: _toggleBreathing,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _showBreathing
                                    ? colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      )
                                    : colorScheme.surface.withValues(
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
                                iconName: 'air',
                                color: _showBreathing
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Countdown overlay
                    if (_isCountingDown) ...[
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Ready!',
                                style: theme.textTheme.headlineMedium?.copyWith(
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
                                    style:
                                        theme.textTheme.displayLarge?.copyWith(
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
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: TimerDisplayWidget(
                            duration: _sessionDuration,
                            isRunning: _isRunning,
                            isPaused: _isPaused,
                            onTap: _isRunning ? null : _showSessionSetup,
                          ),
                        ),
                      ),

                      // Breathing exercise
                      if (_showBreathing)
                        BreathingExerciseWidget(
                          isActive: _isBreathingActive,
                          onToggle: _toggleBreathingActive,
                          onClose: _closeBreathing,
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
                    ],
                  ],
                ),
              ),

              // Session setup modal
              if (_showSetup)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SessionSetupWidget(
                        onSetupComplete: _handleSetupComplete,
                        onCancel: _hideSessionSetup,
                      ),
                    ),
                  ),
                ),

              // Session completion modal
              if (_showCompletion)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SessionCompletionWidget(
                        duration: _sessionDuration.inSeconds,
                        temperature: _temperature,
                        onSaveSession: _handleSessionComplete,
                        onDiscardSession: () {
                          setState(() => _showCompletion = false);
                          _resetSession();
                        },
                      ),
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
                        setState(() => _isSavingSession = true);

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
                              _isSessionComplete = false;
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
                        } finally {
                          if (mounted) {
                            setState(() => _isSavingSession = false);
                          }
                        }
                      },
                      onDiscardSession: () {
                        setState(() {
                          _isSessionComplete = false;
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
