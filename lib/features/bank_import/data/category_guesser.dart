import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

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
/// bilinen bir anahtar kelime geçiyor VE (2) tahmin edilen grup adına
/// karşılık gelen kategori kullanıcının GERÇEK listesinde var (silinmemiş/
/// yeniden adlandırılmamış). Aksi halde `null` — çağıran taraf mevcut
/// varsayılana (türün ilk kategorisi) düşer; yani bu sınıf hiçbir zaman
/// önceki davranıştan daha kötü bir sonuç üretmez. Kullanıcı yine de her
/// satırın kategorisini elle değiştirebilir (bkz. inceleme ekranı).
///
/// Grup karşılığı YOKSA [suggestNewCategories] onu kullanıcı onayına sunar;
/// onaysız hiçbir kategori yaratılmaz (bkz. kullanıcı talebi 2026-07-21).
@lazySingleton
class CategoryGuesser {
  /// Grup adları varsayılan kategori **id**'leriyle (`CategoryModel`) birebir
  /// eşleşecek şekilde seçildi ki kurulumdan hiç dokunulmamış kategori
  /// listesinde doğrudan tutsun. Eşleşme id üzerinden olduğu için kullanıcının
  /// kategoriyi yeniden adlandırması (`displayName`) tahmini bozmaz.
  ///
  /// Gider tarafındaki `Yatırım` varsayılanda YOK (yalnız gelirde var); bu grup
  /// yalnız [suggestNewCategories] üzerinden, onaylanırsa ortaya çıkar (gerçek
  /// Akbank ekstresi örneğinde "Midas Menkul Değerler" transferi hiçbir
  /// varsayılana uymadığı için eklendi).
  static const Map<String, List<String>> _expenseGroups = {
    'Yemek': [
      'starbucks',
      'burger king',
      'mcdonalds',
      'mcdonald',
      ' kfc ',
      'domino',
      'pizza',
      'sushi',
      'yemeksepeti',
      'trendyol yemek',
      'restoran',
      'restaurant',
      'lokanta',
      'cafe',
      'kafe',
      'simit saray',
      'kahve dunyasi',
      'baklava',
    ],
    'Ulaşım': [
      'shell',
      'opet',
      'petrol ofisi',
      ' petrol ',
      ' total ',
      'aytemiz',
      'akaryakit',
      'otopark',
      'otoyol',
      ' hgs ',
      ' ogs ',
      ' iett ',
      'istanbulkart',
      'marmaray',
      'metrobus',
      'taksi',
      'uber',
      'bitaksi',
      ' bolt ',
      ' marti ',
      'benzin',
      'motorin',
      ' lpg ',
    ],
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
    'Alışveriş': [
      'teknosa',
      'mediamarkt',
      'lc waikiki',
      'defacto',
      ' koton ',
      ' zara ',
      'boyner',
      'trendyol',
      'hepsiburada',
      ' n11 ',
      'amazon',
      'gratis',
      'watsons',
      'rossmann',
      ' ikea ',
      'decathlon',
    ],
    'Kira': ['kira odeme', ' kira ', 'kiraci'],
    'Eğitim': [
      'universite',
      'okul taksit',
      ' dershane ',
      ' kurs ',
      'egitim',
      'yayinlari',
    ],
    'Fatura': [
      'elektrik',
      'dogalgaz',
      ' iski ',
      ' aski ',
      'turk telekom',
      'turkcell',
      'vodafone',
      'superonline',
      'turknet',
      'tellcom',
      'fatura',
      'aidat',
    ],
    'Eğlence': [
      'netflix',
      'spotify',
      'youtube',
      'playstation',
      'steam',
      'sinema',
      'cinemaximum',
      'biletix',
      'bilet',
    ],
    'Yatırım': [
      'midas',
      'menkul deger',
      'yatirim',
      'borsa istanbul',
      'hisse senedi',
    ],
    'Sağlık': ['eczane', 'hastane', 'klinik', ' saglik '],
  };

  static const Map<String, List<String>> _incomeGroups = {
    'Maaş': ['maas', 'salary', 'bordro'],
    'Ek Gelir': ['ek gelir', 'prim odemesi', 'ikramiye'],
  };

  /// Yeni kategori oluşturulması gerektiğinde kullanılacak ikon (bkz.
  /// `AppIcons` — burada yalnız isim tutulur, widget bağımlılığı yok).
  /// Sözlüğün hedeflediği kategori adları.
  ///
  /// Dışa açıktır çünkü bunlar başlangıç paketiyle ARASINDAKİ SÖZLEŞMEDİR:
  /// buradaki bir ad pakette karşılık bulmazsa, dokunulmamış bir kurulumda o
  /// grubun tahmini hiçbir zaman tutmaz. Bağ test edilir
  /// (`category_starter_pack_test.dart`).
  static Iterable<String> get expenseGroupNames => _expenseGroups.keys;
  static Iterable<String> get incomeGroupNames => _incomeGroups.keys;
  static Iterable<String> get tagGroupTargets => _tagGroups.values;

  static const Map<String, String> _groupIcons = {
    'Market': 'shopping_cart',
    'Yemek': 'restaurant',
    'Ulaşım': 'directions_bus',
    'Fatura': 'receipt_long',
    'Kira': 'home',
    'Alışveriş': 'shopping_bag',
    'Sağlık': 'medical_services',
    'Eğitim': 'school',
    'Eğlence': 'movie',
    'Yatırım': 'trending_up',
    'Maaş': 'payments',
    'Ek Gelir': 'savings',
  };

  /// [description] içinde bilinen bir anahtar kelime bulunursa VE grup adı
  /// [candidates] (kullanıcının o türdeki kategorileri) içinde varsa o
  /// kategorinin gerçek `id`'sini döner; aksi halde `null`.
  String? guess({
    required String description,
    required bool isIncome,
    required List<CategoryEntity> candidates,
  }) {
    final matched = _matchGroup(description, isIncome);
    if (matched == null) return null;
    final normGroup = _normalizeTr(matched);
    for (final c in candidates) {
      if (_normalizeTr(c.name) == normGroup) return c.id;
    }
    return null;
  }

  /// Bankanın KENDİ etiketi ([ImportDraft.sourceTag]) → uygulamadaki grup adı.
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
    if (sourceTag == null) return null;
    final group = _tagGroups[sourceTag];
    if (group == null) return null;
    final normGroup = _normalizeTr(group);
    for (final c in candidates) {
      if (_normalizeTr(c.name) == normGroup) return c.id;
    }
    return null;
  }

  /// Kullanıcının GEÇMİŞ işlemlerinden bir açıklama-token → kategori indeksi
  /// kurar (tür bazında). Bir kez kurulur, tüm taslaklar için tekrar kullanılır
  /// ([guessFromHistory]). Sabit anahtar-kelime sözlüğünün aksine kullanıcının
  /// kendi kategorize etme alışkanlığından öğrenir ve kendini iyileştirir.
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

  /// [drafts] içinde eşleşen ama ilgili tür (gider/gelir) için kullanıcının
  /// GERÇEK kategori listesinde karşılığı olmayan grupları döner
  /// (tekilleştirilmiş). İçe aktarım incelemesinden ÖNCE kullanıcıya
  /// "bu kategorileri oluşturayım mı?" diye sormak için kullanılır.
  List<CategorySuggestion> suggestNewCategories({
    required List<ImportDraft> drafts,
    required List<CategoryEntity> expenseCategories,
    required List<CategoryEntity> incomeCategories,
  }) {
    final foundIsIncome = <String, bool>{};
    for (final d in drafts) {
      final group = _matchGroup(d.description, d.isIncome);
      if (group != null) foundIsIncome[group] = d.isIncome;
    }

    final result = <CategorySuggestion>[];
    foundIsIncome.forEach((name, isIncome) {
      final existing = isIncome ? incomeCategories : expenseCategories;
      final normName = _normalizeTr(name);
      final alreadyExists =
          existing.any((c) => _normalizeTr(c.name) == normName);
      if (!alreadyExists) {
        // Başlangıç paketinde alt kategori olarak geçen bir ad ("Kira")
        // kökte ikinci kez kurulmamalı; üst kategorisiyle birlikte önerilir.
        final parentName = CategoryStarterPack.parentNameOf(
          name,
          isExpense: !isIncome,
        );
        result.add(CategorySuggestion(
          name: name,
          parentName: parentName,
          isIncome: isIncome,
          iconName:
              CategoryStarterPack.iconNameOf(name, isExpense: !isIncome) ??
                  _groupIcons[name] ??
                  'category',
        ));
      }
    });
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
  List<String> _tokens(String s) => _normalizeTr(s)
      .split(' ')
      .where((t) =>
          t.length >= 3 &&
          !_stopwords.contains(t) &&
          !RegExp(r'^[0-9]+$').hasMatch(t))
      .toList();

  /// [description] hangi gruba (varsa) düşüyor; kullanıcının kategori
  /// listesinden bağımsız, saf anahtar-kelime eşleşmesi.
  String? _matchGroup(String description, bool isIncome) {
    final norm = ' ${_normalizeTr(description)} ';
    final groups = isIncome ? _incomeGroups : _expenseGroups;
    for (final entry in groups.entries) {
      if (entry.value.any(norm.contains)) return entry.key;
    }
    return null;
  }

  /// Türkçe aksanları sadeleştirip küçük harfe çevirir, noktalama/ayraçları
  /// (tire, nokta, `/`, parantez...) TEK boşluğa indirger. Gerçek ekstre
  /// açıklamaları marka adını rakam/koda tire ile bitişik verir
  /// ("SOK-10419-USKUDAR"); ayraçlar boşluğa çevrilmezse kelime-sınırlı
  /// anahtar kelimeler (` sok `) hiçbir zaman eşleşmez. (bkz. `ColumnMapper._norm`
  /// — aynı Türkçe sadeleştirme, farklı dosyada ayrı kalması bilinçli: kolon
  /// başlığı eşleşmesiyle işlem-açıklaması eşleşmesi ayrı evrilebilir.)
  String _normalizeTr(String s) {
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
