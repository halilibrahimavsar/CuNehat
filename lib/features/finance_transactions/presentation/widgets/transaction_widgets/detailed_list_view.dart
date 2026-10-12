import 'package:intl/intl.dart';
import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'dart:math' as math;

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_card.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:flutter/material.dart';

/// Bir günün işlemleri ve o güne ait toplamlar.
///
/// Gruplama sunumdan ayrı tutuluyor: hem sayfa (sliver defter) hem rapor
/// sayfaları (kutu defter) aynı listeyi kurar, ve gruplama widget kurmadan
/// test edilebilir.
///
/// **Evren: özetle AYNI.** Gelir/gider yalnız harcama hareketlerini sayar
/// (bkz. `isSpendingMovement`); para taşıma hareketleri [moved]'da ayrı durur.
/// Eskiden rozet kuplaj hareketlerini de sayıyordu, gerekçe "rozetin altında
/// o satırlar listeleniyor, süzmek gözle sayılamayan bir rakam üretir" idi.
/// Ama satırlar gider kırmızısıyla çizildiği için aynı dönemde özet şeridi
/// "gider 0", gün rozeti "−2.500" diyordu. Artık para taşıma satırları NÖTR
/// renkte ([MoneyColors.moved]) — gözle ayırt edilebiliyor, rozet de
/// özetle aynı şeyi söylüyor.
class LedgerDayGroup {
  final DateTime day;
  final List<TransactionWithBalance> items;
  final double income;
  final double expense;

  /// Para taşıma hareketlerinin işaretli toplamı (giren +, çıkan −).
  final double moved;

  const LedgerDayGroup({
    required this.day,
    required this.items,
    required this.income,
    required this.expense,
    this.moved = 0,
  });

  double get net => income - expense;

  /// Gün yalnız para taşıma hareketinden mi ibaret?
  bool get isOnlyMoved => income == 0 && expense == 0 && moved != 0;

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
        double income = 0, expense = 0, moved = 0;
        for (final e in items) {
          final t = e.transaction;
          if (!isSpendingMovement(t)) {
            if (t.isIncome) moved += t.amount;
            if (t.isExpense) moved -= t.amount;
          } else if (t.isIncome) {
            income += t.amount;
          } else if (t.isExpense) {
            expense += t.amount;
          }
        }
        return LedgerDayGroup(
          day: day,
          items: items,
          income: income,
          expense: expense,
          moved: moved,
        );
      }(),
  ];
}

/// Gün başlığının metni: gün ADI dahil ("24 Eylül Çarşamba"). Eskiden
/// yalnız tarih yazıyordu; "hangi gün alışveriş yapmışım" sorusu ikinci bir
/// hesap gerektiriyordu. Yıl yalnız içinde bulunulan yıldan farklıysa yazılır:
/// her başlıkta aynı yılı tekrarlamak yer kaplıyordu.
String dayHeaderLabel(DateTime day, {DateTime? now}) {
  final locale = Intl.defaultLocale;
  final thisYear = (now ?? DateTime.now()).year;
  return day.year == thisYear
      ? DateFormat.MMMMEEEEd(locale).format(day)
      : DateFormat.yMMMMEEEEd(locale).format(day);
}

/// Defterin hangi günlerinin KAPALI olduğu — sayfanın "tümünü daralt /
/// genişlet" düğmesiyle sliver arasında paylaşılır.
///
/// Varsayılan AÇIK olduğu için yalnız kapananlar tutulur. "Hepsi kapalı mı"
/// sorusu o an LİSTELENEN günlere göre sorulur ([allCollapsed]): dönem
/// değişince yeni günler açık gelir ve düğme doğru etiketi gösterir.
class LedgerCollapseController extends ChangeNotifier {
  final Set<DateTime> _collapsed = {};

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  bool isCollapsed(DateTime day) => _collapsed.contains(_day(day));

  void toggle(DateTime day) {
    final d = _day(day);
    if (!_collapsed.remove(d)) _collapsed.add(d);
    notifyListeners();
  }

  bool allCollapsed(Iterable<DateTime> days) {
    var any = false;
    for (final d in days) {
      any = true;
      if (!_collapsed.contains(_day(d))) return false;
    }
    return any;
  }

  void collapseAll(Iterable<DateTime> days) {
    _collapsed.addAll(days.map(_day));
    notifyListeners();
  }

  void expandAll() {
    if (_collapsed.isEmpty) return;
    _collapsed.clear();
    notifyListeners();
  }
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

  /// Verilirse katlama durumu dışarıda tutulur ("tümünü daralt"); yoksa
  /// sliver kendi durumunu taşır.
  final LedgerCollapseController? collapse;

  /// Verilirse gün başlığında "+" çıkar: o GÜNE yeni kayıt. Geçmiş bir güne
  /// kayıt girmenin tek yolu formu açıp tarihi elle geri almaktı. Salt
  /// okunur yüzeylerde (rapor alt sayfaları) verilmez, düğme çizilmez.
  final ValueChanged<DateTime>? onAddForDay;

  const TransactionLedgerSliver({
    super.key,
    required this.transactions,
    required this.categoryIcons,
    required this.categoryLabels,
    this.mode = FinanceMode.compare,
    this.showDayEndBalance = true,
    this.anchors,
    this.collapse,
    this.onAddForDay,
  });

  @override
  State<TransactionLedgerSliver> createState() =>
      _TransactionLedgerSliverState();
}

class _TransactionLedgerSliverState extends State<TransactionLedgerSliver> {
  LedgerCollapseController? _own;
  LedgerCollapseController get _collapse =>
      widget.collapse ?? (_own ??= LedgerCollapseController());

  @override
  void initState() {
    super.initState();
    _collapse.addListener(_onCollapseChanged);
  }

  @override
  void didUpdateWidget(covariant TransactionLedgerSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapse != widget.collapse) {
      (oldWidget.collapse ?? _own)?.removeListener(_onCollapseChanged);
      _collapse.addListener(_onCollapseChanged);
    }
  }

  @override
  void dispose() {
    _collapse.removeListener(_onCollapseChanged);
    _own?.dispose();
    super.dispose();
  }

  void _onCollapseChanged() => setState(() {});

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
                  isExpanded: !_collapse.isCollapsed(group.day),
                  anchorKey: widget.anchors?.keyFor(group.day),
                  extent: _headerExtent(context),
                  onToggle: () => _collapse.toggle(group.day),
                  onAdd: widget.onAddForDay == null
                      ? null
                      : () => widget.onAddForDay!(group.day),
                ),
              ),
              if (!_collapse.isCollapsed(group.day))
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
          // Bu sarmalayıcının İKİ çağıranı da ekranın DİBİNE oturan modal
          // sheet (rapor detayı / kategori detayı): `showModalBottomSheet`
          // yalnız ÜST payı düşürdüğü için alt payı listenin kendisi almalı,
          // yoksa son işlem satırı gezinme çubuğunun altında kalıyor.
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24)
              .plusSystemBottom(context),
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
  final VoidCallback? onAdd;

  _DayHeaderDelegate({
    required this.group,
    required this.isExpanded,
    required this.anchorKey,
    required this.extent,
    required this.onToggle,
    this.onAdd,
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
                  duration: AppMotion.of(context).d(AppMotion.short),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dayHeaderLabel(group.day),
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
                if (onAdd != null)
                  // Başlığın kendi dokunuşu günü katlar; "+" ondan ayrı bir
                  // hedeftir (başlık yüksekliği en az 44dp, bkz.
                  // `_headerExtent`).
                  IconButton(
                    key: ValueKey('tx-day-add-${_dayKey(group.day)}'),
                    tooltip: context.l10n.txDayAdd,
                    onPressed: onAdd,
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    color: scheme.primary,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  )
                else
                  const SizedBox(width: 8),
                group.isOnlyMoved
                    ? _NetBadge(net: group.moved, moved: true)
                    : _NetBadge(net: group.net),
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
      old.extent != extent ||
      (old.onAdd == null) != (onAdd == null);
}

/// Gün başlığı anahtarlarında kullanılan yerelden bağımsız gün damgası.
String _dayKey(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

class _NetBadge extends StatelessWidget {
  final double net;

  /// Yalnız para taşıma olan gün: nötr renk ve ⇄ işareti.
  final bool moved;

  const _NetBadge({required this.net, this.moved = false});

  // Kutu YOK: cihazda rozet başlığın tüm yüksekliğini kaplayan iri pembe bir
  // kutu olarak çiziliyordu (44dp'lik başlıkta ~42dp) ve günün asıl bilgisi
  // olan tarihten daha baskın duruyordu. Yalın, işaretli metin + küçük renk
  // işareti; para taşıma gününde nokta yerine ⇄.
  @override
  Widget build(BuildContext context) {
    final color = moved
        ? MoneyColors.moved(Theme.of(context).brightness)
        : net >= 0
            ? MoneyColors.income
            : MoneyColors.expense;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (moved)
          Icon(Icons.swap_horiz_rounded, size: 14, color: color)
        else
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 5),
        SignedMoneyText(
          amount: net,
          isExpense: net < 0,
          currency: context.activeWalletCurrency,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.2,
          ),
        ),
      ],
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
