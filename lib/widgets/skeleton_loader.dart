import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Skeleton loader widget for displaying loading states
/// Provides a shimmer effect for better UX during data fetching
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loader for dashboard metric cards
class SkeletonMetricCard extends StatelessWidget {
  const SkeletonMetricCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: 12.w,
            height: 12.w,
            borderRadius: BorderRadius.circular(8),
          ),
          SizedBox(height: 2.h),
          SkeletonLoader(
            width: 20.w,
            height: 2.h,
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(height: 1.h),
          SkeletonLoader(
            width: 15.w,
            height: 3.h,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for session list items
class SkeletonSessionCard extends StatelessWidget {
  const SkeletonSessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SkeletonLoader(
            width: 15.w,
            height: 15.w,
            borderRadius: BorderRadius.circular(12),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 40.w,
                  height: 2.h,
                  borderRadius: BorderRadius.circular(4),
                ),
                SizedBox(height: 1.h),
                SkeletonLoader(
                  width: 30.w,
                  height: 1.5.h,
                  borderRadius: BorderRadius.circular(4),
                ),
                SizedBox(height: 0.5.h),
                SkeletonLoader(
                  width: 25.w,
                  height: 1.5.h,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for analytics table
class SkeletonAnalyticsTable extends StatelessWidget {
  final int rowCount;

  const SkeletonAnalyticsTable({
    super.key,
    this.rowCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonLoader(
                width: 25.w,
                height: 2.h,
                borderRadius: BorderRadius.circular(4),
              ),
              SkeletonLoader(
                width: 20.w,
                height: 2.h,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Rows
          ...List.generate(
            rowCount,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonLoader(
                    width: 30.w,
                    height: 1.8.h,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SkeletonLoader(
                    width: 15.w,
                    height: 1.8.h,
                    borderRadius: BorderRadius.circular(4),
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

/// Skeleton loader for chart widget
class SkeletonChart extends StatelessWidget {
  const SkeletonChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: 40.w,
            height: 2.h,
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              7,
              (index) => SkeletonLoader(
                width: 8.w,
                height: (10 + (index % 3) * 5).h,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              7,
              (index) => SkeletonLoader(
                width: 8.w,
                height: 1.5.h,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for streak counter
class SkeletonStreakCounter extends StatelessWidget {
  const SkeletonStreakCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SkeletonLoader(
            width: 20.w,
            height: 20.w,
            borderRadius: BorderRadius.circular(100),
          ),
          SizedBox(height: 2.h),
          SkeletonLoader(
            width: 30.w,
            height: 2.h,
            borderRadius: BorderRadius.circular(4),
          ),
          SizedBox(height: 1.h),
          SkeletonLoader(
            width: 40.w,
            height: 1.5.h,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
