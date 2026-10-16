import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/features/credit_card/presentation/card_context_rail.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/analysis_empty_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_section_header.dart';
import 'package:cunehat/features/forecast/data/forecast_service.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/forecast/presentation/bloc/forecast_cubit.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_path_card.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "Gelecek" — İşlemler · İçgörü · Rapor yığınının dördüncü yüzü.
///
/// Rol ayrımı: Rapor "ne oldu", İçgörü "şimdi ne yapmalıyım", Gelecek
/// "bu gidişle ne olacak". Sayfa dönem seçicisi TAŞIMAZ: tahmin hep bugünden
/// ileriye bakar; dönem sonu kartı kullanıcının dönem biriminde (maaş günü
/// dahil) içinde bulunulan dönemi kullanır.
class ForecastPage extends StatelessWidget {
  final String userId;
  final String walletId;

  /// Bakiye yolculuğunun ufku.
  static const int horizonDays = 30;

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
        transactions: getIt<TransactionsChangedNotifier>(),
        budgets: getIt<BudgetsChangedNotifier>(),
      )..load(),
      child: ForecastView(walletId: walletId),
    );
  }
}

/// Sayfanın gövdesi (cubit dışarıdan sağlanır — testler doğrudan kurar).
class ForecastView extends StatefulWidget {
  final String walletId;

  /// Testler için sabit gün.
  final DateTime? today;

  const ForecastView({super.key, required this.walletId, this.today});

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
    final now = widget.today ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final money =
        MoneyWriter(currency: f.currency, visible: context.amountsVisible);
    final labels = buildCategoryLabelMap(state.categories);
    const horizon = ForecastPage.horizonDays;

    // Bu hesaba bağlı kartlar (ödeme bu hesaptan çıkıyor) ya da kartın
    // kendisi.
    final cards = <(String, CardOutlook)>[
      for (final w in state.wallets.values)
        if (w.card != null &&
            (w.walletId == f.walletId || w.card!.paymentWalletId == f.walletId))
          (w.walletName, w.card!),
    ];
    // Gelecek ileriye bakar: bitmiş geçici bütçenin sonucu Rapor'da.
    final budgets = [
      for (final b in f.budgets)
        if (b.status != BudgetOutlookStatus.finished) b,
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

    return ListView(
      key: const ValueKey('forecast-list'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: ReportSectionHeader(
                  title: l10n.forecastHorizonCaption(horizon)),
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
        const SizedBox(height: 8),
        if (f.pace == null && !f.isCard) ...[
          AnalysisEmptyCard(
            key: const ValueKey('forecast-no-pace'),
            icon: Icons.hourglass_bottom_rounded,
            title: l10n.forecastNoPaceTitle,
            lines: [l10n.forecastNoPaceBody(f.daysUntilPace)],
          ),
          const SizedBox(height: 12),
        ],
        ForecastPathCard(
          forecast: f,
          money: money,
          today: today,
          horizonDays: horizon,
        ),
        if (f.period != null && !f.isCard)
          section(
            l10n.forecastPeriodTitle,
            ForecastPeriodCard(
                period: f.period!, money: money, hasPace: f.pace != null),
          ),
        if (budgets.isNotEmpty)
          section(
            l10n.forecastBudgetsTitle,
            ForecastBudgetsCard(
              budgets: budgets,
              money: money,
              today: today,
              categoryLabels: labels,
            ),
          ),
        section(
          l10n.forecastUpcomingTitle,
          ForecastUpcomingCard(
            events: f.events,
            overdue: f.overdue,
            money: money,
            today: today,
            horizonDays: horizon,
          ),
        ),
        if (cards.isNotEmpty)
          section(
            l10n.forecastCardsTitle,
            ForecastCardsCard(cards: cards, money: money, today: today),
          ),
        if (f.goals.isNotEmpty)
          section(
            l10n.forecastGoalsTitle,
            ForecastGoalsCard(goals: f.goals, money: money),
          ),
      ],
    );
  }
}
