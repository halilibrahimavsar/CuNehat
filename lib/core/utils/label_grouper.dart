/// Birbirine benzeyen METİN ETİKETLERİNİ kümeleyen ortak motor.
///
/// Ekstre inceleme ekranı ("benzer hareketlere toplu kategori ata") ile rapor
/// sayfası ("en çok harcanan yer") aynı soruyu soruyor: bu satırların hangileri
/// aslında AYNI üye işyeri? İki ayrı kopya er ya da geç sapacağı için motor
/// burada, tek yerde durur; çağıranlar yalnız kendi kayıtlarını `LabelItem`'a
/// çevirir.
///
/// **Neden ön ek (prefix) kümelemesi:** Türkçe ekstrelerde üye işyeri adı
/// açıklamanın BAŞINDA durur, arkasına şube/şehir/kod eklenir
/// ("SOK-10419-USKUDAR", "SOK-22133-KADIKOY"). Ortak ön ek bu yüzden markanın
/// kendisidir; token kümesi benzerliği (Jaccard) aynı işi yapar ama "hangi ad"
/// sorusuna cevap veremez — kullanıcıya gösterilecek bir etiket kalmaz.
///
/// Kümeleme, kelime ön eki üzerine kurulu bir ağaçta (trie) yapılır ve
/// **ayrışan dal daha derine inmez**: `TURK TELEKOM`×3 + `TURK HAVA YOLLARI`×1
/// durumunda "turk" düğümünde durulup dördü birleştirilmez — `turk telekom`
/// grubu ayrı çıkar, THY satırı gruba HİÇ girmez.
///
/// **BİLİNEN SINIR — ortak ön ek her zaman marka değildir.** Ölçüldü
/// (30 Ağu 2026): iki satır ortak bir ilk kelimede buluşup sonra ayrışıyorsa
/// o kelimede gruplanırlar, kelime marka olmasa bile:
///
/// ```
/// ŞOK Üsküdar    + ŞOK Kadıköy            → "sok"       ✔ doğru
/// TÜRK Hava Yol. + TÜRK Ekonomi Bankası   → "turk"      ✘ yanlış
/// ```
///
/// İkisi YAPISAL OLARAK AYNI (ön ek + ayrışan anlamlı kelimeler), yani hiçbir
/// eşik, derinlik ya da dal kuralı birini kesip diğerini bırakamaz — ayrım
/// anlamsal, sözlük gerektirir. Bu yüzden kümeleme bir ÖNERİDİR ve güvenlik
/// ağı arayüzdedir: ekstre tarafında toplu atama uygulanmadan ÖNCE örnek
/// açıklama gösterilir, rapor tarafında ise grup yalnız BİLGİ verir, hiçbir
/// veriyi değiştirmez. Buradaki bir sıkılaştırma o güvenlik ağlarını
/// kaldırmanın gerekçesi olamaz.
library;

import 'package:cunehat/core/utils/text_search.dart';

/// Kümelenecek tek bir kayıt.
typedef LabelItem = ({
  /// Kümelemeye giren metin (ekstre açıklaması, işlem başlığı…).
  String text,

  /// Grubun toplamına eklenecek tutar (mutlak).
  double amount,

  /// Ayrı ağaçta kümelenecek küme. Farklı kovalar ASLA aynı gruba düşmez —
  /// ekstrede gelir/gider ayrımı bu yolla korunuyor (gider kategorisi gelir
  /// satırına yazılamaz).
  int bucket,
});

/// Etiketleri birbirine benzeyen kayıtların kümesi.
typedef LabelGroup = ({
  /// Ortak adın katlanmış hâli — kimlik ve karşılaştırma için.
  String key,

  /// Kullanıcıya gösterilecek ortak ad, kaynağın ÖZGÜN yazımıyla.
  String label,

  /// Grubun kovası ([LabelItem.bucket]).
  int bucket,

  /// Kaynak listedeki indeksler, artan sırada.
  List<int> indexes,

  /// Gruptaki tutarların toplamı.
  double totalAmount,
});

/// Bir grubun anlamlı sayılması için gereken en az satır sayısı. Tek satırlık
/// "grup" toplu işlem değildir, yalnız listeyi şişirir.
const int kMinGroupSize = 2;

/// [items] içindeki benzer etiketleri gruplar.
///
/// [scope] verilirse yalnız o indeksler kümelenir (ör. yalnız kategorisiz
/// satırlar). Sonuç önce satır sayısına, sonra toplam tutara göre azalan
/// sıralanır — kullanıcının en çok kazanacağı grup en üstte.
///
/// [maxDepth] anahtarın kaç kelimeye kadar derinleşebileceğini sınırlar.
/// Varsayılan sınırsız: ekstre tarafında toplu kategori ataması yapılacağı
/// için DAR gruplar tercih edilir (yanlış birleştirmenin bedeli sessiz yanlış
/// kategori).
///
/// Rapor tarafında ise 1 verilir ve sebebi ölçüldü: "SOK-10419-USKUDAR" ×2 +
/// "SOK-22133-KADIKOY" ×1 girdisinde derinlik sınırsızken motor `sok` →
/// `uskudar` dalına iniyor, iki Üsküdar satırını grupluyor ve **Kadıköy
/// satırı hiçbir gruba giremediği için listeden tamamen düşüyor**. "En çok
/// harcanan yer" kartında bu, ŞOK'un toplamını 790 yerine 510 gösterir. İlk
/// anlamlı kelimede durmak markayı yakalar; şube/şehir eki zaten ayrıştırıcı
/// bir bilgi değil.
List<LabelGroup> groupSimilarLabels(
  List<LabelItem> items, {
  Iterable<int>? scope,
  int minSize = kMinGroupSize,
  int? maxDepth,
}) {
  final indexes = scope?.toList() ?? [for (var i = 0; i < items.length; i++) i];

  // Kova başına ayrı ağaç: gruplar kova karıştıramaz.
  final roots = <int, _Node>{};
  final words = <int, List<_Word>>{};

  for (final i in indexes) {
    if (i < 0 || i >= items.length) continue;
    final item = items[i];
    final tokens = _tokenize(item.text);
    if (tokens.isEmpty) continue;
    words[i] = tokens;
    roots
        .putIfAbsent(item.bucket, _Node.new)
        .insert(tokens.map((w) => w.folded).toList(), i);
  }

  final out = <LabelGroup>[];
  for (final entry in roots.entries) {
    _collect(
      node: entry.value,
      path: const [],
      bucket: entry.key,
      items: items,
      words: words,
      minSize: minSize,
      maxDepth: maxDepth,
      out: out,
    );
  }

  out.sort((a, b) {
    final byCount = b.indexes.length.compareTo(a.indexes.length);
    if (byCount != 0) return byCount;
    final byAmount = b.totalAmount.compareTo(a.totalAmount);
    if (byAmount != 0) return byAmount;
    return a.label.compareTo(b.label);
  });
  return out;
}

// --------------------------------------------------------------- kelimeleme

/// Bir kelimenin özgün ve katlanmış hâli. İkisi birlikte taşınır: karşılaştırma
/// katlanmış üzerinden yapılır ama kullanıcıya gösterilecek etiket kaynağın
/// kendi yazımı olmalı ("MİGROS", "migros" değil).
typedef _Word = ({String raw, String folded});

/// Harf/rakam dizileri. Ekstreler ayraçları tutarsız kullanıyor
/// ("SOK-10419-USKUDAR" ↔ "SOK 10419 USKUDAR"); ayraç kelime sınırıdır.
final RegExp _wordPattern = RegExp(r'[0-9\p{L}]+', unicode: true);

/// Bir kelimenin kaç rakam taşıdığı bu sayıya ULAŞIRSA kod/referans sayılır.
///
/// Eşik neden 4: mağaza kodu ("10419"), kart parçası ("4506"), tarih damgası
/// ve dekont numarası elenmeli; ama gerçek marka adı olan "A101" (3 rakam) ve
/// "N11" (2 rakam) elenmemeli.
const int _digitCodeThreshold = 4;

/// Marka taşımayan, neredeyse her ekstrede geçen jenerik kelimeler. Ön ekin
/// BAŞINDA durduklarında ("ODEME - MIGROS") ilgisiz satırları tek gruba
/// çekerler; bu yüzden anahtar kurulmadan önce elenirler.
const Set<String> _noiseWords = {
  'pos',
  'odeme',
  'odemesi',
  'odemeleri',
  'para',
  'transfer',
  'islem',
  'islemi',
  'islemleri',
  'tahsilat',
  'harcama',
  'ucret',
  'ucreti',
  'masraf',
  'komisyon',
  'bsmv',
  'kdv',
  'tutar',
  've',
  'ile',
  'san',
  'sanayi',
  'tic',
  'ticaret',
  'ltd',
  'sti',
  'sirketi',
  'anonim',
  'as',
  'tl',
  'try',
};

/// Metni anahtar kelimelere böler.
///
/// Eleme sonrası HİÇBİR kelime kalmazsa ("KREDİ KARTI ÖDEMESİ" gibi tamamen
/// jenerik satırlar) ham kelimelere geri dönülür: aksi halde birbiriyle
/// alakasız tüm jenerik satırlar tek boş anahtarda toplanırdı.
List<_Word> _tokenize(String text) {
  final all = <_Word>[
    for (final m in _wordPattern.allMatches(text))
      (raw: m[0]!, folded: foldForGrouping(m[0]!)),
  ];
  final meaningful = [
    for (final w in all)
      if (_isMeaningful(w.folded)) w,
  ];
  return meaningful.isEmpty ? all : meaningful;
}

bool _isMeaningful(String folded) {
  if (folded.length < 2) return false;
  if (_noiseWords.contains(folded)) return false;
  var digits = 0;
  for (final c in folded.codeUnits) {
    if (c >= 0x30 && c <= 0x39) digits++;
  }
  if (digits == folded.length) return false;
  return digits < _digitCodeThreshold;
}

/// Türkçe katlama + aksan sadeleştirme.
///
/// [foldTr] tek başına yetmez: aynı üye işyerini bir banka "ÜSKÜDAR", diğeri
/// "USKUDAR" yazıyor. Aksanı da düşürmek iki yazımı tek anahtara indirir.
/// (Aynı gerekçeyle `CategoryGuesser` de kendi sadeleştirmesini yapar.)
String foldForGrouping(String input) => foldTr(input)
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c');

// ------------------------------------------------------------------- ağaç

class _Node {
  final Map<String, _Node> children = {};

  /// Bu düğümden GEÇEN tüm kayıtlar (kendisinde bitenler dahil).
  final List<int> passing = [];

  void insert(List<String> path, int index) {
    var node = this;
    node.passing.add(index);
    for (final token in path) {
      node = node.children.putIfAbsent(token, _Node.new);
      node.passing.add(index);
    }
  }
}

void _collect({
  required _Node node,
  required List<String> path,
  required int bucket,
  required List<LabelItem> items,
  required Map<int, List<_Word>> words,
  required int minSize,
  required int? maxDepth,
  required List<LabelGroup> out,
}) {
  // Derinlik sınırına gelindi: bu düğüm grubun kendisidir, alt dallara
  // inilmez (bkz. [groupSimilarLabels] ölçümü).
  if (maxDepth != null && path.length >= maxDepth) {
    if (path.isNotEmpty && node.passing.length >= minSize) {
      out.add(_group(node.passing, path, bucket, items, words));
    }
    return;
  }

  final qualifying = [
    for (final e in node.children.entries)
      if (e.value.passing.length >= minSize) e,
  ];

  if (qualifying.isEmpty) {
    if (path.isNotEmpty && node.passing.length >= minSize) {
      out.add(_group(node.passing, path, bucket, items, words));
    }
    return;
  }

  for (final child in qualifying) {
    _collect(
      node: child.value,
      path: [...path, child.key],
      bucket: bucket,
      items: items,
      words: words,
      minSize: minSize,
      maxDepth: maxDepth,
      out: out,
    );
  }

  // Hiçbir yeterli dala girmeyen artık satırlar kendi başlarına grup olur —
  // ama yalnız yeterince kalabalıklarsa. Tekler gruplanmadan bırakılır:
  // ayrışmış bir satırı komşu markanın grubuna itmek toplu atamada onu yanlış
  // kategoriye sokardı.
  final covered = {for (final c in qualifying) ...c.value.passing};
  final residual = [
    for (final i in node.passing)
      if (!covered.contains(i)) i,
  ];
  if (path.isNotEmpty && residual.length >= minSize) {
    out.add(_group(residual, path, bucket, items, words));
  }
}

LabelGroup _group(
  List<int> members,
  List<String> path,
  int bucket,
  List<LabelItem> items,
  Map<int, List<_Word>> words,
) {
  final indexes = [...members]..sort();
  // Etiket, kaynağın kendi yazımıyla: ön ekteki kelimeler her üyede aynı
  // konumda durduğundan ilk üyeden okunur (kararlı sonuç için en küçük indeks).
  final sample = words[indexes.first]!;
  final label = [for (var i = 0; i < path.length; i++) sample[i].raw].join(' ');
  return (
    key: path.join(' '),
    label: label,
    bucket: bucket,
    indexes: indexes,
    totalAmount: indexes.fold(0.0, (sum, i) => sum + items[i].amount),
  );
}
