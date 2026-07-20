import 'dart:io';

import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late ReceiptStorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('receipt_store_test_');
    storage = ReceiptStorageService.withBaseDir(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<File> sourceImage(String name, String content) async {
    final f = File('${tempDir.path}/$name');
    await f.writeAsString(content);
    return f;
  }

  test('persist kaynağı receipts dizinine kopyalar ve dosya adı döndürür',
      () async {
    final src = await sourceImage('src.jpg', 'IMG');
    final name = await storage.persist(src.path);

    expect(name, endsWith('.jpg'));
    final saved = await storage.fileFor(name);
    expect(await saved.exists(), isTrue);
    expect(await saved.readAsString(), 'IMG');
    // Kaynak dosya olduğu gibi kalır (kopya, taşıma değil).
    expect(await src.exists(), isTrue);
  });

  test('persist kaynağın uzantısını korur, yoksa .jpg', () async {
    final png = await sourceImage('a.png', 'P');
    expect(await storage.persist(png.path), endsWith('.png'));

    final noExt = await sourceImage('noext', 'N');
    expect(await storage.persist(noExt.path), endsWith('.jpg'));
  });

  test('exists yalnız var olan için true', () async {
    expect(await storage.exists('yok.jpg'), isFalse);
    final src = await sourceImage('s.jpg', 'X');
    final name = await storage.persist(src.path);
    expect(await storage.exists(name), isTrue);
  });

  test('delete dosyayı siler, yoksa sessizce geçer', () async {
    final src = await sourceImage('s.jpg', 'X');
    final name = await storage.persist(src.path);
    await storage.delete(name);
    expect(await storage.exists(name), isFalse);
    // İkinci kez silmek hata vermemeli.
    await storage.delete(name);
  });

  test('clearAll tüm fişleri temizler', () async {
    for (var i = 0; i < 3; i++) {
      final src = await sourceImage('s$i.jpg', 'X$i');
      await storage.persist(src.path);
    }
    await storage.clearAll();

    final dir = Directory('${tempDir.path}/receipts');
    final remaining = await dir.list().toList();
    expect(remaining, isEmpty);
  });

  test('pruneExcept yalnız atıfsız fişleri siler (aynı-cihaz restore korur)',
      () async {
    final names = <String>[];
    for (var i = 0; i < 3; i++) {
      final src = await sourceImage('s$i.jpg', 'X$i');
      names.add(await storage.persist(src.path));
    }
    // İlk ikisi hâlâ atıflı; üçüncüsü orphan.
    await storage.pruneExcept({names[0], names[1]});

    expect(await storage.exists(names[0]), isTrue);
    expect(await storage.exists(names[1]), isTrue);
    expect(await storage.exists(names[2]), isFalse);
  });
}
