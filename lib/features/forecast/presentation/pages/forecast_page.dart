import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/features/credit_card/presentation/card_context_rail.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/analysis_empty_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_section_header.dart';
import 'package:cunehat/features/forecast/data/forecast_service.dart';
import 'package:cunehat/features/forecast/domain/forecast_combiner.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/forecast/domain/forecast_horizon.dart';
import 'package:cunehat/features/forecast/presentation/bloc/forecast_cubit.dart';
import 'package:cunehat/features/forecast/presentation/bloc/forecast_estimates_cubit.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_estimates_switch.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_sections.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_timeline_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Gelecek" — İşlemler · İçgörü · Rapor yığınının dördüncü yüzü.
///
/// Rol ayrımı: Rapor "ne oldu", İçgörü "şimdi ne yapmalıyım", Gelecek
/// "önümüzde ne var". Sayfa dönem seçicisi TAŞIMAZ: hep bugünden ileriye
/// bakar; ufuk kullanıcının dönem biriminin sonudur (maaş günü dahil, bkz.
/// [forecastHorizonEnd]).
///
/// İki katman: PLAN (varsayılan) yalnız kesin kalemleri tarihleriyle
/// gösterir; TAHMİN anahtarı hızdan gelen kısmı MOR olarak üstüne ekler.
class ForecastPage extends StatelessWidget {
  final String userId;
  final String walletId;

  const ForecastPage({super.key, required this.userId, required this.walletId});

  @override
  Widget build(BuildContext context) {
    final filter = context.read<TransactionFilterCubit>();
    return BlocProvider(
      create: (_) => ForecastCubit(
        getIt<ForecastService>(),
        userId: userId,
        periodOf: () =>
            filter.periodPreferences.periodContaining(DateTime.now()),
        previousPeriodOf: () {
          final current =
              filter.periodPreferences.periodContaining(DateTime.now());
          final dayBefore = DateTime(
              current.start.year, current.start.month, current.start.day - 1);
          return filter.periodPreferences.periodContaining(dayBefore);
        },
        // `basePeriod()` DEĞİL: kart bağlamında ekstre döngüsünü döner.
        horizonEndOf: (today) =>
            forecastHorizonEnd(filter.periodPreferences, today),
        transactions: getIt<TransactionsChangedNotifier>(),
        budgets: getIt<BudgetsChangedNotifier>(),
      )..load(),
      // Ayarlar'da dönem birimi değişince ufuk bayat kalmasın.
      child: BlocListener<TransactionFilterCubit, CombinedFilter>(
        listener: (context, _) =>
            context.read<ForecastCubit>().refreshIfStale(),
        child: ForecastView(walletId: walletId),
      ),
    );
  }
}

/// Sayfanın gövdesi (cubit dışarıdan sağlanır — testler doğrudan kurar).
class ForecastView extends StatefulWidget {
  final String walletId;

  /// Testler için sabit gün.
  final DateTime? today;

  /// Tahmin katmanı; verilmezse uygulama ayarından
  /// ([ForecastEstimatesContext.forecastEstimates]).
  final bool? estimates;

  const ForecastView(
      {super.key, required this.walletId, this.today, this.estimates});

  @override
  State<ForecastView> createState() => _ForecastViewState();
}

class _ForecastViewState extends State<ForecastView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Uygulamaya dönüşte (ertesi sabah) dünün tahmini gösterilmesin.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ForecastCubit>().refreshIfStale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CardContextRail(pillsOnly: true),
          Expanded(
            child: BlocBuilder<ForecastCubit, ForecastState>(
              builder: (context, state) {
                final f = state.wallets[widget.walletId];
                if (f == null) {
                  if (state.status == ForecastStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _failed(context);
                }
                return RefreshIndicator(
                  onRefresh: context.read<ForecastCubit>().load,
                  child: _content(context, state, f),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _failed(BuildContext context) => RefreshIndicator(
        onRefresh: context.read<ForecastCubit>().load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(context.l10n.forecastLoadFailed, textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _content(BuildContext context, ForecastState state, WalletForecast f) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = widget.today ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final estimates = widget.estimates ?? context.forecastEstimates;
    final visible = context.amountsVisible;
    final money = MoneyWriter(currency: f.currency, visible: visible);
    final labels = buildCategoryLabelMap(state.categories);
    final horizonEnd = state.horizonEnd ??
        (f.path.isEmpty
            ? today
            : DateTime(f.path.last.day.year, f.path.last.day.month,
                f.path.last.day.day));
    final horizonDays = f.path.isEmpty ? 0 : f.path.length - 1;
    final all = state.scope == ForecastScope.all && state.wallets.length > 1;

    // Birleşik görünüm: toplamlar aktif cüzdanın biriminde.
    final combined = all
        ? combineForecasts(state.wallets.values,
            currency: f.currency, rates: state.rates)
        : null;
    final view = combined?.asWalletForecast() ?? f;
    final scopeWallets = combined?.included ?? [f];
    final names = {
      for (final w in state.wallets.values) w.walletId: w.walletName
    };
    final currencies = {
      for (final w in state.wallets.values) w.walletId: w.currency,
    };
    // Birleşik görünümde olaylar KENDİ biriminde: grafik ve sayılar için
    // görüntü birimine çevrilir.
    double rateOf(ForecastEvent e) {
      final c = currencies[e.walletId] ?? f.currency;
      return c == f.currency ? 1 : (state.rates[c] ?? 1);
    }

    // Kartlar: bu hesaba bağlı olanlar ya da kartın kendisi; birleşikte hepsi.
    final cards = <(String, CardOutlook)>[
      for (final w in all ? scopeWallets : state.wallets.values)
        if (w.card != null &&
            (all ||
                w.walletId == f.walletId ||
                w.card!.paymentWalletId == f.walletId))
          (w.walletName, w.card!),
    ];
    // Gelecek ileriye bakar: bitmiş geçici bütçenin sonucu Rapor'da.
    List<BudgetOutlook> openBudgets(WalletForecast w) => [
          for (final b in w.budgets)
            if (b.status != BudgetOutlookStatus.finished) b,
        ];
    final budgetGroups = [
      for (final w in scopeWallets)
        if (openBudgets(w).isNotEmpty) (w, openBudgets(w)),
    ];
    final goals = [
      for (final w in scopeWallets) ...w.goals,
    ];

    Widget section(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReportSectionHeader(title: title),
              const SizedBox(height: 12),
              child,
            ],
          ),
        );

    MoneyWriter moneyOf(String walletId) => MoneyWriter(
        currency: currencies[walletId] ?? f.currency, visible: visible);

    return ListView(
      key: const ValueKey('forecast-list'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: ReportSectionHeader(
                  title: l10n.forecastHorizonUntilDays(
                      AppFormatters.dayMonth.format(horizonEnd), horizonDays)),
            ),
            IconButton(
              key: const ValueKey('forecast-how'),
              tooltip: l10n.forecastHowTitle,
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () =>
                  showForecastExplanation(context, forecast: f, money: money),
            ),
          ],
        ),
        const ForecastEstimatesSwitch(),
        if (state.wallets.length > 1) ...[
          const SizedBox(height: 4),
          SegmentedButton<ForecastScope>(
            key: const ValueKey('forecast-scope'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ForecastScope.wallet,
                label: Text(l10n.forecastScopeWallet),
              ),
              ButtonSegment(
                value: ForecastScope.all,
                label: Text(l10n.forecastScopeAll),
              ),
            ],
            selected: {state.scope},
            onSelectionChanged: (s) => context
                .read<ForecastCubit>()
                .setScope(s.first, currency: f.currency),
          ),
        ],
        if (combined != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.forecastAllCurrencyNote(f.currency),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (combined.excluded.isNotEmpty)
            Text(
              l10n.forecastExcludedWallets(
                  combined.excluded.map((w) => w.walletName).join(', ')),
              key: const ValueKey('forecast-excluded'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: MoneyColors.expenseText(theme.brightness)),
            ),
        ],
        const SizedBox(height: 8),
        if (estimates && f.pace == null && !f.isCard && combined == null) ...[
          AnalysisEmptyCard(
            key: const ValueKey('forecast-no-pace'),
            icon: Icons.hourglass_bottom_rounded,
            title: l10n.forecastNoPaceTitle,
            lines: [l10n.forecastNoPaceBody(f.daysUntilPace)],
          ),
          const SizedBox(height: 12),
        ],
        ForecastTimelineCard(
          forecast: view,
          money: money,
          today: today,
          horizonEnd: horizonEnd,
          estimates: estimates,
          showBand: combined?.hasPace,
          rateOf: rateOf,
          walletNames: all ? names : const {},
          currencyOf: all ? currencies : const {},
        ),
        if (view.period != null && !view.isCard)
          section(
            l10n.forecastPeriodTitle,
            ForecastPeriodCard(
              period: view.period!,
              money: money,
              hasPace: combined?.hasPace ?? f.pace != null,
              estimates: estimates,
            ),
          ),
        if (budgetGroups.isNotEmpty)
          section(
            l10n.forecastBudgetsTitle,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (w, budgets) in budgetGroups) ...[
                  if (all)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                      child: Text(w.walletName,
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ForecastBudgetsCard(
                    budgets: budgets,
                    money: moneyOf(w.walletId),
                    today: today,
                    categoryLabels: labels,
                    estimates: estimates,
                  ),
                  if (all) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        section(
          l10n.forecastUpcomingTitle,
          ForecastUpcomingCard(
            events: view.events,
            overdue: view.overdue,
            money: money,
            today: today,
            horizonEnd: horizonEnd,
            estimates: estimates,
            walletNames: all ? names : const {},
            currencyOf: all ? currencies : const {},
          ),
        ),
        if (cards.isNotEmpty)
          section(
            l10n.forecastCardsTitle,
            ForecastCardsCard(
              cards: cards,
              money: money,
              today: today,
              estimates: estimates,
              currencyOf: currencies,
            ),
          ),
        if (goals.isNotEmpty)
          section(
            l10n.forecastGoalsTitle,
            ForecastGoalsCard(
              goals: goals,
              money: money,
              estimates: estimates,
              currencyOf: currencies,
            ),
          ),
      ],
    );
  }
}
