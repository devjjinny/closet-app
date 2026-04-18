import 'package:flutter_test/flutter_test.dart';
import 'package:closet_app/data/models/weather_snapshot.dart';

void main() {
  group('WeatherSnapshot', () {
    // Given-When-Then: 11
    test('requiredWarmthBudget가 체감온도 구간별로 올바르게 반환된다', () {
      // Given-When-Then
      expect(
        const WeatherSnapshot(
          provider: 'test', temp: 30, feelsLike: 30,
          humidity: 50, windSpeed: 5, precipProb: 0, condition: 'Clear',
        ).requiredWarmthBudget,
        1,
      );
      expect(
        const WeatherSnapshot(
          provider: 'test', temp: 22, feelsLike: 22,
          humidity: 50, windSpeed: 5, precipProb: 0, condition: 'Clear',
        ).requiredWarmthBudget,
        2,
      );
      expect(
        const WeatherSnapshot(
          provider: 'test', temp: 15, feelsLike: 15,
          humidity: 50, windSpeed: 5, precipProb: 0, condition: 'Clear',
        ).requiredWarmthBudget,
        3,
      );
      expect(
        const WeatherSnapshot(
          provider: 'test', temp: 8, feelsLike: 8,
          humidity: 50, windSpeed: 5, precipProb: 0, condition: 'Clear',
        ).requiredWarmthBudget,
        4,
      );
      expect(
        const WeatherSnapshot(
          provider: 'test', temp: 0, feelsLike: 0,
          humidity: 50, windSpeed: 5, precipProb: 0, condition: 'Clear',
        ).requiredWarmthBudget,
        5,
      );
    });

    // Given-When-Then: 12
    test('needsWaterproof가 강수확률 50% 이상에서 true를 반환한다', () {
      const rainy = WeatherSnapshot(
        provider: 'test', temp: 20, feelsLike: 20,
        humidity: 80, windSpeed: 5, precipProb: 0.6, condition: 'Rain',
      );
      expect(rainy.needsWaterproof, true);

      const clear = WeatherSnapshot(
        provider: 'test', temp: 20, feelsLike: 20,
        humidity: 50, windSpeed: 5, precipProb: 0.1, condition: 'Clear',
      );
      expect(clear.needsWaterproof, false);
    });

    // Given-When-Then: 13
    test('fromMap/toMap 직렬화 라운드트립이 동작한다', () {
      const original = WeatherSnapshot(
        provider: 'openweather',
        temp: 25.5,
        feelsLike: 27.0,
        humidity: 65,
        windSpeed: 3.2,
        precipProb: 0.3,
        condition: 'Clouds',
        rainMm: 1.5,
      );

      final map = original.toMap();
      final restored = WeatherSnapshot.fromMap(map);

      expect(restored.provider, original.provider);
      expect(restored.temp, original.temp);
      expect(restored.feelsLike, original.feelsLike);
      expect(restored.humidity, original.humidity);
      expect(restored.windSpeed, original.windSpeed);
      expect(restored.precipProb, original.precipProb);
      expect(restored.condition, original.condition);
      expect(restored.rainMm, original.rainMm);
    });

    // Given-When-Then: 14
    test('fallback가 합리적인 기본값을 반환한다', () {
      final fallback = WeatherSnapshot.fallback();
      expect(fallback.provider, 'fallback');
      expect(fallback.temp, 20.0);
      expect(fallback.condition, 'Clear');
      expect(fallback.precipProb, 0.0);
    });

    // Given-When-Then: 15
    test('눈이 올 때 isSnowy가 true를 반환한다', () {
      const snowy = WeatherSnapshot(
        provider: 'test', temp: -2, feelsLike: -5,
        humidity: 80, windSpeed: 5, precipProb: 0.8,
        condition: 'Snow', snowMm: 5.0,
      );
      expect(snowy.isSnowy, true);
      expect(snowy.needsWaterproof, true);
    });

    // Given-When-Then: 16
    test('temperatureBand가 8단계 경계값을 올바르게 반환한다', () {
      WeatherSnapshot w(double feels) => WeatherSnapshot(
            provider: 'test', temp: feels, feelsLike: feels,
            humidity: 50, windSpeed: 5, precipProb: 0, condition: 'Clear',
          );

      expect(w(30).temperatureBand, 1);  // 28°C 이상
      expect(w(28).temperatureBand, 1);  // 경계 포함
      expect(w(27).temperatureBand, 2);  // 23~27°C
      expect(w(23).temperatureBand, 2);  // 경계 포함
      expect(w(22).temperatureBand, 3);  // 20~22°C
      expect(w(20).temperatureBand, 3);  // 경계 포함
      expect(w(19).temperatureBand, 4);  // 17~19°C
      expect(w(17).temperatureBand, 4);  // 경계 포함
      expect(w(16).temperatureBand, 5);  // 12~16°C
      expect(w(12).temperatureBand, 5);  // 경계 포함
      expect(w(11).temperatureBand, 6);  // 9~11°C
      expect(w(9).temperatureBand, 6);   // 경계 포함
      expect(w(8).temperatureBand, 7);   // 5~8°C
      expect(w(5).temperatureBand, 7);   // 경계 포함
      expect(w(4).temperatureBand, 8);   // 4°C 이하
      expect(w(-10).temperatureBand, 8); // 극한 추위
    });
  });
}
