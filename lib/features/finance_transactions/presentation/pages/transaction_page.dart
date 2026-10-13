import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/utils/first_record_moment.dart';
import 'package:cunehat/core/shared/widgets/empty_state.dart';
import 'package:cunehat/features/main_feature/utils/section_visibility.dart';
import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:cunehat/core/shared/motion/period_transition.dart';
import 'dart:async';
import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
import 'dart:math' as math;

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/messaging/deletion_undo_message.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/shared/widgets/app_date_range_picker.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_picker_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/ledger_selection.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/daily_spending_summary_service.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/finance_transactions/presentation/transaction_filtering.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/filter_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/detailed_list_view.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_day_rail.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_list_skeleton.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/shared_period.dart';
import 'package:cunehat/features/credit_card/presentation/card_context_rail.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_summary_strip.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_top_bar.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// İşlemler ekranı — uygulamanın açılış yüzü.
///
/// **Tek akış (3 Eyl 2026).** Ekran eskiden Liste ve Takvim diye iki
/// görünümdü ve varsayılanı takvimdi. Ölçüm (360×800, kabuk düşülmüş 630dp)
/// şunu gösterdi: takvim kartı 374dp kaplıyor, bir güne dokununca o günün
/// yalnız 1 işlemi görünüyor, ızgaradaki tek finansal veri 8,5px çiziliyordu.
/// Liste tarafında da ilk satıra kadar 309/630 dp (%49) chrome'a gidiyordu.
/// Yani ekran "hangi gün?" sorusunu cevaplıyordu; kullanıcı ise buraya "ne
/// aldım, param nereye gidiyor" diye bakıyor — üstelik analitiğin ağır işi
/// zaten bir kaydırma ötede (İçgörü + Rapor alt görünümleri).
///
/// Yeni sıra: sabit kontrol çubuğu → arama → dönem özeti → gün şeridi →
/// yapışkan gün başlıklı defter. Takvim ızgarası dönem SEÇİCİ olarak duruyor
/// ([AppDateRangePicker], üst çubuktaki tarihe dokununca).
class TransactionsPage extends StatelessWidget {
  final String userId;
  final WalletEntity wallet;

  const TransactionsPage({
    super.key,
    required this.userId,
    required this.wallet,
  });

  /// Süzgeç (dönem dahil) bu sayfaya ait DEĞİL: uygulama düzeyindeki
  /// [TransactionFilterCubit]'i İçgörü ve Rapor ile paylaşır (bkz.
  /// `shared_period.dart`). Eskiden burada sayfa-yerel bir örnek kuruluyordu
  /// ve uygulama düzeyindeki örneği okuyan hiç kimse yoktu.
  @override
  Widget build(BuildContext context) {
    return _TransactionsView(
      userId: userId,
      wallet: wallet,
    );
  }
}

class _TransactionsView extends StatefulWidget {
  final String userId;
  final WalletEntity wallet;

  const _TransactionsView({
    required this.userId,
    required this.wallet,
  });

  @override
  State<_TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends State<_TransactionsView> {
  /// Kategori kimliği (tag) → ikon. İşlem kartlarında gerçek kategori glyph'i
  /// için.
  Map<String, IconData> _categoryIcons = {};

  /// `tag` → görünen ad; kart/liste gösterimi ve ARAMA bunu kullanır
  /// (kullanıcı "market" yazınca başlığı "ŞOK 4712" olan satır da gelmeli).
  /// Gruplama ve filtre anahtarı hep `tag` kalır.
  Map<String, String> _categoryLabels = {};

  /// `id → kök id`: şeritteki "en çok" satırı KÖK seviyede toplar (Rapor'un
  /// kategori dağılımıyla aynı kırılım).
  Map<String, String> _categoryRoots = const {};

  StreamSubscription<void>? _categoriesSub;

  final ScrollController _scrollController = ScrollController();

  /// Gün şeridinden listeye giden köprü: başlıkların GlobalKey defteri.
  final LedgerDayAnchors _anchors = LedgerDayAnchors();

  /// Hangi günlerin kapalı olduğu — "tümünü daralt / genişlet" düğmesi ile
  /// defter arasında paylaşılır.
  final LedgerCollapseController _collapse = LedgerCollapseController();

  /// Çoklu seçim (bkz. [LedgerSelection]): seçili satırların kategorisi
  /// topluca değiştirilir.
  final LedgerSelection _selection = LedgerSelection();

  /// Şeritte vurgulanan gün. Yalnız gezinme durumu — filtreye yazılmaz,
  /// çünkü bir güne bakmak dönemi daraltmak DEĞİLDİR (eski takvimde bir
  /// sayfa kaydırmak kullanıcının seçtiği yıllık dönemi tek aya düşürüyordu).
  DateTime? _selectedDay;

  /// Defter önbelleği: sıralama + running balance zinciri PAHALI ve yalnız
  /// işlem listesi değişince gerekir. Filtre/arama her tuş vuruşunda
  /// değiştiği için bunu her build'de kurmak listeyi tuş başına yeniden
  /// sıralamak demekti.
  List<TransactionEntity>? _ledgerSource;
  double? _ledgerBalance;
  List<TransactionWithBalance> _ledger = const [];

  /// Gün şeridinin ısı verisi; görünen küme değişmedikçe yeniden kurulmaz.
  static const _summaryService = DailySpendingSummaryService();
  List<TransactionWithBalance>? _summarySource;
  Map<DateTime, DaySummary> _summaries = const {};

  @override
  void initState() {
    super.initState();
    applyStoredPeriodPreferences(context.read<TransactionFilterCubit>());
    context.read<TransactionFilterCubit>().bindWallet(widget.wallet.id);
    _syncStatementCycle();
    // Dışarıdan istenen dönem (ekstre içe aktarımı "Eklenenleri göster");
    // sayfa isteğe göre sonradan kurulduysa burada, zaten açıksa
    // dinleyicide uygulanır.
    _applyRequestedPeriod();
    if (getIt.isRegistered<HomeNavigationRequests>()) {
      getIt<HomeNavigationRequests>().addListener(_applyRequestedPeriod);
    }
    _loadData();
    _loadCategoryIcons();
    _categoriesSub = getIt<CategoriesChangedNotifier>()
        .stream
        .listen((_) => _loadCategoryIcons());
  }

  /// Dönemin giderinde en büyük payı alan (en çok üç) kök kategori.
  ///
  /// Kırılım burada YENİDEN yazılmaz: evren ve gruplama Rapor'unkiyle aynı
  /// işlevlerden gelir (sistem hareketleri hariç, kök seviyede) — iki yerde
  /// hesaplanan kırılım daha önce iki ayrı yanıt vermişti.
  ///
  /// Tek kategoride boş döner: "Market %100" bir şey söylemez.
  List<TopCategoryShare> _topCategories(List<TransactionEntity> visible) {
    final spending = ReportCategoryDataBuilder.universeOf(
      visible,
      includeSystemMovements: false,
    );
    final breakdown = const TransactionReportService().buildCategoryBreakdown(
      spending,
      isExpense: true,
      rootIndex: _categoryRoots,
    );
    final total = breakdown.fold<double>(0, (sum, b) => sum + b.totalAmount);
    if (breakdown.length < 2 || total <= 0) return const [];
    return [
      for (final b in breakdown.take(3))
        (
          label: _categoryLabels[b.name] ?? b.name,
          share: b.totalAmount / total,
        ),
    ];
  }

  /// Kategori ikon+ad indeksini yükler ve kategoriler değiştikçe TAZELER.
  ///
  /// Harita eskiden yalnız initState'te kuruluyordu: sayfa route yığınında
  /// dururken yapılan bir yeniden adlandırma ancak sayfa yeniden kurulduğunda
  /// görünüyordu.
  Future<void> _loadCategoryIcons() async {
    // Kategori deposu `Either` DEĞİL, EXCEPTION fırlatır (CacheException) —
    // bkz. `GetBudgetsUsecase`'teki aynı not. Yakalanmazsa bu, yakalanmamış
    // bir asenkron hataya dönüyor ve indeks BOŞ kalıyordu: `rootIdOf` her
    // tag'i kendi kökü sayar, yani kırılım YAPRAK seviyeye düşer ("%3 → Diğer"
    // kovası ve ilk-N kesimi değişir) ve etiketler ham UUID olarak yazılır.
    // Hata hâlinde ÖNCEKİ indeks korunur: yenileme sırasındaki geçici bir
    // okuma hatası, çalışan bir haritayı silmemeli.
    final List<CategoryEntity> categories;
    try {
      categories = await fetchAllCategories(getIt<CategoryRepository>());
    } catch (e, st) {
      reportError('İşlemler · kategori indeksi', e, st);
      return;
    }
    if (!mounted) return;
    final index = buildCategoryDisplayIndex(categories);
    setState(() {
      _categoryIcons = index.icons;
      _categoryLabels = index.labels;
      _categoryRoots = index.roots;
    });
  }

  /// Bekleyen dönem isteğini bu sayfanın süzgecine uygular (bkz.
  /// [HomeNavigationRequests]). Özel bir aralık kart bağlamına geçişte
  /// korunur (`useStatementCycle` yalnız varsayılan dönemi değiştirir).
  void _applyRequestedPeriod() {
    if (!mounted || !getIt.isRegistered<HomeNavigationRequests>()) return;
    final period = getIt<HomeNavigationRequests>().takePeriod();
    if (period != null) {
      context.read<TransactionFilterCubit>().setPeriod(period);
    }
  }

  @override
  void dispose() {
    if (getIt.isRegistered<HomeNavigationRequests>()) {
      getIt<HomeNavigationRequests>().removeListener(_applyRequestedPeriod);
    }
    _categoriesSub?.cancel();
    _collapse.dispose();
    _selection.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Seçili işlemlerin kategorisini topluca değiştirir.
  ///
  /// Kategori tek bir türe aittir: seçim gider + gelir karışıksa seçici tür
  /// değiştirmeye izin verir ve kategori YALNIZ kendi türündeki satırlara
  /// uygulanır; kaç satırın değişmeyeceği onaydan ÖNCE yazar.
  Future<void> _recategorizeSelected(List<TransactionEntity> all) async {
    final rows = [
      for (final t in all)
        if (_selection.contains(t.id)) t,
    ];
    if (rows.isEmpty) {
      _selection.clear();
      return;
    }
    final hasExpense = rows.any((t) => t.isExpense);
    final hasIncome = rows.any((t) => t.isIncome);
    final picked = await showCategoryPickerSheet(
      context: context,
      isExpense: hasExpense,
      walletId: widget.wallet.id ?? '',
      allowTypeSwitch: hasExpense && hasIncome,
    );
    if (picked == null || !mounted) return;

    final l10n = context.l10n;
    final matching = [
      for (final t in rows)
        if (t.isExpense == picked.isExpense) t,
    ];
    final skipped = rows.length - matching.length;
    if (matching.isEmpty) {
      AppMessenger.info(l10n.topluKategoriAtlanan(skipped));
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title: l10n.topluKategoriOnayBaslik,
      message: [
        l10n.topluKategoriOnayMesaj(matching.length, picked.name),
        if (skipped > 0) l10n.topluKategoriAtlanan(skipped),
      ].join('\n\n'),
      // Kısa etiket: onay diyaloğunun düğme satırı dar ekranda taşmasın.
      confirmText: l10n.degistir,
    );
    if (!confirmed || !mounted) return;

    context.read<TransactionBloc>().add(ChangeTransactionsCategoryEvent(
          transactions: matching,
          categoryId: picked.id,
        ));
    _selection.clear();
  }

  @override
  void didUpdateWidget(covariant _TransactionsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallet.id != widget.wallet.id) {
      context.read<TransactionFilterCubit>().bindWallet(widget.wallet.id);
      // Seçim başka bir cüzdanın satırlarına aitti.
      _selection.clear();
      _loadData();
    }
    if (oldWidget.wallet.id != widget.wallet.id ||
        oldWidget.wallet.creditCard != widget.wallet.creditCard) {
      _syncStatementCycle();
    }
  }

  /// Her zaman cüzdanın TAM geçmişini çeker; dönem dahil tüm filtreler
  /// bellekte uygulanır. Böylece running balance çapası (güncel bakiye)
  /// hiçbir aralıkta yanlış düşmez.
  void _loadData() {
    context.read<TransactionBloc>().add(GetTransactionsEvent(
          userId: widget.userId,
          walletId: widget.wallet.id ?? '',
        ));
  }

  /// Cüzdana ait defteri (bakiye zinciriyle) döndürür; kaynak liste ve bakiye
  /// değişmediyse önbellekten.
  List<TransactionWithBalance> _ledgerFor(List<TransactionEntity> all) {
    // Cüzdan geçişi sırasında bloc state'i kısa süre ESKİ cüzdanın listesini
    // taşıyabilir (TransactionLoading.previousTransactions); yabancı cüzdan
    // satırları yeni bakiyeye çapalanmasın.
    final walletTransactions =
        all.where((t) => t.walletId == widget.wallet.id).toList();
    final balance = widget.wallet.balance;

    if (_ledgerBalance == balance &&
        _ledgerSource != null &&
        _sameList(_ledgerSource!, walletTransactions)) {
      return _ledger;
    }

    _ledgerSource = walletTransactions;
    _ledgerBalance = balance;
    _ledger = buildLedger(
      transactions: walletTransactions,
      currentBalance: balance,
    );
    return _ledger;
  }

  static bool _sameList(List<TransactionEntity> a, List<TransactionEntity> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Gün özetleri; görünen küme değişmedikçe yeniden hesaplanmaz. Filtre her
  /// tuş vuruşunda değişip build tetiklediği için bu önemli.
  Map<DateTime, DaySummary> _summariesFor(
      List<TransactionWithBalance> visible) {
    final cached = _summarySource;
    if (cached != null &&
        cached.length == visible.length &&
        (cached.isEmpty ||
            (identical(cached.first, visible.first) &&
                identical(cached.last, visible.last)))) {
      return _summaries;
    }
    _summarySource = visible;
    _summaries = _summaryService
        .buildDailySummaries(visible.map((e) => e.transaction).toList());
    return _summaries;
  }

  /// Kart bağlamında dönem EKSTRE dönemidir (bkz.
  /// [TransactionFilterCubit.useStatementCycle]); hesapta takvim ayı.
  void _syncStatementCycle() {
    context.read<TransactionFilterCubit>().useStatementCycle(
        FeatureFlags.creditCards ? widget.wallet.creditCard : null);
  }

  void _showFilterSheet(BuildContext parentContext) {
    final cubit = parentContext.read<TransactionFilterCubit>();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: cubit,
          child: BlocBuilder<TransactionFilterCubit, CombinedFilter>(
            builder: (builderContext, state) {
              // Material (renkli Container değil): panel InkWell, Checkbox ve
              // TextButton kullanıyor; opak bir DecoratedBox araya girerse
              // mürekkep dalgası ARKASINA boyanır ve görünmez olur.
              // Klavye açıldığında sheet DARALIR, altına itilmez: panelde iki
              // metin alanı var (tutar + kategori araması) ve sabit yükseklik
              // "N işlemi göster" düğmesini klavyenin ardında bırakıyordu.
              final screenHeight = MediaQuery.sizeOf(builderContext).height;
              final keyboard = MediaQuery.viewInsetsOf(builderContext).bottom;
              final height =
                  math.min(screenHeight * 0.85, screenHeight - keyboard - 24);

              return Padding(
                padding: EdgeInsets.only(bottom: keyboard),
                child: Material(
                  color: Theme.of(builderContext).colorScheme.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SizedBox(
                    height: height,
                    child: FilterView(
                      filter: state,
                      walletId: widget.wallet.id ?? '',
                      // Panel canlı; düğme kaç işlemin kalacağını ÖNCEDEN
                      // söyler.
                      resultCount: filterLedger(
                        ledger: _ledger,
                        filter: state,
                        categoryLabels: _categoryLabels,
                      ).length,
                      onFilterChanged: cubit.updateFilter,
                      onDateTap: () => pickSharedPeriod(builderContext),
                      onPeriodStep: cubit.stepPeriod,
                      onClearAll: cubit.clearAll,
                      onClose: () => Navigator.pop(builderContext),
                      periodLabel: statementPeriodLabel(cubit, context.l10n),
                      onModeChanged: cubit.setFinanceMode,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// [day] gününe yeni kayıt formu açar (gün başlığındaki "+" ve kaydı
  /// olmayan günün satırı). Tür, bakılan görünümden gelir: "Gelir" kipinde
  /// gelir, diğerlerinde gider — formda her zaman değiştirilebilir.
  void _addForDay(DateTime day, FinanceMode mode) {
    TransactionSheetHandler.showSheet(
      context: context,
      userId: widget.userId,
      walletId: widget.wallet.id ?? '',
      type: mode == FinanceMode.income
          ? TransactionTypeModel.income
          : TransactionTypeModel.expense,
      initialDate: day,
    );
  }

  /// Şeritten seçilen günün başlığını listenin tepesine getirir.
  ///
  /// Başlık tembel listede henüz KURULMAMIŞ olabilir; `ensureVisible` o zaman
  /// çalışmaz. O yüzden önce doğru yönde ekran ekran yaklaşılır (her adım bir
  /// kare sürer ve yeni satırlar kurulur), hedef kurulunca kesin hizalama
  /// yapılır. Adım sayısı sınırlı: hedef bir sebeple hiç kurulmazsa döngü
  /// kilitlenmesin.
  Future<void> _scrollToDay(
    DateTime day,
    List<TransactionWithBalance> visible,
    FinanceMode mode,
  ) async {
    setState(() => _selectedDay = day);

    final groups = groupLedgerByDay(visible, mode);
    final targetIndex = groups.indexWhere((g) => isSameDayValue(g.day, day));
    if (targetIndex < 0) return; // O gün hiç işlem yok; şerit vurgusu yeter.

    for (var attempt = 0; attempt < 24; attempt++) {
      if (!mounted) return;
      final ctx = _anchors.contextFor(day);
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0,
          duration: AppMotion.of(context).d(AppMotion.medium),
          curve: Curves.easeOutCubic,
        );
        return;
      }
      if (!_scrollController.hasClients) return;

      // Yön: kurulmuş başlıkların hangi tarafında kaldık? Defter yeniden
      // eskiye sıralı, yani daha ESKİ bir gün listede daha AŞAĞIDADIR.
      var direction = 1;
      for (var i = 0; i < groups.length; i++) {
        if (_anchors.contextFor(groups[i].day) != null) {
          direction = targetIndex > i ? 1 : -1;
          break;
        }
      }

      final position = _scrollController.position;
      final next = (position.pixels + direction * position.viewportDimension)
          .clamp(0.0, position.maxScrollExtent);
      if (next == position.pixels) return;
      _scrollController.jumpTo(next);
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  /// Aramanın/filtrenin dönem dışında da eşleşme bulup bulmadığı.
  /// Ekranın altında sade çubuk mu var (yalnız İşlemler bölümü açık)?
  bool get _simpleBarVisible =>
      getIt.isRegistered<SectionVisibility>() &&
      getIt<SectionVisibility>().hasOnlyTransactions;

  int _matchesOutsidePeriod(
      List<TransactionWithBalance> ledger, CombinedFilter filter) {
    return filterLedger(
      ledger: ledger,
      filter: filter,
      categoryLabels: _categoryLabels,
      applyDateWindow: false,
    ).length;
  }

  /// Dönemi verinin tamamına genişletir ("tüm geçmişte ara").
  void _widenToAllHistory(
      TransactionFilterCubit cubit, List<TransactionWithBalance> ledger) {
    if (ledger.isEmpty) return;
    final today = dayOf(DateTime.now());
    // Defter yeniden eskiye sıralı: ilk eleman en yeni, son eleman en eski.
    var earliest = dayOf(ledger.last.transaction.date);
    var latest = dayOf(ledger.first.transaction.date);
    if (today.isBefore(earliest)) earliest = today;
    if (today.isAfter(latest)) latest = today;
    cubit.setPeriod(DateTimeRange(
      start: earliest,
      end: DateTime(latest.year, latest.month, latest.day, 23, 59, 59),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionFilterCubit, CombinedFilter>(
      builder: (context, filterState) {
        final cubit = context.read<TransactionFilterCubit>();

        return BlocConsumer<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionError) {
              FirstRecordMoment.cancelAnnouncement();
              AppMessenger.error(state.message);
            } else if (state is TransactionActionSuccess) {
              if (state.warning != null) {
                AppMessenger.error(state.warning!);
              } else {
                // Kurulumun ilk kaydında sıradan "eklendi" bildiriminin
                // yerini tek cümle alır (bkz. FirstRecordMoment).
                final message = FirstRecordMoment.takeAnnouncement()
                    ? context.l10n.firstRecordSaved
                    : state.message;
                showDeletionMessage(context,
                    message: message, undo: state.undo);
              }
              _loadData();
              _loadCategoryIcons();
            }
          },
          builder: (context, state) {
            final ledger = _ledgerFor(state.currentTransactions);
            final isLoading = state is TransactionLoading;
            final walletIsEmpty = ledger.isEmpty;
            final mode = filterState.viewFilter.financeMode;

            final visible = filterLedger(
              ledger: ledger,
              filter: filterState,
              categoryLabels: _categoryLabels,
            );

            final period = DateTimeRange(
              start: filterState.viewFilter.startDate,
              end: filterState.viewFilter.endDate,
            );
            final periodHasToday = isDayInRange(DateTime.now(), period);

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: LedgerSelectionScope(
                selection: _selection,
                child: Column(
                  children: [
                    // Cüzdan ↔ bağlı kartları (yalnız kartı olan cüzdanda).
                    // Hap satırı YOK: hesap ↔ kart geçişi üst çubuktaki kart
                    // düğmesinde. Burada yalnız borç/öde şeridi ve son ödeme
                    // bantları kalır.
                    const CardContextRail(showPills: false),
                    // Seçim kipinde üst çubuğun yerini seçim çubuğu alır:
                    // süzgeç/dönem o sırada değişmez, seçili satırlar ekrandan
                    // kaybolup "görünmeyen satırlara uygulandı" olmaz.
                    ListenableBuilder(
                      listenable: _selection,
                      builder: (context, topBar) => _selection.active
                          ? _SelectionBar(
                              count: _selection.count,
                              onClose: _selection.clear,
                              onRecategorize: () => _recategorizeSelected(
                                  state.currentTransactions),
                            )
                          : topBar!,
                      child: TransactionTopBar(
                        filter: filterState,
                        periodLabel: statementPeriodLabel(cubit, context.l10n),
                        // Boş cüzdanda aranacak bir şey yok. Yüklenirken
                        // gizlenmez: kaydı olan kullanıcıda düğmeler her
                        // açılışta sonradan belirirdi.
                        showTools: !walletIsEmpty || isLoading,
                        categoryLabels: _categoryLabels,
                        onModeChanged: cubit.setFinanceMode,
                        onPeriodStep: cubit.stepPeriod,
                        onPeriodPick: () => pickSharedPeriod(context),
                        onFilterTap: () => _showFilterSheet(context),
                        onSearchChanged: cubit.setSearchQuery,
                        onDataFilterChanged: cubit.setDataFilter,
                        onClearCategories: () => cubit.setCategories(const {}),
                        onClearPriceRange: () => cubit.setPriceRange(null),
                        onClearSearch: () => cubit.setSearchQuery(null),
                        // Çip satırındaki "Temizle" görünen TÜM çipleri kaldırır,
                        // tür çipi dahil; dönem korunur.
                        onClearAllFilters: () => cubit
                          ..clearDataFilters()
                          ..setFinanceMode(FinanceMode.compare),
                      ),
                    ),
                    Expanded(
                      child: isLoading && walletIsEmpty
                          ? const TransactionListSkeleton()
                          : CustomScrollView(
                              controller: _scrollController,
                              slivers: _buildSlivers(
                                context: context,
                                cubit: cubit,
                                filterState: filterState,
                                ledger: ledger,
                                visible: visible,
                                mode: mode,
                                period: period,
                                periodHasToday: periodHasToday,
                                walletIsEmpty: walletIsEmpty,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildSlivers({
    required BuildContext context,
    required TransactionFilterCubit cubit,
    required CombinedFilter filterState,
    required List<TransactionWithBalance> ledger,
    required List<TransactionWithBalance> visible,
    required FinanceMode mode,
    required DateTimeRange period,
    required bool periodHasToday,
    required bool walletIsEmpty,
  }) {
    // Arama artık içeriğin ilk satırı DEĞİL: üst çubukta bir ikon (bkz.
    // [TransactionTopBar]). İçerik doğrudan özetle başlar.
    if (visible.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            mode: mode,
            walletIsEmpty: walletIsEmpty,
            // "Sonuç yok / filtreleri temizle" yalnız GERÇEKTEN bir süzgeç
            // varken söylenir. Eskiden ölçüt "cüzdan boş değil" idi: süzgeçsiz
            // boş bir ay da "Bu dönemde sonuç yok · Tüm geçmişte 160 eşleşme
            // var · Filtreleri temizle" diyordu (cihazda görüldü) — hiçbir şey
            // aramamış kullanıcıya arama diliyle konuşuyordu.
            isFiltered: !walletIsEmpty &&
                (filterState.dataFilter.hasActiveFilters ||
                    mode != FinanceMode.compare),
            // Alt çubukta "+ Gelir / − Gider" duruyorsa aynı düğmeleri boş
            // ekranda yinelemeye gerek yok.
            showAddButtons: !_simpleBarVisible,
            query: filterState.dataFilter.searchQuery,
            // Dönem penceresi artık HER ZAMAN uygulanıyor (eski takvim
            // görünümü onu yok sayıyordu). Bu yüzden "bu ayda yok ama
            // geçmişte var" durumunun bir çıkış yolu olmalı.
            outsidePeriodMatches:
                walletIsEmpty ? 0 : _matchesOutsidePeriod(ledger, filterState),
            onWidenPeriod: () => _widenToAllHistory(cubit, ledger),
            onClearFilters: cubit.clearAll,
            onAdd: (type) => TransactionSheetHandler.showSheet(
              context: context,
              userId: widget.userId,
              walletId: widget.wallet.id ?? '',
              type: type,
            ),
          ),
        ),
      ];
    }

    final days = {for (final e in visible) dayOf(e.transaction.date)};

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: PeriodTransition(
            periodStart: period.start,
            child: ListenableBuilder(
              listenable: _collapse,
              builder: (context, _) => TransactionSummaryStrip(
                transactions: visible.map((e) => e.transaction).toList(),
                mode: mode,
                filter: filterState,
                periodLabel: periodLabel(period, context.l10n),
                onToday: periodHasToday ? null : cubit.jumpToToday,
                onModeChanged: cubit.setFinanceMode,
                // Tümünü daralt / genişlet: uzun bir dönemde gün başlıklarını
                // tek tek kapatmak gerekiyordu. Tek günde anlamsız, gizlenir.
                onToggleCollapseAll: days.length < 2
                    ? null
                    : () => _collapse.allCollapsed(days)
                        ? _collapse.expandAll()
                        : _collapse.collapseAll(days),
                allDaysCollapsed: _collapse.allCollapsed(days),
                // "Param nereye gidiyor?" — yalnız gider görünürken.
                topCategories: mode == FinanceMode.income
                    ? const []
                    : _topCategories(
                        visible.map((e) => e.transaction).toList()),
                onOpenBreakdown: getIt.isRegistered<HomeNavigationRequests>()
                    ? () => getIt<HomeNavigationRequests>()
                        .openSection(TransactionsSection.report)
                    : null,
              ),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: PeriodTransition(
            periodStart: period.start,
            child: TransactionDayRail(
              range: period,
              summaries: _summariesFor(visible),
              // Dönem dışına düşen seçim BAYATTIR: kullanıcı bir gün seçip
              // sonra ayı değiştirdiğinde o vurgu artık hiçbir şeyi
              // göstermiyor, üstelik şeridin kendini ortalamasını da
              // engelliyordu.
              selectedDay:
                  _selectedDay != null && isDayInRange(_selectedDay!, period)
                      ? _selectedDay
                      : null,
              onDaySelected: (day) => _scrollToDay(day, visible, mode),
            ),
          ),
        ),
      ),
      // Seçilen günde kayıt yoksa kaydırılacak bir başlık da yok: eskiden
      // dokunuş yalnız şeritteki vurguyu değiştiriyordu. Şimdi o güne kayıt
      // girmenin yolu burada.
      if (_selectedDay case final day?
          when isDayInRange(day, period) && !days.contains(dayOf(day)))
        SliverToBoxAdapter(
          child: _EmptyDayRow(
            day: day,
            onAdd: () => _addForDay(day, mode),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
        sliver: TransactionLedgerSliver(
          transactions: visible,
          mode: mode,
          categoryIcons: _categoryIcons,
          categoryLabels: _categoryLabels,
          anchors: _anchors,
          collapse: _collapse,
          onAddForDay: (day) => _addForDay(day, mode),
        ),
      ),
    ];
  }
}

/// Şeritten seçilen ama hiç kaydı olmayan günün satırı: "14 Eki Çar · kayıt
/// yok  [+ Ekle]".
class _EmptyDayRow extends StatelessWidget {
  final DateTime day;
  final VoidCallback onAdd;

  const _EmptyDayRow({required this.day, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = DateFormat.MMMEd(Intl.defaultLocale).format(day);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 0),
      child: Row(
        children: [
          Icon(Icons.event_available_rounded,
              size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.txDayEmptyRow(date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ),
          TextButton.icon(
            key: const ValueKey('tx-empty-day-add'),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(context.l10n.ekle),
          ),
        ],
      ),
    );
  }
}

/// Çoklu seçim çubuğu: kaç satır seçili + toplu eylem.
class _SelectionBar extends StatelessWidget {
  final int count;
  final VoidCallback onClose;
  final VoidCallback onRecategorize;

  const _SelectionBar({
    required this.count,
    required this.onClose,
    required this.onRecategorize,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        key: const ValueKey('ledger-selection-bar'),
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.secimiKapat,
                icon: Icon(Icons.close_rounded, color: cs.onPrimaryContainer),
                onPressed: onClose,
              ),
              Text(
                l10n.nIslemSecili(count),
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              // Düğme dar ekranda / büyük yazıda taşmak yerine küçülür.
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: FilledButton.icon(
                      key: const ValueKey('ledger-recategorize'),
                      onPressed: onRecategorize,
                      icon: const Icon(Icons.label_outline_rounded, size: 18),
                      label: Text(l10n.kategoriDegistir),
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
}

/// Liste boş kaldığında gösterilen ekran.
///
/// Üç ayrı durum: cüzdan hiç kayıt taşımıyor · filtre/arama bu dönemde
/// eşleşme bırakmadı · bu dönemde yok ama GEÇMİŞTE var. Sonuncusu tek
/// görünüme geçişle birlikte doğdu: takvim modu tarih penceresini yok
/// sayıyordu, artık dönem her zaman uygulanıyor, o yüzden "geçen ay almıştım"
/// diyen kullanıcının çıkış yolu ekranda yazılı olmalı.
class _EmptyState extends StatelessWidget {
  final FinanceMode mode;

  /// Cüzdanda hiç kayıt yok (ilk kullanım).
  final bool walletIsEmpty;

  /// Bir süzgeç ya da arama etkin. false + [walletIsEmpty] false ise durum
  /// yalnızca "bu dönem boş"tur.
  final bool isFiltered;

  /// Boş ekranda "Gider ekle / Gelir ekle" gösterilsin mi.
  final bool showAddButtons;
  final String? query;
  final int outsidePeriodMatches;
  final VoidCallback onWidenPeriod;
  final VoidCallback onClearFilters;

  /// Cüzdan BOŞKEN gösterilen "ekle" düğmeleri. Eskiden boş defter yalnız
  /// "sürgü butonunu kullanın" diyordu: yeni kullanıcının ilk işi, ekranda
  /// görünmeyen bir jesti bulmaktı.
  final ValueChanged<TransactionTypeModel> onAdd;

  const _EmptyState({
    required this.mode,
    required this.walletIsEmpty,
    required this.isFiltered,
    required this.showAddButtons,
    required this.query,
    required this.outsidePeriodMatches,
    required this.onWidenPeriod,
    required this.onClearFilters,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accent = mode.primaryColor;
    final hasQuery = query != null && query!.trim().isNotEmpty;
    final hasElsewhere = isFiltered && outsidePeriodMatches > 0;

    // Süzgeçsiz boş dönem: kayıt var ama bu aralıkta değil.
    final emptyPeriod = !isFiltered && !walletIsEmpty;

    final title = !isFiltered
        ? (emptyPeriod ? l10n.txEmptyPeriodTitle : l10n.henuzIslemYok)
        : hasElsewhere
            ? l10n.txSearchWidenTitle
            : hasQuery
                ? l10n.txSearchNoResultTitle(query!.trim())
                : l10n.txEmptyFilteredTitle;
    final body = !isFiltered
        ? (emptyPeriod ? l10n.txEmptyPeriodBody : l10n.buDonemIcinKayit)
        : hasElsewhere
            ? l10n.txSearchWidenBody(outsidePeriodMatches)
            : l10n.txEmptyFilteredBody;

    return EmptyState(
      icon: !isFiltered
          ? Icons.receipt_long_rounded
          : hasElsewhere
              ? Icons.history_rounded
              : Icons.filter_alt_off_rounded,
      accent: accent,
      title: title,
      body: body,
      actions: [
        if (!isFiltered && showAddButtons)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                key: const ValueKey('tx-empty-add-expense'),
                onPressed: () => onAdd(TransactionTypeModel.expense),
                icon: const Icon(Icons.south_west_rounded, size: 18),
                label: Text(l10n.giderEkle),
              ),
              FilledButton.tonalIcon(
                key: const ValueKey('tx-empty-add-income'),
                onPressed: () => onAdd(TransactionTypeModel.income),
                icon: const Icon(Icons.north_east_rounded, size: 18),
                label: Text(l10n.gelirEkle),
              ),
            ],
          ),
        if (emptyPeriod)
          TextButton(
            key: const ValueKey('tx-empty-show-all'),
            onPressed: onWidenPeriod,
            child: Text(l10n.txEmptyShowAll),
          ),
        if (isFiltered && hasElsewhere)
          FilledButton.tonalIcon(
            onPressed: onWidenPeriod,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: Text(l10n.txSearchWidenAction),
          ),
        if (isFiltered)
          TextButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.clear_all_rounded, size: 18),
            label: Text(l10n.txEmptyClearFilters),
          ),
      ],
    );
  }
}
