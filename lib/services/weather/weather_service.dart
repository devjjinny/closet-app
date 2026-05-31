import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/weather_snapshot.dart';

class WeatherService {
  WeatherService({required this.apiKey, http.Client? httpClient})
    : _client = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _client;

  static const _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const _cacheKeyPrefix = 'weather_cache_';

  /// 현재 날씨 가져오기 (캐시 우선)
  Future<WeatherSnapshot> getCurrentWeather({
    required double lat,
    required double lon,
  }) async {
    final cacheKey = _buildCacheKey(lat, lon);

    // Try cache first
    final cached = await _getFromCache(cacheKey);
    if (cached != null) return cached;

    // Fetch from API
    try {
      final snapshot = await _fetchFromApi(lat, lon);
      await _saveToCache(cacheKey, snapshot);
      return snapshot;
    } catch (e) {
      // Fallback: try expired cache
      final expired = await _getFromCache(cacheKey, ignoreExpiry: true);
      if (expired != null) return expired;

      // Last resort: fallback data
      return WeatherSnapshot.fallback();
    }
  }

  Future<WeatherSnapshot> _fetchFromApi(double lat, double lon) async {
    if (apiKey.isEmpty) {
      throw StateError(
        'OPENWEATHER_API_KEY is not set. '
        'Run with --dart-define=OPENWEATHER_API_KEY=<key>.',
      );
    }

    final uri = Uri.parse(
      '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
    );

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Weather API error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseOpenWeatherResponse(json);
  }

  WeatherSnapshot _parseOpenWeatherResponse(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final rain = json['rain'] as Map<String, dynamic>?;
    final snow = json['snow'] as Map<String, dynamic>?;

    // OpenWeather doesn't directly give precipProb in current weather
    // We approximate based on condition
    final condition = weather['main'] as String;
    double precipProb = 0.0;
    if (['Rain', 'Drizzle', 'Thunderstorm'].contains(condition)) {
      precipProb = 0.8;
    } else if (condition == 'Snow') {
      precipProb = 0.8;
    } else if (condition == 'Clouds') {
      precipProb = 0.2;
    }

    return WeatherSnapshot(
      provider: 'openweather',
      temp: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      humidity: (main['humidity'] as num).toInt(),
      windSpeed: (wind['speed'] as num).toDouble(),
      precipProb: precipProb,
      condition: condition,
      rainMm: rain != null ? (rain['1h'] as num?)?.toDouble() : null,
      snowMm: snow != null ? (snow['1h'] as num?)?.toDouble() : null,
    );
  }

  String _buildCacheKey(double lat, double lon) {
    // Round to 2 decimal places (~1km accuracy)
    final roundedLat = (lat * 100).round() / 100;
    final roundedLon = (lon * 100).round() / 100;
    final date = DateTime.now().toIso8601String().split('T')[0];
    return '$_cacheKeyPrefix${roundedLat}_${roundedLon}_$date';
  }

  Future<WeatherSnapshot?> _getFromCache(
    String key, {
    bool ignoreExpiry = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    if (cached == null) return null;

    final data = jsonDecode(cached) as Map<String, dynamic>;
    final cachedAt = DateTime.parse(data['_cachedAt'] as String);

    if (!ignoreExpiry) {
      final age = DateTime.now().difference(cachedAt).inMinutes;
      if (age > AppConstants.weatherCacheTtlMinutes) return null;
    }

    data.remove('_cachedAt');
    return WeatherSnapshot.fromMap(data);
  }

  Future<void> _saveToCache(String key, WeatherSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final data = snapshot.toMap();
    data['_cachedAt'] = DateTime.now().toIso8601String();
    await prefs.setString(key, jsonEncode(data));
  }
}
