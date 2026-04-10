import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/enums.dart';

class GarmentImage {
  const GarmentImage({
    required this.originalUrl,
    required this.cutoutUrl,
    required this.thumbUrl,
    this.width,
    this.height,
  });

  final String originalUrl;
  final String cutoutUrl;
  final String thumbUrl;
  final int? width;
  final int? height;

  factory GarmentImage.fromMap(Map<String, dynamic> map) {
    return GarmentImage(
      originalUrl: map['originalUrl'] as String? ?? '',
      cutoutUrl: map['cutoutUrl'] as String? ?? '',
      thumbUrl: map['thumbUrl'] as String? ?? '',
      width: map['width'] as int?,
      height: map['height'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'originalUrl': originalUrl,
        'cutoutUrl': cutoutUrl,
        'thumbUrl': thumbUrl,
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
  final String? name; // 사용자가 지정한 옷 이름 (예: "흰 린넨 셔츠")
  final String dominantHex;
  final int warmth; // 1-5
  final int formality; // 1-5
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

  factory GarmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GarmentModel(
      id: doc.id,
      category: GarmentCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => GarmentCategory.top,
      ),
      dominantHex: data['dominantHex'] as String? ?? '#000000',
      warmth: (data['warmth'] as num?)?.toInt() ?? 3,
      formality: (data['formality'] as num?)?.toInt() ?? 3,
      waterproof: data['waterproof'] as bool? ?? false,
      image: GarmentImage.fromMap(
          data['image'] as Map<String, dynamic>? ?? {}),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      status: GarmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GarmentStatus.active,
      ),
      subCategory: data['subCategory'] as String?,
      palette: List<String>.from(data['palette'] ?? []),
      seasonTags: (data['seasonTags'] as List<dynamic>?)
              ?.map((e) => Season.values.firstWhere(
                    (s) => s.name == e,
                    orElse: () => Season.spring,
                  ))
              .toList() ??
          [],
      styleTags: (data['styleTags'] as List<dynamic>?)
              ?.map((e) => StyleTag.values.firstWhere(
                    (s) => s.name == e,
                    orElse: () => StyleTag.casual,
                  ))
              .toList() ??
          [],
      name: data['name'] as String?,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'category': category.name,
        'dominantHex': dominantHex,
        'warmth': warmth,
        'formality': formality,
        'waterproof': waterproof,
        'image': image.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        if (updatedAt != null) 'updatedAt': FieldValue.serverTimestamp(),
        'status': status.name,
        if (name != null) 'name': name,
        if (subCategory != null) 'subCategory': subCategory,
        'palette': palette,
        'seasonTags': seasonTags.map((e) => e.name).toList(),
        'styleTags': styleTags.map((e) => e.name).toList(),
        if (notes != null) 'notes': notes,
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
