import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';

/// 코디 콜라주 이미지 생성 서비스
class CollageService {
  /// 콜라주 생성 (isolate에서 실행)
  /// [cutoutPaths]: Map<GarmentCategory, File> - 카테고리별 cutout 이미지
  Future<File> generateCollage(
    Map<GarmentCategory, File> cutoutPaths,
  ) async {
    // Read all files first (can't pass File objects to isolate)
    final entries = <String, Uint8List>{};
    for (final entry in cutoutPaths.entries) {
      entries[entry.key.name] = await entry.value.readAsBytes();
    }

    final resultBytes = await compute(_buildCollage, entries);

    final tempDir = await getTemporaryDirectory();
    final outputPath = p.join(
      tempDir.path,
      'collage_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(resultBytes);
    return outputFile;
  }

  static Uint8List _buildCollage(Map<String, Uint8List> entries) {
    const canvasWidth = AppConstants.collageWidth;
    const canvasHeight = AppConstants.collageHeight;

    // White background canvas
    final canvas = img.Image(
      width: canvasWidth,
      height: canvasHeight,
      numChannels: 4,
    );
    img.fill(canvas, color: img.ColorFloat32.rgba(245, 245, 245, 255));

    // Layout regions (x, y, maxWidth, maxHeight)
    final regions = {
      'outer': const _Region(700, 50, 350, 450), // top-right
      'top': const _Region(50, 50, 600, 550), // top area
      'bottom': const _Region(50, 620, 600, 550), // middle area
      'dress': const _Region(50, 50, 600, 1100), // full if dress
      'shoes': const _Region(200, 1200, 400, 220), // bottom
      'bag': const _Region(750, 520, 250, 300), // right-middle
      'accessory': const _Region(750, 850, 250, 250), // right-lower
    };

    for (final entry in entries.entries) {
      final category = entry.key;
      final region = regions[category];
      if (region == null) continue;

      final itemImage = img.decodeImage(entry.value);
      if (itemImage == null) continue;

      // Resize to fit region while maintaining aspect ratio
      final resized = _fitToRegion(itemImage, region);

      // Center in region
      final offsetX = region.x + (region.maxWidth - resized.width) ~/ 2;
      final offsetY = region.y + (region.maxHeight - resized.height) ~/ 2;

      img.compositeImage(
        canvas,
        resized,
        dstX: offsetX,
        dstY: offsetY,
      );
    }

    return Uint8List.fromList(img.encodePng(canvas));
  }

  /// 로컬 cutout 경로들로 콜라주 생성
  Future<File> generateCollageFromPaths(
    Map<GarmentCategory, String> paths,
  ) async {
    final entries = <String, Uint8List>{};
    for (final entry in paths.entries) {
      if (entry.value.isEmpty) continue;
      final file = File(entry.value);
      if (await file.exists()) {
        entries[entry.key.name] = await file.readAsBytes();
      }
    }

    final resultBytes = await compute(_buildCollage, entries);

    final tempDir = await getTemporaryDirectory();
    final outputPath = p.join(
      tempDir.path,
      'collage_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(resultBytes);
    return outputFile;
  }

  static img.Image _fitToRegion(img.Image source, _Region region) {
    final scaleX = region.maxWidth / source.width;
    final scaleY = region.maxHeight / source.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    if (scale >= 1.0) return source; // Don't upscale

    return img.copyResize(
      source,
      width: (source.width * scale).round(),
      height: (source.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }
}

class _Region {
  const _Region(this.x, this.y, this.maxWidth, this.maxHeight);
  final int x;
  final int y;
  final int maxWidth;
  final int maxHeight;
}
