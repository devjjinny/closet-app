import 'dart:async';
import 'dart:io';
import '../../core/constants/enums.dart';
import '../models/garment_model.dart';
import '../../services/database/local_database.dart';
import '../../services/storage/local_storage_service.dart';

class GarmentRepository {
  GarmentRepository({LocalStorageService? storage})
      : _storage = storage ?? LocalStorageService();

  final LocalStorageService _storage;
  final _controller = StreamController<List<GarmentModel>>.broadcast();

  Stream<List<GarmentModel>> watchGarments() {
    _emitAll();
    return _controller.stream;
  }

  Future<List<GarmentModel>> getActiveGarments() async {
    final db = await LocalDatabase.instance.db;
    final rows = await db.query(
      'garments',
      where: 'status = ?',
      whereArgs: [GarmentStatus.active.name],
      orderBy: 'created_at DESC',
    );
    return rows.map(GarmentModel.fromRow).toList();
  }

  Future<GarmentModel> addGarment({
    required GarmentModel garment,
    required File originalFile,
    required File cutoutFile,
    required File thumbFile,
    void Function(String step, double progress)? onProgress,
  }) async {
    final id = LocalStorageService.newId();

    onProgress?.call('원본 저장 중...', 0.1);
    final originalPath = await _storage.saveGarmentImage(
        file: originalFile, garmentId: id, type: 'original');

    onProgress?.call('배경제거 이미지 저장 중...', 0.4);
    final cutoutPath = await _storage.saveGarmentImage(
        file: cutoutFile, garmentId: id, type: 'cutout');

    onProgress?.call('썸네일 저장 중...', 0.7);
    final thumbPath = await _storage.saveGarmentImage(
        file: thumbFile, garmentId: id, type: 'thumb');

    final newGarment = garment.copyWith(
      id: id,
      image: GarmentImage(
        originalPath: originalPath,
        cutoutPath: cutoutPath,
        thumbPath: thumbPath,
      ),
    );

    final db = await LocalDatabase.instance.db;
    await db.insert('garments', newGarment.toRow());
    onProgress?.call('완료!', 1.0);

    _emitAll();
    return newGarment;
  }

  Future<void> updateGarment(GarmentModel garment) async {
    final db = await LocalDatabase.instance.db;
    await db.update(
      'garments',
      garment.copyWith(updatedAt: DateTime.now()).toRow(),
      where: 'id = ?',
      whereArgs: [garment.id],
    );
    _emitAll();
  }

  Future<void> archiveGarment(String garmentId) async {
    final db = await LocalDatabase.instance.db;
    final rows = await db.query('garments', where: 'id = ?', whereArgs: [garmentId]);
    if (rows.isEmpty) return;
    final garment = GarmentModel.fromRow(rows.first)
        .copyWith(status: GarmentStatus.archived, updatedAt: DateTime.now());
    await db.update('garments', garment.toRow(),
        where: 'id = ?', whereArgs: [garmentId]);
    _emitAll();
  }

  Future<void> deleteGarment(String garmentId) async {
    await _storage.deleteGarmentFiles(garmentId);
    final db = await LocalDatabase.instance.db;
    await db.delete('garments', where: 'id = ?', whereArgs: [garmentId]);
    _emitAll();
  }

  Future<void> _emitAll() async {
    final garments = await getActiveGarments();
    _controller.add(garments);
  }

  void dispose() => _controller.close();
}
