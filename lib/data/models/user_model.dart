import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/enums.dart';

class UserPrefs {
  const UserPrefs({
    this.units = UnitSystem.metric,
    this.defaultStyleTag,
    this.locationCity,
    this.lastKnownLat,
    this.lastKnownLon,
  });

  final UnitSystem units;
  final StyleTag? defaultStyleTag;
  final String? locationCity;
  final double? lastKnownLat;
  final double? lastKnownLon;

  factory UserPrefs.fromMap(Map<String, dynamic> map) {
    return UserPrefs(
      units: UnitSystem.values.firstWhere(
        (e) => e.name == map['units'],
        orElse: () => UnitSystem.metric,
      ),
      defaultStyleTag: map['defaultStyleTag'] != null
          ? StyleTag.values.firstWhere(
              (e) => e.name == map['defaultStyleTag'],
              orElse: () => StyleTag.casual,
            )
          : null,
      locationCity: map['locationCity'] as String?,
      lastKnownLat: (map['lastKnownLat'] as num?)?.toDouble(),
      lastKnownLon: (map['lastKnownLon'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'units': units.name,
        if (defaultStyleTag != null) 'defaultStyleTag': defaultStyleTag!.name,
        if (locationCity != null) 'locationCity': locationCity,
        if (lastKnownLat != null) 'lastKnownLat': lastKnownLat,
        if (lastKnownLon != null) 'lastKnownLon': lastKnownLon,
      };
}

class UserModel {
  const UserModel({
    required this.uid,
    required this.createdAt,
    this.prefs = const UserPrefs(),
  });

  final String uid;
  final DateTime createdAt;
  final UserPrefs prefs;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      prefs: UserPrefs.fromMap(data['prefs'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'createdAt': FieldValue.serverTimestamp(),
        'prefs': prefs.toMap(),
      };
}
