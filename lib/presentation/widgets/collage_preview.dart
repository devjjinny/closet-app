import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/enums.dart';
import '../../data/models/garment_model.dart';
import '../theme/app_theme.dart';

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
    final rightBottom =
        items[GarmentCategory.accessory] ?? items[GarmentCategory.bag];

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
  const _CollageSlot({required this.label, required this.icon, this.garment});

  final GarmentModel? garment;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final path = garment?.image.thumbPath ?? '';
    final hasImage = path.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lavender50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      _Placeholder(label: label, icon: icon),
                ),
                if (garment!.name != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 4,
                      ),
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
        Icon(icon, size: 22, color: AppTheme.muted),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
