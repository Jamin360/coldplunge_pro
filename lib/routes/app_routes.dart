import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/signup_screen.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/plunge_timer/plunge_timer.dart';
import '../presentation/personal_analytics/personal_analytics.dart';
import '../presentation/challenges/challenges.dart';
import '../presentation/session_history/session_history.dart';
import '../presentation/challenge_progress/challenge_progress.dart';

class AppRoutes {
  // Route constants
  static const String splashScreen = '/splash';
  static const String loginScreen = '/login';
  static const String signUpScreen = '/signup';
  static const String homeDashboard = '/home';
  static const String plungeTimer = '/plunge-timer';
  static const String personalAnalytics = '/personal-analytics';
  static const String challenges = '/challenges';
  static const String sessionHistory = '/session-history';
  static const String challengeProgress = '/challenge-progress';

  // Initial route
  static const String initial = splashScreen;

  // Route map
  static Map<String, WidgetBuilder> get routes {
    return {
      splashScreen: (context) => const SplashScreen(),
      loginScreen: (context) => const LoginScreen(),
      signUpScreen: (context) => const SignUpScreen(),
      homeDashboard: (context) => const HomeDashboard(),
      plungeTimer: (context) => const PlungeTimer(),
      personalAnalytics: (context) => const PersonalAnalytics(),
      challenges: (context) => const Challenges(),
      sessionHistory: (context) => const SessionHistory(),
      challengeProgress: (context) => const ChallengeProgress(),
    };
  }
}
