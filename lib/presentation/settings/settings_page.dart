import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/user_settings_service.dart';
import '../../widgets/custom_app_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsService = UserSettingsService.instance;
  final _nameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
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
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      await _settingsService.loadSettings();
      _nameController.text = _settingsService.displayName;
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

  Future<void> _saveDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _settingsService.updateDisplayName(newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update name: $error'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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

  void _handleSendFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Send feedback - Coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                        _buildEditableTextField(
                          label: 'Display Name',
                          controller: _nameController,
                          onSave: _saveDisplayName,
                          isSaving: _isSaving,
                        ),
                        const Divider(height: 1),
                        _buildReadOnlyRow(
                          label: 'Email',
                          value: _settingsService.email,
                          icon: Icons.email_outlined,
                        ),
                      ],
                    ),

                    SizedBox(height: 2.h),

                    // Preferences Section
                    _buildSectionCard(
                      title: 'Preferences',
                      children: [
                        _buildTemperatureUnitRow(),
                        const Divider(height: 1),
                        _buildVolumeSliderRow(),
                        const Divider(height: 1),
                        _buildHapticsSwitchRow(),
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
                        const Divider(height: 1),
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
                        const Divider(height: 1),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditableTextField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onSave,
    required bool isSaving,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 24, color: const Color(0xFF1E3A5A)),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
                SizedBox(height: 0.5.h),
                TextField(
                  controller: controller,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => onSave(),
                ),
              ],
            ),
          ),
          if (isSaving)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, size: 20),
              color: const Color(0xFF1E3A5A),
              onPressed: onSave,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF1E3A5A)),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
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
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            SizedBox(width: 3.w),
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

  Widget _buildTemperatureUnitRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: [
          Icon(
            Icons.thermostat_outlined,
            size: 24,
            color: const Color(0xFF1E3A5A),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'Temperature Unit',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTemperatureUnitButton('°F', 'F'),
                _buildTemperatureUnitButton('°C', 'C'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureUnitButton(String label, String value) {
    final isSelected = _settingsService.temperatureUnit == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _settingsService.updateTemperatureUnit(value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A5A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }

  Widget _buildVolumeSliderRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volume_up_outlined,
                size: 24,
                color: const Color(0xFF1E3A5A),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Soundscapes Volume',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Text(
                '${_settingsService.soundscapeVolume}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF1E3A5A),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: const Color(0xFF1E3A5A),
              overlayColor: const Color(0xFF1E3A5A).withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: _settingsService.soundscapeVolume.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (value) {
                _settingsService.updateSoundscapeVolume(value.toInt());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHapticsSwitchRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: [
          Icon(
            Icons.vibration_outlined,
            size: 24,
            color: const Color(0xFF1E3A5A),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              'Haptic Feedback',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Switch(
            value: _settingsService.hapticsEnabled,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              _settingsService.updateHapticsEnabled(value);
            },
            activeColor: const Color(0xFF1E3A5A),
          ),
        ],
      ),
    );
  }
}
