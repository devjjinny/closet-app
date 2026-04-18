import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:closet_app/services/weather/weather_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock SharedPreferences with empty data
    SharedPreferences.setMockInitialValues({});
  });

  group('WeatherService', () {
    test('OpenWeather API 응답을 올바르게 파싱한다', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'main': {
              'temp': 22.5,
              'feels_like': 21.0,
              'humidity': 65,
            },
            'wind': {'speed': 3.5},
            'weather': [
              {'main': 'Clear', 'description': 'clear sky'},
            ],
          }),
          200,
        );
      });

      final service = WeatherService(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final snapshot = await service.getCurrentWeather(lat: 37.56, lon: 126.97);

      expect(snapshot.temp, 22.5);
      expect(snapshot.feelsLike, 21.0);
      expect(snapshot.humidity, 65);
      expect(snapshot.windSpeed, 3.5);
      expect(snapshot.condition, 'Clear');
    });

    test('API 실패 시 fallback을 반환한다', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Error', 500);
      });

      final service = WeatherService(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final snapshot = await service.getCurrentWeather(lat: 37.56, lon: 126.97);

      // Should return fallback (no cache exists)
      expect(snapshot.provider, 'fallback');
      expect(snapshot.temp, 20.0);
    });
  });
}
