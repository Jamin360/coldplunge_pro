import 'package:flutter/material.dart';
import 'dart:math'; // Add this import

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class GradientBackgroundWidget extends StatefulWidget {
  final Widget child;

  const GradientBackgroundWidget({
    super.key,
    required this.child,
  });

  @override
  State<GradientBackgroundWidget> createState() =>
      _GradientBackgroundWidgetState();
}

class _GradientBackgroundWidgetState extends State<GradientBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _waveController.repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primaryContainer,
            AppTheme.lightTheme.colorScheme.secondary,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          _buildWaveEffect(),
          SafeArea(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildWaveEffect() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: WavePainter(
              animationValue: _waveAnimation.value,
              color: AppTheme.lightTheme.colorScheme.surface
                  .withValues(alpha: 0.1),
            ),
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  WavePainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 30.0;
    final waveLength = size.width;

    path.moveTo(0, size.height * 0.7);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.7 +
          waveHeight *
              (sin((x / waveLength * 2 * pi) + (animationValue * 2 * pi)) *
                      0.5 +
                  0.5);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Second wave
    final path2 = Path();
    path2.moveTo(0, size.height * 0.8);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.8 +
          waveHeight *
              0.7 *
              (sin((x / waveLength * 2 * pi) + (animationValue * 2 * pi) + pi) *
                      0.5 +
                  0.5);
      path2.lineTo(x, y);
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}