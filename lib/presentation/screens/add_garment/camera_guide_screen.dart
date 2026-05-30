import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/enums.dart';
import '../../theme/app_theme.dart';

/// 옷 촬영 가이드 오버레이가 있는 카메라 화면
class CameraGuideScreen extends StatefulWidget {
  const CameraGuideScreen({super.key, required this.category});

  final GarmentCategory category;

  @override
  State<CameraGuideScreen> createState() => _CameraGuideScreenState();
}

class _CameraGuideScreenState extends State<CameraGuideScreen> {
  CameraController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller.initialize();
    if (!mounted) return;

    setState(() {
      _controller = controller;
      _ready = true;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_controller == null || !_ready) return;

    final file = await _controller!.takePicture();
    if (mounted) Navigator.pop(context, File(file.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: _ready && _controller != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),
                ColoredBox(color: Colors.black.withValues(alpha: 0.22)),

                _GuideOverlay(category: widget.category),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: AppTheme.surface,
                            size: 24,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        const Text(
                          'STEP 1 / 4 · 촬영',
                          style: TextStyle(
                            color: AppTheme.surface,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.flash_on_outlined,
                          color: AppTheme.surface,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 34),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.surface.withValues(alpha: 0.85),
                              width: 1.5,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _capture,
                          child: Container(
                            width: 70,
                            height: 70,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.surface,
                                width: 3,
                              ),
                            ),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.cameraswitch_outlined,
                            color: AppTheme.surface,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: AppTheme.surface),
            ),
    );
  }
}

class _GuideOverlay extends StatelessWidget {
  const _GuideOverlay({required this.category});

  final GarmentCategory category;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final label = _labelFor(category);

    return Stack(
      children: [
        CustomPaint(
          size: size,
          painter: _GuidePainter(category: category),
        ),
        Positioned(
          left: 22,
          right: 22,
          top: size.height * 0.15,
          bottom: size.height * 0.16,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.surface.withValues(alpha: 0.72),
                  width: 1.6,
                ),
              ),
              child: CustomPaint(painter: _CornerPainter()),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.20,
          left: 24,
          right: 24,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.ink.withValues(alpha: 0.64),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$label을 평평한 곳에 놓고 촬영하세요',
                style: const TextStyle(color: AppTheme.surface, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _labelFor(GarmentCategory cat) {
    switch (cat) {
      case GarmentCategory.top:
        return '상의';
      case GarmentCategory.bottom:
        return '하의';
      case GarmentCategory.outer:
        return '아우터';
      case GarmentCategory.dress:
        return '원피스';
      default:
        return cat.label;
    }
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.lavender500
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const inset = 8.0;
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

class _GuidePainter extends CustomPainter {
  _GuidePainter({required this.category});

  final GarmentCategory category;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    final path = switch (category) {
      GarmentCategory.top || GarmentCategory.outer => _topPath(size),
      GarmentCategory.bottom => _bottomPath(size),
      GarmentCategory.dress => _dressPath(size),
      _ => _rectPath(size),
    };

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }

  /// 상의/아우터: 티셔츠 실루엣
  Path _topPath(Size s) {
    final cx = s.width / 2;
    final top = s.height * 0.18;
    final bottom = s.height * 0.72;
    final bodyW = s.width * 0.38;
    final shoulderW = s.width * 0.46;
    final sleeveW = s.width * 0.18;
    final sleeveH = s.height * 0.18;
    final neckR = s.width * 0.07;

    final path = Path();

    // 왼쪽 어깨에서 시작
    path.moveTo(cx - shoulderW, top + sleeveH * 0.3);
    // 왼쪽 소매 끝
    path.lineTo(cx - shoulderW - sleeveW, top + sleeveH);
    // 왼쪽 소매 아래
    path.lineTo(cx - bodyW, top + sleeveH);
    // 왼쪽 몸통 아래
    path.lineTo(cx - bodyW, bottom);
    // 아래단
    path.lineTo(cx + bodyW, bottom);
    // 오른쪽 몸통 위
    path.lineTo(cx + bodyW, top + sleeveH);
    // 오른쪽 소매 아래
    path.lineTo(cx + shoulderW + sleeveW, top + sleeveH);
    // 오른쪽 소매 끝
    path.lineTo(cx + shoulderW, top + sleeveH * 0.3);
    // 오른쪽 넥라인
    path.quadraticBezierTo(cx + neckR * 2, top, cx, top + neckR * 0.5);
    // 왼쪽 넥라인
    path.quadraticBezierTo(
      cx - neckR * 2,
      top,
      cx - shoulderW,
      top + sleeveH * 0.3,
    );

    path.close();
    return path;
  }

  /// 하의: 팬츠 실루엣
  Path _bottomPath(Size s) {
    final cx = s.width / 2;
    final top = s.height * 0.16;
    final bottom = s.height * 0.85;
    final waistW = s.width * 0.30;
    final hipW = s.width * 0.34;
    final legW = s.width * 0.15;
    final crotch = s.height * 0.46;

    final path = Path();

    // 허리 왼쪽
    path.moveTo(cx - waistW, top);
    // 허리 오른쪽
    path.lineTo(cx + waistW, top);
    // 오른쪽 엉덩이
    path.quadraticBezierTo(
      cx + hipW + s.width * 0.02,
      crotch * 0.6,
      cx + hipW,
      crotch,
    );
    // 오른쪽 다리 아래
    path.lineTo(cx + legW, bottom);
    // 가랑이
    path.quadraticBezierTo(cx, crotch + s.height * 0.04, cx - legW, bottom);
    // 왼쪽 다리 위
    path.lineTo(cx - hipW, crotch);
    // 왼쪽 엉덩이
    path.quadraticBezierTo(
      cx - hipW - s.width * 0.02,
      crotch * 0.6,
      cx - waistW,
      top,
    );

    path.close();
    return path;
  }

  /// 원피스: 위는 상의, 아래는 스커트
  Path _dressPath(Size s) {
    final cx = s.width / 2;
    final top = s.height * 0.15;
    final bottom = s.height * 0.85;
    final neckR = s.width * 0.07;
    final shoulderW = s.width * 0.32;
    final waistW = s.width * 0.22;
    final hemW = s.width * 0.40;
    final waistY = s.height * 0.42;

    final path = Path();

    path.moveTo(cx - shoulderW, top + s.height * 0.04);
    path.quadraticBezierTo(cx - neckR * 2, top, cx, top + neckR * 0.5);
    path.quadraticBezierTo(
      cx + neckR * 2,
      top,
      cx + shoulderW,
      top + s.height * 0.04,
    );
    path.lineTo(cx + waistW, waistY);
    path.quadraticBezierTo(
      cx + hemW * 0.7,
      waistY + s.height * 0.1,
      cx + hemW,
      bottom,
    );
    path.lineTo(cx - hemW, bottom);
    path.quadraticBezierTo(
      cx - hemW * 0.7,
      waistY + s.height * 0.1,
      cx - waistW,
      waistY,
    );
    path.close();
    return path;
  }

  /// 기타: 사각형 가이드
  Path _rectPath(Size s) {
    final l = s.width * 0.12;
    final t = s.height * 0.20;
    return Path()..addRRect(
      RRect.fromLTRBR(
        l,
        t,
        s.width - l,
        s.height * 0.80,
        const Radius.circular(12),
      ),
    );
  }

  @override
  bool shouldRepaint(_GuidePainter old) => old.category != category;
}
