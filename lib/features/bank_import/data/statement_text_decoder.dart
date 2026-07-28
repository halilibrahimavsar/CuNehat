/// Banka ekstresi metin dosyalarını (CSV/TXT) baytlardan çözer.
///
/// Türk bankalarının CSV export'ları çoğunlukla **windows-1254 / ISO-8859-9**
/// (Türkçe latin5) kodlamasındadır, UTF-8 değil. Eskiden UTF-8 başarısız
/// olduğunda `latin1`'e düşülüyordu; latin1 bu iki kodlamayla yalnız 6 harfte
/// ayrışıyor ama o 6 harf tam da Türkçenin harfleri:
///
/// ```
/// Şube → Þube        Açıklama → Açýklama        Avşar → Avþar
/// ```
///
/// Sonuçları: (1) bozuk metin kalıcı olarak deftere yazılıyordu, (2) sütun
/// başlığı sezgisi (`aciklama`) hiç eşleşmiyordu, (3) kategori tahmini
/// bozuluyordu. Bu çözücü o 6 harfi ve cp1254'ün 0x80–0x9F aralığını doğru
/// eşler; latin1 girdileri de aynen korunur (iki kodlama kalan tüm baytlarda
/// birebir aynıdır), dolayısıyla latin1'e göre kayıp yok.
library;

import 'dart:convert';

/// cp1254'ün latin1'den ayrıştığı 0x80–0x9F aralığı. `0` = tanımsız bayt
/// (U+FFFD ile değiştirilir).
const _cp1254High = <int>[
  0x20AC, 0, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, //
  0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0, 0, 0, //
  0, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, //
  0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0, 0, 0x0178, //
];

/// cp1254'ün latin1'den ayrıştığı tek tek baytlar (Türkçe harfler).
const _cp1254Turkish = <int, int>{
  0xD0: 0x011E, // Ğ  (latin1: Ð)
  0xDD: 0x0130, // İ  (latin1: Ý)
  0xDE: 0x015E, // Ş  (latin1: Þ)
  0xF0: 0x011F, // ğ  (latin1: ð)
  0xFD: 0x0131, // ı  (latin1: ý)
  0xFE: 0x015F, // ş  (latin1: þ)
};

/// Baytları metne çevirir. Sıra: UTF-16 BOM → UTF-8 (katı) → windows-1254.
/// Asla fırlatmaz. Baştaki BOM (varsa) atılır — aksi halde ilk hücrenin başına
/// görünmez bir `﻿` yapışıp başlık eşleşmesini bozar.
String decodeStatementBytes(List<int> bytes) {
  if (bytes.isEmpty) return '';

  // Excel'in "Unicode Text" export'u UTF-16LE'dir.
  if (bytes.length >= 2) {
    if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return _decodeUtf16(bytes, littleEndian: true);
    }
    if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return _decodeUtf16(bytes, littleEndian: false);
    }
  }

  try {
    final text = utf8.decode(bytes); // katı: geçersiz dizide fırlatır
    return text.startsWith('﻿') ? text.substring(1) : text;
  } on FormatException {
    return _decodeCp1254(bytes);
  }
}

String _decodeCp1254(List<int> bytes) {
  final units = List<int>.generate(bytes.length, (i) {
    final b = bytes[i] & 0xFF;
    if (b < 0x80) return b;
    if (b < 0xA0) {
      final mapped = _cp1254High[b - 0x80];
      return mapped == 0 ? 0xFFFD : mapped;
    }
    return _cp1254Turkish[b] ?? b;
  });
  return String.fromCharCodes(units);
}

String _decodeUtf16(List<int> bytes, {required bool littleEndian}) {
  final units = <int>[];
  for (var i = 2; i + 1 < bytes.length; i += 2) {
    final lo = bytes[i] & 0xFF;
    final hi = bytes[i + 1] & 0xFF;
    units.add(littleEndian ? (hi << 8) | lo : (lo << 8) | hi);
  }
  return String.fromCharCodes(units);
}
