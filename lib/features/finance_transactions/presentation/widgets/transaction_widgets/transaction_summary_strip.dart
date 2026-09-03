import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/core/utils/tr_case.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
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

  const TransactionSummaryStrip({
    super.key,
    required this.transactions,
    required this.mode,
    required this.filter,
    required this.periodLabel,
    this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final currency = context.activeWalletCurrency;

    double income = 0, expense = 0;
    for (final t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else if (t.isExpense) {
        expense += t.amount;
      }
    }
    final net = income - expense;

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
    final headlineColor = switch (mode) {
      FinanceMode.income => AppGradients.savings,
      FinanceMode.expense => AppGradients.debt,
      FinanceMode.compare => net >= 0 ? scheme.onSurface : AppGradients.debt,
    };

    return AppCard(
      section: AppSection.transactions,
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
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          _footerRow(context, income, expense, currency),
        ],
      ),
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
            '$label · ${upperTr(periodLabel)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
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
    const footerStyle = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700);

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
                const SizedBox(width: 14),
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
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
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
    final color = isIncome ? AppGradients.savings : AppGradients.debt;
    return Row(
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
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
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
