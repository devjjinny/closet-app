export '../../services/recommendation/recommendation_engine.dart'
    show OutfitCandidate;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/enums.dart';
import '../../data/models/garment_model.dart';
import '../../data/models/outfit_model.dart';
import '../../data/models/weather_snapshot.dart';
import '../../data/repositories/garment_repository.dart';
import '../../data/repositories/outfit_repository.dart';
import '../../services/auth/auth_service.dart';
import '../../services/image/background_removal_service.dart';
import '../../services/image/collage_service.dart';
import '../../services/recommendation/recommendation_engine.dart';
import '../../services/storage/firebase_storage_service.dart';
import '../../services/weather/weather_service.dart';

// ──────────────────────────────
// Services
// ──────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final weatherServiceProvider = Provider<WeatherService>((ref) {
  // TODO: Replace with actual API key from env/remote config
  return WeatherService(apiKey: const String.fromEnvironment('OPENWEATHER_API_KEY'));
});

final storageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService();
});

final backgroundRemovalServiceProvider =
    Provider<BackgroundRemovalService>((ref) {
  return BackgroundRemovalService();
});

final thumbnailServiceProvider = Provider<ThumbnailService>((ref) {
  return ThumbnailService();
});

final collageServiceProvider = Provider<CollageService>((ref) {
  return CollageService();
});

final recommendationEngineProvider = Provider<RecommendationEngine>((ref) {
  return RecommendationEngine();
});

// ──────────────────────────────
// Repositories
// ──────────────────────────────

final garmentRepositoryProvider = Provider<GarmentRepository>((ref) {
  return GarmentRepository(storage: ref.watch(storageServiceProvider));
});

final outfitRepositoryProvider = Provider<OutfitRepository>((ref) {
  return OutfitRepository(storage: ref.watch(storageServiceProvider));
});

// ──────────────────────────────
// Auth State
// ──────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

// ──────────────────────────────
// Garments
// ──────────────────────────────

final garmentsStreamProvider = StreamProvider<List<GarmentModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(garmentRepositoryProvider).watchGarments(uid);
});

// ──────────────────────────────
// Weather
// ──────────────────────────────

final currentWeatherProvider = FutureProvider<WeatherSnapshot>((ref) async {
  final weatherService = ref.watch(weatherServiceProvider);

  try {
    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Default: Seoul
      return weatherService.getCurrentWeather(lat: 37.5665, lon: 126.978);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
    return weatherService.getCurrentWeather(
      lat: position.latitude,
      lon: position.longitude,
    );
  } catch (e) {
    // Fallback: Seoul
    return weatherService.getCurrentWeather(lat: 37.5665, lon: 126.978);
  }
});

// ──────────────────────────────
// Recommendations
// ──────────────────────────────

final recommendationsProvider =
    FutureProvider.family<List<OutfitCandidate>, String?>(
  (ref, styleTagName) async {
    final uid = ref.watch(currentUidProvider);
    if (uid == null) return [];

    final garments = ref.watch(garmentsStreamProvider).value ?? [];
    if (garments.isEmpty) return [];

    final weather = await ref.watch(currentWeatherProvider.future);
    final recentOutfits =
        await ref.watch(outfitRepositoryProvider).getRecentOutfits(uid);

    final engine = ref.watch(recommendationEngineProvider);

    final styleTag = styleTagName != null
        ? StyleTag.values.firstWhere(
            (e) => e.name == styleTagName,
            orElse: () => StyleTag.casual,
          )
        : null;

    return engine.recommend(
      garments: garments,
      weather: weather,
      styleTag: styleTag,
      recentOutfits: recentOutfits,
    );
  },
);

// ──────────────────────────────
// Outfits / History
// ──────────────────────────────

final outfitsStreamProvider = StreamProvider<List<OutfitModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(outfitRepositoryProvider).watchOutfits(uid);
});
