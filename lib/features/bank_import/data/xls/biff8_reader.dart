/// BIFF8 (Excel 97–2003 `.xls`) çalışma sayfası okuyucusu.
///
/// Kapsam bilinçli olarak DAR: bir banka ekstresini hücre ızgarasına çevirmek.
/// Formül hesaplama, biçim/stil, grafik, makro yok. Anlaşılmayan bir HÜCRE
/// kaydıyla karşılaşırsak sayılır ve üst katmana bildirilir — yarım bir tabloyu
/// "başarılı" diye sunmaktansa açıkça uyarmak için.
///
/// Gerçek bir Garanti BBVA `.xls` ekstresinde kullanılan kayıtlar ölçüldü:
/// `LABELSST` (365) + `NUMBER` (170) — hepsi bu. `RK`/`MULRK`/`LABEL`/`FORMULA`
/// yine de destekleniyor çünkü başka bankalarda yaygındır ve maliyeti düşük.
library;

import 'dart:typed_data';

import 'package:cunehat/features/bank_import/data/xls/ole2_reader.dart';

class Biff8Exception implements Exception {
  final String message;
  const Biff8Exception(this.message);
  @override
  String toString() => 'Biff8Exception: $message';
}

/// Okunan sayfa: satır × sütun hücre metinleri + bütünlük tanılaması.
class XlsSheet {
  final String name;
  final List<List<String>> rows;

  /// Kaydı okunduğu hâlde DEĞERİ çözülemeyen hücre sayısı (SST indeksi aralık
  /// dışı, formülün önbellek string'i eksik). 0 olmalı; değilse tabloda boş
  /// görünen hücreler aslında veri taşıyordu — üst katman uyarır.
  final int unresolvedCells;

  /// Kayıt akışı `EOF` ile bitmedi: dosya kırpık indirilmiş olabilir.
  final bool truncated;

  const XlsSheet({
    required this.name,
    required this.rows,
    required this.unresolvedCells,
    required this.truncated,
  });

  bool get isSuspect => unresolvedCells > 0 || truncated;
}

// --- kayıt türleri ---
const _recBof = 0x0809;
const _recEof = 0x000A;
const _recSst = 0x00FC;
const _recContinue = 0x003C;
const _recLabelSst = 0x00FD;
const _recLabel = 0x0204;
const _recRString = 0x00D6;
const _recNumber = 0x0203;
const _recRk = 0x027E;
const _recMulRk = 0x00BD;
const _recFormula = 0x0006;
const _recString = 0x0207;
const _recBlank = 0x0201;
const _recMulBlank = 0x00BE;
const _recBoolErr = 0x0205;
const _recBoundSheet = 0x0085;
const _recDateMode = 0x0022;
const _recFilePass = 0x002F;
const _recXf = 0x00E0;
const _recFormat = 0x041E;

class Biff8Reader {
  /// `.xls` baytlarından İLK çalışma sayfasını okur.
  ///
  /// Banka ekstrelerinde tek sayfa olur; birden fazlaysa ilki alınır (CSV/xlsx
  /// yolunda da ilk sayfa okunuyor — davranış tutarlı).
  XlsSheet readFirstSheet(Uint8List fileBytes) {
    final ole = Ole2File.parse(fileBytes);
    final workbook = ole.readStream('Workbook') ?? ole.readStream('Book');
    if (workbook == null) {
      throw Biff8Exception(
        'Workbook akışı bulunamadı (kapta: ${ole.streamNames.join(", ")}).',
      );
    }

    final records = _splitRecords(workbook);
    if (records.isEmpty) throw const Biff8Exception('BIFF kaydı bulunamadı.');

    _assertSupported(records);

    final sst = _readSst(records);
    final dateEpoch = _readDateEpoch(records);
    final dateXfs = _readDateFormatXfs(records);
    final sheets = _readBoundSheets(records, workbook);

    // Sayfa alt-akışı: BOUNDSHEET'in gösterdiği BOF'tan o alt-akışın EOF'una.
    final target = sheets.isEmpty ? null : sheets.first;
    final cellRecords = target == null
        ? records
        : _substream(records, target.bofOffset);

    return _buildSheet(
      name: target?.name ?? '',
      records: cellRecords,
      sst: sst,
      dateEpoch: dateEpoch,
      dateXfs: dateXfs,
      // Kırpıklık TÜM akıştan bakılır: alt-akış listesi kapanış EOF'unu
      // zaten dışarıda bırakır, oradan bakmak her dosyayı kırpık gösterirdi.
      truncated: records.last.id != _recEof,
    );
  }

  // ------------------------------------------------------------- kayıt ayırma

  List<_Record> _splitRecords(Uint8List stream) {
    final d = ByteData.sublistView(stream);
    final out = <_Record>[];
    var i = 0;
    while (i + 4 <= stream.length) {
      final id = d.getUint16(i, Endian.little);
      final len = d.getUint16(i + 2, Endian.little);
      if (i + 4 + len > stream.length) break; // kırpık dosya: kalanı yok say
      out.add(_Record(
        id,
        i,
        Uint8List.sublistView(stream, i + 4, i + 4 + len),
      ));
      i += 4 + len;
    }
    return out;
  }

  void _assertSupported(List<_Record> records) {
    for (final r in records) {
      if (r.id == _recFilePass) {
        throw const Biff8Exception('Dosya parola korumalı.');
      }
      if (r.id == _recBof && r.body.length >= 2) {
        final version =
            ByteData.sublistView(r.body).getUint16(0, Endian.little);
        // 0x0600 = BIFF8. Daha eskisi (BIFF5/7 = 0x0500) farklı bir string
        // kodlaması kullanır; desteklemek yerine açıkça reddediyoruz.
        if (version != 0x0600) {
          throw Biff8Exception(
            'Desteklenmeyen Excel sürümü (BIFF ${version.toRadixString(16)}).',
          );
        }
        return; // yalnız ilk BOF'a bak
      }
    }
  }

  /// [bofOffset]'teki BOF'tan başlayıp dengeli BOF/EOF sayımıyla o alt-akışın
  /// sonuna kadar olan kayıtlar.
  List<_Record> _substream(List<_Record> records, int bofOffset) {
    final start = records.indexWhere((r) => r.offset == bofOffset);
    if (start < 0) return records;
    final out = <_Record>[];
    var depth = 0;
    for (var i = start; i < records.length; i++) {
      final r = records[i];
      if (r.id == _recBof) depth++;
      if (r.id == _recEof) {
        depth--;
        if (depth <= 0) break;
      }
      out.add(r);
    }
    return out;
  }

  // ------------------------------------------------------------------ SST

  /// Paylaşılan string tablosu. `CONTINUE` sınırı BIFF8'in en çetrefil yeri:
  /// bir string kayıt sınırında bölünebilir ve devam kaydının İLK baytı
  /// stringin geri kalanının 8-bit mi 16-bit mi olduğunu yeniden bildirir.
  List<String> _readSst(List<_Record> records) {
    final idx = records.indexWhere((r) => r.id == _recSst);
    if (idx < 0) return const [];

    final parts = <Uint8List>[records[idx].body];
    for (var i = idx + 1; i < records.length; i++) {
      if (records[i].id != _recContinue) break;
      parts.add(records[i].body);
    }

    final cursor = _PartCursor(parts);
    cursor.skip(4); // toplam string sayısı (kullanılmıyor)
    final unique = cursor.readInt32();
    if (unique < 0 || unique > 1 << 22) {
      throw Biff8Exception('SST benzersiz string sayısı makul değil: $unique');
    }

    final out = <String>[];
    for (var s = 0; s < unique; s++) {
      if (cursor.exhausted) break;
      final charCount = cursor.readUint16();
      var flags = cursor.readByte();
      var wide = flags & 0x01 != 0;
      final richRuns = flags & 0x08 != 0 ? cursor.readUint16() : 0;
      final extSize = flags & 0x04 != 0 ? cursor.readInt32() : 0;

      final buffer = StringBuffer();
      var remaining = charCount;
      while (remaining > 0 && !cursor.exhausted) {
        if (cursor.atPartBoundary) {
          cursor.advancePart();
          if (cursor.exhausted) break;
          // Devam kaydının ilk baytı yeni genişlik bayrağı.
          flags = cursor.readByte();
          wide = flags & 0x01 != 0;
          continue;
        }
        final availableChars = wide
            ? cursor.remainingInPart ~/ 2
            : cursor.remainingInPart;
        final take = remaining < availableChars ? remaining : availableChars;
        if (take <= 0) {
          cursor.advancePart();
          if (cursor.exhausted) break;
          flags = cursor.readByte();
          wide = flags & 0x01 != 0;
          continue;
        }
        buffer.write(cursor.readString(take, wide: wide));
        remaining -= take;
      }
      if (richRuns > 0) cursor.skip(4 * richRuns);
      if (extSize > 0) cursor.skip(extSize);
      out.add(buffer.toString());
    }
    return out;
  }

  // ------------------------------------------------------------ tarih desteği

  /// 1904 tarih sistemi (Mac Excel) kullanılıyorsa farklı epok.
  DateTime _readDateEpoch(List<_Record> records) {
    for (final r in records) {
      if (r.id == _recDateMode && r.body.length >= 2) {
        final mode = ByteData.sublistView(r.body).getUint16(0, Endian.little);
        if (mode == 1) return DateTime(1904, 1, 1);
      }
    }
    // 1900 sistemi: Excel 1900'ü artık yıl sanar, bu yüzden epok 30 Aralık 1899.
    return DateTime(1899, 12, 30);
  }

  /// Tarih olarak biçimlendirilmiş XF indeksleri. Bir `NUMBER` hücresi bunlardan
  /// birine bağlıysa ham seri numarası (45905) yerine ISO tarih yazılır —
  /// aksi halde tarih sütunu okunamaz hale gelirdi.
  Set<int> _readDateFormatXfs(List<_Record> records) {
    // Yerleşik tarih/saat biçim indeksleri (ECMA-376 / BIFF ortak kümesi).
    const builtinDate = <int>{
      14, 15, 16, 17, 18, 19, 20, 21, 22, //
      27, 28, 29, 30, 31, 32, 33, 34, 35, 36, //
      45, 46, 47, 50, 51, 52, 53, 54, 55, 56, 57, 58,
    };
    final customDate = <int>{};
    for (final r in records) {
      if (r.id != _recFormat || r.body.length < 4) continue;
      final d = ByteData.sublistView(r.body);
      final index = d.getUint16(0, Endian.little);
      final format = _readShortString(r.body, 2);
      if (_looksLikeDateFormat(format)) customDate.add(index);
    }

    final result = <int>{};
    var xfIndex = 0;
    for (final r in records) {
      if (r.id != _recXf || r.body.length < 4) continue;
      final formatIndex =
          ByteData.sublistView(r.body).getUint16(2, Endian.little);
      if (builtinDate.contains(formatIndex) ||
          customDate.contains(formatIndex)) {
        result.add(xfIndex);
      }
      xfIndex++;
    }
    return result;
  }

  /// Biçim dizesinde tarih alanı var mı? Metin literalleri (`"..."`) ve kaçış
  /// karakterleri atlanır ki `"Mart"` gibi bir sabit tarih sanılmasın.
  bool _looksLikeDateFormat(String format) {
    var inQuotes = false;
    for (var i = 0; i < format.length; i++) {
      final c = format[i];
      if (c == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (inQuotes) continue;
      if (c == '\\') {
        i++;
        continue;
      }
      if (c == '[') {
        // [Red] / [\$-409] gibi bölümler
        final close = format.indexOf(']', i);
        if (close < 0) break;
        i = close;
        continue;
      }
      const dateChars = {'y', 'Y', 'd', 'D', 'm', 'M', 'h', 'H', 's', 'S'};
      if (dateChars.contains(c)) return true;
    }
    return false;
  }

  // ----------------------------------------------------------- sayfa listesi

  List<_BoundSheet> _readBoundSheets(List<_Record> records, Uint8List stream) {
    final out = <_BoundSheet>[];
    for (final r in records) {
      if (r.id != _recBoundSheet || r.body.length < 8) continue;
      final d = ByteData.sublistView(r.body);
      final bofOffset = d.getUint32(0, Endian.little);
      final hidden = r.body[4] & 0x03; // 0 = görünür
      final nameLen = r.body[6];
      final flags = r.body[7];
      final name = _readChars(r.body, 8, nameLen, wide: flags & 0x01 != 0);
      if (hidden == 0) out.add(_BoundSheet(name, bofOffset));
    }
    return out;
  }

  // ------------------------------------------------------------ hücre ızgara

  XlsSheet _buildSheet({
    required String name,
    required List<_Record> records,
    required List<String> sst,
    required DateTime dateEpoch,
    required Set<int> dateXfs,
    required bool truncated,
  }) {
    final cells = <int, Map<int, String>>{};
    var maxCol = -1;
    var unresolved = 0;

    void put(int row, int col, String value) {
      (cells[row] ??= <int, String>{})[col] = value;
      if (col > maxCol) maxCol = col;
    }

    String numberToString(double value, int xf) {
      if (dateXfs.contains(xf)) {
        // Kesirli kısım günün saati; ekstrede gün yeterli, ISO yaz
        // (parseStatementDate ISO önekini doğrudan tanır).
        final date = dateEpoch.add(Duration(days: value.floor()));
        return '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
      }
      // Tam sayıysa ondalık kuyruk yazma ("2" değil "2.0" olmasın).
      if (value == value.roundToDouble() && value.abs() < 1e15) {
        return value.toInt().toString();
      }
      // İkili kayan noktada 4412.28, 4412.280000000001 olarak saklanabilir.
      // `toString()` bu gürültüyü aynen yazar ve `parseMoneyToken` ondalık
      // kısmı 2 haneden uzun görünce TÜM ayraçları binlik sanıp değeri
      // 4.412.280.000.000.001'e çevirir — sessiz ve felaket bir hata. Değer
      // kuruşa temiz oturuyorsa 2 haneyle yaz.
      final cents = (value * 100).roundToDouble() / 100;
      final text = (value - cents).abs() < 1e-9
          ? value.toStringAsFixed(2)
          : value.toStringAsFixed(6);
      return text.contains('.')
          ? text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
          : text;
    }

    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      final b = r.body;
      final d = ByteData.sublistView(b);

      switch (r.id) {
        case _recLabelSst:
          if (b.length < 10) break;
          final row = d.getUint16(0, Endian.little);
          final col = d.getUint16(2, Endian.little);
          final index = d.getUint32(6, Endian.little);
          if (index >= sst.length) {
            unresolved++;
            put(row, col, '');
          } else {
            put(row, col, sst[index]);
          }

        case _recLabel:
        case _recRString:
          if (b.length < 8) break;
          final row = d.getUint16(0, Endian.little);
          final col = d.getUint16(2, Endian.little);
          put(row, col, _readLongString(b, 6));

        case _recNumber:
          if (b.length < 14) break;
          final row = d.getUint16(0, Endian.little);
          final col = d.getUint16(2, Endian.little);
          final xf = d.getUint16(4, Endian.little);
          put(row, col, numberToString(d.getFloat64(6, Endian.little), xf));

        case _recRk:
          if (b.length < 10) break;
          final row = d.getUint16(0, Endian.little);
          final col = d.getUint16(2, Endian.little);
          final xf = d.getUint16(4, Endian.little);
          put(row, col,
              numberToString(_decodeRk(d.getUint32(6, Endian.little)), xf));

        case _recMulRk:
          if (b.length < 6) break;
          final row = d.getUint16(0, Endian.little);
          final firstCol = d.getUint16(2, Endian.little);
          final count = (b.length - 6) ~/ 6;
          for (var k = 0; k < count; k++) {
            final o = 4 + k * 6;
            final xf = d.getUint16(o, Endian.little);
            final rk = d.getUint32(o + 2, Endian.little);
            put(row, firstCol + k, numberToString(_decodeRk(rk), xf));
          }

        case _recFormula:
          if (b.length < 16) break;
          final row = d.getUint16(0, Endian.little);
          final col = d.getUint16(2, Endian.little);
          final xf = d.getUint16(4, Endian.little);
          // Önbelleklenmiş sonuç: son iki bayt 0xFFFF ise sayı DEĞİL
          // (string/bool/hata); string ise değeri sonraki STRING kaydında.
          final isNumeric = !(b[12] == 0xFF && b[13] == 0xFF);
          if (isNumeric) {
            put(row, col, numberToString(d.getFloat64(6, Endian.little), xf));
          } else if (b[6] == 0x00) {
            final next = i + 1 < records.length ? records[i + 1] : null;
            if (next?.id == _recString) {
              put(row, col, _readLongString(next!.body, 0));
            } else {
              unresolved++; // string sonuç bekleniyordu ama STRING kaydı yok
              put(row, col, '');
            }
          } else {
            put(row, col, ''); // bool / hata: ekstrede anlamsız
          }

        case _recBlank:
        case _recMulBlank:
        case _recBoolErr:
          break; // boş/mantıksal hücre: ızgarada zaten boş kalır

        default:
          // BIFF8'in DEĞER taşıyan hücre kayıtlarının tamamı yukarıda
          // ele alınıyor; geri kalanı biçim/stil/düzen kaydıdır ve yok
          // sayılması güvenlidir.
          break;
      }
    }

    if (cells.isEmpty) {
      return XlsSheet(
        name: name,
        rows: const [],
        unresolvedCells: unresolved,
        truncated: truncated,
      );
    }

    final maxRow = cells.keys.reduce((a, b) => a > b ? a : b);
    final rows = <List<String>>[];
    for (var r = 0; r <= maxRow; r++) {
      final rowCells = cells[r];
      final row = <String>[
        for (var c = 0; c <= maxCol; c++) rowCells?[c] ?? '',
      ];
      // Tamamen boş satırlar atılır (CSV/xlsx okuyucularıyla aynı davranış).
      if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
    }
    return XlsSheet(
      name: name,
      rows: rows,
      unresolvedCells: unresolved,
      truncated: truncated,
    );
  }

  /// RK: yer kazanmak için sıkıştırılmış sayı. Alt 2 bit bayrak, üst 30 bit ya
  /// işaretli tam sayı ya da bir IEEE754 double'ın EN ANLAMLI 32 biti (alt 34
  /// bit sıfır varsayılır). Bayrak 0x01 ise değer 100'e bölünür.
  double _decodeRk(int rk) {
    final divideBy100 = rk & 0x01 != 0;
    final double value;
    if (rk & 0x02 != 0) {
      var v = rk >> 2;
      if (v & 0x20000000 != 0) v -= 0x40000000; // 30-bit işaret uzatma
      value = v.toDouble();
    } else {
      // Little-endian double'da üst 32 bit 4..7 baytlarındadır.
      final buffer = ByteData(8)
        ..setUint32(4, rk & 0xFFFFFFFC, Endian.little);
      value = buffer.getFloat64(0, Endian.little);
    }
    return divideBy100 ? value / 100.0 : value;
  }

  // ------------------------------------------------------------ string yardım

  /// `len(1) flags(1) chars…` biçimi (FORMAT gibi kısa string alanları).
  String _readShortString(Uint8List b, int offset) {
    if (offset + 2 > b.length) return '';
    final len = b[offset];
    final wide = b[offset + 1] & 0x01 != 0;
    return _readChars(b, offset + 2, len, wide: wide);
  }

  /// `len(2) flags(1) chars…` biçimi (LABEL / STRING kayıtları).
  String _readLongString(Uint8List b, int offset) {
    if (offset + 3 > b.length) return '';
    final len = ByteData.sublistView(b).getUint16(offset, Endian.little);
    final wide = b[offset + 2] & 0x01 != 0;
    return _readChars(b, offset + 3, len, wide: wide);
  }

  String _readChars(Uint8List b, int offset, int count, {required bool wide}) {
    final units = <int>[];
    if (wide) {
      final d = ByteData.sublistView(b);
      for (var i = 0; i < count && offset + i * 2 + 1 < b.length; i++) {
        units.add(d.getUint16(offset + i * 2, Endian.little));
      }
    } else {
      for (var i = 0; i < count && offset + i < b.length; i++) {
        units.add(b[offset + i]);
      }
    }
    return String.fromCharCodes(units);
  }
}

class _Record {
  final int id;
  final int offset;
  final Uint8List body;
  const _Record(this.id, this.offset, this.body);
}

class _BoundSheet {
  final String name;
  final int bofOffset;
  const _BoundSheet(this.name, this.bofOffset);
}

/// SST'yi kayıt sınırlarını aşarak okumak için imleç: `CONTINUE` bölünmesini
/// çağırana görünür kılar (string tam sınırda bölünebiliyor).
class _PartCursor {
  final List<Uint8List> _parts;
  int _part = 0;
  int _offset = 0;

  _PartCursor(this._parts);

  bool get exhausted => _part >= _parts.length;
  int get remainingInPart => exhausted ? 0 : _parts[_part].length - _offset;
  bool get atPartBoundary => !exhausted && remainingInPart == 0;

  void advancePart() {
    _part++;
    _offset = 0;
  }

  void _ensure() {
    while (!exhausted && remainingInPart == 0) {
      advancePart();
    }
  }

  int readByte() {
    _ensure();
    if (exhausted) return 0;
    return _parts[_part][_offset++];
  }

  int readUint16() => readByte() | (readByte() << 8);

  int readInt32() {
    final v = readByte() | (readByte() << 8) | (readByte() << 16);
    final high = readByte();
    final raw = v | (high << 24);
    return raw >= 0x80000000 ? raw - 0x100000000 : raw;
  }

  void skip(int n) {
    var left = n;
    while (left > 0 && !exhausted) {
      _ensure();
      if (exhausted) return;
      final take = left < remainingInPart ? left : remainingInPart;
      _offset += take;
      left -= take;
    }
  }

  /// [count] karakteri MEVCUT parçadan okur (çağıran sınırı kendisi yönetir).
  String readString(int count, {required bool wide}) {
    final part = _parts[_part];
    final units = <int>[];
    if (wide) {
      final d = ByteData.sublistView(part);
      for (var i = 0; i < count; i++) {
        units.add(d.getUint16(_offset + i * 2, Endian.little));
      }
      _offset += count * 2;
    } else {
      for (var i = 0; i < count; i++) {
        units.add(part[_offset + i]);
      }
      _offset += count;
    }
    return String.fromCharCodes(units);
  }
}
