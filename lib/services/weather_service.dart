import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../core/env_config.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  static WeatherService get instance => _instance;

  String get _apiKey => EnvConfig.instance.get('GOOGLE_API_KEY');
  final String _baseUrl =
      'https://weather.googleapis.com/v1/currentConditions:lookup';

  Future<Map<String, dynamic>?> getCurrentWeather() async {
    try {
      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) {
        print('Failed to get current location');
        return null;
      }

      print('Got location: ${position.latitude}, ${position.longitude}');

      // Get location name
      final locationName = await _getLocationName(position);
      print('Location name: $locationName');

      // Fetch weather data from Google Weather API
      final weatherData = await _fetchWeatherData(position);
      if (weatherData == null) {
        print('Failed to fetch weather data');
        return null;
      }

      print('Raw weather data received: $weatherData');

      // Parse temperature - Google Weather API returns Celsius by default
      final tempCelsius = _extractTemperature(weatherData, 'temperature');
      final feelsLikeCelsius =
          _extractTemperature(weatherData, 'feelsLikeTemperature');
      final dewPointCelsius = _extractTemperature(weatherData, 'dewPoint');

      print(
          'Extracted temperatures - temp: $tempCelsius, feels like: $feelsLikeCelsius');

      if (tempCelsius == null) {
        print('Temperature extraction failed');
        return null;
      }

      // Parse the response data with safe defaults
      // Extract wind speed from nested structure
      double windSpeed = 0.0;
      if (weatherData.containsKey('wind')) {
        final wind = weatherData['wind'];
        if (wind is Map<String, dynamic>) {
          windSpeed = _extractValue(wind, 'speed') ?? 0.0;
        }
      }

      // Extract pressure from airPressure.meanSeaLevelMillibars
      double pressure = 1013.0;
      if (weatherData.containsKey('airPressure')) {
        final airPressure = weatherData['airPressure'];
        if (airPressure is Map<String, dynamic>) {
          pressure =
              _extractValue(airPressure, 'meanSeaLevelMillibars') ?? 1013.0;
        }
      }

      return {
        'temperature': tempCelsius,
        'feelsLike': feelsLikeCelsius ?? tempCelsius,
        'humidity': (weatherData['relativeHumidity'] as num?)?.toInt() ?? 50,
        'condition': _getWeatherCondition(weatherData),
        'location': locationName,
        'windSpeed': windSpeed,
        'pressure': pressure,
        'visibility': _extractValue(weatherData, 'visibility') ?? 10000.0,
        'uvIndex': (weatherData['uvIndex'] as num?)?.toInt() ?? 0,
        'dewPoint': dewPointCelsius ?? 10,
        'cloudCover': (weatherData['cloudCover'] as num?)?.toInt() ?? 0,
      };
    } catch (error) {
      print('Weather service error: $error');
      return _getFallbackWeather();
    }
  }

  int? _extractTemperature(Map<String, dynamic> data, String key) {
    try {
      print('Extracting temperature for key: $key');

      if (data.containsKey(key)) {
        final temp = data[key];
        print('Found $key: $temp (type: ${temp.runtimeType})');

        if (temp is Map<String, dynamic>) {
          // Google Weather API uses "degrees" instead of "value"
          final degrees = temp['degrees'] ?? temp['value'];
          print('Degrees/value: $degrees (type: ${degrees?.runtimeType})');
          if (degrees is num) {
            return degrees.round();
          }
        } else if (temp is num) {
          return temp.round();
        }
      }

      print('Failed to extract temperature for $key');
      return null;
    } catch (e) {
      print('Error extracting temperature for $key: $e');
      return null;
    }
  }

  double? _extractValue(Map<String, dynamic> data, String key) {
    try {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value is Map<String, dynamic>) {
          // Handle nested structure - try multiple field names
          final extracted = value['value'] ??
              value['degrees'] ??
              value['distance'] ??
              value['meanSeaLevelMillibars'];
          return (extracted as num?)?.toDouble();
        } else if (value is num) {
          return value.toDouble();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      print('=== STARTING LOCATION RETRIEVAL ===');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        print('ERROR: Location services are disabled');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('Current location permission: $permission');

      if (permission == LocationPermission.denied) {
        print('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          print('ERROR: Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('ERROR: Location permissions are permanently denied');
        return null;
      }

      print('Getting current position...');

      try {
        // Get current position with timeout
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('WARNING: Location timeout - using fallback location');
            // Return a default location (you can change this to your preferred location)
            // Using Mountain View, CA as an example
            return Position(
              latitude: 37.4219983,
              longitude: -122.084,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
          },
        );

        print('GPS COORDINATES RETRIEVED:');
        print('  Latitude: ${position.latitude}');
        print('  Longitude: ${position.longitude}');
        print('  Accuracy: ${position.accuracy}m');
        print('=== LOCATION RETRIEVAL COMPLETE ===');

        return position;
      } catch (positionError) {
        print('Error getting position: $positionError');
        print('WARNING: Using fallback location due to error');
        // Return a default location on error
        return Position(
          latitude: 37.4219983,
          longitude: -122.084,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    } catch (error) {
      print('Error in location retrieval process: $error');
      // Return fallback location instead of null
      print('WARNING: Using fallback location due to overall error');
      return Position(
        latitude: 37.4219983,
        longitude: -122.084,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  Future<String> _getLocationName(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;

        // Extract city with safer null handling - use non-nullable String
        String city = placemark.locality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea ??
            'Unknown Location';

        // Remove empty string check since we now have a guaranteed non-null value
        if (city.isEmpty) {
          city = 'Unknown Location';
        }

        // Extract state with null safety
        String state = placemark.administrativeArea ?? '';

        // Format location string - city is now guaranteed non-null
        if (state.isNotEmpty && city != state) {
          return '$city, $state';
        }
        return city;
      }
    } catch (error) {
      print('Error getting location name: $error');
    }
    return 'Current Location';
  }

  Future<Map<String, dynamic>?> _fetchWeatherData(Position position) async {
    print('=== STARTING WEATHER API CALL ===');

    print(
        'API Key check: ${_apiKey.isEmpty ? "EMPTY" : "Present (length: ${_apiKey.length})"}');

    if (_apiKey.isEmpty || _apiKey == 'your-google-api-key-here') {
      print(
        'ERROR: Google API key not configured. Please add GOOGLE_API_KEY to environment variables.',
      );
      return null;
    }

    try {
      print('Building API URL with coordinates:');
      print('  Latitude: ${position.latitude}');
      print('  Longitude: ${position.longitude}');

      final url = Uri.parse(
        '$_baseUrl?key=$_apiKey&location.latitude=${position.latitude}&location.longitude=${position.longitude}',
      );

      final urlForLogging =
          url.toString().replaceAll(_apiKey, 'API_KEY_HIDDEN');
      print('FULL API URL: $urlForLogging');

      print('Making HTTP GET request...');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print('Weather API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('SUCCESS: API returned 200');
        print('Response body length: ${response.body.length} characters');

        final data = json.decode(response.body);
        print('=== WEATHER API RESPONSE (PARSED) ===');
        print(json.encode(data));
        print('=== END API RESPONSE ===');

        // Google Weather API response structure:
        // {
        //   "date": {...},
        //   "expirationTime": "...",
        //   "regionalParameters": {...},
        //   "values": {
        //     "temperature": {"value": 20.5, "unit": "degreeCelsius"},
        //     "temperatureApparent": {"value": 18.3, "unit": "degreeCelsius"},
        //     "humidity": 65,
        //     "weatherCode": "partly_cloudy_day",
        //     ...
        //   }
        // }

        if (data is Map<String, dynamic>) {
          print('Response is a Map with keys: ${data.keys.toList()}');

          // Check if the response has a 'values' field
          if (data.containsKey('values')) {
            print('Found "values" field in response - extracting it');
            final values = data['values'] as Map<String, dynamic>;
            print('Values keys: ${values.keys.toList()}');
            return values;
          }
          // Otherwise return the whole data object
          print('No "values" field found - returning entire response');
          return data;
        }
        print('Response is not a Map - returning as-is');
        return data;
      } else {
        print('ERROR: Weather API returned status ${response.statusCode}');
        print('Error response body: ${response.body}');
        return null;
      }
    } catch (error) {
      print('Network error fetching weather: $error');
      return null;
    }
  }

  String _getWeatherCondition(Map<String, dynamic> weatherData) {
    // Google Weather API structure: {weatherCondition: {type: "CLOUDY", description: {...}}}
    String? weatherCode;

    if (weatherData.containsKey('weatherCondition')) {
      final condition = weatherData['weatherCondition'];
      if (condition is Map<String, dynamic>) {
        weatherCode = condition['type'] as String?;
      }
    }

    // Fallback to direct weatherCode field
    weatherCode ??= weatherData['weatherCode'] as String?;

    print('Weather code from API: $weatherCode');

    if (weatherCode == null || weatherCode.isEmpty) {
      return 'Partly Cloudy';
    }

    // Map weather codes to conditions
    // Google Weather API uses codes like: CLEAR, CLOUDY, PARTLY_CLOUDY_DAY, RAIN, SNOW, etc.
    final code = weatherCode.toUpperCase();

    if (code.contains('CLEAR')) {
      return 'Clear';
    } else if (code == 'CLOUDY') {
      return 'Cloudy';
    } else if (code.contains('PARTLY')) {
      return 'Partly Cloudy';
    } else if (code.contains('RAIN') || code.contains('DRIZZLE')) {
      return 'Rainy';
    } else if (code.contains('SNOW') || code.contains('SLEET')) {
      return 'Snowy';
    } else if (code.contains('THUNDER') || code.contains('STORM')) {
      return 'Stormy';
    } else if (code.contains('FOG') ||
        code.contains('HAZE') ||
        code.contains('MIST')) {
      return 'Foggy';
    } else if (code.contains('WIND')) {
      return 'Windy';
    }

    return 'Partly Cloudy';
  }

  Map<String, dynamic> _getFallbackWeather() {
    return {
      'temperature': 8,
      'feelsLike': 5,
      'humidity': 65,
      'condition': 'Cloudy',
      'location': 'Location Unavailable',
      'windSpeed': 5.2,
      'pressure': 1013,
      'visibility': 10000,
      'uvIndex': 0,
      'dewPoint': 10,
      'cloudCover': 20,
    };
  }

  Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (error) {
      return false;
    }
  }

  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (error) {
      return false;
    }
  }
}
