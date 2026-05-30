import 'package:closet_app/core/constants/enums.dart';
import 'package:closet_app/data/models/garment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GarmentImage', () {
    test('toMap / fromMap roundtrip', () {
      const image = GarmentImage(
        originalPath: '/docs/garments/001/original.jpg',
        cutoutPath: '/docs/garments/001/cutout.png',
        thumbPath: '/docs/garments/001/thumb.webp',
        width: 1080,
        height: 1440,
      );

      final map = image.toMap();
      final restored = GarmentImage.fromMap(map);

      expect(restored.originalPath, image.originalPath);
      expect(restored.cutoutPath, image.cutoutPath);
      expect(restored.thumbPath, image.thumbPath);
      expect(restored.width, image.width);
      expect(restored.height, image.height);
    });

    test('fromMap handles missing optional fields', () {
      final image = GarmentImage.fromMap({
        'originalPath': '/a',
        'cutoutPath': '/b',
        'thumbPath': '/c',
      });

      expect(image.width, isNull);
      expect(image.height, isNull);
    });

    test('fromMap defaults empty strings for missing paths', () {
      final image = GarmentImage.fromMap({});
      expect(image.originalPath, '');
      expect(image.cutoutPath, '');
      expect(image.thumbPath, '');
    });
  });

  group('GarmentModel', () {
    GarmentModel _base() => GarmentModel(
          id: 'g001',
          category: GarmentCategory.top,
          dominantHex: '#FF5733',
          warmth: 3,
          formality: 2,
          waterproof: false,
          image: const GarmentImage(
            originalPath: '/docs/o.jpg',
            cutoutPath: '/docs/c.png',
            thumbPath: '/docs/t.webp',
          ),
          createdAt: DateTime(2026, 4, 18),
          styleTags: [StyleTag.casual],
        );

    test('toRow includes required fields', () {
      final row = _base().toRow();
      expect(row['category'], 'top');
      expect(row['dominant_hex'], '#FF5733');
      expect(row['warmth'], 3);
      expect(row['formality'], 2);
      expect(row['waterproof'], 0);
      expect(row['status'], 'active');
    });

    test('toRow omits null name', () {
      expect(_base().toRow()['name'], isNull);
    });

    test('toRow includes name when set', () {
      final g = _base().copyWith(name: '흰 린넨 셔츠');
      expect(g.toRow()['name'], '흰 린넨 셔츠');
    });

    test('copyWith preserves unmodified fields', () {
      final original = _base();
      final updated = original.copyWith(warmth: 5);

      expect(updated.warmth, 5);
      expect(updated.category, original.category);
      expect(updated.dominantHex, original.dominantHex);
      expect(updated.image, original.image);
    });

    test('copyWith id updates correctly', () {
      final g = _base().copyWith(id: 'new-id');
      expect(g.id, 'new-id');
    });

    test('category serialization covers all values', () {
      for (final cat in GarmentCategory.values) {
        final model = _base().copyWith(category: cat);
        expect(model.toRow()['category'], cat.name);
      }
    });

    test('status defaults to active', () {
      expect(_base().status, GarmentStatus.active);
      expect(_base().toRow()['status'], 'active');
    });
  });
}
