import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/user_settings_service.dart';
import '../../services/feedback_service.dart';
import '../../services/data_prefetch_service.dart';
import '../../services/dashboard_repository.dart';
import '../../services/analytics_repository.dart';
import '../../services/persistent_cache_service.dart';
import '../../widgets/custom_app_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = UserSettingsService.instance;
  bool _isLoading = true;
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      await _settingsService.loadSettings();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: $error'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (error) {
      print('Failed to load app info: $error');
    }
  }

  Future<void> _handleSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorLight,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && mounted) {
      try {
        // Clear all cached data
        final persistentCache = PersistentCacheService();
        final dashboardRepo =
            DashboardRepository(persistentCacheService: persistentCache);
        final analyticsRepo =
            AnalyticsRepository(persistentCacheService: persistentCache);

        dashboardRepo.clearCache();
        analyticsRepo.clearCache();
        DataPrefetchService.instance.reset();

        await AuthService.instance.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.loginScreen,
            (route) => false,
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: $error'),
              backgroundColor: AppTheme.errorLight,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone.\n\n'
          'Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _settingsService.deleteAccount();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.loginScreen,
            (route) => false,
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: $error'),
              backgroundColor: AppTheme.errorLight,
            ),
          );
        }
      }
    }
  }

  void _handleExportSessions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export sessions - Coming soon')),
    );
  }

  void _handleSendFeedback() async {
    await FeedbackService.sendEmailFeedback(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Account',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: _settingsService,
              builder: (context, _) {
                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  children: [
                    // Profile Section
                    _buildSectionCard(
                      title: 'Profile',
                      children: [
                        _buildProfileRow(
                          value: _settingsService.displayName,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: const Color(0xFFE2E8F0),
                        ),
                        const SizedBox(height: 12),
                        _buildProfileRow(
                          value: _settingsService.email,
                          icon: Icons.email_outlined,
                        ),
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // Data & Privacy Section
                    _buildSectionCard(
                      title: 'Data & Privacy',
                      children: [
                        _buildActionRow(
                          label: 'Export Sessions',
                          icon: Icons.download_outlined,
                          onTap: _handleExportSessions,
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: const Color(0xFFE2E8F0),
                        ),
                        _buildActionRow(
                          label: 'Delete Account',
                          icon: Icons.delete_outline,
                          onTap: _handleDeleteAccount,
                          isDanger: true,
                        ),
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // Support Section
                    _buildSectionCard(
                      title: 'Support',
                      children: [
                        _buildActionRow(
                          label: 'Send Feedback',
                          icon: Icons.feedback_outlined,
                          onTap: _handleSendFeedback,
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: const Color(0xFFE2E8F0),
                        ),
                        _buildReadOnlyRow(
                          label: 'Version',
                          value: _appVersion.isNotEmpty
                              ? '$_appVersion ($_buildNumber)'
                              : 'Loading...',
                          icon: Icons.info_outline,
                        ),
                      ],
                    ),

                    SizedBox(height: 4.h),

                    // Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _handleSignOut,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.errorLight,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Sign Out',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.errorLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 4.h),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow({
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: const Color(0xFF1E3A5A)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
              ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: const Color(0xFF1E3A5A)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final color = isDanger ? AppTheme.errorLight : const Color(0xFF1E3A5A);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: color,
                    ),
              ),
            ),
            Icon(Icons.chevron_right, size: 24, color: const Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
