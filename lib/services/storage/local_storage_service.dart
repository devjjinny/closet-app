import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class LocalStorageService {
  static const _uuid = Uuid();

  Future<String> _baseDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<String> saveGarmentImage({
    required File file,
    required String garmentId,
    required String type, // 'original' | 'cutout' | 'thumb'
  }) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base, 'garments', garmentId));
    await dir.create(recursive: true);
    final ext = type == 'original' ? 'jpg' : (type == 'cutout' ? 'png' : 'webp');
    final dest = p.join(dir.path, '$type.$ext');
    await file.copy(dest);
    return dest;
  }

  Future<String> saveOutfitCollage({
    required File file,
    required String outfitId,
  }) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base, 'outfits', outfitId));
    await dir.create(recursive: true);
    final dest = p.join(dir.path, 'collage.webp');
    await file.copy(dest);
    return dest;
  }

  Future<void> deleteGarmentFiles(String garmentId) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base, 'garments', garmentId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> deleteOutfitFiles(String outfitId) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base, 'outfits', outfitId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  static String newId() => _uuid.v4();
}
