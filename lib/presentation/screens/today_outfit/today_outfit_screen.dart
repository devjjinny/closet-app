import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/enums.dart';
import '../../../data/models/outfit_model.dart';
import '../../../data/models/weather_snapshot.dart';
import '../../providers/providers.dart';

class TodayOutfitScreen extends ConsumerStatefulWidget {
  const TodayOutfitScreen({super.key});

  @override
  ConsumerState<TodayOutfitScreen> createState() => _TodayOutfitScreenState();
}

class _TodayOutfitScreenState extends ConsumerState<TodayOutfitScreen> {
  StyleTag? _selectedStyle;

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(currentWeatherProvider);
    final recommendAsync =
        ref.watch(recommendationsProvider(_selectedStyle?.name));

    return Scaffold(
      appBar: AppBar(title: const Text('오늘 코디')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Weather summary
            weatherAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _WeatherCard(
                weather: WeatherSnapshot.fallback(),
                isError: true,
              ),
              data: (weather) => _WeatherCard(weather: weather),
            ),

            // Style filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StyleChip(
                      label: '전체',
                      selected: _selectedStyle == null,
                      onTap: () => setState(() => _selectedStyle = null),
                    ),
                    ...StyleTag.values.map((tag) => _StyleChip(
                          label: tag.label,
                          selected: _selectedStyle == tag,
                          onTap: () => setState(() => _selectedStyle = tag),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recommendations
            recommendAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('추천 생성 실패: $e'),
              ),
              data: (candidates) {
                if (candidates.isEmpty) {
                  return const _EmptyRecommendation();
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: candidates.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _OutfitCandidateCard(
                    candidate: candidates[index],
                    index: index + 1,
                    onSave: () => _saveOutfit(candidates[index]),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _saveOutfit(OutfitCandidate candidate) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final weather =
        ref.read(currentWeatherProvider).value ?? WeatherSnapshot.fallback();
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // TODO: In production, download cutout images and generate collage
      // For MVP, save outfit without collage image

      final outfit = OutfitModel(
        id: '',
        dateKey: dateKey,
        items: candidate.garmentIds,
        weatherSnapshot: weather,
        createdAt: DateTime.now(),
        context: OutfitContext(styleTag: _selectedStyle),
        reasoning: candidate.reasoning,
      );

      await ref.read(outfitRepositoryProvider).saveOutfit(
            uid: uid,
            outfit: outfit,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('코디가 저장되었어요!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather, this.isError = false});

  final WeatherSnapshot weather;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isError)
            const Text(
              '날씨를 불러오지 못했어요 (기본값 사용)',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          Row(
            children: [
              Icon(_weatherIcon, size: 40, color: Colors.white),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temp.round()}°C',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '체감 ${weather.feelsLike.round()}°C',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _conditionText,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '습도 ${weather.humidity}%  바람 ${weather.windSpeed.toStringAsFixed(1)}m/s',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (weather.precipProb > 0)
                    Text(
                      '강수확률 ${(weather.precipProb * 100).round()}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> get _gradientColors {
    if (weather.feelsLike >= 28) {
      return [const Color(0xFFFF6B6B), const Color(0xFFffa502)];
    }
    if (weather.feelsLike >= 20) {
      return [const Color(0xFF74b9ff), const Color(0xFF0984e3)];
    }
    if (weather.feelsLike >= 12) {
      return [const Color(0xFF55a3e8), const Color(0xFF6C5CE7)];
    }
    return [const Color(0xFF636e72), const Color(0xFF2d3436)];
  }

  IconData get _weatherIcon {
    switch (weather.condition) {
      case 'Clear':
        return Icons.wb_sunny;
      case 'Clouds':
        return Icons.cloud;
      case 'Rain':
      case 'Drizzle':
        return Icons.water_drop;
      case 'Snow':
        return Icons.ac_unit;
      case 'Thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.cloud;
    }
  }

  String get _conditionText {
    switch (weather.condition) {
      case 'Clear':
        return '맑음';
      case 'Clouds':
        return '흐림';
      case 'Rain':
        return '비';
      case 'Drizzle':
        return '이슬비';
      case 'Snow':
        return '눈';
      case 'Thunderstorm':
        return '천둥번개';
      default:
        return weather.condition;
    }
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _OutfitCandidateCard extends StatelessWidget {
  const _OutfitCandidateCard({
    required this.candidate,
    required this.index,
    required this.onSave,
  });

  final OutfitCandidate candidate;
  final int index;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF6C5CE7),
                  child: Text(
                    '$index',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '추천 코디 #$index',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${candidate.score.round()}점',
                    style: TextStyle(color: _scoreColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items preview
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: candidate.items.entries.map((entry) {
                  final garment = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: garment.image.thumbUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: garment.image.thumbUrl,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.checkroom, size: 24, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.key.label,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Reasoning
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                candidate.reasoning,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onSave,
                  child: const Text('이 코디 저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _scoreColor {
    if (candidate.score >= 70) return Colors.green;
    if (candidate.score >= 50) return Colors.orange;
    return Colors.red;
  }
}

class _EmptyRecommendation extends StatelessWidget {
  const _EmptyRecommendation();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.style_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '추천할 코디가 없어요',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '옷을 3벌 이상 등록하면 추천을 받을 수 있어요\n(상의 + 하의 + 신발)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
