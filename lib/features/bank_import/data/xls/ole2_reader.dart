/// OLE2 / CFB (Compound File Binary) kap okuyucusu — eski `.xls` dosyalarının
/// dış katmanı.
///
/// Yalnız OKUMA ve yalnız ihtiyacımız olan kadarı: adı verilen bir stream'in
/// baytlarını çıkarmak. Bir `.xls` dosyasında tüm hücre verisi tek bir
/// `Workbook` stream'inde yaşar (bkz. [Biff8Reader]).
///
/// Neden kendi okuyucumuz: `excel` paketi yalnız .xlsx (zip tabanlı) okuyor ve
/// pub.dev'de bakımlı bir saf-Dart BIFF/OLE2 okuyucusu yok. Kullanıcının
/// bankasının VARSAYILAN dışa aktarımı `.xls` ve o dosya elimizdeki en temiz
/// kaynak (tipli sütunlar + banka etiketi + dekont numarası), bu yüzden
/// desteklemeye değer.
library;

import 'dart:typed_data';

/// Kap yapısı bozuk/desteklenmiyor. Çağıran bunu kullanıcıya açık bir mesaja
/// çevirir — sessizce yarım tablo üretmek yerine.
class Ole2Exception implements Exception {
  final String message;
  const Ole2Exception(this.message);
  @override
  String toString() => 'Ole2Exception: $message';
}

const _signature = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];

/// Zincir sonu / özel sektör işaretçileri.
const _endOfChain = 0xFFFFFFFE;
const _freeSector = 0xFFFFFFFF;

/// Dizin girdisi boyutu (bayt).
const _dirEntrySize = 128;

/// Bundan küçük stream'ler mini-FAT üzerinden, Root Entry'nin mini-stream'i
/// içinde saklanır.
const _miniStreamCutoff = 4096;

class Ole2File {
  final Uint8List _bytes;
  final int _sectorSize;
  final int _miniSectorSize;
  final List<int> _fat;
  final List<int> _miniFat;
  final List<_DirEntry> _entries;

  Ole2File._(
    this._bytes,
    this._sectorSize,
    this._miniSectorSize,
    this._fat,
    this._miniFat,
    this._entries,
  );

  /// [bytes]'ı OLE2 kabı olarak açar. İmza tutmazsa/yapı bozuksa
  /// [Ole2Exception] fırlatır.
  factory Ole2File.parse(Uint8List bytes) {
    if (bytes.length < 512) {
      throw const Ole2Exception('Dosya bir OLE2 kabı olamayacak kadar küçük.');
    }
    for (var i = 0; i < _signature.length; i++) {
      if (bytes[i] != _signature[i]) {
        throw const Ole2Exception('OLE2 imzası bulunamadı.');
      }
    }

    final data = ByteData.sublistView(bytes);
    int u16(int o) => data.getUint16(o, Endian.little);
    int u32(int o) => data.getUint32(o, Endian.little);

    final sectorSize = 1 << u16(0x1E);
    final miniSectorSize = 1 << u16(0x20);
    if (sectorSize < 128 || sectorSize > 1 << 20) {
      throw Ole2Exception('Geçersiz sektör boyutu: $sectorSize');
    }

    final fatSectorCount = u32(0x2C);
    final dirFirstSector = u32(0x30);
    final miniFatFirst = u32(0x3C);
    final difatFirst = u32(0x44);
    final difatCount = u32(0x48);

    // --- DIFAT: FAT sektörlerinin listesi (ilk 109 tanesi başlıkta) ---
    final fatSectors = <int>[];
    for (var i = 0; i < 109 && fatSectors.length < fatSectorCount; i++) {
      final s = u32(0x4C + 4 * i);
      if (s == _freeSector || s == _endOfChain) break;
      fatSectors.add(s);
    }
    // Büyük dosyalarda DIFAT ek sektörlere taşar (her sektörün son 4 baytı
    // bir sonraki DIFAT sektörünü gösterir).
    var difatSector = difatFirst;
    var guard = 0;
    while (difatSector != _endOfChain &&
        difatSector != _freeSector &&
        guard++ < difatCount + 8 &&
        fatSectors.length < fatSectorCount) {
      final base = (difatSector + 1) * sectorSize;
      if (base + sectorSize > bytes.length) break;
      final perSector = sectorSize ~/ 4 - 1;
      for (var i = 0; i < perSector && fatSectors.length < fatSectorCount; i++) {
        final s = u32(base + 4 * i);
        if (s == _freeSector || s == _endOfChain) break;
        fatSectors.add(s);
      }
      difatSector = u32(base + sectorSize - 4);
    }

    // --- FAT: sektör → sonraki sektör ---
    final fat = <int>[];
    for (final s in fatSectors) {
      final base = (s + 1) * sectorSize;
      if (base + sectorSize > bytes.length) {
        throw const Ole2Exception('FAT sektörü dosya sınırının dışında.');
      }
      for (var i = 0; i < sectorSize ~/ 4; i++) {
        fat.add(u32(base + 4 * i));
      }
    }
    if (fat.isEmpty) throw const Ole2Exception('FAT okunamadı.');

    List<int> chain(int start) {
      final out = <int>[];
      var cur = start;
      // Bozuk dosyada sonsuz döngüye girmemek için sektör sayısıyla sınırla.
      while (cur != _endOfChain && cur != _freeSector && out.length <= fat.length) {
        out.add(cur);
        if (cur >= fat.length) {
          throw const Ole2Exception('Sektör zinciri FAT sınırını aştı.');
        }
        cur = fat[cur];
      }
      return out;
    }

    Uint8List readSectors(List<int> sectors, int length) {
      final out = BytesBuilder(copy: false);
      for (final s in sectors) {
        final base = (s + 1) * sectorSize;
        if (base >= bytes.length) break;
        final end = (base + sectorSize).clamp(0, bytes.length);
        out.add(Uint8List.sublistView(bytes, base, end));
      }
      final all = out.toBytes();
      return length >= 0 && length < all.length
          ? Uint8List.sublistView(all, 0, length)
          : all;
    }

    // --- mini-FAT ---
    final miniFat = <int>[];
    if (miniFatFirst != _endOfChain && miniFatFirst != _freeSector) {
      final raw = readSectors(chain(miniFatFirst), -1);
      final md = ByteData.sublistView(raw);
      for (var i = 0; i + 4 <= raw.length; i += 4) {
        miniFat.add(md.getUint32(i, Endian.little));
      }
    }

    // --- dizin ---
    final dirRaw = readSectors(chain(dirFirstSector), -1);
    final entries = <_DirEntry>[];
    for (var o = 0; o + _dirEntrySize <= dirRaw.length; o += _dirEntrySize) {
      final e = _DirEntry.parse(Uint8List.sublistView(dirRaw, o, o + _dirEntrySize));
      if (e != null) entries.add(e);
    }
    if (entries.isEmpty) throw const Ole2Exception('Dizin girdisi bulunamadı.');

    final file = Ole2File._(
      bytes,
      sectorSize,
      miniSectorSize,
      fat,
      miniFat,
      entries,
    );
    return file;
  }

  /// Kaptaki stream adları (tanılama/hata mesajı için).
  List<String> get streamNames =>
      [for (final e in _entries) if (e.isStream) e.name];

  /// Adı [name] olan stream'in baytları; yoksa `null`.
  /// Karşılaştırma büyük/küçük harf duyarsız (bazı üreticiler "workbook" yazar).
  Uint8List? readStream(String name) {
    final lower = name.toLowerCase();
    for (final e in _entries) {
      if (e.isStream && e.name.toLowerCase() == lower) return _read(e);
    }
    return null;
  }

  Uint8List _read(_DirEntry entry) {
    if (entry.size >= _miniStreamCutoff) {
      return _readChain(entry.startSector, entry.size, _sectorSize, _fat, 1);
    }
    // Küçük stream: Root Entry'nin mini-stream'i içinde, mini-FAT ile.
    final root = _entries.first;
    final miniStream =
        _readChain(root.startSector, root.size, _sectorSize, _fat, 1);
    final out = BytesBuilder(copy: false);
    var cur = entry.startSector;
    var guard = 0;
    while (cur != _endOfChain &&
        cur != _freeSector &&
        guard++ <= _miniFat.length + 1) {
      final base = cur * _miniSectorSize;
      if (base >= miniStream.length) break;
      final end = (base + _miniSectorSize).clamp(0, miniStream.length);
      out.add(Uint8List.sublistView(miniStream, base, end));
      if (cur >= _miniFat.length) break;
      cur = _miniFat[cur];
    }
    final all = out.toBytes();
    return entry.size < all.length
        ? Uint8List.sublistView(all, 0, entry.size)
        : all;
  }

  Uint8List _readChain(
      int start, int size, int unit, List<int> table, int offsetSectors) {
    final out = BytesBuilder(copy: false);
    var cur = start;
    var guard = 0;
    while (cur != _endOfChain &&
        cur != _freeSector &&
        guard++ <= table.length + 1) {
      final base = (cur + offsetSectors) * unit;
      if (base >= _bytes.length) break;
      final end = (base + unit).clamp(0, _bytes.length);
      out.add(Uint8List.sublistView(_bytes, base, end));
      if (cur >= table.length) break;
      cur = table[cur];
    }
    final all = out.toBytes();
    return size >= 0 && size < all.length
        ? Uint8List.sublistView(all, 0, size)
        : all;
  }
}

class _DirEntry {
  final String name;
  final int type; // 1=storage, 2=stream, 5=root
  final int startSector;
  final int size;
  const _DirEntry(this.name, this.type, this.startSector, this.size);

  bool get isStream => type == 2;

  static _DirEntry? parse(Uint8List raw) {
    final d = ByteData.sublistView(raw);
    final nameLen = d.getUint16(0x40, Endian.little);
    final type = raw[0x42];
    if (type == 0 || nameLen < 2 || nameLen > 64) return null;
    // Ad UTF-16LE ve sonda NUL var (nameLen buna dahil).
    final units = <int>[];
    for (var i = 0; i + 1 < nameLen - 2; i += 2) {
      units.add(d.getUint16(i, Endian.little));
    }
    final start = d.getUint32(0x74, Endian.little);
    // 32-bit boyut yeterli: 4 GB'lık bir ekstre yok.
    final size = d.getUint32(0x78, Endian.little);
    return _DirEntry(String.fromCharCodes(units), type, start, size);
  }
}
