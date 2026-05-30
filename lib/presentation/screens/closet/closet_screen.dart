import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/enums.dart';
import '../../../data/models/garment_model.dart';
import '../../../data/models/outfit_model.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_widgets.dart';

enum _ClosetViewMode { grid, analysis }

class ClosetScreen extends ConsumerStatefulWidget {
  const ClosetScreen({super.key});

  @override
  ConsumerState<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends ConsumerState<ClosetScreen> {
  GarmentCategory? _selectedCategory;
  String _query = '';
  _ClosetViewMode _viewMode = _ClosetViewMode.grid;

  @override
  Widget build(BuildContext context) {
    final garmentsAsync = ref.watch(garmentsStreamProvider);
    final outfits = ref.watch(outfitsStreamProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: garmentsAsync.buildWidget(
          onRetry: () => ref.refresh(garmentsStreamProvider),
          onData: (garments) {
            final filtered = garments.where((garment) {
              if (_selectedCategory != null &&
                  garment.category != _selectedCategory) {
                return false;
              }
              final query = _query.trim().toLowerCase();
              if (query.isEmpty) return true;
              final haystack = [
                garment.name,
                garment.category.label,
                garment.subCategory,
                garment.dominantHex,
                ...garment.palette,
                ...garment.styleTags.map((tag) => tag.label),
                ...garment.seasonTags.map((season) => season.label),
                garment.notes,
              ].whereType<String>().join(' ').toLowerCase();
              return haystack.contains(query);
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ClosetHeader(
                  count: garments.length,
                  viewMode: _viewMode,
                  onViewModeChanged: (mode) => setState(() => _viewMode = mode),
                  onAdd: () => context.push('/add-garment'),
                ),
                const SizedBox(height: 10),
                _SearchBox(
                  query: _query,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () => setState(() => _query = ''),
                ),
                const SizedBox(height: 10),
                _CategoryFilters(
                  selectedCategory: _selectedCategory,
                  onSelected: (category) {
                    setState(() => _selectedCategory = category);
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _viewMode == _ClosetViewMode.analysis
                      ? _ClosetAnalysisView(
                          garments: garments,
                          outfits: outfits,
                        )
                      : filtered.isEmpty
                      ? _EmptyState(
                          isFiltered: garments.isNotEmpty,
                          hasQuery: _query.trim().isNotEmpty,
                          onAdd: () => context.push('/add-garment'),
                          onClearFilter: () {
                            setState(() {
                              _selectedCategory = null;
                              _query = '';
                            });
                          },
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _GarmentCard(garment: filtered[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ClosetHeader extends StatelessWidget {
  const _ClosetHeader({
    required this.count,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onAdd,
  });

  final int count;
  final _ClosetViewMode viewMode;
  final ValueChanged<_ClosetViewMode> onViewModeChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '내 옷장',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$count벌',
            style: const TextStyle(
              color: AppTheme.inkSoft,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 10),
          _ClosetModeButton(
            selected: viewMode == _ClosetViewMode.analysis,
            onTap: () => onViewModeChanged(
              viewMode == _ClosetViewMode.analysis
                  ? _ClosetViewMode.grid
                  : _ClosetViewMode.analysis,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.lavender500,
              foregroundColor: AppTheme.surface,
              minimumSize: const Size(36, 36),
              fixedSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosetModeButton extends StatelessWidget {
  const _ClosetModeButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(selected ? Icons.grid_view : Icons.insights_outlined),
      tooltip: selected ? '그리드' : '분석',
      style: IconButton.styleFrom(
        backgroundColor: selected ? AppTheme.ink : AppTheme.surface,
        foregroundColor: selected ? AppTheme.surface : AppTheme.inkSoft,
        side: const BorderSide(color: AppTheme.line),
        minimumSize: const Size(36, 36),
        fixedSize: const Size(36, 36),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.line),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppTheme.muted, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  key: ValueKey(query),
                  initialValue: query,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    hintText: '옷 검색...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (query.isNotEmpty)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 16),
                  color: AppTheme.muted,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.selectedCategory,
    required this.onSelected,
  });

  final GarmentCategory? selectedCategory;
  final void Function(GarmentCategory?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _FilterPill(
            label: '전체',
            selected: selectedCategory == null,
            onTap: () => onSelected(null),
          ),
          ...GarmentCategory.values.map(
            (cat) => _FilterPill(
              label: _categoryShortLabel(cat),
              selected: selectedCategory == cat,
              onTap: () => onSelected(cat),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryShortLabel(GarmentCategory category) {
    switch (category) {
      case GarmentCategory.outer:
        return '외투';
      case GarmentCategory.accessory:
        return '악세';
      default:
        return category.label;
    }
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
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
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppTheme.ink : AppTheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? AppTheme.ink : AppTheme.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.surface : AppTheme.inkSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _GarmentCard extends StatelessWidget {
  const _GarmentCard({required this.garment});

  final GarmentModel garment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.line),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: garment.image.thumbPath.isNotEmpty
                  ? Image.file(
                      File(garment.image.thumbPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _GarmentFallback(),
                    )
                  : const _GarmentFallback(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _parseColor(garment.dominantHex),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.line),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                garment.name ?? garment.category.label,
                style: const TextStyle(
                  color: AppTheme.inkSoft,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'WARMTH ${garment.warmth}',
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return AppTheme.muted;
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

class _ClosetAnalysisView extends StatelessWidget {
  const _ClosetAnalysisView({required this.garments, required this.outfits});

  final List<GarmentModel> garments;
  final List<OutfitModel> outfits;

  @override
  Widget build(BuildContext context) {
    if (garments.isEmpty) {
      return const Center(
        child: Text(
          '옷을 등록하면 워드로브 분석을 볼 수 있어요.',
          style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
        ),
      );
    }

    final categoryCounts = <GarmentCategory, int>{};
    final colorCounts = <String, int>{};
    for (final garment in garments) {
      categoryCounts[garment.category] =
          (categoryCounts[garment.category] ?? 0) + 1;
      colorCounts[garment.dominantHex] =
          (colorCounts[garment.dominantHex] ?? 0) + 1;
    }
    final topCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final wearStats = _wearStats;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
      children: [
        _AnalysisCard(
          title: '컬러 톤',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: topColors.take(8).map((entry) {
              return _ColorSwatchPill(hex: entry.key, count: entry.value);
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        _AnalysisCard(
          title: '카테고리 구성',
          child: Column(
            children: topCategories.map((entry) {
              return _CategoryBar(
                category: entry.key,
                count: entry.value,
                total: garments.length,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        _AnalysisCard(
          title: '착용 빈도',
          child: Column(
            children: garments.take(20).map((garment) {
              final stat = wearStats[garment.id];
              return _WearStatRow(
                garment: garment,
                count: stat?.count ?? 0,
                lastWorn: stat?.lastWorn,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Map<String, _WearStat> get _wearStats {
    final stats = <String, _WearStat>{};
    for (final outfit in outfits) {
      final date = _dateForOutfit(outfit);
      for (final id in outfit.items) {
        final current = stats[id] ?? const _WearStat(count: 0);
        stats[id] = _WearStat(
          count: current.count + 1,
          lastWorn: current.lastWorn == null || date.isAfter(current.lastWorn!)
              ? date
              : current.lastWorn,
        );
      }
    }
    return stats;
  }
}

class _WearStat {
  const _WearStat({required this.count, this.lastWorn});

  final int count;
  final DateTime? lastWorn;
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ColorSwatchPill extends StatelessWidget {
  const _ColorSwatchPill({required this.hex, required this.count});

  final String hex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.lavender50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _parseHex(hex),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.line),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count벌',
              style: const TextStyle(
                color: AppTheme.inkSoft,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.count,
    required this.total,
  });

  final GarmentCategory category;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.label,
                  style: const TextStyle(
                    color: AppTheme.inkSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$count벌',
                style: const TextStyle(color: AppTheme.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: AppTheme.lavender50,
              valueColor: const AlwaysStoppedAnimation(AppTheme.lavender500),
            ),
          ),
        ],
      ),
    );
  }
}

class _WearStatRow extends StatelessWidget {
  const _WearStatRow({
    required this.garment,
    required this.count,
    required this.lastWorn,
  });

  final GarmentModel garment;
  final int count;
  final DateTime? lastWorn;

  @override
  Widget build(BuildContext context) {
    final thumbPath = garment.image.thumbPath;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.lavender50,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppTheme.line),
            ),
            child: thumbPath.isNotEmpty
                ? Image.file(
                    File(thumbPath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _GarmentFallback(),
                  )
                : const _GarmentFallback(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garment.name ?? garment.category.label,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastWorn == null
                      ? '아직 착용 기록 없음'
                      : '마지막 착용 ${lastWorn!.month}/${lastWorn!.day}',
                  style: const TextStyle(color: AppTheme.inkSoft, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '$count회',
            style: const TextStyle(
              color: AppTheme.lavender600,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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

Color _parseHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length != 6) return AppTheme.muted;
  return Color(int.parse('FF$cleaned', radix: 16));
}

class _GarmentFallback extends StatelessWidget {
  const _GarmentFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.lavender50,
      child: Center(
        child: Icon(
          Icons.checkroom_outlined,
          color: AppTheme.lavender300.withValues(alpha: 0.9),
          size: 24,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isFiltered,
    required this.hasQuery,
    required this.onAdd,
    required this.onClearFilter,
  });

  final bool isFiltered;
  final bool hasQuery;
  final VoidCallback onAdd;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    if (isFiltered) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasQuery ? '검색 결과가 없어요' : '이 카테고리는 비어있어요',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasQuery ? '검색어를 지우거나 다른 조건으로 볼 수 있어요.' : '전체 옷장에서 다시 볼 수 있어요.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.inkSoft, fontSize: 12),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onClearFilter,
                child: const Text('전체 보기'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Icon(
                  Icons.checkroom_outlined,
                  size: 64,
                  color: AppTheme.lavender300.withValues(alpha: 0.95),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '옷장이 비었어요.\n한 벌만 등록해볼까요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 22,
                height: 1.18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '사진 1장이면 끝.\n배경은 자동으로 지워드릴게요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.inkSoft,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('첫 옷 등록하기'),
            ),
          ],
        ),
      ),
    );
  }
}
