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

  group('OutfitModel.toFirestore', () {
    test('includes required fields', () {
      final map = _base().toFirestore();
      expect(map['dateKey'], '2026-04-18');
      expect(map['items'], ['g1', 'g2', 'g3']);
      expect(map.containsKey('weatherSnapshot'), isTrue);
      expect(map.containsKey('createdAt'), isTrue);
    });

    test('omits optional fields when null', () {
      final map = _base().toFirestore();
      expect(map.containsKey('resultImageUrl'), isFalse);
      expect(map.containsKey('feedback'), isFalse);
      expect(map.containsKey('reasoning'), isFalse);
      expect(map.containsKey('context'), isFalse);
    });

    test('includes resultImageUrl when set', () {
      final outfit = _base().copyWith(resultImageUrl: 'https://img.url');
      expect(outfit.toFirestore()['resultImageUrl'], 'https://img.url');
    });

    test('includes feedback when set', () {
      final outfit = _base().copyWith(feedback: OutfitFeedback.like);
      expect(outfit.toFirestore()['feedback'], 'like');
    });

    test('includes reasoning when set', () {
      final outfit = _base().copyWith(reasoning: '오늘은 따뜻해서 가벼운 코디');
      expect(outfit.toFirestore()['reasoning'], '오늘은 따뜻해서 가벼운 코디');
    });
  });

  group('OutfitModel.copyWith', () {
    test('preserves unchanged fields', () {
      final updated = _base().copyWith(resultImageUrl: 'https://new.url');
      expect(updated.id, 'o001');
      expect(updated.dateKey, '2026-04-18');
      expect(updated.items, ['g1', 'g2', 'g3']);
    });

    test('updates resultImageUrl', () {
      final updated = _base().copyWith(resultImageUrl: 'https://x.com/img.png');
      expect(updated.resultImageUrl, 'https://x.com/img.png');
    });

    test('updates feedback', () {
      final updated = _base().copyWith(feedback: OutfitFeedback.dislike);
      expect(updated.feedback, OutfitFeedback.dislike);
    });
  });

  group('OutfitContext', () {
    test('toMap / fromMap roundtrip', () {
      const ctx = OutfitContext(styleTag: StyleTag.casual, timeOfDay: 'day');
      final restored = OutfitContext.fromMap(ctx.toMap());
      expect(restored.styleTag, StyleTag.casual);
      expect(restored.timeOfDay, 'day');
    });

    test('fromMap handles missing fields', () {
      final ctx = OutfitContext.fromMap({});
      expect(ctx.styleTag, isNull);
      expect(ctx.timeOfDay, isNull);
    });

    test('toMap omits null fields', () {
      const ctx = OutfitContext();
      expect(ctx.toMap().isEmpty, isTrue);
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
