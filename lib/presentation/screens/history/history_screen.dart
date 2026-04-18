import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/enums.dart';
import '../../../data/models/outfit_model.dart';
import '../../providers/providers.dart';
import '../../widgets/async_widgets.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsAsync = ref.watch(outfitsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('코디 기록')),
      body: outfitsAsync.buildWidget(
        onRetry: () => ref.refresh(outfitsStreamProvider),
        onData: (outfits) {
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
            itemBuilder: (context, index) {
              final outfit = outfits[index];
              return Dismissible(
                key: ValueKey(outfit.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.white, size: 28),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('코디 삭제'),
                      content: const Text('이 코디 기록을 삭제할까요?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('삭제',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  final uid = ref.read(currentUidProvider);
                  if (uid == null) return;
                  ref
                      .read(outfitRepositoryProvider)
                      .deleteOutfit(uid, outfit.id);
                },
                child: _OutfitHistoryCard(
                  outfit: outfit,
                  onToggleFavorite: () {
                    final uid = ref.read(currentUidProvider);
                    if (uid == null) return;
                    final next = outfit.feedback == OutfitFeedback.like
                        ? OutfitFeedback.dislike
                        : OutfitFeedback.like;
                    ref.read(outfitRepositoryProvider).updateFeedback(
                          uid,
                          outfit.id,
                          next,
                        );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OutfitHistoryCard extends StatelessWidget {
  const _OutfitHistoryCard({
    required this.outfit,
    required this.onToggleFavorite,
  });

  final OutfitModel outfit;
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
            // 날짜 + 날씨 + 즐겨찾기
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

            // 콜라주 이미지
            if (outfit.resultImageUrl != null &&
                outfit.resultImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: outfit.resultImageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 180,
                    color: Colors.grey[100],
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 60,
                    color: Colors.grey[100],
                    child: Center(
                      child: Text(
                        '아이템 ${outfit.items.length}개',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '아이템 ${outfit.items.length}개',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ),
              ),

            // 추천 이유
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

