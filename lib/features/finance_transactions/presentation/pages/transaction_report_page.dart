import 'dart:async';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/csv_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/app_date_range_picker.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode_segment.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/category_details_bottom_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_compare_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_cumulative_balance_chart.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_budget_summary_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_monthly_trend_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_range_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_top_payees_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_transaction_list_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_section_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_summary_cards.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_system_movements_toggle.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_daily_net_flow_chart.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TransactionReportPage extends StatelessWidget {
  final String userId;
  final String walletId;
  final bool showAppBar;

  const TransactionReportPage({
    super.key,
    required this.userId,
    required this.walletId,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionBloc>()
        ..add(GetTransactionsEvent(userId: userId, walletId: walletId)),
      child: _TransactionReportView(
        showAppBar: showAppBar,
        categoryRepository: getIt<CategoryRepository>(),
        walletId: walletId,
      ),
    );
  }
}

class _TransactionReportView extends StatefulWidget {
  final bool showAppBar;
  final CategoryRepository categoryRepository;

  /// Bütçeler cüzdan bazlı yüklendiği için görünümün cüzdanı bilmesi gerekir.
  final String walletId;

  const _TransactionReportView({
    required this.showAppBar,
    required this.categoryRepository,
    required this.walletId,
  });

  @override
  State<_TransactionReportView> createState() => _TransactionReportViewState();
}

class _TransactionReportViewState extends State<_TransactionReportView> {
  late DateTimeRange _range;
  bool _hasUserPickedRange = false;
  bool _hasAutoAdjustedRange = false;
  bool _showExpenseBarChart = false;
  bool _showIncomeBarChart = false;
  FinanceMode _categoryMode = FinanceMode.compare;

  /// Kullanıcının seçtiği zaman çözünürlüğü; null ise aralığa göre otomatik
  /// (bkz. [ReportSeriesService.autoUnitFor]). Aralık DEĞİŞİNCE sıfırlanır:
  /// "Bu Yıl"da elle seçilen "Ay", "Bu Ay"a dönüldüğünde tek çubuk çizerdi.
  ReportBucketUnit? _unitOverride;

  /// Transfer/borç/yatırım kuplaj hareketleri gelir–gidere sayılsın mı?
  /// Varsayılan KAPALI: raporun sorusu "ne harcadım", oysa bu hareketlerde
  /// para harcanmaz, yer değiştirir (bkz.
  /// [TransactionReportService.splitSystemMovements]).
  bool _includeSystemMovements = false;

  /// Aylık seyir kartının ufku (6 | 12 ay). Seçili aralıktan BAĞIMSIZ:
  /// "daha çok mu harcıyorum" sorusu daha uzun bir pencere ister.
  int _trendMonths = 6;

  Map<String, IconData> _categoryIcons = {};

  /// `tag` → görünen ad. Kırılım anahtarı hep `tag` (kategori id'si) kalır;
  /// bu harita yalnız gösterim içindir (bkz. [buildCategoryLabelMap]).
  Map<String, String> _categoryLabels = {};

  /// `id → kök id`. Kırılım KÖK seviyede toplanır: alt kategoriler kendi
  /// dilimlerine bölünseydi %3 eşiği hepsini "Diğer"e süpürürdü.
  Map<String, String> _categoryRoots = {};
  List<BudgetEntity> _budgets = [];

  StreamSubscription<void>? _categoriesSub;
  StreamSubscription<void>? _budgetsSub;

  static const _reportService = TransactionReportService();
  static const _seriesService = ReportSeriesService();

  /// Türetilmiş rapor verisinin önbelleği.
  ///
  /// **Neden gerekli:** türetme her `build`'de baştan çalışıyordu — aralık
  /// süzme, sistem ayrımı, iki kırılım, iki pasta, iki rank ve iki zaman
  /// serisi. Ölçüldü: 5.000 işlemlik bir yıllık aralıkta tur başına
  /// **23,2 ms**, yani 16,7 ms'lik kare bütçesinin üstünde. Mod değiştirmek
  /// ya da anahtar açmak gibi her `setState` bunu tekrarlıyordu.
  ({
    List<TransactionEntity> transactions,
    DateTimeRange range,
    bool includeSystem,
    ReportBucketUnit? unit,
    Map<String, String> roots,
    List<BudgetEntity> budgets,
    String otherLabel,
    Brightness brightness,
    double walletOpening,
    int trendMonths,
  })? _derivedKey;
  _ReportDerived? _derivedCache;

  /// Kategori kırılımı/renk paleti/bütçe eşlemesi tek yerde; detay bottom
  /// sheet'i de aynı nesneyi alır.
  ReportCategoryDataBuilder _dataBuilder(BuildContext context) =>
      ReportCategoryDataBuilder(
        range: _range,
        budgets: _budgets,
        otherCategoryLabel: context.l10n.categoryDiger,
        rootIndex: _categoryRoots,
      );

  @override
  void initState() {
    super.initState();
    // İçgörüler sayfasıyla AYNI dönem tanımı. Eskiden rapor "ayın 1'i →
    // şimdi" kullanıyordu: hızlı seçenekteki "Bu Ay" çipi hiçbir zaman
    // seçili görünmüyor, iki kardeş sayfa aynı ayı farklı tanımlıyordu.
    _range = DateRangeHelper.thisMonth();
    _loadCategoryIcons();
    _categoriesSub = getIt<CategoriesChangedNotifier>()
        .stream
        .listen((_) => _loadCategoryIcons());
    _loadBudgets();
    // Alt görünümler kaydırma yığınında canlı kalıyor: Bütçeler sayfasında
    // değiştirilen bir limit, `initState` yeniden çalışmadığı için raporda
    // bayat kalıyordu (kategori yeniden adlandırmada çözülen hatanın aynısı).
    _budgetsSub =
        getIt<BudgetsChangedNotifier>().stream.listen((_) => _loadBudgets());

    // Listener yalnız state DEĞİŞİMİNDE tetiklenir; bloc zaten dolu bir
    // durumla verilmişse ilk kontrolü burada yapmak gerekir. [_maybeAdjust...]
    // kendi bayrağıyla korunduğundan iki yolun çakışması sorun değildir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeAdjustInitialRange(
        context.read<TransactionBloc>().state.currentTransactions,
      );
    });
  }

  /// Kategori ikon+ad indeksini yükler ve kategoriler değiştikçe TAZELER.
  ///
  /// Harita eskiden yalnız initState'te kuruluyordu: sayfa route yığınında
  /// dururken yapılan bir yeniden adlandırma ancak sayfa yeniden kurulduğunda
  /// görünüyordu.
  @override
  void dispose() {
    _categoriesSub?.cancel();
    _budgetsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCategoryIcons() async {
    final categories = await fetchAllCategories(widget.categoryRepository);
    if (!mounted) return;
    final index = buildCategoryDisplayIndex(categories);
    setState(() {
      _categoryIcons = index.icons;
      _categoryLabels = index.labels;
      _categoryRoots = index.roots;
    });
  }

  /// Bütçe limitlerini yükler. `spentAmount` burada kullanılmaz — rapor
  /// sayfası kendi seçilebilir [_range]'ına göre harcamayı ayrıca hesaplar
  /// (bkz. [ReportCategoryDataBuilder.budgetProgressFor]), çünkü
  /// [BudgetRepository] yalnızca limitleri döner ve "bu ay" varsayımı taşımaz.
  Future<void> _loadBudgets() async {
    // Bütçeler cüzdan bazlı; rapor da tek cüzdanın işlemlerini gösterir.
    final result = await getIt<BudgetRepository>().getBudgets(widget.walletId);
    if (!mounted) return;
    result.fold(
      (_) {},
      (budgets) => setState(() => _budgets = budgets),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await AppDateRangePicker.pick(
      context,
      initialDateRange: _range,
      quickOptions: DateRangeHelper.buildDateRangeQuickOptions(context.l10n),
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _hasUserPickedRange = true;
        _unitOverride = null;
      });
    }
  }

  /// Seçili [_range] ile aynı gün sayısına sahip, hemen öncesindeki dönemin
  /// toplamlarını hesaplar (dönemsel değişim rozetleri için).
  ///
  /// Evren, güncel dönemle AYNI olmak zorunda: kuplaj hareketleri gelir–
  /// giderin dışında tutulurken önceki dönemin onları saymaya devam etmesi,
  /// rozeti anlamsız bir kıyasa çevirirdi ("bu ay %70 az harcadın" — çünkü
  /// geçen ayın rakamında bir transfer duruyor).
  ReportTotals _previousPeriodTotals(List<TransactionEntity> allTransactions) {
    final window = _previousPeriodWindow();
    if (window == null) return const ReportTotals();
    return _reportService.calculateTotals(_universeOf(
      _reportService.filterByRange(allTransactions, window.start, window.end),
    ));
  }

  Future<void> _shareReport() async {
    final state = context.read<TransactionBloc>().state;
    final filtered = _filterTransactionsByRange(state.currentTransactions);
    if (filtered.isEmpty) return;
    final rangeLabel = '${DateFormat('dd MMM yyyy').format(_range.start)} - '
        '${DateFormat('dd MMM yyyy').format(_range.end)}';
    await getIt<CsvService>().exportTransactionsToCSV(
      filtered,
      shareText: '${context.l10n.islemRaporu} ($rangeLabel)',
    );
  }

  List<TransactionEntity> _filterTransactionsByRange(
      List<TransactionEntity> transactions) {
    return _reportService.filterByRange(transactions, _range.start, _range.end);
  }

  /// Varsayılan aralık ("bu ay") boşsa ama geçmiş veri varsa, aralığı son
  /// işlemin ayına kaydırır — kullanıcı raporu boş sanmasın.
  ///
  /// build sırasında değil, işlem listesi her değiştiğinde bir kez çalışır
  /// (bkz. [BlocListener] kurulumu): build içinde state yazmak aynı kareyi
  /// tutarsız bırakır ve aralık boş kaldığı sürece her rebuild'de tekrarlanırdı.
  void _maybeAdjustInitialRange(List<TransactionEntity> transactions) {
    if (_hasUserPickedRange || _hasAutoAdjustedRange) return;
    if (transactions.isEmpty) return;
    if (_filterTransactionsByRange(transactions).isNotEmpty) return;

    DateTime? latestDate;
    for (final t in transactions) {
      if (latestDate == null || t.date.isAfter(latestDate)) {
        latestDate = t.date;
      }
    }
    if (latestDate == null) return;

    final start = DateTime(latestDate.year, latestDate.month, 1);
    final lastDayOfMonth = DateTime(latestDate.year, latestDate.month + 1, 0);
    final now = DateTime.now();
    final end = latestDate.isBefore(now)
        ? (lastDayOfMonth.isBefore(now) ? lastDayOfMonth : now)
        : latestDate;

    setState(() {
      _range = DateTimeRange(start: start, end: end);
      _hasAutoAdjustedRange = true;
      _unitOverride = null;
    });
  }

  /// Bir build turunun türetilmiş rapor verisi — hepsi tek yerde, tek kez.
  _ReportDerived _derive(
    BuildContext context,
    List<TransactionEntity> transactions,
    Brightness brightness,
  ) {
    final otherLabel = context.l10n.categoryDiger;
    final walletOpening =
        context.walletById(widget.walletId)?.openingBalance ?? 0;

    // Anahtar, türetmeyi etkileyen HER girdiyi taşır. Listeler/haritalar
    // kimliğe göre karşılaştırılır ve hepsi `setState` ile bütün olarak
    // değiştiriliyor — yani kimlik değişimi gerçek bir veri değişimidir.
    final key = (
      transactions: transactions,
      range: _range,
      includeSystem: _includeSystemMovements,
      unit: _unitOverride,
      roots: _categoryRoots,
      budgets: _budgets,
      otherLabel: otherLabel,
      brightness: brightness,
      walletOpening: walletOpening,
      trendMonths: _trendMonths,
    );
    final cached = _derivedCache;
    if (cached != null && _derivedKey == key) return cached;

    final dataBuilder = ReportCategoryDataBuilder(
      range: _range,
      budgets: _budgets,
      otherCategoryLabel: otherLabel,
      rootIndex: _categoryRoots,
    );
    final filtered = _filterTransactionsByRange(transactions);

    // Kuplaj hareketleri "ne harcadım" sorusunun dışında tutulur; bakiye
    // çizgisi ise defterin TAMAMINDAN türer (aşağıda).
    final split = _reportService.splitSystemMovements(filtered);
    final analysed = _includeSystemMovements ? filtered : split.spending;

    // Kategori bazlı karşılaştırma: ÖNCEKİ dönemin aynı kırılımı. Pencere
    // toplam rozetleriyle AYNI ([_previousPeriodWindow]) — iki ayrı "önceki
    // dönem" tanımı kartlar arası çelişki üretirdi.
    final previousWindow = _previousPeriodWindow();
    final previousUniverse = previousWindow == null
        ? const <TransactionEntity>[]
        : _universeOf(_reportService.filterByRange(
            transactions, previousWindow.start, previousWindow.end));

    final expenseFull = dataBuilder.withPreviousAmounts(
      dataBuilder.buildFull(analysed, isExpense: true),
      dataBuilder.buildFull(previousUniverse, isExpense: true),
    );
    final incomeFull = dataBuilder.withPreviousAmounts(
      dataBuilder.buildFull(analysed, isExpense: false),
      dataBuilder.buildFull(previousUniverse, isExpense: false),
    );

    final derived = _ReportDerived(
      dataBuilder: dataBuilder,
      filtered: filtered,
      split: split,
      totals: _reportService.calculateTotals(analysed),
      previousTotals: _previousPeriodTotals(transactions),
      expenseFull: expenseFull,
      incomeFull: incomeFull,
      expensePie: dataBuilder.buildPie(expenseFull),
      incomePie: dataBuilder.buildPie(incomeFull),
      incomeRanked: dataBuilder.buildRanked(incomeFull,
          isExpense: false, brightness: brightness),
      expenseRanked: dataBuilder.buildRanked(expenseFull,
          isExpense: true, brightness: brightness),
      // İKİ ayrı seri kurulur ve bu bilinçlidir:
      //  • akış çubukları özet kartlarıyla AYNI evreni gösterir (kuplaj
      //    hareketleri hariç tutulmuşsa onlarda da yok);
      //  • bakiye çizgisi defterin TAMAMINDAN türer — transferi düşmek
      //    bakiyeyi cüzdanın gerçek bakiyesinden koparırdı.
      flowSeries: _seriesService.build(
        inRange: analysed,
        start: _range.start,
        end: _range.end,
        unit: _unitOverride,
      ),
      balanceSeries: _seriesService.build(
        inRange: filtered,
        start: _range.start,
        end: _range.end,
        unit: _unitOverride,
        openingBalance: _seriesService.openingBalanceFor(
          all: transactions,
          start: _range.start,
          walletOpeningBalance: walletOpening,
        ),
      ),
      // Aylık seyir seçili aralığı DEĞİL, onun bittiği ayla biten pencereyi
      // gösterir; kuplaj hareketleri burada da harcama sayılmaz.
      trendSeries: () {
        final window = _seriesService.monthsWindow(_range.end, _trendMonths);
        return _seriesService.build(
          inRange: _universeOf(_reportService.filterByRange(
              transactions, window.start, window.end)),
          start: window.start,
          end: window.end,
          unit: ReportBucketUnit.month,
        );
      }(),
      budgetStatuses: _budgetStatuses(context, expenseFull),
      // Kümeleme trie kurup dolaşıyor; build içinde İKİ kez çağrılıyordu
      // (biri "kart çizilsin mi" kontrolü için). Türetmeye alındı.
      payeeGroups: ReportTopPayeesCard.buildGroups(analysed),
    );

    _derivedKey = key;
    _derivedCache = derived;
    return derived;
  }

  /// Analiz evreni: kuplaj hareketleri anahtara göre içeride ya da dışarıda.
  /// Her kartın AYNI evreni kullanması şart, yoksa toplamlar birbirini tutmaz.
  List<TransactionEntity> _universeOf(List<TransactionEntity> inRange) =>
      _includeSystemMovements
          ? inRange
          : _reportService.splitSystemMovements(inRange).spending;

  /// Karşılaştırma penceresi — seçili aralığın BUGÜNE kadar GEÇMİŞ kısmı
  /// kadar, hemen öncesinde. Aralık tamamen gelecekteyse null.
  ///
  /// "Bu Ay" seçiliyken ayın 3'ünde tam ayı tam ayla kıyaslamak "geçen aya
  /// göre %90 az harcadın" derdi — çünkü bu ayın 27 günü henüz yaşanmadı.
  ({DateTime start, DateTime end})? _previousPeriodWindow() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay =
        DateTime(_range.start.year, _range.start.month, _range.start.day);
    final rangeEnd =
        DateTime(_range.end.year, _range.end.month, _range.end.day);
    final elapsedEnd = rangeEnd.isAfter(today) ? today : rangeEnd;
    if (elapsedEnd.isBefore(startDay)) return null;

    final dayCount = elapsedEnd.difference(startDay).inDays + 1;
    final previousEnd = startDay.subtract(const Duration(days: 1));
    return (
      start: previousEnd.subtract(Duration(days: dayCount - 1)),
      end: previousEnd,
    );
  }

  /// Dönemin bütçe durumları — harcama SEÇİLİ ARALIĞA göre hesaplanır
  /// (BudgetRepository yalnız limitleri döner, "bu ay" varsayımı taşımaz).
  ///
  /// Alt kategori bütçesi de listeye girer: bütçe iki seviyeye de konabiliyor
  /// ama dilimler kök seviyede toplandığı için alt kategori bütçesi kök
  /// satırında hiç görünmüyordu.
  List<BudgetStatus> _budgetStatuses(
    BuildContext context,
    List<CategoryData> expenseFull,
  ) {
    if (_budgets.isEmpty) return const [];

    final spentByTag = <String, double>{};
    for (final root in expenseFull) {
      spentByTag[root.name] = root.totalAmount;
      for (final child in root.children) {
        if (child.isDirect) continue;
        spentByTag[child.name] = child.totalAmount;
      }
    }

    return [
      for (final budget in _budgets)
        if (budget.limitAmount > 0)
          BudgetStatus(
            categoryId: budget.categoryId,
            label: context.categoryLabelForTag(budget.categoryId,
                labels: _categoryLabels),
            spent: spentByTag[budget.categoryId] ?? 0,
            limit: budget.limitAmount,
          ),
    ];
  }

  /// Akış grafiğinin başlığı çözünürlüğü İZLER: haftalık kovalarda "Günlük
  /// Gelir–Gider" yazmak, mağaza denetiminde yakalanan hatanın aynısıdır.
  String _flowTitle(BuildContext context, ReportBucketUnit unit) =>
      switch (unit) {
        ReportBucketUnit.day => context.l10n.reportFlowTitleDay,
        ReportBucketUnit.week => context.l10n.reportFlowTitleWeek,
        ReportBucketUnit.month => context.l10n.reportFlowTitleMonth,
      };

  /// Her çözünürlüğün seçili aralıkta kaç kova ürettiği — seçicinin hangi
  /// seçeneği kapatacağına bununla karar verilir.
  Map<ReportBucketUnit, int> _bucketCounts() => {
        for (final unit in ReportBucketUnit.values)
          unit: _seriesService.bucketCountFor(_range.start, _range.end, unit),
      };

  /// Trend kartında vurgulanacak ay: seçili aralık TAM olarak bir takvim
  /// ayıysa o ay, değilse yok. Yarım aylık bir aralığı "Ekim" diye
  /// vurgulamak yanlış olurdu.
  DateTime? _selectedTrendMonth() {
    final start = _range.start;
    final end = _range.end;
    if (start.day != 1) return null;
    final lastDay = DateTime(start.year, start.month + 1, 0);
    if (end.year != lastDay.year ||
        end.month != lastDay.month ||
        end.day != lastDay.day) {
      return null;
    }
    return DateTime(start.year, start.month, 1);
  }

  /// Bütçe satırına dokunmak o kategorinin dönem içi işlemlerini açar.
  void _openBudgetCategory(BudgetStatus status) {
    final builder = _dataBuilder(context);
    final filtered = _filterTransactionsByRange(
      context.read<TransactionBloc>().state.currentTransactions,
    );
    final full = builder.buildFull(_universeOf(filtered), isExpense: true);

    // Bütçe alt kategoriye de konabiliyor: önce kökler, sonra çocuklar.
    for (final root in full) {
      if (root.name == status.categoryId) {
        _openCategoryDetails(root, true, ReportSliceMode.full);
        return;
      }
      for (final child in root.children) {
        if (!child.isDirect && child.name == status.categoryId) {
          _openCategoryDetails(child, true, ReportSliceMode.full);
          return;
        }
      }
    }
  }

  /// "En çok harcanan yer" satırına dokunmak o gruptaki işlemleri listeler.
  ///
  /// Grup bir KATEGORİ değil (kırılım eşleştirmesi yok), o yüzden detay
  /// sayfası kendi yeniden hesaplamasını yapamaz — liste doğrudan verilir.
  void _openPayeeGroup(String label, List<TransactionEntity> items) {
    ReportTransactionListSheet.show(
      context: context,
      title: label,
      transactions: items,
      isExpense: true,
      categoryIcons: _categoryIcons,
      categoryLabels: _categoryLabels,
    );
  }

  void _openCategoryDetails(
      CategoryData cat, bool isExpense, ReportSliceMode sliceMode) {
    CategoryDetailsBottomSheet.show(
      context: context,
      initialCategory: cat,
      isExpense: isExpense,
      sliceMode: sliceMode,
      categoryIcons: _categoryIcons,
      categoryLabels: _categoryLabels,
      dataBuilder: _dataBuilder(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(context.l10n.islemRaporu),
              centerTitle: true,
              actions: [
                // Paylaş düğmesi AppBar'dan ALINDI: sayfa üretimde
                // AppBar'sız kuruluyor, bu yüzden artık sayfa başlığında
                // duruyor ve her iki kurulumda da erişilebilir.
                IconButton(
                  icon: const Icon(Icons.date_range),
                  onPressed: _pickDateRange,
                  tooltip: context.l10n.tooltipTarihAraligi,
                ),
              ],
            )
          : null,
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listenWhen: (prev, curr) =>
            prev.currentTransactions != curr.currentTransactions,
        listener: (context, state) =>
            _maybeAdjustInitialRange(state.currentTransactions),
        builder: (context, state) {
          final transactions = state.currentTransactions;
          if (state is TransactionLoading && transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transactions.isEmpty) {
            return _buildEmptyState(context);
          }

          final brightness =
              (theme.extension<AppSurface>() ?? AppSurface.light).brightness;
          final derived = _derive(context, transactions, brightness);

          final dataBuilder = derived.dataBuilder;
          final filteredTransactions = derived.filtered;
          final split = derived.split;
          final totals = derived.totals;
          final previousTotals = derived.previousTotals;
          final expenseFull = derived.expenseFull;
          final incomeFull = derived.incomeFull;
          final expensePie = derived.expensePie;
          final incomePie = derived.incomePie;
          final flowSeries = derived.flowSeries;
          final balanceSeries = derived.balanceSeries;

          // Karşılaştırma modu tek bir kart çizer (bkz.
          // [ReportCompareChartCard]); tek taraflı modlar eskisi gibi
          // pasta/çubuk kartını gösterir.
          final isCompare = _categoryMode == FinanceMode.compare;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportSectionHeader(
                  title: context.l10n.islemRaporu,
                  fontSize: 20,
                  // Paylaş düğmesi eskiden YALNIZ AppBar'daydı ve sayfa
                  // üretimde `showAppBar: false` ile kuruluyor (bkz.
                  // SubViewFactory) — yani CSV dışa aktarımı hiç
                  // erişilemiyordu, `_shareReport` ölü koddu.
                  trailing: filteredTransactions.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.ios_share_rounded),
                          tooltip: context.l10n.reportShareTooltip,
                          onPressed: _shareReport,
                        ),
                ),
                const SizedBox(height: 12),
                // Tarih başlığı aralık boş olsa da görünür kalır; aksi
                // halde kullanıcı aralığı değiştirecek kontrolü bulamıyordu.
                ReportRangeHeader(
                  range: _range,
                  onPickDateRange: _pickDateRange,
                  quickOptions:
                      DateRangeHelper.buildDateRangeQuickOptions(context.l10n),
                  onQuickOptionSelected: (picked) => setState(() {
                    _range = picked;
                    _hasUserPickedRange = true;
                    _unitOverride = null;
                  }),
                ),
                const SizedBox(height: 16),

                if (filteredTransactions.isEmpty) ...[
                  _buildEmptyState(
                    context,
                    message: context.l10n.msgSecilenTarihAraligindaIslem,
                  ),
                ] else ...[
                  ReportSummaryCards(
                    totals: totals,
                    previousTotals: previousTotals,
                  ),
                  // Kart yalnız dönemde kuplaj hareketi VARKEN çizilir;
                  // yoksa hiçbir şeyi açıklamayan bir anahtar yer kaplardı.
                  if (split.system.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ReportSystemMovementsToggle(
                      included: _includeSystemMovements,
                      count: split.system.length,
                      onChanged: (v) =>
                          setState(() => _includeSystemMovements = v),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ReportSectionHeader(
                    title: _flowTitle(context, flowSeries.unit),
                    trailing: ReportUnitSelector(
                      selected: flowSeries.unit,
                      bucketCounts: _bucketCounts(),
                      onChanged: (u) => setState(() => _unitOverride = u),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ReportDailyNetFlowChart(series: flowSeries),
                  const SizedBox(height: 24),
                  ReportSectionHeader(title: context.l10n.reportBalanceTrend),
                  const SizedBox(height: 12),
                  ReportCumulativeBalanceChart(series: balanceSeries),
                  const SizedBox(height: 24),
                  ReportSectionHeader(
                      title: context.l10n.reportMonthlyTrendTitle),
                  const SizedBox(height: 12),
                  ReportMonthlyTrendCard(
                    series: derived.trendSeries,
                    months: _trendMonths,
                    onMonthsChanged: (m) => setState(() => _trendMonths = m),
                    selectedMonth: _selectedTrendMonth(),
                    onMonthTap: (bucket) => setState(() {
                      // Trend kartı gezinme aracıdır: dokunulan ay raporun
                      // dönemi olur.
                      _range = DateTimeRange(
                        start: bucket.start,
                        end: bucket.endExclusive
                            .subtract(const Duration(days: 1)),
                      );
                      _hasUserPickedRange = true;
                      _unitOverride = null;
                    }),
                  ),
                  const SizedBox(height: 24),
                  ReportSectionHeader(
                    title: context.l10n.kategoriDagilimi,
                    trailing: FinanceModeSegment(
                      currentMode: _categoryMode,
                      onModeChanged: (m) => setState(() => _categoryMode = m),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isCompare)
                    ReportCompareChartCard(
                      incomeSlices: derived.incomeRanked,
                      expenseSlices: derived.expenseRanked,
                      categoryLabels: _categoryLabels,
                      // Bütçeler varsayılan modda GÖRÜNMÜYORDU: ilerleme
                      // çubukları yalnız tek taraflı pasta kartına
                      // geçiriliyordu, oysa açılış modu karşılaştırma.
                      budgetProgressFor: dataBuilder.budgetProgressFor,
                      onSliceTap: (slice, isExpense) => _openCategoryDetails(
                          slice, isExpense, ReportSliceMode.ranked),
                    )
                  else if (_categoryMode == FinanceMode.expense)
                    ReportCategoryChartCard(
                      title: context.l10n.reportExpensesTitle,
                      fullData: expenseFull,
                      pieData: expensePie,
                      isExpense: true,
                      showBarChart: _showExpenseBarChart,
                      onToggleBarChart: (v) =>
                          setState(() => _showExpenseBarChart = v),
                      onCategoryTap: (cat, mode) =>
                          _openCategoryDetails(cat, true, mode),
                      budgetProgressFor: dataBuilder.budgetProgressFor,
                      categoryLabels: _categoryLabels,
                    )
                  else
                    ReportCategoryChartCard(
                      title: context.l10n.reportIncomesTitle,
                      fullData: incomeFull,
                      pieData: incomePie,
                      isExpense: false,
                      showBarChart: _showIncomeBarChart,
                      onToggleBarChart: (v) =>
                          setState(() => _showIncomeBarChart = v),
                      onCategoryTap: (cat, mode) =>
                          _openCategoryDetails(cat, false, mode),
                      budgetProgressFor: dataBuilder.budgetProgressFor,
                      categoryLabels: _categoryLabels,
                    ),
                  if (derived.budgetStatuses.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ReportSectionHeader(
                        title: context.l10n.reportBudgetSummaryTitle),
                    const SizedBox(height: 12),
                    ReportBudgetSummaryCard(
                      statuses: derived.budgetStatuses,
                      onTap: (status) => _openBudgetCategory(status),
                    ),
                  ],
                  if (derived.payeeGroups.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    ReportSectionHeader(
                        title: context.l10n.reportTopPayeesTitle),
                    const SizedBox(height: 12),
                    ReportTopPayeesCard(
                        groups: derived.payeeGroups,
                        onGroupTap: _openPayeeGroup),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String? message}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: AppCard(
          section: AppSection.transactions,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 48,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message ?? context.l10n.reportNoDataTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.buDonemIcinHenuz,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [_TransactionReportViewState._derive]'in ürettiği, bir build turunun
/// tamamına yeten türetilmiş veri.
class _ReportDerived {
  final ReportCategoryDataBuilder dataBuilder;
  final List<TransactionEntity> filtered;
  final ({
    List<TransactionEntity> spending,
    List<TransactionEntity> system
  }) split;
  final ReportTotals totals;
  final ReportTotals previousTotals;
  final List<CategoryData> expenseFull;
  final List<CategoryData> incomeFull;
  final List<CategoryData> expensePie;
  final List<CategoryData> incomePie;
  final List<CategoryData> incomeRanked;
  final List<CategoryData> expenseRanked;
  final ReportSeries flowSeries;
  final ReportSeries balanceSeries;
  final ReportSeries trendSeries;
  final List<BudgetStatus> budgetStatuses;
  final List<({String label, double total, List<TransactionEntity> items})>
      payeeGroups;

  const _ReportDerived({
    required this.dataBuilder,
    required this.filtered,
    required this.split,
    required this.totals,
    required this.previousTotals,
    required this.expenseFull,
    required this.incomeFull,
    required this.expensePie,
    required this.incomePie,
    required this.incomeRanked,
    required this.expenseRanked,
    required this.flowSeries,
    required this.balanceSeries,
    required this.trendSeries,
    required this.budgetStatuses,
    required this.payeeGroups,
  });
}
