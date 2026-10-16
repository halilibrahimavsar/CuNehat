import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/core/shared/motion/period_transition.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_scope_chips.dart';
import 'package:cunehat/features/credit_card/presentation/card_context_rail.dart';
import 'dart:async';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/csv_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
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
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/category_details_bottom_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_explorer.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_trend_card.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_trend.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_budget_summary_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_top_payees_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_transaction_list_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_section_header.dart';
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
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/forecast/data/forecast_service.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_link_tile.dart';
import 'package:cunehat/features/forecast/presentation/widgets/report_temp_budget_section.dart';
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
        userId: userId,
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

  /// Tek seferlik bütçe kartının tahmini kullanıcının tüm cüzdanlarını okur.
  final String userId;

  const _TransactionReportView({
    required this.showAppBar,
    required this.categoryRepository,
    required this.userId,
    required this.walletId,
  });

  @override
  State<_TransactionReportView> createState() => _TransactionReportViewState();
}

class _TransactionReportViewState extends State<_TransactionReportView> {
  /// Dönem İşlemler ve İçgörü ile ORTAK (bkz. `shared_period.dart`).
  DateTimeRange get _range => context.read<TransactionFilterCubit>().period;

  /// Zaman çizgisinin ölçüsü. Varsayılan GİDER: raporun asıl sorusu "param
  /// nereye gidiyor"; kullanıcı açılışta çizgi grafiği görmek istedi.
  TrendMetric _metric = TrendMetric.expense;

  /// Zaman çizgisi çizgi mi (varsayılan) çubuk mu.
  bool _trendAsLine = true;

  /// Kategori keşfinin tarafı. Ölçüyle eşitlenir: Gelir ölçüsü seçilince
  /// keşif de gelire geçer (Net/Bakiye'de olduğu yerde kalır).
  bool _sideIsExpense = true;

  /// Keşifte inilen yol. Sayfada durur çünkü zaman çizgisini de süzer;
  /// dönem değişince KORUNUR, yeni dönemde bulunamayan kısmı türetmede
  /// kırpılır (bkz. [ReportCategoryDataBuilder.resolvePath]).
  List<CategoryPathStep> _focusPath = const [];

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
  /// Ham hâl (CSV, kimlik eşleme) ve ödeme gününe taşınmış hâl (analiz;
  /// bkz. [datedByPayment]) ayrı tutulur.
  List<TransactionEntity> _cardLedger = const [];
  List<TransactionEntity> _cardLedgerRaw = const [];
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

  /// Zaman çizgisinin eksenini dönem sonuna uzatmak için kova tavanı
  /// (çözünürlük seçicisinin "okunur" sınırıyla aynı).
  static const _kMaxTrendBuckets = 62;
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
    bool sideIsExpense,
    List<CategoryPathStep> focusPath,
    Map<String, String> roots,
    List<BudgetEntity> budgets,
    String otherLabel,
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
      _cardLedgerRaw = [
        for (final r in results) ...r.getOrElse(() => const []),
      ];
      // Kart harcaması ÖDENDİĞİ aya sayılır: her kart kendi kesim/son ödeme
      // günüyle taşınır.
      _cardLedger = [
        for (var i = 0; i < cards.length; i++)
          ...datedByPayment(
            results[i].getOrElse(() => const []),
            cards[i].creditCard!,
          ),
      ];
    });
  }

  /// Analiz kaynağı: anahtar kapalıyken hesabın defteri; açıkken kart
  /// harcamaları katılmış liste. Girdi kimliklerine göre önbelleklenir
  /// ([_derive]'in önbelleği kimlik tabanlı).
  ///
  /// Kart harcamaları ÖDEME gününe taşınır ([datedByPayment]): rapor bir
  /// kartın (ya da "kartlar dahil" hesabın) harcamasını parasının ödendiği
  /// aya sayar. Kayıtların kendisi değişmez; CSV ve ayrıntı listesi ham
  /// tarihi gösterir ([_rawOf]).
  ///
  /// Kartın KENDİ dönemi bir ekstre dönemiyse kendi harcaması taşınmaz:
  /// ekstre o aralıkta yapılan harcamadır (bkz. İçgörü'deki `_analysisOf`,
  /// smoke test C-52).
  List<TransactionEntity>? _mergeAccountSource;
  List<TransactionEntity>? _mergeCardSource;
  WalletEntity? _mergeSelf;
  bool? _mergeIncludeCards;
  bool? _mergeStatement;
  List<TransactionEntity> _merged = const [];

  List<TransactionEntity> _analysisSource(List<TransactionEntity> account) {
    final self = context.walletById(widget.walletId);
    final statement = context.read<TransactionFilterCubit>().isStatementPeriod;
    if (identical(_mergeAccountSource, account) &&
        identical(_mergeCardSource, _cardLedger) &&
        identical(_mergeSelf, self) &&
        _mergeIncludeCards == _includeCards &&
        _mergeStatement == statement) {
      return _merged;
    }
    _mergeAccountSource = account;
    _mergeCardSource = _cardLedger;
    _mergeSelf = self;
    _mergeIncludeCards = _includeCards;
    _mergeStatement = statement;
    final selfCard = FeatureFlags.creditCards ? self?.creditCard : null;
    final base = selfCard == null || statement
        ? account
        : datedByPayment(account, selfCard);
    _merged = _includeCards
        ? mergeCardSpending(account: base, cards: _cardLedger)
        : base;
    return _merged;
  }

  /// Analiz kopyasının (ödeme gününe taşınmış) HAM kaydı — CSV ve ayrıntı
  /// listesi kullanıcının girdiği tarihi göstersin.
  TransactionEntity _rawOf(TransactionEntity t) {
    final id = t.id;
    if (id == null) return t;
    for (final r in _forWallet(
        context.read<TransactionBloc>().state.currentTransactions)) {
      if (r.id == id) return r;
    }
    for (final r in _cardLedgerRaw) {
      if (r.id == id) return r;
    }
    return t;
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
    // Dönem üyeliği raporla AYNI (kart harcaması ödeme ayında); dosyaya ise
    // kaydın kendi tarihi yazılır.
    final filtered = _filterTransactionsByRange(
            _analysisSource(_forWallet(state.currentTransactions)))
        .map(_rawOf)
        .toList();
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
      sideIsExpense: _sideIsExpense,
      focusPath: _focusPath,
      roots: _categoryRoots,
      budgets: _budgets,
      otherLabel: otherLabel,
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

    final expensePie = dataBuilder.buildPie(expenseFull);
    final incomePie = dataBuilder.buildPie(incomeFull);

    // ── kategori odağı ───────────────────────────────────────────────────
    final sideTop = _sideIsExpense ? expensePie : incomePie;
    final focusNodes =
        ReportCategoryDataBuilder.resolvePath(sideTop, _focusPath);
    final focusNode = focusNodes.isEmpty ? null : focusNodes.last;
    final focusTest = focusNode == null
        ? null
        : dataBuilder.focusFilter(focusNode, isExpense: _sideIsExpense);
    List<TransactionEntity> focused(List<TransactionEntity> list) =>
        focusTest == null ? list : list.where(focusTest).toList();

    // ── zaman çizgisi ────────────────────────────────────────────────────
    // Çözünürlük YAŞANMIŞ pencereden seçilir (bkz. [_chartEnd]); güncel
    // çizgi orada biter. Önceki dönemde hareket varsa eksen dönemin SONUNA
    // uzar: kesikli çizgi "geçen ay ay sonunda ne olmuştu"yu da gösterir.
    // Önceki dönem boşsa uzatmak yalnız boş bir sağ yarı çizerdi.
    final unit =
        _unitOverride ?? _seriesService.autoUnitFor(_range.start, chartEnd);
    final previousPeriod = shiftPeriod(_range, -1);
    final previousFlow = _seriesService.build(
      inRange: focused(_universeOf(_reportService.filterByRange(
          transactions, previousPeriod.start, previousPeriod.end))),
      start: previousPeriod.start,
      end: previousPeriod.end,
      unit: unit,
    );
    final elapsedCount =
        _seriesService.bucketCountFor(_range.start, chartEnd, unit);
    final fullCount =
        _seriesService.bucketCountFor(_range.start, _range.end, unit);
    final axisEnd = !previousFlow.hasNoActivity &&
            fullCount > elapsedCount &&
            fullCount <= _kMaxTrendBuckets
        ? _range.end
        : chartEnd;
    final ledgerInRange = identical(transactions, ledger)
        ? filtered
        : _filterTransactionsByRange(ledger);

    final derived = _ReportDerived(
      dataBuilder: dataBuilder,
      filtered: filtered,
      split: split,
      totals: _reportService.calculateTotals(analysed),
      previousTotals: _previousPeriodTotals(transactions),
      expenseFull: expenseFull,
      incomeFull: incomeFull,
      expensePie: expensePie,
      incomePie: incomePie,
      focusNodes: focusNodes,
      chartEnd: chartEnd,
      elapsedCount: elapsedCount,
      // İKİ ayrı seri kurulur ve bu bilinçlidir:
      //  • akış özetle AYNI evreni gösterir (kuplaj hareketleri hariç
      //    tutulmuşsa onlarda da yok; odak varsa yalnız o kategori);
      //  • bakiye defterin TAMAMINDAN türer — transferi düşmek bakiyeyi
      //    cüzdanın gerçek bakiyesinden koparırdı.
      flowSeries: _seriesService.build(
        inRange: focused(analysed),
        start: _range.start,
        end: axisEnd,
        unit: unit,
      ),
      balanceSeries: _seriesService.build(
        inRange: ledgerInRange,
        start: _range.start,
        end: axisEnd,
        unit: unit,
        openingBalance: _seriesService.openingBalanceFor(
          all: ledger,
          start: _range.start,
          walletOpeningBalance: walletOpening,
        ),
      ),
      previousFlow: previousFlow,
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

  /// Karşılaştırma penceresi: önceki dönemin, bu dönemin YAŞANMIŞ kısmı
  /// kadar başı (bkz. [comparisonWindowFor] — İçgörü ile ortak). Aralık
  /// tamamen gelecekteyse null.
  ({DateTime start, DateTime end})? _previousPeriodWindow() =>
      comparisonWindowFor(_range, now: _today());

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

    // Bütçe alt kategoriye de konabiliyor: arama kökler + çocuklar.
    final hit = ReportCategoryDataBuilder.findSlice(
      full,
      CategoryData(status.categoryId, 0, const [], Colors.transparent),
    );
    if (hit != null) {
      _openCategoryDetails(hit, true, ReportSliceMode.full);
      return;
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
  Widget _tempBudgetSection(BuildContext context) {
    final filter = context.read<TransactionFilterCubit>();
    return ReportTempBudgetSection(
      userId: widget.userId,
      walletId: widget.walletId,
      range: _range,
      periodOf: () => filter.periodPreferences.periodContaining(DateTime.now()),
      onTap: _openTempBudget,
      service: getIt<ForecastService>(),
      transactions: getIt<TransactionsChangedNotifier>(),
      budgets: getIt<BudgetsChangedNotifier>(),
    );
  }

  /// Geçici bütçenin saydığı işlemler: aralığındaki, kategorilerindeki
  /// harcama (kart cüzdanında ödeme gününe göre — bütçe hesabıyla aynı).
  void _openTempBudget(BudgetOutlook outlook, Set<String> tags) {
    final source = _analysisSource(
        _forWallet(context.read<TransactionBloc>().state.currentTransactions));
    final start = outlook.periodStart;
    final endExclusive = DateTime(outlook.periodEnd.year,
        outlook.periodEnd.month, outlook.periodEnd.day + 1);
    final items = [
      for (final t in source)
        if (!t.isIncome &&
            isSpendingMovement(t) &&
            tags.contains(t.tag) &&
            !t.date.isBefore(start) &&
            t.date.isBefore(endExclusive))
          _rawOf(t),
    ];
    ReportTransactionListSheet.show(
      context: context,
      title: outlook.temp?.name ?? '',
      transactions: items,
      isExpense: true,
      categoryIcons: _categoryIcons,
      categoryLabels: _categoryLabels,
    );
  }

  void _openPayeeGroup(String label, List<TransactionEntity> items) {
    ReportTransactionListSheet.show(
      context: context,
      title: label,
      // Gösterilen tarih kaydın kendisi (kart harcaması analizde ödeme
      // gününe taşınmış olabilir).
      transactions: items.map(_rawOf).toList(),
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
      displayOf: _rawOf,
    );
  }

  /// Gelir–gider evreni boş mu (dönemde yalnız para taşıma ya da kart)?
  /// "En çok harcanan yerler" kategori dağılımının KOPYASI mı?
  ///
  /// Not yazmayan kullanıcıda kaydın başlığı kategorinin adıdır; o zaman
  /// "yerler" listesi "Market 2.590 ₺, Yemek 780 ₺" diye bir üstteki kategori
  /// listesini tekrar eder (cihazda görüldü). Tek bir kayıt bile kendi
  /// başlığını taşıyorsa bölüm gösterilir.
  bool _payeesMirrorCategories(_ReportDerived derived) {
    String norm(String text) => text.trim().toLowerCase();
    for (final group in derived.payeeGroups) {
      for (final t in group.items) {
        if (norm(t.title) != norm(_categoryLabels[t.tag] ?? t.tag)) {
          return false;
        }
      }
    }
    return true;
  }

  bool _hasNoFlow(ReportTotals totals) =>
      totals.totalIncome == 0 && totals.totalExpense == 0;

  /// Zaman çizgisinin çizecek bir şeyi var mı? Akış boşsa bakiyeye bakılır:
  /// yalnız transfer içeren bir dönemde de bakiye hareket etmiştir.
  bool _hasTrend(_ReportDerived d) =>
      !d.flowSeries.hasNoActivity || !d.balanceSeries.hasNoActivity;

  void _setMetric(TrendMetric metric) {
    setState(() {
      _metric = metric;
      final side = switch (metric) {
        TrendMetric.expense => true,
        TrendMetric.income => false,
        _ => _sideIsExpense,
      };
      if (side != _sideIsExpense) {
        _sideIsExpense = side;
        _focusPath = const [];
      }
    });
  }

  void _setSide(bool isExpense) {
    if (isExpense == _sideIsExpense) return;
    setState(() {
      _sideIsExpense = isExpense;
      _focusPath = const [];
      if (_metric == TrendMetric.expense || _metric == TrendMetric.income) {
        _metric = isExpense ? TrendMetric.expense : TrendMetric.income;
      }
    });
  }

  void _setFocusPath(List<CategoryPathStep> path) =>
      setState(() => _focusPath = path);

  Widget _buildTrendCard(BuildContext context, _ReportDerived derived) {
    final totals = derived.totals;
    final node = derived.focusNodes.isEmpty ? null : derived.focusNodes.last;
    final sideTotal = _sideIsExpense ? totals.totalExpense : totals.totalIncome;
    final flow = derived.flowSeries;

    return ReportTrendCard(
      // Akış boşken (yalnız para taşıma) çizilebilecek tek şey bakiye.
      metric: _hasNoFlow(totals) ? TrendMetric.balance : _metric,
      onMetricChanged: _setMetric,
      asLine: _trendAsLine,
      onAsLineChanged: (v) => setState(() => _trendAsLine = v),
      totals: totals,
      previousTotals: derived.previousTotals,
      flow: flow,
      balance: derived.balanceSeries,
      previousFlow: derived.previousFlow,
      elapsedCount: derived.elapsedCount,
      currentLabel: periodLabel(_range, context.l10n),
      previousLabel: periodLabel(shiftPeriod(_range, -1), context.l10n),
      focus: node == null
          ? null
          : ReportTrendFocus(
              label: node.labelIn(context, _categoryLabels),
              color: node.color,
              amount: node.totalAmount,
              previousAmount: node.previousAmount,
              share: sideTotal <= 0 ? 0 : node.totalAmount / sideTotal,
              isExpense: _sideIsExpense,
            ),
      onClearFocus: () => _setFocusPath(const []),
      // Çözünürlük seçicisi yalnız GEREKTİĞİNDE: bir ayı ya da daha kısa bir
      // aralığı günlük çizmek her zaman doğru cevap.
      unitSelector: _showsUnitSelector(derived.chartEnd)
          ? ReportUnitSelector(
              selected: flow.unit,
              bucketCounts: _bucketCounts(derived.chartEnd),
              onChanged: (u) => setState(() => _unitOverride = u),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
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

                  final derived = _derive(
                      context, _analysisSource(transactions), transactions);
                  final linkedCards = _linkedCards(context);

                  final filteredTransactions = derived.filtered;
                  final split = derived.split;
                  final totals = derived.totals;

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
                              onPressed: filteredTransactions.isEmpty
                                  ? null
                                  : _shareReport,
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
                                  // 0/0 özet ve boş eksenli grafik yerine nedeni ve bir
                                  // sonraki adımı söyleyen kart. Zaman çizgisi o zaman
                                  // bakiyeyi çizer — orada hareket var.
                                  if (_hasNoFlow(totals))
                                    _noFlowCard(
                                      context,
                                      transactions,
                                      movedCount: split.system.length,
                                      hasCards: linkedCards.isNotEmpty,
                                    ),
                                  // Sıra, uygulamayı yeni açan kişinin sorduğu sırayla:
                                  // NEREYE gitti (kategori) → nasıl gidiyor (zaman) →
                                  // bütçeyi aştım mı → tam olarak nereye (yerler).
                                  //
                                  // Eskiden zaman grafiği öndeydi. Temiz kurulumda acemi
                                  // gibi kullanılırken görüldü (13 Eki 2026): "param
                                  // nereye gidiyor?" sorusunun yanıtı olan kategori
                                  // dağılımı ikinci ekranda kalıyor, önce anlamı
                                  // açıklanmayan birikimli bir çizgi çıkıyordu.
                                  if (!_hasNoFlow(totals)) ...[
                                    const SizedBox(height: 8),
                                    ReportSectionHeader(
                                      title: context.l10n.kategoriDagilimi,
                                      trailing: _SideChips(
                                        isExpense: _sideIsExpense,
                                        onChanged: _setSide,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ReportCategoryExplorer(
                                      isExpense: _sideIsExpense,
                                      top: _sideIsExpense
                                          ? derived.expensePie
                                          : derived.incomePie,
                                      nodes: derived.focusNodes,
                                      onPathChanged: _setFocusPath,
                                      onOpenTransactions: (node) =>
                                          _openCategoryDetails(
                                              node,
                                              _sideIsExpense,
                                              ReportSliceMode.pie),
                                      budgetProgressFor:
                                          derived.dataBuilder.budgetProgressFor,
                                      categoryLabels: _categoryLabels,
                                    ),
                                  ],
                                  if (_hasTrend(derived)) ...[
                                    const SizedBox(height: 24),
                                    _buildTrendCard(context, derived),
                                  ],
                                  if (!_hasNoFlow(totals)) ...[
                                    // Bütçe limitleri aylık; dönem bir ay değilse limit
                                    // döneme ORANTILANIR ve kart bunu yazar (bkz.
                                    // [computeBudgetStatuses]). Liste boşsa (tüm limitler
                                    // 0) başlık da çizilmez.
                                    if (derived.budgetStatuses.isNotEmpty) ...[
                                      const SizedBox(height: 24),
                                      ReportSectionHeader(
                                          title: context
                                              .l10n.reportBudgetSummaryTitle),
                                      const SizedBox(height: 12),
                                      ReportBudgetSummaryCard(
                                        statuses: derived.budgetStatuses,
                                        periodDays: _seriesService.dayCount(
                                            _range.start, _range.end),
                                        periodMonths:
                                            DateRangeHelper.wholeMonthCount(
                                                _range),
                                        onTap: _openBudgetCategory,
                                      ),
                                    ],
                                  ],
                                  // Tek seferlik bütçeler: seçili dönemle
                                  // kesişenler — biten sonucuyla, süren
                                  // tahminiyle. Servis kayıtlı değilse
                                  // (yalıtılmış sayfa testleri) bölüm yok.
                                  if (getIt.isRegistered<ForecastService>())
                                    _tempBudgetSection(context),
                                  if (derived.payeeGroups.isNotEmpty &&
                                      !_payeesMirrorCategories(derived)) ...[
                                    const SizedBox(height: 24),
                                    ReportSectionHeader(
                                        title:
                                            context.l10n.reportTopPayeesTitle),
                                    const SizedBox(height: 12),
                                    ReportTopPayeesCard(
                                      groups: derived.payeeGroups,
                                      onGroupTap: _openPayeeGroup,
                                      periodExpenseTotal:
                                          derived.totals.totalExpense,
                                    ),
                                  ],
                                  if (rangeContainsToday(_range))
                                    const ForecastLinkTile(),
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
      label:
          context.l10n.analysisJumpToPeriod(periodLabel(target, context.l10n)),
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

  /// Keşifte inilen yolun GEÇERLİ kısmı (bkz. [ReportCategoryDataBuilder.
  /// resolvePath]); boşsa odak yok.
  final List<CategoryData> focusNodes;

  /// Grafiklerin çizdiği pencerenin sonu (bkz.
  /// [_TransactionReportViewState._chartEnd]).
  final DateTime chartEnd;

  /// Eksendeki yaşanmış kova sayısı (güncel çizgi burada biter).
  final int elapsedCount;
  final ReportSeries flowSeries;
  final ReportSeries balanceSeries;
  final ReportSeries previousFlow;
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
    required this.focusNodes,
    required this.chartEnd,
    required this.elapsedCount,
    required this.flowSeries,
    required this.balanceSeries,
    required this.previousFlow,
    required this.budgetStatuses,
    required this.payeeGroups,
  });
}

/// Kategori keşfinin tarafı: Gider · Gelir. Bölüm başlığının sağında
/// küçük çipler — üstteki ölçü seçicisiyle aynı ağırlıkta ikinci bir segment
/// sayfayı kalabalıklaştırıyordu.
class _SideChips extends StatelessWidget {
  final bool isExpense;
  final ValueChanged<bool> onChanged;

  const _SideChips({required this.isExpense, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        ChoiceChip(
          label: Text(context.l10n.reportModeExpense),
          selected: isExpense,
          onSelected: (_) => onChanged(true),
          visualDensity: VisualDensity.compact,
        ),
        ChoiceChip(
          label: Text(context.l10n.reportModeIncome),
          selected: !isExpense,
          onSelected: (_) => onChanged(false),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
