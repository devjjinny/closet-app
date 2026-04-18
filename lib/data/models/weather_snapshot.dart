class WeatherSnapshot {
  const WeatherSnapshot({
    required this.provider,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.precipProb,
    required this.condition,
    this.rainMm,
    this.snowMm,
  });

  final String provider;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final double precipProb; // 0.0 ~ 1.0
  final String condition; // "Clear", "Rain", etc.
  final double? rainMm;
  final double? snowMm;

  bool get isRainy => precipProb > 0.4 || (rainMm != null && rainMm! > 0);
  bool get isSnowy => snowMm != null && snowMm! > 0;
  bool get needsWaterproof => precipProb > 0.5 || isRainy || isSnowy;

  /// 체감온도 기반 warmth 구간 (1=매우 더움 ~ 5=매우 추움) — 채점용
  int get requiredWarmthBudget {
    if (feelsLike >= 28) return 1;
    if (feelsLike >= 20) return 2;
    if (feelsLike >= 12) return 3;
    if (feelsLike >= 5) return 4;
    return 5;
  }

  /// 체감온도 기반 세부 구간 (1=최고온 ~ 8=최저온) — 추천 텍스트 생성용
  /// 이미지 기준: 28↑ / 23~27 / 20~22 / 17~19 / 12~16 / 9~11 / 5~8 / ~4
  int get temperatureBand {
    if (feelsLike >= 28) return 1;
    if (feelsLike >= 23) return 2;
    if (feelsLike >= 20) return 3;
    if (feelsLike >= 17) return 4;
    if (feelsLike >= 12) return 5;
    if (feelsLike >= 9) return 6;
    if (feelsLike >= 5) return 7;
    return 8;
  }

  factory WeatherSnapshot.fromMap(Map<String, dynamic> map) {
    return WeatherSnapshot(
      provider: map['provider'] as String? ?? 'openweather',
      temp: (map['temp'] as num?)?.toDouble() ?? 20.0,
      feelsLike: (map['feelsLike'] as num?)?.toDouble() ?? 20.0,
      humidity: (map['humidity'] as num?)?.toInt() ?? 50,
      windSpeed: (map['windSpeed'] as num?)?.toDouble() ?? 0.0,
      precipProb: (map['precipProb'] as num?)?.toDouble() ?? 0.0,
      condition: map['condition'] as String? ?? 'Clear',
      rainMm: (map['rainMm'] as num?)?.toDouble(),
      snowMm: (map['snowMm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'provider': provider,
        'temp': temp,
        'feelsLike': feelsLike,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'precipProb': precipProb,
        'condition': condition,
        if (rainMm != null) 'rainMm': rainMm,
        if (snowMm != null) 'snowMm': snowMm,
      };

  /// 기본 날씨 (API 실패 시 fallback)
  factory WeatherSnapshot.fallback() => const WeatherSnapshot(
        provider: 'fallback',
        temp: 20.0,
        feelsLike: 20.0,
        humidity: 50,
        windSpeed: 5.0,
        precipProb: 0.0,
        condition: 'Clear',
      );

  @override
  String toString() =>
      'Weather($condition, ${temp.toStringAsFixed(1)}°C, feels $feelsLike°C)';
}
