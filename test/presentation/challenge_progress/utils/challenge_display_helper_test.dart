import 'package:flutter_test/flutter_test.dart';
import 'package:coldplunge_pro/presentation/challenge_progress/utils/challenge_display_helper.dart';

void main() {
  group('ChallengeDisplayHelper', () {
    group('Extreme Cold Challenge (streak with temperature condition)', () {
      test('displays days with temperature condition at 0% progress', () {
        final metadata = ChallengeDisplayHelper.getProgressDisplay(
          challengeTitle: 'Extreme Cold Challenge',
          challengeType: 'temperature',
          targetValue: 10, // 10°C
          durationDays: 14,
          currentProgress: 0.0,
        );

        expect(metadata.currentText, '0');
        expect(metadata.goalText, '14');
        expect(metadata.unitLabel, 'Days');
        expect(metadata.subLabel, contains('50°F'));
        expect(metadata.subLabel, contains('10°C'));
        expect(metadata.subLabel, contains('<'));
        expect(metadata.subLabel, isNot(contains('≤'))); // Must NOT contain ≤
      });

      test('displays days with temperature condition at 50% progress', () {
        final metadata = ChallengeDisplayHelper.getProgressDisplay(
          challengeTitle: 'Extreme Cold Challenge',
          challengeType: 'temperature',
          targetValue: 10, // 10°C
          durationDays: 14,
          currentProgress: 50.0,
        );

        expect(metadata.currentText, '7');
        expect(metadata.goalText, '14');
        expect(metadata.unitLabel, 'Days');
        expect(metadata.subLabel, '< 50°F (10°C)');
      });

      test('displays days with temperature condition at 100% progress', () {
        final metadata = ChallengeDisplayHelper.getProgressDisplay(
          challengeTitle: 'Extreme Cold Challenge',
          challengeType: 'temperature',
          targetValue: 10, // 10°C
          durationDays: 14,
          currentProgress: 100.0,
        );

        expect(metadata.currentText, '14');
        expect(metadata.goalText, '14');
        expect(metadata.unitLabel, 'Days');
        expect(metadata.subLabel, '< 50°F (10°C)');
      });
    });

    group('Regular streak challenge', () {
      test('Ice Warrior displays consecutive days', () {
        final metadata = ChallengeDisplayHelper.getProgressDisplay(
          challengeTitle: 'Ice Warrior – 7 Day Streak',
          challengeType: 'streak',
          targetValue: 7,
          durationDays: 7,
          currentProgress: 42.85, // ~3 days
        );

        expect(metadata.currentText, '3');
        expect(metadata.goalText, '7');
        expect(metadata.unitLabel, 'Days');
        expect(metadata.subLabel, 'Consecutive days');
      });
    });

    group('Duration challenge', () {
      test('Two-Minute Club displays seconds with minute conversion', () {
        final metadata = ChallengeDisplayHelper.getProgressDisplay(
          challengeTitle: 'Two-Minute Club',
          challengeType: 'duration',
          targetValue: 120, // 2 minutes
          durationDays: 30,
          currentProgress: 0.0,
        );

        expect(metadata.currentText, '0');
        expect(metadata.goalText, '120');
        expect(metadata.unitLabel, 'Seconds');
        expect(metadata.subLabel, contains('2m'));
        expect(metadata.subLabel, contains('Single session'));
      });
    });

    group('Temperature session count challenge', () {
      test('Ice Breaker displays sessions with temperature condition', () {
        final metadata = ChallengeDisplayHelper.getProgressDisplay(
          challengeTitle: 'Ice Breaker',
          challengeType: 'temperature',
          targetValue: 12, // 12°C
          durationDays: 30,
          currentProgress: 25.0, // 3 sessions (25% of 12 = 3)
        );

        expect(metadata.currentText, '3');
        expect(metadata.goalText, '10');
        expect(metadata.unitLabel, 'Sessions');
        expect(metadata.subLabel, contains('54°F'));
        expect(metadata.subLabel, contains('12°C'));
      });
    });

    group('Consistency challenge', () {
      test('Quick Start displays session count', () {
        final metadata = ChallengeDisplayHelper.getProgressDisplay(
          challengeTitle: 'Quick Start',
          challengeType: 'consistency',
          targetValue: 5,
          durationDays: 7,
          currentProgress: 60.0, // 3 sessions
        );

        expect(metadata.currentText, '3');
        expect(metadata.goalText, '5');
        expect(metadata.unitLabel, 'Sessions');
        expect(metadata.subLabel, 'Total sessions');
      });
    });

    group('Temperature conversion', () {
      test('converts 10°C to 50°F correctly', () {
        final metadata = ChallengeDisplayHelper.getProgressDisplay(
          challengeTitle: 'Extreme Cold Challenge',
          challengeType: 'temperature',
          targetValue: 10,
          durationDays: 14,
          currentProgress: 0.0,
        );

        expect(metadata.subLabel, '< 50°F (10°C)');
      });

      test('converts 12°C to 54°F correctly', () {
        final metadata = ChallengeDisplayHelper.getProgressDisplay(
          challengeTitle: 'Ice Breaker',
          challengeType: 'temperature',
          targetValue: 12,
          durationDays: 30,
          currentProgress: 0.0,
        );

        expect(metadata.subLabel, contains('54°F'));
        expect(metadata.subLabel, contains('12°C'));
      });

      test('formatTemperatureCondition always uses strict less-than symbol',
          () {
        final condition10C =
            ChallengeDisplayHelper.formatTemperatureCondition(10);
        final condition12C =
            ChallengeDisplayHelper.formatTemperatureCondition(12);
        final condition0C =
            ChallengeDisplayHelper.formatTemperatureCondition(0);

        // Must use "<" (strict less-than)
        expect(condition10C, '< 50°F (10°C)');
        expect(condition12C, '< 54°F (12°C)');
        expect(condition0C, '< 32°F (0°C)');

        // Must NOT use "≤" (less-than-or-equal)
        expect(condition10C, isNot(contains('≤')));
        expect(condition12C, isNot(contains('≤')));
        expect(condition0C, isNot(contains('≤')));
      });
    });
  });
}
