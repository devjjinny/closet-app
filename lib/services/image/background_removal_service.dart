import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 배경제거 서비스
/// MVP: 간단한 색상 기반 배경제거 + 촬영 가이드로 보완
/// 향후: ML Kit Selfie Segmentation 또는 외부 API로 교체
class BackgroundRemovalService {
  /// 배경 제거 처리 (isolate에서 실행)
  Future<File> removeBackground(File inputFile) async {
    final bytes = await inputFile.readAsBytes();
    final resultBytes = await compute(_processBackgroundRemoval, bytes);

    final tempDir = await getTemporaryDirectory();
    final outputPath = p.join(
      tempDir.path,
      'cutout_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(resultBytes);
    return outputFile;
  }

  /// isolate에서 실행되는 배경제거 로직
  static Uint8List _processBackgroundRemoval(Uint8List inputBytes) {
    final image = img.decodeImage(inputBytes);
    if (image == null) throw Exception('Failed to decode image');

    // Simple approach: assume white/light background
    // In production, replace with ML-based segmentation
    final result = img.Image(
      width: image.width,
      height: image.height,
      numChannels: 4,
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Check if pixel is "background-like" (white/very light)
        final brightness = (r + g + b) / 3;
        final saturation = _saturation(r, g, b);

        if (brightness > 230 && saturation < 0.1) {
          // Transparent
          result.setPixelRgba(x, y, 0, 0, 0, 0);
        } else {
          result.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    }

    return Uint8List.fromList(img.encodePng(result));
  }

  static double _saturation(int r, int g, int b) {
    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final min = [r, g, b].reduce((a, b) => a < b ? a : b);
    if (max == 0) return 0;
    return (max - min) / max;
  }
}

/// 썸네일 생성 서비스
class ThumbnailService {
  /// 썸네일 생성 (isolate에서 실행)
  Future<File> generateThumbnail(
    File inputFile, {
    int width = 300,
  }) async {
    final bytes = await inputFile.readAsBytes();
    final resultBytes = await compute(
      _generateThumb,
      _ThumbParams(bytes, width),
    );

    final tempDir = await getTemporaryDirectory();
    final outputPath = p.join(
      tempDir.path,
      'thumb_${DateTime.now().millisecondsSinceEpoch}.webp',
    );
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(resultBytes);
    return outputFile;
  }

  static Uint8List _generateThumb(_ThumbParams params) {
    final image = img.decodeImage(params.bytes);
    if (image == null) throw Exception('Failed to decode image');

    final resized = img.copyResize(image, width: params.width);
    // Use PNG as fallback since image package webp support varies
    return Uint8List.fromList(img.encodePng(resized));
  }
}

class _ThumbParams {
  const _ThumbParams(this.bytes, this.width);
  final Uint8List bytes;
  final int width;
}

/// 지배색 추출
class ColorExtractor {
  /// 이미지에서 지배적인 색상 추출 (isolate에서 실행)
  static Future<String> extractDominantColor(Uint8List imageBytes) async {
    return compute(_extractColor, imageBytes);
  }

  static String _extractColor(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return '#808080';

    int totalR = 0, totalG = 0, totalB = 0;
    int count = 0;

    // Sample every 10th pixel for speed
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final a = pixel.a.toInt();

        // Skip transparent pixels
        if (a < 128) continue;
        // Skip very light/white pixels (likely background remnants)
        if (r > 240 && g > 240 && b > 240) continue;

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
