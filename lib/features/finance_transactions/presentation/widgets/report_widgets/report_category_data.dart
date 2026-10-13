import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:flutter/material.dart';

/// Bir kategorinin dönem içi bütçe durumu.
///
/// [progress] ÇUBUK içindir ve 0–1'e kırpılır; [ratio] ham orandır ve
/// ETİKET onu yazar. Eskiden etiket de kırpılmış değeri yazıyordu: Bütçe
/// sayfası "%112" derken rapor aynı kalem için "%100" gösteriyordu.
typedef ReportBudgetProgress = ({
  double progress,
  double ratio,
  bool isExceeded,
  double limit,
});

/// Kategori keşfinde inilen yolun bir adımı. Ad tek başına yetmez: kökün
/// doğrudan dilimi kökle, sentetik "Diğer" kovası kullanıcının gerçek bir
/// "Diğer" kategorisiyle aynı adı taşıyabilir.
typedef CategoryPathStep = ({String name, bool isOther, bool isDirect});

/// Rapor sayfasındaki tek bir kategori dilimi: ad, dönem toplamı, o kategoriye
/// düşen işlemler ve dilim rengi.
class CategoryData {
  final String name;
  final double totalAmount;
  final List<TransactionEntity> transactions;
  final Color color;

  /// Pasta eşiklemesinde toplanan küçük kategorilerin sentetik "Diğer" kovası.
  /// Kullanıcının gerçek bir "Diğer" kategorisi olabildiğinden eşleştirme
  /// isimle değil bu bayrakla yapılır.
  final bool isOther;

  /// Alt kategori kırılımı — çemberin dış halkası, çubuk satırının açılan
  /// kısmı ve detay sayfası hep bunu okur.
  ///
  /// Toplamları [totalAmount]'a EŞİTTİR: kökün doğrudan harcaması da sentetik
  /// bir çocuk olarak burada durur ([isDirect]). Bu eşitlik çemberin iki
  /// halkasının hizalanmasının ön koşuludur — dış halka iç halkayla aynı
  /// toplamı kaplamazsa açılar kayar.
  ///
  /// Çocuğu olmayan kategorilerde BOŞTUR (tek çocuklu sentetik bir sarmalayıcı
  /// üretilmez; "kırılım yok" bilgisi listenin boş olmasıyla taşınır).
  final List<CategoryData> children;

  /// Bu dilim, bir ana kategorinin KENDİ (alt kategoriye yazılmamış)
  /// harcaması mı? Yalnız [children] içinde görülür.
  final bool isDirect;

  /// Aynı uzunluktaki ÖNCEKİ dönemde bu kategorinin toplamı; hesaplanmadıysa
  /// null. Kategori bazlı değişim rozetleri bunu okur.
  final double? previousAmount;

  const CategoryData(
    this.name,
    this.totalAmount,
    this.transactions,
    this.color, {
    this.isOther = false,
    this.isDirect = false,
    this.children = const [],
    this.previousAmount,
  });

  /// Bu dilime inen yol adımı (bkz. [ReportCategoryDataBuilder.resolvePath]).
  CategoryPathStep get step =>
      (name: name, isOther: isOther, isDirect: isDirect);

  /// İçine inilebilir mi? Alt kategorisi olan kök ve küçük kalemleri
  /// toplayan "Diğer" kovası; doğrudan dilim ve yaprak İNİLMEZ, işlemleri
  /// açılır.
  bool get canDrill => children.isNotEmpty && !isDirect;

  /// Önceki döneme göre yüzde değişim; kıyas yoksa ya da önceki dönem sıfırsa
  /// null (sıfırdan artışın yüzdesi tanımsızdır).
  double? get changePercent {
    final previous = previousAmount;
    if (previous == null || previous == 0) return null;
    return ((totalAmount - previous) / previous) * 100;
  }

  CategoryData copyWith({
    Color? color,
    List<CategoryData>? children,
    double? previousAmount,
  }) =>
      CategoryData(
        name,
        totalAmount,
        transactions,
        color ?? this.color,
        isOther: isOther,
        isDirect: isDirect,
        children: children ?? this.children,
        previousAmount: previousAmount ?? this.previousAmount,
      );
}

extension CategoryDataLabel on CategoryData {
  /// Dilimin kullanıcıya gösterilecek adı.
  ///
  /// Sentetik "Diğer" kovasının [CategoryData.name]'i bir kategori id'si DEĞİL,
  /// çağıran tarafından zaten l10n'a çevrilmiş bir ETİKETTİR. tag→ad
  /// haritasından geçirilirse, kullanıcının gerçek "Diğer" kategorisi
  /// yeniden adlandırılmışsa kova onun yeni adını alır ve yan yana duran iki
  /// dilim ayırt edilemez olur. Eşleştirme her zaman [CategoryData.isOther]
  /// bayrağıyla yapılır, isimle değil.
  String labelIn(BuildContext context, Map<String, String>? labels) =>
      isOther ? name : context.categoryLabelForTag(name, labels: labels);
}

/// Bir kategori diliminin hangi listeden geldiği. Detay sayfası listeyi
/// TransactionBloc her değiştiğinde yeniden hesapladığı için, hangi kırılımın
/// içinde durduğunu bilmek zorundadır — aksi hâlde pastadan açılan "Diğer"
/// kovası tam listede karşılığını bulamaz.
enum ReportSliceMode {
  /// Tüm kategoriler, eşiksiz (çubuk grafiği).
  full,

  /// Payı eşiğin altındakiler "Diğer"de toplanmış (pasta).
  pie,
}

/// Kategori donutunun ve listesinin KATEGORİK paleti.
///
/// İki karar bilinçli:
///
/// **Tek hue ailesi değil.** Eskiden gider dilimleri kırmızı–turuncu–kehribar
/// bandından, gelir dilimleri yeşil–turkuaz bandından geliyordu. Ama dilimler
/// SIRALI değil KATEGORİK veridir: "Market" ile "Ulaşım" arasında bir büyüklük
/// ilişkisi yok, ayırt edilebilirlik var. Aynı aileden dört ton yan yana
/// gelince ayırt edilemiyorlardı. Gelir/gider kutupluluğunu kartın başlığı,
/// toplamı ve mod seçicisi zaten taşıyor — dilimlerin ayrıca kırmızı olmasına
/// gerek yok.
///
/// **Hue'lar eşit aralıklı değil.** Göz sarı-yeşil bandında yakın hue'ları
/// ayırt edemez; adımlar el ile açılıp kapatıldı ve açıklık, kartın gerçek
/// zeminine (light `#DCE9FD`, dark `#213B69`) göre orta bantta tutuldu.
abstract final class ReportCategoryPalette {
  static const List<Color> colors = [
    Color(0xFF2563EB), // mavi
    Color(0xFFDC2626), // kırmızı
    Color(0xFF059669), // zümrüt
    Color(0xFFD97706), // kehribar
    Color(0xFF7C3AED), // mor
    Color(0xFF0891B2), // camgöbeği
    Color(0xFFDB2777), // fuşya
    Color(0xFF65A30D), // limon-yeşil
    Color(0xFFEA580C), // turuncu
    Color(0xFF4F46E5), // indigo
    Color(0xFF0D9488), // deniz yeşili
    // Eskiden menekşeydi (0xFF9333EA): "mor"dan ayırt edilemiyordu — aynı
    // halkada Fatura ile Yemek yan yana iki mor dilimdi (cihazda görüldü).
    Color(0xFF92400E), // kahve
  ];

  static int get length => colors.length;

  /// Kategori id'sinden KARARLI bir tercih indeksi.
  ///
  /// `String.hashCode` kullanılmaz: Dart'ta çalışma-arası tutarlılığı garanti
  /// edilmiyor. Basit ve deterministik bir FNV-1a yeterli — amaç kriptografi
  /// değil, "aynı kategori her dönem aynı rengi alsın".
  static int preferredIndex(String categoryId) {
    var hash = 0x811c9dc5;
    for (final unit in categoryId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash % colors.length;
  }
}

/// Rapor sayfasının kategori kırılımını üreten yardımcı: seçili tarih aralığı,
/// bütçe limitleri ve renk paletini tek yerde tutar.
///
/// Detay bottom sheet'i, sayfanın State'ine kapanan dört ayrı closure yerine
/// bu nesneyi alır; böylece TransactionBloc her değiştiğinde kırılımı kendisi
/// yeniden hesaplayabilir ve State'e bağımlı kalmaz.
class ReportCategoryDataBuilder {
  static const _service = TransactionReportService();

  /// Kalıcı paletin dışına taşan kategoriler için ayrılan, kategori
  /// renkleriyle çakışmayacak sabit "Diğer" rengi.
  static const _otherColor = Colors.blueGrey;

  /// Pasta diliminde ayrı gösterilmek için gereken en düşük pay (%).
  static const _pieThresholdPercent = 3.0;

  final DateTimeRange range;

  /// Cüzdanın bütçe limitleri. `spentAmount` kullanılmaz — rapor sayfası
  /// harcamayı seçili [range]'a göre ayrıca hesaplar (BudgetRepository yalnız
  /// limitleri döner ve "bu ay" varsayımı taşımaz).
  final List<BudgetEntity> budgets;

  /// Sentetik "Diğer" kovasının yerelleştirilmiş adı. Yapıcıda alınır ki bu
  /// sınıf BuildContext'e bağımlı olmasın.
  final String otherCategoryLabel;

  /// `id → kök id` (bkz. `buildRootIndex`). Dilimler KÖK seviyede toplanır;
  /// boş verilirse her tag kendi dilimidir.
  final Map<String, String> rootIndex;

  /// Kuplaj hareketleri (transfer/borç/yatırım) kırılıma dahil mi —
  /// rapor sayfasındaki para taşıma çipinin (`ReportScopeChips`) karşılığı.
  ///
  /// **Varsayılanı YOK, bilerek:** düzeltilen hata tam olarak buydu. Kırılımı
  /// yeniden hesaplayan iki yer vardı — sayfa (`_universeOf` ile kuplajı
  /// AYIRIYORDU) ve `CategoryDetailsBottomSheet` (ayırMIYORdu). Evren
  /// ayrışınca yüzde eşiği ve ilk-N kesimi kayıyor: sayfada dilim olarak
  /// duran bir kategori alt sayfada "Diğer"e katlanıyor, `firstWhere`
  /// bulamıyor ve kullanıcı BOŞ bir liste görüyordu. Dönemde büyük bir
  /// transfer varken ("bu ay" tipik senaryo) hata her seferinde çıkıyordu;
  /// anahtarı AÇMAK iki evreni eşitlediği için "kuplajı açınca düzeliyor"
  /// gibi görünüyordu.
  final bool includeSystemMovements;

  const ReportCategoryDataBuilder({
    required this.range,
    required this.budgets,
    required this.otherCategoryLabel,
    required this.includeSystemMovements,
    this.rootIndex = const {},
  });

  List<TransactionEntity> filterByRange(List<TransactionEntity> transactions) =>
      _service.filterByRange(transactions, range.start, range.end);

  /// Analiz evreni. Dönem filtresi UYGULAMAZ: çağıran hangi pencereyi verirse
  /// ona uygulanır (önceki dönem, aylık seyir penceresi ...).
  static List<TransactionEntity> universeOf(
    List<TransactionEntity> inRange, {
    required bool includeSystemMovements,
  }) =>
      includeSystemMovements
          ? inRange
          : _service.splitSystemMovements(inRange).spending;

  /// Dönem + evren tek adımda: kırılımın gördüğü işlemler. Kırılımı kendi
  /// hesaplayan her yerin giriş kapısı burasıdır.
  List<TransactionEntity> universeIn(List<TransactionEntity> transactions) =>
      universeOf(filterByRange(transactions),
          includeSystemMovements: includeSystemMovements);

  /// [target] dilimini [items] içinde — kökler, sonra alt kırılımlar —
  /// arar; bulamazsa null.
  ///
  /// **Neden özyinelemeli:** kırılım KÖK seviyede toplanır, alt kategoriler
  /// yalnız [CategoryData.children] içinde durur. Detay sayfası dokunulan
  /// dilimi eskiden yalnız kök listesinde arıyordu; alt kategoriye (ya da
  /// alt kategoriye konmuş bütçeye) dokunan kullanıcı 0 ₺ ve "işlem yok"
  /// görüyordu. Eşleşme kimlik + [CategoryData.isOther] +
  /// [CategoryData.isDirect] ile: kökün doğrudan dilimi kökle AYNI adı taşır
  /// ama yalnız kökün kendi işlemlerini kapsar.
  static CategoryData? findSlice(
    List<CategoryData> items,
    CategoryData target,
  ) {
    for (final item in items) {
      if (item.name == target.name &&
          item.isOther == target.isOther &&
          item.isDirect == target.isDirect) {
        return item;
      }
    }
    for (final item in items) {
      final hit = findSlice(item.children, target);
      if (hit != null) return hit;
    }
    return null;
  }

  /// [path] boyunca iner ve yolun GEÇERLİ önekindeki düğümleri döner.
  ///
  /// Dönem değişince kullanıcı inmiş olduğu yerde kalır (Eylül'de Fatura'ya
  /// inmişken Ağustos'a geçmek Fatura'da kalır); yeni dönemde o düğüm yoksa
  /// yol bulunabildiği yere kadar kısalır — boş bir seviye gösterilmez.
  static List<CategoryData> resolvePath(
    List<CategoryData> top,
    List<CategoryPathStep> path,
  ) {
    final out = <CategoryData>[];
    var level = top;
    for (final step in path) {
      CategoryData? hit;
      for (final item in level) {
        if (item.step == step) {
          hit = item;
          break;
        }
      }
      if (hit == null || !hit.canDrill) break;
      out.add(hit);
      level = hit.children;
    }
    return out;
  }

  /// [node] dilimine düşen işlemleri seçen yüklem — zaman çizgisi bir
  /// kategoriye odaklanınca HEM bu dönemi HEM önceki dönemi bununla süzer.
  ///
  /// İşlem listesiyle değil kimlikle süzülür: önceki dönemin işlemleri
  /// düğümün listesinde yoktur. Kural kırılımın kendisiyle aynı
  /// ([rootIdOf]): kök kendi alt ağacını, alt kategori yalnız kendini,
  /// doğrudan dilim yalnız kökün kendi kaydını, "Diğer" katladığı kökleri
  /// kapsar.
  bool Function(TransactionEntity) focusFilter(
    CategoryData node, {
    required bool isExpense,
  }) {
    bool side(TransactionEntity t) => t.isExpense == isExpense;
    if (node.isDirect) return (t) => side(t) && t.tag == node.name;
    if (node.isOther) {
      final roots = {for (final c in node.children) c.name};
      return (t) => side(t) && roots.contains(rootIdOf(t.tag, rootIndex));
    }
    return (t) =>
        side(t) &&
        (t.tag == node.name || rootIdOf(t.tag, rootIndex) == node.name);
  }

  List<CategoryData> buildFull(
    List<TransactionEntity> transactions, {
    required bool isExpense,
  }) {
    final breakdowns = _service.buildCategoryBreakdown(
      transactions,
      isExpense: isExpense,
      rootIndex: rootIndex,
    );

    final colors = _stableColors([for (final b in breakdowns) b.name]);

    return [
      for (int i = 0; i < breakdowns.length; i++)
        CategoryData(
          breakdowns[i].name,
          breakdowns[i].totalAmount,
          breakdowns[i].transactions,
          colors[i],
          children: _childSlices(breakdowns[i], colors[i]),
        ),
    ];
  }

  /// Bir kökün alt kırılımını renkli dilimlere çevirir.
  ///
  /// **Kökün DOĞRUDAN harcaması da bir dilimdir** ([CategoryData.isDirect]):
  /// çocukların toplamı ile kökün toplamı arasındaki fark. Bu olmadan
  /// çemberin dış halkası iç halkadan kısa kalır ve iki halkanın açıları
  /// kayardı. Kuruş artıkları (< 0,5 kuruş) dilim üretmez.
  ///
  /// Çocuk renkleri ANA RENKTEN türer: aynı hue, farklı açıklık. Kırılımın
  /// hangi ana kategoriye ait olduğu böylece renkten okunur — palette'ten
  /// bağımsız renk vermek dış halkayı anlamsız bir konfetiye çevirirdi.
  List<CategoryData> _childSlices(CategoryBreakdown root, Color rootColor) {
    if (root.children.isEmpty) return const [];

    final childrenTotal =
        root.children.fold<double>(0.0, (sum, c) => sum + c.totalAmount);
    final direct = root.totalAmount - childrenTotal;

    final tints = _stableTints(
      [for (final c in root.children) c.name],
      rootColor,
    );

    return [
      for (var i = 0; i < root.children.length; i++)
        CategoryData(
          root.children[i].name,
          root.children[i].totalAmount,
          root.children[i].transactions,
          tints[i],
        ),
      if (direct > 0.005)
        CategoryData(
          root.name,
          direct,
          // Kökün doğrudan işlemleri: alt kategoriye yazılmamış olanlar.
          [
            for (final t in root.transactions)
              if (t.tag == root.name) t,
          ],
          rootColor,
          isDirect: true,
        ),
    ];
  }

  /// Alt kategori renkleri: ana rengin açıklık varyantları.
  ///
  /// Seçim yine KİMLİĞE bağlı ([ReportCategoryPalette.preferredIndex]), sıraya
  /// değil — bir alt kategorinin tonu dönemden döneme kaymasın. Çakışmalar
  /// ileri sondalamayla çözülür; adım sayısını aşan çocukta tekrar kaçınılmaz
  /// ama o noktada dilim zaten okunmayacak kadar incedir.
  List<Color> _stableTints(List<String> childIds, Color rootColor) {
    final hsl = HSLColor.fromColor(rootColor);
    // Ana renk kökün KENDİ dilimine ayrılır; çocuklar onun etrafında dizilir.
    // Adımlar simetrik değil: koyu uçta göz farkı daha iyi ayırt ediyor.
    const offsets = [0.16, -0.12, 0.30, -0.22, 0.08, -0.30];

    final taken = <int>{};
    final out = <Color>[];
    for (final id in childIds) {
      var slot = ReportCategoryPalette.preferredIndex(id) % offsets.length;
      for (var probe = 0; probe < offsets.length; probe++) {
        final candidate = (slot + probe) % offsets.length;
        if (taken.add(candidate)) {
          slot = candidate;
          break;
        }
      }
      out.add(
        hsl
            .withLightness((hsl.lightness + offsets[slot]).clamp(0.24, 0.80))
            // Açıklık uçlara giderken doygunluğu biraz düşür: aksi hâlde açık
            // tonlar neon, koyu tonlar çamur oluyor.
            .withSaturation(
                (hsl.saturation - offsets[slot].abs() * 0.5).clamp(0.25, 1.0))
            .toColor(),
      );
    }
    return out;
  }

  /// [current] dilimlerine önceki dönem tutarlarını iliştirir.
  ///
  /// Eşleştirme kategori KİMLİĞİ üzerinden; sentetik "Diğer" kovası
  /// dışarıda bırakılır (iki dönemin kovaları farklı kategorilerden kurulur,
  /// kıyaslamak yanıltıcı olurdu).
  List<CategoryData> withPreviousAmounts(
    List<CategoryData> current,
    List<CategoryData> previous,
  ) {
    if (current.isEmpty) return current;
    final byName = {
      for (final p in previous)
        if (!p.isOther) p.name: p.totalAmount,
    };

    // Alt kategoriler de rozet alır: kullanıcı Fatura'ya indiğinde
    // "Elektrik geçen aya göre ↑%30" görmeli. Doğrudan dilim kökle AYNI adı
    // taşıdığı için ayrı tutulur.
    final childByName = <String, double>{};
    final directByName = <String, double>{};
    for (final p in previous) {
      for (final c in p.children) {
        (c.isDirect ? directByName : childByName)[c.name] = c.totalAmount;
      }
    }

    CategoryData withChildren(CategoryData item) => item.children.isEmpty
        ? item
        : item.copyWith(children: [
            for (final c in item.children)
              c.copyWith(
                previousAmount:
                    (c.isDirect ? directByName : childByName)[c.name] ?? 0,
              ),
          ]);

    return [
      for (final item in current)
        if (item.isOther)
          item
        else
          withChildren(item).copyWith(previousAmount: byName[item.name] ?? 0),
    ];
  }

  /// Kategori id'lerine KARARLI renk atar.
  ///
  /// **Neden rank değil:** renk eskiden sıraya göre veriliyordu
  /// (`_colorForIndex(i)`). Ağustos'ta 2. sırada olan "Market" turuncu,
  /// Eylül'de 1. sıraya çıkınca kırmızı oluyordu; iki ayı yan yana koyan
  /// kullanıcı aynı kategoriyi tanıyamıyordu. Artık renk kategorinin
  /// KİMLİĞİNDEN türer, dönemdeki yerinden değil.
  ///
  /// Çakışma çözümü ileri sondalama: aynı grafikte iki dilim asla aynı rengi
  /// almaz (yan yana iki eş renkli dilim tek dilim gibi okunurdu). Bir
  /// kategorinin rengi ancak kendisiyle çakışan bir kategori listeye
  /// girip/çıktığında değişir.
  List<Color> _stableColors(List<String> categoryIds) {
    final palette = ReportCategoryPalette.colors;
    final taken = <int>{};
    final out = <Color>[];

    for (final id in categoryIds) {
      var index = ReportCategoryPalette.preferredIndex(id);
      // Palet dolduğunda (kategori sayısı > palet) tekrar kaçınılmaz;
      // sondalama bir tur atıp durur.
      for (var probe = 0; probe < palette.length; probe++) {
        final candidate = (index + probe) % palette.length;
        if (taken.add(candidate)) {
          index = candidate;
          break;
        }
      }
      out.add(palette[index]);
    }
    return out;
  }

  /// Payı [_pieThresholdPercent]'in altında kalan kategorileri tek "Diğer"
  /// diliminde toplar. Toplam değişmez; yalnız dilimler yeniden gruplanır.
  List<CategoryData> buildPie(List<CategoryData> fullData) {
    if (fullData.isEmpty) return fullData;

    final total =
        fullData.fold<double>(0.0, (sum, item) => sum + item.totalAmount);
    if (total <= 0) return fullData;

    final major = <CategoryData>[];
    final folded = <CategoryData>[];
    double otherTotal = 0;
    final otherTx = <TransactionEntity>[];

    for (final item in fullData) {
      final percent = (item.totalAmount / total) * 100;
      if (percent >= _pieThresholdPercent) {
        major.add(item);
      } else {
        folded.add(item);
        otherTotal += item.totalAmount;
        otherTx.addAll(item.transactions);
      }
    }

    if (otherTx.isEmpty) return major;
    // Kovaya TEK kalem düşerse kova kurulmaz: tek bir kalemin adını "Diğer"
    // ardında saklamanın kazancı yok, üstüne bir iniş adımı daha ekler.
    if (folded.length == 1) return [...major, folded.single];

    // Kova katladığı kalemleri `children` olarak TAŞIR: içine inilebilir.
    // Eskiden kovaya düşen küçük bir kökün alt kategorileri hiçbir yerden
    // görülemiyordu.
    return [
      ...major,
      CategoryData(otherCategoryLabel, otherTotal, otherTx, _otherColor,
          isOther: true, children: folded),
    ];
  }

  /// [tag] kategorisi için, o an görüntülenen [range]'a göre bütçe
  /// ilerlemesini hesaplar. Bütçe tanımlı değilse null döner.
  ReportBudgetProgress? budgetProgressFor(
    String tag,
    double spentInRange,
  ) {
    // Limit AYLIK; aralık bir ay değilse "dönem harcaması / aylık limit"
    // boyutsal olarak yanlıştır ("Bu Yıl"da 12 ayın harcaması 1 aylık limite
    // bölünüyordu). Kıyas yapılamıyorsa çubuk hiç çizilmez — yanlış bir
    // çubuk, çubuğun yokluğundan kötüdür.
    // Tam bir ay değilse limit döneme orantılanır (bkz.
    // [DateRangeHelper.monthlyLimitFactor]; özet kartıyla AYNI hesap).
    final factor = DateRangeHelper.monthlyLimitFactor(range);
    for (final b in budgets) {
      if (b.categoryId == tag) {
        if (b.limitAmount <= 0) return null;
        final limit = b.limitAmount * factor;
        final ratio = spentInRange / limit;
        return (
          progress: ratio.clamp(0.0, 1.0),
          ratio: ratio,
          isExceeded: spentInRange > limit,
          limit: limit,
        );
      }
    }
    return null;
  }
}
