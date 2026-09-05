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
    'transport': ['otoyol', ' hgs ', ' ogs ', 'kgm gecis'],
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
    ],
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
    ],
    'bills.phone': ['turk telekom', 'turkcell', 'vodafone'],
    'bills': ['fatura'],
    'entertainment.subscriptions': [
      'netflix',
      'spotify',
      'youtube',
      'amazon prime',
      ' blutv ',
      ' exxen ',
      'abonelik',
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
    'health.doctor': ['hastane', 'klinik', 'poliklinik', 'laboratuvar'],
    'health.fitness': ['spor salonu', 'fitness', 'macfit', 'gym'],
    'health': [' saglik '],
    'personal.hairdresser': ['kuafor', 'berber'],
    'personal.cosmetics': ['gratis', 'watsons', 'rossmann'],
    'shopping.clothing': [
      'lc waikiki',
      'defacto',
      ' koton ',
      ' zara ',
      'boyner',
      'decathlon',
    ],
    'shopping.electronics': ['teknosa', 'mediamarkt', 'vatan bilgisayar'],
    'shopping.homegoods': [' ikea ', 'bellona', 'istikbal'],
    'shopping': [
      'trendyol',
      'hepsiburada',
      ' n11 ',
      'amazon',
      // Marka değil, bankaların yazdığı JENERİK karşılıklar. Ekstrelerin
      // çoğu üye işyeri adı yerine bunu basıyor; sözlük yalnız markadan
      // ibaret kalınca bu satırlar kategorisiz düşüyordu.
      'kirtasiye',
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
  };

  static const Map<String, List<String>> _incomeGroups = {
    'salary': ['maas', 'salary', 'bordro'],
    'sideIncome.bonus': ['prim odemesi', 'ikramiye'],
    'sideIncome': ['ek gelir'],
    'rentalIncome': ['kira geliri'],
  };

  /// Sözlüğün hedefleri. Başlangıç paketiyle olan sözleşme bunlar üzerinden
  /// test edilir: hem alt kategori adının hem üstündeki ana kategorinin
  /// pakette gerçekten var olması gerekir.
  static Iterable<CategoryTarget> get expenseTargets =>
      _expenseGroups.keys.map(parseCategoryTarget);
  static Iterable<CategoryTarget> get incomeTargets =>
      _incomeGroups.keys.map(parseCategoryTarget);
  static Iterable<String> get tagGroupTargets => _tagGroups.values;

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

  /// Bankanın KENDİ etiketi ([ImportDraft.sourceTag]) → uygulamadaki hedef.
  /// Yalnız anlamlı olanlar eşlenir: "Para Çekme"/"Para Transferi"/"Komisyon"
  /// gibi etiketler bir harcama TÜRÜ değil bir kanal bildirir, kategoriye
  /// çevrilmeleri yanlış güven verirdi — bilerek listede yok (o satırlar
  /// kategorisiz kalıp inceleme ekranında kullanıcıya sorulur).
  /// Anahtar bankanın Türkçe etiketi (ekstreden gelir, çevrilmez); değer
  /// bizim hedef anahtarımız.
  static const Map<String, String> _tagGroups = {
    'Alışveriş': 'shopping',
    'Fatura': 'bills',
    'Fatura Ödemesi': 'bills',
    'Yatırım': 'investment',
    'Maaş': 'salary',
  };

  /// Ekstrenin kendi kategori etiketinden tahmin. Sabit anahtar-kelime
  /// sözlüğünden GÜÇLÜDÜR (bankanın işlemi sınıflandırması, metinden çıkarılan
  /// tahmin değil) ama kullanıcının kendi geçmişinden zayıftır. Etiket
  /// eşlenemiyorsa ya da karşılık gelen kategori kullanıcının listesinde yoksa
  /// `null` — çağıran bir sonraki tahmin yoluna düşer.
  String? guessFromSourceTag({
    required String? sourceTag,
    required List<CategoryEntity> candidates,
  }) {
    final target = _tagTarget(sourceTag);
    if (target == null) return null;
    return resolveTarget(target, candidates)?.id;
  }

  static CategoryTarget? _tagTarget(String? sourceTag) {
    if (sourceTag == null) return null;
    final group = _tagGroups[sourceTag];
    return group == null ? null : parseCategoryTarget(group);
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
  HistoryCategoryIndex buildHistoryIndex(List<TransactionEntity> history) {
    final expense = <String, Map<String, int>>{};
    final income = <String, Map<String, int>>{};
    for (final tx in history) {
      final tag = tx.tag.trim();
      if (tag.isEmpty || tx.isSystem) continue;
      final map = tx.isIncome ? income : expense;
      for (final tok in _tokens(tx.title)) {
        (map[tok] ??= <String, int>{})
            .update(tag, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return HistoryCategoryIndex._(expense, income);
  }

  /// Açıklamayı kullanıcının geçmişinden öğrenilen [index] ile eşleştirir:
  /// paylaşılan anlamlı token'lar üzerinden en çok kullanılan (ve hâlâ
  /// [candidates] içinde bulunan) kategori `id`'sini döner; yoksa `null`.
  /// [guess]'ten ÖNCE denenir; böylece "bu markayı geçen sefer X yapmıştım"
  /// bilgisi sabit sözlüğü döver. Eşleşme yoksa çağıran sabit sözlüğe düşer.
  String? guessFromHistory({
    required String description,
    required bool isIncome,
    required HistoryCategoryIndex index,
    required List<CategoryEntity> candidates,
  }) {
    final tokens = _tokens(description);
    if (tokens.isEmpty) return null;
    final candidateIds = candidates.map((c) => c.id).toSet();
    final map = isIncome ? index._income : index._expense;

    final scores = <String, int>{};
    for (final tok in tokens) {
      final tagCounts = map[tok];
      if (tagCounts == null) continue;
      tagCounts.forEach((tag, count) {
        if (candidateIds.contains(tag)) {
          scores.update(tag, (v) => v + count, ifAbsent: () => count);
        }
      });
    }
    if (scores.isEmpty) return null;

    String? best;
    var bestScore = 0;
    scores.forEach((tag, score) {
      if (score > bestScore) {
        bestScore = score;
        best = tag;
      }
    });
    return best;
  }

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
      want(_tagGroups[d.sourceTag], d.isIncome);
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

  /// Geçmiş eşleşmesinde gürültü yaratan, marka-özgü OLMAYAN jenerik banka
  /// token'ları (yön belirtmez, çoğu işlemde geçer). Dışlanır ki "pos ödeme"
  /// gibi ortak kelimeler yanlış kategori taşımasın.
  static const _stopwords = <String>{
    'pos',
    'odeme',
    'para',
    'transfer',
    'islem',
    'tahsilat',
    'harcama',
  };

  /// Açıklamayı geçmiş-eşleşmesi için anlamlı token'lara böler: Türkçe
  /// sadeleştirme + boşluk; kısa (<3), tamamen sayısal (mağaza kodu) ve
  /// jenerik banka kelimeleri elenir.
  List<String> _tokens(String s) => normalized(s)
      .split(' ')
      .where((t) =>
          t.length >= 3 &&
          !_stopwords.contains(t) &&
          !RegExp(r'^[0-9]+$').hasMatch(t))
      .toList();

  /// [description] hangi hedefe (varsa) düşüyor; kullanıcının kategori
  /// listesinden bağımsız, saf anahtar-kelime eşleşmesi.
  ///
  /// **En UZUN anahtar kelime kazanır**, sözlükteki sıra değil: "TRENDYOL
  /// YEMEK" hem `trendyol` (Alışveriş) hem `trendyol yemek` (Paket Servis)
  /// içinde geçiyor ve doğru olan daha özel olanı. Sıraya dayanmak, alt
  /// kategori hedefleri eklendikçe sözlüğü görünmez bir sıralama sözleşmesine
  /// bağlardı. Uzunluk kelime-sınırı boşlukları hariç ölçülür (` sok ` ile
  /// `market` adil karşılaşsın).
  String? _matchGroup(String description, bool isIncome) {
    final norm = ' ${normalized(description)} ';
    final groups = isIncome ? _incomeGroups : _expenseGroups;
    String? bestKey;
    var bestLength = 0;
    for (final entry in groups.entries) {
      for (final keyword in entry.value) {
        final length = keyword.trim().length;
        if (length <= bestLength) continue;
        if (norm.contains(keyword)) {
          bestKey = entry.key;
          bestLength = length;
        }
      }
    }
    return bestKey;
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
  const HistoryCategoryIndex._(this._expense, this._income);

  bool get isEmpty => _expense.isEmpty && _income.isEmpty;
}
