import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/garment_model.dart';
import '../../../data/models/outfit_model.dart';
import '../../../data/models/weather_snapshot.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_widgets.dart';

class OotdPinSaveScreen extends ConsumerStatefulWidget {
  const OotdPinSaveScreen({super.key});

  @override
  ConsumerState<OotdPinSaveScreen> createState() => _OotdPinSaveScreenState();
}

class _OotdPinSaveScreenState extends ConsumerState<OotdPinSaveScreen> {
  final _picker = ImagePicker();
  final List<_OotdPin> _pins = [];
  File? _photo;
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PinHeader(
                  onClose: () => context.pop(),
                  onSave: _photo == null || _pins.isEmpty || _saving
                      ? null
                      : () => _save(garments, weather),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    '오늘 사진에 옷 핀 찍기',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    '사진을 고르고 탭하면 내 옷장에서 매칭해요',
                    style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _PhotoPinCanvas(
                      photo: _photo,
                      pins: _pins,
                      garments: garments,
                      onPickPhoto: _pickPhoto,
                      onTapPhoto: (offset) => _addPin(offset, garments),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _PinSummary(pins: _pins, garments: garments),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: ElevatedButton.icon(
                    onPressed: _photo == null || _pins.isEmpty || _saving
                        ? null
                        : () => _save(garments, weather),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.push_pin_outlined),
                    label: Text(
                      _pins.isEmpty ? '핀을 추가해 주세요' : '${_pins.length}개 핀으로 저장',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('카메라'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('앨범'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, maxWidth: 2048);
    if (picked == null) return;
    setState(() {
      _photo = File(picked.path);
      _pins.clear();
    });
  }

  Future<void> _addPin(
    Offset relativeOffset,
    List<GarmentModel> garments,
  ) async {
    if (_photo == null || garments.isEmpty) return;
    final garment = await showModalBottomSheet<GarmentModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bg,
      builder: (context) => _GarmentPickerSheet(garments: garments),
    );
    if (garment == null) return;
    setState(() {
      _pins.add(
        _OotdPin(
          index: _pins.length + 1,
          x: relativeOffset.dx.clamp(0.0, 1.0),
          y: relativeOffset.dy.clamp(0.0, 1.0),
          garmentId: garment.id,
        ),
      );
    });
  }

  Future<void> _save(
    List<GarmentModel> garments,
    WeatherSnapshot weather,
  ) async {
    final photo = _photo;
    if (photo == null) return;
    setState(() => _saving = true);
    try {
      final garmentById = {for (final garment in garments) garment.id: garment};
      final names = _pins
          .map(
            (pin) =>
                garmentById[pin.garmentId]?.name ??
                garmentById[pin.garmentId]?.category.label ??
                '옷',
          )
          .join(', ');
      final outfit = OutfitModel(
        id: '',
        dateKey: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        items: _pins.map((pin) => pin.garmentId).toSet().toList(),
        weatherSnapshot: weather,
        createdAt: DateTime.now(),
        feedback: OutfitFeedback.like,
        reasoning: 'OOTD 사진 핀 태그: $names',
      );
      await ref
          .read(outfitRepositoryProvider)
          .saveOutfit(outfit: outfit, collageFile: photo);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OOTD 기록이 저장되었어요.')));
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

class _OotdPin {
  const _OotdPin({
    required this.index,
    required this.x,
    required this.y,
    required this.garmentId,
  });

  final int index;
  final double x;
  final double y;
  final String garmentId;
}

class _PinHeader extends StatelessWidget {
  const _PinHeader({required this.onClose, required this.onSave});

  final VoidCallback onClose;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        children: [
          TextButton(onPressed: onClose, child: const Text('‹ 취소')),
          const Spacer(),
          const Text(
            '오늘 입은 코디',
            style: TextStyle(
              color: AppTheme.inkSoft,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          TextButton(onPressed: onSave, child: const Text('저장')),
        ],
      ),
    );
  }
}

class _PhotoPinCanvas extends StatelessWidget {
  const _PhotoPinCanvas({
    required this.photo,
    required this.pins,
    required this.garments,
    required this.onPickPhoto,
    required this.onTapPhoto,
  });

  final File? photo;
  final List<_OotdPin> pins;
  final List<GarmentModel> garments;
  final VoidCallback onPickPhoto;
  final ValueChanged<Offset> onTapPhoto;

  @override
  Widget build(BuildContext context) {
    final currentPhoto = photo;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: currentPhoto == null
            ? InkWell(
                onTap: onPickPhoto,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: AppTheme.lavender300,
                        size: 54,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'OOTD 사진 선택',
                        style: TextStyle(
                          color: AppTheme.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) {
                      onTapPhoto(
                        Offset(
                          details.localPosition.dx / constraints.maxWidth,
                          details.localPosition.dy / constraints.maxHeight,
                        ),
                      );
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(currentPhoto, fit: BoxFit.cover),
                        ...pins.map(
                          (pin) => Positioned(
                            left: pin.x * constraints.maxWidth - 14,
                            top: pin.y * constraints.maxHeight - 14,
                            child: _PinMarker(index: pin.index),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.ink,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Text(
                                '+ 탭해서 핀',
                                style: TextStyle(
                                  color: AppTheme.surface,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _PinMarker extends StatelessWidget {
  const _PinMarker({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.lavender300,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.ink, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$index',
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PinSummary extends StatelessWidget {
  const _PinSummary({required this.pins, required this.garments});

  final List<_OotdPin> pins;
  final List<GarmentModel> garments;

  @override
  Widget build(BuildContext context) {
    final garmentById = {for (final garment in garments) garment.id: garment};
    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: pins.isEmpty ? 1 : pins.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (pins.isEmpty) {
            return const Center(
              child: Text(
                '매칭된 핀이 아직 없어요',
                style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
              ),
            );
          }
          final pin = pins[index];
          final garment = garmentById[pin.garmentId];
          return _PinnedGarmentChip(pin: pin, garment: garment);
        },
      ),
    );
  }
}

class _PinnedGarmentChip extends StatelessWidget {
  const _PinnedGarmentChip({required this.pin, required this.garment});

  final _OotdPin pin;
  final GarmentModel? garment;

  @override
  Widget build(BuildContext context) {
    final thumbPath = garment?.image.thumbPath ?? '';
    return SizedBox(
      width: 92,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: thumbPath.isNotEmpty
                            ? Image.file(
                                File(thumbPath),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _PinThumbFallback(),
                              )
                            : const _PinThumbFallback(),
                      ),
                    ),
                    _PinMarker(index: pin.index),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                garment?.name ?? garment?.category.label ?? '옷',
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
        ),
      ),
    );
  }
}

class _PinThumbFallback extends StatelessWidget {
  const _PinThumbFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTheme.lavender50,
      child: Center(
        child: Icon(Icons.checkroom_outlined, color: AppTheme.muted, size: 18),
      ),
    );
  }
}

class _GarmentPickerSheet extends StatelessWidget {
  const _GarmentPickerSheet({required this.garments});

  final List<GarmentModel> garments;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '어떤 옷인가요?',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: garments.length,
                itemBuilder: (context, index) {
                  final garment = garments[index];
                  final thumbPath = garment.image.thumbPath;
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, garment),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: thumbPath.isNotEmpty
                                ? Image.file(
                                    File(thumbPath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const _PinThumbFallback(),
                                  )
                                : const _PinThumbFallback(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          garment.name ?? garment.category.label,
                          style: const TextStyle(
                            color: AppTheme.inkSoft,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
