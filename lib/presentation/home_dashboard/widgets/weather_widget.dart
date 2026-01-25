import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/weather_service.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isFahrenheit = true; // Default to Fahrenheit

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final weatherData = await WeatherService.instance.getCurrentWeather();
      setState(() {
        _weatherData = weatherData;
        _isLoading = false;
        _hasError = weatherData == null;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadWeatherData();
  }

  double _convertTemperature(int celsius) {
    return _isFahrenheit ? (celsius * 9 / 5) + 32 : celsius.toDouble();
  }

  String _getTemperatureUnit() {
    return _isFahrenheit ? '°F' : '°C';
  }

  void _toggleTemperatureUnit() {
    setState(() {
      _isFahrenheit = !_isFahrenheit;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return _buildLoadingWidget(theme, colorScheme);
    }

    if (_hasError || _weatherData == null) {
      return _buildErrorWidget(theme, colorScheme);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getWeatherColor(_weatherData!['condition'] as String)
                  .withValues(alpha: 0.1),
              _getWeatherColor(_weatherData!['condition'] as String)
                  .withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getWeatherColor(_weatherData!['condition'] as String)
                .withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weather Conditions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName:
                          _getWeatherIcon(_weatherData!['condition'] as String),
                      color: _getWeatherColor(
                          _weatherData!['condition'] as String),
                      size: 24,
                    ),
                    SizedBox(width: 2.w),
                    GestureDetector(
                      onTap: _toggleTemperatureUnit,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _isFahrenheit ? '°F' : '°C',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    GestureDetector(
                      onTap: _handleRefresh,
                      child: CustomIconWidget(
                        iconName: 'refresh',
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_convertTemperature(_weatherData!['temperature'] as int).toStringAsFixed(1)}${_getTemperatureUnit()}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                        ),
                      ),
                      Text(
                        _weatherData!['condition'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'location_on',
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Expanded(
                            child: Text(
                              _weatherData!['location'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildWeatherDetail(
                        context,
                        'Feels Like',
                        '${_convertTemperature(_weatherData!['feelsLike'] as int).toStringAsFixed(1)}${_getTemperatureUnit()}',
                        'thermostat',
                      ),
                      SizedBox(height: 1.h),
                      _buildWeatherDetail(
                        context,
                        'Humidity',
                        '${_weatherData!['humidity']}%',
                        'water_drop',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        width: double.infinity,
        height: 25.h,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Getting weather data...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.errorLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.errorLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'warning',
                  color: AppTheme.errorLight,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Weather Unavailable',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.errorLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Unable to fetch weather data. Check your location settings and internet connection.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: CustomIconWidget(
                  iconName: 'refresh',
                  color: Colors.white,
                  size: 16,
                ),
                label: Text(
                  'Retry',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(
      BuildContext context, String label, String value, String iconName) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: colorScheme.onSurfaceVariant,
          size: 16,
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  String _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return 'wb_sunny';
      case 'cloudy':
      case 'overcast':
      case 'partly cloudy':
        return 'cloud';
      case 'rainy':
      case 'rain':
        return 'umbrella';
      case 'snowy':
      case 'snow':
        return 'ac_unit';
      case 'windy':
        return 'air';
      case 'stormy':
        return 'thunderstorm';
      case 'foggy':
        return 'visibility_off';
      default:
        return 'wb_cloudy';
    }
  }

  Color _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return AppTheme.warningLight;
      case 'cloudy':
      case 'overcast':
      case 'partly cloudy':
        return AppTheme.primaryLight;
      case 'rainy':
      case 'rain':
        return AppTheme.secondaryLight;
      case 'snowy':
      case 'snow':
        return AppTheme.primaryLight;
      case 'windy':
        return AppTheme.secondaryLight;
      case 'stormy':
        return AppTheme.errorLight;
      case 'foggy':
        return AppTheme.primaryLight;
      default:
        return AppTheme.primaryLight;
    }
  }

  String _getPlungeRecommendation(int temperature) {
    if (temperature <= 5) {
      return 'Perfect for cold plunge! Extreme cold conditions.';
    } else if (temperature <= 15) {
      return 'Great conditions for outdoor plunge session.';
    } else if (temperature <= 25) {
      return 'Good weather for cold exposure therapy.';
    } else {
      return 'Consider indoor plunge or early morning session.';
    }
  }

  Color _getPlungeRecommendationColor(int temperature) {
    if (temperature <= 5) {
      return AppTheme.primaryLight;
    } else if (temperature <= 15) {
      return AppTheme.successLight;
    } else if (temperature <= 25) {
      return AppTheme.warningLight;
    } else {
      return AppTheme.errorLight;
    }
  }

  String _getPlungeRecommendationIcon(int temperature) {
    if (temperature <= 5) {
      return 'ac_unit';
    } else if (temperature <= 15) {
      return 'check_circle';
    } else if (temperature <= 25) {
      return 'info';
    } else {
      return 'warning';
    }
  }
}
