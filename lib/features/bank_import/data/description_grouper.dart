import 'package:cunehat/core/utils/text_search.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';

/// Açıklamaları birbirine benzeyen taslakların kümesi.
///
/// [indexes] KAYNAK listedeki gerçek indekslerdir: inceleme ekranının tüm
/// mutasyonları indeks tabanlı olduğu için grup, üzerinde çalıştığı listeyle
/// birlikte taşınmak zorunda (bkz. `BankImportReviewView._visible`).
typedef DraftGroup = ({
  /// Ortak adın katlanmış hâli — kimlik ve karşılaştırma için.
  String key,

  /// Kullanıcıya gösterilecek ortak ad, ekstredeki ÖZGÜN yazımıyla.
  String label,

  /// Grubun türü. Gruplar tür bazında ayrılır: gider kategorisi gelir
  /// satırına yazılamaz, dolayısıyla karışık bir gruba tek kategori
  /// atanamazdı.
  bool isIncome,

  /// Kaynak listedeki indeksler, artan sırada.
  List<int> indexes,

  /// Gruptaki tutarların toplamı (mutlak; yön [isIncome] ile taşınır).
  double totalAmount,
});

/// Bir grubun anlamlı sayılması için gereken en az satır sayısı. Tek satırlık
/// "grup" toplu işlem değildir, yalnız listeyi şişirir.
const int kMinGroupSize = 2;

/// [drafts] içindeki benzer açıklamaları gruplar.
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
/// grubu ayrı çıkar, THY satırı gruba HİÇ girmez. Fazla birleştirmek toplu
/// atamada sessiz yanlış kategoriye yol açar; az gruplamanın bedeli ise o
/// satırın elle seçilmesidir.
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
/// ağı arayüzdedir: hem grup sayfası hem tek-dokunuş kısayolu, uygulamadan
/// ÖNCE etkilenecek satırlardan örnek açıklama gösterir. Buradaki bir
/// sıkılaştırma o örnekleri kaldırmanın gerekçesi olamaz.
///
/// [scope] verilirse yalnız o indeksler kümelenir (ör. yalnız kategorisiz
/// satırlar). Sonuç önce satır sayısına, sonra toplam tutara göre azalan
/// sıralanır — kullanıcının en çok kazanacağı grup en üstte.
List<DraftGroup> groupSimilarDrafts(
  List<ImportDraft> drafts, {
  Iterable<int>? scope,
  int minSize = kMinGroupSize,
}) {
  final indexes =
      scope?.toList() ?? [for (var i = 0; i < drafts.length; i++) i];

  // Tür başına ayrı ağaç: gruplar tür karıştıramaz.
  final roots = <bool, _Node>{false: _Node(), true: _Node()};
  final words = <int, List<_Word>>{};

  for (final i in indexes) {
    if (i < 0 || i >= drafts.length) continue;
    final draft = drafts[i];
    final tokens = _tokenize(draft.description);
    if (tokens.isEmpty) continue;
    words[i] = tokens;
    roots[draft.isIncome]!.insert(tokens.map((w) => w.folded).toList(), i);
  }

  final out = <DraftGroup>[];
  for (final entry in roots.entries) {
    _collect(
      node: entry.value,
      path: const [],
      isIncome: entry.key,
      drafts: drafts,
      words: words,
      minSize: minSize,
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

/// [drafts] içinde [index] satırına benzeyen DİĞER satırların indeksleri.
/// Benzer yoksa boş liste. Satır bazında "bunun benzerlerine de uygula"
/// kısayolu için.
List<int> similarDraftIndexes(List<ImportDraft> drafts, int index) {
  for (final group in groupSimilarDrafts(drafts)) {
    if (group.indexes.contains(index)) {
      return [
        for (final i in group.indexes)
          if (i != index) i,
      ];
    }
  }
  return const [];
}

// --------------------------------------------------------------- kelimeleme

/// Bir kelimenin özgün ve katlanmış hâli. İkisi birlikte taşınır: karşılaştırma
/// katlanmış üzerinden yapılır ama kullanıcıya gösterilecek etiket ekstrenin
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

/// Açıklamayı anahtar kelimelere böler.
///
/// Eleme sonrası HİÇBİR kelime kalmazsa ("KREDİ KARTI ÖDEMESİ" gibi tamamen
/// jenerik satırlar) ham kelimelere geri dönülür: aksi halde birbiriyle
/// alakasız tüm jenerik satırlar tek boş anahtarda toplanırdı.
List<_Word> _tokenize(String description) {
  final all = <_Word>[
    for (final m in _wordPattern.allMatches(description))
      (raw: m[0]!, folded: _fold(m[0]!)),
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
String _fold(String input) => foldTr(input)
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c');

// ------------------------------------------------------------------- ağaç

class _Node {
  final Map<String, _Node> children = {};

  /// Bu düğümden GEÇEN tüm taslaklar (kendisinde bitenler dahil).
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
  required bool isIncome,
  required List<ImportDraft> drafts,
  required Map<int, List<_Word>> words,
  required int minSize,
  required List<DraftGroup> out,
}) {
  final qualifying = [
    for (final e in node.children.entries)
      if (e.value.passing.length >= minSize) e,
  ];

  if (qualifying.isEmpty) {
    if (path.isNotEmpty && node.passing.length >= minSize) {
      out.add(_group(node.passing, path, isIncome, drafts, words));
    }
    return;
  }

  for (final child in qualifying) {
    _collect(
      node: child.value,
      path: [...path, child.key],
      isIncome: isIncome,
      drafts: drafts,
      words: words,
      minSize: minSize,
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
    out.add(_group(residual, path, isIncome, drafts, words));
  }
}

DraftGroup _group(
  List<int> members,
  List<String> path,
  bool isIncome,
  List<ImportDraft> drafts,
  Map<int, List<_Word>> words,
) {
  final indexes = [...members]..sort();
  // Etiket, ekstrenin kendi yazımıyla: ön ekteki kelimeler her üyede aynı
  // konumda durduğundan ilk üyeden okunur (kararlı sonuç için en küçük indeks).
  final sample = words[indexes.first]!;
  final label = [for (var i = 0; i < path.length; i++) sample[i].raw].join(' ');
  return (
    key: path.join(' '),
    label: label,
    isIncome: isIncome,
    indexes: indexes,
    totalAmount: indexes.fold(0.0, (sum, i) => sum + drafts[i].amount),
  );
}
