import 'package:cunehat/features/bank_import/domain/column_mapping.dart';

/// Banka ekstresi tarih hücrelerini ayrıştırır. `CsvService.parseDate`'in
/// genellemesi: ISO 8601 + gg/aa/yyyy ile birlikte aa/gg sırası, 2 haneli yıl
/// ve `-`/`.`/`/` ayraçlarını destekler. Belirsiz sıra [fmt] ile çözülür.

/// ISO/yıl-önce biçimi, hücrenin BAŞINDA: `2026-07-16`, `2026/07/16` ve
/// arkasına saat/zaman damgası eklenmiş biçimler (`2026-07-16 10:53:10`,
/// `2026-07-16-10.53.10.816925`).
final _isoPrefixRe = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})');

/// gg/aa/yyyy biçimi. **Sınırlar zorunlu**: eşleşmenin iki yanında rakam ya da
/// tarih ayracı OLMAMALI. Sabitlenmemiş bir regex, uzun bir zaman damgasının
/// ORTASINDAN geçerli görünen bir tarih çıkarır ve bu sessizce yanlış bir
/// kayda dönüşür — gerçek bir Akbank CSV'sinde `2026-07-16-10.53.10.816925`
/// hücresi, içindeki `26-07-16` alt dizesi yüzünden 2016-07-26 olarak
/// ayrıştırılıyordu (75 satırın tamamı 2003–2030'a dağılmıştı).
final _re =
    RegExp(r'(?<![\d./-])(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})(?![\d./-])');

/// Tarih SÜTUNUNUN tamamına bakarak gün-önce/ay-önce kararını BİR KEZ verir.
///
/// Neden gerekli: [StatementDateFormat.auto] hücre bazında karar verirse aynı
/// dosya satır satır farklı yorumlanabilir. Ay-önce (MM/DD) bir kaynakta
/// `01/15/2026` ikinci grup 12'yi aştığı için doğru okunur, ama bir sonraki
/// satırdaki `01/05/2026` belirsiz olduğu için TR varsayılanıyla gün-önce
/// sayılır: **aynı sütunda 15 Ocak ile 1 Mayıs yan yana** çıkar ve hiçbir
/// uyarı verilmez. Karar sütuna ait olduğu için sütuna ait bir kanıtla
/// verilmelidir.
///
/// Kanıt: yalnız 12'yi aşan gruplar. İki yönde de kanıt varsa (bozuk/karışık
/// kaynak) TR varsayılanına düşülür — sessizce yarısını ters çevirmektense
/// tutarlı davranmak yeğdir; kullanıcı eşleme ekranından değiştirebilir.
StatementDateFormat resolveStatementDateFormat(Iterable<String> cells) {
  var dayFirstEvidence = 0;
  var monthFirstEvidence = 0;
  for (final cell in cells) {
    final s = cell.trim();
    if (s.isEmpty) continue;
    if (_isoPrefixRe.hasMatch(s)) continue; // ISO: sıra zaten belirsiz değil
    final m = _re.firstMatch(s);
    if (m == null) continue;
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    if (a > 12 && b <= 12) dayFirstEvidence++;
    if (b > 12 && a <= 12) monthFirstEvidence++;
  }
  if (monthFirstEvidence > 0 && dayFirstEvidence == 0) {
    return StatementDateFormat.monthFirst;
  }
  return StatementDateFormat.dayFirst;
}

DateTime? parseStatementDate(String raw, StatementDateFormat fmt) {
  final s = raw.trim();
  if (s.isEmpty) return null;

  // Yıl-önce biçimi baştan yakalanır; ardındaki saat/mikrosaniye kuyruğu
  // (varsa) yok sayılır. Sıra belirsizliği yok, [fmt]'ten bağımsız.
  final isoMatch = _isoPrefixRe.firstMatch(s);
  if (isoMatch != null) {
    return _build(
      year: int.parse(isoMatch.group(1)!),
      month: int.parse(isoMatch.group(2)!),
      day: int.parse(isoMatch.group(3)!),
    );
  }

  final m = _re.firstMatch(s);
  if (m == null) return null;
  final a = int.parse(m.group(1)!);
  final b = int.parse(m.group(2)!);
  var year = int.parse(m.group(3)!);
  if (year < 100) year += 2000;

  final int day;
  final int month;
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
      if (b > 12 && a <= 12) {
        month = a;
        day = b;
      } else {
        day = a;
        month = b;
      }
  }

  return _build(year: year, month: month, day: day);
}

/// Ortak doğrulama: makul aralık + taşan tarihleri (31.02) reddeder.
DateTime? _build({required int year, required int month, required int day}) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (year < 2000 || year > 2100) return null;
  final date = DateTime(year, month, day);
  if (date.month != month || date.day != day) return null;
  return date;
}
