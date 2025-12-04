import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ExportOptionsWidget extends StatelessWidget {
  final VoidCallback? onExportPDF;
  final VoidCallback? onExportCSV;

  const ExportOptionsWidget({
    super.key,
    this.onExportPDF,
    this.onExportCSV,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'file_download',
                color: colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Data',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Download your analytics for external analysis',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 4.w),
          Row(
            children: [
              Expanded(
                child: _buildExportButton(
                  context: context,
                  title: 'PDF Report',
                  subtitle: 'Visual analytics',
                  icon: 'picture_as_pdf',
                  onTap: onExportPDF,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildExportButton(
                  context: context,
                  title: 'CSV Data',
                  subtitle: 'Raw session data',
                  icon: 'table_chart',
                  onTap: onExportCSV,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String icon,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: colorScheme.primary,
                size: 6.w,
              ),
            ),
            SizedBox(height: 2.w),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.w),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
