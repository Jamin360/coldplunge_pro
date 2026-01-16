import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ProgressRingWidget extends StatelessWidget {
  final double progress;
  final String status;
  final String challengeTitle;

  const ProgressRingWidget({
    super.key,
    required this.progress,
    required this.status,
    required this.challengeTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Progress Ring
        SizedBox(
          width: 50.w,
          height: 50.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Circle
              CustomPaint(
                size: Size(50.w, 50.w),
                painter: _ProgressRingPainter(
                  progress: progress,
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                  progressColor: _getProgressColor(status, colorScheme),
                  strokeWidth: 12.0,
                ),
              ),

              // Center Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${progress.toInt()}%',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _getStatusText(status),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Challenge Title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            challengeTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'Completed':
        return AppTheme.successLight;
      case 'Failed':
        return AppTheme.errorLight;
      default:
        return colorScheme.primary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Completed':
        return 'COMPLETED';
      case 'Failed':
        return 'CHALLENGE ENDED';
      case 'Active':
        return 'IN PROGRESS';
      default:
        return status.toUpperCase();
    }
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          progressColor,
          progressColor.withValues(alpha: 0.6),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * (progress / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}
