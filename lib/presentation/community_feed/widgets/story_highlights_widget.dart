import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StoryHighlightsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> highlights;
  final Function(Map<String, dynamic>)? onHighlightTap;

  const StoryHighlightsWidget({
    super.key,
    required this.highlights,
    this.onHighlightTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 25.h,
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Active Challenges & Highlights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: highlights.length,
              itemBuilder: (context, index) {
                final highlight = highlights[index];
                return _buildHighlightItem(
                    context, highlight, theme, colorScheme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(
    BuildContext context,
    Map<String, dynamic> highlight,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isChallenge = highlight['type'] == 'challenge';
    final isActive = highlight['isActive'] ?? false;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onHighlightTap?.call(highlight);
      },
      child: Container(
        width: 20.w,
        margin: EdgeInsets.only(right: 3.w),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isChallenge
                        ? LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: !isChallenge
                        ? Border.all(
                            color: colorScheme.outline,
                            width: 2,
                          )
                        : null,
                  ),
                  padding: EdgeInsets.all(isChallenge ? 3 : 2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isChallenge ? colorScheme.surface : null,
                    ),
                    child: ClipOval(
                      child: highlight['image'] != null
                          ? CustomImageWidget(
                              imageUrl: highlight['image'] as String,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              semanticLabel:
                                  highlight['imageSemanticLabel'] as String,
                            )
                          : Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Center(
                                child: CustomIconWidget(
                                  iconName:
                                      isChallenge ? 'emoji_events' : 'person',
                                  color: colorScheme.onSurfaceVariant,
                                  size: 8.w,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                if (isActive)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 5.w,
                      height: 5.w,
                      decoration: BoxDecoration(
                        color: AppTheme.successLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              highlight['title'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
