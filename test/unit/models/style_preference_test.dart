import 'package:flutter_test/flutter_test.dart';
import 'package:closet_app/core/constants/enums.dart';
import 'package:closet_app/data/models/style_preference.dart';

void main() {
  group('StylePreference', () {
    test('기본값은 selectedTag가 null이다', () {
      const pref = StylePreference();
      expect(pref.selectedTag, isNull);
    });

    test('toMap / fromMap 라운드트립', () {
      const pref = StylePreference(selectedTag: StyleTag.date);
      final restored = StylePreference.fromMap(pref.toMap());
      expect(restored.selectedTag, StyleTag.date);
    });

    test('null tag는 toMap에 키를 포함하지 않는다', () {
      const pref = StylePreference();
      expect(pref.toMap().containsKey('selected_style_tag'), isFalse);
    });

    test('fromMap 빈 맵이면 selectedTag null', () {
      final pref = StylePreference.fromMap({});
      expect(pref.selectedTag, isNull);
    });

    test('copyWith으로 태그 변경', () {
      const pref = StylePreference(selectedTag: StyleTag.casual);
      final updated = pref.copyWith(selectedTag: StyleTag.formal);
      expect(updated.selectedTag, StyleTag.formal);
    });

    test('copyWith clearTag=true로 태그 해제', () {
      const pref = StylePreference(selectedTag: StyleTag.sport);
      final cleared = pref.copyWith(clearTag: true);
      expect(cleared.selectedTag, isNull);
    });

    test('모든 StyleTag 값을 직렬화/역직렬화할 수 있다', () {
      for (final tag in StyleTag.values) {
        final pref = StylePreference(selectedTag: tag);
        final restored = StylePreference.fromMap(pref.toMap());
        expect(restored.selectedTag, tag);
      }
    });
  });
}
