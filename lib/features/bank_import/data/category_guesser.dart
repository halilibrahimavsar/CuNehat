import 'package:cunehat/core/l10n/category_seed_names.dart';
import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// Sözlüğün hedeflediği kategori: alt kategori ise [parentKey] doludur.
///
/// Hedef bir ÇİFT olmak zorunda, çünkü kullanıcının hiyerarşisi bizimkinden
/// sapabilir: "Elektrik" hem `Fatura` altında hem kökte durabilir, hem de hiç
/// olmayabilir. Çözüm sırası [CategoryGuesser.resolveTarget] içinde.
///
/// Taşınan şey AD değil ANAHTAR'dır (`bills.electricity`): kategori adı
/// kullanıcı verisidir ve kurulduğu dilde donar, anahtar ise sabittir
/// (bkz. `category_seed_names.dart`).
typedef CategoryTarget = ({String key, String? parentKey});

/// Anahtar yolunda ana ve alt kategoriyi ayıran işaret.
const String kCategoryKeySeparator = '.';

/// `"bills.electricity"` → `(key: 'bills.electricity', parentKey: 'bills')`.
/// Ayraç yoksa kök hedef.
CategoryTarget parseCategoryTarget(String path) {
  final parts = path.split(kCategoryKeySeparator);
  if (parts.length < 2) return (key: path, parentKey: null);
  return (key: path, parentKey: parts.first);
}

/// Yeni kategori önerisi: [drafts] içinde eşleşen ama kullanıcının GERÇEK
/// listesinde karşılığı olmayan bir grup. Yalnız kullanıcı onayıyla
/// [CategoryEntity]'ye dönüşür (bkz. `BankImportCubit.resolveCategorySuggestions`).
class CategorySuggestion extends Equatable {
  /// Kurulacak ad — ÖNERİ ÜRETİLDİĞİ ANDAKİ dilde çözülmüş hâli. Kurulduktan
  /// sonra kullanıcı verisidir; sonradan dil değişse de değişmez.
  final String name;

  /// Kurulacaksa altına gireceği ana kategorinin ADI; kök olarak kurulacaksa
  /// `null`. Ana kategori kullanıcıda yoksa o da birlikte kurulur.
  final String? parentName;

  /// Üst kategori kurulursa kullanılacak ikon; [parentName] boşsa `null`.
  final String? parentIconName;

  final bool isIncome;
  final String iconName;
  const CategorySuggestion({
    required this.name,
    required this.isIncome,
    required this.iconName,
    this.parentName,
    this.parentIconName,
  });

  @override
  List<Object?> get props =>
      [name, parentName, parentIconName, isIncome, iconName];
}

/// Banka ekstresi açıklamasından kategori tahmini (best-effort/tahminî).
///
/// Yalnız şu ikisi birden sağlandığında bir kategori döner: (1) açıklamada
/// bilinen bir anahtar kelime geçiyor VE (2) tahmin edilen hedefe karşılık
/// gelen kategori kullanıcının GERÇEK listesinde var (silinmemiş/yeniden
/// adlandırılmamış). Aksi halde `null` — çağıran taraf satırı kategorisiz
/// bırakır; yani bu sınıf hiçbir zaman önceki davranıştan daha kötü bir sonuç
/// üretmez. Kullanıcı yine de her satırın kategorisini elle değiştirebilir
/// (bkz. inceleme ekranı).
///
/// Hedef karşılığı HİÇ YOKSA [suggestNewCategories] onu kullanıcı onayına
/// sunar; onaysız hiçbir kategori yaratılmaz (bkz. kullanıcı talebi 2026-07-21).
@lazySingleton
class CategoryGuesser {
  /// Anahtar: hedef kategorinin ANAHTAR YOLU. Başlangıç paketinde bir alt
  /// kategori karşılığı olan gruplar `"ana.alt"` biçiminde yazılır — ekstre
  /// tahmininin iki seviyeli hiyerarşiyi hiç kullanmaması, kullanıcının
  /// kurduğu 31 alt kategoriyi ölü ağırlığa çeviriyordu ("elektrik faturası"
  /// `bills` köküne düşüyor, `bills.electricity` boş kalıyordu).
  ///
  /// Karşılığı olmayan bir hedef sessizce ana kategoriye düşer
  /// ([resolveTarget]), yani alt kategorisini silen kullanıcı eskisi gibi kök
  /// eşleşmesi almaya devam eder.
  ///
  /// Anahtarlar başlangıç paketiyle SÖZLEŞMEDİR: buradaki bir anahtar pakette
  /// karşılık bulmazsa dokunulmamış bir kurulumda o grubun tahmini hiçbir
  /// zaman tutmaz. Bağ test edilir (`category_starter_pack_test.dart`).
  /// Anahtar kullanmanın ikinci kazancı: bir çeviriyi düzeltmek (ya da
  /// kullanıcının dili değiştirmesi) sözlüğü koparmaz.
  static const Map<String, List<String>> _expenseGroups = {
    'dining.restaurant': [
      'restoran',
      'restaurant',
      'lokanta',
      'sushi',
      'pizza',
      'baklava',
      'kebap',
      'doner',
    ],
    'dining.cafe': [
      'starbucks',
      'cafe',
      'kafe',
      'kahve dunyasi',
      'simit saray',
      'gloria jean',
      'pastane',
    ],
    'dining.takeaway': [
      'yemeksepeti',
      'trendyol yemek',
      'getir yemek',
      'tikla gelsin',
    ],
    'dining': [
      'burger king',
      'mcdonalds',
      'mcdonald',
      ' kfc ',
      'domino',
      'popeyes',
      // Üye işyeri adında yemeğin TÜRÜ geçen küçük işletmeler (gerçek QNB
      // ekstresi: "HAS CIGKOFTE", "TARIHI BAGDETLI BOREKCISI"). Marka
      // listesi bunları hiçbir zaman kapsayamaz.
      'cigkofte',
      'borek',
      'lahmacun',
      ' pide',
      'kofte',
      'burger',
      ' bufe',
      ' yemek ',
    ],
    'transport.fuel': [
      'shell',
      'opet',
      'petrol ofisi',
      ' petrol ',
      ' total ',
      'aytemiz',
      'akaryakit',
      'benzin',
      'motorin',
      ' lpg ',
      ' bp ',
      'lukoil',
      'alpet',
      'sunpet',
      'kadoil',
    ],
    'transport.taxi': [
      'taksi',
      'uber',
      'bitaksi',
      ' bolt ',
      ' marti ',
    ],
    'transport.public': [
      ' iett ',
      'istanbulkart',
      'marmaray',
      'metrobus',
      'ego kart',
    ],
    'transport.parking': ['otopark'],
    'transport': [
      'otoyol',
      ' hgs ',
      ' ogs ',
      'kgm gecis',
      // Araç bakımı ve yol: gerçek ekstrede "SUDE MOTOR", "MEG OTOMOTIV".
      'otomotiv',
      ' motor ',
      'oto yikama',
      ' lastik',
      'nakliye',
      'turk hava yollari',
      'pegasus',
      'obilet',
    ],
    // Market (gıda/temel ihtiyaç) ile Alışveriş (giyim/elektronik/genel)
    // bilerek AYRI: ikisi tek kovada toplanınca aylık gıda harcaması
    // görünmez oluyor ve o kaleme bütçe koymak imkânsızlaşıyordu.
    'groceries': [
      'migros',
      'carrefour',
      'sok market',
      ' sok ',
      ' a101 ',
      ' bim ',
      'market',
      'getir',
      'banabi',
      'tarim kredi',
      'metro market',
      'hakmar',
      // "X GIDA" bir gıda işletmesinin ticari adıdır; gerçek ekstrelerde
      // beş ayrı üye işyeri böyle geçiyordu (MACGAL GIDA, SEYHANLAR GIDA…).
      ' gida',
      'unlu mamul',
      ' firin',
      'kuruyemis',
      'sarkuteri',
    ],
    'groceries.butcher': [' kasap', 'et ve et urunleri'],
    'groceries.produce': ['manav'],
    'housing.rent': ['kira odeme', ' kira ', 'kiraci'],
    'housing.dues': ['aidat', 'site yonetim', 'apartman yonetim'],
    'education.school': [
      'universite',
      'okul taksit',
      ' dershane ',
      ' kurs ',
    ],
    'education.books': ['yayinlari', 'kitabevi', 'kitapyurdu'],
    'education': ['egitim'],
    'bills.electricity': ['elektrik', 'enerjisa', 'bedas', 'ayedas'],
    'bills.water': [' iski ', ' aski ', ' asat ', ' izsu ', 'su faturasi'],
    'bills.gas': ['dogalgaz', 'igdas', 'izgaz', 'baskentgaz'],
    'bills.internet': [
      'superonline',
      'turknet',
      'tellcom',
      ' ttnet ',
      'internet faturasi',
      'kablonet',
      'millenicom',
      // "Türk Telekom İnternet/TV (TTNET)": `turk telekom` (Telefon) daha
      // uzun olduğu için `ttnet`i yeniyordu; bu anahtar ondan da uzun.
      'turk telekom internet',
    ],
    'bills.phone': ['turk telekom', 'turkcell', 'vodafone', ' avea '],
    'bills': ['fatura'],
    'entertainment.subscriptions': [
      'netflix',
      'spotify',
      'youtube',
      'amazon prime',
      ' blutv ',
      ' exxen ',
      'abonelik',
      'digiturk',
      'disney',
      'google play',
      'icloud',
      'apple com',
    ],
    'entertainment.games': ['playstation', 'steam', 'epic games', ' riot '],
    'entertainment.cinema': [
      'sinema',
      'cinemaximum',
      'biletix',
      'bilet',
      'konser',
    ],
    'health.pharmacy': ['eczane'],
    'health.doctor': [
      'hastane',
      'klinik',
      'klinigi',
      'poliklinik',
      'laboratuvar',
      'tip merkezi',
      'dis hekimi',
    ],
    'health.fitness': ['spor salonu', 'fitness', 'macfit', 'gym'],
    'health': [' saglik '],
    'personal.hairdresser': ['kuafor', 'berber'],
    'personal.cosmetics': ['gratis', 'watsons', 'rossmann'],
    'shopping.clothing': [
      'lc waikiki',
      ' lcw ',
      'defacto',
      ' koton ',
      ' zara ',
      'boyner',
      'decathlon',
      ' flo ',
    ],
    'shopping.electronics': ['teknosa', 'mediamarkt', 'vatan bilgisayar'],
    'shopping.homegoods': [
      ' ikea ',
      'bellona',
      'istikbal',
      'koctas',
      'english home',
    ],
    'shopping': [
      'trendyol',
      'hepsiburada',
      ' n11 ',
      'amazon',
      'ciceksepeti',
      'pazarama',
      // Marka değil, bankaların yazdığı JENERİK karşılıklar. Ekstrelerin
      // çoğu üye işyeri adı yerine bunu basıyor; sözlük yalnız markadan
      // ibaret kalınca bu satırlar kategorisiz düşüyordu.
      'kirtasiye',
      'outlet',
      'ucuzluk',
    ],
    // Gider tarafındaki `Yatırım`, ekstredeki hisse/fon/altın ALIMIDIR:
    // cüzdandan çıkan paradır. (Uygulama içinden yapılan yatırım hareketleri
    // sistem etiketi taşır, buraya düşmez.)
    'investment': [
      'midas',
      'menkul deger',
      'yatirim',
      'borsa istanbul',
      'hisse senedi',
    ],
    // Bankanın kendi kestiği ücret ve vergiler. Gerçek bir QNB ekstresinde
    // 164 satırın 16'sı buydu ("3.3.1 EFT Ücreti" + ardındaki "BSMV
    // Tahsilatı" çiftleri) ve hepsi kategorisiz düşüp tek tek soruluyordu.
    'fees': [
      'eft ucreti',
      'havale ucreti',
      'fast ucreti',
      'bsmv',
      'kkdf',
      'kesinti ve ekleri',
      'hesap isletim',
      'kart aidati',
      'kart ucreti',
      'komisyon',
      'masraf',
    ],
  };

  static const Map<String, List<String>> _incomeGroups = {
    'salary': ['maas', 'salary', 'bordro'],
    'sideIncome.bonus': ['prim odemesi', 'ikramiye'],
    'sideIncome': ['ek gelir'],
    'rentalIncome': ['kira geliri', ' kira '],
    'investmentIncome': ['temettu', 'kar payi', 'faiz', 'yatirim'],
    // İade ve iptal ekstrede GELİR satırıdır (kart harcamasının geri
    // dönüşü). Gerçek ekstrelerde "İADE", "... Pos satış. İptali".
    'otherIncome': ['iade', 'iptali'],
  };

  /// Sözlüğün hedefleri. Başlangıç paketiyle olan sözleşme bunlar üzerinden
  /// test edilir: hem alt kategori adının hem üstündeki ana kategorinin
  /// pakette gerçekten var olması gerekir.
  static Iterable<CategoryTarget> get expenseTargets =>
      _expenseGroups.keys.map(parseCategoryTarget);
  static Iterable<CategoryTarget> get incomeTargets =>
      _incomeGroups.keys.map(parseCategoryTarget);

  /// Sözlüğün ham hâli — yalnız sözleşme testleri için (aynı anahtar kelimenin
  /// iki hedefte birden yazılmadığını doğrular). Eşleşme her zaman
  /// [guess] üzerinden yapılır.
  @visibleForTesting
  static Map<String, List<String>> get expenseKeywords => _expenseGroups;
  @visibleForTesting
  static Map<String, List<String>> get incomeKeywords => _incomeGroups;

  /// Pakette karşılığı olmayan bir hedef için son çare ikon.
  static const Map<String, String> _groupIcons = {
    'groceries': 'shopping_cart',
    'dining': 'restaurant',
    'transport': 'directions_bus',
    'bills': 'receipt_long',
    'housing': 'home',
    'shopping': 'shopping_bag',
    'health': 'medical_services',
    'education': 'school',
    'entertainment': 'movie',
    'personal': 'face',
    'investment': 'trending_up',
    'fees': 'request_quote',
    'salary': 'payments',
    'sideIncome': 'savings',
    'rentalIncome': 'apartment',
  };

  /// [description] içinde bilinen bir anahtar kelime bulunursa VE hedef
  /// [candidates] (kullanıcının o türdeki kategorileri) içinde çözülebiliyorsa
  /// o kategorinin gerçek `id`'sini döner; aksi halde `null`.
  String? guess({
    required String description,
    required bool isIncome,
    required List<CategoryEntity> candidates,
  }) {
    final matched = _matchGroup(description, isIncome);
    if (matched == null) return null;
    return resolveTarget(parseCategoryTarget(matched), candidates)?.id;
  }

  /// Bankanın KENDİ etiketinden ([ImportDraft.sourceTag]) tahmin: etiket
  /// metni AYNI sözlükten geçer ("Fatura" → fatura, "Maaş" → maaş,
  /// "Market"/"Akaryakıt" gibi üye işyeri sınıfı veren bankalarda da doğru
  /// hedef).
  ///
  /// **Açıklamadan SONRA denenir, önce değil.** Eskiden etiket sözlükten
  /// güçlü sayılıyordu; gerçek Garanti ekstresinde ölçüldü ki banka BÜTÜN
  /// kart harcamalarına "Alışveriş" yazıyor — BİM, A101, eczane ve telefon
  /// faturası dahil. Etiket sözlüğün önünde durunca 85 satırın 50'si
  /// "Alışveriş"e düşüyor, açıklamanın doğru bildiği Market/İlaç/Fatura
  /// eziliyordu. "Alışveriş", "Para Çekme", "Para Transferi" bir harcama
  /// TÜRÜ değil KANAL bildirir; sözlükte karşılıkları olmadığı için artık
  /// hiçbir kategoriye çevrilmez (satır kategorisiz kalıp kullanıcıya
  /// sorulur — yanlış güven vermekten iyidir).
  String? guessFromSourceTag({
    required String? sourceTag,
    required bool isIncome,
    required List<CategoryEntity> candidates,
  }) {
    if (sourceTag == null || sourceTag.trim().isEmpty) return null;
    return guess(
      description: sourceTag,
      isIncome: isIncome,
      candidates: candidates,
    );
  }

  /// Hedefi kullanıcının GERÇEK kategori listesine bağlar.
  ///
  /// Sıra bilinçli — daha özelden daha genele:
  /// 1. Doğru yerdeki alt kategori (`bills.electricity`),
  /// 2. adı tutan herhangi bir kategori (kullanıcı "Elektrik"i kökte tutuyor
  ///    ya da başka bir ana kategorinin altına taşımış olabilir),
  /// 3. hedefin ANA kategorisi (alt kategoriyi hiç kurmamış/silmiş kullanıcı
  ///    eskisi gibi kök eşleşmesi alır — davranış geriye dönük bozulmaz),
  /// 4. hiçbiri yoksa `null`.
  ///
  /// Eşleşme anahtarın TÜM dillerdeki adlarına bakar ([_namesOf]): kategori
  /// adı kurulduğu dilde donmuş kullanıcı verisidir, kullanıcı sonradan dil
  /// değiştirmiş olabilir. Yalnız seçili dile bakılsaydı Türkçe kurulumdan
  /// İngilizceye geçen kullanıcıda hiçbir hedef çözülmezdi.
  CategoryEntity? resolveTarget(
    CategoryTarget target,
    List<CategoryEntity> candidates,
  ) {
    final byId = {for (final c in candidates) c.id: c};
    final leaf = _namesOf(target.key);
    final parentKey = target.parentKey;
    final parent = parentKey == null ? null : _namesOf(parentKey);

    if (parent != null) {
      for (final c in candidates) {
        if (!leaf.contains(normalized(c.name))) continue;
        final p = c.parentId == null ? null : byId[c.parentId];
        if (p != null && parent.contains(normalized(p.name))) return c;
      }
    }

    final byName = _firstNamed(leaf, candidates);
    if (byName != null) return byName;
    if (parent == null) return null;
    return _firstNamed(parent, candidates);
  }

  /// Anahtarın tüm dillerdeki adları, eşleşme için sadeleştirilmiş hâlde.
  /// Önbellekli: ekstredeki her satır için çağrılıyor.
  static Set<String> _namesOf(String key) => _normalizedNames[key] ??= {
        for (final name in categorySeedNameCandidates(key)) normalized(name),
      };

  static final Map<String, Set<String>> _normalizedNames = {};

  /// Adı tutan ilk kategori; eşitlikte ANA kategori tercih edilir (aynı ad iki
  /// seviyede birden bulunabilir, kökteki daha genel/olası hedeftir).
  static CategoryEntity? _firstNamed(
    Set<String> normalizedNames,
    List<CategoryEntity> candidates,
  ) {
    CategoryEntity? fallback;
    for (final c in candidates) {
      if (!normalizedNames.contains(normalized(c.name))) continue;
      if (c.isRoot) return c;
      fallback ??= c;
    }
    return fallback;
  }

  /// Kullanıcının GEÇMİŞ işlemlerinden bir açıklama-token → kategori indeksi
  /// kurar (tür bazında). Bir kez kurulur, tüm taslaklar için tekrar kullanılır
  /// ([guessFromHistory]). Sabit anahtar-kelime sözlüğünün aksine kullanıcının
  /// kendi kategorize etme alışkanlığından öğrenir ve kendini iyileştirir.
  ///
  /// Geçmiş `tag` alanı doğrudan kategori id'sidir; alt kategoriye yazılmış bir
  /// geçmiş, alt kategoriyi öğretir — hiyerarşi burada bedavaya çalışır.
  ///
  /// [statementTexts] içe aktarılan ekstrenin kendi açıklamalarıdır: bir
  /// token o ekstrenin satırlarının büyük kısmında geçiyorsa (bankanın kalıbı)
  /// kategori kanıtı sayılmaz — bkz. [guessFromHistory].
  HistoryCategoryIndex buildHistoryIndex(
    List<TransactionEntity> history, {
    Iterable<String> statementTexts = const [],
  }) {
    final expense = <String, Map<String, int>>{};
    final income = <String, Map<String, int>>{};
    for (final tx in history) {
      final tag = tx.tag.trim();
      if (tag.isEmpty || tx.isSystem) continue;
      final map = tx.isIncome ? income : expense;
      for (final tok in _historyTokens(tx.title)) {
        (map[tok] ??= <String, int>{})
            .update(tag, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    final statementDf = <String, int>{};
    var statementRows = 0;
    for (final text in statementTexts) {
      statementRows++;
      for (final tok in _historyTokens(text)) {
        statementDf.update(tok, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return HistoryCategoryIndex._(expense, income, statementDf, statementRows);
  }

  /// Açıklamayı kullanıcının geçmişinden öğrenilen [index] ile eşleştirir;
  /// eşleşme yoksa ya da kanıt tutarsızsa `null` (çağıran sözlüğe düşer).
  /// [guess]'ten ÖNCE denenir: "bu üye işyerini geçen sefer X yapmıştım"
  /// bilgisi sabit sözlüğü döver.
  ///
  /// **Neden kapılar var — ölçüldü (11 Eyl 2026).** Eski sürüm açıklamayla
  /// PAYLAŞILAN HER token'ı oy sayıyordu. Gerçek ekstrelerde her satırda
  /// bankanın kalıbı geçer ("POS Kart İşlemleri … ISTANBUL TR Pos satış.",
  /// "SATIŞ-517040*4626-…"), yani ilk ekstre doğru kategorize edilse bile
  /// ikinci ekstrede `kart`/`islemleri`/`satis`/`istanbul` her satırı
  /// geçmişin EN SIK kategorisine çekiyordu (İGDAŞ → Market, Enerjisa →
  /// Telefon, BİM → Alışveriş…) — ve geçmiş sözlükten önce denendiği için
  /// sözlüğün doğru bildiğini eziyordu. Ekstrenin ilk yarısı kullanıcının
  /// kategorize ettiği geçmiş, ikinci yarısı yeni içe aktarım olarak
  /// ölçüldüğünde (doğru/YANLIŞ/boş): QNB 44/38/0 → 69/1/12, Garanti
  /// 17/25/1 → 38/0/5. "Boş" satırlar kullanıcıya sorulur; yanlış kategori
  /// ise sessizce rapora gider.
  ///
  /// Kapılar:
  /// 1. **Kalıp kelimeler** ([_boilerplate]) hiç token sayılmaz.
  /// 2. **Ekstrenin çoğunda geçen token** kanıt değildir (bilinmeyen bir
  ///    bankanın kalıbı; ekstrenin kendi satırlarından ölçülür).
  /// 3. **Tutarsız token** kanıt değildir: geçmişte birden çok kategoriye
  ///    dağılmış bir kelime (semt adı, jenerik kelime) en az [_minPurity]
  ///    oranında TEK kategoriye gitmiyorsa sayılmaz.
  /// 4. **Konum**: Türkçe ekstrede üye işyeri adı açıklamanın BAŞINDA durur,
  ///    semt/şehir arkasından gelir. İlk anlamlı token daha ağır basar —
  ///    "BIM V365 ACIBADEM" satırı, geçmişte sık görülen "SHELL ACIBADEM"
  ///    yüzünden Yakıt'a gitmesin.
  String? guessFromHistory({
    required String description,
    required bool isIncome,
    required HistoryCategoryIndex index,
    required List<CategoryEntity> candidates,
  }) {
    final tokens = [
      for (final t in _historyTokens(description))
        if (!index._isStatementBoilerplate(t)) t,
    ];
    if (tokens.isEmpty) return null;
    final candidateIds = {for (final c in candidates) c.id};
    final map = isIncome ? index._income : index._expense;

    final scores = <String, double>{};
    for (var position = 0; position < tokens.length; position++) {
      final tagCounts = map[tokens[position]];
      if (tagCounts == null) continue;
      var total = 0;
      String? best;
      var bestCount = 0;
      tagCounts.forEach((tag, count) {
        total += count;
        if (count > bestCount && candidateIds.contains(tag)) {
          bestCount = count;
          best = tag;
        }
      });
      final winner = best;
      if (winner == null) continue;
      final purity = bestCount / total;
      if (purity < _minPurity) continue;
      // Sıklık BİLEREK ağırlığa girmiyor: geçmişte 10 kez görülen bir semt
      // adı ("ACIBADEM", hep aynı istasyondan yakıt alınıyorsa) bir kez
      // görülmüş üye işyeri adını ikinci sıradan yenmemeli. Tutarlılığın
      // KARESİ: karışık bir kelime (QNB'de "telekom" hem Telefon hem İnternet
      // faturasında, %60) başta dursa da tek anlamlı "ttnet"i yenmesin.
      final weight = purity *
          purity *
          (position < _positionWeights.length
              ? _positionWeights[position]
              : 1.0);
      scores.update(winner, (v) => v + weight, ifAbsent: () => weight);
    }
    if (scores.isEmpty) return null;

    String? best;
    var bestScore = 0.0;
    scores.forEach((tag, score) {
      if (score > bestScore) {
        bestScore = score;
        best = tag;
      }
    });
    return best;
  }

  /// Bir token'ın kategori kanıtı sayılması için geçmişte tek kategoriye
  /// gitme oranı. Çoğunluk yeter (2'ye 1 "akaryakıt → Ulaşım" kanıttır),
  /// dağınık kelimeler (semt adları) elenir.
  static const double _minPurity = 0.6;

  /// İlk, ikinci ve sonraki anlamlı token'ın ağırlığı (bkz. kapı 4).
  static const List<double> _positionWeights = [3.0, 1.5];

  /// [drafts] içinde eşleşen ama kullanıcının GERÇEK kategori listesinde
  /// HİÇBİR karşılığı olmayan hedefleri döner (tekilleştirilmiş). İçe aktarım
  /// incelemesinden ÖNCE kullanıcıya "bu kategorileri oluşturayım mı?" diye
  /// sormak için kullanılır.
  ///
  /// Ölçüt "adı birebir yok" değil, [resolveTarget]'ın HİÇ çözememesidir: alt
  /// kategorisi olmayan ama ana kategorisi duran bir hedef zaten köke düşerek
  /// çalışıyor, kullanıcıyı gereksiz onaya boğmanın anlamı yok.
  ///
  /// Bankanın kendi etiketi ([ImportDraft.sourceTag]) de hesaba katılır:
  /// açıklamada anahtar kelime geçmese bile etiketten gelen hedef
  /// çözülemiyorsa o kategori önerilir — aksi halde `guessFromSourceTag`
  /// kurulabilecek bir kategori yok diye sessizce boş dönüyordu.
  /// [languageCode] önerilen adların hangi dilde KURULACAĞINI belirler;
  /// eşleşme tarafı dilden bağımsızdır (bkz. [resolveTarget]).
  List<CategorySuggestion> suggestNewCategories({
    required List<ImportDraft> drafts,
    required List<CategoryEntity> expenseCategories,
    required List<CategoryEntity> incomeCategories,
    required String languageCode,
  }) {
    final wanted = <String, ({CategoryTarget target, bool isIncome})>{};
    void want(String? path, bool isIncome) {
      if (path == null) return;
      wanted['$isIncome|$path'] =
          (target: parseCategoryTarget(path), isIncome: isIncome);
    }

    for (final d in drafts) {
      want(_matchGroup(d.description, d.isIncome), d.isIncome);
      final tag = d.sourceTag;
      if (tag != null) want(_matchGroup(tag, d.isIncome), d.isIncome);
    }

    final result = <CategorySuggestion>[];
    for (final entry in wanted.values) {
      final existing = entry.isIncome ? incomeCategories : expenseCategories;
      if (resolveTarget(entry.target, existing) != null) continue;

      final isExpense = !entry.isIncome;
      final key = entry.target.key;
      // Anahtar YOLU hiyerarşiyi kendi taşır: `housing.rent` kökte ikinci bir
      // "Kira" olarak değil, üst kategorisiyle birlikte önerilir. (Ada dayalı
      // eski sürümde bu bağ ayrı bir tabloda aranmak zorundaydı.)
      final parentKey = entry.target.parentKey;
      result.add(CategorySuggestion(
        name: categorySeedName(key, languageCode),
        parentName: parentKey == null
            ? null
            : categorySeedName(parentKey, languageCode),
        parentIconName:
            parentKey == null ? null : _iconFor(parentKey, isExpense),
        isIncome: entry.isIncome,
        iconName: _iconFor(key, isExpense),
      ));
    }
    return result;
  }

  /// Anahtarın ikonu: önce başlangıç paketi, sonra son çare grup ikonu.
  static String _iconFor(String key, bool isExpense) =>
      CategoryStarterPack.iconNameOf(key, isExpense: isExpense) ??
      _groupIcons[key] ??
      'category';

  /// Hiçbir üye işyerini ayırt etmeyen, bankaların KALIBINDA geçen kelimeler:
  /// kanal ("pos", "satis", "kart"), işlem türü ("islemleri", "tahsilati"),
  /// şirket eki ("ltd", "sti"), web artığı ("com", "trtr") ve büyük şehirler.
  /// Geçmiş eşleşmesinde hiç token sayılmazlar (bkz. [guessFromHistory]).
  ///
  /// Liste bilinen bankaların kalıbından derlendi; bilinmeyen bir bankanın
  /// kalıbını ikinci kapı (ekstrenin çoğunda geçen token) yakalar.
  ///
  /// "atm" ve "iade" BİLEREK yok: kullanıcı ATM çekimini ya da iadeyi hep aynı
  /// kategoriye koyuyorsa bunu öğrenmek istenen davranıştır.
  static const Set<String> _boilerplate = {
    // kanal / işlem türü
    'pos', 'webpos', 'sanal', 'satis', 'harcama', 'harcamasi', 'odeme',
    'odemesi', 'odemeleri', 'tahsilat', 'tahsilati', 'islem', 'islemi',
    'islemleri', 'transfer', 'havale', 'eft', 'fast', 'swift', 'virman',
    'para', 'kart', 'karti', 'kartlari', 'kredi', 'banka', 'bankasi', 'bank',
    'bankacilik', 'mobil', 'internet', 'online', 'sube', 'subesi', 'cep',
    'alici', 'gonderen', 'sorgu', 'referans', 'dekont', 'nolu', 'biten',
    'hesap', 'hesaba', 'hesaptan', 'katilim', 'merkez', 'ile',
    // şirket ekleri
    'ltd', 'sti', 'sirketi', 'anonim', 'san', 'sanayi', 'tic', 'ticaret',
    'paz', 'pazarlama', 'ins', 'insaat',
    // web artığı
    'www', 'com', 'net', 'org', 'trtr',
    // ülke / büyük şehir
    'turk', 'turkiye', 'istanbul', 'ankara', 'izmir', 'bursa', 'antalya',
    'adana', 'konya', 'kocaeli', 'gaziantep', 'mersin', 'kayseri',
    'eskisehir', 'samsun', 'trabzon', 'diyarbakir', 'sakarya', 'denizli',
  };

  /// Açıklamayı geçmiş eşleşmesi için anlamlı token'lara böler, SIRAYI
  /// koruyarak (konum ağırlığı için). Elenenler: kısa (<3), tamamen sayısal,
  /// 4+ rakam taşıyan kod ("01582crs222"; marka olan "a101" kalır — eşik
  /// `label_grouper.dart` ile aynı), kalıp kelimeler ve tekrarlar.
  static List<String> _historyTokens(String s) {
    final out = <String>[];
    for (final t in normalized(s).split(' ')) {
      if (t.length < 3) continue;
      if (_boilerplate.contains(t)) continue;
      if (_digit.allMatches(t).length >= 4) continue;
      if (_allDigits.hasMatch(t)) continue;
      if (out.contains(t)) continue;
      out.add(t);
    }
    return out;
  }

  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _allDigits = RegExp(r'^[0-9]+$');

  /// Metnin üye işyerini ayırt eden kelimeleri (kalıp, kod ve kısa kelimeler
  /// elenmiş, sıra korunmuş). Geçmiş eşleşmesiyle AYNI tanım — tekrar tespiti
  /// "iki metin aynı yeri mi anlatıyor" sorusunu bununla sorar, iki ayrı
  /// kelime listesi zamanla ayrışmasın diye.
  static List<String> meaningfulTokens(String s) => _historyTokens(s);

  /// [description] hangi hedefe (varsa) düşüyor; kullanıcının kategori
  /// listesinden bağımsız, saf anahtar-kelime eşleşmesi.
  ///
  /// **En UZUN anahtar kelime kazanır**, sözlükteki sıra değil: "TRENDYOL
  /// YEMEK" hem `trendyol` (Alışveriş) hem `trendyol yemek` (Paket Servis)
  /// içinde geçiyor ve doğru olan daha özel olanı. Sıraya dayanmak, alt
  /// kategori hedefleri eklendikçe sözlüğü görünmez bir sıralama sözleşmesine
  /// bağlardı. Uzunluk kelime-sınırı boşlukları hariç ölçülür (` sok ` ile
  /// `market` adil karşılaşsın).
  ///
  /// **İstisna — aynı daldaki alt hedef, kendi ana hedefini yener**, anahtar
  /// kelimesi kısa olsa bile: "İGDAŞ FATURA" satırında `igdas` (5) `fatura`
  /// (6)'dan kısa, ama `bills.gas` `bills`'in daha özel hâlidir; uzunluk
  /// kuralı satırı genel "Fatura"ya düşürüyordu (gerçek Garanti ekstresinde
  /// 6 satır "AVEA COM TR FATURA").
  String? _matchGroup(String description, bool isIncome) {
    final norm = ' ${normalized(description)} ';
    final groups = isIncome ? _incomeGroups : _expenseGroups;
    String? bestKey;
    var bestLength = 0;
    for (final entry in groups.entries) {
      for (final keyword in entry.value) {
        if (!norm.contains(keyword)) continue;
        final length = keyword.trim().length;
        if (entry.key == bestKey) {
          // Aynı hedefin daha uzun anahtarı hedefin gücünü artırır: aksi hâlde
          // `ttnet` (5) ile kalan İnternet, `turk telekom` (12) Telefon'a
          // yenilir, kendi `turk telekom internet` (21) anahtarı sayılmazdı.
          if (length > bestLength) bestLength = length;
        } else if (bestKey == null ||
            _outranks(entry.key, length, bestKey, bestLength)) {
          bestKey = entry.key;
          bestLength = length;
        }
      }
    }
    return bestKey;
  }

  /// [key] hedefi ([length] uzunluğunda bir anahtar kelimeyle), şimdiye kadarki
  /// en iyi [bestKey]'i geçiyor mu? Bkz. [_matchGroup].
  static bool _outranks(
      String key, int length, String bestKey, int bestLength) {
    if (parseCategoryTarget(key).parentKey == bestKey) return true;
    if (parseCategoryTarget(bestKey).parentKey == key) return false;
    return length > bestLength;
  }

  /// Türkçe aksanları sadeleştirip küçük harfe çevirir, noktalama/ayraçları
  /// (tire, nokta, `/`, parantez...) TEK boşluğa indirger. Gerçek ekstre
  /// açıklamaları marka adını rakam/koda tire ile bitişik verir
  /// ("SOK-10419-USKUDAR"); ayraçlar boşluğa çevrilmezse kelime-sınırlı
  /// anahtar kelimeler (` sok `) hiçbir zaman eşleşmez. (bkz. `ColumnMapper._norm`
  /// — aynı Türkçe sadeleştirme, farklı dosyada ayrı kalması bilinçli: kolon
  /// başlığı eşleşmesiyle işlem-açıklaması eşleşmesi ayrı evrilebilir.)
  static String normalized(String s) {
    final folded = s
        .replaceAll('İ', 'I')
        .replaceAll('ı', 'i')
        .replaceAll('Ş', 'S')
        .replaceAll('ş', 's')
        .replaceAll('Ğ', 'G')
        .replaceAll('ğ', 'g')
        .replaceAll('Ü', 'U')
        .replaceAll('ü', 'u')
        .replaceAll('Ö', 'O')
        .replaceAll('ö', 'o')
        .replaceAll('Ç', 'C')
        .replaceAll('ç', 'c')
        .toLowerCase();
    return folded.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}

/// Kullanıcının geçmiş işlemlerinden kurulan, tür bazında
/// token → (kategori id → sıklık) indeksi. [CategoryGuesser.buildHistoryIndex]
/// üretir, [CategoryGuesser.guessFromHistory] tüketir. Private alanlar aynı
/// kütüphanede (bu dosyada) erişilir.
class HistoryCategoryIndex {
  final Map<String, Map<String, int>> _expense;
  final Map<String, Map<String, int>> _income;

  /// İçe aktarılan ekstrede her token'ın geçtiği SATIR sayısı.
  final Map<String, int> _statementDf;
  final int _statementRows;

  const HistoryCategoryIndex._(
    this._expense,
    this._income,
    this._statementDf,
    this._statementRows,
  );

  bool get isEmpty => _expense.isEmpty && _income.isEmpty;

  /// Bir token ekstrenin satırlarının [_maxStatementShare]'inden fazlasında
  /// geçiyorsa bankanın kalıbıdır, üye işyeri değil. Çok kısa ekstrelerde
  /// (< [_minStatementRows]) oran anlamsız olduğu için bakılmaz.
  ///
  /// Eşik bilerek geniş: aynı markadan sık alışveriş eden kullanıcıda
  /// ("MIGROS" satırların üçte biri) marka adı kalıp sanılmasın.
  bool _isStatementBoilerplate(String token) {
    if (_statementRows < _minStatementRows) return false;
    return (_statementDf[token] ?? 0) / _statementRows > _maxStatementShare;
  }

  static const int _minStatementRows = 10;
  static const double _maxStatementShare = 0.4;
}
