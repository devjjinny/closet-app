import 'package:closet_app/core/constants/enums.dart';
import 'package:closet_app/data/models/outfit_model.dart';
import 'package:closet_app/data/models/weather_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WeatherSnapshot _weather() => const WeatherSnapshot(
        provider: 'openweather',
        temp: 18.0,
        feelsLike: 17.0,
        humidity: 50,
        condition: 'Clear',
        windSpeed: 2.0,
        precipProb: 0.0,
      );

  OutfitModel _base() => OutfitModel(
        id: 'o001',
        dateKey: '2026-04-18',
        items: ['g1', 'g2', 'g3'],
        weatherSnapshot: _weather(),
        createdAt: DateTime(2026, 4, 18),
      );

  group('OutfitModel.toRow', () {
    test('includes required fields', () {
      final row = _base().toRow();
      expect(row['date_key'], '2026-04-18');
      expect(row['items'], isA<String>());
      expect(row.containsKey('weather_snapshot'), isTrue);
      expect(row.containsKey('created_at'), isTrue);
    });

    test('omits optional fields when null', () {
      final row = _base().toRow();
      expect(row['collage_path'], isNull);
      expect(row['feedback'], isNull);
      expect(row['reasoning'], isNull);
    });

    test('includes collagePath when set', () {
      final outfit = _base().copyWith(collagePath: '/docs/outfits/001/collage.webp');
      expect(outfit.toRow()['collage_path'], '/docs/outfits/001/collage.webp');
    });

    test('includes feedback when set', () {
      final outfit = _base().copyWith(feedback: OutfitFeedback.like);
      expect(outfit.toRow()['feedback'], 'like');
    });

    test('includes reasoning when set', () {
      final outfit = _base().copyWith(reasoning: '오늘은 따뜻해서 가벼운 코디');
      expect(outfit.toRow()['reasoning'], '오늘은 따뜻해서 가벼운 코디');
    });
  });

  group('OutfitModel.copyWith', () {
    test('preserves unchanged fields', () {
      final updated = _base().copyWith(collagePath: '/new/path');
      expect(updated.id, 'o001');
      expect(updated.dateKey, '2026-04-18');
      expect(updated.items, ['g1', 'g2', 'g3']);
    });

    test('updates collagePath', () {
      final updated = _base().copyWith(collagePath: '/docs/collage.webp');
      expect(updated.collagePath, '/docs/collage.webp');
    });

    test('updates feedback', () {
      final updated = _base().copyWith(feedback: OutfitFeedback.dislike);
      expect(updated.feedback, OutfitFeedback.dislike);
    });
  });

  group('favorite logic', () {
    test('feedback like = favorite', () {
      final outfit = _base().copyWith(feedback: OutfitFeedback.like);
      expect(outfit.feedback == OutfitFeedback.like, isTrue);
    });

    test('feedback dislike = not favorite', () {
      final outfit = _base().copyWith(feedback: OutfitFeedback.dislike);
      expect(outfit.feedback == OutfitFeedback.like, isFalse);
    });

    test('null feedback = not favorite', () {
      expect(_base().feedback == OutfitFeedback.like, isFalse);
    });
  });
}
