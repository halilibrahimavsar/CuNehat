import 'package:cunehat/core/shared/motion/period_transition.dart';
import 'package:cunehat/features/credit_card/presentation/card_context_rail.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/config/theme/money_colors.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_category_data.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_budget_summary_card.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'dart:async';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_analytics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/category_spike_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/insight_budget_cards.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/insight_stat_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/insight_widgets/recurring_suggestion_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/analysis_empty_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_section_header.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/report_widgets/report_transaction_list_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/shared_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_occurrences.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_pattern_detector.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_suggestion_dismiss_store.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/get_all_recurring_templates_usecase.dart';
import 'package:cunehat/features/recurring_transactions/domain/usecases/save_recurring_transaction_usecase.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

/// "Akıllı İçgörüler" — transactions sekmesinin ilk swipe sayfası.
///
/// **Rapor sayfasından farkı bilinçli:** rapor "ne oldu" sorusunu grafiklerle
/// yanıtlar; bu sayfa "şimdi ne yapmalıyım" sorusunu yanıtlar. Bu yüzden
/// sıralama da öyle: önce dönemin durumu (harcanabilir tutar / açık) ve
/// uyarılar, sonra dönemin özeti, en sonda alışkanlık ve eyleme dönüşebilen
/// düzenli ödeme önerileri.
///
/// Cihaz içinde, paketsiz istatistikle çalışır (bkz.
/// [TransactionAnalyticsService], [RecurringPatternDetector]).
class TransactionInsightsPage extends StatelessWidget {
  final String userId;
  final String walletId;
  final bool showAppBar;

  const TransactionInsightsPage({
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
      child: _InsightsView(
        userId: userId,
        walletId: walletId,
        showAppBar: showAppBar,
      ),
    );
  }
}

/// Bir build turunun türetilmiş içgörü verisi.
typedef _InsightsDerived = ({
  TransactionInsights insights,
  List<RecurringSuggestion> suggestions,
  List<BudgetStatus> budgetStatuses,
});

class _InsightsView extends StatefulWidget {
  final String userId;
  final String walletId;
  final bool showAppBar;

  const _InsightsView({
    required this.userId,
    required this.walletId,
    required this.showAppBar,
  });

  @override
  State<_InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<_InsightsView> {
  static const _analytics = TransactionAnalyticsService();
  static const _detector = RecurringPatternDetector();

  /// Seçili dönem kullanıcının biriminde bugünü içeren dönem mi?
  bool _isCurrentUnitPeriod() {
    final cubit = context.read<TransactionFilterCubit>();
    final base = cubit.periodPreferences.periodContaining(DateTime.now());
    return base.start == dayOf(_range.start) &&
        isDayInRange(base.end, _range) &&
        isDayInRange(_range.end, base);
  }

  /// Dönem İşlemler ve Rapor ile ORTAK (bkz. `shared_period.dart`).
  DateTimeRange get _range => context.read<TransactionFilterCubit>().period;

  /// Mevcut şablonlar; null = henüz yükleniyor.
  List<RecurringTransactionEntity>? _templates;

  /// "Yoksay" denen öneri anahtarları (kalıcı) + bu oturumda eklenenler.
  Set<String> _dismissed = {};

  /// `tag` → görünen ad; analiz hep `tag` üzerinden gruplar, bu harita
  /// yalnız gösterim içindir.
  Map<String, String> _categoryLabels = {};

  /// `id → kök id`; analiz KÖK seviyede toplar (bkz. buildRootIndex).
  Map<String, String> _categoryRoots = {};

  /// Kırılım sayfası (`ReportTransactionListSheet`) için ikonlar.
  Map<String, IconData> _categoryIcons = {};

  StreamSubscription<void>? _categoriesSub;

  /// Cüzdanın bütçe limitleri — "Durum" bölümündeki bütçe uyarısı için.
  /// Hesap Rapor ile ORTAK ([computeBudgetStatuses]); iki sayfa "bütçemi
  /// aştım mı" sorusuna farklı cevap vermesin. Eskiden bütçe yalnız Rapor'da
  /// vardı, bu sayfanın "iyi miyim" cevabı yalnız nete bakıyordu.
  List<BudgetEntity> _budgets = const [];
  StreamSubscription<void>? _budgetsSub;

  /// Türetilmiş verinin önbelleği.
  ///
  /// **Neden gerekli:** `analyze` ve `detect` her `build`'de baştan
  /// çalışıyordu. Ölçüldü: 5.000 işlemlik defterde tur başına **32,9 ms**
  /// (yalnız `analyze` 20,0 ms), yani 16,7 ms'lik kare bütçesinin iki katı.
  /// Dönem çipine dokunmak, öneri eklemek, kategori adının tazelenmesi —
  /// her `setState` bunu tekrarlıyordu. (Rapor sayfası aynı dersi
  /// `_derivedCache` ile ayrıca öğrendi.)
  ({
    List<TransactionEntity> transactions,
    DateTimeRange range,
    Map<String, String> roots,
    List<RecurringTransactionEntity> templates,
    List<BudgetEntity> budgets,
    String currency,
    DateTime today,
  })? _derivedKey;
  _InsightsDerived? _derivedCache;

  @override
  void initState() {
    super.initState();
    // Sayfa cüzdan başına yeniden kurulur (bkz. SubViewFactory): ortak
    // dönemi bu cüzdanın bağlamına (kartsa ekstre döngüsü) eşitle.
    bindSharedPeriodTo(context, context.walletById(widget.walletId));
    _loadTemplates();
    _loadCategoryLabels();
    _dismissed = RecurringSuggestionDismissStore(getIt<SharedPreferences>())
        .read()
        .toSet();
    _categoriesSub = getIt<CategoriesChangedNotifier>()
        .stream
        .listen((_) => _loadCategoryLabels());
    _loadBudgets();
    if (getIt.isRegistered<BudgetsChangedNotifier>()) {
      _budgetsSub =
          getIt<BudgetsChangedNotifier>().stream.listen((_) => _loadBudgets());
    }

  }

  /// Kategori ikon+ad indeksini yükler ve kategoriler değiştikçe TAZELER.
  ///
  /// Harita eskiden yalnız initState'te kuruluyordu: sayfa route yığınında
  /// dururken yapılan bir yeniden adlandırma ancak sayfa yeniden kurulduğunda
  /// görünüyordu.
  Future<void> _loadCategoryLabels() async {
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
      reportError('İçgörüler · kategori indeksi', e, st);
      return;
    }
    if (!mounted) return;
    final index = buildCategoryDisplayIndex(categories);
    setState(() {
      _categoryLabels = index.labels;
      _categoryRoots = index.roots;
      _categoryIcons = index.icons;
    });
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    _budgetsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadBudgets() async {
    if (!getIt.isRegistered<BudgetRepository>()) return;
    final result = await getIt<BudgetRepository>().getBudgets(widget.walletId);
    if (!mounted) return;
    result.fold((_) {}, (budgets) => setState(() => _budgets = budgets));
  }

  /// Düzenli şablonlar — YALNIZ bu cüzdanınkiler.
  ///
  /// `GetAllRecurringTemplatesUsecase` adı gibi davranır: cüzdan filtresi
  /// yoktur. Süzülmediğinde iki şey birden bozuluyordu:
  ///  * "Günde ne kadar harcayabilirim" hedefinden düşülen yükümlülükler
  ///    TÜM cüzdanların şablonlarını topluyordu — üstelik para birimine de
  ///    bakmadan: USD cüzdanındaki 500 $ kira, TRY cüzdanının netinden
  ///    500 ₺ olarak düşülüyordu (tutarlar cüzdanın biriminde saklanır).
  ///  * Öneri motoru başka cüzdanın şablonunu "zaten var" sayıp bu cüzdanda
  ///    gerçek bir düzenli ödemeyi önermiyordu.
  Future<void> _loadTemplates() async {
    final res = await getIt<GetAllRecurringTemplatesUsecase>()();
    if (!mounted) return;
    setState(() {
      _templates = res.fold(
        (_) => <RecurringTransactionEntity>[],
        (list) => list.where((t) => t.walletId == widget.walletId).toList(),
      );
    });
  }

  /// Bloc state'i cüzdan geçişinde kısa süre ESKİ cüzdanın listesini taşır
  /// (`TransactionLoading.previousTransactions`). İşlemler sayfası bunu
  /// bilerek süzüyordu, bu sayfa süzmüyordu: yabancı cüzdanın rakamları
  /// YENİ cüzdanın para birimi sembolüyle gösteriliyordu.
  ///
  /// Kaynak listenin KİMLİĞİNE göre önbelleklenir — her build'de yeni bir
  /// liste üretmek `_derive`'in kimlik tabanlı önbelleğini geçersiz kılar ve
  /// türetme (ölçülmüştü: 32,9 ms) her karede baştan çalışırdı.
  List<TransactionEntity>? _walletSource;
  List<TransactionEntity> _walletTransactions = const [];

  List<TransactionEntity> _forWallet(List<TransactionEntity> all) {
    if (identical(_walletSource, all)) return _walletTransactions;
    _walletSource = all;
    _walletTransactions =
        all.where((t) => t.walletId == widget.walletId).toList();
    return _walletTransactions;
  }

  /// Analiz kopyası: kart cüzdanında harcamalar ÖDEME gününe taşınır
  /// ([datedByPayment]) — İçgörü de Rapor gibi kart harcamasını ödendiği
  /// aya sayar. Kimliğe göre önbelleklenir.
  List<TransactionEntity>? _analysisSourceRaw;
  WalletEntity? _analysisSelf;
  List<TransactionEntity> _analysisList = const [];

  List<TransactionEntity> _analysisOf(List<TransactionEntity> raw) {
    final self = context.walletById(widget.walletId);
    if (identical(_analysisSourceRaw, raw) && identical(_analysisSelf, self)) {
      return _analysisList;
    }
    _analysisSourceRaw = raw;
    _analysisSelf = self;
    final card = FeatureFlags.creditCards ? self?.creditCard : null;
    _analysisList = card == null ? raw : datedByPayment(raw, card);
    return _analysisList;
  }

  /// Analiz kopyasının HAM kaydı: listeler kullanıcının girdiği tarihi
  /// göstersin (kart harcaması analizde ödeme gününe taşınmış olabilir).
  TransactionEntity _rawOf(TransactionEntity t) {
    final raw = _analysisSourceRaw;
    if (raw == null || identical(raw, _analysisList) || t.id == null) return t;
    for (final r in raw) {
      if (r.id == t.id) return r;
    }
    return t;
  }

  _InsightsDerived _derive(BuildContext context, List<TransactionEntity> all) {
    final templates = _templates ?? const <RecurringTransactionEntity>[];
    final currency = context.activeWalletCurrency;

    // Anahtar, türetmeyi etkileyen HER girdiyi taşır. Listeler/haritalar
    // kimliğe göre karşılaştırılır; hepsi `setState` ile bütün olarak
    // değiştiriliyor, yani kimlik değişimi gerçek bir veri değişimidir.
    final key = (
      transactions: all,
      range: _range,
      roots: _categoryRoots,
      templates: templates,
      budgets: _budgets,
      currency: currency,
      // BUGÜN de bir girdi: yaşanmış gün sayısı, kalan gün sayısı ve kıyas
      // penceresi `DateTime.now()`tan türüyor. Anahtarda olmayınca gece
      // yarısını geçen bir oturum dünün rakamlarını göstermeye devam
      // ediyordu — "günde ne kadar harcayabilirim" dahil.
      today: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );
    final cached = _derivedCache;
    if (cached != null && _derivedKey == key) return cached;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Yükümlülükler dönemin KALANI için toplanır; aralık tamamen
    // gelecekteyse pencerenin tamamı "kalan"dır.
    final obligationsFrom = today.isBefore(_range.start) ? _range.start : today;

    final derived = (
      insights: _analytics.analyze(
        all,
        rangeStart: _range.start,
        rangeEnd: _range.end,
        // Sıçrama alt eşiği tutar bazlıdır; işlemler aktif cüzdanın
        // biriminde tutulduğundan eşik de o birimden seçilir
        // (50 ₺ ile 50 $ aynı büyüklük değil).
        spikeMinimumAmount: noiseThresholdFor(currency),
        // Günlük harcama hedefi yalnız bütçe döneminde ("Bu Ay", "Bu Yıl")
        // dönemin son gününde de anlamlı.
        // Kullanıcının biriminde bugünü içeren dönem (ör. Çarşamba–Salı
        // haftası, 15–14 ayı) de bir "bütçe dönemi"dir.
        rangeIsBudgetPeriod: DateRangeHelper.isBudgetPeriod(_range) ||
            _isCurrentUnitPeriod(),
        rootIndex: _categoryRoots,
        upcomingObligations: RecurringOccurrences.plannedExpenseTotal(
          templates,
          from: obligationsFrom,
          to: _range.end,
        ),
      ),
      // Tekrar tespiti GERÇEK tarihlerle: ödeme gününe taşınmış kart
      // satırları hepsi ayın aynı gününde durur, sahte "aylık" örüntü üretirdi.
      suggestions: _detector.detect(_analysisSourceRaw ?? all,
          existingTemplates: templates),
      budgetStatuses: _budgets.isEmpty
          ? const <BudgetStatus>[]
          : () {
              final builder = ReportCategoryDataBuilder(
                range: _range,
                budgets: _budgets,
                otherCategoryLabel: context.l10n.categoryDiger,
                rootIndex: _categoryRoots,
                // Durum sorusu "ne harcadım": para taşıma harcama değildir.
                includeSystemMovements: false,
              );
              return computeBudgetStatuses(
                budgets: _budgets,
                expenseFull:
                    builder.buildFull(builder.universeIn(all), isExpense: true),
                range: _range,
                labelFor: (tag) =>
                    context.categoryLabelForTag(tag, labels: _categoryLabels),
              );
            }(),
    );

    _derivedKey = key;
    _derivedCache = derived;
    return derived;
  }

  String _suggestionKey(RecurringSuggestion s) =>
      '${s.title.trim().toLowerCase()}|${s.type.name}';

  Future<void> _dismissSuggestion(RecurringSuggestion s) async {
    final key = _suggestionKey(s);
    setState(() => _dismissed = {..._dismissed, key});
    await RecurringSuggestionDismissStore(getIt<SharedPreferences>()).add(key);
  }

  Future<void> _addAsRecurring(RecurringSuggestion s) async {
    final l10n = context.l10n;
    final pendingBloc = context.read<PendingRecurringBloc>();

    final entity = RecurringTransactionEntity(
      id: UidGenerator.generateV7(),
      userId: widget.userId,
      walletId: widget.walletId,
      title: s.title,
      tag: s.tag,
      amount: s.amount,
      type: s.type,
      frequency: s.frequency,
      nextExecutionDate: s.nextExecutionDate,
      anchorDay: s.anchorDay,
    );

    final res = await getIt<SaveRecurringTransactionUsecase>()(entity);
    if (!mounted) return;

    res.fold(
      (_) => AppMessenger.error(l10n.duzenliOdemeEklenemedi),
      (_) {
        // Öneri geçmiş bir örüntüden türer; şablon anında vadesi gelmiş
        // olabilir. Bekleyen liste tazelenmezse hatırlatma gecikirdi.
        pendingBloc.add(const LoadPendingTransactionsEvent());
        setState(() {
          _dismissed = {..._dismissed, _suggestionKey(s)};
          // Yeni şablon hem tespitin "zaten var" süzgecine hem de
          // yükümlülük toplamına girmeli: eklenen kira, günlük harcanabilir
          // tutardan aynı karede düşülür.
          _templates = [...?_templates, entity];
        });
        AppMessenger.success(l10n.duzenliOdemeEklendi(s.title));
      },
    );
  }

  /// Bir kategorinin (kök) dönem içindeki işlemlerini listeler.
  void _openCategoryTransactions(
    BuildContext context,
    String rootTag,
    List<TransactionEntity> all,
  ) {
    final startDay =
        DateTime(_range.start.year, _range.start.month, _range.start.day);
    final endDay = DateTime(_range.end.year, _range.end.month, _range.end.day);
    final members = [
      for (final t in all)
        // Evren kuralı ORTAK fonksiyondan gelir; `!t.isSystem` yazmak kuralın
        // dördüncü kopyasıydı (bkz. [isSpendingMovement]).
        if (t.isExpense &&
            isSpendingMovement(t) &&
            rootIdOf(t.tag, _categoryRoots) == rootTag &&
            !DateTime(t.date.year, t.date.month, t.date.day)
                .isBefore(startDay) &&
            !DateTime(t.date.year, t.date.month, t.date.day).isAfter(endDay))
          t,
    ]..sort((a, b) => b.date.compareTo(a.date));

    ReportTransactionListSheet.show(
      context: context,
      title: context.categoryLabelForTag(rootTag, labels: _categoryLabels),
      transactions: members.map(_rawOf).toList(),
      isExpense: true,
      categoryIcons: _categoryIcons,
      categoryLabels: _categoryLabels,
    );
  }

  /// Dönemin giderlerini büyükten küçüğe listeler.
  void _openLargestExpenses(BuildContext context, List<TransactionEntity> all) {
    final startDay =
        DateTime(_range.start.year, _range.start.month, _range.start.day);
    final endDay = DateTime(_range.end.year, _range.end.month, _range.end.day);
    final members = [
      for (final t in all)
        if (t.isExpense &&
            isSpendingMovement(t) &&
            !DateTime(t.date.year, t.date.month, t.date.day)
                .isBefore(startDay) &&
            !DateTime(t.date.year, t.date.month, t.date.day).isAfter(endDay))
          t,
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    ReportTransactionListSheet.show(
      context: context,
      title: context.l10n.insightTopExpensesTitle,
      transactions: members.map(_rawOf).toList(),
      isExpense: true,
      categoryIcons: _categoryIcons,
      categoryLabels: _categoryLabels,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(context.l10n.akilliIcgoruler),
              centerTitle: true,
            )
          : null,
      // Dönem ortak: başka bir sayfada değişince bu sayfa da yeniden çizilir.
      // Eskiden burada "dönem boşsa verinin olduğu aya SESSİZCE kay"
      // mantığı vardı; ortak dönemi arka planda değiştirmek diğer iki sayfayı
      // da kaydırırdı. Yerine boş durum kartı "… dönemine git" eylemini sunar.
      // Kart şeridi gövdenin DIŞINDA: yükleniyor/boş hâllerinde de görünür.
      body: Column(
        children: [
          // Kart bağlamı (yalnız haplar; borç şeridi İşlemler'de).
          const CardContextRail(pillsOnly: true),
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                context.select((TransactionFilterCubit c) => c.period);
                final all = _analysisOf(_forWallet(state.currentTransactions));

                if (state is TransactionLoading && all.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (all.isEmpty) {
                  return _buildEmptyState(context);
                }

                final money = MoneyWriter.of(context);
                final derived = _derive(context, all);
                final insights = derived.insights;
                final suggestions = derived.suggestions
                    .where((s) => !_dismissed.contains(_suggestionKey(s)))
                    .toList();

                // Dönem kontrolü YAPIŞKAN — rapor sayfasındaki ders: kullanıcı
                // aşağı indiğinde hangi dönemin sayılarına baktığını göremiyor ve
                // dönemi değiştirmek için en başa dönmesi gerekiyordu.
                return Column(
                  children: [
                    // Dönem kontrolü rapor sayfasıyla AYNI: tek satırlık ay
                    // çubuğu. İki kardeş sayfanın dönemi iki farklı kontrolle
                    // seçmesi için sebep yok ve eski blok (başlık + aralık metni +
                    // yatay kayan çip satırı) 411dp telefonda ekranın dörtte birini
                    // yiyordu. Hızlı seçenekler etikete dokununca açılır.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: const SharedPeriodBar(),
                    ),
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
                              if (insights.isEmpty)
                                _buildPeriodEmptyNote(context, all, insights)
                              else ...[
                                ..._buildPeriodSection(context, insights, money),
                                ..._buildStatusSection(
                                    context, insights, money, all, derived),
                                ..._buildHabitSection(context, insights, money, all),
                              ],
                              ..._buildRecurringSection(context, suggestions, money),
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
        ],
      ),
    );
  }

  /// ① Dönemin durumu ve uyarılar — sayfanın ASIL cevabı.
  List<Widget> _buildStatusSection(
    BuildContext context,
    TransactionInsights insights,
    MoneyWriter money,
    List<TransactionEntity> all,
    _InsightsDerived derived,
  ) {
    final budgetAlert = _budgetAlertCard(context, derived.budgetStatuses);
    final cards = <Widget>[
      if (insights.dailySafeToSpend != null)
        DailySafeToSpendCard(
          dailySafeAmount: insights.dailySafeToSpend!,
          remainingDays: insights.remainingDays,
          upcomingObligations: insights.upcomingObligations,
          money: money,
        )
      else if (insights.isOverspent)
        InsightOverspentCard(
          shortfall: insights.spendableRemaining.abs(),
          remainingDays: insights.remainingDays,
          upcomingObligations: insights.upcomingObligations,
          money: money,
        ),
      if (insights.categorySpike != null)
        CategorySpikeCard(
          spike: insights.categorySpike!,
          money: money,
          categoryLabels: _categoryLabels,
          onTap: () => _openCategoryTransactions(
              context, insights.categorySpike!.categoryName, all),
        ),
      if (budgetAlert != null) budgetAlert,
    ];
    if (cards.isEmpty) return const [];

    return [
      const SizedBox(height: 24),
      ReportSectionHeader(title: context.l10n.insightSectionStatus),
      const SizedBox(height: 12),
      ...cards,
    ];
  }

  /// Dönemin tek satırlık özeti; dokunmak Rapor'u açar.
  ///
  /// Eskiden burada Rapor'un özet kartları BİREBİR tekrarlanıyordu
  /// (`ReportSummaryCards`, ~130dp): iki yan sayfa aynı üç sayıyı aynı
  /// kartlarla söylüyordu. Bu sayfanın işi "durumum ne, ne yapmalıyım";
  /// sayıların ayrıntısı Rapor'da. Özet bağlam olarak sayfanın başında kalır.
  List<Widget> _buildPeriodSection(
    BuildContext context,
    TransactionInsights insights,
    MoneyWriter money,
  ) {
    final l10n = context.l10n;
    return [
      InsightStatCard(
        icon: Icons.insights_rounded,
        label: l10n.insightPeriodLinkTitle(periodLabel(_range, l10n)),
        value: l10n.insightPeriodLinkValue(
            money(insights.totalExpense), money.withSign(insights.net)),
        hint: l10n.insightPeriodLinkHint,
        onTap: () => _openReport(),
      ),
      if (insights.systemMovementCount > 0)
        _buildSystemMovementsNote(context, insights.systemMovementCount),
    ];
  }

  void _openReport() {
    if (getIt.isRegistered<HomeNavigationRequests>()) {
      getIt<HomeNavigationRequests>().openSection(TransactionsSection.report);
    }
  }

  /// Aşılmış ya da %80'i geçmiş bütçeler; hiçbiri yoksa `null` (kart yok —
  /// "her şey yolunda" kartı gürültü olurdu, Rapor'da tam liste var).
  Widget? _budgetAlertCard(BuildContext context, List<BudgetStatus> statuses) {
    final alerts = [
      for (final s in statuses)
        if (s.ratio >= 0.8) s,
    ]..sort((a, b) => b.ratio.compareTo(a.ratio));
    if (alerts.isEmpty) return null;
    final l10n = context.l10n;
    final anyExceeded = alerts.first.isExceeded;
    return InsightStatCard(
      icon: Icons.pie_chart_outline_rounded,
      label: l10n.insightBudgetAlertTitle,
      value: [
        for (final a in alerts.take(2))
          a.isExceeded
              ? l10n.insightBudgetExceeded(a.label)
              : l10n.insightBudgetNear(a.label, formatPercent(a.ratio * 100)),
      ].join(' · '),
      hint: l10n.insightBudgetAlertHint,
      accent: anyExceeded ? MoneyColors.bad : AppGradients.neutral,
      onTap: _openReport,
    );
  }

  /// ③ Alışkanlık — hepsi bir ORTALAMA, bu yüzden hepsinin böleni yazar.
  List<Widget> _buildHabitSection(
    BuildContext context,
    TransactionInsights insights,
    MoneyWriter money,
    List<TransactionEntity> all,
  ) {
    if (!insights.hasExpense) return const [];

    final largest = insights.largestExpense;

    return [
      const SizedBox(height: 24),
      ReportSectionHeader(title: context.l10n.insightSectionHabits),
      const SizedBox(height: 12),
      InsightStatCard(
        icon: Icons.calendar_today_rounded,
        label: context.l10n.gunlukOrtalamaHarcama,
        value: money(insights.dailyAverageExpense),
        hint: context.l10n.insightDailyAverageHint(insights.elapsedDays),
      ),
      if (insights.topExpenseWeekday != null)
        InsightStatCard(
          icon: Icons.event_rounded,
          label: context.l10n.enCokHarcananGun,
          value: '${_weekdayName(context, insights.topExpenseWeekday!)} · '
              '${money(insights.topExpenseWeekdayAverage)}',
          hint: context.l10n
              .insightWeekdayHint(insights.topExpenseWeekdayOccurrences),
        ),
      // "En çok harcanan kategori" kartı kalktı: bu bilgi Rapor'un kategori
      // dağılımının İLK dilimi ve cihazda aynı 18.500 ₺'lik kira ödemesi
      // "en büyük harcama" ile yan yana iki kez yazıyordu.
      if (largest != null)
        InsightStatCard(
          icon: Icons.north_east_rounded,
          label: context.l10n.enBuyukHarcama,
          value: '${largest.title} · ${money(largest.amount)}',
          hint: context.l10n.insightTapForTransactions,
          accent: AppGradients.debt,
          onTap: () => _openLargestExpenses(context, all),
        ),
    ];
  }

  /// ④ Eyleme dönüşebilen öneriler.
  List<Widget> _buildRecurringSection(
    BuildContext context,
    List<RecurringSuggestion> suggestions,
    MoneyWriter money,
  ) {
    // null = şablonlar henüz yüklenmedi; boş liste ile "öneri yok" durumunu
    // ayırt etmek gerekir, aksi halde bölüm bir kare boyunca yanıp söner.
    if (_templates == null || suggestions.isEmpty) return const [];

    final theme = Theme.of(context);
    return [
      const SizedBox(height: 24),
      ReportSectionHeader(title: context.l10n.tekrarlayanOdemeler),
      const SizedBox(height: 4),
      Text(
        '${context.l10n.tekrarlayanTespitOzeti(suggestions.length)} · '
        '${context.l10n.insightRecurringIndependent}',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 12),
      for (final s in suggestions)
        RecurringSuggestionCard(
          suggestion: s,
          money: money,
          onAdd: () => _addAsRecurring(s),
          onDismiss: () => _dismissSuggestion(s),
        ),
    ];
  }

  /// Kuplaj hareketleri toplamların DIŞINDA; sessizce atmak yerine söylenir.
  Widget _buildSystemMovementsNote(BuildContext context, int count) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.swap_horiz_rounded,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            context.l10n.insightSystemMovementsNote(count),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }

  /// Dönemde gelir–gider yoksa ne olduğunu ve nereye gidilebileceğini söyler.
  ///
  /// Eskiden tek cümleydi: "Bu dönemde işlem yok". Dönemde yalnız para taşıma
  /// hareketi (kart ödemesi, transfer) varken bu YANLIŞTI — işlemler sayfası
  /// aynı dönemde o satırı gösteriyordu. Kullanıcıya bir sonraki adım da
  /// sunulmuyordu: sayfanın yarısı boş kalıyordu.
  Widget _buildPeriodEmptyNote(
    BuildContext context,
    List<TransactionEntity> all,
    TransactionInsights insights,
  ) {
    final l10n = context.l10n;
    final moved = insights.systemMovementCount;
    final day = nearestDayOutside(
      [
        for (final t in all)
          if (isSpendingMovement(t)) t.date,
      ],
      _range,
    );
    final target = day == null ? null : periodContainingDay(_range, day);
    return AnalysisEmptyCard(
      icon: moved > 0 ? Icons.swap_horiz_rounded : Icons.event_busy_rounded,
      title: moved > 0
          ? l10n.analysisNoFlowTitle
          : l10n.msgSecilenTarihAraligindaIslem,
      lines: [
        moved > 0
            ? l10n.analysisNoFlowMoved(moved)
            : l10n.analysisPeriodEmptyBody,
      ],
      actions: [
        if (target != null)
          (
            label: l10n.analysisJumpToPeriod(periodLabel(target, l10n)),
            onTap: () =>
                context.read<TransactionFilterCubit>().setPeriod(target),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
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
                child: Icon(Icons.insights_rounded,
                    size: 48, color: scheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.detayGosterilecekIslemYok,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.gelirVeyaGiderKaydettikten,
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

  /// Haftanın günü adı — elle yazılmış tr/en listesi DEĞİL, `intl`in kendi
  /// takvim adları. Eski listeler yeni bir dil eklendiğinde sessizce
  /// İngilizce'ye düşerdi.
  String _weekdayName(BuildContext context, int weekday) {
    if (weekday < 1 || weekday > 7) return '';
    final locale = Localizations.localeOf(context).languageCode;
    // 2024-01-01 bir Pazartesi; weekday 1..7 doğrudan güne oturur.
    final day = DateTime(2024, 1, weekday);
    return DateFormat.EEEE(locale).format(day);
  }
}
