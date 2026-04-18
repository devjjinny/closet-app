export '../../services/recommendation/recommendation_engine.dart'
    show OutfitCandidate;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/garment_model.dart';
import '../../data/models/outfit_model.dart';
import '../../data/models/style_preference.dart';
import '../../data/models/user_model.dart';
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
// App Init
// ──────────────────────────────

final authInitProvider = FutureProvider<void>((ref) async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }
});

// ──────────────────────────────
// Services
// ──────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(apiKey: 'f3af7a73ad5b5004f4be31ee7e17672a');
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
// Auth State
// ──────────────────────────────

final userPrefsProvider = StreamProvider<UserPrefs>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const UserPrefs());
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return const UserPrefs();
    final data = doc.data() as Map<String, dynamic>;
    return UserPrefs.fromMap(data['prefs'] as Map<String, dynamic>? ?? {});
  });
});

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
    FutureProvider<List<OutfitCandidate>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return [];

  final garments = ref.watch(garmentsStreamProvider).value ?? [];
  if (garments.isEmpty) return [];

  final weather = await ref.watch(currentWeatherProvider.future);
  final recentOutfits =
      await ref.watch(outfitRepositoryProvider).getRecentOutfits(uid);

  final engine = ref.watch(recommendationEngineProvider);
  final styleTag = ref.watch(stylePreferenceProvider).selectedTag;

  return engine.recommend(
    garments: garments,
    weather: weather,
    styleTag: styleTag,
    recentOutfits: recentOutfits,
  );
});

// ──────────────────────────────
// Outfits / History
// ──────────────────────────────

final outfitsStreamProvider = StreamProvider<List<OutfitModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value([]);
  return ref.watch(outfitRepositoryProvider).watchOutfits(uid);
});
