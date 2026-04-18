import 'dart:io';
import 'dart:typed_data';
import 'package:closet_app/core/constants/enums.dart';
import 'package:closet_app/services/image/collage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // path_provider 채널 mock — 시스템 temp 디렉토리 반환
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getTemporaryDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    });
  });

  group('CollageService', () {
    test('generateCollage with empty map produces a valid PNG canvas', () async {
      final service = CollageService();
      final file = await service.generateCollage({});

      expect(await file.exists(), isTrue);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      expect(image, isNotNull);
      expect(image!.width, 1080);
      expect(image.height, 1440);
    });

    test('generateCollage with one item produces 1080×1440 PNG', () async {
      final service = CollageService();

      // 50×50 짜리 단색 PNG 생성
      final testImg = img.Image(width: 50, height: 50, numChannels: 4);
      img.fill(testImg, color: img.ColorFloat32.rgba(0, 128, 255, 255));
      final pngBytes = Uint8List.fromList(img.encodePng(testImg));

      final inputFile = await _writeTempFile('test_top.png', pngBytes);

      final collageFile = await service.generateCollage({
        GarmentCategory.top: inputFile,
      });

      final resultBytes = await collageFile.readAsBytes();
      final result = img.decodeImage(resultBytes);
      expect(result, isNotNull);
      expect(result!.width, 1080);
      expect(result.height, 1440);
    });

    test('generateCollage with all categories produces 1080×1440 PNG', () async {
      final service = CollageService();

      final pngBytes = _makeColorPng(200, 200, 200);

      final files = {
        for (final cat in [
          GarmentCategory.top,
          GarmentCategory.bottom,
          GarmentCategory.outer,
          GarmentCategory.shoes,
          GarmentCategory.accessory,
        ])
          cat: await _writeTempFile('${cat.name}.png', pngBytes),
      };

      final collageFile = await service.generateCollage(files);
      final result = img.decodeImage(await collageFile.readAsBytes());
      expect(result, isNotNull);
      expect(result!.width, 1080);
      expect(result.height, 1440);
    });
  });
}

// ── helpers ──────────────────────────────────────────────────────

Uint8List _makeColorPng(int r, int g, int b) {
  final image = img.Image(width: 100, height: 100, numChannels: 4);
  img.fill(image, color: img.ColorFloat32.rgba(r.toDouble(), g.toDouble(), b.toDouble(), 255));
  return Uint8List.fromList(img.encodePng(image));
}

Future<File> _writeTempFile(String name, Uint8List bytes) async {
  final file = File('${Directory.systemTemp.path}/$name');
  await file.writeAsBytes(bytes);
  return file;
}
