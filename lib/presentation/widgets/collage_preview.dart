import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/enums.dart';
import '../../data/models/garment_model.dart';

/// 코디 콜라주 미리보기 위젯
/// 왼쪽 3칸(상의/하의/신발) + 오른쪽 2칸(아우터/악세서리)
class CollagePreviewWidget extends StatelessWidget {
  const CollagePreviewWidget({
    super.key,
    required this.items,
    this.height = 280,
  });

  final Map<GarmentCategory, GarmentModel> items;
  final double height;

  @override
  Widget build(BuildContext context) {
    // 오른쪽 칸 우선순위: outer → accessory → bag
    final rightBottom = items[GarmentCategory.accessory] ??
        items[GarmentCategory.bag];

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 왼쪽: 상의 / 하의 / 신발 (3등분)
          Expanded(
            flex: 55,
            child: Column(
              children: [
                _CollageSlot(
                  garment: items[GarmentCategory.top],
                  label: '상의',
                  icon: Icons.dry_cleaning,
                ),
                const SizedBox(height: 4),
                _CollageSlot(
                  garment: items[GarmentCategory.bottom],
                  label: '하의',
                  icon: Icons.straighten,
                ),
                const SizedBox(height: 4),
                _CollageSlot(
                  garment: items[GarmentCategory.shoes],
                  label: '신발',
                  icon: Icons.directions_walk,
                ),
              ].map((w) => Expanded(child: w)).toList(),
            ),
          ),
          const SizedBox(width: 4),
          // 오른쪽: 아우터 / 악세서리 (2등분)
          Expanded(
            flex: 38,
            child: Column(
              children: [
                _CollageSlot(
                  garment: items[GarmentCategory.outer],
                  label: '아우터',
                  icon: Icons.checkroom,
                ),
                const SizedBox(height: 4),
                _CollageSlot(
                  garment: rightBottom,
                  label: '악세서리',
                  icon: Icons.watch,
                ),
              ].map((w) => Expanded(child: w)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollageSlot extends StatelessWidget {
  const _CollageSlot({
    required this.label,
    required this.icon,
    this.garment,
  });

  final GarmentModel? garment;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        garment != null && garment!.image.thumbUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: garment!.image.thumbUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => _Placeholder(label: label, icon: icon),
                  errorWidget: (_, __, ___) =>
                      _Placeholder(label: label, icon: icon),
                ),
                // 이름 라벨 (하단)
                if (garment!.name != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 4),
                      color: Colors.black.withValues(alpha: 0.35),
                      child: Text(
                        garment!.name!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            )
          : _Placeholder(label: label, icon: icon),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
        ),
      ],
    );
  }
}
