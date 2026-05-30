import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/garment_model.dart';
import '../../../data/models/outfit_model.dart';
import '../../../data/models/weather_snapshot.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_widgets.dart';

class SaveOutfitScreen extends ConsumerStatefulWidget {
  const SaveOutfitScreen({super.key});

  @override
  ConsumerState<SaveOutfitScreen> createState() => _SaveOutfitScreenState();
}

class _SaveOutfitScreenState extends ConsumerState<SaveOutfitScreen> {
  final Set<String> _selectedIds = {};
  GarmentCategory? _selectedCategory;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final garmentsAsync = ref.watch(garmentsStreamProvider);
    final weather =
        ref.watch(currentWeatherProvider).value ?? WeatherSnapshot.fallback();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: garmentsAsync.buildWidget(
          onRetry: () => ref.refresh(garmentsStreamProvider),
          onData: (garments) {
            final filtered = _selectedCategory == null
                ? garments
                : garments
                      .where((g) => g.category == _selectedCategory)
                      .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SaveHeader(
                  selectedCount: _selectedIds.length,
                  onClose: () => context.pop(),
                ),
                const SizedBox(height: 10),
                _WeatherLine(weather: weather),
                const SizedBox(height: 10),
                _SaveCategoryFilters(
                  selectedCategory: _selectedCategory,
                  onSelected: (category) {
                    setState(() => _selectedCategory = category);
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptySaveCloset(
                          onAdd: () => context.push('/add-garment'),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.78,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final garment = filtered[index];
                            final selected = _selectedIds.contains(garment.id);
                            return _SelectableGarmentCard(
                              garment: garment,
                              selected: selected,
                              onTap: () => _toggle(garment.id),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => context.push('/save-ootd'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(Icons.add_a_photo_outlined),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedIds.isEmpty || _saving
                              ? null
                              : () => _save(garments, weather),
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.favorite),
                          label: Text(
                            _selectedIds.isEmpty
                                ? '입은 옷을 선택해 주세요'
                                : '${_selectedIds.length}벌 코디로 저장',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _save(
    List<GarmentModel> garments,
    WeatherSnapshot weather,
  ) async {
    setState(() => _saving = true);
    try {
      final selected = garments
          .where((garment) => _selectedIds.contains(garment.id))
          .toList();
      final cutoutPaths = <GarmentCategory, String>{};
      for (final garment in selected) {
        cutoutPaths[garment.category] = garment.image.cutoutPath;
      }
      final collageFile = await ref
          .read(collageServiceProvider)
          .generateCollageFromPaths(cutoutPaths);
      final outfit = OutfitModel(
        id: '',
        dateKey: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        items: selected.map((g) => g.id).toList(),
        weatherSnapshot: weather,
        createdAt: DateTime.now(),
        feedback: OutfitFeedback.like,
        reasoning: '옷장에서 직접 선택한 오늘 코디',
      );
      await ref
          .read(outfitRepositoryProvider)
          .saveOutfit(outfit: outfit, collageFile: collageFile);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('오늘 입은 코디가 저장되었어요.')));
      context.go('/history');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SaveHeader extends StatelessWidget {
  const _SaveHeader({required this.selectedCount, required this.onClose});

  final int selectedCount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        children: [
          TextButton(onPressed: onClose, child: const Text('‹ 취소')),
          const Spacer(),
          const Text(
            '오늘 입은 옷 고르기',
            style: TextStyle(
              color: AppTheme.inkSoft,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            selectedCount == 0 ? '선택' : '$selectedCount ✓',
            style: const TextStyle(
              color: AppTheme.lavender600,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherLine extends StatelessWidget {
  const _WeatherLine({required this.weather});

  final WeatherSnapshot weather;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${DateTime.now().month}/${DateTime.now().day} · ${weather.temp.round()}° ${_conditionLabel}',
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(_weatherIcon, color: AppTheme.ink, size: 26),
        ],
      ),
    );
  }

  String get _conditionLabel {
    return switch (weather.condition) {
      'Clear' => '맑음',
      'Rain' => '비',
      'Drizzle' => '이슬비',
      'Snow' => '눈',
      'Thunderstorm' => '천둥',
      _ => '흐림',
    };
  }

  IconData get _weatherIcon {
    return switch (weather.condition) {
      'Clear' => Icons.wb_sunny_outlined,
      'Rain' || 'Drizzle' => Icons.water_drop_outlined,
      'Snow' => Icons.ac_unit,
      'Thunderstorm' => Icons.flash_on_outlined,
      _ => Icons.cloud_outlined,
    };
  }
}

class _SaveCategoryFilters extends StatelessWidget {
  const _SaveCategoryFilters({
    required this.selectedCategory,
    required this.onSelected,
  });

  final GarmentCategory? selectedCategory;
  final ValueChanged<GarmentCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: [
          _SaveFilterPill(
            label: '전체',
            selected: selectedCategory == null,
            onTap: () => onSelected(null),
          ),
          ...GarmentCategory.values.map(
            (category) => _SaveFilterPill(
              label: category == GarmentCategory.outer
                  ? '외투'
                  : category == GarmentCategory.accessory
                  ? '악세'
                  : category.label,
              selected: selectedCategory == category,
              onTap: () => onSelected(category),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveFilterPill extends StatelessWidget {
  const _SaveFilterPill({
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

class _SelectableGarmentCard extends StatelessWidget {
  const _SelectableGarmentCard({
    required this.garment,
    required this.selected,
    required this.onTap,
  });

  final GarmentModel garment;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbPath = garment.image.thumbPath;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? AppTheme.lavender500 : AppTheme.line,
                      width: selected ? 2.4 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: thumbPath.isNotEmpty
                        ? Image.file(
                            File(thumbPath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _GarmentIcon(garment.category),
                          )
                        : _GarmentIcon(garment.category),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                garment.name ?? garment.category.label,
                style: const TextStyle(
                  color: AppTheme.inkSoft,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          if (selected)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppTheme.lavender500,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.ink, width: 1.3),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppTheme.surface,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GarmentIcon extends StatelessWidget {
  const _GarmentIcon(this.category);

  final GarmentCategory category;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.lavender50,
      child: Center(
        child: Icon(
          switch (category) {
            GarmentCategory.top => Icons.dry_cleaning,
            GarmentCategory.bottom => Icons.straighten,
            GarmentCategory.outer => Icons.checkroom,
            GarmentCategory.dress => Icons.woman,
            GarmentCategory.shoes => Icons.directions_walk,
            GarmentCategory.bag => Icons.shopping_bag,
            GarmentCategory.accessory => Icons.watch,
          },
          color: AppTheme.muted,
          size: 22,
        ),
      ),
    );
  }
}

class _EmptySaveCloset extends StatelessWidget {
  const _EmptySaveCloset({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '고를 옷이 없어요',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '먼저 옷을 등록하면 오늘 입은 코디로 저장할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('옷 등록'),
            ),
          ],
        ),
      ),
    );
  }
}
