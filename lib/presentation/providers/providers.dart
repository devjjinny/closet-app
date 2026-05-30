export '../../services/recommendation/recommendation_engine.dart'
    show OutfitCandidate;

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/enums.dart';
import '../../data/models/garment_model.dart';
import '../../data/models/outfit_model.dart';
import '../../data/models/style_preference.dart';
import '../../data/models/user_model.dart';
import '../../data/models/weather_snapshot.dart';
import '../../data/repositories/garment_repository.dart';
import '../../data/repositories/outfit_repository.dart';
import '../../services/image/background_removal_service.dart';
import '../../services/image/collage_service.dart';
import '../../services/recommendation/recommendation_engine.dart';
import '../../services/storage/local_storage_service.dart';
import '../../services/weather/weather_service.dart';

// ──────────────────────────────
// Services
// ──────────────────────────────

final weatherServiceProvider = Provider<WeatherService>((ref) {
  const apiKey = String.fromEnvironment('OWM_API_KEY');
  return WeatherService(apiKey: apiKey);
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
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
  final repo = GarmentRepository(
      storage: ref.watch(localStorageServiceProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final outfitRepositoryProvider = Provider<OutfitRepository>((ref) {
  final repo = OutfitRepository(
      storage: ref.watch(localStorageServiceProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

// ──────────────────────────────
// Style Preference
// ──────────────────────────────

class StylePreferenceNotifier extends Notifier<StylePreference> {
  static const _prefKey = 'selected_style_tag';

  @override
  StylePreference build() {
    _load();
    return const StylePreference();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      final tag = StyleTag.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => StyleTag.casual,
      );
      state = StylePreference(selectedTag: tag);
    }
  }

  Future<void> setTag(StyleTag? tag) async {
    state = StylePreference(selectedTag: tag);
    final prefs = await SharedPreferences.getInstance();
    if (tag == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, tag.name);
    }
  }
}

final stylePreferenceProvider =
    NotifierProvider<StylePreferenceNotifier, StylePreference>(
  StylePreferenceNotifier.new,
);

// ──────────────────────────────
// Onboarding
// ──────────────────────────────

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
});

// ──────────────────────────────
// User Prefs (SharedPreferences)
// ──────────────────────────────

class UserPrefsNotifier extends Notifier<UserPrefs> {
  static const _key = 'user_prefs';

  @override
  UserPrefs build() {
    _load();
    return const UserPrefs();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      state = UserPrefs.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    }
  }

  Future<void> saveGender(Gender gender) async {
    state = state.copyWith(gender: gender);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toMap()));
  }
}

final userPrefsProvider =
    NotifierProvider<UserPrefsNotifier, UserPrefs>(UserPrefsNotifier.new);

// ──────────────────────────────
// Garments
// ──────────────────────────────

final garmentsStreamProvider = StreamProvider<List<GarmentModel>>((ref) {
  return ref.watch(garmentRepositoryProvider).watchGarments();
});

// ──────────────────────────────
// Weather
// ──────────────────────────────

final currentWeatherProvider = FutureProvider<WeatherSnapshot>((ref) async {
  final weatherService = ref.watch(weatherServiceProvider);

  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
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
    return weatherService.getCurrentWeather(lat: 37.5665, lon: 126.978);
  }
});

// ──────────────────────────────
// Recommendations
// ──────────────────────────────

final recommendationsProvider =
    FutureProvider<List<OutfitCandidate>>((ref) async {
  final garments = ref.watch(garmentsStreamProvider).value ?? [];
  if (garments.isEmpty) return [];

  final weather = await ref.watch(currentWeatherProvider.future);
  final repo = ref.watch(outfitRepositoryProvider);
  final recentOutfits = await repo.getRecentOutfits();
  final likedOutfits = await repo.getLikedOutfits();

  final engine = ref.watch(recommendationEngineProvider);
  final styleTag = ref.watch(stylePreferenceProvider).selectedTag;

  return engine.recommend(
    garments: garments,
    weather: weather,
    styleTag: styleTag,
    recentOutfits: recentOutfits,
    likedOutfits: likedOutfits,
  );
});

// ──────────────────────────────
// Outfits / History
// ──────────────────────────────

final outfitsStreamProvider = StreamProvider<List<OutfitModel>>((ref) {
  return ref.watch(outfitRepositoryProvider).watchOutfits();
});
