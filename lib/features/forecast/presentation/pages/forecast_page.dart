import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
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
import 'package:cunehat/features/forecast/domain/forecast_horizon.dart';
import 'package:cunehat/features/forecast/presentation/bloc/forecast_cubit.dart';
import 'package:cunehat/features/forecast/presentation/bloc/forecast_estimates_cubit.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_estimates_switch.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_sections.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_timeline_card.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
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
/// Tahmin bildiriminden açılınca tahmin o açılış için görünür (bkz.
/// [ForecastCubit.reveal]).
///
/// Yalnız aktif cüzdan: "Tüm cüzdanlar" tahmini sonraki sürümün tüm cüzdan
/// raporunda (birleştirici hazır, bkz. `combineForecasts`). Başka cüzdanın
/// bildirimi o cüzdana geçip açar (bkz. `HomeNavigationRequests.openForecast`).
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
        walletId: walletId,
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
        // Ayarlar'da dönem birimi değişince ufuk bayat kalmasın — süzgeç
        // özel bir aralıktayken durumu değişmez, bu yüzden ayrı akış.
        horizonChanges: filter.periodPreferencesChanges,
      ).._start(),
      child: ForecastView(walletId: walletId),
    );
  }
}

extension on ForecastCubit {
  /// İlk yükleme; bildirimden açılıştaysa tahmin görünür ve ufuk bildirimin
  /// gününe uzamış olarak (tek yükleme).
  void _start() {
    final focus = getIt.isRegistered<HomeNavigationRequests>()
        ? getIt<HomeNavigationRequests>().takeForecastFocus()
        : null;
    focus == null ? load() : reveal(until: focus.day);
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
  HomeNavigationRequests? _requests;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Sayfa zaten açıkken gelen tahmin bildirimi (kurulurken gelen istek
    // ForecastPage'de alınır).
    if (getIt.isRegistered<HomeNavigationRequests>()) {
      _requests = getIt<HomeNavigationRequests>()
        ..forecastFocus.addListener(_onFocusRequest);
    }
  }

  @override
  void dispose() {
    _requests?.forecastFocus.removeListener(_onFocusRequest);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onFocusRequest() {
    final focus = _requests?.takeForecastFocus();
    if (focus == null || !mounted) return;
    context.read<ForecastCubit>().reveal(until: focus.day);
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
    // Bildirimden açılış tahmini bu ziyaret için gösterir; kalıcı ayar
    // değişmez.
    final setting = context.forecastEstimates;
    final estimates = widget.estimates ?? (setting || state.revealed);
    final visible = context.amountsVisible;
    final money = MoneyWriter(currency: f.currency, visible: visible);
    final labels = buildCategoryLabelMap(state.categories);
    final horizonEnd = state.horizonEnd ??
        (f.path.isEmpty
            ? today
            : DateTime(f.path.last.day.year, f.path.last.day.month,
                f.path.last.day.day));
    final horizonDays = f.path.isEmpty ? 0 : f.path.length - 1;

    // Kartlar: kartın kendisi ya da bu hesaba bağlı olanlar (kart başka bir
    // birimde olabilir).
    final cardWallets = [
      for (final w in state.wallets.values)
        if (w.card != null &&
            (w.walletId == f.walletId || w.card!.paymentWalletId == f.walletId))
          w,
    ];
    final cards = <(String, CardOutlook)>[
      for (final w in cardWallets) (w.walletName, w.card!),
    ];
    final currencies = {for (final w in cardWallets) w.walletId: w.currency};
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
        ForecastEstimatesSwitch(
          value: estimates,
          temporary: state.revealed && !setting,
          onChanged: (on) {
            if (!on) context.read<ForecastCubit>().endReveal();
            context.read<ForecastEstimatesCubit>().set(on);
          },
        ),
        const SizedBox(height: 8),
        if (estimates && f.pace == null && !f.isCard) ...[
          AnalysisEmptyCard(
            key: const ValueKey('forecast-no-pace'),
            icon: Icons.hourglass_bottom_rounded,
            title: l10n.forecastNoPaceTitle,
            lines: [l10n.forecastNoPaceBody(f.daysUntilPace)],
          ),
          const SizedBox(height: 12),
        ],
        ForecastTimelineCard(
          forecast: f,
          money: money,
          today: today,
          horizonEnd: horizonEnd,
          estimates: estimates,
        ),
        if (f.period != null && !f.isCard)
          section(
            l10n.forecastPeriodTitle,
            ForecastPeriodCard(
              period: f.period!,
              money: money,
              hasPace: f.pace != null,
              estimates: estimates,
            ),
          ),
        if (budgets.isNotEmpty)
          section(
            l10n.forecastBudgetsTitle,
            ForecastBudgetsCard(
              budgets: budgets,
              money: money,
              today: today,
              categoryLabels: labels,
              estimates: estimates,
            ),
          ),
        section(
          l10n.forecastUpcomingTitle,
          ForecastUpcomingCard(
            events: f.events,
            overdue: f.overdue,
            money: money,
            today: today,
            horizonEnd: horizonEnd,
            estimates: estimates,
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
        if (f.goals.isNotEmpty)
          section(
            l10n.forecastGoalsTitle,
            ForecastGoalsCard(
              goals: f.goals,
              money: money,
              estimates: estimates,
            ),
          ),
      ],
    );
  }
}
