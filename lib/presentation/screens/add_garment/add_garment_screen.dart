import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/constants/enums.dart';
import 'camera_guide_screen.dart';
import '../../../data/models/garment_model.dart';
import '../../../services/image/background_removal_service.dart';
import '../../providers/providers.dart';

class AddGarmentScreen extends ConsumerStatefulWidget {
  const AddGarmentScreen({super.key});

  @override
  ConsumerState<AddGarmentScreen> createState() => _AddGarmentScreenState();
}

class _AddGarmentScreenState extends ConsumerState<AddGarmentScreen> {
  File? _originalFile;
  File? _cutoutFile;
  File? _thumbFile;
  String? _dominantColor;

  GarmentCategory _category = GarmentCategory.top;
  int _warmth = 3;
  int _formality = 3;
  bool _waterproof = false;
  final List<StyleTag> _styleTags = [];

  bool _processing = false;
  bool _uploading = false;
  String _statusMessage = '';
  double _uploadProgress = 0;

  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('옷 등록'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo section
            _buildPhotoSection(),
            const SizedBox(height: 24),

            if (_cutoutFile != null) ...[
              // Shooting guide tip
              _buildShootingTip(),
              const SizedBox(height: 16),

              // Category
              _buildCategorySelector(),
              const SizedBox(height: 16),

              // Color preview
              if (_dominantColor != null) _buildColorPreview(),
              const SizedBox(height: 16),

              // Warmth slider
              _buildSlider(
                label: '보온성',
                value: _warmth,
                min: 1,
                max: 5,
                labels: ['시원함', '보통', '따뜻함'],
                onChanged: (v) => setState(() => _warmth = v),
              ),
              const SizedBox(height: 16),

              // Formality slider
              _buildSlider(
                label: '포멀도',
                value: _formality,
                min: 1,
                max: 5,
                labels: ['캐주얼', '보통', '포멀'],
                onChanged: (v) => setState(() => _formality = v),
              ),
              const SizedBox(height: 16),

              // Waterproof toggle
              SwitchListTile(
                title: const Text('방수'),
                value: _waterproof,
                onChanged: (v) => setState(() => _waterproof = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // Style tags
              _buildStyleTagSelector(),
              const SizedBox(height: 32),

              // Save button
              if (_uploading)
                Column(
                  children: [
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 8),
                    Text(_statusMessage, style: const TextStyle(fontSize: 12)),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: _save,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('저장하기', style: TextStyle(fontSize: 16)),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _processing ? null : _pickAndProcessImage,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _processing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('배경 제거 중...'),
                  ],
                ),
              )
            : _cutoutFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_cutoutFile!, fit: BoxFit.contain),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        '사진을 촬영하거나 앨범에서 선택하세요',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildShootingTip() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Color(0xFFFF9800), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '밝은 단색 배경에서 촬영하면 배경제거 품질이 높아져요',
              style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('카테고리', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GarmentCategory.values.map((cat) {
            final selected = _category == cat;
            return ChoiceChip(
              label: Text(cat.label),
              selected: selected,
              onSelected: (_) => setState(() => _category = cat),
              selectedColor: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorPreview() {
    final color = _parseColor(_dominantColor!);
    return Row(
      children: [
        const Text('대표 색상', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
        const SizedBox(width: 8),
        Text(_dominantColor!, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required List<String> labels,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: value.toString(),
          onChanged: (v) => onChanged(v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map((l) => Text(l, style: TextStyle(fontSize: 11, color: Colors.grey[500])))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStyleTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('스타일 태그 (선택)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: StyleTag.values.map((tag) {
            final selected = _styleTags.contains(tag);
            return FilterChip(
              label: Text(tag.label),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _styleTags.add(tag);
                  } else {
                    _styleTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _pickAndProcessImage() async {
    // Show picker options
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('앨범'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    File? imageFile;
    if (source == ImageSource.camera &&
        (_category == GarmentCategory.top ||
            _category == GarmentCategory.bottom ||
            _category == GarmentCategory.outer ||
            _category == GarmentCategory.dress)) {
      // 가이드 오버레이 카메라 사용
      imageFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (_) => CameraGuideScreen(category: _category),
          fullscreenDialog: true,
        ),
      );
    } else {
      final picked = await _picker.pickImage(source: source, maxWidth: 2048);
      if (picked != null) imageFile = File(picked.path);
    }
    if (imageFile == null) return;

    // 기존 XFile을 File로 대체했으므로 crop 처리
    final picked = XFile(imageFile.path);

    // Crop
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 4),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '옷 영역 선택',
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: '옷 영역 선택'),
      ],
    );
    if (cropped == null) return;

    setState(() {
      _processing = true;
      _originalFile = File(cropped.path);
    });

    try {
      // Background removal
      final bgService = ref.read(backgroundRemovalServiceProvider);
      final cutout = await bgService.removeBackground(File(cropped.path));

      // Thumbnail
      final thumbService = ref.read(thumbnailServiceProvider);
      final thumb = await thumbService.generateThumbnail(cutout);

      // Extract dominant color
      final bytes = await cutout.readAsBytes();
      final color = await ColorExtractor.extractDominantColor(bytes);

      setState(() {
        _cutoutFile = cutout;
        _thumbFile = thumb;
        _dominantColor = color;
        _processing = false;
      });
    } catch (e) {
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 처리 실패: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null || _originalFile == null || _cutoutFile == null || _thumbFile == null) {
      return;
    }

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });

    try {
      final garment = GarmentModel(
        id: '', // Will be set by repository
        category: _category,
        dominantHex: _dominantColor ?? '#808080',
        warmth: _warmth,
        formality: _formality,
        waterproof: _waterproof,
        styleTags: _styleTags,
        image: const GarmentImage(
          originalUrl: '',
          cutoutUrl: '',
          thumbUrl: '',
        ),
        createdAt: DateTime.now(),
      );

      await ref.read(garmentRepositoryProvider).addGarment(
            uid: uid,
            garment: garment,
            originalFile: _originalFile!,
            cutoutFile: _cutoutFile!,
            thumbFile: _thumbFile!,
            onProgress: (step, progress) {
              setState(() {
                _statusMessage = step;
                _uploadProgress = progress;
              });
            },
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('옷이 등록되었어요!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return Colors.grey;
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
