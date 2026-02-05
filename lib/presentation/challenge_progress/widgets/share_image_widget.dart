import 'dart:math' show cos, sin, pi;
import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Widget designed to be captured as a shareable image
class ShareImageWidget extends StatelessWidget {
  final String challengeTitle;
  final double progress;
  final String currentValue;
  final String targetValue;
  final String daysRemaining;
  final String difficulty;
  final String challengeType;

  const ShareImageWidget({
    super.key,
    required this.challengeTitle,
    required this.progress,
    required this.currentValue,
    required this.targetValue,
    required this.daysRemaining,
    required this.difficulty,
    required this.challengeType,
  });

  IconData _getChallengeIcon() {
    switch (challengeType.toLowerCase()) {
      case 'consistency':
      case 'streak':
        return Icons.local_fire_department;
      case 'cold_tolerance':
      case 'temperature':
        return Icons.ac_unit;
      case 'duration':
      case 'time':
        return Icons.timer;
      case 'frequency':
        return Icons.calendar_today;
      case 'milestone':
        return Icons.emoji_events;
      default:
        return Icons.stars;
    }
  }

  Color _getIconColor() {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.successLight;
      case 'medium':
        return AppTheme.warningLight;
      case 'hard':
        return AppTheme.errorLight;
      default:
        return AppTheme.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1080,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A237E), // Navy blue
            const Color(0xFF283593),
            const Color(0xFF303F9F),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern (snowflakes)
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                painter: _SnowflakePainter(),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header - App Branding
                Column(
                  children: [
                    // Snowflake icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.ac_unit,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ColdPlunge Pro',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),

                // Middle - Challenge Info
                Column(
                  children: [
                    // Challenge Type Icon
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: _getIconColor().withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getIconColor(),
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        _getChallengeIcon(),
                        size: 80,
                        color: _getIconColor(),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Challenge Title
                    Text(
                      challengeTitle,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Progress Circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: CircularProgressIndicator(
                            value: progress / 100,
                            strokeWidth: 20,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.secondaryLight,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${progress.toInt()}%',
                              style: const TextStyle(
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Complete',
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          'Current',
                          currentValue,
                          Icons.trending_up,
                        ),
                        _buildStatCard(
                          'Goal',
                          targetValue,
                          Icons.flag,
                        ),
                        _buildStatCard(
                          'Time',
                          daysRemaining,
                          Icons.schedule,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Difficulty Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: _getIconColor().withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _getIconColor(),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        difficulty.toUpperCase(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _getIconColor(),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),

                // Footer - Motivational Message
                Column(
                  children: [
                    const Text(
                      'Join me on my cold plunge journey!',
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        'Download ColdPlunge Pro',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: AppTheme.secondaryLight,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for snowflake background pattern
class _SnowflakePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw multiple snowflakes
    for (var i = 0; i < 15; i++) {
      final x = (i * 200.0 + 50) % size.width;
      final y = (i * 150.0 + 50) % size.height;
      _drawSnowflake(canvas, Offset(x, y), 30, paint);
    }
  }

  void _drawSnowflake(
      Canvas canvas, Offset center, double radius, Paint paint) {
    // Draw 6 arms of the snowflake
    for (var i = 0; i < 6; i++) {
      final angle = i * 60 * (pi / 180);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), paint);

      // Draw small branches
      final branchLength = radius * 0.3;
      for (var j = 1; j <= 2; j++) {
        final branchDist = radius * 0.4 * j;
        final branchX = center.dx + branchDist * cos(angle);
        final branchY = center.dy + branchDist * sin(angle);

        final branch1X = branchX + branchLength * cos(angle + 0.5);
        final branch1Y = branchY + branchLength * sin(angle + 0.5);
        canvas.drawLine(
            Offset(branchX, branchY), Offset(branch1X, branch1Y), paint);

        final branch2X = branchX + branchLength * cos(angle - 0.5);
        final branch2Y = branchY + branchLength * sin(angle - 0.5);
        canvas.drawLine(
            Offset(branchX, branchY), Offset(branch2X, branch2Y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
