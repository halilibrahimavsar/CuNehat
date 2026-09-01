import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:flutter/material.dart';

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

  /// İlk N kalem + "Diğer" (karşılaştırma çubuğu).
  ranked,
}

/// Karşılaştırma çubuğunun gelir(yeşil)/gider(kırmızı) renk rampaları.
///
/// Adımlar GÖZLE seçilmedi. `AppCard(section: transactions)`'ın gerçek zemini
/// üzerinde — light `#DCE9FD`, dark `#213B69`; ikisi de kartın accent
/// gradyanının kontrast açısından en kötü köşesi — sıralı (ordinal) rampa
/// kapısından geçirilerek OKLCH'de üretildi: tek hue, monoton açıklık, komşu
/// adımlar arası ΔL ≥ 0.06, yüzeye en yakın uç ≥ 2:1 kontrast.
///
/// Neden Material `Colors.green/red` swatch'ı değil: bu zeminde swatch 2:1
/// tabanının üstünde yalnız **3** adım bırakıyor (yeşil 900/800/600). Amaca
/// göre üretilen adımlar **5**'e çıkarır — bir taraftaki dilim sayısının
/// tavanı budur, keyfi bir sınır değil.
///
/// UYARI — renk tek başına gelir/gideri ANLATMAZ: tam şiddette deuteranopia
/// altında bu iki rampa çakışır (ölçülen ΔE 1.2–4.6; taban 6). Kutupluluğu
/// taşıyan şey konum + satır etiketi + ikondur; renk yalnız pekiştirir.
abstract final class ReportCompareRamp {
  /// Bir tarafta gösterilebilen en fazla dilim. Rampanın adım sayısıyla
  /// birebir: her dilim kendi adımını alır, renk asla tekrar etmez.
  static int get maxSlices => _incomeLight.length;

  // rank 1 (en büyük kalem) → rank 5 ("Diğer"): light modda koyudan açığa.
  static const _incomeLight = [
    Color(0xFF215E2E),
    Color(0xFF2A733A),
    Color(0xFF338846),
    Color(0xFF3D9F52),
    Color(0xFF47B55F),
  ];
  static const _expenseLight = [
    Color(0xFF8D2525),
    Color(0xFFAA2E2F),
    Color(0xFFC93839),
    Color(0xFFE94344),
    Color(0xFFEE6E67),
  ];

  // Dark modda yön TERSİNE döner: koyu zeminde "daha çok" = daha parlak.
  // Rampa otomatik çevrilmedi, kendi zeminine göre ayrı seçildi.
  static const _incomeDark = [
    Color(0xFF59DF76),
    Color(0xFF4FC86A),
    Color(0xFF45B25D),
    Color(0xFF3C9D51),
    Color(0xFF338745),
  ];
  static const _expenseDark = [
    Color(0xFFF3A9A3),
    Color(0xFFF08B83),
    Color(0xFFED6862),
    Color(0xFFE64243),
    Color(0xFFC83839),
  ];

  static List<Color> of({
    required bool isExpense,
    required Brightness brightness,
  }) {
    if (brightness == Brightness.dark) {
      return isExpense ? _expenseDark : _incomeDark;
    }
    return isExpense ? _expenseLight : _incomeLight;
  }
}

/// Tek taraflı (yalnız gider ya da yalnız gelir) pasta/çubuk için KATEGORİK
/// palet.
///
/// İki karar bilinçli:
///
/// **Tek hue ailesi değil.** Eskiden gider dilimleri kırmızı–turuncu–kehribar
/// bandından, gelir dilimleri yeşil–turkuaz bandından geliyordu. Ama dilimler
/// SIRALI değil KATEGORİK veridir: "Market" ile "Ulaşım" arasında bir büyüklük
/// ilişkisi yok, ayırt edilebilirlik var. Aynı aileden dört ton yan yana
/// gelince ayırt edilemiyorlardı. Gelir/gider kutupluluğunu kartın başlığı,
/// toplamı ve mod seçicisi zaten taşıyor — dilimlerin ayrıca kırmızı olmasına
/// gerek yok. (Karşılaştırma kartı FARKLIDIR: orada sıralama anlamlıdır ve
/// [ReportCompareRamp]'in sıralı rampası kullanılır.)
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
    Color(0xFF9333EA), // menekşe
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

  const ReportCategoryDataBuilder({
    required this.range,
    required this.budgets,
    required this.otherCategoryLabel,
    this.rootIndex = const {},
  });

  List<TransactionEntity> filterByRange(List<TransactionEntity> transactions) =>
      _service.filterByRange(transactions, range.start, range.end);

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

    return [
      for (final item in current)
        if (item.isOther)
          item
        else
          item.copyWith(previousAmount: byName[item.name] ?? 0),
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
    double otherTotal = 0;
    final otherTx = <TransactionEntity>[];

    for (final item in fullData) {
      final percent = (item.totalAmount / total) * 100;
      if (percent >= _pieThresholdPercent) {
        major.add(item);
      } else {
        otherTotal += item.totalAmount;
        otherTx.addAll(item.transactions);
      }
    }

    if (otherTx.isEmpty) return major;

    return [
      ...major,
      CategoryData(otherCategoryLabel, otherTotal, otherTx, _otherColor,
          isOther: true),
    ];
  }

  /// Karşılaştırma çubuğunun dilimleri: ilk [ReportCompareRamp.maxSlices] − 1
  /// kalem + kalanların "Diğer" kovası, renkler o tarafın rampasından.
  ///
  /// Sayı tavanının yanında [_pieThresholdPercent] eşiği de uygulanır: 2px
  /// boşluklu yığılmış çubukta payı %3'ün altında kalan bir dilim telefonda
  /// ~9dp'den ince kalır, ne okunur ne dokunulur — kovaya iner.
  ///
  /// Kovaya TEK bir kategori düşerse kova KURULMAZ, kategori kendi adıyla
  /// gösterilir: tek bir kalemin adını "Diğer" ardında saklamanın kazancı yok.
  List<CategoryData> buildRanked(
    List<CategoryData> fullData, {
    required bool isExpense,
    required Brightness brightness,
  }) {
    if (fullData.isEmpty) return const [];

    final total =
        fullData.fold<double>(0.0, (sum, item) => sum + item.totalAmount);
    if (total <= 0) return const [];

    final ramp =
        ReportCompareRamp.of(isExpense: isExpense, brightness: brightness);

    final kept = <CategoryData>[];
    final folded = <CategoryData>[];
    for (final item in fullData) {
      final percent = (item.totalAmount / total) * 100;
      final hasRoom = kept.length < ramp.length - 1;
      if (hasRoom && percent >= _pieThresholdPercent) {
        kept.add(item);
      } else {
        folded.add(item);
      }
    }

    final slices = <CategoryData>[
      ...kept,
      if (folded.length == 1)
        folded.single
      else if (folded.length > 1)
        CategoryData(
          otherCategoryLabel,
          folded.fold<double>(0.0, (sum, item) => sum + item.totalAmount),
          [for (final item in folded) ...item.transactions],
          ramp.last,
          isOther: true,
        ),
    ]
      // "Diğer" kovası her zaman SONA eklenir ama her zaman en küçük DEĞİLDİR:
      // ölçüldü — Kira %54, Market %27, Sağlık %5, Fatura %5 tutulurken kova
      // %9 çıkıyordu, yani 3. büyük kalem "en küçük" rampa adımını alıyordu.
      // Rampa sıralı (ordinal) bir kodlama olduğuna göre sıra GERÇEK olmalı.
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    // Renk sırayı izler: rank 1 rampanın ilk adımını alır. Sıralama anlamlı
    // olduğu için bu bir sıralı (ordinal) kodlamadır, kimlik kodlaması değil —
    // kimliği efsane ve etiketler taşır.
    //
    // `copyWith` ŞART: elle kurulan bir `CategoryData` önceki dönem tutarını
    // düşürüyordu, yani karşılaştırma kartının efsanesinde değişim rozeti
    // hiç görünmüyordu.
    return [
      for (int i = 0; i < slices.length; i++)
        slices[i].copyWith(color: ramp[i]),
    ];
  }

  /// [tag] kategorisi için, o an görüntülenen [range]'a göre bütçe
  /// ilerlemesini hesaplar. Bütçe tanımlı değilse null döner.
  ({double progress, bool isExceeded, double limit})? budgetProgressFor(
    String tag,
    double spentInRange,
  ) {
    for (final b in budgets) {
      if (b.categoryId == tag) {
        if (b.limitAmount <= 0) return null;
        return (
          progress: (spentInRange / b.limitAmount).clamp(0.0, 1.0),
          isExceeded: spentInRange > b.limitAmount,
          limit: b.limitAmount,
        );
      }
    }
    return null;
  }
}
