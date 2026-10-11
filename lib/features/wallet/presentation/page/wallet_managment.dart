import 'dart:async';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_setup_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/credit_card_tile.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/onboarding/onboarding_tour.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/wallet_category_scope.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_starter_pack_sheet.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/shared/widgets/error_view.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_form_dialog.dart';
import 'package:cunehat/features/wallet/presentation/widgets/no_wallet_view.dart';
import 'package:cunehat/features/wallet/presentation/widgets/transfer_sheet.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_deck.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_info_dialog.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_quick_start_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/error/error_handling.dart';

class WalletSheetContent extends StatefulWidget {
  final String userId;
  final ScrollController scrollController;

  /// Sayfa açılır açılmaz "yeni cüzdan" formunu da aç. İlk cüzdanını kuracak
  /// kullanıcı için: eskiden "İlk Cüzdanı Oluştur" düğmesi BOŞ bir yönetim
  /// sayfası açıyor, kullanıcı orada bir de "Yeni Cüzdan Oluştur"a basıyordu.
  /// Form yine bu sayfanın üstünde açılır ki oluşturma sonrası zincir
  /// (kategori paketi → hızlı başlangıç) aynen işlesin.
  final bool createOnOpen;

  const WalletSheetContent({
    super.key,
    required this.userId,
    required this.scrollController,
    this.createOnOpen = false,
  });

  @override
  State<WalletSheetContent> createState() => _WalletSheetContentState();
}

class _WalletSheetContentState extends State<WalletSheetContent> {
  /// Hızlı başlangıç sheet'ine verilen bloc'lar (bkz.
  /// [_openFirstTransactionSheet]). İkisi de DI'da FACTORY olduğundan her
  /// çağrıda yeni örnek üretilir; bu yüzey onları SAHİPLENİR ve [dispose]'da
  /// kapatır.
  TransactionBloc? _quickStartTxBloc;
  PendingRecurringBloc? _quickStartPendingBloc;

  @override
  void dispose() {
    // close() edilmezlerse constructor'daki TransactionsChangedNotifier
    // aboneliği süreç boyu açık kalır ve sonraki her defter değişikliği
    // ölü bloc'lara da dağıtılır.
    _quickStartTxBloc?.close();
    _quickStartPendingBloc?.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final bloc = context.read<WalletBloc>();
    if (bloc.state is WalletInitialSt || bloc.state is WalletErrorSt) {
      bloc.add(WatchWalletsEvent(widget.userId));
    }
    // Kur tazeleme (sheet açılışında): döviz cüzdanlarının ≈₺ satırı ve
    // TL genel toplam güncel kurla gelsin. Tek çağrı tüm kurları alır;
    // hata sessizce bayat önbelleğe düşer.
    unawaited(getIt<ExchangeRateService>().rateToTry('USD').then((_) {
      if (mounted) setState(() {});
    }));
    if (widget.createOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _createWallet(context);
      });
    }
  }

  /// Tüm cüzdanların TL karşılığı toplamı; herhangi bir döviz cüzdanının
  /// kuru yoksa null (yanıltıcı eksik toplam göstermeyiz).
  double? _tlTotal(List<WalletEntity> wallets) {
    final fx = getIt<ExchangeRateService>();
    var total = 0.0;
    for (final w in wallets) {
      final rate = fx.cachedRateToTry(w.currency);
      if (rate == null) return null;
      total += w.balance * rate;
    }
    return total;
  }

  /// NET değer kırılımı (TL): hesaplar − kart borcu − kredi/kişisel borç +
  /// alacak (bkz. [netBreakdown]). Düşülecek bir şey yoksa ya da bir kur
  /// eksikse `null` (yanıltıcı eksik toplam göstermeyiz).
  ///
  /// Bayrağa bağlı DEĞİL: kredi ve alacak her sürümde var; kart kalemi
  /// yalnız kart varken yazılır.
  String? _netLine(BuildContext context, WalletState state) {
    if (state is! WalletLoadedSt) return null;
    final b = netBreakdown(state.wallets,
        rateToTry: getIt<ExchangeRateService>().cachedRateToTry);
    if (b == null) return null;
    final l10n = context.l10n;
    return [
      l10n.netWorthHead(formatMoney(b.net)),
      l10n.netPartAccounts(formatMoney(b.accounts)),
      if (moneyIsPositive(b.cardDebt))
        l10n.netPartCards(formatMoney(b.cardDebt)),
      if (moneyIsPositive(b.loans)) l10n.netPartLoans(formatMoney(b.loans)),
      if (moneyIsPositive(b.receivables))
        l10n.netPartReceivables(formatMoney(b.receivables)),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    // Kendi route'u olan yüzey: turu kabuğun dönüşümüne değil, sheet'in
    // açılış animasyonunun bitmesine bağlıdır. (Eskiden kabuk "dönüşmüş"
    // sayıldığından bu tur hiç oynayamıyordu.)
    return OnboardingTour(
      flow: OnboardingFlow.walletManagement,
      keys: _tourKeys,
      // Form açıkken tur oynamaz (overlay formun üstüne binerdi); bayrağı da
      // yazılmaz, sayfa bir sonraki açılışta — cüzdanlar varken — tanıtılır.
      enabled: !widget.createOnOpen,
      child: _buildContent(context),
    );
  }

  static final List<GlobalKey> _tourKeys = [
    OnboardingKeys.walletManagementHeader,
    OnboardingKeys.walletManagementAddButton,
  ];

  Widget _buildContent(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state is WalletLoadedSt) {
          if (state.messageType != null) {
            AppMessenger.success(
                _getLocalizedMessage(context, state.messageType!));
          }
          if (state.error != null) {
            AppMessenger.error(state.error!);
          }
        } else if (state is NoWalletSt) {
          if (state.messageType != null) {
            AppMessenger.success(
                _getLocalizedMessage(context, state.messageType!));
          }
          if (state.error != null) {
            AppMessenger.error(state.error!);
          }
        } else if (state is WalletErrorSt) {
          AppMessenger.error(state.err);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.9),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // ========== DRAG HANDLE ==========
                _buildDragHandle(),

                // ========== HEADER ==========
                _buildHeader(context, state),

                // ========== DIVIDER ==========
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),

                // ========== BODY CONTENT ==========
                Expanded(
                  child: _buildBody(state),
                ),

                // ========== GENEL EYLEMLER ==========
                _buildBottomBar(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Drag handle (sürükleme göstergesi)
  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Başlık: ad + net kırılım + bilgi/kapat. Genel eylemler (transfer,
  /// ekstre, yeni cüzdan) alttaki çubuktadır — başlık ne kadar kısaysa
  /// desteye o kadar yer kalır.
  Widget _buildHeader(BuildContext context, WalletState state) {
    final cs = Theme.of(context).colorScheme;
    final subtitleStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: cs.onSurfaceVariant,
    );
    return Showcase(
      key: OnboardingKeys.walletManagementHeader,
      title: context.l10n.onboardingWalletListTitle,
      description: context.l10n.onboardingWalletListDesc,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 8, 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: cs.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.cuzdanlarim,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // NET kırılım (hesaplar − kart borcu − krediler +
                  // alacaklar); döviz cüzdanı varsa ve tüm kurlar
                  // biliniyorsa TL toplamı; aksi halde standart alt başlık.
                  if (_netLine(context, state) case final line?)
                    Text(
                      line,
                      key: const ValueKey('wallet-net-breakdown'),
                      maxLines: 3,
                      style: subtitleStyle,
                    )
                  else if (state is WalletLoadedSt &&
                      state.wallets
                          .any((w) => w.currency != kDefaultCurrency) &&
                      _tlTotal(state.wallets) != null)
                    Text(
                      context.l10n.toplamTlKarsilikFormat(
                          formatMoney(_tlTotal(state.wallets)!)),
                      style: subtitleStyle,
                    )
                  else
                    Text(
                      context.l10n.cuzdanlariniziYonetin,
                      style:
                          subtitleStyle.copyWith(fontWeight: FontWeight.w400),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => WalletInfoDialog.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Body content based on state
  Widget _buildBody(WalletState state) {
    return switch (state) {
      NoWalletSt() => Center(
          child: NoWalletView(
            infoText: context.l10n.henuzCuzdanOlusturmadiniz,
            showButton: false,
          ),
        ),
      WalletLoadingSt() => const Center(
          child: CircularProgressIndicator(),
        ),
      WalletLoadedSt() => _buildWalletList(state),
      WalletErrorSt() => Center(
          child: ErrorView(message: state.err),
        ),
      _ => Center(
          child: Text(context.l10n.beklenmeyenDurum),
        ),
    };
  }

  /// Cüzdan destesi (bkz. [WalletDeck]).
  Widget _buildWalletList(WalletLoadedSt state) {
    final wallets = state.wallets;
    return WalletDeck(
      wallets: wallets,
      active: state.activeWallet,
      scrollController: widget.scrollController,
      showCards: FeatureFlags.creditCards,
      onSelect: _select,
      onEdit: (wallet) => _editWallet(context, wallet),
      onDelete: (wallet) => _deleteWallet(context, wallet),
      onAddCard: (owner) => CreditCardSetupSheet.show(
        context,
        userId: widget.userId,
        wallets: wallets,
        defaultCurrency: owner.currency,
        ownerWalletId: owner.id,
      ),
      onAttachCard: (card) => CreditCardSetupSheet.show(
        context,
        userId: widget.userId,
        wallets: wallets,
        wallet: card,
        defaultCurrency: card.currency,
      ),
      onCardDetails: (card) => CardDetailsSheet.show(context, card: card),
    );
  }

  /// Cüzdana (ya da karta) geç ve sayfayı kapat.
  ///
  /// Eskiden seçim sayfayı AÇIK bırakıyordu: kullanıcı cüzdanı seçtikten
  /// sonra bir de sayfayı kapatmak zorundaydı. Bildirim de yok
  /// (`announce: false`) — sayfa kapanınca üst çubuk zaten yeni cüzdanı
  /// gösterir.
  void _select(WalletEntity wallet) {
    final bloc = context.read<WalletBloc>();
    final state = bloc.state;
    final alreadyActive =
        state is WalletLoadedSt && state.activeWallet?.id == wallet.id;
    if (!alreadyActive && wallet.id != null) {
      bloc.add(SetActiveWalletEvent(
        userId: widget.userId,
        walletId: wallet.id!,
        announce: false,
      ));
    }
    Navigator.pop(context);
  }

  /// Sayfanın altındaki genel eylemler: bir cüzdana değil hepsine ait olanlar.
  Widget _buildBottomBar(BuildContext context, WalletState state) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _SheetAction(
                key: const ValueKey('wallet-sheet-transfer'),
                icon: Icons.swap_horiz_rounded,
                label: l10n.transferKisa,
                onTap: () => _openTransferSheet(context, state),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SheetAction(
                key: const ValueKey('wallet-sheet-import'),
                icon: Icons.account_balance_rounded,
                label: l10n.ekstreAktarKisa,
                onTap: () => _openBankImport(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Showcase(
                key: OnboardingKeys.walletManagementAddButton,
                title: l10n.onboardingWalletManagementTitle,
                description: l10n.onboardingWalletManagementDesc,
                child: _SheetAction(
                  key: const ValueKey('wallet-sheet-create'),
                  icon: Icons.add_rounded,
                  label: l10n.yeniCuzdanKisa,
                  primary: true,
                  onTap: () => _createWallet(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔧 HELPER METHODS
  // ========================================

  void _openTransferSheet(BuildContext context, WalletState state) {
    if (state is! WalletLoadedSt || state.wallets.length < 2) {
      AppMessenger.error(context.l10n.transferIcinIkiCuzdanGerekli);
      return;
    }
    TransferSheet.show(
      context,
      wallets: state.wallets,
      initialFrom: state.activeWallet ?? state.wallets.first,
    );
  }

  /// Sheet'i kapatıp banka ekstresi içe aktarma sayfasına yönlendirir.
  /// BankImportPage kendi cüzdan seçim adımına sahip (aktif cüzdanı
  /// varsayılan seçer), bu yüzden burada bir walletId iletmiyoruz.
  void _openBankImport(BuildContext context) {
    Navigator.of(context).pop();
    context.push(AppRoutes.bankStatementImport);
  }

  void _createWallet(BuildContext context) {
    showCreateEditDialog(
      context: context,
      userId: widget.userId,
      wallet: null,
      // Yeni cüzdan boş açılır ve kullanıcıya hiçbir yön göstermez; en çok
      // değer veren adım (ekstre içe aktarma) tam bu anda önerilir.
      onSuccess: (name) => _offerQuickStart(context, name),
      onError: (error) {},
    );
  }

  void _editWallet(BuildContext context, WalletEntity wallet) {
    showCreateEditDialog(
      context: context,
      userId: widget.userId,
      wallet: wallet,
      // Düzenlemede hızlı başlangıç YOK — cüzdan zaten kurulu.
      onSuccess: (_) {},
      onError: (error) {},
    );
  }

  /// Cüzdan oluşturulduktan sonraki atlanabilir yönlendirme.
  Future<void> _offerQuickStart(BuildContext context, String walletName) async {
    // Kategori kurulumu hızlı başlangıçtan ÖNCE gelir: hızlı başlangıcın iki
    // aksiyonu da (ekstre içe aktar / işlem ekle) kategori olmadan yürümez,
    // kategori zorunlu bir alandır.
    //
    // Kapı artık CÜZDAN BAZLI. Eskiden küresel `categories.isEmpty` idi:
    // ikinci cüzdanını kuran kullanıcıya paket hiç sorulmuyor, birincinin
    // tüm kalemleri sessizce devrediyordu. Yeni cüzdan boş kümeyle doğduğu
    // için paket ona yeniden önerilir; eski (kürasyonsuz) cüzdanlarda
    // davranış aynen korunur — onlar zaten hepsini görüyor.
    //
    // Cüzdan bloc state'inden DEĞİL depodan okunuyor: `onSuccess` cüzdan
    // yaratıldıktan hemen sonra tetikleniyor ve state'in yeni cüzdanı
    // içermesi garanti değil. `CreateWalletEvent` aktif cüzdanı yazmayı
    // bekliyor, dolayısıyla kutu güncel.
    final walletResult =
        await getIt<WalletRepository>().getActiveWallet(widget.userId);
    final wallet = walletResult.fold((_) => null, (w) => w);
    if (!context.mounted) return;

    if (wallet?.id != null) {
      final visible = wallet!.categoryIds;
      // Küresel liste yalnız kürasyonsuz cüzdanlar için gerekiyor; küratörlü
      // cüzdanda kararı kümenin kendisi veriyor (bkz. `needsCategorySetup`).
      var anyCategoryExists = true;
      if (visible == null) {
        try {
          anyCategoryExists =
              (await getIt<CategoryRepository>().getAllCategories()).isNotEmpty;
        } catch (e, st) {
          // Kategori deposu `Either` DEĞİL, EXCEPTION fırlatır; eskiden hata
          // hızlı başlangıç akışını yarıda kesiyordu. Okunamadıysa başlangıç
          // paketi ÖNERİLMEZ (varsayılan `true` kalır): var olan kategorilerin
          // üstüne ikinci bir paket kurmak, önermemekten kötü. Hızlı başlangıç
          // yine açılır.
          reportError('Cüzdan · kategori kontrolü', e, st);
        }
      }
      if (!context.mounted) return;
      if (needsCategorySetup(
        visibleIds: visible,
        anyCategoryExists: anyCategoryExists,
      )) {
        await showCategoryStarterPack(context, walletId: wallet.id!);
        if (!context.mounted) return;
      }
    }

    final action =
        await WalletQuickStartSheet.show(context, walletName: walletName);
    if (action == null || !context.mounted) return;

    switch (action) {
      case WalletQuickStartAction.importStatement:
        // BankImportPage aktif cüzdanı varsayılan seçer; CreateWalletEvent
        // yeni cüzdanı zaten aktif yaptığı için ek parametre gerekmez.
        _openBankImport(context);
      case WalletQuickStartAction.addTransaction:
        _openFirstTransactionSheet(context);
      case WalletQuickStartAction.skip:
        break;
    }
  }

  /// İlk işlem sheet'ini cüzdan yönetimi üstünde açar.
  ///
  /// Bu yüzey kendi route'unda olduğundan ağacında TransactionBloc yoktur;
  /// bloc'lar DI'dan açıkça verilir (bkz. [TransactionSheetHandler.showSheet]).
  ///
  /// Örnekler sheet route'una DEĞİL bu State'e bağlanır: kayıttan sonra düzenli
  /// işlem şablonu yazımı route kapandıktan SONRA tamamlanıp bekleyen listeye
  /// event gönderir; route'la birlikte kapatılan bir bloc o anda ölü olurdu.
  /// Tembel kurulur — kullanıcı hızlı başlangıcı hiç seçmezse hiç üretilmez.
  void _openFirstTransactionSheet(BuildContext context) {
    final state = context.read<WalletBloc>().state;
    final wallet = state is WalletLoadedSt ? state.activeWallet : null;
    if (wallet?.id == null) return;

    TransactionSheetHandler.showSheet(
      context: context,
      userId: widget.userId,
      walletId: wallet!.id!,
      type: TransactionTypeModel.expense,
      transactionBloc: _quickStartTxBloc ??= getIt<TransactionBloc>(),
      pendingBloc: _quickStartPendingBloc ??= getIt<PendingRecurringBloc>(),
    );
  }

  void _deleteWallet(BuildContext context, WalletEntity wallet) async {
    // Kartı olan cüzdan silinmez: kartlar yetim kalıp listede ayrı cüzdan
    // gibi belirirdi. Önce kartlar silinir (ya da başka cüzdana bağlanır).
    final state = context.read<WalletBloc>().state;
    if (state is WalletLoadedSt) {
      final cards = cardsOf(wallet.id, state.wallets);
      if (cards.isNotEmpty) {
        AppMessenger.info(
            context.l10n.kkCuzdanKartliSilinemez(wallet.name, cards.length));
        return;
      }
    }
    final step1 = await ConfirmDialog.show(
      context,
      title: context.l10n.deleteWalletTitle,
      message: context.l10n.deleteWalletConfirmMessage(wallet.name),
      confirmText: context.l10n.sil,
    );
    if (!step1 || !context.mounted) return;

    // Geri alınamaz eylem: ikinci onay + 5sn geri sayım kapılı.
    final step2 = await ConfirmDialog.show(
      context,
      title: context.l10n.irreversibleActionTitle,
      message: context.l10n.deleteWalletDangerMessage(wallet.name),
      confirmText: context.l10n.sil,
      danger: true,
      countdownSeconds: 5,
    );
    if (!step2 || !context.mounted) return;

    context.read<WalletBloc>().add(DeleteWalletEvent(wallet.id!));
  }

  String _getLocalizedMessage(BuildContext context, WalletMessageType type) {
    switch (type) {
      case WalletMessageType.created:
        return context.l10n.cuzdanOlusturuldu;
      case WalletMessageType.cardCreated:
        return context.l10n.kkKartEklendi;
      case WalletMessageType.updated:
        return context.l10n.cuzdanGuncellendi;
      case WalletMessageType.deleted:
        return context.l10n.cuzdanSilindi;
      case WalletMessageType.selected:
        return context.l10n.cuzdanSecildi;
      case WalletMessageType.createFailed:
        return context.l10n.cuzdanOlusturulamadi;
      case WalletMessageType.updateFailed:
        return context.l10n.beklenmeyenDurum; // Fallback
      case WalletMessageType.deleteFailed:
        return context.l10n.beklenmeyenDurum; // Fallback
      case WalletMessageType.selectFailed:
        return context.l10n.beklenmeyenDurum; // Fallback
      case WalletMessageType.activeSetFailed:
        return context.l10n.beklenmeyenDurum; // Fallback
    }
  }
}

/// Alt çubuktaki tek bir eylem: ikon üstte, etiket altta.
class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Sayfanın birincil eylemi (yeni cüzdan).
  final bool primary;

  const _SheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = primary ? cs.onPrimary : cs.onSurface;
    return Material(
      color: primary ? cs.primary : cs.onSurface.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fg,
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
