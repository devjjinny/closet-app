import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/enums.dart';
import '../../../data/models/outfit_model.dart';
import '../../providers/providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsAsync = ref.watch(outfitsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('코디 기록')),
      body: outfitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (outfits) {
          if (outfits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '아직 저장된 코디가 없어요',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: outfits.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _OutfitHistoryCard(
              outfit: outfits[index],
              onFeedback: (feedback) {
                final uid = ref.read(currentUidProvider);
                if (uid == null) return;
                ref.read(outfitRepositoryProvider).updateFeedback(
                      uid,
                      outfits[index].id,
                      feedback,
                    );
              },
            ),
          );
        },
      ),
    );
  }
}

class _OutfitHistoryCard extends StatelessWidget {
  const _OutfitHistoryCard({
    required this.outfit,
    required this.onFeedback,
  });

  final OutfitModel outfit;
  final ValueChanged<OutfitFeedback> onFeedback;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & weather summary
            Row(
              children: [
                Text(
                  outfit.dateKey,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(_weatherIcon, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${outfit.weatherSnapshot.temp.round()}°C',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Collage image
            if (outfit.resultImageUrl != null &&
                outfit.resultImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: outfit.resultImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            // Item count
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '아이템 ${outfit.items.length}개',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),

            // Reasoning
            if (outfit.reasoning != null && outfit.reasoning!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  outfit.reasoning!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),

            // Feedback buttons
            Row(
              children: [
                _FeedbackButton(
                  icon: Icons.thumb_up_outlined,
                  activeIcon: Icons.thumb_up,
                  label: '좋아요',
                  isActive: outfit.feedback == OutfitFeedback.like,
                  color: Colors.green,
                  onTap: () => onFeedback(OutfitFeedback.like),
                ),
                const SizedBox(width: 8),
                _FeedbackButton(
                  icon: Icons.thumb_down_outlined,
                  activeIcon: Icons.thumb_down,
                  label: '별로',
                  isActive: outfit.feedback == OutfitFeedback.dislike,
                  color: Colors.red,
                  onTap: () => onFeedback(OutfitFeedback.dislike),
                ),
              ],
            ),
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

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 16,
              color: isActive ? color : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
