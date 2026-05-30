import 'dart:convert';
import '../../core/constants/enums.dart';

class GarmentImage {
  const GarmentImage({
    required this.originalPath,
    required this.cutoutPath,
    required this.thumbPath,
    this.width,
    this.height,
  });

  final String originalPath;
  final String cutoutPath;
  final String thumbPath;
  final int? width;
  final int? height;

  factory GarmentImage.fromMap(Map<String, dynamic> map) {
    return GarmentImage(
      originalPath: map['originalPath'] as String? ?? '',
      cutoutPath: map['cutoutPath'] as String? ?? '',
      thumbPath: map['thumbPath'] as String? ?? '',
      width: map['width'] as int?,
      height: map['height'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'originalPath': originalPath,
        'cutoutPath': cutoutPath,
        'thumbPath': thumbPath,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };
}

class GarmentModel {
  const GarmentModel({
    required this.id,
    required this.category,
    required this.dominantHex,
    required this.warmth,
    required this.formality,
    required this.waterproof,
    required this.image,
    required this.createdAt,
    this.name,
    this.updatedAt,
    this.status = GarmentStatus.active,
    this.subCategory,
    this.palette = const [],
    this.seasonTags = const [],
    this.styleTags = const [],
    this.notes,
  });

  final String id;
  final GarmentCategory category;
  final String? name;
  final String dominantHex;
  final int warmth;
  final int formality;
  final bool waterproof;
  final GarmentImage image;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final GarmentStatus status;
  final String? subCategory;
  final List<String> palette;
  final List<Season> seasonTags;
  final List<StyleTag> styleTags;
  final String? notes;

  factory GarmentModel.fromRow(Map<String, dynamic> row) {
    return GarmentModel(
      id: row['id'] as String,
      category: GarmentCategory.values.firstWhere(
        (e) => e.name == row['category'],
        orElse: () => GarmentCategory.top,
      ),
      name: row['name'] as String?,
      dominantHex: row['dominant_hex'] as String? ?? '#000000',
      warmth: row['warmth'] as int? ?? 3,
      formality: row['formality'] as int? ?? 3,
      waterproof: (row['waterproof'] as int? ?? 0) == 1,
      image: GarmentImage(
        originalPath: row['original_path'] as String? ?? '',
        cutoutPath: row['cutout_path'] as String? ?? '',
        thumbPath: row['thumb_path'] as String? ?? '',
      ),
      status: GarmentStatus.values.firstWhere(
        (e) => e.name == row['status'],
        orElse: () => GarmentStatus.active,
      ),
      subCategory: row['sub_category'] as String?,
      palette: List<String>.from(jsonDecode(row['palette'] as String? ?? '[]')),
      seasonTags: (jsonDecode(row['season_tags'] as String? ?? '[]') as List)
          .map((e) => Season.values.firstWhere(
                (s) => s.name == e,
                orElse: () => Season.spring,
              ))
          .toList(),
      styleTags: (jsonDecode(row['style_tags'] as String? ?? '[]') as List)
          .map((e) => StyleTag.values.firstWhere(
                (s) => s.name == e,
                orElse: () => StyleTag.casual,
              ))
          .toList(),
      notes: row['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: row['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int)
          : null,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'category': category.name,
        'name': name,
        'dominant_hex': dominantHex,
        'warmth': warmth,
        'formality': formality,
        'waterproof': waterproof ? 1 : 0,
        'original_path': image.originalPath,
        'cutout_path': image.cutoutPath,
        'thumb_path': image.thumbPath,
        'status': status.name,
        'sub_category': subCategory,
        'palette': jsonEncode(palette),
        'season_tags': jsonEncode(seasonTags.map((e) => e.name).toList()),
        'style_tags': jsonEncode(styleTags.map((e) => e.name).toList()),
        'notes': notes,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt?.millisecondsSinceEpoch,
      };

  GarmentModel copyWith({
    String? id,
    GarmentCategory? category,
    String? name,
    String? dominantHex,
    int? warmth,
    int? formality,
    bool? waterproof,
    GarmentImage? image,
    DateTime? createdAt,
    DateTime? updatedAt,
    GarmentStatus? status,
    String? subCategory,
    List<String>? palette,
    List<Season>? seasonTags,
    List<StyleTag>? styleTags,
    String? notes,
  }) {
    return GarmentModel(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      dominantHex: dominantHex ?? this.dominantHex,
      warmth: warmth ?? this.warmth,
      formality: formality ?? this.formality,
      waterproof: waterproof ?? this.waterproof,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      subCategory: subCategory ?? this.subCategory,
      palette: palette ?? this.palette,
      seasonTags: seasonTags ?? this.seasonTags,
      styleTags: styleTags ?? this.styleTags,
      notes: notes ?? this.notes,
    );
  }
}
