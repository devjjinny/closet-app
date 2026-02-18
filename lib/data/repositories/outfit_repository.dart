import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../models/outfit_model.dart';
import '../../services/storage/firebase_storage_service.dart';

class OutfitRepository {
  OutfitRepository({
    FirebaseFirestore? firestore,
    FirebaseStorageService? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorageService();

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _storage;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('outfits');

  /// 코디 히스토리 스트림
  Stream<List<OutfitModel>> watchOutfits(String uid) {
    return _collection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => OutfitModel.fromFirestore(doc)).toList());
  }

  /// 최근 N일 코디 조회 (추천 엔진용)
  Future<List<OutfitModel>> getRecentOutfits(
    String uid, {
    int days = 7,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _collection(uid)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => OutfitModel.fromFirestore(doc))
        .toList();
  }

  /// 특정 날짜의 코디 조회
  Future<List<OutfitModel>> getOutfitsByDate(
    String uid,
    String dateKey,
  ) async {
    final snapshot = await _collection(uid)
        .where('dateKey', isEqualTo: dateKey)
        .get();
    return snapshot.docs
        .map((doc) => OutfitModel.fromFirestore(doc))
        .toList();
  }

  /// 코디 저장 (콜라주 이미지 포함)
  Future<OutfitModel> saveOutfit({
    required String uid,
    required OutfitModel outfit,
    File? collageFile,
    void Function(double progress)? onProgress,
  }) async {
    final docRef = _collection(uid).doc();
    final outfitId = docRef.id;
    String? imageUrl;

    if (collageFile != null) {
      onProgress?.call(0.0);
      imageUrl = await _storage.uploadFile(
        path: AppConstants.outfitCollagePath(uid, outfitId),
        file: collageFile,
        contentType: 'image/webp',
        onProgress: (p) => onProgress?.call(p * 0.8),
      );
    }

    onProgress?.call(0.8);

    final newOutfit = outfit.copyWith(
      id: outfitId,
      resultImageUrl: imageUrl,
    );

    await docRef.set(newOutfit.toFirestore());
    onProgress?.call(1.0);

    return newOutfit;
  }

  /// 피드백 업데이트
  Future<void> updateFeedback(
    String uid,
    String outfitId,
    OutfitFeedback feedback,
  ) async {
    await _collection(uid).doc(outfitId).update({
      'feedback': feedback.name,
    });
  }

  /// 코디 삭제
  Future<void> deleteOutfit(String uid, String outfitId) async {
    await _storage
        .deleteFile(AppConstants.outfitCollagePath(uid, outfitId));
    await _collection(uid).doc(outfitId).delete();
  }
}
