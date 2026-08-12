import 'dart:async';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/onboarding/onboarding_tour.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_starter_pack_sheet.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/shared/widgets/error_view.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_form_dialog.dart';
import 'package:cunehat/features/wallet/presentation/widgets/no_wallet_view.dart';
import 'package:cunehat/features/wallet/presentation/widgets/transfer_sheet.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_card_widget.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_info_dialog.dart';
import 'package:cunehat/features/wallet/presentation/widgets/wallet_quick_start_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

class WalletSheetContent extends StatefulWidget {
  final String userId;
  final ScrollController scrollController;

  const WalletSheetContent({
    super.key,
    required this.userId,
    required this.scrollController,
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

  @override
  Widget build(BuildContext context) {
    // Kendi route'u olan yüzey: turu kabuğun dönüşümüne değil, sheet'in
    // açılış animasyonunun bitmesine bağlıdır. (Eskiden kabuk "dönüşmüş"
    // sayıldığından bu tur hiç oynayamıyordu.)
    return OnboardingTour(
      flow: OnboardingFlow.walletManagement,
      keys: _tourKeys,
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
                  color: Colors.grey.shade200,
                ),

                // ========== BODY CONTENT ==========
                Expanded(
                  child: _buildBody(state),
                ),

                // ========== FLOATING ADD BUTTON ==========
                _buildFloatingAddButton(context),
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
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Header with title and actions
  Widget _buildHeader(BuildContext context, WalletState state) {
    return Showcase(
      key: OnboardingKeys.walletManagementHeader,
      title: context.l10n.onboardingWalletListTitle,
      description: context.l10n.onboardingWalletListDesc,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Simge + başlık
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).primaryColor,
                    size: 24,
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Döviz cüzdanı varsa ve tüm kurlar biliniyorsa TL toplamı;
                      // aksi halde standart alt başlık.
                      if (state is WalletLoadedSt &&
                          state.wallets
                              .any((w) => w.currency != kDefaultCurrency) &&
                          _tlTotal(state.wallets) != null)
                        Text(
                          context.l10n.toplamTlKarsilikFormat(
                              formatMoney(_tlTotal(state.wallets)!)),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        )
                      else
                        Text(
                          context.l10n.cuzdanlariniziYonetin,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                // Kapatma eylemi
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Eylem satırı
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openTransferSheet(context, state),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                    label: Text(
                      context.l10n.cuzdanlarArasiTransfer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade800,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.account_balance, size: 22),
                  tooltip: context.l10n.bankImportSettingsEntry,
                  onPressed: () => _openBankImport(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => WalletInfoDialog.show(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
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
      WalletLoadedSt() => _buildWalletList(state.wallets),
      WalletErrorSt() => Center(
          child: ErrorView(message: state.err),
        ),
      _ => Center(
          child: Text(context.l10n.beklenmeyenDurum),
        ),
    };
  }

  /// Wallet list
  Widget _buildWalletList(List<WalletEntity> wallets) {
    return ListView.builder(
      controller: widget.scrollController,
      padding:
          const EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding for FAB
      itemCount: wallets.length,
      itemBuilder: (context, index) {
        final wallet = wallets[index];
        return AnimatedScale(
          scale: 1.0,
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutCubic,
          child: WalletCardWidget(
            wallet: wallet,
            onTap: () => context.read<WalletBloc>().add(
                  SetActiveWalletEvent(
                    userId: widget.userId,
                    walletId: wallet.id!,
                  ),
                ),
            onEdit: () => _editWallet(context, wallet),
            onDelete: () => _deleteWallet(context, wallet),
          ),
        );
      },
    );
  }

  /// Floating add button (fixed at bottom)
  Widget _buildFloatingAddButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: Showcase(
            key: OnboardingKeys.walletManagementAddButton,
            title: context.l10n.onboardingWalletManagementTitle,
            description: context.l10n.onboardingWalletManagementDesc,
            child: ElevatedButton.icon(
              onPressed: () => _createWallet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add, size: 22),
              label: Text(
                context.l10n.yeniCuzdanOlustur,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
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
    // kategori zorunlu bir alandır. Yalnız hiç kategori yoksa gösterilir.
    final categories = await getIt<CategoryRepository>().getAllCategories();
    if (!context.mounted) return;
    if (categories.isEmpty) {
      await showCategoryStarterPack(context);
      if (!context.mounted) return;
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
