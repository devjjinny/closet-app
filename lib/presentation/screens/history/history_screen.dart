import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/enums.dart';
import '../../../data/models/garment_model.dart';
import '../../../data/models/outfit_model.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_widgets.dart';

enum _HistoryFilter {
  all('전체'),
  clear('맑음'),
  cloudy('흐림'),
  rainy('비'),
  cold('15° 이하');

  const _HistoryFilter(this.label);

  final String label;
}

enum _HistoryViewMode {
  lookbook('룩북'),
  calendar('캘린더'),
  report('리포트');

  const _HistoryViewMode(this.label);

  final String label;
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _HistoryFilter _selectedFilter = _HistoryFilter.all;
  _HistoryViewMode _viewMode = _HistoryViewMode.lookbook;
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final outfitsAsync = ref.watch(outfitsStreamProvider);
    final garments = ref.watch(garmentsStreamProvider).value ?? [];
    final garmentById = {for (final g in garments) g.id: g};

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: outfitsAsync.buildWidget(
          onRetry: () => ref.refresh(outfitsStreamProvider),
          onData: (outfits) {
            if (outfits.isEmpty) return const _EmptyHistory();
            final filtered = _filterOutfits(outfits);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HistoryHeader(
                  totalCount: outfits.length,
                  visibleCount: filtered.length,
                  selectedFilter: _selectedFilter,
                  viewMode: _viewMode,
                  onViewModeChanged: (mode) {
                    setState(() => _viewMode = mode);
                  },
                ),
                if (_viewMode != _HistoryViewMode.lookbook) ...[
                  const SizedBox(height: 10),
                  _MonthSwitcher(
                    focusedMonth: _focusedMonth,
                    onPrevious: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month - 1,
                        );
                      });
                    },
                    onNext: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month + 1,
                        );
                      });
                    },
                  ),
                ],
                const SizedBox(height: 10),
                _HistoryFilters(
                  selectedFilter: _selectedFilter,
                  onSelected: (filter) {
                    setState(() => _selectedFilter = filter);
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyFilteredHistory(
                          filterLabel: _selectedFilter.label,
                          onClear: () {
                            setState(() {
                              _selectedFilter = _HistoryFilter.all;
                            });
                          },
                        )
                      : _viewMode == _HistoryViewMode.calendar
                      ? _HistoryCalendarView(
                          outfits: filtered,
                          garmentById: garmentById,
                          focusedMonth: _focusedMonth,
                        )
                      : _viewMode == _HistoryViewMode.report
                      ? _HistoryReportView(
                          outfits: filtered,
                          allOutfits: outfits,
                          garments: garments,
                          garmentById: garmentById,
                          focusedMonth: _focusedMonth,
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final outfit = filtered[index];
                            final outfitGarments = outfit.items
                                .map((id) => garmentById[id])
                                .whereType<GarmentModel>()
                                .toList();

                            return _OutfitHistoryCard(
                              outfit: outfit,
                              garments: outfitGarments,
                              onToggleFavorite: () {
                                final next =
                                    outfit.feedback == OutfitFeedback.like
                                    ? OutfitFeedback.dislike
                                    : OutfitFeedback.like;
                                ref
                                    .read(outfitRepositoryProvider)
                                    .updateFeedback(outfit.id, next);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<OutfitModel> _filterOutfits(List<OutfitModel> outfits) {
    return outfits.where((outfit) {
      final weather = outfit.weatherSnapshot;
      switch (_selectedFilter) {
        case _HistoryFilter.all:
          return true;
        case _HistoryFilter.clear:
          return weather.condition == 'Clear';
        case _HistoryFilter.cloudy:
          return weather.condition == 'Clouds';
        case _HistoryFilter.rainy:
          return weather.isRainy ||
              weather.condition == 'Rain' ||
              weather.condition == 'Drizzle' ||
              weather.condition == 'Thunderstorm';
        case _HistoryFilter.cold:
          return weather.feelsLike <= 15;
      }
    }).toList();
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.totalCount,
    required this.visibleCount,
    required this.selectedFilter,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  final int totalCount;
  final int visibleCount;
  final _HistoryFilter selectedFilter;
  final _HistoryViewMode viewMode;
  final ValueChanged<_HistoryViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '코디 기록',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _subtitle,
                  style: const TextStyle(color: AppTheme.inkSoft, fontSize: 11),
                ),
              ),
              _HistoryViewToggle(
                selectedMode: viewMode,
                onSelected: onViewModeChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _subtitle {
    if (selectedFilter == _HistoryFilter.all) {
      return '$totalCount개 코디 · 이번 달';
    }
    return '${selectedFilter.label} $visibleCount개 · 전체 $totalCount개';
  }
}

class _HistoryViewToggle extends StatelessWidget {
  const _HistoryViewToggle({
    required this.selectedMode,
    required this.onSelected,
  });

  final _HistoryViewMode selectedMode;
  final ValueChanged<_HistoryViewMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _HistoryViewMode.values.map((mode) {
          final selected = mode == selectedMode;
          return GestureDetector(
            onTap: () => onSelected(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppTheme.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                mode.label,
                style: TextStyle(
                  color: selected ? AppTheme.surface : AppTheme.inkSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.focusedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime focusedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _MonthButton(icon: Icons.chevron_left, onTap: onPrevious),
          Expanded(
            child: Text(
              '${focusedMonth.year} · ${focusedMonth.month}월',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _MonthButton(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.line),
        ),
        child: Icon(icon, color: AppTheme.ink, size: 20),
      ),
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({
    required this.selectedFilter,
    required this.onSelected,
  });

  final _HistoryFilter selectedFilter;
  final ValueChanged<_HistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: _HistoryFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = _HistoryFilter.values[index];
          final selected = filter == selectedFilter;
          return GestureDetector(
            onTap: () => onSelected(filter),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? AppTheme.ink : AppTheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? AppTheme.ink : AppTheme.line,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Text(
                  filter.label,
                  style: TextStyle(
                    color: selected ? AppTheme.surface : AppTheme.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCalendarView extends StatelessWidget {
  const _HistoryCalendarView({
    required this.outfits,
    required this.garmentById,
    required this.focusedMonth,
  });

  final List<OutfitModel> outfits;
  final Map<String, GarmentModel> garmentById;
  final DateTime focusedMonth;

  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final monthOutfits = _outfitsByDay;
    final days = _calendarDays;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: _weekdays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: AppTheme.inkSoft,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final entries = day == null
                    ? const <OutfitModel>[]
                    : monthOutfits[day.day] ?? const <OutfitModel>[];

                return _CalendarDayCell(
                  day: day,
                  outfits: entries,
                  garments: entries.isEmpty
                      ? const <GarmentModel>[]
                      : entries.first.items
                            .map((id) => garmentById[id])
                            .whereType<GarmentModel>()
                            .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _CalendarMonthSummary(
            outfitCount: monthOutfits.values.fold<int>(
              0,
              (sum, entries) => sum + entries.length,
            ),
          ),
        ],
      ),
    );
  }

  Map<int, List<OutfitModel>> get _outfitsByDay {
    final grouped = <int, List<OutfitModel>>{};
    for (final outfit in outfits) {
      final date = _dateForOutfit(outfit);
      if (date.year != focusedMonth.year || date.month != focusedMonth.month) {
        continue;
      }
      grouped.putIfAbsent(date.day, () => []).add(outfit);
    }
    for (final entries in grouped.values) {
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return grouped;
  }

  List<DateTime?> get _calendarDays {
    final first = DateTime(focusedMonth.year, focusedMonth.month);
    final last = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final slots = <DateTime?>[];

    for (var i = 0; i < first.weekday % 7; i += 1) {
      slots.add(null);
    }
    for (var day = 1; day <= last.day; day += 1) {
      slots.add(DateTime(focusedMonth.year, focusedMonth.month, day));
    }
    while (slots.length % 7 != 0) {
      slots.add(null);
    }
    while (slots.length < 35) {
      slots.add(null);
    }

    return slots;
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.outfits,
    required this.garments,
  });

  final DateTime? day;
  final List<OutfitModel> outfits;
  final List<GarmentModel> garments;

  bool get _isToday {
    if (day == null) return false;
    final now = DateTime.now();
    return day!.year == now.year &&
        day!.month == now.month &&
        day!.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final hasOutfit = outfits.isNotEmpty;
    final outfit = hasOutfit ? outfits.first : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasOutfit ? AppTheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _isToday ? AppTheme.ink : Colors.transparent,
          width: _isToday ? 1.3 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: day == null
            ? const SizedBox.shrink()
            : Column(
                children: [
                  Text(
                    '${day!.day}',
                    style: TextStyle(
                      color: hasOutfit ? AppTheme.ink : AppTheme.muted,
                      fontSize: 9,
                      fontWeight: _isToday ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  if (outfit != null) ...[
                    const SizedBox(height: 2),
                    Expanded(
                      child: _CalendarOutfitThumb(
                        outfit: outfit,
                        garments: garments,
                      ),
                    ),
                  ] else
                    const Spacer(),
                ],
              ),
      ),
    );
  }
}

class _CalendarOutfitThumb extends StatelessWidget {
  const _CalendarOutfitThumb({required this.outfit, required this.garments});

  final OutfitModel outfit;
  final List<GarmentModel> garments;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.lavender50,
          border: Border.all(color: AppTheme.line),
        ),
        child: outfit.collagePath != null && outfit.collagePath!.isNotEmpty
            ? Image.file(
                File(outfit.collagePath!),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _TinyGarmentGrid(garments: garments),
              )
            : _TinyGarmentGrid(garments: garments),
      ),
    );
  }
}

class _TinyGarmentGrid extends StatelessWidget {
  const _TinyGarmentGrid({required this.garments});

  final List<GarmentModel> garments;

  @override
  Widget build(BuildContext context) {
    if (garments.isEmpty) {
      return const Center(
        child: Icon(Icons.checkroom_outlined, size: 12, color: AppTheme.muted),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: garments.take(4).length,
      itemBuilder: (context, index) {
        final garment = garments[index];
        final thumbPath = garment.image.thumbPath;
        return ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: thumbPath.isNotEmpty
              ? Image.file(
                  File(thumbPath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _CategoryIcon(garment.category),
                )
              : _CategoryIcon(garment.category),
        );
      },
    );
  }
}

class _CalendarMonthSummary extends StatelessWidget {
  const _CalendarMonthSummary({required this.outfitCount});

  final int outfitCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppTheme.inkSoft,
              size: 15,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                outfitCount == 0 ? '이 달에 저장된 코디가 없어요' : '이번 달 $outfitCount개 코디',
                style: const TextStyle(
                  color: AppTheme.inkSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryReportView extends StatelessWidget {
  const _HistoryReportView({
    required this.outfits,
    required this.allOutfits,
    required this.garments,
    required this.garmentById,
    required this.focusedMonth,
  });

  final List<OutfitModel> outfits;
  final List<OutfitModel> allOutfits;
  final List<GarmentModel> garments;
  final Map<String, GarmentModel> garmentById;
  final DateTime focusedMonth;

  @override
  Widget build(BuildContext context) {
    final monthOutfits = _monthOutfits;
    final monthDays = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    final mostWorn = _mostWornGarment(monthOutfits);
    final stale = _leastRecentlyWornGarment;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      children: [
        _ReportCountCard(count: monthOutfits.length, monthDays: monthDays),
        const SizedBox(height: 10),
        _InsightCard(
          eyebrow: 'MOST WORN',
          title: mostWorn == null
              ? '이번 달 착용 기록이 아직 적어요'
              : '${_garmentName(mostWorn.garment)} ${mostWorn.count}번 입었어요',
          body: mostWorn == null
              ? '코디를 저장하면 자주 입는 옷을 자동으로 보여줄게요.'
              : '이번 달 기록 기준으로 가장 자주 등장한 아이템이에요.',
          garment: mostWorn?.garment,
        ),
        const SizedBox(height: 10),
        _InsightCard(
          eyebrow: 'CHECK',
          title: stale == null
              ? '옷장 데이터가 더 쌓이면 정리 힌트를 보여줄게요'
              : '${_garmentName(stale.garment)} ${stale.label} 안 입었어요',
          body: stale == null
              ? '착용 기록과 옷장 등록일을 같이 보고 오래 안 입은 옷을 찾습니다.'
              : '계절이 맞지 않거나 손이 안 가는 옷인지 확인해볼 만해요.',
          garment: stale?.garment,
        ),
        const SizedBox(height: 10),
        _ReportWeatherStrip(outfits: monthOutfits),
      ],
    );
  }

  List<OutfitModel> get _monthOutfits {
    return outfits.where((outfit) {
      final date = _dateForOutfit(outfit);
      return date.year == focusedMonth.year && date.month == focusedMonth.month;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  _WornGarment? _mostWornGarment(List<OutfitModel> monthOutfits) {
    final counts = <String, int>{};
    for (final outfit in monthOutfits) {
      for (final id in outfit.items) {
        if (garmentById.containsKey(id)) {
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
    }
    if (counts.isEmpty) return null;

    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final garment = garmentById[top.key];
    if (garment == null) return null;
    return _WornGarment(garment: garment, count: top.value);
  }

  _StaleGarment? get _leastRecentlyWornGarment {
    if (garments.isEmpty) return null;

    final lastWorn = <String, DateTime>{};
    for (final outfit in allOutfits) {
      final date = _dateForOutfit(outfit);
      for (final id in outfit.items) {
        final previous = lastWorn[id];
        if (previous == null || date.isAfter(previous)) {
          lastWorn[id] = date;
        }
      }
    }

    final sorted = [...garments]
      ..sort((a, b) {
        final aDate = lastWorn[a.id] ?? a.createdAt;
        final bDate = lastWorn[b.id] ?? b.createdAt;
        return aDate.compareTo(bDate);
      });
    final garment = sorted.first;
    final lastDate = lastWorn[garment.id];
    final days = DateTime.now()
        .difference(lastDate ?? garment.createdAt)
        .inDays;
    return _StaleGarment(
      garment: garment,
      label: lastDate == null ? '등록 후 아직' : '${days.clamp(0, 999)}일째',
    );
  }

  String _garmentName(GarmentModel garment) {
    if (garment.name != null && garment.name!.trim().isNotEmpty) {
      return garment.name!.trim();
    }
    return switch (garment.category) {
      GarmentCategory.top => '상의',
      GarmentCategory.bottom => '하의',
      GarmentCategory.outer => '아우터',
      GarmentCategory.dress => '원피스',
      GarmentCategory.shoes => '신발',
      GarmentCategory.bag => '가방',
      GarmentCategory.accessory => '액세서리',
    };
  }
}

class _WornGarment {
  const _WornGarment({required this.garment, required this.count});

  final GarmentModel garment;
  final int count;
}

class _StaleGarment {
  const _StaleGarment({required this.garment, required this.label});

  final GarmentModel garment;
  final String label;
}

class _ReportCountCard extends StatelessWidget {
  const _ReportCountCard({required this.count, required this.monthDays});

  final int count;
  final int monthDays;

  @override
  Widget build(BuildContext context) {
    final ratio = monthDays == 0 ? 0.0 : (count / monthDays).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.ink, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기록 횟수',
              style: TextStyle(
                color: AppTheme.inkSoft,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    color: AppTheme.lavender500,
                    fontSize: 42,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '/ $monthDays일',
                    style: const TextStyle(
                      color: AppTheme.inkSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppTheme.lavender50,
                valueColor: const AlwaysStoppedAnimation(AppTheme.lavender500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.garment,
  });

  final String eyebrow;
  final String title;
  final String body;
  final GarmentModel? garment;

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
        child: Row(
          children: [
            _ReportGarmentThumb(garment: garment),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: AppTheme.inkSoft,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppTheme.inkSoft,
                      fontSize: 11,
                      height: 1.3,
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

class _ReportGarmentThumb extends StatelessWidget {
  const _ReportGarmentThumb({this.garment});

  final GarmentModel? garment;

  @override
  Widget build(BuildContext context) {
    final current = garment;
    final thumbPath = current?.image.thumbPath ?? '';

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppTheme.lavender50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: current == null
          ? const Icon(Icons.insights_outlined, color: AppTheme.lavender300)
          : thumbPath.isNotEmpty
          ? Image.file(
              File(thumbPath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _CategoryIcon(current.category),
            )
          : _CategoryIcon(current.category),
    );
  }
}

class _ReportWeatherStrip extends StatelessWidget {
  const _ReportWeatherStrip({required this.outfits});

  final List<OutfitModel> outfits;

  @override
  Widget build(BuildContext context) {
    final averageTemp = outfits.isEmpty
        ? null
        : outfits
                  .map((outfit) => outfit.weatherSnapshot.temp)
                  .reduce((a, b) => a + b) /
              outfits.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.lavender50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            const Icon(Icons.thermostat_outlined, color: AppTheme.inkSoft),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                averageTemp == null
                    ? '이번 달 날씨 기록이 아직 없어요'
                    : '이번 달 저장한 날 평균 ${averageTemp.round()}°',
                style: const TextStyle(
                  color: AppTheme.inkSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _dateForOutfit(OutfitModel outfit) {
  final parts = outfit.dateKey.split('-');
  if (parts.length == 3) {
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }
  return outfit.createdAt;
}

class _OutfitHistoryCard extends StatelessWidget {
  const _OutfitHistoryCard({
    required this.outfit,
    required this.garments,
    required this.onToggleFavorite,
  });

  final OutfitModel outfit;
  final List<GarmentModel> garments;
  final VoidCallback onToggleFavorite;

  bool get _isFavorite => outfit.feedback == OutfitFeedback.like;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                        outfit.collagePath != null &&
                            outfit.collagePath!.isNotEmpty
                        ? Image.file(
                            File(outfit.collagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _LookbookFallback(garments: garments),
                          )
                        : _LookbookFallback(garments: garments),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onToggleFavorite,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _isFavorite
                          ? AppTheme.lavender500
                          : AppTheme.surface.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.ink, width: 1.2),
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? AppTheme.surface : AppTheme.inkSoft,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                _dateLabel,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(_weatherIcon, size: 13, color: AppTheme.inkSoft),
            const SizedBox(width: 3),
            Text(
              '${outfit.weatherSnapshot.temp.round()}°',
              style: const TextStyle(color: AppTheme.inkSoft, fontSize: 10),
            ),
          ],
        ),
        if (garments.isNotEmpty) ...[
          const SizedBox(height: 5),
          _PinTagStrip(garments: garments.take(3).toList()),
        ],
      ],
    );
  }

  String get _dateLabel {
    final parts = outfit.dateKey.split('-');
    if (parts.length == 3) {
      return '${int.tryParse(parts[1]) ?? parts[1]}/${int.tryParse(parts[2]) ?? parts[2]}';
    }
    return outfit.dateKey;
  }

  IconData get _weatherIcon {
    switch (outfit.weatherSnapshot.condition) {
      case 'Clear':
        return Icons.wb_sunny_outlined;
      case 'Rain':
      case 'Drizzle':
        return Icons.water_drop_outlined;
      case 'Snow':
        return Icons.ac_unit;
      default:
        return Icons.cloud_outlined;
    }
  }
}

class _LookbookFallback extends StatelessWidget {
  const _LookbookFallback({required this.garments});

  final List<GarmentModel> garments;

  @override
  Widget build(BuildContext context) {
    if (garments.isEmpty) {
      return const ColoredBox(
        color: AppTheme.lavender50,
        child: Center(
          child: Icon(Icons.checkroom_outlined, color: AppTheme.muted),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(6),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: garments.take(4).length,
        itemBuilder: (context, index) {
          final garment = garments[index];
          final thumbPath = garment.image.thumbPath;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.lavender50,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: AppTheme.line),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: thumbPath.isNotEmpty
                  ? Image.file(
                      File(thumbPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _CategoryIcon(garment.category),
                    )
                  : _CategoryIcon(garment.category),
            ),
          );
        },
      ),
    );
  }
}

class _LegacyOutfitHistoryCard extends StatelessWidget {
  const _LegacyOutfitHistoryCard({
    required this.outfit,
    required this.garments,
    required this.onToggleFavorite,
  });

  final OutfitModel outfit;
  final List<GarmentModel> garments;
  final VoidCallback onToggleFavorite;

  bool get _isFavorite => outfit.feedback == OutfitFeedback.like;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: date, weather, favorite
            Row(
              children: [
                Text(
                  outfit.dateKey,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(_weatherIcon, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 2),
                Text(
                  '${outfit.weatherSnapshot.temp.round()}°C',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onToggleFavorite,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(_isFavorite),
                      color: _isFavorite
                          ? const Color(0xFFE84393)
                          : Colors.grey[400],
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Collage image
            if (outfit.collagePath != null && outfit.collagePath!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(outfit.collagePath!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            // Pin tag strip
            if (garments.isNotEmpty) ...[
              const SizedBox(height: 10),
              _PinTagStrip(garments: garments),
            ],

            // Reasoning
            if (outfit.reasoning != null && outfit.reasoning!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                outfit.reasoning!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _weatherIcon {
    switch (outfit.weatherSnapshot.condition) {
      case 'Clear':
        return Icons.wb_sunny;
      case 'Rain':
      case 'Drizzle':
        return Icons.water_drop;
      case 'Snow':
        return Icons.ac_unit;
      default:
        return Icons.cloud;
    }
  }
}

class _PinTagStrip extends StatelessWidget {
  const _PinTagStrip({required this.garments});
  final List<GarmentModel> garments;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: garments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _PinTagChip(garment: garments[i]),
      ),
    );
  }
}

class _PinTagChip extends StatelessWidget {
  const _PinTagChip({required this.garment});
  final GarmentModel garment;

  @override
  Widget build(BuildContext context) {
    final thumbPath = garment.image.thumbPath;
    final hasThumb = thumbPath.isNotEmpty;

    return Container(
      width: 42,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Garment thumbnail
          if (hasThumb)
            Image.file(
              File(thumbPath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _CategoryIcon(garment.category),
            )
          else
            _CategoryIcon(garment.category),

          // Category label badge
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon(this.category);
  final GarmentCategory category;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(_iconFor(category), size: 16, color: AppTheme.muted)],
    );
  }

  IconData _iconFor(GarmentCategory cat) {
    return switch (cat) {
      GarmentCategory.top => Icons.dry_cleaning,
      GarmentCategory.bottom => Icons.straighten,
      GarmentCategory.outer => Icons.checkroom,
      GarmentCategory.dress => Icons.woman,
      GarmentCategory.shoes => Icons.directions_walk,
      GarmentCategory.bag => Icons.shopping_bag,
      GarmentCategory.accessory => Icons.watch,
    };
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '나의 룩북',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.line),
            ),
            child: const Padding(
              padding: EdgeInsets.all(22),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 56,
                color: AppTheme.lavender300,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '아직 저장된 코디가 없어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '오늘 코디를 저장하면 날씨별 룩북으로 모아볼 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _EmptyFilteredHistory extends StatelessWidget {
  const _EmptyFilteredHistory({
    required this.filterLabel,
    required this.onClear,
  });

  final String filterLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.line),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Icon(
                  Icons.filter_alt_off_outlined,
                  color: AppTheme.lavender300,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '$filterLabel 기록이 없어요',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '다른 날씨 조건으로 다시 볼 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
            ),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onClear, child: const Text('전체 보기')),
          ],
        ),
      ),
    );
  }
}
