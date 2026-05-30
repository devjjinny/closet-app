import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/constants/enums.dart';
import 'camera_guide_screen.dart';
import 'cutout_editor_screen.dart';
import '../../../data/models/garment_model.dart';
import '../../../services/image/background_removal_service.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

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

  final _nameController = TextEditingController();
  GarmentCategory _category = GarmentCategory.top;
  int _warmth = 3;
  int _formality = 3;
  bool _waterproof = false;
  final List<StyleTag> _styleTags = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _processing = false;
  bool _uploading = false;
  String _statusMessage = '';
  double _uploadProgress = 0;

  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          MediaQuery.of(context).padding.top + 10,
          18,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AddHeader(
              step: _cutoutFile == null ? 'STEP 1 / 3' : 'STEP 3 / 3',
              onClose: () => context.pop(),
            ),
            const SizedBox(height: 14),
            if (_cutoutFile == null) ...[
              const Text(
                '옷을 추가해요',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '사진 1장이면 배경 제거와 기본 정보 입력까지 이어집니다.',
                style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => context.push('/add-garments-bulk'),
                icon: const Icon(Icons.grid_view_outlined),
                label: const Text('여러 벌 한번에 등록'),
              ),
              const SizedBox(height: 10),
            ] else ...[
              const Text(
                '맞나요?',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'AI가 자동으로 채웠어요. 수정 가능.',
                style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
              ),
              const SizedBox(height: 14),
            ],
            _buildPhotoSection(),
            const SizedBox(height: 14),

            if (_cutoutFile != null) ...[
              _buildInferenceCard(),
              const SizedBox(height: 10),
              _buildNameCard(),
              const SizedBox(height: 10),
              _buildStyleTagSelector(),
              const SizedBox(height: 10),
              _buildWaterproofCard(),
              const SizedBox(height: 18),

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
                    child: Text('저장 (1초)', style: TextStyle(fontSize: 16)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _processing ? null : _pickAndProcessImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: _cutoutFile == null ? 420 : 118,
        decoration: BoxDecoration(
          color: _cutoutFile == null ? AppTheme.ink : AppTheme.surface,
          borderRadius: BorderRadius.circular(_cutoutFile == null ? 16 : 14),
          border: Border.all(
            color: _cutoutFile == null ? AppTheme.ink : AppTheme.line,
          ),
        ),
        child: _processing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: _cutoutFile == null
                          ? AppTheme.surface
                          : AppTheme.lavender500,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '배경 제거 중...',
                      style: TextStyle(
                        color: _cutoutFile == null
                            ? AppTheme.surface
                            : AppTheme.inkSoft,
                      ),
                    ),
                  ],
                ),
              )
            : _cutoutFile != null
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 92,
                        height: 92,
                        child: Image.file(_cutoutFile!, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '배경제거됨',
                            style: TextStyle(
                              color: AppTheme.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${_category.label} · WARMTH $_warmth',
                            style: const TextStyle(
                              color: AppTheme.inkSoft,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '탭해서 다시 선택',
                            style: TextStyle(
                              color: AppTheme.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.surface.withValues(alpha: 0.85),
                      width: 1.6,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      const Positioned.fill(child: _ViewfinderCorners()),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.checkroom_outlined,
                              size: 42,
                              color: AppTheme.surface.withValues(alpha: 0.45),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '옷을 평평한 곳에',
                              style: TextStyle(
                                color: AppTheme.surface,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '밝은 배경 · 옷이 화면을 80% 채우게',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.surface.withValues(alpha: 0.72),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ElevatedButton.icon(
                              onPressed: null,
                              icon: Icon(Icons.photo_camera_outlined),
                              label: Text('촬영 또는 선택'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInferenceCard() {
    return _Panel(
      child: Column(
        children: [
          _buildCategorySelector(),
          const SizedBox(height: 12),
          if (_dominantColor != null) _buildColorPreview(),
          if (_dominantColor != null) const SizedBox(height: 12),
          _buildWarmthSelector(),
          const SizedBox(height: 12),
          _buildSlider(
            label: '포멀도',
            value: _formality,
            min: 1,
            max: 5,
            labels: ['캐주얼', '보통', '포멀'],
            onChanged: (v) => setState(() => _formality = v),
          ),
        ],
      ),
    );
  }

  Widget _buildNameCard() {
    return _Panel(
      child: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: '이름 (선택)',
          hintText: '예: 흰 린넨 셔츠',
          counterText: '',
        ),
        textCapitalization: TextCapitalization.none,
        maxLength: 30,
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
              '입고 찍으면 ML Kit으로 배경 자동 제거 • 흰 배경에 놓고 찍어도 OK',
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
        const _PanelLabel('카테고리'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 8,
          children: GarmentCategory.values.map((cat) {
            final selected = _category == cat;
            return _MiniPill(
              label: cat.label,
              selected: selected,
              onTap: () => setState(() => _category = cat),
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
        const _PanelLabel('색상'),
        const Spacer(),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.ink),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _dominantColor!,
          style: const TextStyle(color: AppTheme.inkSoft, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildWaterproofCard() {
    return _Panel(
      child: Row(
        children: [
          const _PanelLabel('방수'),
          const Spacer(),
          Switch(
            value: _waterproof,
            onChanged: (v) => setState(() => _waterproof = v),
            activeThumbColor: AppTheme.ink,
            activeTrackColor: AppTheme.lavender100,
          ),
        ],
      ),
    );
  }

  // TODO: remove after add flow migration is complete.
  // ignore: unused_element
  Widget _legacyColorPreview() {
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

  static const _warmthColors = [
    Color(0xFFFF6B6B), // 1 — 더움
    Color(0xFFFFB347), // 2
    Color(0xFF74b9ff), // 3
    Color(0xFF6C5CE7), // 4
    Color(0xFF2d3436), // 5 — 추움
  ];
  static const _warmthIcons = ['☀️', '🌤️', '🍃', '🧥', '❄️'];
  static const _warmthTemps = ['28°C~', '20~27°C', '12~19°C', '5~11°C', '~4°C'];
  static const _warmthExamples = [
    '민소매, 크롭탑, 반바지',
    '반팔 티셔츠, 얇은 셔츠, 면바지',
    '긴팔, 얇은 니트, 맨투맨, 가디건',
    '자켓, 야상, 트렌치코트, 두꺼운 니트',
    '패딩, 두꺼운 코트, 기모 제품',
  ];

  Widget _buildWarmthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelLabel('보온도'),
        const SizedBox(height: 10),
        Row(
          children: List.generate(5, (i) {
            final level = i + 1;
            final selected = _warmth == level;
            final color = _warmthColors[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _warmth = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.ink : AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected ? AppTheme.ink : AppTheme.line,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$level',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: selected ? AppTheme.surface : AppTheme.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Container(
            key: ValueKey(_warmth),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.lavender50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _warmthTemps[_warmth - 1],
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.lavender600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _warmthExamples[_warmth - 1],
                  style: const TextStyle(fontSize: 12, color: AppTheme.inkSoft),
                ),
              ],
            ),
          ),
        ),
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
        _PanelLabel(label),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: value.toString(),
          onChanged: (v) => onChanged(v.round()),
          activeColor: AppTheme.lavender500,
          inactiveColor: AppTheme.lavender100,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels
              .map(
                (l) => Text(
                  l,
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStyleTagSelector() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelLabel('스타일 태그 (자동)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: StyleTag.values.map((tag) {
              final selected = _styleTags.contains(tag);
              return _MiniPill(
                label: tag.label,
                selected: selected,
                onTap: () {
                  setState(() {
                    if (selected) {
                      _styleTags.remove(tag);
                    } else {
                      _styleTags.add(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
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
    if (!mounted) return;

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
        AndroidUiSettings(toolbarTitle: '옷 영역 선택', lockAspectRatio: false),
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
      final rawCutout = await bgService.removeBackground(File(cropped.path));

      // Manual eraser refinement
      final refined = mounted
          ? await Navigator.push<File>(
              context,
              MaterialPageRoute(
                builder: (_) => CutoutEditorScreen(cutoutFile: rawCutout),
              ),
            )
          : null;
      final cutout = refined ?? rawCutout;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('이미지 처리 실패: $e')));
      }
    }
  }

  Future<void> _save() async {
    if (_originalFile == null || _cutoutFile == null || _thumbFile == null) {
      return;
    }

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });

    try {
      final garment = GarmentModel(
        id: '',
        category: _category,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        dominantHex: _dominantColor ?? '#808080',
        warmth: _warmth,
        formality: _formality,
        waterproof: _waterproof,
        styleTags: _styleTags,
        image: const GarmentImage(
          originalPath: '',
          cutoutPath: '',
          thumbPath: '',
        ),
        createdAt: DateTime.now(),
      );

      await ref
          .read(garmentRepositoryProvider)
          .addGarment(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('옷이 등록되었어요!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return AppTheme.muted;
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

class _AddHeader extends StatelessWidget {
  const _AddHeader({required this.step, required this.onClose});

  final String step;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            foregroundColor: AppTheme.ink,
            minimumSize: const Size(36, 36),
            fixedSize: const Size(36, 36),
          ),
        ),
        const Spacer(),
        Text(
          step,
          style: const TextStyle(
            color: AppTheme.inkSoft,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.inkSoft,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.35,
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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
    );
  }
}

class _ViewfinderCorners extends StatelessWidget {
  const _ViewfinderCorners();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ViewfinderPainter());
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.lavender500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square;
    const inset = 10.0;
    const len = 26.0;

    void corner(double x, double y, double sx, double sy) {
      canvas.drawLine(Offset(x, y), Offset(x + len * sx, y), paint);
      canvas.drawLine(Offset(x, y), Offset(x, y + len * sy), paint);
    }

    corner(inset, inset, 1, 1);
    corner(size.width - inset, inset, -1, 1);
    corner(inset, size.height - inset, 1, -1);
    corner(size.width - inset, size.height - inset, -1, -1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
