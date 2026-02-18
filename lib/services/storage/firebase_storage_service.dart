import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase Storage 업로드/다운로드 서비스
class FirebaseStorageService {
  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// 파일 업로드 (진행률 콜백 포함)
  Future<String> uploadFile({
    required String path,
    required File file,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref(path);
    final metadata = contentType != null
        ? SettableMetadata(contentType: contentType)
        : null;

    final uploadTask = ref.putFile(file, metadata);

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress =
            snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// 파일 삭제
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  /// 다운로드 URL 가져오기
  Future<String> getDownloadUrl(String path) async {
    return await _storage.ref(path).getDownloadURL();
  }
}

/// 업로드 상태
enum UploadStatus { idle, uploading, success, error }

class UploadState {
  const UploadState({
    this.status = UploadStatus.idle,
    this.progress = 0.0,
    this.error,
    this.downloadUrl,
  });

  final UploadStatus status;
  final double progress; // 0.0 ~ 1.0
  final String? error;
  final String? downloadUrl;

  UploadState copyWith({
    UploadStatus? status,
    double? progress,
    String? error,
    String? downloadUrl,
  }) {
    return UploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}
