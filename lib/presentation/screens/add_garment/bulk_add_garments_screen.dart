import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/enums.dart';
import '../../../data/models/garment_model.dart';
import '../../../services/image/background_removal_service.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

class BulkAddGarmentsScreen extends ConsumerStatefulWidget {
  const BulkAddGarmentsScreen({super.key});

  @override
  ConsumerState<BulkAddGarmentsScreen> createState() =>
      _BulkAddGarmentsScreenState();
}

class _BulkAddGarmentsScreenState extends ConsumerState<BulkAddGarmentsScreen> {
  final _picker = ImagePicker();
  final List<_BulkGarmentDraft> _drafts = [];
  bool _saving = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BulkHeader(onClose: () => context.pop()),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                '여러 벌 한번에 등록',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                '앨범에서 여러 사진을 고르고 카테고리만 빠르게 확인해요.',
                style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _pickImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_drafts.isEmpty ? '사진 여러 장 선택' : '사진 더 추가'),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _drafts.isEmpty
                  ? const _BulkEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                      itemCount: _drafts.length,
                      itemBuilder: (context, index) {
                        final draft = _drafts[index];
                        return _BulkDraftCard(
                          draft: draft,
                          onCategoryChanged: (category) {
                            setState(() => draft.category = category);
                          },
                          onRemove: () {
                            setState(() => _drafts.removeAt(index));
                          },
                        );
                      },
                    ),
            ),
            if (_saving) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: LinearProgressIndicator(
                  value: _drafts.isEmpty
                      ? null
                      : _drafts.where((draft) => draft.done).length /
                            _drafts.length,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  _status,
                  style: const TextStyle(color: AppTheme.inkSoft, fontSize: 12),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: ElevatedButton.icon(
                onPressed: _drafts.isEmpty || _saving ? null : _saveAll,
                icon: const Icon(Icons.done_all),
                label: Text(
                  _drafts.isEmpty ? '등록할 사진을 선택해 주세요' : '${_drafts.length}벌 저장',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(maxWidth: 2048);
    if (images.isEmpty) return;
    setState(() {
      _drafts.addAll(
        images.map((image) => _BulkGarmentDraft(file: File(image.path))),
      );
    });
  }

  Future<void> _saveAll() async {
    setState(() {
      _saving = true;
      _status = '이미지 처리 준비 중...';
      for (final draft in _drafts) {
        draft.done = false;
      }
    });

    try {
      final bgService = ref.read(backgroundRemovalServiceProvider);
      final thumbService = ref.read(thumbnailServiceProvider);
      final repo = ref.read(garmentRepositoryProvider);

      for (var i = 0; i < _drafts.length; i += 1) {
        final draft = _drafts[i];
        setState(() => _status = '${i + 1}/${_drafts.length} 배경 제거 중...');
        final cutout = await bgService.removeBackground(draft.file);
        final thumb = await thumbService.generateThumbnail(cutout);
        final color = await ColorExtractor.extractDominantColor(
          await cutout.readAsBytes(),
        );

        final garment = GarmentModel(
          id: '',
          category: draft.category,
          name: null,
          dominantHex: color,
          warmth: 3,
          formality: 3,
          waterproof: false,
          image: const GarmentImage(
            originalPath: '',
            cutoutPath: '',
            thumbPath: '',
          ),
          createdAt: DateTime.now(),
        );
        await repo.addGarment(
          garment: garment,
          originalFile: draft.file,
          cutoutFile: cutout,
          thumbFile: thumb,
        );
        setState(() => draft.done = true);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${_drafts.length}벌이 등록되었어요.')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('여러 벌 저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _BulkGarmentDraft {
  _BulkGarmentDraft({required this.file});

  final File file;
  GarmentCategory category = GarmentCategory.top;
  bool done = false;
}

class _BulkHeader extends StatelessWidget {
  const _BulkHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: Row(
        children: [
          TextButton(onPressed: onClose, child: const Text('‹ 닫기')),
          const Spacer(),
          const Text(
            '빠른 등록',
            style: TextStyle(
              color: AppTheme.inkSoft,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _BulkDraftCard extends StatelessWidget {
  const _BulkDraftCard({
    required this.draft,
    required this.onCategoryChanged,
    required this.onRemove,
  });

  final _BulkGarmentDraft draft;
  final ValueChanged<GarmentCategory> onCategoryChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: draft.done ? AppTheme.lavender500 : AppTheme.line,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(draft.file, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filled(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close, size: 16),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surface.withValues(
                          alpha: 0.9,
                        ),
                        foregroundColor: AppTheme.ink,
                        minimumSize: const Size(28, 28),
                        fixedSize: const Size(28, 28),
                      ),
                    ),
                  ),
                  if (draft.done)
                    const Positioned(
                      left: 6,
                      top: 6,
                      child: Icon(
                        Icons.check_circle,
                        color: AppTheme.lavender500,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<GarmentCategory>(
              value: draft.category,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              items: GarmentCategory.values
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                  )
                  .toList(),
              onChanged: (category) {
                if (category != null) onCategoryChanged(category);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkEmptyState extends StatelessWidget {
  const _BulkEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          '한 번에 등록할 옷 사진을 선택해 주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.inkSoft, fontSize: 13),
        ),
      ),
    );
  }
}
