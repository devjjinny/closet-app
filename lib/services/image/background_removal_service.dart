import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 배경제거 서비스
/// ML Kit Selfie Segmentation 우선 시도,
/// 사람이 감지되지 않으면 색상 기반 폴백 (흰 배경)
class BackgroundRemovalService {
  Future<File> removeBackground(File inputFile) async {
    final inputImage = InputImage.fromFile(inputFile);
    final segmenter = SelfieSegmenter(mode: SegmenterMode.single);

    try {
      final mask = await segmenter.processImage(inputImage);

      // ML Kit이 사람을 감지한 경우
      if (mask != null && _hasPerson(mask.confidences)) {
        final imageBytes = await inputFile.readAsBytes();
        final resultBytes = await compute(
          _applySegmentationMask,
          _MaskParams(
            imageBytes: imageBytes,
            maskValues: mask.confidences,
            maskWidth: mask.width,
            maskHeight: mask.height,
          ),
        );
        return _writeTempFile(resultBytes);
      }
    } catch (_) {
      // ML Kit 실패 시 폴백
    } finally {
      await segmenter.close();
    }

    // 폴백: 색상 기반 배경제거 (흰/밝은 배경 전용)
    return _colorBasedRemoval(inputFile);
  }

  /// ML Kit 결과에 실제로 사람이 있는지 확인 (confidence 0.5 이상 픽셀 비율)
  bool _hasPerson(List<double> confidences) {
    int foreground = 0;
    for (final v in confidences) {
      if (v > 0.5) foreground++;
    }
    return foreground / confidences.length > 0.05; // 5% 이상이면 사람 있음
  }

  Future<File> _colorBasedRemoval(File inputFile) async {
    final bytes = await inputFile.readAsBytes();
    final resultBytes = await compute(_processColorBased, bytes);
    return _writeTempFile(resultBytes);
  }

  Future<File> _writeTempFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final outputPath = p.join(
      tempDir.path,
      'cutout_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    return file;
  }

  // ── Isolate: ML Kit 마스크 적용 ────────────────────────────────

  static Uint8List _applySegmentationMask(_MaskParams params) {
    final image = img.decodeImage(params.imageBytes);
    if (image == null) throw Exception('Failed to decode image');

    final result = img.Image(
      width: image.width,
      height: image.height,
      numChannels: 4,
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        // 마스크 크기가 이미지와 다를 경우 스케일 처리
        final maskX = (x * params.maskWidth / image.width)
            .round()
            .clamp(0, params.maskWidth - 1);
        final maskY = (y * params.maskHeight / image.height)
            .round()
            .clamp(0, params.maskHeight - 1);
        final confidence = params.maskValues[maskY * params.maskWidth + maskX];

        final pixel = image.getPixel(x, y);
        final alpha = _smoothAlpha(confidence);
        result.setPixelRgba(
            x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), alpha);
      }
    }

    return Uint8List.fromList(img.encodePng(result));
  }

  /// 0.4~0.6 구간에서 부드럽게 전환 (경계 안티에일리어싱)
  static int _smoothAlpha(double confidence) {
    const low = 0.4;
    const high = 0.6;
    if (confidence >= high) return 255;
    if (confidence <= low) return 0;
    return ((confidence - low) / (high - low) * 255).round();
  }

  // ── Isolate: 색상 기반 배경제거 (흰/밝은 배경) ─────────────────

  static Uint8List _processColorBased(Uint8List inputBytes) {
    final image = img.decodeImage(inputBytes);
    if (image == null) throw Exception('Failed to decode image');

    final result = img.Image(
      width: image.width,
      height: image.height,
      numChannels: 4,
    );

    // 1단계: 임계값 마스크 생성
    final maskBool = List<bool>.filled(image.width * image.height, false);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final brightness = (r + g + b) / 3;
        final saturation = _saturation(r, g, b);
        maskBool[y * image.width + x] =
            brightness > 220 && saturation < 0.12; // 배경(흰색) = true
      }
    }

    // 2단계: 가장자리에서 flood-fill로 실제 배경 영역만 선택
    final bgMask = List<bool>.filled(image.width * image.height, false);
    _floodFillEdges(maskBool, bgMask, image.width, image.height);

    // 3단계: 배경이 아닌 픽셀만 유지
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (bgMask[y * image.width + x]) {
          result.setPixelRgba(x, y, 0, 0, 0, 0); // 배경 → 투명
        } else {
          result.setPixelRgba(
              x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), 255);
        }
      }
    }

    return Uint8List.fromList(img.encodePng(result));
  }

  /// 이미지 가장자리에서 BFS flood-fill로 연결된 밝은 영역을 배경으로 표시
  static void _floodFillEdges(
    List<bool> isLight,
    List<bool> bgMask,
    int width,
    int height,
  ) {
    final queue = <int>[];

    void enqueue(int x, int y) {
      final idx = y * width + x;
      if (!isLight[idx] || bgMask[idx]) return;
      bgMask[idx] = true;
      queue.add(y * width + x);
    }

    // 네 가장자리 시드
    for (int x = 0; x < width; x++) {
      enqueue(x, 0);
      enqueue(x, height - 1);
    }
    for (int y = 0; y < height; y++) {
      enqueue(0, y);
      enqueue(width - 1, y);
    }

    const dx = [1, -1, 0, 0];
    const dy = [0, 0, 1, -1];

    while (queue.isNotEmpty) {
      final idx = queue.removeLast();
      final x = idx % width;
      final y = idx ~/ width;

      for (int d = 0; d < 4; d++) {
        final nx = x + dx[d];
        final ny = y + dy[d];
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
        enqueue(nx, ny);
      }
    }
  }

  static double _saturation(int r, int g, int b) {
    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final min = [r, g, b].reduce((a, b) => a < b ? a : b);
    if (max == 0) return 0;
    return (max - min) / max;
  }
}

// ── 파라미터 클래스 ──────────────────────────────────────────────

class _MaskParams {
  const _MaskParams({
    required this.imageBytes,
    required this.maskValues,
    required this.maskWidth,
    required this.maskHeight,
  });

  final Uint8List imageBytes;
  final List<double> maskValues;
  final int maskWidth;
  final int maskHeight;
}

// ── 썸네일 생성 서비스 ───────────────────────────────────────────

class ThumbnailService {
  Future<File> generateThumbnail(File inputFile, {int width = 300}) async {
    final bytes = await inputFile.readAsBytes();
    final resultBytes = await compute(_generateThumb, _ThumbParams(bytes, width));

    final tempDir = await getTemporaryDirectory();
    final outputPath = p.join(
      tempDir.path,
      'thumb_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final file = File(outputPath);
    await file.writeAsBytes(resultBytes);
    return file;
  }

  static Uint8List _generateThumb(_ThumbParams params) {
    final image = img.decodeImage(params.bytes);
    if (image == null) throw Exception('Failed to decode image');
    final resized = img.copyResize(image, width: params.width);
    return Uint8List.fromList(img.encodePng(resized));
  }
}

class _ThumbParams {
  const _ThumbParams(this.bytes, this.width);
  final Uint8List bytes;
  final int width;
}

// ── 지배색 추출 ─────────────────────────────────────────────────

class ColorExtractor {
  static Future<String> extractDominantColor(Uint8List imageBytes) async {
    return compute(_extractColor, imageBytes);
  }

  static String _extractColor(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return '#808080';

    int totalR = 0, totalG = 0, totalB = 0;
    int count = 0;

    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final a = pixel.a.toInt();

        if (a < 128) continue; // 투명 픽셀 제외
        if (r > 240 && g > 240 && b > 240) continue; // 흰 배경 잔여 제외

        totalR += r;
        totalG += g;
        totalB += b;
        count++;
      }
    }

    if (count == 0) return '#808080';

    final avgR = (totalR / count).round();
    final avgG = (totalG / count).round();
    final avgB = (totalB / count).round();

    return '#${avgR.toRadixString(16).padLeft(2, '0')}'
        '${avgG.toRadixString(16).padLeft(2, '0')}'
        '${avgB.toRadixString(16).padLeft(2, '0')}';
  }
}
