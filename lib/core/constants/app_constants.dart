abstract class AppConstants {
  // Weather cache TTL
  static const weatherCacheTtlMinutes = 60;

  // Image sizes
  static const thumbnailWidth = 300;
  static const thumbnailQuality = 80;
  static const collageWidth = 1080;
  static const collageHeight = 1440;

  // Recommendation
  static const maxRecommendations = 5;
  static const recentOutfitPenaltyDays = 7;

}

abstract class WeatherCondition {
  static const clear = 'Clear';
  static const clouds = 'Clouds';
  static const rain = 'Rain';
  static const drizzle = 'Drizzle';
  static const thunderstorm = 'Thunderstorm';
  static const snow = 'Snow';
  static const mist = 'Mist';
}
