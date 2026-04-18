import 'package:closet_app/core/constants/enums.dart';
import 'package:closet_app/data/models/garment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GarmentImage', () {
    test('toMap / fromMap roundtrip', () {
      const image = GarmentImage(
        originalUrl: 'https://example.com/original.jpg',
        cutoutUrl: 'https://example.com/cutout.png',
        thumbUrl: 'https://example.com/thumb.webp',
        width: 1080,
        height: 1440,
      );

      final map = image.toMap();
      final restored = GarmentImage.fromMap(map);

      expect(restored.originalUrl, image.originalUrl);
      expect(restored.cutoutUrl, image.cutoutUrl);
      expect(restored.thumbUrl, image.thumbUrl);
      expect(restored.width, image.width);
      expect(restored.height, image.height);
    });

    test('fromMap handles missing optional fields', () {
      final image = GarmentImage.fromMap({
        'originalUrl': 'https://a.com',
        'cutoutUrl': 'https://b.com',
        'thumbUrl': 'https://c.com',
      });

      expect(image.width, isNull);
      expect(image.height, isNull);
    });

    test('fromMap defaults empty strings for missing URLs', () {
      final image = GarmentImage.fromMap({});
      expect(image.originalUrl, '');
      expect(image.cutoutUrl, '');
      expect(image.thumbUrl, '');
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
            originalUrl: 'https://a.com/o.jpg',
            cutoutUrl: 'https://a.com/c.png',
            thumbUrl: 'https://a.com/t.webp',
          ),
          createdAt: DateTime(2026, 4, 18),
          styleTags: [StyleTag.casual],
        );

    test('toFirestore includes required fields', () {
      final map = _base().toFirestore();
      expect(map['category'], 'top');
      expect(map['dominantHex'], '#FF5733');
      expect(map['warmth'], 3);
      expect(map['formality'], 2);
      expect(map['waterproof'], false);
      expect(map['status'], 'active');
      expect(map['styleTags'], ['casual']);
    });

    test('toFirestore omits null name', () {
      expect(_base().toFirestore().containsKey('name'), isFalse);
    });

    test('toFirestore includes name when set', () {
      final g = _base().copyWith(name: '흰 린넨 셔츠');
      expect(g.toFirestore()['name'], '흰 린넨 셔츠');
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
        expect(model.toFirestore()['category'], cat.name);
      }
    });

    test('styleTags roundtrip via toFirestore', () {
      final model = _base().copyWith(
        styleTags: [StyleTag.casual, StyleTag.formal],
      );
      final map = model.toFirestore();
      expect(map['styleTags'], ['casual', 'formal']);
    });

    test('status defaults to active', () {
      expect(_base().status, GarmentStatus.active);
      expect(_base().toFirestore()['status'], 'active');
    });
  });
}
