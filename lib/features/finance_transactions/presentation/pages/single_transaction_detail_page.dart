import 'dart:async';
import 'dart:io';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/features/coupling/presentation/link_transaction_flow.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/receipt_viewer_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_action_sheet.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:cunehat/features/finance_transactions/domain/installments.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/installment_group_edit_sheet.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tek bir işlemin premium detay ekranı.
///
/// Karttan [Navigator.push] ile açılır; düzenleme/silme için aktif
/// [TransactionBloc] `BlocProvider.value` ile sağlanmalıdır.
///
/// Sayfa açılış anındaki [item]'ı DEĞİL, bloc'taki canlı defteri gösterir:
/// buradan yapılan düzenleme aynı sayfada anında yansımalı. Karttan taşınan
/// değerler (kategori adı/ikonu, işlem sonrası bakiye) yalnız ilk kareyi
/// doldurur; sonrasında canlı kaynaklardan yeniden çözülürler.
class SingleTransactionDetailPage extends StatefulWidget {
  final TransactionWithBalance item;
  final IconData? categoryIcon;

  /// Kategorinin çözülmüş görünen adı (karttan taşınır). null ise `tag`
  /// l10n'a düşer — sistem etiketleri için doğru davranış budur.
  final String? categoryLabel;

  /// Hero animasyonunun karttaki ikonla eşleşmesi için benzersiz etiket.
  final String heroTag;

  const SingleTransactionDetailPage({
    super.key,
    required this.item,
    required this.heroTag,
    this.categoryIcon,
    this.categoryLabel,
  });

  @override
  State<SingleTransactionDetailPage> createState() =>
      _SingleTransactionDetailPageState();
}

class _SingleTransactionDetailPageState
    extends State<SingleTransactionDetailPage> {
  /// Kategori kimliği → görünen ad/ikon.
  ///
  /// Karttan gelen [SingleTransactionDetailPage.categoryLabel]/`categoryIcon`
  /// AÇILIŞ etiketine donmuştur; kullanıcı bu sayfadan kategoriyi
  /// değiştirdiğinde donmuş değer yanlışa döner. İndeks yüklenene kadar
  /// karttan gelen değer kullanılır (ilk karede boşluk olmasın), sonrasında
  /// `tag` üzerinden canlı çözüm yapılır.
  Map<String, IconData> _icons = const {};
  Map<String, String> _labels = const {};

  StreamSubscription<void>? _categoriesSub;

  @override
  void initState() {
    super.initState();
    _loadCategoryIndex();
    // Düzenleme sayfasından kategori yöneticisi açılabiliyor; yeniden
    // adlandırma bu sayfa açıkken de yansımalı.
    _categoriesSub = getIt<CategoriesChangedNotifier>()
        .stream
        .listen((_) => _loadCategoryIndex());
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCategoryIndex() async {
    // Kategori deposu `Either` DEĞİL, EXCEPTION fırlatır (CacheException).
    // Kardeş sayfalardaki kalıp (bkz. `TransactionPage._loadCategoryIcons`):
    // hata hâlinde ÖNCEKİ indeks korunur, ilk açılışta karttan gelen ad/ikon
    // görünmeye devam eder. Eskiden bu çağrı korumasızdı ve hata sayfadan
    // yakalanmadan kaçıyordu.
    final List<CategoryEntity> categories;
    try {
      categories = await fetchAllCategories(getIt<CategoryRepository>());
    } catch (e, st) {
      reportError('İşlem detayı · kategori indeksi', e, st);
      return;
    }
    if (!mounted) return;
    final index = buildCategoryDisplayIndex(categories);
    setState(() {
      _icons = index.icons;
      _labels = index.labels;
    });
  }

  /// Etiket açılıştakiyle aynıysa karttan gelen çözülmüş değer güvenlidir;
  /// değiştiyse yalnız canlı indeks doğru cevabı verir.
  bool _tagUnchanged(TransactionEntity t) =>
      t.tag == widget.item.transaction.tag;

  String _categoryLabelOf(BuildContext context, TransactionEntity t) =>
      _labels[t.tag] ??
      (_tagUnchanged(t) ? widget.categoryLabel : null) ??
      context.translateSystemTag(t.tag);

  IconData? _categoryIconOf(TransactionEntity t) =>
      _icons[t.tag] ?? (_tagUnchanged(t) ? widget.categoryIcon : null);

  /// "İşlem sonrası bakiye"yi CANLI defterden hesaplar.
  ///
  /// Karttan gelen `balanceAfter` sayfa açıldığı ana donmuştur: tutar
  /// düzenlenince ya da araya işlem girince yanlışa döner. Cüzdanın canlı
  /// bakiyesi okunamıyorsa (WalletBloc sağlanmamış) donmuş değere düşülür —
  /// hiç göstermemektense açılıştaki doğru değeri göstermek yeğdir.
  double _balanceAfter(
    BuildContext context,
    List<TransactionEntity> ledger,
    TransactionEntity t,
  ) {
    final balance = context.watchWalletBalance(t.walletId);
    if (balance == null) return widget.item.balanceAfter;

    final view = buildLedgerView(
      allTransactions: ledger.where((e) => e.walletId == t.walletId).toList(),
      currentBalance: balance,
    );
    for (final e in view) {
      if (e.transaction.id == t.id) return e.balanceAfter;
    }
    return widget.item.balanceAfter;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionBloc, TransactionState>(
      listener: (context, state) {
        // İşlem defterden gittiyse sayfanın gösterecek bir şeyi kalmaz.
        // Yalnız YERLEŞİK durumlara bakılır: TransactionLoading yükleme
        // sırasında listeyi boş taşıyabilir, TransactionError ise eylem
        // ÖNCESİNDEKİ listeyi taşır; ikisi de yanlış kapanmaya yol açardı.
        if (state is! TransactionActionSuccess && state is! TransactionLoaded) {
          return;
        }
        final isDeleted = !state.currentTransactions
            .any((tx) => tx.id == widget.item.transaction.id);
        if (isDeleted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final tList = state.currentTransactions;
        final t = tList.firstWhere(
          (x) => x.id == widget.item.transaction.id,
          orElse: () => widget.item.transaction,
        );

        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final accent = t.isIncome ? AppGradients.savings : AppGradients.debt;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(context.l10n.islemDetayi),
            actions: [
              if (!t.isSystem)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: context.l10n.duzenle,
                  onPressed: () => _edit(context, t),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32)
                .plusSystemBottom(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero ikon + tutar
                Center(
                  child: Column(
                    children: [
                      Hero(
                        tag: widget.heroTag,
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withValues(alpha: 0.22),
                                accent.withValues(alpha: 0.06),
                              ],
                            ),
                            border: Border.all(
                                color: accent.withValues(alpha: 0.3),
                                width: 1.5),
                          ),
                          child: Icon(
                            _categoryIconOf(t) ??
                                (t.isIncome
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded),
                            color: accent,
                            size: 38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SignedMoneyText(
                        amount: t.amount,
                        isExpense: t.isExpense,
                        currency: context.activeWalletCurrency,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 36,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (t.isSystem) ...[
                        const SizedBox(height: 8),
                        _systemBadge(context, scheme),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Bilgi kartı
                AppCard(
                  accent: accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Column(
                    children: [
                      _infoRow(context,
                          icon: Icons.sell_rounded,
                          label: context.l10n.labelKategori,
                          value: _categoryLabelOf(context, t)),
                      _divider(scheme),
                      _infoRow(context,
                          icon: Icons.event_rounded,
                          label: context.l10n.detailLabelTarih,
                          value: AppFormatters.dateLong.format(t.date)),
                      _divider(scheme),
                      // Kart harcaması: bankanın tahsil ettiği gün. Rapor ve
                      // İçgörü harcamayı bu güne (ödeme ayına) sayar.
                      if (_paymentDayOf(context, t) case final paid?) ...[
                        _infoRow(context,
                            icon: Icons.credit_card_rounded,
                            label: context.l10n.kkOdemeGunu,
                            value: AppFormatters.dateLong.format(paid)),
                        _divider(scheme),
                      ],
                      _infoRow(context,
                          icon: Icons.schedule_rounded,
                          label: context.l10n.detailLabelSaat,
                          value: AppFormatters.time.format(t.date)),
                      _divider(scheme),
                      _infoRow(context,
                          icon: t.isIncome
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          label: context.l10n.detailLabelTur,
                          value: t.isIncome
                              ? context.l10n.detailLabelGelir
                              : context.l10n.detailLabelGider,
                          valueColor: accent),
                      _divider(scheme),
                      Builder(builder: (context) {
                        final balanceAfter = _balanceAfter(context, tList, t);
                        return _infoRow(context,
                            icon: Icons.account_balance_wallet_rounded,
                            label: context.l10n.detailLabelIslemSonrasiBakiye,
                            valueWidget: MoneyText(
                              amount: balanceAfter,
                              currency: context.activeWalletCurrency,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: balanceAfter >= 0
                                    ? scheme.onSurface
                                    : AppGradients.debt,
                              ),
                            ));
                      }),
                    ],
                  ),
                ),

                // Taksit grubu: alışverişin bütün aylık satırları birlikte;
                // grup tek seferde silinir (geri alınabilir).
                if (t.installmentGroupId case final groupId?) ...[
                  const SizedBox(height: 24),
                  _InstallmentGroupCard(
                    current: t,
                    group: installmentGroup(tList, groupId),
                    accent: accent,
                    onDeleteAll: (group) => _deleteGroup(context, group),
                    onEditAll: (group) => _editGroup(
                      context,
                      group,
                      categoryLabel: _categoryLabelOf(context, t),
                    ),
                  ),
                ],

                if (t.receiptFileName != null) ...[
                  const SizedBox(height: 24),
                  _ReceiptCard(fileName: t.receiptFileName!, accent: accent),
                ],

                const SizedBox(height: 24),

                // Aksiyonlar
                if (t.isSystem) ...[
                  _systemNotice(context, scheme, t),
                  if (isRemovableTransferLeg(t)) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => confirmAndRemoveTransfer(context, t),
                      icon: const Icon(Icons.link_off_rounded),
                      label: Text(context.l10n.transferiKaldir),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppGradients.debt,
                        side: BorderSide(
                            color: AppGradients.debt.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _delete(context, t),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(context.l10n.sil),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppGradients.debt,
                            side: BorderSide(
                                color:
                                    AppGradients.debt.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _edit(context, t),
                          icon: const Icon(Icons.edit_rounded),
                          label: Text(context.l10n.duzenle),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _duplicate(context, t),
                    icon: const Icon(Icons.content_copy_rounded),
                    label: Text(context.l10n.yenidenEkle),
                  ),
                  if (canLinkTransaction(t)) ...[
                    TextButton.icon(
                      onPressed: () => startLinkTransactionFlow(
                        context,
                        transaction: t,
                        currency: context.walletById(t.walletId)?.currency ??
                            context.activeWalletCurrency,
                      ),
                      icon: const Icon(Icons.link_rounded),
                      label: Text(context.l10n.baglaEylemi),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Kart harcamasının ödeme günü (bkz. [cardPaymentDate]); kart dışı ya
  /// da sistem hareketinde `null`.
  DateTime? _paymentDayOf(BuildContext context, TransactionEntity t) {
    if (!FeatureFlags.creditCards || t.isSystem) return null;
    final card = context.walletById(t.walletId)?.creditCard;
    return card == null ? null : cardPaymentDate(t, card);
  }

  /// Aynı içerikle yeni kayıt (bkz. `TransactionAction.duplicate`).
  void _duplicate(BuildContext context, TransactionEntity t) {
    TransactionSheetHandler.showSheet(
      context: context,
      userId: t.userId,
      walletId: t.walletId,
      type: t.type,
      prefill: t,
    );
  }

  void _edit(BuildContext context, TransactionEntity t) {
    if (t.isSystem) return;
    TransactionSheetHandler.showSheet(
      context: context,
      userId: t.userId,
      walletId: t.walletId,
      type: t.type,
      initialTransaction: t,
    );
  }

  /// Onay diyaloğu YOK: silme anında yapılır, snackbar 6 saniye boyunca
  /// "Geri al" sunar (bkz. `showDeletionMessage`). Sayfa silme sonrası
  /// kapandığı için mesaj listenin üstünde görünür.
  void _delete(BuildContext context, TransactionEntity t) {
    if (t.id != null) {
      context.read<TransactionBloc>().add(DeleteTransactionEvent(t.id!));
    }
  }

  /// Taksitli ALIŞVERİŞİ düzenler: toplam, ad ve kategori bütün satırlara
  /// yazılır (bkz. `redistributeInstallments`). Sistem ve benimsenmiş
  /// satırlar dışarıda kalır — onlar sahibinden yönetilir.
  Future<void> _editGroup(
    BuildContext context,
    List<TransactionEntity> group, {
    String? categoryLabel,
  }) async {
    final editable = [
      for (final g in group)
        if (g.id != null && !g.isSystem && !g.isAdopted) g,
    ];
    if (editable.isEmpty) return;
    final bloc = context.read<TransactionBloc>();
    final updated = await InstallmentGroupEditSheet.show(
      context,
      group: editable,
      currency: context.walletById(editable.first.walletId)?.currency ??
          context.activeWalletCurrency,
      categoryLabel: categoryLabel,
    );
    if (updated == null || updated.isEmpty) return;
    bloc.add(UpdateTransactionsEvent(
      updated,
      label: installmentBaseTitle(updated.first.title),
    ));
  }

  /// Taksit grubunun TÜMÜNÜ siler (tek "Geri al" hepsini getirir). Sayfa,
  /// kendi satırı defterden gidince kapanır (dinleyici).
  void _deleteGroup(BuildContext context, List<TransactionEntity> group) {
    final ids = [
      for (final g in group)
        if (g.id != null && !g.isSystem) g.id!,
    ];
    if (ids.isEmpty) return;
    context.read<TransactionBloc>().add(DeleteTransactionsEvent(
          ids,
          label: installmentBaseTitle(group.first.title),
        ));
  }

  Widget _systemBadge(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            context.l10n.otomatikIslem,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Bağlanmış (benimsenmiş) satırda özgün kategori de söylenir: kayıt
  /// silinince satır o kategoriye döner.
  String _systemNoticeText(BuildContext context, TransactionEntity t) {
    final original = t.adoptedFromTag;
    if (original != null && !isRemovableTransferLeg(t)) {
      return context.l10n.bagliSatirNotu(
        _labels[original] ?? context.translateSystemTag(original),
      );
    }
    return systemNoticeText(context, t);
  }

  Widget _systemNotice(
    BuildContext context,
    ColorScheme scheme,
    TransactionEntity t,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: scheme.onSurfaceVariant.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _systemNoticeText(context, t),
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme scheme) => Divider(
        height: 1,
        thickness: 1,
        color: scheme.onSurface.withValues(alpha: 0.06),
      );

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
    Color? valueColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          valueWidget ??
              Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? scheme.onSurface,
                ),
              ),
        ],
      ),
    );
  }
}

/// İşleme iliştirilmiş fişin önizleme kartı. Dosya bu cihazda yoksa (geri
/// yüklenen yedek — binary taşınmaz) "görsel bu cihazda yok" gösterir.
class _ReceiptCard extends StatelessWidget {
  final String fileName;
  final Color accent;

  const _ReceiptCard({required this.fileName, required this.accent});

  Future<File?> _resolve() async {
    final f = await getIt<ReceiptStorageService>().fileFor(fileName);
    return await f.exists() ? f : null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<File?>(
      future: _resolve(),
      builder: (context, snap) {
        final file = snap.data;
        final missing =
            snap.connectionState == ConnectionState.done && file == null;
        return AppCard(
          accent: accent,
          padding: const EdgeInsets.all(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: file == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReceiptViewerPage(imageFile: file),
                      ),
                    ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: file != null
                        ? Image.file(
                            file,
                            fit: BoxFit.cover,
                            // 1600 px'lik fişi 56 dp'ye tam çözmesin; 2 kat
                            // pay yatay fişin `cover` ile bulanıklaşmaması için.
                            cacheWidth: (56 *
                                    2 *
                                    MediaQuery.devicePixelRatioOf(context))
                                .round(),
                            // Dosya var ama çözülemiyor (yarım kalmış kopya,
                            // bozuk görsel). İşleyici yokken kare boş kalıyor
                            // ve hata "yakalanmamış" diye raporlanıyordu.
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: scheme.onSurface.withValues(alpha: 0.06),
                              child: Icon(Icons.broken_image_rounded,
                                  color: scheme.onSurfaceVariant),
                            ),
                          )
                        : ColoredBox(
                            color: scheme.onSurface.withValues(alpha: 0.06),
                            child: Icon(Icons.image_not_supported_rounded,
                                color: scheme.onSurfaceVariant),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    missing
                        ? context.l10n.fisCihazdaYok
                        : context.l10n.fisGoruntule,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          missing ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                  ),
                ),
                if (file != null)
                  Icon(Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bir taksit grubunun satırları: sıra, tarih, tutar; bu sayfanın satırı
/// vurgulu, geçmiş taksitler soluk. Altta "Tüm taksitleri sil".
class _InstallmentGroupCard extends StatelessWidget {
  final TransactionEntity current;
  final List<TransactionEntity> group;
  final Color accent;
  final void Function(List<TransactionEntity> group) onDeleteAll;
  final void Function(List<TransactionEntity> group) onEditAll;

  const _InstallmentGroupCard({
    required this.current,
    required this.group,
    required this.accent,
    required this.onDeleteAll,
    required this.onEditAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = current.installmentCount ?? group.length;
    final today = DateTime.now();
    final todayEnd = DateTime(today.year, today.month, today.day + 1);
    final missing = count - group.length;

    return AppCard(
      key: const ValueKey('installment-group'),
      accent: accent,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.installmentSectionTitle(
                '${current.installmentNo ?? '?'}', '$count'),
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final g in group)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Opacity(
                opacity:
                    g.date.isBefore(todayEnd) && g.id != current.id ? 0.55 : 1,
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${g.installmentNo ?? '?'}/$count',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: g.id == current.id ? accent : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        g.id == current.id
                            ? '${AppFormatters.dateShort.format(g.date)} · '
                                '${l10n.installmentThisOne}'
                            : AppFormatters.dateShort.format(g.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    MoneyText(
                      amount: g.amount,
                      currency: context.activeWalletCurrency,
                      style: TextStyle(
                        fontWeight: g.id == current.id
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (missing > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.installmentMissingHint('$missing'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          // Wrap: iki eylem 360dp'de yan yana sığmayabilir.
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            children: [
              // Alışverişin toplamı/adı/kategorisi tek yerden: alttaki
              // "Düzenle" yalnız BU taksit satırını değiştirir.
              TextButton.icon(
                key: const ValueKey('installment-edit-all'),
                onPressed: () => onEditAll(group),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(l10n.installmentEditAll),
              ),
              if (group.length > 1)
                TextButton.icon(
                  key: const ValueKey('installment-delete-all'),
                  onPressed: () => onDeleteAll(group),
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: Text(l10n.installmentDeleteAll(group.length)),
                  style:
                      TextButton.styleFrom(foregroundColor: AppGradients.debt),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
