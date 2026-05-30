import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/enums.dart';
import '../../data/models/weather_snapshot.dart';
import '../providers/providers.dart';

class CharacterWidget extends ConsumerWidget {
  const CharacterWidget({super.key, required this.weather});

  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gender = ref.watch(userPrefsProvider).gender ?? Gender.female;
    final condition = _weatherCondition(weather);
    final assetPath = 'assets/characters/${gender.name}_$condition.png';
    final fallbackPath =
        'assets/characters/${gender.name}_${_fallbackCondition(weather)}.png';

    return Center(
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Image.asset(
          fallbackPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _Placeholder(gender: gender),
        ),
      ),
    );
  }

  String _weatherCondition(WeatherSnapshot w) {
    if (w.isRainy || w.isSnowy) return 'rainy';
    return 'band${w.temperatureBand}';
  }

  String _fallbackCondition(WeatherSnapshot w) {
    if (w.isRainy || w.isSnowy) return 'rainy';
    if (w.feelsLike < 10) return 'cold';
    if (w.condition == 'Clouds') return 'cloudy';
    return 'sunny';
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.gender});

  final Gender gender;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 260,
      decoration: BoxDecoration(
        color: gender == Gender.female
            ? const Color(0xFFFFF0F5)
            : const Color(0xFFEEEBFB),
        borderRadius: BorderRadius.circular(120),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 100,
            color: gender == Gender.female
                ? const Color(0xFFE84393)
                : const Color(0xFF6C5CE7),
          ),
          const SizedBox(height: 8),
          Text(
            gender.label,
            style: TextStyle(
              fontSize: 12,
              color: gender == Gender.female
                  ? const Color(0xFFE84393)
                  : const Color(0xFF6C5CE7),
            ),
          ),
        ],
      ),
    );
  }
}
