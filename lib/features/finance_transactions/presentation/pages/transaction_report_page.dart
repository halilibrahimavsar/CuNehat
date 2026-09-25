import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:cunehat/core/shared/motion/period_transition.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_scope_chips.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/features/credit_card/presentation/card_context_rail.dart';
import 'dart:async';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/csv_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/category_details_bottom_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_compare_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_budget_summary_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_period_chart_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_top_payees_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_transaction_list_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_section_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_summary_cards.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/shared_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/analysis_empty_card.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/credit_card/domain/card_spending_merge.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
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
  /// Dönem İşlemler ve İçgörü ile ORTAK (bkz. `shared_period.dart`).
  DateTimeRange get _range => context.read<TransactionFilterCubit>().period;
  bool _showExpenseBarChart = false;
  bool _showIncomeBarChart = false;
  /// Varsayılan GİDER: raporun asıl sorusu "param nereye gitti" ve
  /// hiyerarşik çember (ana/alt kategori) yalnız tek taraflı modda var.
  /// Eski varsayılan "karşılaştırma" özetin üç sayısını ikinci kez yazıp
  /// çemberi bir dokunuş arkasına saklıyordu.
  FinanceMode _categoryMode = FinanceMode.expense;

  /// Kullanıcının seçtiği zaman çözünürlüğü; null ise aralığa göre otomatik
  /// (bkz. [ReportSeriesService.autoUnitFor]). Aralık DEĞİŞİNCE sıfırlanır:
  /// "Bu Yıl"da elle seçilen "Ay", "Bu Ay"a dönüldüğünde tek çubuk çizerdi.
  ReportBucketUnit? _unitOverride;

  /// Transfer/borç/yatırım kuplaj hareketleri gelir–gidere sayılsın mı?
  /// Varsayılan KAPALI: raporun sorusu "ne harcadım", oysa bu hareketlerde
  /// para harcanmaz, yer değiştirir (bkz.
  /// [TransactionReportService.splitSystemMovements]).
  bool _includeSystemMovements = false;

  /// Hesabın raporu bağlı kartlarının HARCAMALARINI da kapsasın mı ("kartlar
  /// dahil"; bkz. [mergeCardSpending]). Varsayılan KAPALI: kart cüzdanın
  /// içinde ayrı bir sekmedir; rapor önce hesabın kendi hareketidir. Bakiye
  /// çizgisi anahtardan bağımsız hep hesabın defteri.
  bool _includeCards = false;

  /// Bağlı kartların defterleri (birleşik); yalnız anahtar açıkken okunur.
  List<TransactionEntity> _cardLedger = const [];
  StreamSubscription<TransactionsChange>? _cardChangesSub;

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
    List<TransactionEntity> ledger,
    DateTimeRange range,
    bool includeSystem,
    ReportBucketUnit? unit,
    Map<String, String> roots,
    List<BudgetEntity> budgets,
    String otherLabel,
    Brightness brightness,
    double walletOpening,
    DateTime today,
  })? _derivedKey;
  _ReportDerived? _derivedCache;

  /// Kategori kırılımı/renk paleti/bütçe eşlemesi tek yerde; detay bottom
  /// sheet'i de aynı nesneyi alır.
  ReportCategoryDataBuilder _dataBuilder(BuildContext context) =>
      ReportCategoryDataBuilder(
        range: _range,
        budgets: _budgets,
        otherCategoryLabel: _otherLabel(context),
        rootIndex: _categoryRoots,
        includeSystemMovements: _includeSystemMovements,
      );

  /// Payı eşiğin altında kalan kalemleri toplayan sentetik kovanın adı.
  ///
  /// Kullanıcının GERÇEK bir "Diğer" kategorisi olabiliyor (başlangıç
  /// paketinde var). O zaman aynı listede iki satır aynı adı taşıyordu —
  /// cihazda ölçüldü: karşılaştırma kartının gider tarafında "Diğer %28" ve
  /// "Diğer %15" alt alta duruyor, hangisinin gerçek kategori hangisinin
  /// kova olduğu okunamıyordu. Ad çakışıyorsa kova KENDİ adını alır;
  /// çakışmıyorsa alışılmış "Diğer" kalır.
  String _otherLabel(BuildContext context) {
    final base = context.l10n.categoryDiger;
    final taken = _categoryLabels.values.any((label) => label == base);
    return taken ? context.l10n.reportOtherSmallItems : base;
  }

  @override
  void initState() {
    super.initState();
    // Sayfa cüzdan başına yeniden kurulur (bkz. SubViewFactory): ortak
    // dönemi bu cüzdanın bağlamına (kartsa ekstre döngüsü) eşitle.
    bindSharedPeriodTo(context, context.walletById(widget.walletId));
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
    _cardChangesSub?.cancel();
    super.dispose();
  }

  /// Bu hesaba bağlı, AYNI birimdeki kartlar (tutarlar tek birimde toplanır).
  /// Rapor bir kartın kendisininse ya da bayrak kapalıysa boş.
  List<WalletEntity> _linkedCards(BuildContext context) {
    if (!FeatureFlags.creditCards) return const [];
    final self = context.walletById(widget.walletId);
    if (self == null || self.isCreditCard) return const [];
    return [
      for (final c in cardsOf(widget.walletId, context.allWallets))
        if (c.currency == self.currency) c,
    ];
  }

  Future<void> _setIncludeCards(bool value) async {
    setState(() => _includeCards = value);
    await _cardChangesSub?.cancel();
    _cardChangesSub = null;
    if (!value) return;
    await _loadCardLedger();
    if (!mounted || !_includeCards) return;
    if (getIt.isRegistered<TransactionsChangedNotifier>()) {
      _cardChangesSub = getIt<TransactionsChangedNotifier>().stream.listen((c) {
        if (!mounted) return;
        final ids = _linkedCards(context).map((w) => w.id).toSet();
        if (c.walletId == null || ids.contains(c.walletId)) _loadCardLedger();
      });
    }
  }

  Future<void> _loadCardLedger() async {
    final cards = _linkedCards(context);
    if (!getIt.isRegistered<TransactionsRepository>()) return;
    final repo = getIt<TransactionsRepository>();
    final results = await Future.wait(cards
        .map((c) => repo.getTransactions(userId: c.userId, walletId: c.id!)));
    if (!mounted) return;
    setState(() {
      _cardLedger = [
        for (final r in results) ...r.getOrElse(() => const []),
      ];
    });
  }

  /// Analiz kaynağı: anahtar kapalıyken hesabın defteri; açıkken kart
  /// harcamaları katılmış liste. Girdi kimliklerine göre önbelleklenir
  /// ([_derive]'in önbelleği kimlik tabanlı).
  List<TransactionEntity>? _mergeAccountSource;
  List<TransactionEntity>? _mergeCardSource;
  List<TransactionEntity> _merged = const [];

  List<TransactionEntity> _analysisSource(List<TransactionEntity> account) {
    if (!_includeCards) return account;
    if (identical(_mergeAccountSource, account) &&
        identical(_mergeCardSource, _cardLedger)) {
      return _merged;
    }
    _mergeAccountSource = account;
    _mergeCardSource = _cardLedger;
    _merged = mergeCardSpending(account: account, cards: _cardLedger);
    return _merged;
  }

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
      categories = await fetchAllCategories(widget.categoryRepository);
    } catch (e, st) {
      reportError('Rapor · kategori indeksi', e, st);
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
    // Paylaşılan CSV de bu cüzdanın defteridir: süzülmediğinde başka
    // cüzdanların satırları dışarı gidiyordu.
    //
    // "Kartları dahil et" açıkken ekranda görülen kart harcamaları dosyaya da
    // girer (eskiden anahtar yok sayılıyordu). Para taşıma hareketleri ise
    // anahtardan bağımsız olarak HEP dosyadadır: CSV bir kayıt dökümüdür,
    // gelir–gider toplamı değil — transferi atmak defteri eksik gösterirdi.
    final filtered = _filterTransactionsByRange(
        _analysisSource(_forWallet(state.currentTransactions)));
    if (filtered.isEmpty) return;
    // Ay adı arayüz dilinde: locale'siz `DateFormat` sistem diline bağlanıp
    // Türkçe arayüzde "Sep" yazabiliyordu.
    final format =
        DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    final rangeLabel =
        '${format.format(_range.start)} – ${format.format(_range.end)}';
    await getIt<CsvService>().exportTransactionsToCSV(
      filtered,
      shareText: '${context.l10n.islemRaporu} ($rangeLabel)',
    );
  }

  List<TransactionEntity> _filterTransactionsByRange(
      List<TransactionEntity> transactions) {
    return _reportService.filterByRange(transactions, _range.start, _range.end);
  }

  /// Bloc state'i cüzdan geçişinde kısa süre ESKİ cüzdanın listesini taşır
  /// (`TransactionLoading.previousTransactions`). İşlemler sayfası bunu
  /// bilerek süzüyordu, rapor süzmüyordu: yabancı cüzdanın toplamları YENİ
  /// cüzdanın para birimi sembolüyle çiziliyor, üstelik
  /// [_maybeAdjustInitialRange] yabancı listenin son tarihine göre dönemi
  /// kaydırabiliyordu.
  ///
  /// Kaynak listenin KİMLİĞİNE göre önbelleklenir: her build'de yeni liste
  /// üretmek [_derive]'in kimlik tabanlı önbelleğini geçersiz kılar ve
  /// türetme her karede baştan çalışırdı.
  List<TransactionEntity>? _walletSource;
  List<TransactionEntity> _walletTransactions = const [];

  List<TransactionEntity> _forWallet(List<TransactionEntity> all) {
    if (identical(_walletSource, all)) return _walletTransactions;
    _walletSource = all;
    _walletTransactions =
        all.where((t) => t.walletId == widget.walletId).toList();
    return _walletTransactions;
  }

  /// Türetmeyi etkileyen "bugün". Gün hassasiyetinde: saat başına önbellek
  /// atmanın anlamı yok.
  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Bir build turunun türetilmiş rapor verisi — hepsi tek yerde, tek kez.
  ///
  /// [transactions] analiz evrenidir (kartlar dahilse onların harcamalarıyla
  /// birlikte); [ledger] hesabın KENDİ defteri — bakiye çizgisi yalnız ondan
  /// türer.
  _ReportDerived _derive(
    BuildContext context,
    List<TransactionEntity> transactions,
    List<TransactionEntity> ledger,
    Brightness brightness,
  ) {
    final otherLabel = _otherLabel(context);
    final walletOpening =
        context.walletById(widget.walletId)?.openingBalance ?? 0;

    // Anahtar, türetmeyi etkileyen HER girdiyi taşır. Listeler/haritalar
    // kimliğe göre karşılaştırılır ve hepsi `setState` ile bütün olarak
    // değiştiriliyor — yani kimlik değişimi gerçek bir veri değişimidir.
    final key = (
      transactions: transactions,
      ledger: ledger,
      range: _range,
      includeSystem: _includeSystemMovements,
      unit: _unitOverride,
      roots: _categoryRoots,
      budgets: _budgets,
      otherLabel: otherLabel,
      brightness: brightness,
      walletOpening: walletOpening,
      // BUGÜN de bir girdi: `_previousPeriodWindow` "yaşanmış" pencereyi
      // `DateTime.now()`tan türetiyor ve bütçe kartı içinde bulunulan aya
      // bakıyor. Anahtarda olmayınca gece yarısını geçen bir oturum, dünün
      // kıyas penceresini ve dünün ayını göstermeye devam ediyordu.
      today: _today(),
    );
    final cached = _derivedCache;
    if (cached != null && _derivedKey == key) return cached;

    final dataBuilder = ReportCategoryDataBuilder(
      range: _range,
      budgets: _budgets,
      otherCategoryLabel: otherLabel,
      rootIndex: _categoryRoots,
      includeSystemMovements: _includeSystemMovements,
    );
    final filtered = _filterTransactionsByRange(transactions);

    // Grafiklerin penceresi aralığın YAŞANMIŞ kısmıyla sınırlı (bkz.
    // [_chartEnd]); kartların ve toplamların penceresi ise aralığın kendisi.
    final chartEnd = _chartEnd(filtered);

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
      chartEnd: chartEnd,
      flowSeries: _seriesService.build(
        inRange: analysed,
        start: _range.start,
        end: chartEnd,
        unit: _unitOverride,
      ),
      balanceSeries: _seriesService.build(
        inRange: identical(transactions, ledger)
            ? filtered
            : _filterTransactionsByRange(ledger),
        start: _range.start,
        end: chartEnd,
        unit: _unitOverride,
        openingBalance: _seriesService.openingBalanceFor(
          all: ledger,
          start: _range.start,
          walletOpeningBalance: walletOpening,
        ),
      ),
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
  ///
  /// Kural TEK yerde ([ReportCategoryDataBuilder.universeOf]): kırılımı ayrıca
  /// hesaplayan alt sayfa da aynı fonksiyondan geçiyor.
  List<TransactionEntity> _universeOf(List<TransactionEntity> inRange) =>
      ReportCategoryDataBuilder.universeOf(inRange,
          includeSystemMovements: _includeSystemMovements);

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

  /// Dönemin bütçe durumları (hesap İçgörü ile ortak: [computeBudgetStatuses]).
  List<BudgetStatus> _budgetStatuses(
    BuildContext context,
    List<CategoryData> expenseFull,
  ) {
    return computeBudgetStatuses(
      budgets: _budgets,
      expenseFull: expenseFull,
      range: _range,
      labelFor: (tag) =>
          context.categoryLabelForTag(tag, labels: _categoryLabels),
    );
  }

  /// Akış grafiğinin başlığı çözünürlüğü İZLER: haftalık kovalarda "Günlük
  /// Gelir–Gider" yazmak, mağaza denetiminde yakalanan hatanın aynısıdır.
  String _flowTitle(BuildContext context, ReportBucketUnit unit) =>
      switch (unit) {
        ReportBucketUnit.day => context.l10n.reportFlowTitleDay,
        ReportBucketUnit.week => context.l10n.reportFlowTitleWeek,
        ReportBucketUnit.month => context.l10n.reportFlowTitleMonth,
      };

  /// Her çözünürlüğün ÇİZİLEN pencerede kaç kova ürettiği — seçicinin hangi
  /// seçeneği kapatacağına bununla karar verilir. Pencere [_chartEnd] ile
  /// sınırlı: aksi hâlde seçici "30 gün" derken grafik 10 çubuk çiziyordu.
  Map<ReportBucketUnit, int> _bucketCounts(DateTime chartEnd) => {
        for (final unit in ReportBucketUnit.values)
          unit: _seriesService.bucketCountFor(_range.start, chartEnd, unit),
      };

  /// Çözünürlük seçicisi çizilsin mi?
  ///
  /// [ReportSeriesService.autoUnitFor] 35 güne kadar zaten GÜN seçiyor ve bu
  /// doğru cevap: "Bu Ay"da haftalık kovaya inmek 4 çubuk bırakır. Seçici
  /// ancak otomatik seçimin gün OLMADIĞI aralıklarda (üç ay, bir yıl) bir işe
  /// yarıyor; kısa aralıklarda kalıcı bir çip satırından ibaretti.
  bool _showsUnitSelector(DateTime chartEnd) =>
      _seriesService.dayCount(_range.start, chartEnd) >
      ReportSeriesService.kMaxDailyDays;

  /// Grafiklerin çizeceği pencerenin SONU: seçili aralığın yaşanmış kısmı.
  ///
  /// **Neden:** "Bu Ay" ayın son gününe kadar sürer, ama ayın 10'undayken o
  /// ayın 20 günü henüz yaşanmadı. Eski hâlinde akış grafiğinin sağ üçte
  /// ikisi boş çubuk, bakiye çizgisi ise 21 gün boyunca DÜMDÜZ gidiyordu
  /// (ölçüldü, 411dp telefon: 30 kovanın 20'si gelecekte). Gelecek bir kova
  /// "para hareket etmedi" demek değil, "henüz olmadı" demektir — sıfır
  /// çizmek ikisini aynı şeye benzetiyor.
  ///
  /// Kesim BUGÜN değil, "bugün ya da aralıktaki EN SON kayıt": ileri tarihli
  /// bir işlem (planlanmış kira, onaylanmış düzenli kayıt) özet kartında
  /// sayılıyor; grafikten düşerse iki kart aynı dönem için farklı toplam
  /// gösterirdi. Yani çizilen pencere = yaşanmış kısım ∪ veri olan kısım.
  ///
  /// Aralık TAMAMEN gelecekteyse ve içinde kayıt yoksa kırpılmaz: kırpmak
  /// boş bir pencere üretir, oysa aralığın kendisi zaten boş ve bölüm hiç
  /// çizilmez.
  DateTime _chartEnd(List<TransactionEntity> inRange) {
    final end = DateTime(_range.end.year, _range.end.month, _range.end.day);
    final start =
        DateTime(_range.start.year, _range.start.month, _range.start.day);
    var cut = _today();
    for (final t in inRange) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      if (day.isAfter(cut)) cut = day;
    }
    if (!cut.isBefore(end) || cut.isBefore(start)) return end;
    return cut;
  }

  /// Bütçe satırına dokunmak o kategorinin dönem içi işlemlerini açar.
  void _openBudgetCategory(BudgetStatus status) {
    final builder = _dataBuilder(context);
    final full = builder.buildFull(
      builder.universeIn(
        _analysisSource(_forWallet(
            context.read<TransactionBloc>().state.currentTransactions)),
      ),
      isExpense: true,
    );

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

    // Dönemde hiç harcaması olmayan bütçe kırılımda yer almaz. Eskiden
    // dokunuş burada SESSİZCE boşa gidiyordu (satır düğme gibi görünüyor,
    // hiçbir şey olmuyor). Başlıklı, boş bir detay açılır: kullanıcı
    // bütçenin adını, limitini ve "işlem yok" bilgisini görür; dönem içinde
    // bir harcama eklenirse detay canlı olarak dolar.
    _openCategoryDetails(
      CategoryData(
        status.categoryId,
        0,
        const [],
        ReportCategoryPalette
            .colors[ReportCategoryPalette.preferredIndex(status.categoryId)],
      ),
      true,
      ReportSliceMode.full,
    );
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
      sourceOf: (all) => _analysisSource(_forWallet(all)),
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
            )
          : null,
      // Dönem ortak (bkz. `shared_period.dart`): başka bir sayfada değişince
      // bu sayfa da yeniden çizilir; elle seçilen çözünürlük ise yeni
      // dönemde anlamını yitirir ("62 kovayı aşan seçenek KAPALI" kuralı
      // aralığa bağlı) ve sıfırlanır. Eskiden burada "dönem boşsa verinin
      // olduğu aya SESSİZCE kay" mantığı vardı; ortak dönemi arka planda
      // değiştirmek diğer iki sayfayı da kaydırırdı — yerine boş durum kartı
      // "… dönemine git" eylemini sunar.
      // Kart şeridi gövdenin DIŞINDA: yükleniyor/boş hâllerinde de görünür.
      body: Column(
        children: [
          // Kart bağlamı (yalnız haplar; borç şeridi İşlemler'de).
          const CardContextRail(pillsOnly: true),
          Expanded(
            child: BlocListener<TransactionFilterCubit, CombinedFilter>(
              listenWhen: (prev, curr) =>
                  prev.viewFilter.startDate != curr.viewFilter.startDate ||
                  prev.viewFilter.endDate != curr.viewFilter.endDate,
              listener: (context, _) {
                if (_unitOverride != null) setState(() => _unitOverride = null);
              },
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  context.select((TransactionFilterCubit c) => c.period);
                  final transactions = _forWallet(state.currentTransactions);
                  if (state is TransactionLoading && transactions.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (transactions.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  final brightness =
                      (theme.extension<AppSurface>() ?? AppSurface.light).brightness;
                  final derived = _derive(
                      context, _analysisSource(transactions), transactions, brightness);
                  final linkedCards = _linkedCards(context);

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

                  // Dönem kontrolü YAPIŞKAN. Ölçüldü: sayfa 360×800 telefonda ~3
                  // ekran; kullanıcı ikinci ekranda hangi dönemin raporuna baktığını
                  // göremiyor ve dönemi değiştirmek için en başa dönmesi gerekiyordu.
                  return Column(
                    children: [
                      // Dönem kontrolü TEK satır: `‹ Eylül 2026 ›` + paylaş.
                      //
                      // Eskiden burada sayfa başlığı, aralık metni ("01 Eyl 2026 -
                      // 30 Eyl 2026"), takvim düğmesi ve yatay kayan hızlı çip
                      // satırı vardı. Ölçüldü (411dp telefon): yapışkan blok
                      // **188dp**, yani ekranın dörtte biri; üstelik çip satırı
                      // sağdan kırpıldığı için son çip "Son…" diye yarım
                      // görünüyordu. Aynı kontrol işlemler ekranında zaten 44dp'lik
                      // bir ay çubuğu ([TransactionPeriodBar]) — iki kardeş sayfanın
                      // dönemi farklı kontrollerle seçmesi için sebep yok.
                      //
                      // Hızlı seçenekler (Son 7 Gün, Bu Yıl…) kaybolmadı: etikete
                      // dokunmak onların menüsünü açar ([_pickDateRange]).
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                        child: Row(
                          children: [
                            const Expanded(child: SharedPeriodBar()),
                            // Paylaş düğmesi eskiden YALNIZ AppBar'daydı ve sayfa
                            // üretimde `showAppBar: false` ile kuruluyor (bkz.
                            // SubViewFactory) — yani CSV dışa aktarımı hiç
                            // erişilemiyordu, `_shareReport` ölü koddu.
                            IconButton(
                              icon: const Icon(Icons.ios_share_rounded),
                              tooltip: context.l10n.reportShareTooltip,
                              onPressed:
                                  filteredTransactions.isEmpty ? null : _shareReport,
                            ),
                          ],
                        ),
                      ),
                      // Kapsam (kartlar / para taşıma) dönemin yanında, yapışkan
                      // bölgede: ikisi de sayfanın TAMAMINI değiştiriyor (bkz.
                      // [ReportScopeChips]).
                      if (linkedCards.isNotEmpty || split.system.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ReportScopeChips(
                              cardCount: linkedCards.length,
                              cardsIncluded: _includeCards,
                              onCardsChanged: _setIncludeCards,
                              movedCount: split.system.length,
                              movedIncluded: _includeSystemMovements,
                              onMovedChanged: (v) =>
                                  setState(() => _includeSystemMovements = v),
                            ),
                          ),
                        ),
                      // İçerik yapışkan başlığın ALTINDAN kayıyor; ince bir çizgi
                      // olmadan kartlar başlığa yapışmış gibi görünüyor.
                      Divider(
                        height: 12,
                        thickness: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.06),
                      ),
                      Expanded(
                        child: PeriodTransition(
                          fill: true,
                          periodStart: _range.start,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (filteredTransactions.isEmpty) ...[
                                  _periodEmptyCard(context, transactions),
                                ] else ...[
                                  // Dönemde kayıt var ama gelir–gider evreni BOŞ (yalnız
                                  // para taşıma hareketi ya da harcamalar kartlarda):
                                  // 0/0 özet, "↓%100" rozeti ve boş eksenli grafik yerine
                                  // nedeni ve bir sonraki adımı söyleyen kart. Bakiye
                                  // çizgisi aşağıda yine çizilir — orada hareket var.
                                  if (totals.totalIncome == 0 &&
                                      totals.totalExpense == 0)
                                    _noFlowCard(
                                      context,
                                      transactions,
                                      movedCount: split.system.length,
                                      hasCards: linkedCards.isNotEmpty,
                                    )
                                  else ...[
                                    ReportSummaryCards(
                                      totals: totals,
                                      previousTotals: previousTotals,
                                    ),
                                    const SizedBox(height: 24),
                                    ReportSectionHeader(
                                        title: context.l10n.kategoriDagilimi),
                                    const SizedBox(height: 10),
                                    // Etiketli: ikon-yalnız segment (↗ ⇄ ↘)
                                    // anlamını yalnız ipucu metninde söylüyordu.
                                    LabeledSegment<FinanceMode>(
                                      selected: _categoryMode,
                                      onChanged: (m) =>
                                          setState(() => _categoryMode = m),
                                      items: [
                                        SegmentItem(
                                          value: FinanceMode.expense,
                                          label: context.l10n.reportModeExpense,
                                          color: FinanceMode.expense.primaryColor,
                                        ),
                                        SegmentItem(
                                          value: FinanceMode.income,
                                          label: context.l10n.reportModeIncome,
                                          color: FinanceMode.income.primaryColor,
                                        ),
                                        SegmentItem(
                                          value: FinanceMode.compare,
                                          label: context.l10n.reportModeBoth,
                                          color: FinanceMode.compare.primaryColor,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Mod değişimi (Gider · Gelir · İkisi) solarak ve yükseklik
                                    // yumuşakça değişerek olur; eskiden kart tek karede değişiyordu.
                                    _CategoryModeSwitch(
                                      mode: _categoryMode,
                                      child: isCompare
                                          ? ReportCompareChartCard(
                                              incomeSlices: derived.incomeRanked,
                                              expenseSlices: derived.expenseRanked,
                                              categoryLabels: _categoryLabels,
                                              // Bütçe ilerlemesi karşılaştırma modunda da görünür; eskiden
                                              // yalnız tek taraflı pasta kartına geçiriliyordu.
                                              budgetProgressFor: dataBuilder.budgetProgressFor,
                                              onSliceTap: (slice, isExpense) => _openCategoryDetails(
                                                  slice, isExpense, ReportSliceMode.ranked),
                                            )
                                          : _categoryMode == FinanceMode.expense
                                              ? ReportCategoryChartCard(
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
                                              : ReportCategoryChartCard(
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
                                    ),
                                    // ── ürün önceliğine göre sıra ────────────────────────
                                    // Ölçüldü: sayfa 360×800'de 2.761dp'ye (3,5 ekran)
                                    // çıkmıştı ve uygulamanın ASIL sorusu olan kategori
                                    // dağılımı 1507dp'de, iki ekran aşağıdaydı. Sıra artık
                                    // kullanıcının sorduğu sırayla: ne oldu → nereye gitti →
                                    // bütçeyi aştım mı → eğilim ne → tam olarak nereye.
                                    // Koşul BÜTÇE VARLIĞINA bakar, durum listesine değil:
                                    // aralık bir ay olmadığında liste boş döner ama bölüm
                                    // kaybolmamalı — kullanıcı bütçelerini silinmiş sanır.
                                    // Kart o durumda sebebini yazar.
                                    // Ay dışı aralıkta liste boştur ama kart sebebini
                                    // yazar; ay içinde liste boşsa (tüm limitler 0) kart
                                    // hiçbir şey çizmez — başlık da yetim kalmamalı.
                                    if (_budgets.isNotEmpty &&
                                        (derived.budgetStatuses.isNotEmpty ||
                                            !DateRangeHelper.isSingleCalendarMonth(
                                                _range))) ...[
                                      const SizedBox(height: 24),
                                      ReportSectionHeader(
                                          title: context.l10n.reportBudgetSummaryTitle),
                                      const SizedBox(height: 12),
                                      ReportBudgetSummaryCard(
                                        statuses: derived.budgetStatuses,
                                        monthScoped:
                                            DateRangeHelper.isSingleCalendarMonth(_range),
                                        onTap: _openBudgetCategory,
                                      ),
                                    ],
                                  ],
                                  // Dönem içi seyir: akış çubukları ve bakiye çizgisi
                                  // AYNI kartta, aynı zaman ekseninde (bkz.
                                  // [ReportPeriodChartCard]). Bölüm, çizilecek bir şey
                                  // varken kurulur — grafik kendini gizlediğinde geriye
                                  // başlık + seçici + BOŞLUK kalıyordu.
                                  if (ReportPeriodChartCard.hasContent(
                                    flowSeries: flowSeries,
                                    balanceSeries: balanceSeries,
                                  )) ...[
                                    const SizedBox(height: 24),
                                    ReportSectionHeader(
                                      // Başlık çözünürlüğü İZLER: haftalık kovalarda
                                      // "Günlük Gelir–Gider" yazmak mağaza denetiminde
                                      // yakalanan hatanın aynısıdır. Akış boşsa (dönemde
                                      // yalnız kuplaj hareketi var) kart tek başına
                                      // bakiyeyi çizer, başlık da onu söyler.
                                      title: flowSeries.hasNoActivity
                                          ? context.l10n.reportBalanceTrend
                                          : _flowTitle(context, flowSeries.unit),
                                      // Çözünürlük seçicisi yalnız GEREKTİĞİNDE: bir ayı
                                      // ya da daha kısa bir aralığı günlük çizmek her
                                      // zaman doğru cevap, seçenek sunmak boşuna bir
                                      // çip satırı demekti.
                                      trailing: _showsUnitSelector(derived.chartEnd)
                                          ? ReportUnitSelector(
                                              selected: flowSeries.unit,
                                              bucketCounts:
                                                  _bucketCounts(derived.chartEnd),
                                              onChanged: (u) =>
                                                  setState(() => _unitOverride = u),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    ReportPeriodChartCard(
                                      flowSeries: flowSeries,
                                      balanceSeries: balanceSeries,
                                    ),
                                  ],
                                  if (derived.payeeGroups.isNotEmpty) ...[
                                    const SizedBox(height: 24),
                                    ReportSectionHeader(
                                        title: context.l10n.reportTopPayeesTitle),
                                    const SizedBox(height: 12),
                                    ReportTopPayeesCard(
                                      groups: derived.payeeGroups,
                                      onGroupTap: _openPayeeGroup,
                                      periodExpenseTotal: derived.totals.totalExpense,
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Seçili dönemin dışındaki en yakın HAREKETLİ döneme götüren eylem.
  ///
  /// Hareket, sayfanın gösterdiği evrende aranır (kuplaj anahtarı ve kartlar
  /// dahil): yalnız transfer olan bir aya götürmek kullanıcıyı aynı boş
  /// karta bırakırdı. Hedef, oklarla ulaşılan hizadadır
  /// ([periodContainingDay]).
  AnalysisEmptyAction? _jumpAction(
      BuildContext context, List<TransactionEntity> account) {
    final day = nearestDayOutside(
      _universeOf(_analysisSource(account)).map((t) => t.date),
      _range,
    );
    if (day == null) return null;
    final target = periodContainingDay(_range, day);
    return (
      label: context.l10n
          .analysisJumpToPeriod(periodLabel(target, context.l10n)),
      onTap: () => context.read<TransactionFilterCubit>().setPeriod(target),
    );
  }

  Widget _periodEmptyCard(
      BuildContext context, List<TransactionEntity> account) {
    final jump = _jumpAction(context, account);
    return AnalysisEmptyCard(
      icon: Icons.event_busy_rounded,
      title: context.l10n.msgSecilenTarihAraligindaIslem,
      lines: [context.l10n.analysisPeriodEmptyBody],
      actions: [if (jump != null) jump],
    );
  }

  Widget _noFlowCard(
    BuildContext context,
    List<TransactionEntity> account, {
    required int movedCount,
    required bool hasCards,
  }) {
    final l10n = context.l10n;
    final offerCards = hasCards && !_includeCards;
    final offerMoved = movedCount > 0 && !_includeSystemMovements;
    final jump = _jumpAction(context, account);
    return AnalysisEmptyCard(
      icon: Icons.swap_horiz_rounded,
      title: l10n.analysisNoFlowTitle,
      lines: [
        if (movedCount > 0) l10n.analysisNoFlowMoved(movedCount),
        if (offerCards) l10n.analysisNoFlowCards,
      ],
      actions: [
        // Kart önce: bu durumun en sık sebebi harcamanın kartta olması.
        if (offerCards)
          (
            label: l10n.analysisIncludeCards,
            onTap: () => _setIncludeCards(true),
          ),
        if (offerMoved)
          (
            label: l10n.analysisIncludeMoved,
            onTap: () => setState(() => _includeSystemMovements = true),
          ),
        if (jump != null) jump,
      ],
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

  /// Grafiklerin çizdiği pencerenin sonu (bkz.
  /// [_TransactionReportViewState._chartEnd]).
  final DateTime chartEnd;
  final ReportSeries flowSeries;
  final ReportSeries balanceSeries;
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
    required this.chartEnd,
    required this.flowSeries,
    required this.balanceSeries,
    required this.budgetStatuses,
    required this.payeeGroups,
  });
}

/// Kategori kartının mod geçişi: yükseklik yumuşak, kart solarak değişir.
/// Azaltılmış harekette anında (bkz. [AppMotion]).
class _CategoryModeSwitch extends StatelessWidget {
  final FinanceMode mode;
  final Widget child;

  const _CategoryModeSwitch({required this.mode, required this.child});

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    return AnimatedSize(
      duration: motion.d(AppMotion.medium),
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: motion.d(AppMotion.medium),
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.exit,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, if (current != null) current],
        ),
        child: KeyedSubtree(key: ValueKey(mode), child: child),
      ),
    );
  }
}
