import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/enums.dart';
import '../../../data/models/outfit_model.dart';
import '../../widgets/async_widgets.dart';
import '../../widgets/character_widget.dart';
import '../../../data/models/weather_snapshot.dart';
import '../../providers/providers.dart';
import '../../widgets/collage_preview.dart';

class TodayOutfitScreen extends ConsumerStatefulWidget {
  const TodayOutfitScreen({super.key});

  @override
  ConsumerState<TodayOutfitScreen> createState() => _TodayOutfitScreenState();
}

class _TodayOutfitScreenState extends ConsumerState<TodayOutfitScreen> {
  int _candidateIndex = 0;

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(currentWeatherProvider);
    final recommendAsync = ref.watch(recommendationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: weatherAsync.when(
          loading: () => const AppLoadingWidget(message: '날씨 확인 중...'),
          error: (_, __) => _HomeBody(
            weather: WeatherSnapshot.fallback(),
            recommendAsync: recommendAsync,
            candidateIndex: _candidateIndex,
            selectedTag: ref.watch(stylePreferenceProvider).selectedTag,
            onTagSelected: _onTagSelected,
            onNextOutfit: _nextOutfit,
            onSave: _saveOutfit,
            onRetryRecommend: () => ref.refresh(recommendationsProvider),
            onRefreshWeather: () => ref.refresh(currentWeatherProvider),
          ),
          data: (weather) => _HomeBody(
            weather: weather,
            recommendAsync: recommendAsync,
            candidateIndex: _candidateIndex,
            selectedTag: ref.watch(stylePreferenceProvider).selectedTag,
            onTagSelected: _onTagSelected,
            onNextOutfit: _nextOutfit,
            onSave: _saveOutfit,
            onRetryRecommend: () => ref.refresh(recommendationsProvider),
            onRefreshWeather: () => ref.refresh(currentWeatherProvider),
          ),
        ),
      ),
    );
  }

  void _nextOutfit(int total) {
    setState(() => _candidateIndex = (_candidateIndex + 1) % total);
  }

  void _onTagSelected(StyleTag? tag) {
    final notifier = ref.read(stylePreferenceProvider.notifier);
    final current = ref.read(stylePreferenceProvider).selectedTag;
    // 같은 태그 다시 탭하면 해제
    notifier.setTag(tag == current ? null : tag);
    setState(() => _candidateIndex = 0);
  }

  Future<void> _saveOutfit(OutfitCandidate candidate) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final weather =
        ref.read(currentWeatherProvider).value ?? WeatherSnapshot.fallback();
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // cutout URL로 콜라주 PNG 생성
      final cutoutUrls = candidate.items.map(
        (cat, garment) => MapEntry(cat, garment.image.cutoutUrl),
      );
      final collageFile = await ref
          .read(collageServiceProvider)
          .generateCollageFromUrls(cutoutUrls);

      final outfit = OutfitModel(
        id: '',
        dateKey: dateKey,
        items: candidate.garmentIds,
        weatherSnapshot: weather,
        createdAt: DateTime.now(),
        reasoning: candidate.reasoning,
      );
      await ref.read(outfitRepositoryProvider).saveOutfit(
            uid: uid,
            outfit: outfit,
            collageFile: collageFile,
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

// ──────────────────────────────────────────────────────────
// 메인 바디
// ──────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.weather,
    required this.recommendAsync,
    required this.candidateIndex,
    required this.selectedTag,
    required this.onTagSelected,
    required this.onNextOutfit,
    required this.onSave,
    required this.onRetryRecommend,
    required this.onRefreshWeather,
  });

  final WeatherSnapshot weather;
  final AsyncValue<List<OutfitCandidate>> recommendAsync;
  final int candidateIndex;
  final StyleTag? selectedTag;
  final void Function(StyleTag?) onTagSelected;
  final void Function(int total) onNextOutfit;
  final Future<void> Function(OutfitCandidate) onSave;
  final VoidCallback onRetryRecommend;
  final VoidCallback onRefreshWeather;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onRefreshWeather,
          child: _WeatherBar(weather: weather),
        ),

        _StyleTagRow(selectedTag: selectedTag, onTagSelected: onTagSelected),

        Expanded(
          flex: 5,
          child: CharacterWidget(weather: weather),
        ),

        Expanded(
          flex: 4,
          child: recommendAsync.buildWidget(
            onRetry: onRetryRecommend,
            onData: (candidates) {
              if (candidates.isEmpty) {
                return const _EmptyOutfitPanel();
              }
              final current = candidates[candidateIndex % candidates.length];
              return _OutfitPanel(
                candidate: current,
                onNext: () => onNextOutfit(candidates.length),
                onSave: () => onSave(current),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StyleTagRow extends StatelessWidget {
  const _StyleTagRow({required this.selectedTag, required this.onTagSelected});

  final StyleTag? selectedTag;
  final void Function(StyleTag?) onTagSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: StyleTag.values.map((tag) {
          final selected = selectedTag == tag;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onTagSelected(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF6C5CE7)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF6C5CE7)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  tag.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : Colors.grey[600],
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// 날씨 바
// ──────────────────────────────────────────────────────────

class _WeatherBar extends StatelessWidget {
  const _WeatherBar({required this.weather});

  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Icon(_weatherIcon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text(
            '${weather.temp.round()}°',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _conditionText,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                '체감 ${weather.feelsLike.round()}°',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          if (weather.precipProb > 0)
            _WeatherBadge(
              icon: Icons.water_drop,
              label: '${(weather.precipProb * 100).round()}%',
            ),
          const SizedBox(width: 8),
          _WeatherBadge(
            icon: Icons.air,
            label: '${weather.windSpeed.toStringAsFixed(1)}m/s',
          ),
        ],
      ),
    );
  }

  List<Color> get _gradientColors {
    if (weather.feelsLike >= 28) return [const Color(0xFFFF6B6B), const Color(0xFFffa502)];
    if (weather.feelsLike >= 20) return [const Color(0xFF74b9ff), const Color(0xFF0984e3)];
    if (weather.feelsLike >= 12) return [const Color(0xFF6C5CE7), const Color(0xFF55a3e8)];
    return [const Color(0xFF2d3436), const Color(0xFF636e72)];
  }

  IconData get _weatherIcon {
    switch (weather.condition) {
      case 'Clear': return Icons.wb_sunny;
      case 'Clouds': return Icons.cloud;
      case 'Rain': case 'Drizzle': return Icons.water_drop;
      case 'Snow': return Icons.ac_unit;
      case 'Thunderstorm': return Icons.flash_on;
      default: return Icons.cloud;
    }
  }

  String get _conditionText {
    switch (weather.condition) {
      case 'Clear': return '맑음';
      case 'Clouds': return '흐림';
      case 'Rain': return '비';
      case 'Drizzle': return '이슬비';
      case 'Snow': return '눈';
      case 'Thunderstorm': return '천둥번개';
      default: return weather.condition;
    }
  }
}

class _WeatherBadge extends StatelessWidget {
  const _WeatherBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// 코디 패널
// ──────────────────────────────────────────────────────────

class _OutfitPanel extends StatelessWidget {
  const _OutfitPanel({
    required this.candidate,
    required this.onNext,
    required this.onSave,
  });

  final OutfitCandidate candidate;
  final VoidCallback onNext;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 추천 이유
          Text(
            candidate.reasoning,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // 콜라주 미리보기
          CollagePreviewWidget(items: candidate.items, height: 200),
          const SizedBox(height: 12),

          // 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onNext,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6C5CE7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '다른 코디 보기',
                    style: TextStyle(color: Color(0xFF6C5CE7)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('이 코디 입기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyOutfitPanel extends StatelessWidget {
  const _EmptyOutfitPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '옷을 3벌 이상 등록하면\n코디 추천을 받을 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

