import 'dart:math';
import '../../core/constants/enums.dart';
import '../../data/models/garment_model.dart';
import '../../data/models/outfit_model.dart';
import '../../data/models/weather_snapshot.dart';

/// 추천 코디 후보
class OutfitCandidate {
  const OutfitCandidate({
    required this.items,
    required this.score,
    required this.reasoning,
  });

  final Map<GarmentCategory, GarmentModel> items;
  final double score;
  final String reasoning;

  List<String> get garmentIds => items.values.map((g) => g.id).toList();
}

/// 룰 기반 추천 엔진 v1
class RecommendationEngine {
  /// 추천 코디 후보 생성
  List<OutfitCandidate> recommend({
    required List<GarmentModel> garments,
    required WeatherSnapshot weather,
    StyleTag? styleTag,
    List<OutfitModel> recentOutfits = const [],
    int maxResults = 5,
  }) {
    final activeGarments =
        garments.where((g) => g.status == GarmentStatus.active).toList();

    // Group by category
    final byCategory = <GarmentCategory, List<GarmentModel>>{};
    for (final g in activeGarments) {
      byCategory.putIfAbsent(g.category, () => []).add(g);
    }

    final tops = byCategory[GarmentCategory.top] ?? [];
    final bottoms = byCategory[GarmentCategory.bottom] ?? [];
    final outers = byCategory[GarmentCategory.outer] ?? [];
    final shoes = byCategory[GarmentCategory.shoes] ?? [];
    final dresses = byCategory[GarmentCategory.dress] ?? [];

    final candidates = <OutfitCandidate>[];

    // Strategy 1: top + bottom (+ outer) + shoes
    for (final top in tops) {
      for (final bottom in bottoms) {
        final combo = <GarmentCategory, GarmentModel>{
          GarmentCategory.top: top,
          GarmentCategory.bottom: bottom,
        };

        // Add outer if cool or cold (12°C 이하부터 아우터 추천)
        if (weather.requiredWarmthBudget >= 3 && outers.isNotEmpty) {
          final bestOuter = _bestOuter(outers, weather, styleTag);
          if (bestOuter != null) {
            combo[GarmentCategory.outer] = bestOuter;
          }
        }

        // Add shoes
        if (shoes.isNotEmpty) {
          final bestShoe = _bestShoe(shoes, weather, styleTag);
          if (bestShoe != null) {
            combo[GarmentCategory.shoes] = bestShoe;
          }
        }

        final score = _scoreOutfit(combo, weather, styleTag, recentOutfits);
        final reasoning = _generateReasoning(combo, weather, score);

        candidates.add(OutfitCandidate(
          items: combo,
          score: score,
          reasoning: reasoning,
        ));
      }
    }

    // Strategy 2: dress (+ outer) + shoes
    for (final dress in dresses) {
      final combo = <GarmentCategory, GarmentModel>{
        GarmentCategory.dress: dress,
      };

      if (weather.requiredWarmthBudget >= 3 && outers.isNotEmpty) {
        final bestOuter = _bestOuter(outers, weather, styleTag);
        if (bestOuter != null) {
          combo[GarmentCategory.outer] = bestOuter;
        }
      }

      if (shoes.isNotEmpty) {
        final bestShoe = _bestShoe(shoes, weather, styleTag);
        if (bestShoe != null) {
          combo[GarmentCategory.shoes] = bestShoe;
        }
      }

      final score = _scoreOutfit(combo, weather, styleTag, recentOutfits);
      final reasoning = _generateReasoning(combo, weather, score);

      candidates.add(OutfitCandidate(
        items: combo,
        score: score,
        reasoning: reasoning,
      ));
    }

    // Sort by score descending
    candidates.sort((a, b) => b.score.compareTo(a.score));

    return candidates.take(maxResults).toList();
  }

  /// 코디 점수 계산
  double _scoreOutfit(
    Map<GarmentCategory, GarmentModel> items,
    WeatherSnapshot weather,
    StyleTag? styleTag,
    List<OutfitModel> recentOutfits,
  ) {
    double score = 50.0; // Base score

    // 1. Warmth score: 체감온도에 맞는 보온성
    final targetWarmth = weather.requiredWarmthBudget;
    final totalWarmth = _calculateTotalWarmth(items);
    final warmthDiff = (targetWarmth - totalWarmth).abs();
    score += (10.0 - warmthDiff * 5).clamp(0, 15); // max +15

    // 2. Waterproof score
    if (weather.needsWaterproof) {
      final hasWaterproof =
          items.values.any((g) => g.waterproof);
      score += hasWaterproof ? 10 : -10;
    }

    // 3. Style tag matching
    if (styleTag != null) {
      final matchCount = items.values
          .where((g) => g.styleTags.contains(styleTag))
          .length;
      score += matchCount * 5; // max ~20
    }

    // 4. Color harmony (simple)
    score += _colorHarmonyScore(items);

    // 5. Recent outfit penalty
    score += _recentPenalty(items, recentOutfits);

    // 6. Formality consistency
    score += _formalityConsistency(items);

    return score.clamp(0, 100);
  }

  double _calculateTotalWarmth(Map<GarmentCategory, GarmentModel> items) {
    // Average warmth of all items, weighted
    double total = 0;
    double weight = 0;

    for (final entry in items.entries) {
      final w = switch (entry.key) {
        GarmentCategory.outer => 1.5,
        GarmentCategory.top || GarmentCategory.dress => 1.0,
        GarmentCategory.bottom => 0.8,
        _ => 0.3,
      };
      total += entry.value.warmth * w;
      weight += w;
    }

    return weight > 0 ? total / weight : 3;
  }

  /// 색상 조화 점수 (간단 버전)
  double _colorHarmonyScore(Map<GarmentCategory, GarmentModel> items) {
    final colors = items.values.map((g) => g.dominantHex).toList();
    if (colors.length < 2) return 5;

    int neutralCount = 0;
    int boldCount = 0;

    for (final hex in colors) {
      if (_isNeutralColor(hex)) {
        neutralCount++;
      } else {
        boldCount++;
      }
    }

    // Rule: 무채색 + 포인트 1개 → 좋음
    if (neutralCount >= 1 && boldCount <= 1) return 8;
    // 강한 색 2개 이상 → 패널티
    if (boldCount >= 2) return -3;
    return 3;
  }

  bool _isNeutralColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return true;
    final r = int.parse(cleaned.substring(0, 2), radix: 16);
    final g = int.parse(cleaned.substring(2, 4), radix: 16);
    final b = int.parse(cleaned.substring(4, 6), radix: 16);

    final maxC = [r, g, b].reduce(max);
    final minC = [r, g, b].reduce(min);
    final saturation = maxC == 0 ? 0.0 : (maxC - minC) / maxC;

    // Low saturation or very dark/very light = neutral
    return saturation < 0.2 || maxC < 60 || minC > 200;
  }

  /// 최근 7일 동일 조합 패널티
  double _recentPenalty(
    Map<GarmentCategory, GarmentModel> items,
    List<OutfitModel> recentOutfits,
  ) {
    final currentIds = items.values.map((g) => g.id).toSet();

    for (final outfit in recentOutfits) {
      final outfitIds = outfit.items.toSet();
      final overlap = currentIds.intersection(outfitIds);
      // 동일 아이템 2개 이상 겹치면 패널티
      if (overlap.length >= 2) return -15;
      if (overlap.length == 1) return -5;
    }

    return 0;
  }

  /// 포멀도 일관성
  double _formalityConsistency(Map<GarmentCategory, GarmentModel> items) {
    final formalities = items.values.map((g) => g.formality).toList();
    if (formalities.length < 2) return 3;

    final avg = formalities.reduce((a, b) => a + b) / formalities.length;
    final maxDiff = formalities
        .map((f) => (f - avg).abs())
        .reduce((a, b) => a > b ? a : b);

    // 포멀도가 일관될수록 높은 점수
    if (maxDiff <= 0.5) return 5;
    if (maxDiff <= 1.0) return 3;
    if (maxDiff <= 2.0) return 0;
    return -5;
  }

  GarmentModel? _bestOuter(
    List<GarmentModel> outers,
    WeatherSnapshot weather,
    StyleTag? styleTag,
  ) {
    if (outers.isEmpty) return null;

    outers.sort((a, b) {
      double scoreA = 0, scoreB = 0;

      // Warmth match
      final target = weather.requiredWarmthBudget;
      scoreA -= (a.warmth - target).abs() * 2;
      scoreB -= (b.warmth - target).abs() * 2;

      // Waterproof bonus
      if (weather.needsWaterproof) {
        if (a.waterproof) scoreA += 5;
        if (b.waterproof) scoreB += 5;
      }

      // Style match
      if (styleTag != null) {
        if (a.styleTags.contains(styleTag)) scoreA += 3;
        if (b.styleTags.contains(styleTag)) scoreB += 3;
      }

      return scoreB.compareTo(scoreA);
    });

    return outers.first;
  }

  GarmentModel? _bestShoe(
    List<GarmentModel> shoes,
    WeatherSnapshot weather,
    StyleTag? styleTag,
  ) {
    if (shoes.isEmpty) return null;

    shoes.sort((a, b) {
      double scoreA = 0, scoreB = 0;

      if (weather.needsWaterproof) {
        if (a.waterproof) scoreA += 5;
        if (b.waterproof) scoreB += 5;
      }

      if (styleTag != null) {
        if (a.styleTags.contains(styleTag)) scoreA += 3;
        if (b.styleTags.contains(styleTag)) scoreB += 3;
      }

      return scoreB.compareTo(scoreA);
    });

    return shoes.first;
  }

  /// 추천 사유 텍스트 생성
  String _generateReasoning(
    Map<GarmentCategory, GarmentModel> items,
    WeatherSnapshot weather,
    double score,
  ) {
    final parts = <String>[];
    final temp = weather.feelsLike.round();

    // 8단계 온도 구간별 날씨 설명 + 권장 아이템 힌트
    switch (weather.temperatureBand) {
      case 1:
        parts.add('체감온도 $temp°C, 무더운 날이에요. 민소매·반팔·반바지가 딱 맞아요');
      case 2:
        parts.add('체감온도 $temp°C, 더운 날이에요. 반팔·얇은 셔츠·면바지가 좋아요');
      case 3:
        parts.add('체감온도 $temp°C, 따뜻한 날이에요. 얇은 가디건이나 긴팔을 챙기세요');
      case 4:
        parts.add('체감온도 $temp°C, 선선해요. 얇은 니트나 맨투맨이 적당해요');
      case 5:
        parts.add('체감온도 $temp°C, 쌀쌀해요. 자켓이나 가디건·야상이 어울려요');
      case 6:
        parts.add('체감온도 $temp°C, 춥네요. 트렌치코트나 야상에 니트 레이어링을 추천해요');
      case 7:
        parts.add('체감온도 $temp°C, 많이 추워요. 히트텍·니트·레깅스로 따뜻하게 입으세요');
      default:
        parts.add('체감온도 $temp°C, 매우 추운 날이에요. 패딩·두꺼운 코트·목도리가 필수예요');
    }

    // Rain/snow
    if (weather.isRainy) {
      parts.add('비 예보가 있어 방수 아이템을 고려했어요');
    } else if (weather.isSnowy) {
      parts.add('눈 예보가 있어 따뜻하고 방수되는 아이템을 추천해요');
    }

    // Color harmony note
    final boldItems = items.values
        .where((g) => !_isNeutralColor(g.dominantHex))
        .toList();
    if (boldItems.length == 1) {
      parts.add('포인트 컬러로 조화를 맞췄어요');
    }

    return '${parts.join('. ')}.';
  }
}
