import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';

/// İşlemler ekranının dönem özeti — net, gelir, gider, işlem sayısı.
///
/// **Neden yeniden yazıldı.** Önceki `TransactionHeader` 360×800'de 191dp
/// kaplıyordu ve üst çubukla birlikte ilk işlem satırına kadar 309/630 dp
/// (%49) harcanıyordu; ekranda üç kart kalıyordu. Üstelik yalnız liste
/// modunda vardı: takvim görünümü aynı rakamları 9,5–10,5px'lik ayrı bir
/// satırda söylüyordu, yani aynı veri iki farklı dille anlatılıyordu.
/// Analitiğin ağır işi zaten bir kaydırma ötede (İçgörü + Rapor alt
/// görünümleri); ana ekranın işi "bu dönemde ne oldu"yu tek bakışta vermek.
///
/// Bir kategorinin dönem giderindeki payı (0–1).
typedef TopCategoryShare = ({String label, double share});

/// "En çok: Market %44 · Fatura %31 · Yemek %13 ›"
class _TopCategoriesLine extends StatelessWidget {
  const _TopCategoriesLine({required this.items, required this.onTap});

  final List<TopCategoryShare> items;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final strong = muted?.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    String percent(double share) => (share * 100).round().toString();

    final line = Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: muted,
              children: [
                TextSpan(text: '${l10n.txTopCategoriesLead} '),
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const TextSpan(text: ' · '),
                  TextSpan(text: items[i].label, style: strong),
                  TextSpan(
                      text: ' ${l10n.percentValue(percent(items[i].share))}'),
                ],
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onTap != null)
          Icon(Icons.chevron_right_rounded,
              size: 18, color: scheme.onSurfaceVariant),
      ],
    );

    return Semantics(
      button: onTap != null,
      label: l10n.txTopCategoriesSemantics(
        [
          for (final item in items)
            '${item.label} ${l10n.percentValue(percent(item.share))}',
        ].join(', '),
      ),
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('tx-top-categories'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          // Sıkı: bu satır defterin ilk kaydını aşağı iter (bkz. dikey
          // bütçe testi); 22dp'den fazlasına değmez.
          padding: const EdgeInsets.only(top: 6),
          child: line,
        ),
      ),
    );
  }
}

/// **Taşmaya karşı sertleştirildi.** Eski takvim özeti yazı ölçeği 1.6'da 6px,
/// 2.0'da 53px taşıyordu (ölçüldü). Buradaki her para satırı ya `FittedBox`
/// ile küçülür ya da `Flexible` + ellipsis ile kırpılır; kartın kendisi
/// yüksekliğine sabitlenmediği için ölçek büyüdükçe DİKEYDE uzar.
class TransactionSummaryStrip extends StatelessWidget {
  /// Dönem + filtre uygulanmış işlemler (ekranda görünen küme).
  final List<TransactionEntity> transactions;

  final FinanceMode mode;
  final CombinedFilter filter;

  /// Aktif dönemin insan-okur adı ("Eylül 2026"). Etikete eklenir ki
  /// rakamın hangi zamana ait olduğu kartın içinde de yazsın.
  final String periodLabel;

  /// Dönem bugünü KAPSAMIYORSA verilir; "Bugüne dön" düğmesi çıkar.
  final VoidCallback? onToday;

  /// Verilirse ↑gelir / ↓gider rakamları TÜR SEÇİCİ olur: dokunmak listeyi o
  /// türe daraltır, seçiliyken tekrar dokunmak tümüne döner. Üst çubuktaki
  /// ikon-yalnız segmentin (↗ ⇄ ↘) yerini aldı — rakamın kendisi zaten
  /// "gelirler"/"giderler" diyor.
  final ValueChanged<FinanceMode>? onModeChanged;

  /// Verilirse işlem sayısının yanında "tümünü daralt / genişlet" ikonu
  /// çizilir. Eskiden gün şeridinin altında kendi satırıydı (~40dp); ikon
  /// listenin özetinin yanında ek satır tutmadan durur.
  final VoidCallback? onToggleCollapseAll;

  /// Listelenen bütün günler kapalı mı (ikonun yönü ve etiketi).
  final bool allDaysCollapsed;

  /// Verilirse sayı satırında "Bakiye hattı" ikonu çizilir: liste
  /// görünümünden varsayılan görünüme dönüş. Bakiye hattı çizilemiyorken
  /// (arama/süzgeç etkin, tek günlük dönem) verilmez.
  final VoidCallback? onShowBalanceLine;

  const TransactionSummaryStrip({
    super.key,
    required this.transactions,
    required this.mode,
    required this.filter,
    required this.periodLabel,
    this.onToday,
    this.onModeChanged,
    this.onToggleCollapseAll,
    this.allDaysCollapsed = false,
    this.onShowBalanceLine,
    this.topCategories = const [],
    this.onOpenBreakdown,
  });

  /// Dönemde en çok harcanan kategoriler (en çok üç), payı büyükten küçüğe.
  ///
  /// "Param nereye gidiyor?" sorusunun yanıtı uygulamanın yeni kullanıcıya
  /// verdiği asıl şey; eskiden yalnız Rapor'un ikinci ekranındaydı (▤ → Rapor
  /// → kaydır) ve kullanıcı ona tesadüfen ulaşıyordu. Şerit bunu ana ekranda
  /// TEK SATIRLA söyler; ayrıntısı Rapor'dadır ([onOpenBreakdown]).
  ///
  /// Boşsa satır hiç kurulmaz (tek kategoride söylenecek bir şey yoktur).
  final List<TopCategoryShare> topCategories;

  /// Satıra dokununca: kategori dağılımının tamamı (Rapor).
  final VoidCallback? onOpenBreakdown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final currency = context.activeWalletCurrency;

    // Kuplaj hareketleri toplamların DIŞINDA — kural rapor sayfasında vardı,
    // burada YOKTU. Ölçüldü: nakitten bankaya 20.000 ₺ taşımak bu kartta
    // "Gider 20.000 ₺" yazdırıyor, bir kaydırma ötedeki rapor aynı dönem için
    // 0 diyordu; yan yana duran iki sayfanın farklı rakam söylemesi tek
    // başına bir hata. Ayrım yalnız "ne harcadım" sorusu içindir: LİSTE bu
    // satırları göstermeye devam eder, çünkü bakiye zinciri onlara dayanır.
    const service = TransactionReportService();
    final split = service.splitSystemMovements(transactions);
    final totals = service.calculateTotals(split.spending);
    final income = totals.totalIncome;
    final expense = totals.totalExpense;
    final net = totals.net;
    final systemCount = split.system.length;

    final hasActiveFilters = filter.dataFilter.hasActiveFilters;
    // Tek modda (yalnız gelir / yalnız gider) "net" kavramı yanıltıcı olur:
    // gösterilen rakam zaten o türün toplamıdır.
    final headline = switch (mode) {
      FinanceMode.income => income,
      FinanceMode.expense => expense,
      FinanceMode.compare => net,
    };
    final headlineLabel = switch (mode) {
      FinanceMode.income =>
        hasActiveFilters ? l10n.txSummaryIncomeFiltered : l10n.txSummaryIncome,
      FinanceMode.expense => hasActiveFilters
          ? l10n.txSummaryExpenseFiltered
          : l10n.txSummaryExpense,
      FinanceMode.compare =>
        hasActiveFilters ? l10n.txSummaryNetFiltered : l10n.txSummaryNet,
    };
    final brightness = Theme.of(context).brightness;
    final headlineColor = switch (mode) {
      FinanceMode.income => MoneyColors.incomeText(brightness),
      FinanceMode.expense => MoneyColors.expenseText(brightness),
      FinanceMode.compare =>
        net >= 0 ? scheme.onSurface : MoneyColors.expenseText(brightness),
    };

    return AppCard(
      section: AppSection.transactions,
      // Dönem özeti: listedeki nötr satırlardan ayrışan tek renkli zemin.
      emphasized: true,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _labelRow(context, headlineLabel, hasActiveFilters),
          const SizedBox(height: 1),
          // Tutar tek satırda kalmalı ama kırpılmamalı: yedi haneli tutar +
          // yazı ölçeği 2.0 birlikte 400dp'yi aşıyor, `scaleDown` orada
          // devreye girer.
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MoneyText(
                amount: headline,
                currency: currency,
                style: TextStyle(
                  color: headlineColor,
                  // Ölçekte 24 yok. 28 şeridi ~8dp uzatıp ilk defter satırını aşağı
                  // itiyordu (dikey bütçe testi); bir alt basamak.
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          _footerRow(context, income, expense, currency),
          if (topCategories.isNotEmpty)
            _TopCategoriesLine(items: topCategories, onTap: onOpenBreakdown),
          // Sessizce atmak yerine söylenir: 20.000 ₺'lik bir transferin
          // toplamdan düşmesi açıklanmazsa kullanıcı "giderim nereye gitti"
          // diye sorar. Rapor bunu bir anahtarla, içgörü bir dipnotla
          // söylüyordu; ana ekran hiç söylemiyordu.
          if (systemCount > 0) ...[
            const SizedBox(height: 4),
            _systemNote(context, systemCount),
          ],
        ],
      ),
    );
  }

  /// Dönemde toplamların dışında bırakılan kuplaj hareketi sayısı.
  ///
  /// l10n anahtarı içgörü sayfasıyla ORTAK: metin ("N para taşıma hareketi
  /// (transfer, borç, yatırım) sayılmadı") sayfaya değil kurala ait ve iki
  /// yerde ayrı cümle kurmak, aynı kuralın iki farklı adı olması demekti.
  ///
  /// Ekranda "kuplaj" GEÇMEZ: kod tarafının sözlüğü son kullanıcının sözlüğü
  /// değil. Kavramın kendisi (para harcanmadı, yer değiştirdi) parantezle
  /// örneklenir.
  Widget _systemNote(BuildContext context, int count) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.swap_horiz_rounded,
            size: 12, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            context.l10n.insightSystemMovementsNote(count),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.2,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _labelRow(BuildContext context, String label, bool filtered) {
    final scheme = Theme.of(context).colorScheme;
    final labelColor =
        filtered ? Colors.orangeAccent.shade200 : scheme.onSurfaceVariant;

    return Row(
      children: [
        if (filtered) ...[
          Icon(Icons.filter_alt_rounded, size: 12, color: labelColor),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            '$label · $periodLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (onToday != null) ...[
          const SizedBox(width: 8),
          _TodayButton(onTap: onToday!),
        ],
      ],
    );
  }

  Widget _footerRow(
    BuildContext context,
    double income,
    double expense,
    String currency,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.85);
    const footerStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);

    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _flow(context, true, income, currency, footerStyle),
                SizedBox(width: onModeChanged == null ? 14 : 8),
                _flow(context, false, expense, currency, footerStyle),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          context.l10n.countCountlabel(
            transactions.length,
            filter.dataFilter.hasActiveFilters
                ? context.l10n.txSummaryCountFiltered
                : context.l10n.txSummaryCount,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onShowBalanceLine != null)
          IconButton(
            key: const ValueKey('tx-show-line'),
            tooltip: context.l10n.blShowLine,
            onPressed: onShowBalanceLine,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            // Yükseklik daralt düğmesiyle aynı (satır büyümesin, bkz. altta);
            // dokunma hedefi genişlikten kazanılır — yanındaki düğmeyle
            // arasında boşluk da kalır, yanlış dokunuş azalır.
            style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 28),
            iconSize: 20,
            color: muted,
            icon: const Icon(Icons.show_chart_rounded),
          ),
        if (onToggleCollapseAll != null)
          IconButton(
            key: const ValueKey('tx-collapse-all'),
            tooltip: allDaysCollapsed
                ? context.l10n.txExpandAllDays
                : context.l10n.txCollapseAllDays,
            onPressed: onToggleCollapseAll,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            // Satır yüksekliğini BÜYÜTMESİN: varsayılan 48dp dokunma hedefi
            // özet kartını 104dp'ye çıkarıyordu.
            style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
            iconSize: 20,
            color: muted,
            icon: Icon(allDaysCollapsed
                ? Icons.unfold_more_rounded
                : Icons.unfold_less_rounded),
          ),
      ],
    );
  }

  Widget _flow(
    BuildContext context,
    bool isIncome,
    double amount,
    String currency,
    TextStyle style,
  ) {
    final brightness = Theme.of(context).brightness;
    final color = isIncome
        ? MoneyColors.incomeText(brightness)
        : MoneyColors.expenseText(brightness);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 3),
        MoneyText(
          amount: amount,
          currency: currency,
          style: style.copyWith(color: color),
        ),
      ],
    );
    final onModeChanged = this.onModeChanged;
    if (onModeChanged == null) return content;

    final target = isIncome ? FinanceMode.income : FinanceMode.expense;
    final selected = mode == target;
    return Semantics(
      button: true,
      selected: selected,
      label: target.label(context.l10n),
      child: Material(
        color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: color.withValues(alpha: selected ? 0.45 : 0.18),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onModeChanged(selected ? FinanceMode.compare : target),
          child: Padding(
            // Dikey dolgu bilerek dar: şerit ekranın ilk yarısında ve her dp
            // bir defter satırından çalınıyor (6dp'de ilk kart 12dp aşağı
            // iniyordu). Alternatif tam boy yol filtre sayfasındaki "Tür".
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Dönem bugünü kapsamadığında çıkan geri dönüş yolu.
///
/// Eskiden yoktu: altı ay geriye giden kullanıcı bugüne dönmek için oku altı
/// kez itmek ya da tarih seçiciyi açmak zorundaydı.
class _TodayButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TodayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = AppGradients.transactions;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.today_rounded, size: 13, color: accent),
              const SizedBox(width: 5),
              Text(
                context.l10n.txTodayJump,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
