import '../../core/constants/enums.dart';

class StylePreference {
  const StylePreference({this.selectedTag});

  final StyleTag? selectedTag;

  static const _key = 'selected_style_tag';

  Map<String, dynamic> toMap() => {
        if (selectedTag != null) _key: selectedTag!.name,
      };

  factory StylePreference.fromMap(Map<String, dynamic> map) {
    final raw = map[_key] as String?;
    final tag = raw != null
        ? StyleTag.values.firstWhere(
            (e) => e.name == raw,
            orElse: () => StyleTag.casual,
          )
        : null;
    return StylePreference(selectedTag: tag);
  }

  StylePreference copyWith({StyleTag? selectedTag, bool clearTag = false}) =>
      StylePreference(
        selectedTag: clearTag ? null : (selectedTag ?? this.selectedTag),
      );
}
