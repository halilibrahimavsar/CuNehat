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

  const CategoryData(
    this.name,
    this.totalAmount,
    this.transactions,
    this.color, {
    this.isOther = false,
  });
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

/// Rapor sayfasının kategori kırılımını üreten yardımcı: seçili tarih aralığı,
/// bütçe limitleri ve renk paletini tek yerde tutar.
///
/// Detay bottom sheet'i, sayfanın State'ine kapanan dört ayrı closure yerine
/// bu nesneyi alır; böylece TransactionBloc her değiştiğinde kırılımı kendisi
/// yeniden hesaplayabilir ve State'e bağımlı kalmaz.
class ReportCategoryDataBuilder {
  static const _service = TransactionReportService();

  static const _expensePalette = [
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.deepOrangeAccent,
    Colors.amberAccent,
  ];
  static const _incomePalette = [
    Colors.greenAccent,
    Colors.tealAccent,
    Colors.blueAccent,
    Colors.indigoAccent,
  ];

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

  const ReportCategoryDataBuilder({
    required this.range,
    required this.budgets,
    required this.otherCategoryLabel,
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
    );

    return [
      for (int i = 0; i < breakdowns.length; i++)
        CategoryData(
          breakdowns[i].name,
          breakdowns[i].totalAmount,
          breakdowns[i].transactions,
          _colorForIndex(i, isExpense),
        ),
    ];
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
    ];

    // Renk sırayı izler: rank 1 rampanın ilk adımını alır. Sıralama anlamlı
    // olduğu için bu bir sıralı (ordinal) kodlamadır, kimlik kodlaması değil —
    // kimliği efsane ve etiketler taşır.
    return [
      for (int i = 0; i < slices.length; i++)
        CategoryData(
          slices[i].name,
          slices[i].totalAmount,
          slices[i].transactions,
          ramp[i],
          isOther: slices[i].isOther,
        ),
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

  Color _colorForIndex(int i, bool isExpense) {
    final palette = isExpense ? _expensePalette : _incomePalette;
    if (i < palette.length) return palette[i];

    final overflow = i - palette.length;
    const stepsPerCycle = 8;
    final hueStart = isExpense ? 0.0 : 95.0;
    final hueWidth = isExpense ? 45.0 : 150.0;
    final hue =
        (hueStart + (overflow % stepsPerCycle) * (hueWidth / stepsPerCycle)) %
            360;
    final cycle = overflow ~/ stepsPerCycle;
    final lightness = (0.42 + (cycle % 3) * 0.12).clamp(0.3, 0.72);
    return HSLColor.fromAHSL(1, hue, 0.65, lightness).toColor();
  }
}
