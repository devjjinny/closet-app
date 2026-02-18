import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/enums.dart';
import '../../../data/models/garment_model.dart';
import '../../providers/providers.dart';

class ClosetScreen extends ConsumerStatefulWidget {
  const ClosetScreen({super.key});

  @override
  ConsumerState<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends ConsumerState<ClosetScreen> {
  GarmentCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final garmentsAsync = ref.watch(garmentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 옷장'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/add-garment'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: '전체',
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...GarmentCategory.values.map((cat) => _FilterChip(
                      label: cat.label,
                      selected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    )),
              ],
            ),
          ),
          // Garment grid
          Expanded(
            child: garmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (garments) {
                final filtered = _selectedCategory != null
                    ? garments
                        .where((g) => g.category == _selectedCategory)
                        .toList()
                    : garments;

                if (filtered.isEmpty) {
                  return _EmptyState(
                    onAdd: () => context.push('/add-garment'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _GarmentCard(garment: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
        checkmarkColor: const Color(0xFF6C5CE7),
      ),
    );
  }
}

class _GarmentCard extends StatelessWidget {
  const _GarmentCard({required this.garment});

  final GarmentModel garment;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: garment.image.thumbUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: garment.image.thumbUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[100],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey[100],
                    child: const Icon(Icons.checkroom, color: Colors.grey),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _parseColor(garment.dominantHex),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    garment.category.label,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return Colors.grey;
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '옷장이 비어있어요',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 옷을 등록해보세요',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('옷 등록하기'),
          ),
        ],
      ),
    );
  }
}
