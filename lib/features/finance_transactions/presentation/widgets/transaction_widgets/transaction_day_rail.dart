import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/features/finance_transactions/domain/services/daily_spending_summary_service.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

/// Dönemin günlerini yatay bir şeritte gösteren ısı göstergesi.
///
/// **Ay ızgarasının yerine geçti.** Tam takvim 360×800'de 374dp kaplıyordu ve
/// sayfaya kalan 630dp'nin içinde işlem listesini katlanmanın altına
/// itiyordu: bir güne dokunulduğunda o günün yalnız 1 işlemi görünüyordu
/// (ölçüldü). Izgaradaki tek finansal veri olan tutar ise gerçekten 8,5px
/// çiziliyordu — `FittedBox` küçültmüyordu bile, ölçek 1.000'di. Şerit aynı
/// bilgiyi (hangi gün ne kadar harcandı) YAZI yerine GEOMETRİYLE verir:
/// çubuk yüksekliği okunmak için font boyutuna muhtaç değildir.
///
/// **İki kanal, iki kodlama.** Eski hücre giderle boyanıyor ama neti
/// yazıyordu; 48,8K'lık bir gelir günü hiç boyanmadığı için görünmez
/// oluyordu. Burada çubuk YALNIZ gideri ölçer, gelir ayrı bir noktayla
/// işaretlenir — aynı 40dp'lik alanda iki bilgi çakışmaz.
///
/// Şerit dönemin TAMAMINI kapsar: "bu yıl" seçen kullanıcı 365 hücrelik bir
/// şerit görür ve gezinebilir. Eski takvim bunu yapamıyordu; üstelik sayfa
/// çevirince kullanıcının seçtiği yıllık dönemi sessizce tek aya düşürüyordu.
class TransactionDayRail extends StatefulWidget {
  /// Etkin dönem — şeridin kapsamı.
  final DateTimeRange range;

  /// Gün → o günün gelir/gider/sayı özeti (filtre uygulanmış küme).
  final Map<DateTime, DaySummary> summaries;

  /// Kullanıcının seçtiği gün; listenin kaydırıldığı gün de budur.
  final DateTime? selectedDay;

  final ValueChanged<DateTime> onDaySelected;

  const TransactionDayRail({
    super.key,
    required this.range,
    required this.summaries,
    required this.onDaySelected,
    this.selectedDay,
  });

  /// Şeridin kapladığı yükseklik.
  ///
  /// Yatay `ListView` SINIRLI bir yükseklik ister, yani hücre içeriği
  /// serbestçe uzayamaz. Sabit 74dp bırakılınca yazı ölçeği 1.6'da hücre 4px
  /// taşıyordu (ölçüldü), o yüzden yükseklik yazı metriklerinden türetilir.
  ///
  /// **TUZAK — satır yüksekliği temadan gelir.** İki yazı da `height`'ini
  /// AÇIKÇA veriyor ([_lineHeight]). Vermeselerdi `Scaffold` altındaki
  /// Material 3 `bodyMedium` mirası devreye girer ve 9,5px'lik harf 14dp,
  /// 12px'lik gün 17dp çizilirdi — hesap %40 şaşardı. (Bu ölçüm Material
  /// atası OLMADAN yapılınca doğru görünüyor; hata ancak gerçek ağaçta
  /// çıkıyor.)
  ///
  /// Çubuk yine de [Expanded] içinde: yuvarlama artığı çubuğa gider, hiçbir
  /// koşulda taşmaya dönüşmez.
  static double heightFor(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final weekdayLine = scaler.scale(_weekdayFont) * _lineHeight;
    final dayChip = scaler.scale(_dayFont) * _lineHeight + _dayChipPadding * 2;
    return _outerPadding * 2 + weekdayLine + 3 + _barTrack + 3 + dayChip;
  }

  static const double _cellWidth = 42;
  static const double _barTrack = 20;
  static const double _weekdayFont = 9.5;
  static const double _dayFont = 12;
  static const double _dayChipPadding = 3;
  static const double _outerPadding = 4;
  static const double _lineHeight = 1.15;

  @override
  State<TransactionDayRail> createState() => _TransactionDayRailState();
}

class _TransactionDayRailState extends State<TransactionDayRail> {
  final ScrollController _controller = ScrollController();
  late List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _days = daysOf(widget.range);
    _scheduleCenter();
  }

  @override
  void didUpdateWidget(covariant TransactionDayRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.range != oldWidget.range) {
      _days = daysOf(widget.range);
      _scheduleCenter();
    } else if (widget.selectedDay != oldWidget.selectedDay) {
      _scheduleCenter();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Şeridi ilgi çeken güne ortalar: seçili gün, yoksa bugün, o da dönemde
  /// değilse dönemin başı. Kaydırma yerleşimden SONRA yapılmalı — viewport
  /// genişliği ancak o zaman bilinir.
  ///
  /// Seçili gün DÖNEM DIŞINDA kalabilir (kullanıcı bir gün seçip sonra ayı
  /// değiştirdi). O zaman ona çapalamak şeridi hiç kaydırmamak demekti:
  /// yeni ay açıldığında şerit 1'inde takılı kalıyordu.
  void _scheduleCenter() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final selected = widget.selectedDay;
      final anchor = (selected != null && isDayInRange(selected, widget.range))
          ? selected
          : focusDayFor(widget.range);
      final index = _days.indexWhere((d) => isSameDayValue(d, anchor));
      if (index < 0) return;
      final viewport = _controller.position.viewportDimension;
      final target = index * TransactionDayRail._cellWidth -
          (viewport - TransactionDayRail._cellWidth) / 2;
      _controller.jumpTo(
        target.clamp(0.0, _controller.position.maxScrollExtent),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double maxExpense = 0;
    for (final day in _days) {
      final e = widget.summaries[day]?.expense ?? 0;
      if (e > maxExpense) maxExpense = e;
    }

    return SizedBox(
      height: TransactionDayRail.heightFor(context),
      child: Semantics(
        container: true,
        label: context.l10n.txRailTitle,
        child: ListView.builder(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemExtent: TransactionDayRail._cellWidth,
          itemCount: _days.length,
          itemBuilder: (context, index) => _DayCell(
            day: _days[index],
            summary: widget.summaries[_days[index]],
            maxExpense: maxExpense,
            isSelected: widget.selectedDay != null &&
                isSameDayValue(_days[index], widget.selectedDay!),
            isToday: isSameDayValue(_days[index], dayOf(DateTime.now())),
            onTap: () => widget.onDaySelected(_days[index]),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final DaySummary? summary;
  final double maxExpense;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.summary,
    required this.maxExpense,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Intl.defaultLocale;
    final s = summary;
    final expense = s?.expense ?? 0;
    final hasIncome = (s?.income ?? 0) > 0;

    // Çubuk yüksekliği dönemin en yüksek gider gününe göre normalize edilir:
    // her dönem kendi içinde okunur kalsın.
    final intensity =
        maxExpense <= 0 ? 0.0 : (expense / maxExpense).clamp(0.0, 1.0);
    // Çubuk oranı gerçek ray yüksekliğinden hesaplanır (ray Expanded).
    double barHeightIn(double track) =>
        expense > 0 ? 3 + (track - 3) * intensity : 0.0;

    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    final Color dayColor = isSelected
        ? Colors.white
        : isToday
            ? AppGradients.transactions
            : scheme.onSurface.withValues(alpha: 0.85);

    return Semantics(
      button: true,
      selected: isSelected,
      label: _semanticsLabel(context),
      // TUZAK — `excludeSemantics` alt ağacın semantiklerini TÜMDEN düşürür,
      // InkWell'in tap EYLEMİ dahil. Ölçüldü: hücre "düğme" diye duyuruluyor
      // ama TalkBack'in çift dokunması hiçbir şey yapmıyordu (isButton true,
      // hasAction(tap) FALSE) — yani şerit ekran okuyucuyla kullanılamıyordu
      // ve defteri bir güne kaydırmanın başka yolu yok. Rol eklerken eylem
      // KAYBOLMAMALI; bkz. test/core/shared/widgets/app_card_semantics_test.dart.
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 2, vertical: TransactionDayRail._outerPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                // Haftanın tek harfi; hafta sonu ayrı renkte (takvimdeki
                // ayrım korunuyor).
                DateFormat.E(locale).format(day).substring(0, 1),
                maxLines: 1,
                style: TextStyle(
                  fontSize: TransactionDayRail._weekdayFont,
                  fontWeight: FontWeight.w800,
                  height: TransactionDayRail._lineHeight,
                  letterSpacing: 0.2,
                  color: isWeekend
                      ? AppGradients.debt.withValues(alpha: 0.65)
                      : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Boş günde bile ince bir taban çizgisi: hücre "veri yok"
                    // ile "ölçülmedi"yi ayırt ettirir.
                    Container(
                      height: 1.5,
                      width: 16,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    if (expense > 0)
                      LayoutBuilder(
                        builder: (context, c) => Container(
                          height: barHeightIn(c.maxHeight),
                          width: 16,
                          decoration: BoxDecoration(
                            color: AppGradients.debt
                                .withValues(alpha: 0.35 + 0.55 * intensity),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    if (hasIncome)
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppGradients.savings,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: TransactionDayRail._dayChipPadding),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppGradients.transactions
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: !isSelected && isToday
                      ? Border.all(
                          color:
                              AppGradients.transactions.withValues(alpha: 0.7),
                          width: 1.2,
                        )
                      : null,
                ),
                // TUZAK — iki haneli gün SARAR. Yazı ölçeği 2.0'da "30"
                // 42dp'lik hücreye sığmayıp iki satıra düşüyor ve rozet
                // yüksekliği ikiye katlanıyordu (ölçüldü: 8,6px taşma).
                // Üstelik yalnız GENİŞ ekranda görünüyordu: şerit tembel,
                // 360dp'de o hücre hiç kurulmuyordu.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${day.day}',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: TransactionDayRail._dayFont,
                      height: TransactionDayRail._lineHeight,
                      fontWeight: (isSelected || isToday)
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: dayColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ekran okuyucu çubuğu göremez: gerçek rakamlar buradan okunur.
  ///
  /// Tutar [MoneyWriter]'dan geçer, `formatMoney`'den DEĞİL. Hücrede rakam
  /// çizilmediği için göz düğmesi kapatıldığında ekran görsel olarak temiz
  /// görünüyordu, ama etiket gerçek tutarı okumaya devam ediyordu: gizleme
  /// yalnız GÖZE uygulanmış oluyordu. Aynı kusur İçgörü/Rapor sayfalarında
  /// da `formatMoney`'nin doğrudan çağrılmasından çıkmıştı.
  String _semanticsLabel(BuildContext context) {
    final date = DateFormat.yMMMMEEEEd(Intl.defaultLocale).format(day);
    final s = summary;
    if (s == null || s.isEmpty) {
      return context.l10n.txRailDayEmptySemantics(date);
    }
    final money = MoneyWriter.of(context);
    return context.l10n.txRailDaySemantics(date, money(s.net), s.count);
  }
}
