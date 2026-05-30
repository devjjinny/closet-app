import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CutoutEditorScreen extends StatefulWidget {
  const CutoutEditorScreen({super.key, required this.cutoutFile});
  final File cutoutFile;

  @override
  State<CutoutEditorScreen> createState() => _CutoutEditorScreenState();
}

class _Stroke {
  _Stroke({required this.radius});
  final double radius;
  final List<Offset> offsets = [];
}

class _CutoutEditorScreenState extends State<CutoutEditorScreen> {
  ui.Image? _image;
  final List<_Stroke> _strokes = [];
  double _brushRadius = 20.0;
  bool _exporting = false;
  Size? _canvasSize;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.cutoutFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _image = frame.image);
  }

  void _undo() {
    if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
  }

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _strokes.add(_Stroke(radius: _brushRadius)..offsets.add(d.localPosition));
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _strokes.last.offsets.add(d.localPosition));
  }

  Future<void> _export() async {
    final img = _image;
    if (img == null) return;
    setState(() => _exporting = true);

    try {
      final widgetSize =
          _canvasSize ?? Size(img.width.toDouble(), img.height.toDouble());
      final scaleX = img.width / widgetSize.width;
      final scaleY = img.height / widgetSize.height;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.saveLayer(
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Paint(),
      );
      canvas.drawImage(img, Offset.zero, Paint());

      final eraser = Paint()
        ..blendMode = BlendMode.clear
        ..strokeCap = StrokeCap.round;

      for (final stroke in _strokes) {
        final r = stroke.radius * scaleX;
        for (int i = 0; i < stroke.offsets.length; i++) {
          final pt = Offset(
            stroke.offsets[i].dx * scaleX,
            stroke.offsets[i].dy * scaleY,
          );
          eraser.style = PaintingStyle.fill;
          canvas.drawCircle(pt, r, eraser);
          if (i > 0) {
            final prev = Offset(
              stroke.offsets[i - 1].dx * scaleX,
              stroke.offsets[i - 1].dy * scaleY,
            );
            eraser
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 2;
            canvas.drawLine(prev, pt, eraser);
          }
        }
      }
      canvas.restore();

      final picture = recorder.endRecording();
      final exported = await picture.toImage(img.width, img.height);
      final byteData = await exported.toByteData(
        format: ui.ImageByteFormat.png,
      );

      final file = File(
        '${Directory.systemTemp.path}/cutout_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData!.buffer.asUint8List());

      if (mounted) Navigator.pop(context, file);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: _image == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.lavender500),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('뒤로'),
                        ),
                        const Spacer(),
                        const Text(
                          'STEP 2 · 보정',
                          style: TextStyle(
                            color: AppTheme.inkSoft,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _exporting ? null : _export,
                          child: const Text('건너뛰기'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.lavender50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final imgAspect =
                                    _image!.width / _image!.height;
                                final availW = constraints.maxWidth;
                                final availH = constraints.maxHeight;

                                double w, h;
                                if (availW / availH < imgAspect) {
                                  w = availW;
                                  h = w / imgAspect;
                                } else {
                                  h = availH;
                                  w = h * imgAspect;
                                }
                                _canvasSize = Size(w, h);

                                return SizedBox(
                                  width: w,
                                  height: h,
                                  child: GestureDetector(
                                    onPanStart: _onPanStart,
                                    onPanUpdate: _onPanUpdate,
                                    child: CustomPaint(
                                      painter: _EraserPainter(
                                        image: _image!,
                                        strokes: _strokes,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ToolPanel(
                      canUndo: _strokes.isNotEmpty,
                      exporting: _exporting,
                      brushRadius: _brushRadius,
                      onUndo: _undo,
                      onExport: _export,
                      onBrushChanged: (v) => setState(() => _brushRadius = v),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _EraserPainter extends CustomPainter {
  const _EraserPainter({required this.image, required this.strokes});
  final ui.Image image;
  final List<_Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCheckerboard(canvas, size);

    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(image, src, rect, Paint());

    final eraser = Paint()
      ..blendMode = BlendMode.clear
      ..strokeCap = StrokeCap.round;

    for (final stroke in strokes) {
      final r = stroke.radius;
      for (int i = 0; i < stroke.offsets.length; i++) {
        eraser.style = PaintingStyle.fill;
        canvas.drawCircle(stroke.offsets[i], r, eraser);
        if (i > 0) {
          eraser
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 2;
          canvas.drawLine(stroke.offsets[i - 1], stroke.offsets[i], eraser);
        }
      }
    }

    canvas.restore();
  }

  void _drawCheckerboard(Canvas canvas, Size size) {
    const cell = 10.0;
    final p1 = Paint()..color = Colors.white;
    final p2 = Paint()..color = AppTheme.lavender100;
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * cell, r * cell, cell, cell),
          (r + c).isEven ? p1 : p2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_EraserPainter old) => true;
}

class _ToolPanel extends StatelessWidget {
  const _ToolPanel({
    required this.canUndo,
    required this.exporting,
    required this.brushRadius,
    required this.onUndo,
    required this.onExport,
    required this.onBrushChanged,
  });

  final bool canUndo;
  final bool exporting;
  final double brushRadius;
  final VoidCallback onUndo;
  final VoidCallback onExport;
  final ValueChanged<double> onBrushChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.line),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                FilledButton.tonal(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: AppTheme.ink,
                    disabledForegroundColor: AppTheme.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('지우개'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: canUndo ? onUndo : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('되돌리기'),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SIZE',
                  style: TextStyle(
                    color: AppTheme.inkSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: brushRadius,
                    min: 8,
                    max: 60,
                    onChanged: onBrushChanged,
                    activeColor: AppTheme.ink,
                    inactiveColor: AppTheme.lavender100,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canUndo ? onUndo : null,
                icon: const Icon(Icons.undo),
                label: const Text('되돌리기'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: exporting ? null : onExport,
                child: exporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('완료 →'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
