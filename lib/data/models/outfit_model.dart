import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/enums.dart';
import 'weather_snapshot.dart';

class OutfitContext {
  const OutfitContext({
    this.styleTag,
    this.timeOfDay,
  });

  final StyleTag? styleTag;
  final String? timeOfDay; // "day" | "night"

  factory OutfitContext.fromMap(Map<String, dynamic> map) {
    return OutfitContext(
      styleTag: map['styleTag'] != null
          ? StyleTag.values.firstWhere(
              (e) => e.name == map['styleTag'],
              orElse: () => StyleTag.casual,
            )
          : null,
      timeOfDay: map['timeOfDay'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        if (styleTag != null) 'styleTag': styleTag!.name,
        if (timeOfDay != null) 'timeOfDay': timeOfDay,
      };
}

class OutfitModel {
  const OutfitModel({
    required this.id,
    required this.dateKey,
    required this.items,
    required this.weatherSnapshot,
    required this.createdAt,
    this.context,
    this.resultImageUrl,
    this.feedback,
    this.reasoning,
  });

  final String id;
  final String dateKey; // "YYYY-MM-DD"
  final List<String> items; // garmentIds
  final WeatherSnapshot weatherSnapshot;
  final DateTime createdAt;
  final OutfitContext? context;
  final String? resultImageUrl;
  final OutfitFeedback? feedback;
  final String? reasoning;

  factory OutfitModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OutfitModel(
      id: doc.id,
      dateKey: data['dateKey'] as String? ?? '',
      items: List<String>.from(data['items'] ?? []),
      weatherSnapshot: WeatherSnapshot.fromMap(
          data['weatherSnapshot'] as Map<String, dynamic>? ?? {}),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      context: data['context'] != null
          ? OutfitContext.fromMap(data['context'] as Map<String, dynamic>)
          : null,
      resultImageUrl: data['resultImageUrl'] as String?,
      feedback: data['feedback'] != null
          ? OutfitFeedback.values.firstWhere(
              (e) => e.name == data['feedback'],
              orElse: () => OutfitFeedback.like,
            )
          : null,
      reasoning: data['reasoning'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'dateKey': dateKey,
        'items': items,
        'weatherSnapshot': weatherSnapshot.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        if (context != null) 'context': context!.toMap(),
        if (resultImageUrl != null) 'resultImageUrl': resultImageUrl,
        if (feedback != null) 'feedback': feedback!.name,
        if (reasoning != null) 'reasoning': reasoning,
      };

  OutfitModel copyWith({
    String? id,
    String? dateKey,
    List<String>? items,
    WeatherSnapshot? weatherSnapshot,
    DateTime? createdAt,
    OutfitContext? context,
    String? resultImageUrl,
    OutfitFeedback? feedback,
    String? reasoning,
  }) {
    return OutfitModel(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      items: items ?? this.items,
      weatherSnapshot: weatherSnapshot ?? this.weatherSnapshot,
      createdAt: createdAt ?? this.createdAt,
      context: context ?? this.context,
      resultImageUrl: resultImageUrl ?? this.resultImageUrl,
      feedback: feedback ?? this.feedback,
      reasoning: reasoning ?? this.reasoning,
    );
  }
}
