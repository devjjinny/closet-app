import 'dart:async';
import 'dart:io';
import '../../core/constants/enums.dart';
import '../models/outfit_model.dart';
import '../../services/database/local_database.dart';
import '../../services/storage/local_storage_service.dart';

class OutfitRepository {
  OutfitRepository({LocalStorageService? storage})
    : _storage = storage ?? LocalStorageService();

  final LocalStorageService _storage;
  final _controller = StreamController<List<OutfitModel>>.broadcast();

  Stream<List<OutfitModel>> watchOutfits() {
    _emitAll();
    return _controller.stream;
  }

  Future<List<OutfitModel>> getRecentOutfits({int days = 7}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final db = await LocalDatabase.instance.db;
    final rows = await db.query(
      'outfits',
      where: 'created_at > ?',
      whereArgs: [cutoff],
      orderBy: 'created_at DESC',
    );
    return rows.map(OutfitModel.fromRow).toList();
  }

  Future<List<OutfitModel>> getLikedOutfits() async {
    final db = await LocalDatabase.instance.db;
    final rows = await db.query(
      'outfits',
      where: 'feedback = ?',
      whereArgs: ['like'],
      orderBy: 'created_at DESC',
    );
    return rows.map(OutfitModel.fromRow).toList();
  }

  Future<List<OutfitModel>> getOutfitsByDate(String dateKey) async {
    final db = await LocalDatabase.instance.db;
    final rows = await db.query(
      'outfits',
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );
    return rows.map(OutfitModel.fromRow).toList();
  }

  Future<OutfitModel> saveOutfit({
    required OutfitModel outfit,
    File? collageFile,
    void Function(double progress)? onProgress,
  }) async {
    final id = LocalStorageService.newId();
    String? collagePath;

    if (collageFile != null) {
      onProgress?.call(0.0);
      collagePath = await _storage.saveOutfitCollage(
        file: collageFile,
        outfitId: id,
      );
      onProgress?.call(0.8);
    }

    final newOutfit = outfit.copyWith(id: id, collagePath: collagePath);
    final db = await LocalDatabase.instance.db;
    await db.insert('outfits', newOutfit.toRow());
    onProgress?.call(1.0);

    await _emitAll();
    return newOutfit;
  }

  Future<void> updateFeedback(String outfitId, OutfitFeedback feedback) async {
    final db = await LocalDatabase.instance.db;
    await db.update(
      'outfits',
      {'feedback': feedback.name},
      where: 'id = ?',
      whereArgs: [outfitId],
    );
  }

  Future<void> deleteOutfit(String outfitId) async {
    await _storage.deleteOutfitFiles(outfitId);
    final db = await LocalDatabase.instance.db;
    await db.delete('outfits', where: 'id = ?', whereArgs: [outfitId]);
    await _emitAll();
  }

  Future<void> _emitAll() async {
    final db = await LocalDatabase.instance.db;
    final rows = await db.query('outfits', orderBy: 'created_at DESC');
    _controller.add(rows.map(OutfitModel.fromRow).toList());
  }

  void dispose() => _controller.close();
}
