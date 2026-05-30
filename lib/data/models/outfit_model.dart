import 'dart:convert';
import '../../core/constants/enums.dart';
import 'weather_snapshot.dart';

class OutfitModel {
  const OutfitModel({
    required this.id,
    required this.dateKey,
    required this.items,
    required this.weatherSnapshot,
    required this.createdAt,
    this.collagePath,
    this.feedback,
    this.reasoning,
  });

  final String id;
  final String dateKey;
  final List<String> items;
  final WeatherSnapshot weatherSnapshot;
  final DateTime createdAt;
  final String? collagePath;
  final OutfitFeedback? feedback;
  final String? reasoning;

  factory OutfitModel.fromRow(Map<String, dynamic> row) {
    return OutfitModel(
      id: row['id'] as String,
      dateKey: row['date_key'] as String? ?? '',
      items: List<String>.from(jsonDecode(row['items'] as String? ?? '[]')),
      weatherSnapshot: WeatherSnapshot.fromMap(
          jsonDecode(row['weather_snapshot'] as String? ?? '{}')),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      collagePath: row['collage_path'] as String?,
      feedback: row['feedback'] != null
          ? OutfitFeedback.values.firstWhere(
              (e) => e.name == row['feedback'],
              orElse: () => OutfitFeedback.like,
            )
          : null,
      reasoning: row['reasoning'] as String?,
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'date_key': dateKey,
        'items': jsonEncode(items),
        'weather_snapshot': jsonEncode(weatherSnapshot.toMap()),
        'created_at': createdAt.millisecondsSinceEpoch,
        'collage_path': collagePath,
        'feedback': feedback?.name,
        'reasoning': reasoning,
      };

  OutfitModel copyWith({
    String? id,
    String? dateKey,
    List<String>? items,
    WeatherSnapshot? weatherSnapshot,
    DateTime? createdAt,
    String? collagePath,
    OutfitFeedback? feedback,
    String? reasoning,
  }) {
    return OutfitModel(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      items: items ?? this.items,
      weatherSnapshot: weatherSnapshot ?? this.weatherSnapshot,
      createdAt: createdAt ?? this.createdAt,
      collagePath: collagePath ?? this.collagePath,
      feedback: feedback ?? this.feedback,
      reasoning: reasoning ?? this.reasoning,
    );
  }
}
