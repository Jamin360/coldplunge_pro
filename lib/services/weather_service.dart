import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  static WeatherService get instance => _instance;

  final String _apiKey = const String.fromEnvironment('GOOGLE_API_KEY');
  final String _baseUrl =
      'https://weather.googleapis.com/v1/currentConditions:lookup';

  Future<Map<String, dynamic>?> getCurrentWeather() async {
    try {
      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) return null;

      // Get location name
      final locationName = await _getLocationName(position);

      // Fetch weather data from Google Weather API
      final weatherData = await _fetchWeatherData(position);
      if (weatherData == null) return null;

      return {
        'temperature': (weatherData['temperature']['degrees'] as num).round(),
        'feelsLike':
            (weatherData['feelsLikeTemperature']['degrees'] as num).round(),
        'humidity': weatherData['relativeHumidity'],
        'condition': _getWeatherCondition(weatherData['weatherCondition']),
        'location': locationName,
        'windSpeed': weatherData['wind']['speed']['value'],
        'pressure': weatherData['airPressure']['meanSeaLevelMillibars'],
        'visibility': weatherData['visibility']['distance'] *
            1000, // Convert km to meters
        'uvIndex': weatherData['uvIndex'] ?? 0,
        'dewPoint': (weatherData['dewPoint']['degrees'] as num).round(),
        'cloudCover': weatherData['cloudCover'] ?? 0,
      };
    } catch (error) {
      print('Weather service error: $error');
      return _getFallbackWeather();
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (error) {
      print('Error getting location: $error');
      return null;
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
    if (_apiKey.isEmpty || _apiKey == 'your-google-api-key-here') {
      print(
        'Google API key not configured. Please add GOOGLE_API_KEY to environment variables.',
      );
      return null;
    }

    try {
      final url = Uri.parse(
        '$_baseUrl?key=$_apiKey&location.latitude=${position.latitude}&location.longitude=${position.longitude}&unitsSystem=METRIC',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Weather API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (error) {
      print('Network error fetching weather: $error');
      return null;
    }
  }

  String _getWeatherCondition(Map<String, dynamic> weatherCondition) {
    final description = weatherCondition['description']['text'] as String?;
    final type = weatherCondition['type'] as String?;

    if (description != null) {
      return description;
    }

    // Fallback to type-based condition mapping
    switch (type?.toUpperCase()) {
      case 'CLEAR':
        return 'Sunny';
      case 'CLOUDY':
      case 'PARTLY_CLOUDY':
        return 'Cloudy';
      case 'RAIN':
      case 'DRIZZLE':
        return 'Rainy';
      case 'SNOW':
        return 'Snowy';
      case 'THUNDERSTORM':
        return 'Stormy';
      case 'FOG':
      case 'HAZE':
        return 'Foggy';
      default:
        return 'Partly Cloudy';
    }
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
