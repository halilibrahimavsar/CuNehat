import 'dart:math' as math;

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_card.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';

/// Bir günün işlemleri ve o güne ait toplamlar.
///
/// Gruplama sunumdan ayrı tutuluyor: hem sayfa (sliver defter) hem rapor
/// sayfaları (kutu defter) aynı listeyi kurar, ve gruplama widget kurmadan
/// test edilebilir.
class LedgerDayGroup {
  final DateTime day;
  final List<TransactionWithBalance> items;
  final double income;
  final double expense;

  const LedgerDayGroup({
    required this.day,
    required this.items,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;

  /// Gün sonu bakiyesi = o günün EN YENİ işleminden sonraki bakiye.
  /// [items] defterle aynı sırayı (yeniden eskiye) taşır.
  double get dayEndBalance => items.first.balanceAfter;
}

/// Defteri güne göre gruplar; sıra yeniden eskiye.
///
/// [mode] tek türe daralttığında grup toplamları da yalnız o türü sayar —
/// başlıktaki rakam altındaki kartlarla tutarlı kalsın.
List<LedgerDayGroup> groupLedgerByDay(
  List<TransactionWithBalance> ledger,
  FinanceMode mode,
) {
  final buckets = <DateTime, List<TransactionWithBalance>>{};
  for (final item in ledger) {
    final t = item.transaction;
    if (mode == FinanceMode.income && !t.isIncome) continue;
    if (mode == FinanceMode.expense && !t.isExpense) continue;
    final d = t.date;
    buckets.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(item);
  }

  final days = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in days)
      () {
        final items = buckets[day]!;
        double income = 0, expense = 0;
        for (final e in items) {
          if (e.transaction.isIncome) {
            income += e.transaction.amount;
          } else if (e.transaction.isExpense) {
            expense += e.transaction.amount;
          }
        }
        return LedgerDayGroup(
          day: day,
          items: items,
          income: income,
          expense: expense,
        );
      }(),
  ];
}

/// Gün başlıklarına "şu güne git" diyebilmek için sayfayla defter arasında
/// paylaşılan çapa defteri.
///
/// Gün şeridinden bir güne dokunmak listeyi oraya kaydırır; hedef başlık
/// tembel listede henüz kurulmamış olabilir, o yüzden çağıran önce yaklaşır
/// sonra [contextFor] ile kesin hizalamayı yapar.
class LedgerDayAnchors {
  final Map<DateTime, GlobalKey> _keys = {};

  GlobalKey keyFor(DateTime day) =>
      _keys.putIfAbsent(DateTime(day.year, day.month, day.day), GlobalKey.new);

  BuildContext? contextFor(DateTime day) =>
      _keys[DateTime(day.year, day.month, day.day)]?.currentContext;
}

/// Defterin sliver hâli: her gün için YAPIŞKAN başlık + kartlar.
///
/// **Neden sliver.** Gün başlığı ekranın tepesinde asılı kalır, yani uzun bir
/// listede hangi güne baktığın her an yazılıdır. `SliverMainAxisGroup` her
/// başlığı kendi grubuyla sınırlar: bir sonraki gün geldiğinde önceki başlık
/// yukarı itilir, başlıklar üst üste YIĞILMAZ.
///
/// **Giriş animasyonu kaldırıldı.** Eski `_EntranceAnimation` her satıra
/// `index.clamp(0,8) * 40 ms` gecikme veriyor ve "eleman geri dönüşümü
/// sayesinde scroll'da tekrar oynamaz" diyordu. Ölçüm bunun doğru olmadığını
/// gösterdi: kaydırmadan 216 ms sonra 17 satırın 4'ü hâlâ tam opak değildi —
/// yani hızlı kaydırmada satırlar boş gelip sonradan beliriyordu.
class TransactionLedgerSliver extends StatefulWidget {
  final List<TransactionWithBalance> transactions;
  final FinanceMode mode;
  final Map<String, IconData> categoryIcons;

  /// `tag` → görünen ad (bkz. `buildCategoryLabelMap`).
  ///
  /// [categoryIcons] ile TEK bir indeksin iki yarısıdır ve birlikte yüklenir;
  /// ikisi de zorunludur. Varsayılanlı olduklarında ikonları geçip adları
  /// unutmak sessizce derleniyordu: rapor detay sheet'inde başlık yeni adı,
  /// altındaki kartlar eski adı gösteriyordu.
  final Map<String, String> categoryLabels;

  final bool showDayEndBalance;

  /// Verilirse gün başlıklarına çapa takılır ("şu güne git" için).
  final LedgerDayAnchors? anchors;

  const TransactionLedgerSliver({
    super.key,
    required this.transactions,
    required this.categoryIcons,
    required this.categoryLabels,
    this.mode = FinanceMode.compare,
    this.showDayEndBalance = true,
    this.anchors,
  });

  @override
  State<TransactionLedgerSliver> createState() =>
      _TransactionLedgerSliverState();
}

class _TransactionLedgerSliverState extends State<TransactionLedgerSliver> {
  /// Kapatılmış günler. Varsayılan AÇIK olduğu için yalnız kapananlar tutulur;
  /// böylece liste değişince "hangi günler vardı" defterini taşımak gerekmez.
  final Set<DateTime> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    final groups = groupLedgerByDay(widget.transactions, widget.mode);

    return SliverMainAxisGroup(
      slivers: [
        for (final group in groups)
          SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _DayHeaderDelegate(
                  group: group,
                  isExpanded: !_collapsed.contains(group.day),
                  anchorKey: widget.anchors?.keyFor(group.day),
                  extent: _headerExtent(context),
                  onToggle: () => setState(() {
                    if (!_collapsed.remove(group.day)) {
                      _collapsed.add(group.day);
                    }
                  }),
                ),
              ),
              if (!_collapsed.contains(group.day))
                SliverList.builder(
                  itemCount: group.items.length,
                  itemBuilder: (context, index) {
                    final item = group.items[index];
                    final isLast = index == group.items.length - 1;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TransactionCard(
                          item: item,
                          categoryIcon:
                              widget.categoryIcons[item.transaction.tag],
                          categoryLabel:
                              widget.categoryLabels[item.transaction.tag],
                        ),
                        if (isLast && widget.showDayEndBalance)
                          _DayEndBalance(balance: group.dayEndBalance),
                        if (isLast) const SizedBox(height: 10),
                      ],
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }

  /// Yapışkan başlığın yüksekliği yazı ölçeğiyle büyür.
  ///
  /// `SliverPersistentHeader` sabit bir `extent` ister; 44dp'de bırakılırsa
  /// erişilebilirlik için yazıyı büyüten kullanıcıda başlık kırpılırdı.
  static double _headerExtent(BuildContext context) =>
      math.max(44.0, MediaQuery.textScalerOf(context).scale(14) * 1.4 + 20);
}

/// Rapor sayfalarının kullandığı kutu defter (kendi kaydırmasıyla).
///
/// İşlemler ekranı defteri kendi `CustomScrollView`'ine gömer; bu sarmalayıcı
/// aynı görünümü kendi başına duran bir liste isteyen çağıranlar içindir.
class DetailedListView extends StatelessWidget {
  final List<TransactionWithBalance> transactions;
  final FinanceMode mode;
  final Map<String, IconData> categoryIcons;
  final Map<String, String> categoryLabels;
  final bool showDayEndBalance;

  const DetailedListView({
    super.key,
    required this.transactions,
    required this.categoryIcons,
    required this.categoryLabels,
    this.mode = FinanceMode.compare,
    this.showDayEndBalance = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: TransactionLedgerSliver(
            transactions: transactions,
            mode: mode,
            categoryIcons: categoryIcons,
            categoryLabels: categoryLabels,
            showDayEndBalance: showDayEndBalance,
          ),
        ),
      ],
    );
  }
}

// ======================================================== Gün başlığı

class _DayHeaderDelegate extends SliverPersistentHeaderDelegate {
  final LedgerDayGroup group;
  final bool isExpanded;
  final GlobalKey? anchorKey;
  final double extent;
  final VoidCallback onToggle;

  _DayHeaderDelegate({
    required this.group,
    required this.isExpanded,
    required this.anchorKey,
    required this.extent,
    required this.onToggle,
  });

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scheme = Theme.of(context).colorScheme;

    // Opak zemin ŞART: başlık asılı kaldığında altından geçen kartlar
    // yazının arkasından görünürdü.
    return Material(
      key: anchorKey,
      color: scheme.surface,
      child: InkWell(
        onTap: onToggle,
        child: Semantics(
          button: true,
          expanded: isExpanded,
          label: isExpanded
              ? context.l10n.txDayCollapse
              : context.l10n.txDayExpand,
          child: SizedBox(
            height: extent,
            child: Row(
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppFormatters.dateLong.format(group.day),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _NetBadge(net: group.net),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DayHeaderDelegate old) =>
      old.group.day != group.day ||
      old.group.net != group.net ||
      old.group.items.length != group.items.length ||
      old.isExpanded != isExpanded ||
      old.extent != extent;
}

class _NetBadge extends StatelessWidget {
  final double net;

  const _NetBadge({required this.net});

  @override
  Widget build(BuildContext context) {
    final color = net >= 0 ? AppGradients.savings : AppGradients.debt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 0.5),
      ),
      child: SignedMoneyText(
        amount: net,
        isExpense: net < 0,
        currency: context.activeWalletCurrency,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _DayEndBalance extends StatelessWidget {
  final double balance;

  const _DayEndBalance({required this.balance});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2, right: 6, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.gunSonu,
            style: TextStyle(
              fontSize: 10.5,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          MoneyText(
            amount: balance,
            currency: context.activeWalletCurrency,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: balance >= 0 ? scheme.onSurfaceVariant : AppGradients.debt,
            ),
          ),
        ],
      ),
    );
  }
}
