import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class SessionSetupWidget extends StatefulWidget {
  final Function(double temperature, String location, int mood, String tempUnit)
      onSetupComplete;
  final VoidCallback onCancel;

  const SessionSetupWidget({
    super.key,
    required this.onSetupComplete,
    required this.onCancel,
  });

  @override
  State<SessionSetupWidget> createState() => _SessionSetupWidgetState();
}

class _SessionSetupWidgetState extends State<SessionSetupWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isCelsius = false;
  int _selectedMood = 2; // Default to Neutral

  final List<Map<String, dynamic>> _moodOptions = [
    {'emoji': '😰', 'label': 'Anxious', 'value': 1},
    {'emoji': '😐', 'label': 'Neutral', 'value': 2},
    {'emoji': '⚡', 'label': 'Energized', 'value': 3},
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();
    _temperatureController.text = '59';
    _locationController.text = 'Home Ice Bath';
  }

  @override
  void dispose() {
    _slideController.dispose();
    _temperatureController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _toggleTemperatureUnit(bool switchToCelsius) {
    // Get current temperature value
    final currentTemp = double.tryParse(_temperatureController.text);

    if (currentTemp == null) {
      // If no valid value, just toggle the unit
      setState(() => _isCelsius = switchToCelsius);
      return;
    }

    // Convert temperature based on current unit and desired unit
    double convertedTemp;
    if (switchToCelsius && !_isCelsius) {
      // Converting from °F to °C
      convertedTemp = (currentTemp - 32) * 5 / 9;
    } else if (!switchToCelsius && _isCelsius) {
      // Converting from °C to °F
      convertedTemp = (currentTemp * 9 / 5) + 32;
    } else {
      // Already in the desired unit, no conversion needed
      return;
    }

    // Update state and text controller with converted value (rounded to whole degrees)
    setState(() {
      _isCelsius = switchToCelsius;
      _temperatureController.text = convertedTemp.round().toString();
    });

    HapticFeedback.lightImpact();
  }

  void _handleSetupComplete() {
    final temperature = double.tryParse(_temperatureController.text) ?? 59.0;
    // CRITICAL: Always convert to Fahrenheit for Supabase database storage
    // Database stores all temperatures in Fahrenheit regardless of user input unit
    final temperatureInFahrenheit =
        _isCelsius ? (temperature * 9 / 5) + 32 : temperature;

    HapticFeedback.mediumImpact();
    widget.onSetupComplete(
      temperatureInFahrenheit,
      _locationController.text,
      _selectedMood,
      _isCelsius ? 'C' : 'F', // Pass selected unit
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 32 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Session Setup',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Configure your cold plunge session',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4.h),

            // Temperature input
            Text(
              'Water Temperature',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _temperatureController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter temperature',
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _toggleTemperatureUnit(true),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: _isCelsius
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '°C',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: _isCelsius
                                        ? colorScheme.onPrimary
                                        : colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _toggleTemperatureUnit(false),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 1.h,
                                ),
                                decoration: BoxDecoration(
                                  color: !_isCelsius
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '°F',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: !_isCelsius
                                        ? colorScheme.onPrimary
                                        : colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Location input
            Text(
              'Location',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Enter location',
              ),
            ),
            SizedBox(height: 3.h),

            // Pre-plunge mood
            Text(
              'Pre-Plunge Mood',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _moodOptions.map((mood) {
                final isSelected = _selectedMood == mood['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedMood = mood['value']);
                    HapticFeedback.lightImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          mood['emoji'],
                          style: TextStyle(fontSize: 20.sp),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          mood['label'],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 4.h),

            // Full-width Start Session button with increased height
            SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton(
                onPressed: _handleSetupComplete,
                child: Text('Start Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
