import 'package:closet_app/core/constants/enums.dart';
import 'package:closet_app/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserPrefs', () {
    test('fromMap parses gender correctly', () {
      final prefs = UserPrefs.fromMap({'gender': 'female'});
      expect(prefs.gender, Gender.female);
    });

    test('fromMap defaults gender to null when missing', () {
      final prefs = UserPrefs.fromMap({});
      expect(prefs.gender, isNull);
    });

    test('toMap includes gender when set', () {
      const prefs = UserPrefs(gender: Gender.male);
      expect(prefs.toMap()['gender'], 'male');
    });

    test('toMap omits gender when null', () {
      const prefs = UserPrefs();
      expect(prefs.toMap().containsKey('gender'), isFalse);
    });

    test('copyWith updates gender', () {
      const prefs = UserPrefs();
      final updated = prefs.copyWith(gender: Gender.female);
      expect(updated.gender, Gender.female);
    });

    test('roundtrip: toMap → fromMap preserves gender', () {
      const original = UserPrefs(gender: Gender.female);
      final restored = UserPrefs.fromMap(original.toMap());
      expect(restored.gender, original.gender);
    });
  });

  group('Gender enum', () {
    test('labels are correct', () {
      expect(Gender.male.label, '남성');
      expect(Gender.female.label, '여성');
    });
  });
}
