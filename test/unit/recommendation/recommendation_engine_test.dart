import 'package:flutter_test/flutter_test.dart';
import 'package:closet_app/services/recommendation/recommendation_engine.dart';
import 'package:closet_app/data/models/garment_model.dart';
import 'package:closet_app/data/models/weather_snapshot.dart';
import 'package:closet_app/core/constants/enums.dart';

void main() {
  late RecommendationEngine engine;

  setUp(() {
    engine = RecommendationEngine();
  });

  GarmentModel makeGarment({
    required String id,
    required GarmentCategory category,
    int warmth = 3,
    int formality = 3,
    bool waterproof = false,
    String color = '#000000',
    List<StyleTag> styleTags = const [],
  }) {
    return GarmentModel(
      id: id,
      category: category,
      dominantHex: color,
      warmth: warmth,
      formality: formality,
      waterproof: waterproof,
      styleTags: styleTags,
      image: const GarmentImage(
        originalUrl: '',
        cutoutUrl: '',
        thumbUrl: '',
      ),
      createdAt: DateTime.now(),
    );
  }

  WeatherSnapshot makeWeather({
    double feelsLike = 20.0,
    double precipProb = 0.0,
    String condition = 'Clear',
  }) {
    return WeatherSnapshot(
      provider: 'test',
      temp: feelsLike,
      feelsLike: feelsLike,
      humidity: 50,
      windSpeed: 5.0,
      precipProb: precipProb,
      condition: condition,
    );
  }

  group('RecommendationEngine', () {
    // Given-When-Then: 1
    test('상의+하의가 있으면 추천 결과를 반환한다', () {
      // Given: 상의 1, 하의 1 등록
      final garments = [
        makeGarment(id: 't1', category: GarmentCategory.top),
        makeGarment(id: 'b1', category: GarmentCategory.bottom),
      ];
      final weather = makeWeather();

      // When: 추천 요청
      final results = engine.recommend(garments: garments, weather: weather);

      // Then: 1개 이상 추천
      expect(results.isNotEmpty, true);
      expect(results.first.items.containsKey(GarmentCategory.top), true);
      expect(results.first.items.containsKey(GarmentCategory.bottom), true);
    });

    // Given-When-Then: 2
    test('옷이 부족하면 빈 결과를 반환한다', () {
      // Given: 상의만 있음
      final garments = [
        makeGarment(id: 't1', category: GarmentCategory.top),
      ];
      final weather = makeWeather();

      // When
      final results = engine.recommend(garments: garments, weather: weather);

      // Then
      expect(results.isEmpty, true);
    });

    // Given-When-Then: 3
    test('추운 날씨에 아우터가 포함된다', () {
      // Given: 체감 0도, 아우터 있음
      final garments = [
        makeGarment(id: 't1', category: GarmentCategory.top, warmth: 4),
        makeGarment(id: 'b1', category: GarmentCategory.bottom, warmth: 4),
        makeGarment(id: 'o1', category: GarmentCategory.outer, warmth: 5),
      ];
      final weather = makeWeather(feelsLike: 0);

      // When
      final results = engine.recommend(garments: garments, weather: weather);

      // Then: 아우터 포함
      expect(results.first.items.containsKey(GarmentCategory.outer), true);
    });

    // Given-When-Then: 4
    test('비 오는 날 방수 아이템이 높은 점수를 받는다', () {
      // Given: 방수 아우터 vs 비방수 아우터
      final garments = [
        makeGarment(id: 't1', category: GarmentCategory.top),
        makeGarment(id: 'b1', category: GarmentCategory.bottom),
        makeGarment(id: 'o1', category: GarmentCategory.outer, waterproof: true, warmth: 4),
        makeGarment(id: 'o2', category: GarmentCategory.outer, waterproof: false, warmth: 4),
      ];
      final weather = makeWeather(feelsLike: 3, precipProb: 0.8, condition: 'Rain');

      // When
      final results = engine.recommend(garments: garments, weather: weather);

      // Then: 방수 아우터가 선택됨
      final outer = results.first.items[GarmentCategory.outer];
      expect(outer?.waterproof, true);
    });

    // Given-When-Then: 5
    test('스타일 태그 매칭이 점수에 반영된다', () {
      // Given
      final garments = [
        makeGarment(id: 't1', category: GarmentCategory.top, styleTags: [StyleTag.office]),
        makeGarment(id: 't2', category: GarmentCategory.top, styleTags: [StyleTag.sport]),
        makeGarment(id: 'b1', category: GarmentCategory.bottom, styleTags: [StyleTag.office]),
      ];
      final weather = makeWeather();

      // When: office 스타일로 추천
      final results = engine.recommend(
        garments: garments,
        weather: weather,
        styleTag: StyleTag.office,
      );

      // Then: office 태그가 있는 상의가 더 높은 점수
      expect(results.isNotEmpty, true);
      // 첫 번째 결과의 상의가 office 태그를 가질 가능성이 높음
      final topItem = results.first.items[GarmentCategory.top];
      expect(topItem?.styleTags.contains(StyleTag.office), true);
    });

    // Given-When-Then: 6
    test('추천 사유(reasoning) 텍스트가 생성된다', () {
      // Given
      final garments = [
        makeGarment(id: 't1', category: GarmentCategory.top),
        makeGarment(id: 'b1', category: GarmentCategory.bottom),
      ];
      final weather = makeWeather(feelsLike: 25);

      // When
      final results = engine.recommend(garments: garments, weather: weather);

      // Then
      expect(results.first.reasoning.isNotEmpty, true);
      expect(results.first.reasoning.contains('°C'), true);
    });

    // Given-When-Then: 7
    test('최대 maxResults 개수만큼만 반환한다', () {
      // Given: 많은 조합 가능한 옷
      final garments = [
        for (int i = 0; i < 5; i++)
          makeGarment(id: 't$i', category: GarmentCategory.top),
        for (int i = 0; i < 5; i++)
          makeGarment(id: 'b$i', category: GarmentCategory.bottom),
      ];
      final weather = makeWeather();

      // When
      final results = engine.recommend(
        garments: garments,
        weather: weather,
        maxResults: 3,
      );

      // Then
      expect(results.length, 3);
    });

    // Given-When-Then: 8
    test('원피스도 추천 후보에 포함된다', () {
      // Given
      final garments = [
        makeGarment(id: 'd1', category: GarmentCategory.dress),
      ];
      final weather = makeWeather();

      // When
      final results = engine.recommend(garments: garments, weather: weather);

      // Then
      expect(results.isNotEmpty, true);
      expect(results.first.items.containsKey(GarmentCategory.dress), true);
    });

    // Given-When-Then: 9
    test('archived 아이템은 제외된다', () {
      // Given
      final garments = [
        makeGarment(id: 't1', category: GarmentCategory.top)
            .copyWith(status: GarmentStatus.archived),
        makeGarment(id: 'b1', category: GarmentCategory.bottom),
      ];
      final weather = makeWeather();

      // When
      final results = engine.recommend(garments: garments, weather: weather);

      // Then
      expect(results.isEmpty, true);
    });

    // Given-When-Then: 10
    test('결과가 점수 내림차순으로 정렬된다', () {
      // Given
      final garments = [
        makeGarment(id: 't1', category: GarmentCategory.top, warmth: 2, color: '#808080'),
        makeGarment(id: 't2', category: GarmentCategory.top, warmth: 5, color: '#FF0000'),
        makeGarment(id: 'b1', category: GarmentCategory.bottom, warmth: 2, color: '#000000'),
      ];
      final weather = makeWeather(feelsLike: 22); // 따뜻 → warmth 2가 적합

      // When
      final results = engine.recommend(garments: garments, weather: weather);

      // Then: 점수 내림차순
      for (int i = 0; i < results.length - 1; i++) {
        expect(results[i].score >= results[i + 1].score, true);
      }
    });
  });
}
