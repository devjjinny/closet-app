import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../models/garment_model.dart';
import '../../services/storage/firebase_storage_service.dart';

class GarmentRepository {
  GarmentRepository({
    FirebaseFirestore? firestore,
    FirebaseStorageService? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorageService();

  final FirebaseFirestore _firestore;
  final FirebaseStorageService _storage;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('garments');

  /// 옷장 아이템 스트림 (실시간)
  Stream<List<GarmentModel>> watchGarments(String uid) {
    return _collection(uid)
        .where('status', isEqualTo: GarmentStatus.active.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GarmentModel.fromFirestore(doc)).toList());
  }

  /// 모든 active 아이템 가져오기 (한 번)
  Future<List<GarmentModel>> getActiveGarments(String uid) async {
    final snapshot = await _collection(uid)
        .where('status', isEqualTo: GarmentStatus.active.name)
        .get();
    return snapshot.docs
        .map((doc) => GarmentModel.fromFirestore(doc))
        .toList();
  }

  /// 카테고리 필터
  Future<List<GarmentModel>> getGarmentsByCategory(
    String uid,
    GarmentCategory category,
  ) async {
    final snapshot = await _collection(uid)
        .where('status', isEqualTo: GarmentStatus.active.name)
        .where('category', isEqualTo: category.name)
        .get();
    return snapshot.docs
        .map((doc) => GarmentModel.fromFirestore(doc))
        .toList();
  }

  /// 옷 등록 (이미지 업로드 + Firestore 문서 생성)
  Future<GarmentModel> addGarment({
    required String uid,
    required GarmentModel garment,
    required File originalFile,
    required File cutoutFile,
    required File thumbFile,
    void Function(String step, double progress)? onProgress,
  }) async {
    // Create document first to get ID
    final docRef = _collection(uid).doc();
    final garmentId = docRef.id;

    // Upload images in sequence (each depends on getting URL)
    onProgress?.call('원본 업로드 중...', 0.0);
    final originalUrl = await _storage.uploadFile(
      path: AppConstants.garmentOriginalPath(uid, garmentId),
      file: originalFile,
      contentType: 'image/jpeg',
      onProgress: (p) => onProgress?.call('원본 업로드 중...', p * 0.3),
    );

    onProgress?.call('배경제거 이미지 업로드 중...', 0.3);
    final cutoutUrl = await _storage.uploadFile(
      path: AppConstants.garmentCutoutPath(uid, garmentId),
      file: cutoutFile,
      contentType: 'image/png',
      onProgress: (p) => onProgress?.call('배경제거 이미지 업로드 중...', 0.3 + p * 0.3),
    );

    onProgress?.call('썸네일 업로드 중...', 0.6);
    final thumbUrl = await _storage.uploadFile(
      path: AppConstants.garmentThumbPath(uid, garmentId),
      file: thumbFile,
      contentType: 'image/webp',
      onProgress: (p) => onProgress?.call('썸네일 업로드 중...', 0.6 + p * 0.2),
    );

    onProgress?.call('저장 중...', 0.8);

    final image = GarmentImage(
      originalUrl: originalUrl,
      cutoutUrl: cutoutUrl,
      thumbUrl: thumbUrl,
    );

    final newGarment = garment.copyWith(
      id: garmentId,
      image: image,
    );

    await docRef.set(newGarment.toFirestore());

    onProgress?.call('완료!', 1.0);
    return newGarment;
  }

  /// 옷 수정
  Future<void> updateGarment(String uid, GarmentModel garment) async {
    await _collection(uid).doc(garment.id).update({
      ...garment.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 옷 보관 (soft delete)
  Future<void> archiveGarment(String uid, String garmentId) async {
    await _collection(uid).doc(garmentId).update({
      'status': GarmentStatus.archived.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 옷 삭제 (hard delete + storage 정리)
  Future<void> deleteGarment(String uid, String garmentId) async {
    // Delete storage files
    await Future.wait([
      _storage.deleteFile(AppConstants.garmentOriginalPath(uid, garmentId)),
      _storage.deleteFile(AppConstants.garmentCutoutPath(uid, garmentId)),
      _storage.deleteFile(AppConstants.garmentThumbPath(uid, garmentId)),
    ]);

    // Delete Firestore document
    await _collection(uid).doc(garmentId).delete();
  }
}
