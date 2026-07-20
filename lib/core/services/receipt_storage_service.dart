import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// İşlemlere iliştirilen fiş/fotoğraf görsellerinin cihaz-yerel deposu.
///
/// Görseller `belgelerDizini/receipts/<uuid>.<ext>` altında saklanır. Modelde
/// yalnız dosya ADI tutulur (mutlak yol reinstall/cihaz değişince değişir);
/// görüntülerken [fileFor] ile çözülür. Binary yedeğe girmez — bu depo
/// tamamen cihaza özeldir.
///
/// Orphan (yörünge) dosya bırakmamak için: görsel SEÇİLİNCE değil, işlem
/// KAYDEDİLİNCE [persist] çağrılır. Seçim iptal edilirse hiçbir şey yazılmaz.
@lazySingleton
class ReceiptStorageService {
  static const String _subDir = 'receipts';

  final Uuid _uuid;
  Directory? _cachedDir;

  ReceiptStorageService() : _uuid = const Uuid();

  /// Test için: path_provider'ı atlayıp taban dizini enjekte eder.
  @visibleForTesting
  ReceiptStorageService.withBaseDir(Directory baseDir, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid(),
        _cachedDir = Directory('${baseDir.path}/$_subDir');

  Future<Directory> _dir() async {
    final cached = _cachedDir;
    if (cached != null) {
      if (!await cached.exists()) await cached.create(recursive: true);
      return cached;
    }
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_subDir');
    if (!await dir.exists()) await dir.create(recursive: true);
    _cachedDir = dir;
    return dir;
  }

  /// [sourcePath]'teki görseli kalıcı dizine `<uuid>.<ext>` adıyla kopyalar ve
  /// yalnız dosya ADINI döndürür (modele bu ad yazılır).
  Future<String> persist(String sourcePath) async {
    final dir = await _dir();
    final name = '${_uuid.v4()}${_extensionOf(sourcePath)}';
    await File(sourcePath).copy('${dir.path}/$name');
    return name;
  }

  /// Dosya adını mutlak yola çözer. Dosya var OLMAYABİLİR (geri yüklenen
  /// yedekte binary taşınmaz) — çağıran [File.exists] ile kontrol etmeli.
  Future<File> fileFor(String name) async {
    final dir = await _dir();
    return File('${dir.path}/$name');
  }

  Future<bool> exists(String name) async => (await fileFor(name)).exists();

  /// Verilen fişi siler (yoksa sessizce geçer).
  Future<void> delete(String name) async {
    final f = await fileFor(name);
    if (await f.exists()) await f.delete();
  }

  /// Tüm receipts dizinini boşaltır ("tüm veriyi sil" gizlilik özelliği).
  Future<void> clearAll() async => pruneExcept(const {});

  /// [keep] kümesindeki dosya adları DIŞINDAKİ tüm fişleri siler.
  ///
  /// Yedek geri yükleme sonrası yörünge (orphan) temizliği için: geri yüklenen
  /// işlemlerin hâlâ atıfta bulunduğu görseller korunur (aynı-cihaz geri
  /// yüklemede kayıp olmaz), artık atıfsız kalanlar silinir. [keep] boşsa
  /// hepsini siler.
  Future<void> pruneExcept(Set<String> keep) async {
    final dir = await _dir();
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File && !keep.contains(entity.uri.pathSegments.last)) {
        try {
          await entity.delete();
        } catch (_) {
          // Tek dosya silinemezse tüm temizliği bozma.
        }
      }
    }
  }

  /// Kaynak yolundan güvenli bir uzantı çıkarır; bulunamazsa `.jpg`.
  String _extensionOf(String path) {
    final slash = path.lastIndexOf('/');
    final dot = path.lastIndexOf('.');
    if (dot > slash && dot != -1) {
      final ext = path.substring(dot).toLowerCase();
      if (ext.length <= 5) return ext;
    }
    return '.jpg';
  }
}
