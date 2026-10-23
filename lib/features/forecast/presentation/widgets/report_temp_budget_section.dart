import 'dart:async';

import 'package:cunehat/config/theme/app_tokens.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_section_header.dart';
import 'package:cunehat/features/forecast/data/forecast_service.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_sections.dart';
import 'package:flutter/material.dart';

/// Rapor'daki "Tek seferlik bütçeler" kartı: seçili dönemle KESİŞEN geçici
/// bütçeler — biten sonucuyla, süren tahminiyle ("bu hızla 24 Kas'ta
/// dolar"), yaklaşan "bu hızla ne harcanır" diye.
///
/// Sayılar Gelecek sayfasıyla AYNI kaynaktan ([ForecastService]) gelir; iki
/// yüzey aynı bütçe için farklı tahmin yazmasın.
class ReportTempBudgetSection extends StatefulWidget {
  final String userId;
  final String walletId;

  /// Rapor'un seçili dönemi — kesişim buna göre.
  final DateTimeRange range;

  /// Tahminin dönemi (kullanıcının biriminde içinde bulunulan dönem).
  final DateTimeRange Function() periodOf;

  /// Satıra dokunulunca: bütçe ve saydığı kategori kümesi (alt kategoriler
  /// dahil).
  final void Function(BudgetOutlook outlook, Set<String> tags) onTap;

  final ForecastService service;
  final TransactionsChangedNotifier? transactions;
  final BudgetsChangedNotifier? budgets;

  /// Testler için sabit gün.
  final DateTime? today;

  const ReportTempBudgetSection({
    super.key,
    required this.userId,
    required this.walletId,
    required this.range,
    required this.periodOf,
    required this.onTap,
    required this.service,
    this.transactions,
    this.budgets,
    this.today,
  });

  @override
  State<ReportTempBudgetSection> createState() =>
      _ReportTempBudgetSectionState();
}

class _ReportTempBudgetSectionState extends State<ReportTempBudgetSection> {
  ForecastResult? _result;
  final _subs = <StreamSubscription<Object?>>[];
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
    final tx = widget.transactions;
    if (tx != null) _subs.add(tx.stream.listen((_) => _load()));
    final b = widget.budgets;
    if (b != null) _subs.add(b.stream.listen((_) => _load()));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final gen = ++_generation;
    try {
      final result = await widget.service.forecast(
        userId: widget.userId,
        period: widget.periodOf(),
        today: widget.today,
        walletId: widget.walletId,
      );
      if (!mounted || gen != _generation) return;
      setState(() => _result = result);
    } catch (e, st) {
      reportError('Rapor · tek seferlik bütçe tahmini', e, st);
    }
  }

  bool _overlaps(BudgetOutlook o) {
    final s = DateTime(widget.range.start.year, widget.range.start.month,
        widget.range.start.day);
    final e = DateTime(
        widget.range.end.year, widget.range.end.month, widget.range.end.day);
    return !o.periodEnd.isBefore(s) && !o.periodStart.isAfter(e);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final f = result?.wallets[widget.walletId];
    if (result == null || f == null) return const SizedBox.shrink();
    final order = {
      BudgetOutlookStatus.over: 0,
      BudgetOutlookStatus.atRisk: 0,
      BudgetOutlookStatus.onTrack: 0,
      BudgetOutlookStatus.upcoming: 1,
      BudgetOutlookStatus.finished: 2,
    };
    final temps = [
      for (final b in f.budgets)
        if (b.isTemp && _overlaps(b)) b,
    ]..sort((a, b) {
        final c = order[a.status]!.compareTo(order[b.status]!);
        return c != 0 ? c : a.periodStart.compareTo(b.periodStart);
      });
    if (temps.isEmpty) return const SizedBox.shrink();

    final now = widget.today ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final money = MoneyWriter.of(context);

    return Column(
      key: const ValueKey('report-temp-budgets'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        ReportSectionHeader(title: context.l10n.tempBudgetSectionTitle),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            children: [
              for (var i = 0; i < temps.length; i++) ...[
                if (i > 0) const Divider(height: 12),
                InkWell(
                  key: ValueKey('report-temp-budget-${temps[i].id}'),
                  borderRadius: AppRadius.controlAll,
                  onTap: () => widget.onTap(temps[i], {
                    for (final r in temps[i].temp!.categoryIds)
                      ...subtreeIds(r, result.categories),
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: BudgetOutlookRow(
                      outlook: temps[i],
                      money: money,
                      today: today,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
