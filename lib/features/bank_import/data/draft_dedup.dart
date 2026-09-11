/// Taslakları, mevcut deftere ve dosyanın kendisine karşı olası tekrarlara
/// göre işaretler. Üç katman, güç sırasıyla:
///
/// ## 1. Kesin eşleşme — aynı ekstre ikinci kez geliyor
///
///  * **Güçlü anahtar** — `(gün, işaretli kuruş, banka referansı)`. Referans
///    (Dekont/Fiş/İşlem No) `TransactionEntity.reference` olarak deftere de
///    yazıldığı için (şema v5) İÇE AKTARIMLAR ARASI karşılaştırılabilir.
///    Başlık içermez: **kullanıcı başlığı düzenleyebilir** (inceleme ekranı
///    bunu zaten yaptırıyor) ve düzenlenmiş bir işlem yeniden aktarımda
///    ikinci kez yazılıyordu.
///  * **Zayıf anahtar** — `(gün, işaretli kuruş, normalize başlık)`.
///    Referansı olmayan taraflar için (ör. Garanti'nin PDF'i Dekont No vermez,
///    `.xls`'i verir — aynı hesabın iki biçimi birbirini yine bulmalı).
///
/// **Referans TEK BAŞINA anahtar DEĞİLDİR.** Gerçek bir Garanti ekstresinde
/// dekont numarası işlem başına değil OPERASYON başına veriliyor: bir havalenin
/// masraf satırı ("KESİNTİ VE EKLERİ") ana havaleyle AYNI numarayı taşıyor.
/// Tutar anahtara dahil olduğu için bu iki satır yine ayrışır.
///
/// **Eşleşme TÜKETİMLİDİR (sayaç, küme değil).** Aynı gün, aynı tutar, aynı
/// açıklamalı İKİ GERÇEK hareket varsa (ölçüldü: bir Garanti ekstresinde
/// "KARACA OTOMAT" 40,00 ve "MACGAL GIDA" 30,00 çiftleri) defterdeki tek kayıt
/// yalnız BİR taslağı eşleştirebilir.
///
/// **İki taraf da referans taşıyor ve güçlü anahtar tutmadıysa zayıf anahtara
/// düşülmez:** banka onlara ayrı numara verdiyse ayrı hareketlerdir.
///
/// ## 2. Dosya içi tekrar
///
/// Aynı dosyada aynı gün/tutar/açıklama ikinci kez geçiyorsa. **Ama yalnız
/// satırların ayrı hareketler olduğu kanıtlanamıyorsa** ([rowsProvenDistinct]):
/// bakiye zinciri tutan bir ekstrede her satır bakiyeyi değiştirir, yani
/// ikisi de gerçektir. Ölçüldü (11 Eyl 2026): aritmetik olarak DOĞRULANMIŞ
/// Garanti PDF'inde yukarıdaki iki çiftin ikinci satırları "tekrar" sayılıp
/// seçimsiz geliyordu — 70 TL gerçek harcama kullanıcı fark etmezse
/// eklenmiyordu. (Kanıtsız yolda, ör. üst üste binen ekran görüntülerinden
/// OCR'da, kontrol hâlâ anlamlı.)
///
/// ## 3. Yaklaşık eşleşme — aynı harcama elle girilmiş
///
/// Kesin eşleşme, elle girilen bir kaydı pratikte HİÇ bulamıyordu: başlığın
/// ekstredeki açıklamayla birebir aynı olmasını istiyor, kullanıcı ise "bim"
/// yazar ya da not bırakmaz (başlık kategori adına düşer). Üstelik tutarı
/// yaklaşık girer (913,15 yerine 913 ya da 910) ve saatine/gününe dikkat
/// etmez. Bu katman bir TAHMİNDİR ve gerekçesini taşır ([DuplicateMatch]):
///
///  * **Tutar** yalnız YUVARLAMA kalıbıyla benzeyebilir ([amountPatternOf]);
///    rastgele bir fark eşleşme değildir.
///  * **Gün** en fazla [kMaxDayDistance] gün uzakta olabilir.
///  * **Ortak kelime** ("bim") ve **aynı kategori** ek kanıttır.
///
/// Puan [_minScore]'u geçmeyen çift eşleşme sayılmaz; eşleşmeler kesinlerle
/// aynı tüketim kuralına uyar ve en güçlü çiftten başlanarak birebir atanır.
///
/// Ekstreden gelmiş görünen kayıtlar (referanslı ya da açıklaması banka
/// yazımında) bu katmanda yalnız AYNI GÜN + AYNI TUTAR + ortak kelimeyle
/// eşleşebilir (aynı hareketin başka biçimde yeniden gelmesi). Aksi hâlde
/// ardışık iki ekstrenin sınırında her gün aynı büfeden alınan 450 TL'lik
/// alışverişler birbirinin "tekrarı" sanılırdı.
///
/// Eşleşen taslak `selected=false` döner (kullanıcı incelemede yeniden
/// işaretler).
library;

import 'package:cunehat/core/utils/text_search.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// Yaklaşık eşleşmede iki tarih arasında izin verilen en büyük gün farkı.
/// Kart harcaması bankaya ertesi gün düşebilir; elle giriş formu tarihi
/// "şimdi"ye ayarlar ve kullanıcı çoğu zaman sonradan girer.
const int kMaxDayDistance = 3;

List<ImportDraft> markDuplicateDrafts(
  List<ImportDraft> drafts,
  List<TransactionEntity> existing, {
  bool rowsProvenDistinct = false,
  String? Function(String categoryId)? rootOf,
}) {
  // Defterdeki her kayıt tek kullanımlık: eşleşince tüketilir.
  final pool = <_Existing>[];
  final byStrong = <String, List<_Existing>>{};
  final byWeak = <String, List<_Existing>>{};
  for (final t in existing) {
    final money = _money(t.date, t.amount, t.isExpense);
    final reference = _norm(t.reference);
    final entry = _Existing(t, hasReference: reference != null);
    pool.add(entry);
    if (reference != null) {
      (byStrong['$money|$reference'] ??= []).add(entry);
    }
    (byWeak['$money|${_normTitle(t.title)}'] ??= []).add(entry);
  }

  final result = List<ImportDraft>.of(drafts);
  final withinFile = <String, ImportDraft>{};

  for (var i = 0; i < drafts.length; i++) {
    final d = drafts[i];
    final money = _money(d.date, d.amount, !d.isIncome);
    final reference = _norm(d.reference);
    final weakKey = '$money|${_normTitle(d.description)}';

    // Dosya içi tekrar: referans yalnız AYIRICIDIR, yerine geçmez — aksi halde
    // dekontu paylaşan havale+masraf çifti tek satır sanılır.
    if (!rowsProvenDistinct) {
      final fileKey = '$weakKey|${reference ?? ''}';
      final first = withinFile[fileKey];
      if (first != null) {
        result[i] = d.copyWith(
          duplicateOf: DuplicateMatch(
            kind: DuplicateKind.withinFile,
            existingTitle: first.description,
            existingAmount: first.amount,
            existingDate: first.date,
          ),
          selected: false,
        );
        continue;
      }
      withinFile[fileKey] = d;
    }

    final matched =
        (reference != null ? _consume(byStrong['$money|$reference']) : null) ??
            // Referanslı bir taslak, referanslı FARKLI bir kayda zayıf
            // anahtardan bağlanamaz.
            _consume(byWeak[weakKey], skipReferenced: reference != null);
    if (matched != null) {
      final t = matched.tx;
      result[i] = d.copyWith(
        duplicateOf: DuplicateMatch(
          kind: DuplicateKind.exact,
          existingId: t.id,
          existingTitle: t.title,
          existingTag: t.tag,
          existingAmount: t.amount,
          existingDate: t.date,
          existingIsSystem: t.isSystem,
        ),
        selected: false,
      );
    }
  }

  _markApproximate(result, pool, rootOf);
  return result;
}

// ------------------------------------------------------------- yaklaşık

/// Eşleşme sayılması için gereken en düşük puan ve "güçlü" eşik. Puanlar
/// [_approximateMatch] içinde; örnekler (kullanıcının kendi senaryosu):
///
/// | elle giriş               | tutar | gün | kelime | kategori | puan      |
/// |--------------------------|-------|-----|--------|----------|-----------|
/// | 913 · aynı gün · Market  | 2,5   | 2   | —      | 1        | 5,5 güçlü |
/// | 910 · aynı gün · Market  | 1,5   | 2   | —      | 1        | 4,5 olası |
/// | 910 · "bim" · aynı gün   | 1,5   | 2   | 2      | 1        | 6,5 güçlü |
/// | 910 · 2 gün sonra        | 1,5   | 1   | —      | 1        | 3,5 YOK   |
const double _minScore = 4.0;
const double _strongScore = 5.5;

const Map<AmountPattern, double> _amountScore = {
  AmountPattern.exact: 3.0,
  AmountPattern.centsDropped: 2.5,
  AmountPattern.roundedSmall: 1.5,
  AmountPattern.roundedLarge: 1.0,
};

const List<double> _dayScore = [2.0, 1.5, 1.0, 0.5];

void _markApproximate(
  List<ImportDraft> drafts,
  List<_Existing> pool,
  String? Function(String categoryId)? rootOf,
) {
  final byDay = <int, List<_Existing>>{};
  for (final e in pool) {
    if (e.consumed) continue;
    (byDay[_dayNumber(e.tx.date)] ??= []).add(e);
  }
  if (byDay.isEmpty) return;

  final pairs = <_Pair>[];
  for (var i = 0; i < drafts.length; i++) {
    final d = drafts[i];
    if (d.duplicateOf != null) continue;
    final day = _dayNumber(d.date);
    for (var offset = -kMaxDayDistance; offset <= kMaxDayDistance; offset++) {
      for (final e in byDay[day + offset] ?? const <_Existing>[]) {
        final scored = _approximateMatch(d, e.tx, offset.abs(), rootOf);
        if (scored != null) pairs.add(_Pair(i, e, scored.$1, scored.$2));
      }
    }
  }

  // En güçlü çift önce: aynı kayda iki taslak, aynı taslağa iki kayıt
  // adaysa en iyi açıklanan eşleşme kazanır. Eşitlikte daha yakın gün,
  // daha küçük tutar farkı, sonra sıra (deterministik).
  pairs.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byDays = a.match.dayDistance.compareTo(b.match.dayDistance);
    if (byDays != 0) return byDays;
    final byDelta =
        a.match.amountDelta.abs().compareTo(b.match.amountDelta.abs());
    if (byDelta != 0) return byDelta;
    return a.draftIndex.compareTo(b.draftIndex);
  });

  final taken = <int>{};
  for (final p in pairs) {
    if (p.existing.consumed || taken.contains(p.draftIndex)) continue;
    p.existing.consumed = true;
    taken.add(p.draftIndex);
    drafts[p.draftIndex] = drafts[p.draftIndex].copyWith(
      duplicateOf: p.match,
      selected: false,
    );
  }
}

/// [d] (bankanın satırı) ile [t] (defter kaydı) yaklaşık aynı hareket mi?
/// Evetse gerekçeli eşleşme + puan, değilse `null`.
(DuplicateMatch, double)? _approximateMatch(
  ImportDraft d,
  TransactionEntity t,
  int dayDistance,
  String? Function(String categoryId)? rootOf,
) {
  if (t.isIncome != d.isIncome) return null;

  // İki taraf da banka numarası taşıyor ve farklıysa ayrı hareketlerdir.
  final draftRef = _norm(d.reference);
  final existingRef = _norm(t.reference);
  if (draftRef != null && existingRef != null && draftRef != existingRef) {
    return null;
  }

  final pattern = amountPatternOf(bank: d.amount, typed: t.amount);
  if (pattern == null) return null;

  final shared = _sharedWord(bankText: d.description, typedText: t.title);
  final fromStatement = existingRef != null || _looksImported(t.title);
  if (fromStatement &&
      (pattern != AmountPattern.exact || dayDistance != 0 || shared == null)) {
    return null;
  }

  final sameCategory = _sameCategory(d.categoryId, t.tag, rootOf);
  var score = _amountScore[pattern]! + _dayScore[dayDistance];
  if (shared != null) score += 2.0;
  if (sameCategory) score += 1.0;
  if (score < _minScore) return null;

  return (
    DuplicateMatch(
      kind: DuplicateKind.approximate,
      existingId: t.id,
      existingTitle: t.title,
      existingTag: t.tag,
      existingAmount: t.amount,
      existingDate: t.date,
      existingIsSystem: t.isSystem,
      amountDelta: ((d.amount - t.amount) * 100).round() / 100,
      amountPattern: pattern,
      dayDistance: dayDistance,
      sharedWord: shared,
      categoryMatches: sameCategory,
      strong: score >= _strongScore,
    ),
    score,
  );
}

/// Elle yazılmış [typed] tutar, bankanın [bank] tutarının bir yuvarlaması mı?
///
/// Kabul edilen kalıplar ([AmountPattern]): birebir, kuruşları atılmış
/// (tam sayı ve fark < 1), 5/10'a yuvarlanmış (fark yarım adımdan küçük),
/// büyük tutarda 50/100'e yuvarlanmış. Göreli fark [_maxRelativeGap]'i
/// aşarsa hiçbiri sayılmaz: 7,50 TL'lik bir harcamaya "10" demek yuvarlama
/// değil başka bir harcamadır.
AmountPattern? amountPatternOf({required double bank, required double typed}) {
  final b = (bank.abs() * 100).round();
  final t = (typed.abs() * 100).round();
  if (b == t) return AmountPattern.exact;
  if (b == 0 || t == 0) return null;
  final gap = (b - t).abs();
  if (gap / b > _maxRelativeGap) return null;

  if (t % 100 == 0 && gap < 100) return AmountPattern.centsDropped;
  if (t % 1000 == 0 && gap <= 500) return AmountPattern.roundedSmall;
  if (t % 500 == 0 && gap <= 250) return AmountPattern.roundedSmall;
  if (b >= 100000 && t % 10000 == 0 && gap <= 5000) {
    return AmountPattern.roundedLarge;
  }
  if (b >= 50000 && t % 5000 == 0 && gap <= 2500) {
    return AmountPattern.roundedLarge;
  }
  return null;
}

const double _maxRelativeGap = 0.2;

/// Kayıt ekstreden mi gelmiş görünüyor? Banka açıklaması ya kod taşır
/// ("SOK-10419", 4+ rakam) ya da tamamı BÜYÜK HARFTİR; elle giriş formu
/// cümle düzeninde yazdırır ve boş notu kategori adıyla ("Market") doldurur.
bool _looksImported(String title) {
  if (_longDigits.hasMatch(title)) return true;
  final letters = title.replaceAll(_nonLetter, '');
  if (letters.length < 6) return false;
  return letters == letters.toUpperCase() && letters != letters.toLowerCase();
}

final RegExp _longDigits = RegExp(r'\d{4,}');
final RegExp _nonLetter = RegExp(r'[^\p{L}]', unicode: true);

/// İki metinde de geçen, üye işyerini gösteren kelime — [typedText]'in kendi
/// yazımıyla ("bim").
///
/// Kullanıcı marka adına Türkçe ek getirir ("bimden", "migrosta"), banka
/// getirmez: bu yüzden ön ek eşleşmesi TEK YÖNLÜDÜR — bankanın kelimesi
/// kullanıcınınkinin başıysa ve kalan en fazla 4 harfse sayılır. Ters yön
/// (kullanıcının kısa kelimesi bankanın uzun kelimesinin başı: "kar" ↔
/// "KARACA") birebir eşitlik ister.
String? _sharedWord({required String bankText, required String typedText}) {
  final bank = CategoryGuesser.meaningfulTokens(bankText);
  if (bank.isEmpty) return null;
  for (final raw in typedText.split(_wordSplit)) {
    final tokens = CategoryGuesser.meaningfulTokens(raw);
    if (tokens.isEmpty) continue;
    final typed = tokens.first;
    // Kesme işaretinden sonra kalan ek ("bim'den" → "den") kelime değildir.
    if (_suffixFragments.contains(typed)) continue;
    for (final b in bank) {
      if (typed == b || (typed.startsWith(b) && typed.length - b.length <= 4)) {
        return raw;
      }
    }
  }
  return null;
}

final RegExp _wordSplit = RegExp(r'[^0-9\p{L}]+', unicode: true);

/// Kesme işaretiyle ayrılmış ekler (katlanmış hâlleriyle).
const Set<String> _suffixFragments = {
  'den',
  'dan',
  'ten',
  'tan',
  'nin',
  'nun',
  'yla',
  'yle',
  'dir',
  'dur',
};

/// Taslağın tahmini kategorisi kaydınkiyle aynı mı (ya da aynı ana
/// kategorinin altında mı)?
bool _sameCategory(
  String? draftCategory,
  String existingTag,
  String? Function(String categoryId)? rootOf,
) {
  if (draftCategory == null || existingTag.isEmpty) return false;
  if (draftCategory == existingTag) return true;
  if (rootOf == null) return false;
  final a = rootOf(draftCategory);
  return a != null && a == rootOf(existingTag);
}

// --------------------------------------------------------------- ortak

/// Havuzdan ilk tüketilmemiş kaydı tüketir; bulduysa onu döner.
_Existing? _consume(List<_Existing>? candidates,
    {bool skipReferenced = false}) {
  if (candidates == null) return null;
  for (final c in candidates) {
    if (c.consumed) continue;
    if (skipReferenced && c.hasReference) continue;
    c.consumed = true;
    return c;
  }
  return null;
}

class _Existing {
  final TransactionEntity tx;
  final bool hasReference;
  bool consumed = false;
  _Existing(this.tx, {required this.hasReference});
}

class _Pair {
  final int draftIndex;
  final _Existing existing;
  final DuplicateMatch match;
  final double score;
  const _Pair(this.draftIndex, this.existing, this.match, this.score);
}

String? _norm(String? raw) {
  final s = raw?.trim();
  return (s == null || s.isEmpty) ? null : s;
}

String _money(DateTime date, double amount, bool isExpense) {
  final day = DateTime(date.year, date.month, date.day).toIso8601String();
  final cents = (amount.abs() * 100).round() * (isExpense ? -1 : 1);
  return '$day|$cents';
}

/// Takvim günü numarası (UTC üzerinden; yaz saati geçişi gün farkını bozmasın).
int _dayNumber(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

/// Zayıf anahtarın başlık parçası.
///
/// [foldTr] kullanılır, `toLowerCase()` DEĞİL: Dart noktasız `I`'yı `i`'ye
/// çevirir, `ı`'ya değil. Ekstre "IŞIK ELEKTRİK" yazar (`işik elektrik`),
/// kullanıcı elle "Işık Elektrik" girer (`ışık elektrik`) — iki taraf hiç
/// eşleşmez ve aynı hareket ikinci kez deftere yazılırdı. (Trim + iç
/// boşlukların teklenmesi [foldTr]'nin içinde.)
String _normTitle(String desc) => foldTr(desc);
