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

  // Storage paths
  static String garmentOriginalPath(String uid, String garmentId) =>
      'users/$uid/garments/$garmentId/original.jpg';
  static String garmentCutoutPath(String uid, String garmentId) =>
      'users/$uid/garments/$garmentId/cutout.png';
  static String garmentThumbPath(String uid, String garmentId) =>
      'users/$uid/garments/$garmentId/thumb.webp';
  static String outfitCollagePath(String uid, String outfitId) =>
      'users/$uid/outfits/$outfitId/collage.webp';
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
