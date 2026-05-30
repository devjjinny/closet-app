import '../../core/constants/enums.dart';

class UserPrefs {
  const UserPrefs({
    this.units = UnitSystem.metric,
    this.gender,
    this.defaultStyleTag,
  });

  final UnitSystem units;
  final Gender? gender;
  final StyleTag? defaultStyleTag;

  factory UserPrefs.fromMap(Map<String, dynamic> map) {
    return UserPrefs(
      units: UnitSystem.values.firstWhere(
        (e) => e.name == map['units'],
        orElse: () => UnitSystem.metric,
      ),
      gender: map['gender'] != null
          ? Gender.values.firstWhere(
              (e) => e.name == map['gender'],
              orElse: () => Gender.male,
            )
          : null,
      defaultStyleTag: map['defaultStyleTag'] != null
          ? StyleTag.values.firstWhere(
              (e) => e.name == map['defaultStyleTag'],
              orElse: () => StyleTag.casual,
            )
          : null,
    );
  }

  UserPrefs copyWith({Gender? gender}) => UserPrefs(
        units: units,
        gender: gender ?? this.gender,
        defaultStyleTag: defaultStyleTag,
      );

  Map<String, dynamic> toMap() => {
        'units': units.name,
        if (gender != null) 'gender': gender!.name,
        if (defaultStyleTag != null) 'defaultStyleTag': defaultStyleTag!.name,
      };
}
