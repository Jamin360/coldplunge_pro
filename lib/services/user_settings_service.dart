import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user settings and preferences
class UserSettingsService extends ChangeNotifier {
  static UserSettingsService? _instance;
  static UserSettingsService get instance =>
      _instance ??= UserSettingsService._();

  UserSettingsService._();

  final SupabaseClient _client = Supabase.instance.client;

  // Settings cache
  String _temperatureUnit = 'F'; // 'F' or 'C'
  int _soundscapeVolume = 70; // 0-100
  bool _hapticsEnabled = true;
  String _displayName = '';
  String _email = '';

  // Getters
  String get temperatureUnit => _temperatureUnit;
  int get soundscapeVolume => _soundscapeVolume;
  bool get hapticsEnabled => _hapticsEnabled;
  String get displayName => _displayName;
  String get email => _email;

  /// Load user settings from Supabase
  Future<void> loadSettings() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get email from auth
      _email = currentUser.email ?? '';

      // Load profile data from user_profiles
      final response = await _client
          .from('user_profiles')
          .select('full_name, preferred_temperature')
          .eq('id', currentUser.id)
          .single();

      _displayName = response['full_name'] as String? ?? '';

      // Load temperature unit preference from database
      _temperatureUnit = response['temp_unit'] as String? ?? 'F';

      // Load soundscape volume and haptics settings
      _soundscapeVolume = response['soundscape_volume'] as int? ?? 70;
      _hapticsEnabled = response['haptics_enabled'] as bool? ?? true;

      notifyListeners();
    } catch (error) {
      print('Failed to load user settings: $error');
      // Use defaults on error
      _displayName = '';
      _soundscapeVolume = 70;
      _hapticsEnabled = true;
      _temperatureUnit = 'F';
    }
  }

  /// Update display name
  Future<void> updateDisplayName(String newName) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('user_profiles')
          .update({'full_name': newName}).eq('id', currentUser.id);

      _displayName = newName;
      notifyListeners();
    } catch (error) {
      throw Exception('Failed to update display name: $error');
    }
  }

  /// Update temperature unit preference
  Future<void> updateTemperatureUnit(String unit) async {
    if (unit != 'F' && unit != 'C') {
      throw ArgumentError('Temperature unit must be F or C');
    }

    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('user_profiles')
          .update({'temp_unit': unit}).eq('id', currentUser.id);

      _temperatureUnit = unit;
      notifyListeners();
    } catch (error) {
      throw Exception('Failed to update temperature unit: $error');
    }
  }

  /// Update soundscape volume
  Future<void> updateSoundscapeVolume(int volume) async {
    if (volume < 0 || volume > 100) {
      throw ArgumentError('Volume must be between 0 and 100');
    }

    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('user_profiles')
          .update({'soundscape_volume': volume}).eq('id', currentUser.id);

      _soundscapeVolume = volume;
      notifyListeners();
    } catch (error) {
      throw Exception('Failed to update soundscape volume: $error');
    }
  }

  /// Update haptics enabled
  Future<void> updateHapticsEnabled(bool enabled) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _client
          .from('user_profiles')
          .update({'haptics_enabled': enabled}).eq('id', currentUser.id);

      _hapticsEnabled = enabled;
      notifyListeners();
    } catch (error) {
      throw Exception('Failed to update haptics setting: $error');
    }
  }

  /// Delete user account (dangerous operation)
  Future<void> deleteAccount() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Delete user profile (cascade will handle related data)
      await _client.from('user_profiles').delete().eq('id', currentUser.id);

      // Sign out
      await _client.auth.signOut();
    } catch (error) {
      throw Exception('Failed to delete account: $error');
    }
  }
}
