import 'package:cunehat/features/bank_import/domain/column_mapping.dart';

/// Banka ekstresi tarih hücrelerini ayrıştırır. `CsvService.parseDate`'in
/// genellemesi: ISO 8601 + gg/aa/yyyy ile birlikte aa/gg sırası, 2 haneli yıl
/// ve `-`/`.`/`/` ayraçlarını destekler. Belirsiz sıra [fmt] ile çözülür.
final _re = RegExp(r'(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})');

DateTime? parseStatementDate(String raw, StatementDateFormat fmt) {
  final s = raw.trim();
  if (s.isEmpty) return null;

  // ISO (yyyy-MM-dd, kendi export'umuz veya bazı bankalar) — auto/dayFirst'te
  // önce dene; monthFirst kullanıcı açıkça seçtiyse ISO'yu atlamayalım ki
  // yyyy-MM-dd yanlış yorumlanmasın (zaten regex 4 haneli grubu sonda bekler).
  final iso = DateTime.tryParse(s);
  if (iso != null && s.contains('-') && s.indexOf('-') == 4) {
    return DateTime(iso.year, iso.month, iso.day);
  }

  final m = _re.firstMatch(s);
  if (m == null) return null;
  var a = int.parse(m.group(1)!);
  var b = int.parse(m.group(2)!);
  var year = int.parse(m.group(3)!);
  if (year < 100) year += 2000;

  int day;
  int month;
  switch (fmt) {
    case StatementDateFormat.dayFirst:
      day = a;
      month = b;
    case StatementDateFormat.monthFirst:
      month = a;
      day = b;
    case StatementDateFormat.auto:
      // İlk grup 12'yi aşıyorsa gün olmalı; ikinci grup aşıyorsa ay-önce;
      // aksi halde TR varsayılanı gün-önce.
      if (a > 12) {
        day = a;
        month = b;
      } else if (b > 12) {
        month = a;
        day = b;
      } else {
        day = a;
        month = b;
      }
  }

  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (year < 2000 || year > 2100) return null;
  final date = DateTime(year, month, day);
  // Taşan tarihleri (31.02) reddet.
  if (date.month != month || date.day != day) return null;
  return date;
}
