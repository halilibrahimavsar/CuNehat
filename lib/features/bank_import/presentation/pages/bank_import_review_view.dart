import 'package:cunehat/core/utils/money_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/text_search.dart';
import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/description_grouper.dart';
import 'package:cunehat/features/bank_import/data/link_hint.dart';
import 'package:cunehat/features/bank_import/data/card_statement_parser.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/bank_import/presentation/import_category_labels.dart';
import 'package:cunehat/features/bank_import/presentation/review_search.dart';
import 'package:cunehat/features/bank_import/presentation/widgets/bulk_category_dialog.dart';
import 'package:cunehat/features/bank_import/presentation/widgets/draft_edit_sheet.dart';
import 'package:cunehat/features/bank_import/presentation/widgets/duplicate_match_panel.dart';
import 'package:cunehat/features/bank_import/presentation/widgets/leftover_review_sheet.dart';
import 'package:cunehat/features/bank_import/presentation/widgets/similar_group_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_picker_sheet.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';

/// İnceleme listesinde hangi taslakların gösterileceği.
enum _ReviewFilter {
  all,
  uncategorized,

  /// Kategorisi yalnız bankanın genel etiketinden tahmin edilenler.
  toCheck,
  duplicates,
  leftoverCandidates,
  expenses,
  incomes,
}

/// Kategori seçiminin sonucu: seçilen kategori + hangi türe ait olduğu. Toplu
/// atamada tür de gerekir; kategori yalnız KENDİ türündeki satırlara uygulanır
/// (gider kategorisi gelir satırına yazılamaz).
typedef _PickedCategory = ({String id, bool isExpense});

/// Taslakları inceleme: liste (varsayılan) + tek-tek stepper. Toplu ekleme.
///
/// Liste 80+ satıra kadar çıkabildiği için (gerçek bir Garanti ekstresinde 85)
/// arama + filtre şart: "kategorisiz" olanlara doğrudan gitmek, tekrarları
/// gözden geçirmek elle kaydırmadan mümkün olmalı. Aynı nedenle tam ekran
/// kipi var: özet/uyarı kartı ve AppBar gizlenince ekrana ~4 satır daha sığar.
class BankImportReviewView extends StatefulWidget {
  final BankImportReview state;

  /// Tam ekran (yalnız liste) kipi. Durum sayfada tutulur, çünkü AppBar'ı
  /// gizleyen `Scaffold` orada.
  final bool fullscreen;
  final VoidCallback onToggleFullscreen;

  const BankImportReviewView({
    super.key,
    required this.state,
    required this.onToggleFullscreen,
    this.fullscreen = false,
  });

  @override
  State<BankImportReviewView> createState() => _BankImportReviewViewState();
}

class _BankImportReviewViewState extends State<BankImportReviewView> {
  bool _stepper = false;
  int _step = 0;
  _ReviewFilter _filter = _ReviewFilter.all;
  String _query = '';

  /// Katlanmamış arama metni — tutar araması virgül/noktayı görmeli.
  String _rawQuery = '';
  final _searchController = TextEditingController();

  /// Defterde BİREBİR kayıtlı (eklenmeyecek) satırlar gösterilsin mi. Varsayılan
  /// kapalı: ardışık ekstrelerde her örtüşen satır ayrı bir "zaten kayıtlı"
  /// paneli çiziyor, yeni hareketler bunların arasında kayboluyordu.
  bool _showKnown = false;

  /// Özet kartı ayrıntılı mı (doğrulama dökümü, kart künyesi satırları).
  bool _summaryExpanded = false;

  /// Arama alanının odağı. Bu ekranda klavyeyi açan tek alan bu; özet kartı
  /// odak varken çekilir (bkz. [_buildList]).
  final _searchFocus = FocusNode();
  bool _searching = false;

  /// Arama satırı açık mı. Alan eskiden hep duruyordu ve listeden kalıcı bir
  /// satır (52dp) götürüyordu; artık süzgeç çiplerinin ucundaki büyüteçle
  /// açılır. Sorgu doluyken kapanmaz — görünmeyen bir süzgeç listeyi sessizce
  /// daraltmasın.
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      final focused = _searchFocus.hasFocus;
      if (_searching == focused) return;
      setState(() {
        _searching = focused;
        if (!focused && _query.isEmpty) _searchOpen = false;
      });
    });
  }

  List<ImportDraft>? _groupKey;
  int _groupCount = 0;

  /// Kategorisiz satırlar arasındaki benzer grup sayısı — "Benzerleri grupla"
  /// satırı yalnız gerçekten gruplanacak bir şey varken çıkar. Taslak listesi
  /// her mutasyonda YENİ bir liste olduğundan kimliğe göre önbelleklenir.
  int get _uncategorizedGroupCount {
    if (!identical(_groupKey, _s.drafts)) {
      _groupKey = _s.drafts;
      final scope = [
        for (var i = 0; i < _s.drafts.length; i++)
          if (_s.drafts[i].needsCategory) i,
      ];
      _groupCount = scope.length < kMinGroupSize
          ? 0
          : groupSimilarDrafts(_s.drafts, scope: scope).length;
    }
    return _groupCount;
  }

  BankImportCubit get _cubit => context.read<BankImportCubit>();
  BankImportReview get _s => widget.state;

  String get _currency => _s.walletCurrency ?? kDefaultCurrency;
  String _money(double v) => formatMoney(v, currency: _currency);

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Seçili filtrenin karşılığı kalmadıysa (ör. kullanıcı son kategorisiz
  /// satırı da kategorize etti) sessizce "tümü"ne döner; aksi halde ekran
  /// boşalır ve kullanıcı neden hiçbir şey göremediğini anlamaz.
  _ReviewFilter get _effectiveFilter => switch (_filter) {
        _ReviewFilter.uncategorized when _s.uncategorizedCount == 0 =>
          _ReviewFilter.all,
        _ReviewFilter.toCheck when _s.toCheckCount == 0 => _ReviewFilter.all,
        _ReviewFilter.duplicates when _s.duplicateCount == 0 =>
          _ReviewFilter.all,
        _ReviewFilter.leftoverCandidates when _s.leftovers.isEmpty =>
          _ReviewFilter.all,
        _ReviewFilter.expenses when !_hasBothTypes => _ReviewFilter.all,
        _ReviewFilter.incomes when !_hasBothTypes => _ReviewFilter.all,
        _ => _filter,
      };

  /// Gelir/Gider süzgeçleri yalnız ikisi birden varken anlamlı.
  bool get _hasBothTypes =>
      _s.drafts.any((d) => d.isIncome) && _s.drafts.any((d) => !d.isIncome);

  /// Görünür taslaklar; cubit mutasyonları İNDEKS tabanlı olduğu için gerçek
  /// (filtrelenmemiş) indeks satırla birlikte taşınır — aksi halde filtreliyken
  /// yapılan her düzenleme başka bir satıra uygulanırdı.
  ///
  /// Arama `toLowerCase()` DEĞİL [matchesFolded] ile yapılır: Dart noktasız
  /// `I`'yı `i`'ye çevirir, `ı`'ya değil. Ekstre açıklamaları BÜYÜK HARF
  /// olduğu için "IŞIK ELEKTRİK" satırı `işik...` diye küçülüyor ve
  /// kullanıcının doğal yazımı olan "ışık" onu hiç bulamıyordu. Tutar da
  /// aranır (bkz. [draftAmountMatches]).
  ///
  /// Birebir kayıtlı satırlar ([BankImportReview.isKnown]) "Olası tekrar"
  /// süzgeci dışında katlanır; kaç tanesinin katlandığı `hiddenKnown`'da.
  List<(int, ImportDraft)> get _visible => _filtered().visible;

  ({List<(int, ImportDraft)> visible, int hiddenKnown}) _filtered() {
    final q = _query;
    final filter = _effectiveFilter;
    final candidates = filter == _ReviewFilter.leftoverCandidates
        ? _s.leftoverCandidateIndexes
        : const <int>{};
    final foldKnown = !_showKnown && filter != _ReviewFilter.duplicates;
    final out = <(int, ImportDraft)>[];
    var hidden = 0;
    for (var i = 0; i < _s.drafts.length; i++) {
      final d = _s.drafts[i];
      final passesFilter = switch (filter) {
        _ReviewFilter.all => true,
        _ReviewFilter.uncategorized => d.needsCategory,
        _ReviewFilter.toCheck =>
          d.categoryId != null && d.categorySource == CategorySource.bankTag,
        _ReviewFilter.duplicates => d.isDuplicate,
        _ReviewFilter.leftoverCandidates => candidates.contains(i),
        _ReviewFilter.expenses => !d.isIncome,
        _ReviewFilter.incomes => d.isIncome,
      };
      if (!passesFilter) continue;
      if (!matchesFolded(d.description, q) &&
          !draftAmountMatches(d.amount, _rawQuery)) {
        continue;
      }
      if (foldKnown && BankImportReview.isKnown(d)) {
        hidden++;
        continue;
      }
      out.add((i, d));
    }
    return (visible: out, hiddenKnown: hidden);
  }

  @override
  Widget build(BuildContext context) {
    if (_s.drafts.isEmpty) {
      return Center(child: Text(context.l10n.bankImportNoRows));
    }
    // Ekstrenin TAMAMI zaten kayıtlıysa liste yerine tek bir sonuç: eskiden
    // 157 satırın her biri ayrı bir "zaten kayıtlı" paneliyle çiziliyor ve
    // altta "Seçilenleri ekle (0)" duruyordu (cihazda ölçüldü).
    final allKnownView = _s.allKnown && !_showKnown && !_stepper;
    final body = allKnownView
        ? _allKnownView(context)
        : _stepper
            ? _buildStepper(context)
            : _buildList(context);
    return PopScope(
      // İnceleme adımından geri hareketi hiçbir zaman doğrudan çıkmaz:
      // tam ekrandaysa önce KİPTEN çıkar (AppBar gizli, başka çıkış yolu yok),
      // değilse onay ister — 80 satırlık bir ekstrede yapılan kategori emeği
      // tek bir kaydırmayla sessizce gidiyordu. "Yeni hareket yok" ekranında
      // kaybolacak bir emek yok, doğrudan çıkılır.
      canPop: allKnownView && !widget.fullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.fullscreen) {
          widget.onToggleFullscreen();
        } else {
          _confirmLeave();
        }
      },
      // AppBar gizliyken üst çentik/durum çubuğu alanını Scaffold tüketmez.
      child: widget.fullscreen ? SafeArea(bottom: false, child: body) : body,
    );
  }

  /// İncelemeden çıkış. Henüz hiçbir şey yazılmadı; çıkmak yalnız bu
  /// ekstre için yapılan seçimleri atar — ama bu emek kullanıcının, onay
  /// istenir. Stepper'daki "Tümünü iptal" de buradan geçer.
  Future<void> _confirmLeave() async {
    final l10n = context.l10n;
    final leave = await ConfirmDialog.show(
      context,
      title: l10n.bankImportExitTitle,
      message: l10n.bankImportExitBody,
      confirmText: l10n.bankImportExitConfirm,
      danger: true,
    );
    if (leave && mounted) Navigator.of(context).pop();
  }

  /// "Bu ekstrede yeni hareket yok" ekranı (bkz. [BankImportReview.allKnown]).
  Widget _allKnownView(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.task_alt_rounded,
                  size: 36, color: Colors.green),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.bankImportAllKnownTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.bankImportAllKnownBody(_s.drafts.length),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.bankImportClose),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => setState(() => _showKnown = true),
              child: Text(l10n.bankImportAllKnownShowRows),
            ),
          ],
        ),
      ),
    );
  }

  List<CategoryEntity> _catsFor(bool income) =>
      income ? _s.incomeCategories : _s.expenseCategories;

  ({List<CategoryEntity> expense, List<CategoryEntity> income})? _labelKey;
  Map<String, String> _labelCache = const {};

  /// `id → gösterilecek kategori adı`; alt kategori adı tür içinde tekil
  /// değilse ana kategorisiyle birlikte ("Fatura › Su"). Bkz.
  /// [buildImportCategoryLabels].
  ///
  /// Liste kimliğine göre önbelleklenir: kategoriler yalnız inceleme sırasında
  /// yeni kategori kurulunca değişiyor, her satır için yeniden kurmak 85
  /// satırlık bir ekstrede her karede boşuna iş demek.
  Map<String, String> get _categoryLabels {
    if (_labelKey?.expense != _s.expenseCategories ||
        _labelKey?.income != _s.incomeCategories) {
      _labelKey = (expense: _s.expenseCategories, income: _s.incomeCategories);
      _labelCache = {
        ...buildImportCategoryLabels(_s.expenseCategories),
        ...buildImportCategoryLabels(_s.incomeCategories),
      };
    }
    return _labelCache;
  }

  CategoryEntity? _categoryById(List<CategoryEntity> cats, String? id) {
    if (id == null) return null;
    for (final c in cats) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ---------------------------------------------------------------- List mode

  Widget _buildList(BuildContext context) {
    final filtered = _filtered();
    final visible = filtered.visible;
    final hidden = filtered.hiddenKnown;
    // Katlama satırı: kaç satırın neden gizlendiği ve geri açma yolu. Birebir
    // kayıtlılar gösterilirken de "gizle" olarak durur.
    final showKnownTile = hidden > 0 ||
        (_showKnown &&
            _s.knownCount > 0 &&
            _effectiveFilter != _ReviewFilter.duplicates);
    // Benzer grup kısayolu: süzgeçsiz ya da "kategorisiz" görünümde, listenin
    // İLK satırı olarak. Sabit başlıkta değil listede durur — görünür ama
    // kaydırınca yer tutmaz. (Eskiden yalnız ⋮ menüsündeydi.)
    final groups = _query.isEmpty &&
            (_effectiveFilter == _ReviewFilter.all ||
                _effectiveFilter == _ReviewFilter.uncategorized)
        ? _uncategorizedGroupCount
        : 0;
    final headers = [
      if (groups > 0) _groupTile(context, groups),
      if (showKnownTile) _knownTile(context, hidden),
    ];
    return Column(
      children: [
        // Aranırken (klavye açık) özet kartı çekilir: kart kaydırılmayan
        // başlıkta duruyor ve birkaç uyarı varken klavyeyle birlikte sayfayı
        // taşırıyordu (cihazda ölçüldü: 41px). Kart tam ekranda olduğu gibi
        // kaybolmaz, odak bırakılınca geri gelir.
        //
        // Ölçüt klavye yüksekliği DEĞİL: Scaffold gövdenin MediaQuery'sinden
        // alt boşluğu siliyor (orada klavye hep "kapalı"), `View` ise
        // değişince yeniden çizim tetiklemiyor.
        //
        // Kart ayrıca ekranın en çok %38'ine sınırlanır ve kendi içinde
        // kayar: kaydırılmayan başlıkta olduğu için birkaç uyarı + öneri
        // şeridi + kart künyesi dar/alçak ekranda sayfayı taşırıyordu
        // (ölçüldü: 360×780'de 13px) ve listeye hiç yer kalmıyordu.
        if (!widget.fullscreen && !_searching)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.38,
            ),
            child: SingleChildScrollView(child: _statusCard(context)),
          ),
        _toolbar(context),
        Expanded(
          child: visible.isEmpty && headers.isEmpty
              ? Center(child: Text(context.l10n.bankImportNoMatch))
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: visible.length + headers.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, k) {
                    if (k < headers.length) return headers[k];
                    final (index, draft) = visible[k - headers.length];
                    return _row(context, index, draft);
                  },
                ),
        ),
        _bottomBar(context),
      ],
    );
  }

  /// "Benzer N grubu tek seferde kategorile ›" — benzer hareketler sayfasını
  /// açar. Tek satır: etiket ile eylem aynı metindir.
  Widget _groupTile(BuildContext context, int groups) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      key: const ValueKey('review-group-tile'),
      onTap: () => showSimilarGroupSheet(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              Icon(Icons.workspaces_outline, size: 18, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.bankImportGroupTile(groups),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.primary),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }

  /// "N satır zaten kayıtlı olduğu için gizlendi · Göster" / "Gizle".
  Widget _knownTile(BuildContext context, int hidden) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return InkWell(
      onTap: () => setState(() => _showKnown = hidden > 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            Icon(Icons.copy_all_rounded, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hidden > 0
                    ? l10n.bankImportKnownHidden(hidden)
                    : l10n.bankImportKnownShown(_s.knownCount),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
            Text(
              hidden > 0
                  ? l10n.bankImportShowUncategorized
                  : l10n.bankImportKnownHide,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Status card

  /// Özet + uyarılar TEK kartta. Eskiden üst üste üç tam genişlik şerit
  /// (genel uyarı, mutabakat, para birimi) vardı ve listeye yer kalmıyordu;
  /// olumlu bilgi (bakiye doğrulandı) artık çip olarak, uyarılar tek blokta.
  ///
  /// Varsayılan SIKI: bilgilendirici ayrıntılar (doğrulama dökümü, kart
  /// künyesinin satırları) tek satıra iner, dokununca açılır. Cihazda
  /// ölçüldü — ayrıntılı kart 6,7" ekranın ~%40'ını kaplıyor, liste ancak
  /// ortadan başlıyordu. Eylem isteyen şeritler (hedef önerisi, tahminle
  /// atlananlar, karşılıksız kayıtlar) ve hatalar her zaman görünür.
  ///
  /// Sıkı kipte sayaçlar TEK satırdır (sığmazsa yana kayar, alt satıra
  /// inmez) ve genel uyarı kısa hâliyle tek satır yazar; tam metin ok ile ya
  /// da uyarıya dokununca açılır.
  ///
  /// Tam ekran kipinde listeden çıkar ama KAYBOLMAZ: taşma menüsünden aynı
  /// kart ayrıntılı olarak bir sayfada açılır (bkz. [_showSummarySheet]).
  Widget _statusCard(BuildContext context, {bool? expanded}) {
    final cs = Theme.of(context).colorScheme;
    final full = expanded ?? _summaryExpanded;
    final warnings = _warnings(context);
    final verified =
        _s.verification.status == StatementVerificationStatus.verified;
    final failed = _s.verification.status == StatementVerificationStatus.failed;
    final reconciled =
        _s.verification.status == StatementVerificationStatus.unavailable &&
            _s.reconciliation?.status == ReconcileStatus.matched;
    final stats = [
      _stat(context, '${_s.drafts.length}', context.l10n.bankImportStatRows,
          cs.primary),
      if (_s.duplicateCount > 0)
        _stat(context, '${_s.duplicateCount}',
            context.l10n.bankImportStatDuplicates, AppGradients.debt),
      if (_s.uncategorizedCount > 0)
        _stat(context, '${_s.uncategorizedCount}',
            context.l10n.bankImportStatUncategorized, cs.error),
      if (_s.skippedRows > 0)
        _stat(context, '${_s.skippedRows}', context.l10n.bankImportStatSkipped,
            cs.onSurfaceVariant),
      if ((verified && !full) || reconciled)
        _chip(context, Icons.verified_rounded,
            context.l10n.bankImportVerifiedChip, Colors.green),
    ];

    return Container(
      width: double.infinity,
      color: cs.surfaceContainerHighest,
      padding: EdgeInsets.fromLTRB(12, full ? 10 : 4, 12, full ? 10 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                full ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: full
                    ? Wrap(spacing: 6, runSpacing: 6, children: stats)
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < stats.length; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              stats[i],
                            ],
                          ],
                        ),
                      ),
              ),
              if (expanded == null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: full
                      ? context.l10n.bankImportSummaryLess
                      : context.l10n.bankImportSummaryMore,
                  icon: Icon(full
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded),
                  onPressed: () =>
                      setState(() => _summaryExpanded = !_summaryExpanded),
                ),
            ],
          ),
          if (_s.targetSuggestion case final t?) ...[
            const SizedBox(height: 10),
            _targetBanner(context, t),
          ],
          if (failed || (verified && full)) ...[
            const SizedBox(height: 10),
            _verificationBanner(context),
          ],
          if (_s.cardFacts case final facts?) ...[
            const SizedBox(height: 10),
            full
                ? _cardFactsBanner(context, facts)
                : _cardFactsLine(context, facts),
          ],
          if (_s.approximateSkippedCount > 0) ...[
            const SizedBox(height: 10),
            _approximateBanner(context, _s.approximateSkippedCount),
          ],
          if (_s.leftovers.isNotEmpty) ...[
            const SizedBox(height: 10),
            _leftoverBanner(context, _s.leftovers.length),
          ],
          // Genel "otomatik algılandı" uyarısı HER ZAMAN görünür (kullanıcı
          // talebi) ama sıkı kipte kutusuz TEK satırdır ve kısa yazar; tam
          // metin dokununca açılır. Asıl hatalar (OCR, para birimi, tutmayan
          // bakiye…) kutuda kalır.
          if (!full) ...[
            const SizedBox(height: 2),
            InkWell(
              onTap: expanded == null
                  ? () => setState(() => _summaryExpanded = true)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _inlineNote(context, Icons.warning_amber_rounded,
                    context.l10n.bankImportReviewWarningShort, Colors.orange),
              ),
            ),
          ],
          if (full ? warnings.isNotEmpty : warnings.length > 1) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final w in full ? warnings : warnings.skip(1))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(w.icon, size: 16, color: w.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(w.message,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inlineNote(
      BuildContext context, IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// "Hedefi X yap" şeridi (bkz. [TargetSuggestion]). Yanlış cüzdan en pahalı
  /// hatadır — satırlar yanlış deftere yazılır ve sonradan tek tek taşınması
  /// gerekir — bu yüzden kartın en üstünde ve tek dokunuşla düzeltilebilir.
  Widget _targetBanner(BuildContext context, TargetSuggestion t) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final strong = t.reason == TargetSuggestionReason.entriesElsewhere ||
        t.reason == TargetSuggestionReason.accountOnCard;
    final color = strong ? cs.error : cs.primary;
    final message = switch (t.reason) {
      TargetSuggestionReason.entriesElsewhere =>
        l10n.bankImportTargetElsewhere(t.matchCount, t.walletName),
      TargetSuggestionReason.cardNumber =>
        l10n.bankImportTargetCard(t.last4 ?? '', t.walletName),
      TargetSuggestionReason.accountOnCard =>
        l10n.bankImportTargetAccount(t.walletName),
      TargetSuggestionReason.usedBefore =>
        l10n.bankImportTargetUsedBefore(t.walletName),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _cubit.switchTarget(t.walletId),
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text(
                l10n.bankImportTargetSwitch(t.walletName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kart künyesinin sıkı hâli: tek satır, dokununca ayrıntı açılır.
  Widget _cardFactsLine(BuildContext context, CardStatementFacts facts) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final parts = [
      facts.isClosedStatement
          ? l10n.bankImportCardStatement
          : l10n.bankImportCardPeriod,
      if (facts.last4 case final l?) '•••• $l',
      if (facts.dueDate case final d?)
        // Ay adıyla: "05.10.26" gün/ay sırası belirsiz okunuyordu.
        '${l10n.kkSonOdemeTarihi} ${AppFormatters.dayMonth.format(d)}',
      if (facts.statementBalance case final v?) _money(v),
    ];
    return InkWell(
      onTap: () => setState(() => _summaryExpanded = true),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(Icons.credit_card_rounded, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              parts.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Tam ekran kipinde gizlenen özet/uyarı kartını sayfa olarak gösterir
  /// (ayrıntılı hâliyle).
  void _showSummarySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          child: SingleChildScrollView(
              child: _statusCard(context, expanded: true)),
        ),
      ),
    );
  }

  /// Ekstrenin KENDİ verileriyle yapılan aritmetik doğrulamanın sonucu.
  ///
  /// Buradaki iddia "muhtemelen doğru okuduk" değil, kanıtlanabilir bir
  /// eşitliktir: bakiye zinciri her satırın tutar+işaretini, beyan edilen
  /// kayıt sayısı hiçbir satırın kaçmadığını, devreden/kapanış bakiyesi ve
  /// Borç/Alacak toplamları da bütünü doğrular. Kontrollerin dökümü
  /// gösterilir ki kullanıcı neye güvendiğini görebilsin.
  /// Kart ekstresi künyesi: bankanın beyanı + uygulanan işaret kuralı.
  Widget _cardFactsBanner(BuildContext context, CardStatementFacts facts) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    String money(double v) => formatMoney(v, currency: _currency);
    final rows = <(String, String)>[
      if (facts.closingDate case final d?)
        (l10n.kkKesimTarihi, AppFormatters.dayMonthYear.format(d)),
      if (facts.dueDate case final d?)
        (l10n.kkSonOdemeTarihi, AppFormatters.dayMonthYear.format(d)),
      if (facts.statementBalance case final v?) (l10n.kkDonemBorcu, money(v)),
      if (facts.minimumPayment case final v?) (l10n.kkAsgariOdeme, money(v)),
    ];
    final title = facts.isClosedStatement
        ? l10n.bankImportCardStatement
        : l10n.bankImportCardPeriod;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  facts.last4 == null ? title : '$title · •••• ${facts.last4}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                      child: Text(label, style: theme.textTheme.bodySmall)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(l10n.bankImportCardSign, style: theme.textTheme.bodySmall),
          if (facts.isClosedStatement && _s.targetIsCard)
            Text(l10n.bankImportCardSavesToWallet,
                style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _verificationBanner(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = _s.verification;
    final ok = v.status == StatementVerificationStatus.verified;
    final color = ok ? Colors.green : cs.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ok ? Icons.verified_rounded : Icons.error_outline_rounded,
                  size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ok
                      ? context.l10n.bankImportVerified
                      : context.l10n.bankImportVerifyFailed,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ok
                ? context.l10n.bankImportVerifiedHint
                : context.l10n.bankImportVerifyFailedHint,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 6),
          for (final c in v.checks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                children: [
                  Icon(
                    c.passed ? Icons.check_rounded : Icons.close_rounded,
                    size: 13,
                    color: c.passed ? Colors.green : cs.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_checkLabel(context, c.kind)}: ${c.detail}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Yaklaşık eşleşme yüzünden EKLENMEYECEK satırlar. Kesin tekrarın aksine
  /// bu karar bir tahmine dayanıyor; kullanıcı sayıyı görmeden eklemeye
  /// basarsa gerçek bir harcama sessizce dışarıda kalabilirdi. Şerit doğrudan
  /// o satırlara götürür.
  Widget _approximateBanner(BuildContext context, int count) {
    final color = Colors.orange.shade800;
    return InkWell(
      onTap: () => setState(() {
        _stepper = false;
        _filter = _ReviewFilter.duplicates;
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.difference_outlined, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.bankImportApproxWarning(count),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.bankImportShowUncategorized,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }

  /// Ekstre döneminde defterde duran ama hiçbir satırla otomatik eşleşmemiş,
  /// olası eşi olan kayıtlar. Eşleşmediği için ekstre satırı SEÇİLİ gelir;
  /// kullanıcı görmeden eklerse aynı harcama iki kez yazılır. Şerit karar
  /// sayfasını açar (bkz. [LeftoverReviewSheet]).
  Widget _leftoverBanner(BuildContext context, int count) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () => showLeftoverReviewSheet(
        context,
        categoryLabels: _categoryLabels,
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.link_rounded, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.bankImportLeftoverBanner(count),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.bankImportLeftoverReview,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }

  String _checkLabel(BuildContext context, StatementCheckKind kind) =>
      switch (kind) {
        StatementCheckKind.balanceChain =>
          context.l10n.bankImportCheckBalanceChain,
        StatementCheckKind.recordCount =>
          context.l10n.bankImportCheckRecordCount,
        StatementCheckKind.openingBalance =>
          context.l10n.bankImportCheckOpeningBalance,
        StatementCheckKind.closingBalance =>
          context.l10n.bankImportCheckClosingBalance,
        StatementCheckKind.totals => context.l10n.bankImportCheckTotals,
      };

  /// Gösterilecek uyarılar: genel "otomatik algılandı" uyarısı HER ZAMAN
  /// (kullanıcı talebi), bakiye tutmazsa ve para birimi uyuşmazsa ek olarak.
  List<_Warning> _warnings(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rec = _s.reconciliation;
    return [
      _Warning(Icons.warning_amber_rounded,
          context.l10n.bankImportReviewWarning, Colors.orange),
      // OCR yolu diğerlerinden belirgin biçimde hatalı: en üstte, kırmızıyla.
      if (_s.fromOcr)
        _Warning(Icons.image_search_rounded, context.l10n.bankImportOcrWarning,
            cs.error),
      if (rec != null && rec.status == ReconcileStatus.mismatch)
        _Warning(
          Icons.error_outline_rounded,
          context.l10n.bankImportReconcileMismatch(rec.mismatchCount),
          cs.error,
        ),
      // Hesap ekstresi kart cüzdanına: öneri şeridi zaten söylüyorsa tekrar
      // etme (kartın ödendiği hesap tanımlı değilse öneri yoktur).
      if (_s.accountStatementOnCard &&
          _s.targetSuggestion?.reason != TargetSuggestionReason.accountOnCard)
        _Warning(Icons.credit_card_off_rounded,
            context.l10n.bankImportAccountOnCard, cs.error),
      if (_s.cardFacts != null && !_s.targetIsCard && FeatureFlags.creditCards)
        _Warning(Icons.credit_card_off_rounded,
            context.l10n.bankImportCardTargetNotCard, cs.error),
      if (_s.foreignCurrency case final foreign?)
        _Warning(
          Icons.currency_exchange_rounded,
          context.l10n.bankImportCurrencyMismatch(
              currencySymbol(foreign), currencySymbol(_currency)),
          cs.error,
        ),
      // Kaynak dosyanın kendisi şüpheliyse (kırpık .xls / çözülemeyen hücre)
      // bunu ayrıştırma uyarılarından AYRI söyle: burada sorun bizim
      // yorumumuz değil, elimizdeki verinin eksikliği.
      if (_s.sourceTruncated)
        _Warning(Icons.broken_image_outlined,
            context.l10n.bankImportSourceTruncated, cs.error),
      if (_s.sourceUnresolvedCells > 0)
        _Warning(
          Icons.help_outline_rounded,
          context.l10n.bankImportSourceUnresolved(_s.sourceUnresolvedCells),
          cs.error,
        ),
    ];
  }

  Widget _stat(BuildContext context, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          // Satır içinde (tekrar rozeti) yer daralabiliyor: etiket taşmak
          // yerine kısalsın.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- Toolbar

  Widget _toolbar(BuildContext context) {
    final f = _filtered();
    final visible = f.visible;
    final visibleCount = visible.length;
    // Düğme yapacak bir şey yoksa pasif görünür: tekrar satırları seçilmediği
    // için yalnız tekrarlar görünürken "seç" sessizce hiçbir şey yapmıyordu.
    final canSelect = visible.any((r) => !r.$2.selected && !r.$2.isDuplicate);
    final canDeselect = visible.any((r) => r.$2.selected);
    final filtered = _effectiveFilter != _ReviewFilter.all ||
        _query.isNotEmpty ||
        f.hiddenKnown > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Column(
        children: [
          if (_searchOpen || _query.isNotEmpty) ...[
            TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              // Büyüteçle açıldı: kullanıcı yazmak istiyor.
              autofocus: true,
              // Dışarı dokununca odak bırakılır. Bırakılmazsa klavye kapansa da
              // alan odakta kalıyor ve her diyalog/menü kapanışında Flutter
              // odağı ona iade edip klavyeyi yeniden açıyordu (cihazda ölçüldü).
              // `FocusScope.of(context).unfocus()` YETMEZ: kapsam, son odaklanan
              // çocuğunu (bu alanı) hatırlamaya devam ediyor ve rota kapanınca
              // yine ona dönüyor — alanın KENDİ düğümü bırakılmalı.
              onTapOutside: (_) => _searchFocus.unfocus(),
              // Sorgu tuş başına BİR kez katlanır, aday satır başına değil.
              onChanged: (v) => setState(() {
                _query = foldTr(v);
                _rawQuery = v;
              }),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                hintText: context.l10n.bankImportSearchHint,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                // Çarpı HER ZAMAN var: sorguyu siler ve satırı kapatır.
                suffixIcon: IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchFocus.unfocus();
                    setState(() {
                      _query = '';
                      _rawQuery = '';
                      _searchController.clear();
                      _searchOpen = false;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(context, _ReviewFilter.all,
                          context.l10n.bankImportFilterAll),
                      const SizedBox(width: 6),
                      if (_s.uncategorizedCount > 0)
                        _filterChip(context, _ReviewFilter.uncategorized,
                            '${context.l10n.bankImportFilterUncategorized} (${_s.uncategorizedCount})'),
                      if (_s.uncategorizedCount > 0) const SizedBox(width: 6),
                      if (_s.toCheckCount > 0) ...[
                        _filterChip(context, _ReviewFilter.toCheck,
                            '${context.l10n.bankImportFilterToCheck} (${_s.toCheckCount})'),
                        const SizedBox(width: 6),
                      ],
                      if (_s.duplicateCount > 0)
                        _filterChip(context, _ReviewFilter.duplicates,
                            '${context.l10n.bankImportFilterDuplicates} (${_s.duplicateCount})'),
                      if (_s.leftovers.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _filterChip(context, _ReviewFilter.leftoverCandidates,
                            '${context.l10n.bankImportFilterLeftover} (${_s.leftoverCandidateIndexes.length})'),
                      ],
                      if (_hasBothTypes) ...[
                        const SizedBox(width: 6),
                        _filterChip(context, _ReviewFilter.expenses,
                            context.l10n.detailLabelGider),
                        const SizedBox(width: 6),
                        _filterChip(context, _ReviewFilter.incomes,
                            context.l10n.detailLabelGelir),
                      ],
                    ],
                  ),
                ),
              ),
              if (!_searchOpen && _query.isEmpty)
                IconButton(
                  key: const ValueKey('review-search-open'),
                  tooltip: context.l10n.bankImportSearchHint,
                  icon: const Icon(Icons.search_rounded, size: 20),
                  onPressed: () => setState(() => _searchOpen = true),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  filtered
                      ? context.l10n
                          .bankImportShownOf(visibleCount, _s.drafts.length)
                      : context.l10n.bankImportSelectedOf(
                          _s.selectedCount, _s.drafts.length),
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Kapsam GÖRÜNEN satırlar: süzgeç açıkken ekranda olmayan
              // satırların seçimi değişmiyor. Seçim tekrarları atlar (bkz.
              // `BankImportCubit.setSelectedAt`).
              IconButton(
                tooltip: context.l10n.bankImportSelectVisible,
                icon: const Icon(Icons.done_all_rounded, size: 20),
                onPressed: canSelect
                    ? () => _cubit
                        .setSelectedAt([for (final (i, _) in visible) i], true)
                    : null,
              ),
              IconButton(
                tooltip: context.l10n.bankImportDeselectVisible,
                icon: const Icon(Icons.remove_done_rounded, size: 20),
                onPressed: canDeselect
                    ? () => _cubit
                        .setSelectedAt([for (final (i, _) in visible) i], false)
                    : null,
              ),
              IconButton(
                tooltip: widget.fullscreen
                    ? context.l10n.bankImportExitFullscreen
                    : context.l10n.bankImportFullscreen,
                icon: Icon(
                    widget.fullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    size: 20),
                onPressed: widget.onToggleFullscreen,
              ),
              _overflowMenu(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, _ReviewFilter value, String label) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _effectiveFilter == value,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  /// Seyrek kullanılan işlemler tek taşma menüsünde: eylem satırına dördüncü
  /// bir simge daha sığmıyor (dar telefonda taşıyordu).
  Widget _overflowMenu(BuildContext context) {
    final visible = _visible;
    final blank = [
      for (final (index, draft) in visible)
        if (draft.needsCategory) index,
    ];
    final all = [for (final (index, _) in visible) index];

    return PopupMenuButton<void>(
      tooltip: context.l10n.bankImportMoreActions,
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      itemBuilder: (ctx) => [
        // Toplu atamanın kapsamı artık eylemin ADINDA. Tek bir "görünen
        // satırlara ata" eylemi vardı ve varsayılan süzgeç "tümü" olduğu için
        // kullanıcının ELLE seçtiği kategorilerin üzerine de yazıyordu:
        // "kalan boşları doldur" diye dokunulan düğme bütün listeyi tek
        // kategoriye çeviriyordu. Boşları doldurmak ile üzerine yazmak artık
        // iki ayrı eylem; ikincisi sayısıyla birlikte açıkça söylüyor.
        if (blank.isNotEmpty)
          _menuItem(
            icon: Icons.label_outline_rounded,
            label: context.l10n.bankImportAssignUncategorized(blank.length),
            onTap: () => _assignCategoryTo(blank),
          ),
        if (all.length > blank.length)
          _menuItem(
            icon: Icons.edit_note_rounded,
            label: context.l10n.bankImportAssignOverwrite(all.length),
            onTap: () => _assignCategoryTo(all),
          ),
        if (_s.drafts.length >= kMinGroupSize)
          _menuItem(
            icon: Icons.workspaces_outline,
            label: context.l10n.bankImportGroupSimilar,
            onTap: () => showSimilarGroupSheet(context),
          ),
        if (_s.correctableCount > 0)
          _menuItem(
            icon: Icons.published_with_changes_rounded,
            label: context.l10n.bankImportCorrectAll(_s.correctableCount),
            onTap: _cubit.correctAllApproximate,
          ),
        // Eşleme ekranı güvenilir dosyalarda atlanıyor; yanılırsak dönüş yolu.
        if (_s.canRemap)
          _menuItem(
            icon: Icons.view_column_outlined,
            label: context.l10n.bankImportRemap,
            onTap: _cubit.remap,
          ),
        _menuItem(
          icon: Icons.view_agenda_outlined,
          label: context.l10n.bankImportStepperMode,
          onTap: () => setState(() {
            _stepper = true;
            _step = 0;
          }),
        ),
        if (widget.fullscreen)
          _menuItem(
            icon: Icons.info_outline_rounded,
            label: context.l10n.bankImportSummarySheet,
            onTap: () => _showSummarySheet(context),
          ),
        // Yalnız türü GERÇEKTEN değişecek satır varsa: hepsi zaten giderse
        // "Tümünü gider yap" bir şey yapmayan düğmedir.
        if (_s.drafts.any((d) => d.type != TransactionTypeModel.expense))
          _menuItem(
            icon: Icons.trending_down_rounded,
            label:
                '${context.l10n.bankImportBatchTypeLabel} ${context.l10n.bankImportSetAllExpense}',
            onTap: () => _confirmSetAllType(TransactionTypeModel.expense),
          ),
        if (_s.drafts.any((d) => d.type != TransactionTypeModel.income))
          _menuItem(
            icon: Icons.trending_up_rounded,
            label:
                '${context.l10n.bankImportBatchTypeLabel} ${context.l10n.bankImportSetAllIncome}',
            onTap: () => _confirmSetAllType(TransactionTypeModel.income),
          ),
      ],
    );
  }

  /// Toplu tür çevirme onayla. Çevrilen satırın kategorisi yeniden tahmin
  /// edilir (gider kategorisi gelir satırına yazılamaz), yani o satırlarda
  /// elle yapılmış seçim gider — kullanıcı bunu kaç satır olduğuyla birlikte
  /// bilmeden onaylamamalı.
  Future<void> _confirmSetAllType(TransactionTypeModel type) async {
    final l10n = context.l10n;
    final changing = _s.drafts.where((d) => d.type != type).length;
    if (changing == 0) return;
    final ok = await ConfirmDialog.show(
      context,
      title: type == TransactionTypeModel.expense
          ? l10n.bankImportSetTypeExpenseTitle
          : l10n.bankImportSetTypeIncomeTitle,
      message: l10n.bankImportSetTypeBody(changing),
      confirmText: l10n.bankImportSetTypeConfirm,
    );
    if (ok && mounted) _cubit.setAllType(type);
  }

  /// Menü satırı. Etiket `Flexible`: çeviriler ve "{n} satır" gibi değişken
  /// parçalar menü genişliğini taşırabiliyor (ölçüldü), taşma yerine sarsın.
  PopupMenuItem<void> _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return PopupMenuItem<void>(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(child: Text(label)),
      ]),
    );
  }

  // -------------------------------------------------------- Category picking

  /// Kategori seçim sayfasını açar; iptalde `null`.
  ///
  /// Sayfanın içinden YENİ kategori de kurulabilir: ekstredeki bir harcama
  /// mevcut kategorilerin hiçbirine uymadığında akıştan çıkıp ayarlara gitmek
  /// gerekmemeli (öneri adımı yalnız BİLİNEN grupları önerir, kullanıcının
  /// kendi kategorisini değil).
  /// Seçici PAYLAŞILAN yüzeydir (`CategoryPickerSheet`): ağaç mantığı burada
  /// ikinci kez yazılsaydı işlem formuyla ekstre incelemesi zamanla ayrışırdı.
  Future<_PickedCategory?> _pickCategory(
    BuildContext context, {
    required bool allowTypeSwitch,
    required bool initialIsExpense,
    String? currentId,
  }) async {
    final picked = await showCategoryPickerSheet(
      context: context,
      isExpense: initialIsExpense,
      walletId: _cubit.walletId,
      currentId: currentId,
      allowTypeSwitch: allowTypeSwitch,
      onCreated: _cubit.registerCreatedCategory,
    );
    if (picked == null) return null;
    return (id: picked.id, isExpense: picked.isExpense);
  }

  Future<void> _pickCategoryForRow(
      BuildContext context, int i, ImportDraft d) async {
    final picked = await _pickCategory(
      context,
      allowTypeSwitch: false,
      initialIsExpense: !d.isIncome,
      currentId: d.categoryId,
    );
    if (picked == null || !mounted) return;
    _cubit.setDraftCategory(i, picked.id);
    await _offerSimilar(i, picked.id);
  }

  /// Bu satıra benzeyen KATEGORİSİZ satırlar varsa onlara da uygulamayı
  /// önerir — diyalogda, etkilenecek satırlar listelenip tek tek
  /// çıkarılabilir halde (bkz. [showBulkCategoryDialog]).
  ///
  /// Öneri, kullanıcı zaten doğru kararı verdiği anda gelir: aynı üye
  /// işyerinin 12 satırını tek tek gezmek yerine ilkini seçip onaylamak
  /// yeter. Onaydan sonra hedefler YENİDEN süzülür — arada elle kategori
  /// verilmiş bir satırın üzerine yazmaz.
  Future<void> _offerSimilar(int index, String categoryId) async {
    final state = _cubit.state;
    if (state is! BankImportReview) return;
    final similar = [
      for (final i in similarDraftIndexes(state.drafts, index))
        if (state.drafts[i].needsCategory) (i, state.drafts[i]),
    ];
    if (similar.isEmpty) return;

    final labels = _labelsOf(state);
    final l10n = context.l10n;
    final chosen = await showBulkCategoryDialog(
      context,
      title: l10n.bankImportSimilarTitle(labels[categoryId] ?? categoryId),
      message: l10n.bankImportSimilarBody(similar.length),
      rows: similar,
      categoryId: categoryId,
      currency: _currency,
      categoryLabels: labels,
      cancelLabel: l10n.bankImportSimilarOnlyThis,
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;
    final fresh = _cubit.state;
    if (fresh is! BankImportReview) return;
    final targets = [
      for (final i in chosen)
        if (fresh.drafts[i].needsCategory) i,
    ];
    if (targets.isNotEmpty) _cubit.applyCategoryToIndexes(targets, categoryId);
  }

  /// Taze durumdan kategori adları. Diyaloglar [_categoryLabels] yerine bunu
  /// kullanır: seçici içinden yeni kategori kurulduysa `widget.state` o
  /// karede henüz eski listeyi taşıyor ve ad yerine kimlik görünürdü.
  static Map<String, String> _labelsOf(BankImportReview s) => {
        ...buildImportCategoryLabels(s.expenseCategories),
        ...buildImportCategoryLabels(s.incomeCategories),
      };

  /// [targets] indekslerine toplu kategori uygular. Kapsamı ÇAĞIRAN belirler
  /// (yalnız kategorisiz olanlar / görünenlerin tamamı); bu fonksiyon verilen
  /// kümenin dışına asla çıkmaz.
  ///
  /// Kategori kendi türündeki satırlara uygulanır; karışık listede seçilmeyen
  /// tür olduğu gibi kalır. Hiç eşleşen satır kalmazsa sessizce dönmek yerine
  /// söylenir — eskiden gider kategorisi seçilen gelir listesinde düğme hiçbir
  /// şey yapmıyor gibi görünüyordu.
  ///
  /// `context` bilerek parametre DEĞİL: seçim sayfası beklenirken sayfa
  /// kapanmış olabilir, `mounted` ancak State'in kendi context'ini korur.
  Future<void> _assignCategoryTo(List<int> targets) async {
    if (targets.isEmpty) return;
    final rows = [for (final i in targets) (i, _s.drafts[i])];
    final hasExpense = rows.any((r) => !r.$2.isIncome);
    final hasIncome = rows.any((r) => r.$2.isIncome);

    final picked = await _pickCategory(
      context,
      allowTypeSwitch: hasExpense && hasIncome,
      initialIsExpense: hasExpense,
    );
    if (picked == null || !mounted) return;

    final matching = [
      for (final row in rows)
        if (row.$2.isIncome != picked.isExpense) row,
    ];
    final fresh = _cubit.state;
    final labels =
        fresh is BankImportReview ? _labelsOf(fresh) : _categoryLabels;
    final l10n = context.l10n;
    // Önizleme: hangi satırlara uygulanacağı (ve kimin kategorisinin
    // DEĞİŞECEĞİ) onaydan önce görünür. Uygulamanın kendisi zaten listede
    // görünür, ayrıca "yapıldı" mesajı gerekmez.
    final chosen = await showBulkCategoryDialog(
      context,
      title: l10n.bankImportBulkTitle(labels[picked.id] ?? picked.id),
      message: l10n.bankImportBulkBody,
      rows: matching,
      categoryId: picked.id,
      currency: _currency,
      categoryLabels: labels,
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;
    _cubit.applyCategoryToIndexes(chosen, picked.id);
  }

  // --------------------------------------------------------------------- Row

  Widget _row(BuildContext context, int i, ImportDraft d) {
    final cs = Theme.of(context).colorScheme;
    final accent = d.isIncome ? AppGradients.savings : AppGradients.debt;
    // Seçimsiz satır soluklaşır — ama tekrar paneli SOLUKLAŞMAZ: satırın
    // neden eklenmeyeceğini anlatan tek yer orası, okunaklı kalmalı.
    final dim = d.selected ? 1.0 : 0.45;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: d.selected,
            visualDensity: VisualDensity.compact,
            onChanged: (_) => _cubit.toggleDraft(i),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: dim,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _editRow(i, d),
                          borderRadius: BorderRadius.circular(4),
                          child: Text(
                            d.description.isEmpty ? '—' : d.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _editRow(i, d, focusAmount: true),
                        borderRadius: BorderRadius.circular(4),
                        child: Text(
                          '${d.isIncome ? '+' : '−'}${_money(d.amount)}',
                          style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Opacity(
                  opacity: dim,
                  child: Row(
                    children: [
                      Text(AppFormatters.dateShort.format(d.date),
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          // Transfer olarak işaretli satırın kategorisi olmaz.
                          child: d.isTransfer
                              ? _transferChip(context, i, d)
                              : _categoryControl(context, i, d),
                        ),
                      ),
                      // Görünür düzenleme kolu: açıklama, tutar ve tür TEK
                      // sayfada. Eskiden burada 20dp'lik bir ok vardı ve
                      // dokununca türü onaysız çevirip kategoriyi sıfırlıyordu.
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        // 40×32: satırın ikinci çizgisini kategori düğmesiyle
                        // aynı yükseklikte tutar (48dp her satırı ~%25 uzatır
                        // ve listeden bir satır götürürdü). Açıklama ve tutar
                        // da aynı sayfayı açar; bu yalnız GÖRÜNEN koldur.
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 32),
                        tooltip: context.l10n.bankImportEditRowTitle,
                        icon: Icon(Icons.edit_outlined,
                            size: 18, color: cs.onSurfaceVariant),
                        onPressed: () => _editRow(i, d),
                      ),
                    ],
                  ),
                ),
                // Kendi cüzdanların arasındaki para taşıması bir harcama ya
                // da gelir değildir: kategori seçtirmek yerine BAĞLAMAK
                // önerilir (yalnız öneri — karar kullanıcının).
                if (d.selected && !d.isTransfer && !d.isDuplicate)
                  if (_transferHintOf(d) case final hint?)
                    _transferSuggestion(context, i, d, hint),
                // Sürpriz olmasın: bu satır yazılınca kalan taksitler de
                // ileri tarihe yazılır.
                if (d.selected && (d.installment?.remaining ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Text(
                      context.l10n.bankImportInstallmentNote(
                        d.installment!.remaining,
                        AppFormatters.dateShort.format(
                            d.installment!.dateOf(d.installment!.count)),
                      ),
                      key: ValueKey('review-installment-note-$i'),
                      style: TextStyle(fontSize: 12, color: cs.primary),
                    ),
                  ),
                if (d.isDuplicate) _duplicatePanel(i, d),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _duplicatePanel(int i, ImportDraft d) {
    final tag = d.duplicateOf?.existingTag;
    // Belirsiz eşleşmenin diğer adayı — yalnız hâlâ serbestse (arada başka
    // bir kayda eşleşmiş ya da kullanıcı bağlamış olabilir).
    final alt = d.duplicateOf?.alternativeDraftIndex;
    final altDraft = (alt != null && alt >= 0 && alt < _s.drafts.length)
        ? _s.drafts[alt]
        : null;
    final freeAlternative = altDraft?.duplicateOf == null ? altDraft : null;
    return DuplicateMatchPanel(
      draft: d,
      currency: _currency,
      // Sistem kaydının etiketi bir kimlik değil, okunur addır ("Borç
      // Ödemesi"); kategori kimliğiyse listeden çözülür.
      existingCategoryLabel: tag == null
          ? null
          : (_categoryLabels[tag] ??
              ((d.duplicateOf?.existingIsSystem ?? false)
                  ? context.translateSystemTag(tag)
                  : null)),
      onSelected: (value) => _cubit.setDraftSelected(i, value),
      onCorrect: (value) => _cubit.setCorrectExisting(i, value),
      onRelocate: (value) => _cubit.setRelocateExisting(i, value),
      alternativeDraft: freeAlternative,
      onMoveMatch:
          freeAlternative == null ? null : () => _cubit.moveMatch(i, alt!),
    );
  }

  /// Satırın kategori düğmesi. Açılır liste (Dropdown) yerine sayfa açar:
  /// listeye "yeni kategori" girişi eklenebilsin ve 20+ kategori dar satırda
  /// okunabilsin diye.
  ///
  /// Tahmin edilemeyen taslaklar `categoryId: null` gelir (bkz. cubit); boş
  /// görünmek yerine kırmızı bir "Kategori seç" çağrısı basılır — kategorisiz
  /// satır zaten eklenemez.
  // ------------------------------------------------- transfer olarak bağla

  /// Satır kendi cüzdanların arasındaki bir para taşıması gibi mi görünüyor
  /// (karta ödeme, kartın aldığı ödeme, karttan çıkan havale)? Diğer bağlama
  /// ipuçları (birikim, borç) bu ekranda sorulmaz: onlar kayıt seçtirir ve
  /// bitiş ekranında önerilir.
  LinkHint? _transferHintOf(ImportDraft d) {
    final hint = linkHintOf(
      d.description,
      isIncome: d.isIncome,
      onCard: _s.targetIsCard,
    );
    return switch (hint) {
      LinkHint.cardPayment ||
      LinkHint.cardPaymentReceived ||
      LinkHint.ownTransfer =>
        hint,
      _ => null,
    };
  }

  List<WalletEntity> _wallets(BuildContext context) {
    try {
      final state = context.read<WalletBloc>().state;
      return state is WalletLoadedSt ? state.wallets : const [];
    } on ProviderNotFoundException {
      return const [];
    }
  }

  WalletEntity? _walletById(BuildContext context, String? id) {
    if (id == null) return null;
    for (final w in _wallets(context)) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// Karşı cüzdan belliyse o: banka satırında son 4 hanesi açıklamada geçen
  /// TEK kart; kart dökümünde kartın ödendiği hesap. Belli değilse `null`
  /// (kullanıcı seçer).
  WalletEntity? _suggestedCounterpart(
    BuildContext context,
    ImportDraft d,
    LinkHint hint,
  ) {
    final wallets = _wallets(context);
    final targetId = _cubit.walletId;
    final id = switch (hint) {
      LinkHint.cardPayment => cardIdByLast4(d.description, [
          for (final w in wallets)
            if (w.id != null && w.creditCard?.last4 != null)
              (id: w.id!, last4: w.creditCard!.last4!),
        ]),
      LinkHint.cardPaymentReceived =>
        _walletById(context, targetId)?.creditCard?.paymentWalletId,
      _ => null,
    };
    return id == targetId ? null : _walletById(context, id);
  }

  Future<void> _markTransfer(
    BuildContext context,
    int i,
    ImportDraft d,
    LinkHint hint,
  ) async {
    var counterpart = _suggestedCounterpart(context, d, hint);
    if (counterpart == null) {
      final others = [
        for (final w in _wallets(context))
          if (w.id != null && w.id != _cubit.walletId) w,
      ];
      if (others.isEmpty) return;
      final picked = await RowActionSheet.show<String>(
        context,
        title: context.l10n.baglaCuzdanSec,
        icon: Icons.swap_horiz_rounded,
        accent: Theme.of(context).colorScheme.primary,
        keyPrefix: 'review-transfer-wallet',
        actions: [
          for (final w in others)
            RowAction(
              value: w.id!,
              icon: w.isCreditCard
                  ? Icons.credit_card_rounded
                  : Icons.account_balance_wallet_rounded,
              title: w.name,
              subtitle: formatMoney(w.balance, currency: w.currency),
            ),
        ],
      );
      if (picked == null || !context.mounted) return;
      counterpart = _walletById(context, picked);
    }
    final id = counterpart?.id;
    if (id != null) _cubit.setDraftTransfer(i, id);
  }

  /// "Kart ödemesi mi? Bonus ile bağla" — tek dokunuşla satır transfer olur
  /// ve kategori aranmaz.
  Widget _transferSuggestion(
    BuildContext context,
    int i,
    ImportDraft d,
    LinkHint hint,
  ) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final question = switch (hint) {
      LinkHint.cardPaymentReceived => l10n.bankImportTransferAskOwnPayment,
      LinkHint.ownTransfer => l10n.bankImportTransferAskOwnTransfer,
      _ => l10n.bankImportTransferAskCard,
    };
    final counterpart = _suggestedCounterpart(context, d, hint);
    final action = counterpart == null
        ? l10n.bankImportLinkButton
        : l10n.bankImportTransferLinkTo(counterpart.name);
    return InkWell(
      key: ValueKey('review-transfer-suggest-$i'),
      onTap: () => _markTransfer(context, i, d, hint),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(Icons.swap_horiz_rounded, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: '$question ',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  children: [
                    TextSpan(
                      text: action,
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// İşaretli satırda kategori kolunun yerini alır; dokununca işaret kalkar
  /// (satır yeniden kategori ister).
  Widget _transferChip(BuildContext context, int i, ImportDraft d) {
    final cs = Theme.of(context).colorScheme;
    final name = _walletById(context, d.transferWalletId)?.name ?? '—';
    return Tooltip(
      message: context.l10n.bankImportTransferUnmark,
      child: InkWell(
        key: ValueKey('review-transfer-chip-$i'),
        onTap: () => _cubit.setDraftTransfer(i, null),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horiz_rounded, size: 14, color: cs.primary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  context.l10n.bankImportTransferChip(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.close_rounded, size: 14, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryControl(BuildContext context, int i, ImportDraft d) {
    final cs = Theme.of(context).colorScheme;
    final cat = _categoryById(_catsFor(d.isIncome), d.categoryId);
    final missing = cat == null;
    return InkWell(
      onTap: () => _pickCategoryForRow(context, i, d),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        // Bu ekranın en çok dokunulan kolu; eskiden ~24dp yüksekliğindeydi.
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              missing
                  ? Icons.error_outline_rounded
                  : AppIcons.getIconData(cat.iconName),
              size: 14,
              color: missing ? cs.error : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                missing
                    ? context.l10n.bankImportPickCategoryHint
                    : (_categoryLabels[cat.id] ?? cat.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: missing ? cs.error : cs.onSurface,
                  fontWeight: missing ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (!missing) ..._sourceMarker(context, d.categorySource),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  /// Kategorinin nereden geldiğini gösteren küçük işaret: geçmişten
  /// öğrenilen (saat) ve yalnız bankanın etiketinden tahmin edilen (soru —
  /// "buna bir bak"). Sözlükten kesin eşleşen ve elle seçilen işaretsizdir.
  List<Widget> _sourceMarker(BuildContext context, CategorySource? source) {
    final cs = Theme.of(context).colorScheme;
    final (icon, color, tip) = switch (source) {
      CategorySource.history => (
          Icons.history_rounded,
          cs.onSurfaceVariant,
          context.l10n.bankImportSourceHistory
        ),
      CategorySource.bankTag => (
          Icons.help_outline_rounded,
          cs.tertiary,
          context.l10n.bankImportSourceBankTag
        ),
      _ => (null, null, null),
    };
    if (icon == null) return const [];
    return [
      const SizedBox(width: 3),
      Tooltip(
        message: tip!,
        child: Icon(icon, size: 13, color: color),
      ),
    ];
  }

  Widget _bottomBar(BuildContext context) {
    final blocked = _s.selectedUncategorizedCount;
    final corrections = _s.correctionCount;
    final onlyCorrections = _s.selectedCount == 0 && corrections > 0;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (blocked > 0) _uncategorizedBanner(context, blocked),
          // Düzeltme, var olan bir kaydı DEĞİŞTİRİR: düğmeye basmadan önce
          // kaç kaydın etkileneceği görünmeli.
          if (corrections > 0 && !onlyCorrections)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.published_with_changes_rounded,
                      size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.l10n.bankImportCorrectionsPending(corrections),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          // Eklenecek satırların toplamı: eklemeden önce ekstrenin kendi
          // Borç/Alacak toplamlarıyla karşılaştırılabilsin.
          if (_s.selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                context.l10n.bankImportTotals(
                  _money(_s.selectedExpenseTotal),
                  _money(_s.selectedIncomeTotal),
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _s.canCommit ? () => _cubit.commit() : null,
              icon: const Icon(Icons.playlist_add_check_rounded),
              label: Text(onlyCorrections
                  ? context.l10n.bankImportApplyCorrections(corrections)
                  : context.l10n.bankImportAdd(_s.selectedCount)),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  /// Seçili ama kategorisiz satır varsa ekleme kapalıdır: kategorisiz hareket
  /// deftere boş etiketle yazılır ve bütçe/raporda hiçbir kategoriye sayılmaz
  /// (elle girişte de kategori zorunlu). Şerit doğrudan o satırlara götürür.
  Widget _uncategorizedBanner(BuildContext context, int count) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final compact = TextButton.styleFrom(
      foregroundColor: cs.error,
      visualDensity: VisualDensity.compact,
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 2, 0),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.bankImportUncategorizedBlockedShort(count),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Engelin iki çıkışı da burada: satırlara git ya da hepsine tek
            // seferde kategori ver. Toplu atama eskiden yalnız ⋮ menüsündeydi;
            // kullanıcı şeride dokunup satırları TEK TEK kategorize ediyordu.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: compact,
                  onPressed: () => setState(() {
                    _stepper = false;
                    _filter = _ReviewFilter.uncategorized;
                  }),
                  child: Text(l10n.bankImportShowUncategorized),
                ),
                TextButton(
                  key: const ValueKey('review-assign-blocked'),
                  style: compact,
                  onPressed: () {
                    setState(() => _stepper = false);
                    _assignCategoryTo([
                      for (var i = 0; i < _s.drafts.length; i++)
                        if (_s.drafts[i].selected &&
                            _s.drafts[i].needsCategory &&
                            // Kart ödemesi gibi görünen satıra toplu
                            // kategori basılmaz: o satır bağlanmalı, karar
                            // satırın kendi önerisinden verilir.
                            _transferHintOf(_s.drafts[i]) == null)
                          i,
                    ]);
                  },
                  child: Text(l10n.bankImportAssignBlocked),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Stepper mode

  Widget _buildStepper(BuildContext context) {
    final total = _s.drafts.length;
    final d = _s.drafts[_step];
    final accent = d.isIncome ? AppGradients.savings : AppGradients.debt;

    return Column(
      children: [
        LinearProgressIndicator(value: (_step + 1) / total),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${_step + 1} / $total'),
              const Spacer(),
              // Tam ekranda AppBar yok: kipten çıkış burada da bulunmalı,
              // yoksa stepper'a geçen kullanıcı için tek yol geri hareketi
              // kalıyor.
              if (widget.fullscreen)
                IconButton(
                  tooltip: context.l10n.bankImportExitFullscreen,
                  icon: const Icon(Icons.fullscreen_exit_rounded, size: 20),
                  onPressed: widget.onToggleFullscreen,
                ),
              TextButton.icon(
                onPressed: () => setState(() => _stepper = false),
                icon: const Icon(Icons.list_rounded, size: 18),
                label: Text(context.l10n.bankImportFilterAll),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            // Kaydırılabilir: bağlama önerisi ve taksit notu eklenince içerik
            // küçük ekranda ortalanan sütuna sığmayabilir.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppFormatters.dateLong.format(d.date)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () =>
                        _editDescriptionDialog(context, _step, d.description),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              d.description.isEmpty ? '—' : d.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.outline),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _editAmountDialog(context, _step, d.amount),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${d.isIncome ? '+' : '−'}${_money(d.amount)}',
                            style: TextStyle(
                                color: accent,
                                fontSize: 28,
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined,
                              size: 20, color: accent.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Dokunma kolu [_categoryControl]'ün kendisinde; burada
                  // yalnız daha görünür bir çerçeveye alınıyor (iç içe iki
                  // tıklama alanı kurulmaz).
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      // Transfer olarak işaretli satırın kategorisi olmaz
                      // (liste görünümüyle aynı kural). Eskiden bu görünüm
                      // işaretli satırda da "Kategori seç" gösteriyordu.
                      child: d.isTransfer
                          ? _transferChip(context, _step, d)
                          : _categoryControl(context, _step, d),
                    ),
                  ),
                  // Liste görünümündeki bağlama önerisi burada YOKTU: kart
                  // ödemesi satırına adım adım gelen kullanıcı anlamsız bir
                  // kategori seçmek zorunda kalıyordu.
                  if (!d.isTransfer && !d.isDuplicate)
                    if (_transferHintOf(d) case final hint?)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _transferSuggestion(context, _step, d, hint),
                      ),
                  if ((d.installment?.remaining ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        context.l10n.bankImportInstallmentNote(
                          d.installment!.remaining,
                          AppFormatters.dateShort.format(
                              d.installment!.dateOf(d.installment!.count)),
                        ),
                        key: ValueKey('review-installment-note-$_step'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  if (d.isDuplicate) ...[
                    const SizedBox(height: 8),
                    _duplicatePanel(_step, d),
                  ],
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Tekrar sanılan satırda birincil eylem ATLA'dır: hızlı ilerleyen
              // kullanıcı büyük düğmeye basar ve eskiden bu "Ekle"ydi — panel
              // "zaten defterde" derken satır ikinci kez ekleniyordu.
              if (d.isDuplicate && !d.selected)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        // Kategorisiz satır eklenemez (bkz. [_uncategorizedBanner]).
                        onPressed:
                            d.needsCategory ? null : () => _stepDecide(true),
                        child: Text(context.l10n.bankImportStepAddAnyway),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _stepDecide(false),
                        child: Text(context.l10n.bankImportStepSkip),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _stepDecide(false),
                        child: Text(context.l10n.bankImportStepSkip),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        // Kategorisiz satır eklenemez (bkz. [_uncategorizedBanner]).
                        onPressed:
                            d.needsCategory ? null : () => _stepDecide(true),
                        child: Text(context.l10n.bankImportStepAdd),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(context.l10n.bankImportStepAddRest),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _confirmLeave,
                      child: Text(context.l10n.bankImportStepCancelAll),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _stepDecide(bool add) {
    _cubit.setDraftSelected(_step, add);
    if (_step >= _s.drafts.length - 1) {
      _finish();
    } else {
      setState(() => _step++);
    }
  }

  /// Toplu yazımı başlatır. Seçililer arasında kategorisiz satır kalmışsa
  /// (stepper yalnız gezilen satırları etkiler) yazmaz; listeye dönüp o
  /// satırları gösterir.
  ///
  /// Durum cubit'ten TAZE okunur: `widget.state` bu karede hâlâ mutasyon
  /// öncesini taşıyor olabilir.
  Future<void> _finish() async {
    final s = _cubit.state;
    if (s is BankImportReview && !s.canCommit && s.selectedCount > 0) {
      // Kullanıcı açıklamasız listeye atılmasın: neden eklenemediği ve
      // nereye gidileceği sorulur; vazgeçerse stepper'da kalır.
      final l10n = context.l10n;
      final show = await ConfirmDialog.show(
        context,
        title: l10n.bankImportStepMissingTitle,
        message:
            l10n.bankImportUncategorizedBlocked(s.selectedUncategorizedCount),
        confirmText: l10n.bankImportStepMissingShow,
      );
      if (show && mounted) {
        setState(() {
          _stepper = false;
          _filter = _ReviewFilter.uncategorized;
        });
      }
      return;
    }
    _cubit.commit();
  }

  /// Liste satırını düzenler; yalnız DEĞİŞEN alanlar cubit'e yazılır (her
  /// yazım tekrar eşleşmesini yeniden kurar).
  Future<void> _editRow(int i, ImportDraft d,
      {bool focusAmount = false}) async {
    final edit = await showDraftEditSheet(
      context,
      draft: d,
      currency: _currency,
      focusAmount: focusAmount,
    );
    if (edit == null || !mounted) return;
    if (edit.description != d.description) {
      _cubit.setDraftDescription(i, edit.description);
    }
    if (edit.amount != d.amount) _cubit.setDraftAmount(i, edit.amount);
    if (edit.type != d.type) _cubit.setDraftType(i, edit.type);
  }

  Future<void> _editDescriptionDialog(
      BuildContext context, int i, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.bankImportEditDescTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration:
              InputDecoration(labelText: ctx.l10n.bankImportEditDescLabel),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.iptal)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(ctx.l10n.kaydet)),
        ],
      ),
    );
    if (result != null) {
      _cubit.setDraftDescription(i, result);
    }
  }

  Future<void> _editAmountDialog(
      BuildContext context, int i, double current) async {
    final controller =
        TextEditingController(text: formatAmountForInput(current));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.bankImportEditAmountTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: ctx.l10n.bankImportEditAmountLabel,
            // Hedef cüzdanın birimi; sabit '₺' USD/EUR cüzdanda yanlıştı.
            suffixText: currencySymbol(_currency),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.iptal)),
          FilledButton(
            onPressed: () {
              final val = parseMoneyInput(controller.text);
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: Text(ctx.l10n.kaydet),
          ),
        ],
      ),
    );
    if (result != null) {
      _cubit.setDraftAmount(i, result);
    }
  }
}

/// İnceleme ekranında gösterilen tek bir uyarı satırı.
class _Warning {
  final IconData icon;
  final String message;
  final Color color;
  const _Warning(this.icon, this.message, this.color);
}
