import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/enums.dart';
import '../../../data/models/outfit_model.dart';
import '../../widgets/async_widgets.dart';
import '../../widgets/character_widget.dart';
import '../../theme/app_theme.dart';
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
      backgroundColor: AppTheme.bg,
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
            onSave: _openSaveFlow,
            onManualSave: () => context.push('/save-outfit'),
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
            onSave: _openSaveFlow,
            onManualSave: () => context.push('/save-outfit'),
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

  Future<void> _openSaveFlow(OutfitCandidate candidate) async {
    final weather =
        ref.read(currentWeatherProvider).value ?? WeatherSnapshot.fallback();
    final result = await showModalBottomSheet<_OutfitSaveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SaveOutfitSheet(candidate: candidate, weather: weather);
      },
    );

    if (result == null) return;
    await _saveOutfit(candidate, result);
  }

  Future<void> _saveOutfit(
    OutfitCandidate candidate,
    _OutfitSaveResult result,
  ) async {
    final weather =
        ref.read(currentWeatherProvider).value ?? WeatherSnapshot.fallback();
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final cutoutPaths = candidate.items.map(
        (cat, garment) => MapEntry(cat, garment.image.cutoutPath),
      );
      final collageFile = await ref
          .read(collageServiceProvider)
          .generateCollageFromPaths(cutoutPaths);

      final memo = result.memo.trim();
      final reasoning = memo.isEmpty
          ? candidate.reasoning
          : '${candidate.reasoning}\n메모: $memo';
      final outfit = OutfitModel(
        id: '',
        dateKey: dateKey,
        items: candidate.garmentIds,
        weatherSnapshot: weather,
        createdAt: DateTime.now(),
        feedback: result.feedback,
        reasoning: reasoning,
      );
      await ref
          .read(outfitRepositoryProvider)
          .saveOutfit(outfit: outfit, collageFile: collageFile);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('코디가 저장되었어요!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
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
    required this.onManualSave,
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
  final VoidCallback onManualSave;
  final VoidCallback onRetryRecommend;
  final VoidCallback onRefreshWeather;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onRefreshWeather,
            child: _TodayHeader(weather: weather),
          ),
          const SizedBox(height: 12),
          _DaySwitch(weather: weather),
          const SizedBox(height: 12),
          Expanded(
            child: recommendAsync.buildWidget(
              onRetry: onRetryRecommend,
              onData: (candidates) {
                if (candidates.isEmpty) {
                  return _EmptyOutfitPanel(weather: weather);
                }
                final current = candidates[candidateIndex % candidates.length];
                return _OutfitPanel(
                  candidate: current,
                  selectedTag: selectedTag,
                  weather: weather,
                  onTagSelected: onTagSelected,
                  onNext: () => onNextOutfit(candidates.length),
                  onSave: () => onSave(current),
                  onManualSave: onManualSave,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.weather});

  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Text(
            '오늘 코디',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _WeatherIcon(condition: weather.condition),
        const SizedBox(width: 8),
        Text(
          '${weather.temp.round()}°',
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DaySwitch extends StatelessWidget {
  const _DaySwitch({required this.weather});

  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.ink, width: 1.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.lavender500, width: 3),
                ),
              ),
              child: const Text(
                '오늘',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Text(
                '내일 · ${(weather.temp + 2).round()}°',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.inkSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherIcon extends StatelessWidget {
  const _WeatherIcon({required this.condition});

  final String condition;

  @override
  Widget build(BuildContext context) {
    return Icon(_icon, color: AppTheme.ink, size: 24);
  }

  IconData get _icon {
    switch (condition) {
      case 'Clear':
        return Icons.wb_sunny_outlined;
      case 'Rain':
      case 'Drizzle':
        return Icons.water_drop_outlined;
      case 'Snow':
        return Icons.ac_unit;
      case 'Thunderstorm':
        return Icons.flash_on_outlined;
      case 'Clouds':
      default:
        return Icons.cloud_outlined;
    }
  }
}

class _StyleTagRow extends StatelessWidget {
  const _StyleTagRow({required this.selectedTag, required this.onTagSelected});

  final StyleTag? selectedTag;
  final void Function(StyleTag?) onTagSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: StyleTag.values.map((tag) {
          final selected = selectedTag == tag;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onTagSelected(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.lavender50 : AppTheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppTheme.lavender500 : AppTheme.line,
                  ),
                ),
                child: Text(
                  tag.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: selected ? AppTheme.lavender600 : AppTheme.inkSoft,
                    fontWeight: FontWeight.w700,
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
    if (weather.feelsLike >= 28)
      return [const Color(0xFFFF6B6B), const Color(0xFFffa502)];
    if (weather.feelsLike >= 20)
      return [const Color(0xFF74b9ff), const Color(0xFF0984e3)];
    if (weather.feelsLike >= 12)
      return [const Color(0xFF6C5CE7), const Color(0xFF55a3e8)];
    return [const Color(0xFF2d3436), const Color(0xFF636e72)];
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
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
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
    required this.selectedTag,
    required this.weather,
    required this.onTagSelected,
    required this.onNext,
    required this.onSave,
    required this.onManualSave,
  });

  final OutfitCandidate candidate;
  final StyleTag? selectedTag;
  final WeatherSnapshot weather;
  final void Function(StyleTag?) onTagSelected;
  final VoidCallback onNext;
  final VoidCallback onSave;
  final VoidCallback onManualSave;

  @override
  Widget build(BuildContext context) {
    final collageH = (MediaQuery.of(context).size.height * 0.48).clamp(
      320.0,
      440.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.line),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lavender500.withValues(alpha: 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CollagePreviewWidget(
                items: candidate.items,
                height: collageH,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _StyleTagRow(selectedTag: selectedTag, onTagSelected: onTagSelected),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _MetaTag(label: selectedTag?.label.toUpperCase() ?? 'CASUAL'),
            _MetaTag(label: 'WARMTH ${weather.requiredWarmthBudget}'),
            _MetaTag(label: weather.needsWaterproof ? '방수 추천' : '방수 X'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          candidate.reasoning,
          style: const TextStyle(
            color: AppTheme.inkSoft,
            fontSize: 12,
            height: 1.35,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onSave,
                child: const Text('입었어요'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(onPressed: onNext, child: const Text('다시')),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: OutlinedButton(
                onPressed: onManualSave,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 48),
                ),
                child: const Icon(Icons.playlist_add_check),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyOutfitPanel extends StatelessWidget {
  const _EmptyOutfitPanel({required this.weather});

  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Expanded(child: CharacterWidget(weather: weather)),
            const SizedBox(height: 16),
            const Text(
              '첫 옷을 등록해 추천을 시작해요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '상의, 하의, 신발을 등록하면 오늘 날씨에 맞춰 코디를 만들어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutfitSaveResult {
  const _OutfitSaveResult({required this.feedback, required this.memo});

  final OutfitFeedback feedback;
  final String memo;
}

class _SaveOutfitSheet extends StatefulWidget {
  const _SaveOutfitSheet({required this.candidate, required this.weather});

  final OutfitCandidate candidate;
  final WeatherSnapshot weather;

  @override
  State<_SaveOutfitSheet> createState() => _SaveOutfitSheetState();
}

class _SaveOutfitSheetState extends State<_SaveOutfitSheet> {
  final _memoController = TextEditingController();
  OutfitFeedback _feedback = OutfitFeedback.like;

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final dateLabel = _todayLabel();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('‹ 추천'),
                    ),
                    const Spacer(),
                    const Text(
                      '코디 기록',
                      style: TextStyle(
                        color: AppTheme.inkSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          _OutfitSaveResult(
                            feedback: _feedback,
                            memo: _memoController.text,
                          ),
                        );
                      },
                      icon: const Icon(Icons.favorite),
                      color: AppTheme.lavender500,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '이대로 입었어요!',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '추천에서 입은 옷이 자동 연결됐어요',
                  style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
                ),
                const SizedBox(height: 12),
                _SaveOutfitPreview(
                  candidate: widget.candidate,
                  weather: widget.weather,
                  dateLabel: dateLabel,
                ),
                const SizedBox(height: 10),
                _SaveMemoCard(controller: _memoController),
                const SizedBox(height: 10),
                _SaveFeedbackCard(
                  selected: _feedback,
                  onSelected: (feedback) {
                    setState(() => _feedback = feedback);
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _OutfitSaveResult(
                        feedback: _feedback,
                        memo: _memoController.text,
                      ),
                    );
                  },
                  child: const Text('저장'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _todayLabel() {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final now = DateTime.now();
    return '${now.month}월 ${now.day}일 · ${weekdays[now.weekday - 1]}';
  }
}

class _SaveOutfitPreview extends StatelessWidget {
  const _SaveOutfitPreview({
    required this.candidate,
    required this.weather,
    required this.dateLabel,
  });

  final OutfitCandidate candidate;
  final WeatherSnapshot weather;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 118,
              height: 140,
              child: CollagePreviewWidget(items: candidate.items, height: 140),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      color: AppTheme.inkSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _WeatherIcon(condition: weather.condition),
                      const SizedBox(width: 6),
                      Text(
                        '${weather.temp.round()}°',
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      const _MetaTag(label: 'RECOMMENDED'),
                      _MetaTag(label: 'WARMTH ${weather.requiredWarmthBudget}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '연결된 옷 ${candidate.garmentIds.length}벌',
                    style: const TextStyle(
                      color: AppTheme.inkSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveMemoCard extends StatelessWidget {
  const _SaveMemoCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '한 줄 메모 (선택)',
              style: TextStyle(
                color: AppTheme.inkSoft,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextField(
              controller: controller,
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: '예) 미팅에 좋았음, 바람 좀 추웠음',
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(color: AppTheme.ink, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveFeedbackCard extends StatelessWidget {
  const _SaveFeedbackCard({required this.selected, required this.onSelected});

  final OutfitFeedback selected;
  final ValueChanged<OutfitFeedback> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘 코디 어땠어요?',
              style: TextStyle(
                color: AppTheme.inkSoft,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FeedbackButton(
                    label: '아쉬움',
                    icon: Icons.sentiment_dissatisfied_outlined,
                    selected: selected == OutfitFeedback.dislike,
                    onTap: () => onSelected(OutfitFeedback.dislike),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FeedbackButton(
                    label: '좋았음',
                    icon: Icons.sentiment_very_satisfied_outlined,
                    selected: selected == OutfitFeedback.like,
                    onTap: () => onSelected(OutfitFeedback.like),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '추천이 더 정확해져요',
              style: TextStyle(color: AppTheme.inkSoft, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppTheme.lavender50 : AppTheme.surface,
        side: BorderSide(
          color: selected ? AppTheme.ink : AppTheme.line,
          width: selected ? 1.4 : 1,
        ),
      ),
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.lavender50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.lavender600,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
