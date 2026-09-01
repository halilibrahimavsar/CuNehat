import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// Bir dönemin gelir/gider/net özeti. Saf veri; biçimlendirme UI'da yapılır.
class ReportTotals {
  final double totalIncome;
  final double totalExpense;
  final double net;

  const ReportTotals({
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.net = 0,
  });
}

/// Tek bir kategorinin (tag) dönem içindeki toplamı ve ona ait işlemler.
/// Renk taşımaz — renk ataması bir sunum kararıdır, UI katmanında yapılır.
class CategoryBreakdown {
  /// Kalemin kimliği: kök kategori id'si ya da (kategoriye çözülmeyen
  /// satırlarda) ham `tag`.
  final String name;

  /// Kökün KENDİ işlemleri + tüm alt kategorilerinin toplamı.
  final double totalAmount;

  /// Alt ağacın tamamı — kırılımı çıkarmak için değil, dilime dokunulduğunda
  /// listelemek için.
  final List<TransactionEntity> transactions;

  /// Alt kategori kırılımı (drill-down). Kökün DOĞRUDAN işlemleri burada
  /// görünmez; onlar [totalAmount] ile çocukların toplamı arasındaki farktır.
  /// Çocuğu olmayan kalemlerde boştur.
  final List<CategoryBreakdown> children;

  const CategoryBreakdown({
    required this.name,
    required this.totalAmount,
    required this.transactions,
    this.children = const [],
  });
}

/// Saf-Dart işlem raporu servisi: rapor sayfasının ihtiyaç duyduğu
/// agregasyonları (aralık filtresi, gelir/gider toplamı, kategori dağılımı)
/// tek yerde toplar.
///
/// Flutter/Hive bağımlılığı yoktur → kolay birim test edilir. Veriyi yalnızca
/// okur; para zincirine (syncBalance) dokunmaz. [DailySpendingSummaryService]
/// ile kardeştir ama farklı sorumluluk taşır (gün-bazlı dağılım değil, dönem
/// raporu).
class TransactionReportService {
  const TransactionReportService();

  /// İşlemleri `[start, end]` kapalı tarih aralığına göre süzer (saat
  /// bileşeninden bağımsız). Başlangıç günün 00:00'ı kabul edilir; bitiş için
  /// "ertesi gün 00:00'dan önce" mantığı kullanılır, böylece bitiş gününün
  /// 23:59:59.999'dan sonraki mikrosaniyeli kayıtları da aralığa dahil kalır.
  List<TransactionEntity> filterByRange(
    List<TransactionEntity> transactions,
    DateTime start,
    DateTime end,
  ) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endExclusive = DateTime(end.year, end.month, end.day + 1);

    return transactions
        .where(
            (t) => !t.date.isBefore(startDay) && t.date.isBefore(endExclusive))
        .toList();
  }

  /// Kuplajla üretilen sistem hareketlerini (transfer, borç ödemesi, yatırım
  /// alımı…) ayrı ayırır.
  ///
  /// **Neden gerekli:** `WalletMetricsService` her kuplaj hareketini gerçek
  /// bir işlem olarak deftere yazar (`isSystem: true`). Rapor bunları
  /// süzmediği için nakitten bankaya 20.000 TL taşımak, o cüzdanın
  /// raporunda 20.000 TL "Gider" + pastada en büyük dilim + çöken bir
  /// birikim oranı demekti. Oysa bu para harcanmadı, yer değiştirdi.
  ///
  /// Ayırma bakiyeyi İLGİLENDİRMEZ: cüzdan bakiyesi defterin tamamından
  /// türer, bu yüzden bakiye çizgisi her zaman tüm hareketleri içerir.
  /// Buradaki ayrım yalnız "ne harcadım" sorusu içindir.
  ({List<TransactionEntity> spending, List<TransactionEntity> system})
      splitSystemMovements(List<TransactionEntity> transactions) {
    final spending = <TransactionEntity>[];
    final system = <TransactionEntity>[];
    for (final t in transactions) {
      (t.isSystem ? system : spending).add(t);
    }
    return (spending: spending, system: system);
  }

  /// Gelir ve gider toplamlarını ve net (gelir − gider) değerini hesaplar.
  ReportTotals calculateTotals(List<TransactionEntity> transactions) {
    double income = 0;
    double expense = 0;

    for (final t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }

    return ReportTotals(
      totalIncome: income,
      totalExpense: expense,
      net: income - expense,
    );
  }

  /// İşlemleri KÖK kategoriye göre gruplayıp her grubun toplamını çıkarır.
  /// [isExpense] true ise yalnızca giderler, false ise yalnızca gider-olmayan
  /// (gelir) işlemler dikkate alınır. Sonuç toplam tutara göre azalan sıralıdır.
  ///
  /// [rootIndex] (`id → kök id`, bkz. `buildRootIndex`) verilmezse her tag
  /// kendi başına bir kalem olur — hiyerarşi öncesi davranış.
  ///
  /// Toplamanın kök seviyede olması zorunludur: yaprak seviyede gruplansaydı
  /// on kategorilik bir kurulum otuz dilime çıkar, pasta grafiğin %3 eşiği
  /// hepsini "Diğer" kovasına süpürür ve alt kategoriye geçmek raporu
  /// boşaltırdı.
  List<CategoryBreakdown> buildCategoryBreakdown(
    List<TransactionEntity> transactions, {
    required bool isExpense,
    Map<String, String> rootIndex = const {},
  }) {
    // Kök → (alt kalem kimliği → işlemler). Kökün doğrudan işlemleri kendi
    // kimliği altında toplanır.
    final grouped = <String, Map<String, List<TransactionEntity>>>{};

    for (final t in transactions) {
      if (t.isExpense != isExpense) continue;
      final root = rootIdOf(t.tag, rootIndex);
      grouped.putIfAbsent(root, () => {}).putIfAbsent(t.tag, () => []).add(t);
    }

    if (grouped.isEmpty) return const [];

    double sumOf(Iterable<TransactionEntity> list) =>
        list.fold<double>(0.0, (prev, t) => prev + t.amount);

    final result = grouped.entries.map((entry) {
      final root = entry.key;
      final byLeaf = entry.value;
      final all = [for (final list in byLeaf.values) ...list];

      final children = [
        for (final leaf in byLeaf.entries)
          // Kökün DOĞRUDAN işlemleri çocuk kırılımında ayrı kalem değildir.
          if (leaf.key != root)
            CategoryBreakdown(
              name: leaf.key,
              totalAmount: sumOf(leaf.value),
              transactions: leaf.value,
            ),
      ]..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      return CategoryBreakdown(
        name: root,
        totalAmount: sumOf(all),
        transactions: all,
        children: children,
      );
    }).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return result;
  }
}
