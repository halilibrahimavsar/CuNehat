import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';

/// Sözlüğün hedeflediği kategori: alt kategori ise [parentName] doludur.
///
/// Hedef bir ÇİFT olmak zorunda, çünkü kullanıcının hiyerarşisi bizimkinden
/// sapabilir: "Elektrik" hem `Fatura` altında hem kökte durabilir, hem de hiç
/// olmayabilir. Çözüm sırası [CategoryGuesser.resolveTarget] içinde.
typedef CategoryTarget = ({String name, String? parentName});

/// Sözlük anahtarlarında ana ve alt kategoriyi ayıran işaret ("Fatura › Su").

/// `"Fatura › Elektrik"` → `(name: 'Elektrik', parentName: 'Fatura')`.
/// Ayraç yoksa kök hedef.
CategoryTarget parseCategoryTarget(String path) {
  final parts = path.split(kCategorySeparator);
  if (parts.length < 2) return (name: path.trim(), parentName: null);
  return (name: parts.last.trim(), parentName: parts.first.trim());
}

/// Yeni kategori önerisi: [drafts] içinde eşleşen ama kullanıcının GERÇEK
/// listesinde karşılığı olmayan bir grup. Yalnız kullanıcı onayıyla
/// [CategoryEntity]'ye dönüşür (bkz. `BankImportCubit.resolveCategorySuggestions`).
class CategorySuggestion extends Equatable {
  final String name;

  /// Kurulacaksa altına gireceği ana kategorinin ADI; kök olarak kurulacaksa
  /// `null`. Ana kategori kullanıcıda yoksa o da birlikte kurulur.
  final String? parentName;

  final bool isIncome;
  final String iconName;
  const CategorySuggestion({
    required this.name,
    required this.isIncome,
    required this.iconName,
    this.parentName,
  });

  @override
  List<Object?> get props => [name, parentName, isIncome, iconName];
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
  /// Anahtar: hedef kategori YOLU. Başlangıç paketinde bir alt kategori
  /// karşılığı olan gruplar `"Ana › Alt"` biçiminde yazılır — ekstre
  /// tahmininin iki seviyeli hiyerarşiyi hiç kullanmaması, kullanıcının
  /// kurduğu 31 alt kategoriyi ölü ağırlığa çeviriyordu ("elektrik faturası"
  /// `Fatura` köküne düşüyor, `Fatura › Elektrik` boş kalıyordu).
  ///
  /// Karşılığı olmayan bir hedef sessizce ana kategoriye düşer
  /// ([resolveTarget]), yani alt kategorisini silen kullanıcı eskisi gibi kök
  /// eşleşmesi almaya devam eder.
  ///
  /// Adlar başlangıç paketiyle SÖZLEŞMEDİR: buradaki bir ad pakette karşılık
  /// bulmazsa dokunulmamış bir kurulumda o grubun tahmini hiçbir zaman tutmaz.
  /// Bağ test edilir (`category_starter_pack_test.dart`).
  static const Map<String, List<String>> _expenseGroups = {
    'Yemek › Restoran': [
      'restoran',
      'restaurant',
      'lokanta',
      'sushi',
      'pizza',
      'baklava',
      'kebap',
      'doner',
    ],
    'Yemek › Kafe': [
      'starbucks',
      'cafe',
      'kafe',
      'kahve dunyasi',
      'simit saray',
      'gloria jean',
    ],
    'Yemek › Paket Servis': [
      'yemeksepeti',
      'trendyol yemek',
      'getir yemek',
      'tikla gelsin',
    ],
    'Yemek': [
      'burger king',
      'mcdonalds',
      'mcdonald',
      ' kfc ',
      'domino',
      'popeyes',
    ],
    'Ulaşım › Yakıt': [
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
    'Ulaşım › Taksi': [
      'taksi',
      'uber',
      'bitaksi',
      ' bolt ',
      ' marti ',
    ],
    'Ulaşım › Toplu Taşıma': [
      ' iett ',
      'istanbulkart',
      'marmaray',
      'metrobus',
      'ego kart',
    ],
    'Ulaşım › Otopark': ['otopark'],
    'Ulaşım': ['otoyol', ' hgs ', ' ogs ', 'kgm gecis'],
    // Market (gıda/temel ihtiyaç) ile Alışveriş (giyim/elektronik/genel)
    // bilerek AYRI: ikisi tek kovada toplanınca aylık gıda harcaması
    // görünmez oluyor ve o kaleme bütçe koymak imkânsızlaşıyordu.
    'Market': [
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
    'Konut › Kira': ['kira odeme', ' kira ', 'kiraci'],
    'Konut › Aidat': ['aidat', 'site yonetim', 'apartman yonetim'],
    'Eğitim › Okul & Kurs': [
      'universite',
      'okul taksit',
      ' dershane ',
      ' kurs ',
    ],
    'Eğitim › Kitap': ['yayinlari', 'kitabevi', 'kitapyurdu'],
    'Eğitim': ['egitim'],
    'Fatura › Elektrik': ['elektrik', 'enerjisa', 'bedas', 'ayedas'],
    'Fatura › Su': [' iski ', ' aski ', ' asat ', ' izsu ', 'su faturasi'],
    'Fatura › Doğalgaz': ['dogalgaz', 'igdas', 'izgaz', 'baskentgaz'],
    'Fatura › İnternet': [
      'superonline',
      'turknet',
      'tellcom',
      ' ttnet ',
      'internet faturasi',
    ],
    'Fatura › Telefon': ['turk telekom', 'turkcell', 'vodafone'],
    'Fatura': ['fatura'],
    'Eğlence › Abonelikler': [
      'netflix',
      'spotify',
      'youtube',
      'amazon prime',
      ' blutv ',
      ' exxen ',
      'abonelik',
    ],
    'Eğlence › Oyun': ['playstation', 'steam', 'epic games', ' riot '],
    'Eğlence › Sinema & Konser': [
      'sinema',
      'cinemaximum',
      'biletix',
      'bilet',
      'konser',
    ],
    'Sağlık › İlaç': ['eczane'],
    'Sağlık › Doktor': ['hastane', 'klinik', 'poliklinik', 'laboratuvar'],
    'Sağlık › Spor': ['spor salonu', 'fitness', 'macfit', 'gym'],
    'Sağlık': [' saglik '],
    'Kişisel › Kuaför': ['kuafor', 'berber'],
    'Kişisel › Kozmetik': ['gratis', 'watsons', 'rossmann'],
    'Alışveriş › Giyim': [
      'lc waikiki',
      'defacto',
      ' koton ',
      ' zara ',
      'boyner',
      'decathlon',
    ],
    'Alışveriş › Elektronik': ['teknosa', 'mediamarkt', 'vatan bilgisayar'],
    'Alışveriş › Ev Eşyası': [' ikea ', 'bellona', 'istikbal'],
    'Alışveriş': [
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
    'Yatırım': [
      'midas',
      'menkul deger',
      'yatirim',
      'borsa istanbul',
      'hisse senedi',
    ],
  };

  static const Map<String, List<String>> _incomeGroups = {
    'Maaş': ['maas', 'salary', 'bordro'],
    'Ek Gelir › Prim & İkramiye': ['prim odemesi', 'ikramiye'],
    'Ek Gelir': ['ek gelir'],
    'Kira Geliri': ['kira geliri'],
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
    'Market': 'shopping_cart',
    'Yemek': 'restaurant',
    'Ulaşım': 'directions_bus',
    'Fatura': 'receipt_long',
    'Konut': 'home',
    'Alışveriş': 'shopping_bag',
    'Sağlık': 'medical_services',
    'Eğitim': 'school',
    'Eğlence': 'movie',
    'Kişisel': 'face',
    'Yatırım': 'trending_up',
    'Maaş': 'payments',
    'Ek Gelir': 'savings',
    'Kira Geliri': 'apartment',
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
  static const Map<String, String> _tagGroups = {
    'Alışveriş': 'Alışveriş',
    'Fatura': 'Fatura',
    'Fatura Ödemesi': 'Fatura',
    'Yatırım': 'Yatırım',
    'Maaş': 'Maaş',
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
  /// 1. Doğru yerdeki alt kategori (`Fatura › Elektrik`),
  /// 2. adı tutan herhangi bir kategori (kullanıcı "Elektrik"i kökte tutuyor
  ///    ya da başka bir ana kategorinin altına taşımış olabilir),
  /// 3. hedefin ANA kategorisi (alt kategoriyi hiç kurmamış/silmiş kullanıcı
  ///    eskisi gibi kök eşleşmesi alır — davranış geriye dönük bozulmaz),
  /// 4. hiçbiri yoksa `null`.
  CategoryEntity? resolveTarget(
    CategoryTarget target,
    List<CategoryEntity> candidates,
  ) {
    final byId = {for (final c in candidates) c.id: c};
    final leaf = normalized(target.name);
    final parent =
        target.parentName == null ? null : normalized(target.parentName!);

    if (parent != null) {
      for (final c in candidates) {
        if (normalized(c.name) != leaf) continue;
        final p = c.parentId == null ? null : byId[c.parentId];
        if (p != null && normalized(p.name) == parent) return c;
      }
    }

    final byName = _firstNamed(leaf, candidates);
    if (byName != null) return byName;
    if (parent == null) return null;
    return _firstNamed(parent, candidates);
  }

  /// Adı tutan ilk kategori; eşitlikte ANA kategori tercih edilir (aynı ad iki
  /// seviyede birden bulunabilir, kökteki daha genel/olası hedeftir).
  static CategoryEntity? _firstNamed(
    String normalizedName,
    List<CategoryEntity> candidates,
  ) {
    CategoryEntity? fallback;
    for (final c in candidates) {
      if (normalized(c.name) != normalizedName) continue;
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
  List<CategorySuggestion> suggestNewCategories({
    required List<ImportDraft> drafts,
    required List<CategoryEntity> expenseCategories,
    required List<CategoryEntity> incomeCategories,
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

      final name = entry.target.name;
      // Başlangıç paketinde alt kategori olarak geçen bir ad ("Kira") kökte
      // ikinci kez kurulmamalı; üst kategorisiyle birlikte önerilir. Sözlük
      // hedefi zaten yol taşıyorsa o kullanılır.
      final parentName = entry.target.parentName ??
          CategoryStarterPack.parentNameOf(name, isExpense: !entry.isIncome);
      result.add(CategorySuggestion(
        name: name,
        parentName: parentName,
        isIncome: entry.isIncome,
        iconName:
            CategoryStarterPack.iconNameOf(name, isExpense: !entry.isIncome) ??
                _groupIcons[name] ??
                'category',
      ));
    }
    return result;
  }

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
