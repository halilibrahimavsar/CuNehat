import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/goal_progress.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/investment_notice_text.dart';
import 'package:cunehat/features/investments/presentation/widgets/contribute_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/goal_form_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/goal_group_card.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_action_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_card.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_type_chooser.dart';
import 'package:cunehat/features/investments/presentation/widgets/sell_investment_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/investment_chart.dart';
import 'package:cunehat/features/investments/presentation/widgets/summary_card.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_gold_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_stock_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_custom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/messaging/deletion_undo_message.dart';

class InvestmentMoneyPage extends StatefulWidget {
  final WalletEntity activeWallet;

  const InvestmentMoneyPage({super.key, required this.activeWallet});

  @override
  State<InvestmentMoneyPage> createState() => _InvestmentMoneyPageState();
}

class _InvestmentMoneyPageState extends State<InvestmentMoneyPage> {
  late ConfettiController _confettiController;

  /// Açık hedef grupları. Sayfa yeniden çizildiğinde (her katkı/fiyat
  /// yenilemesi listeyi tazeler) açık grup kapanmasın diye sayfada durur.
  final Set<String> _expandedGoals = {};

  /// Son yüklemede hedefine ULAŞMIŞ hedeflerin kimlikleri. Konfeti,
  /// bu kümeye YENİ bir kimlik eklendiğinde atılır — böylece kutlama
  /// yalnız eşiğin geçildiği anda olur, her yüklemede değil.
  Set<String>? _reachedGoalIds;

  /// Kayıt silme onayı: hatalı girişler için, alım gideri iade edilir.
  Future<bool> _confirmDelete(InvestmentEntity investment) {
    return ConfirmDialog.show(
      context,
      title: context.l10n.yatirimSilOnayBaslik(investment.name),
      message: context.l10n.hataliGirislerIcinAlim(
          formatMoney(investment.bookedCost, currency: _currency)),
      confirmText: context.l10n.kaydiSil,
      cancelText: context.l10n.vazgec,
      danger: true,
    );
  }

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadInvestments();
  }

  @override
  void didUpdateWidget(covariant InvestmentMoneyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeWallet.id != oldWidget.activeWallet.id) {
      // Cüzdan değişti: hedefler de değişti, açık gruplar ve ulaşılmış
      // hedef kümesi eski cüzdanındı.
      _expandedGoals.clear();
      _reachedGoalIds = null;
      _loadInvestments();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _loadInvestments() {
    context.read<InvestmentBloc>().add(GetInvestmentsEvent(
          userId: widget.activeWallet.userId,
          walletId: widget.activeWallet.id!,
        ));
  }

  /// Değerlemenin yapıldığı birim: cüzdanın kendi birimi.
  String get _currency => widget.activeWallet.currency;

  String get _userId => widget.activeWallet.userId;
  String get _walletId => widget.activeWallet.id!;

  /// Hedef listesi bloc durumundan okunur; sayfa ikinci bir kopya tutmaz.
  List<GoalEntity> get _currentGoals {
    final state = context.read<InvestmentBloc>().state;
    return state is InvestmentLoaded ? state.goals : const [];
  }

  // ======================================================== yatırım eylemleri

  /// Sat: nakit gelir işlenir; Kaydı Sil: alım gideri ters kayıtla iade.
  ///
  /// [proceeds] yalnız satışta anlamlıdır: cüzdana giren tutar kaydın (belki
  /// bayat) güncel değeri değil, satış sayfasında onaylanan tutardır.
  void _dispatchDelete(
    InvestmentEntity investment, {
    required bool sell,
    double? proceeds,
  }) {
    context.read<InvestmentBloc>().add(DeleteInvestmentEvent(
          id: investment.id!,
          userId: _userId,
          walletId: _walletId,
          // Yalnız cüzdandan gerçekten çıkmış kısım iade edilebilir.
          amount: investment.bookedCost,
          currentValue: proceeds ?? investment.currentValue,
          dateAdded: investment.dateAdded,
          recordSale: sell,
        ));
  }

  /// Satış: tamamı ya da bir kısmı.
  Future<void> _sell(InvestmentEntity investment) async {
    final request = await SellInvestmentSheet.show(
      context,
      investment: investment,
      walletCurrency: _currency,
    );
    if (request == null || !mounted) return;

    if (request.sellAll) {
      _dispatchDelete(investment, sell: true, proceeds: request.proceeds);
      return;
    }
    context.read<InvestmentBloc>().add(PartialSellInvestmentEvent(
          previous: investment,
          remaining: request.remaining!,
          proceeds: request.proceeds,
          userId: _userId,
          walletId: _walletId,
        ));
  }

  /// Katkı (miktar / tutar kipi) — muhasebe contribute_sheet'te.
  void _showContributeSheet(InvestmentEntity investment) {
    final bloc = context.read<InvestmentBloc>();
    final state = bloc.state;
    final goal = investment.goalId == null || state is! InvestmentLoaded
        ? null
        : state.goals.where((g) => g.id == investment.goalId).firstOrNull;

    ContributeSheet.show(
      context,
      investment: investment,
      walletCurrency: _currency,
      // Hedef satırı kaydın değil, bağlı olduğu HEDEFİN ilerlemesini gösterir.
      goalProgress: goal == null || state is! InvestmentLoaded
          ? null
          : GoalProgress.from(goal, state.investments),
      // Kaydınkinden farklı altın türü seçildiğinde katkı değil YENİ kayıt:
      // tek kayıtta iki tür karışırsa miktar da değer de anlamını yitirir.
      onCreateForGoldType: (goldType) => _showCreateSheet(
        InvestmentType.gold,
        goldType: goldType,
        goalId: investment.goalId,
      ),
      onSave: (updated) {
        bloc.add(UpdateInvestmentEvent(
          investment: updated,
          userId: _userId,
          walletId: _walletId,
          // Defteri yalnız İŞLENMİŞ maliyetin değişimi ilgilendirir:
          // "zaten bende" kısmı cüzdandan hiç çıkmadı.
          prevAmount: investment.bookedCost,
          newAmount: updated.bookedCost,
        ));
      },
    );
  }

  /// Yeni kayıt. [goalId] verilirse hedef ön seçili gelir (hedefin
  /// "varlık ekle" düğmesinden gelinmişse).
  void _showCreateSheet(
    InvestmentType type, {
    String? goldType,
    String? goalId,
  }) {
    final bloc = context.read<InvestmentBloc>();
    final goals = _currentGoals;
    void onSave(InvestmentEntity investment) {
      bloc.add(CreateInvestmentEvent(
        investment: investment,
        userId: _userId,
        walletId: _walletId,
      ));
    }

    switch (type) {
      case InvestmentType.gold:
        AddGoldSheet.show(
          context,
          userId: _userId,
          walletId: _walletId,
          walletCurrency: _currency,
          goals: goals,
          initialGoalId: goalId,
          initialGoldType: goldType,
          onSave: onSave,
        );
      case InvestmentType.stock:
        AddStockSheet.show(
          context,
          userId: _userId,
          walletId: _walletId,
          walletCurrency: _currency,
          goals: goals,
          initialGoalId: goalId,
          onSave: onSave,
        );
      case InvestmentType.custom:
        AddCustomSheet.show(
          context,
          userId: _userId,
          walletId: _walletId,
          walletCurrency: _currency,
          goals: goals,
          initialGoalId: goalId,
          onSave: onSave,
        );
    }
  }

  /// "Ne eklemek istersin?" — hedeften ya da boş durumdan gelinir.
  Future<void> _chooseTypeAndCreate({String? goalId}) async {
    final type = await InvestmentTypeChooser.show(context);
    if (type == null || !mounted) return;
    _showCreateSheet(type, goalId: goalId);
  }

  void _openEditSheet(InvestmentEntity item) {
    final goals = _currentGoals;
    void onSave(InvestmentEntity updatedInvestment) {
      context.read<InvestmentBloc>().add(UpdateInvestmentEvent(
            investment: updatedInvestment,
            userId: _userId,
            walletId: _walletId,
            prevAmount: item.bookedCost,
            newAmount: updatedInvestment.bookedCost,
          ));
    }

    switch (item.type) {
      case InvestmentType.gold:
        AddGoldSheet.show(
          context,
          userId: item.userId,
          walletId: item.walletId,
          walletCurrency: _currency,
          goals: goals,
          investmentToEdit: item,
          onSave: onSave,
        );
      case InvestmentType.stock:
        AddStockSheet.show(
          context,
          userId: item.userId,
          walletId: item.walletId,
          walletCurrency: _currency,
          goals: goals,
          investmentToEdit: item,
          onSave: onSave,
        );
      case InvestmentType.custom:
        AddCustomSheet.show(
          context,
          userId: item.userId,
          walletId: item.walletId,
          walletCurrency: _currency,
          goals: goals,
          investmentToEdit: item,
          onSave: onSave,
        );
    }
  }

  /// Karta dokunma: Sat / Sil / Düzenle / Katkı / Fiyat eylemleri.
  Future<void> _showActionSheet(InvestmentEntity investment) async {
    final action =
        await InvestmentActionSheet.show(context, investment: investment);
    if (action == null || !mounted) return;

    switch (action) {
      case InvestmentAction.contribute:
        _showContributeSheet(investment);
      case InvestmentAction.refreshPrice:
        context.read<InvestmentBloc>().add(RefreshPricesEvent(
              userId: _userId,
              walletId: _walletId,
              walletCurrency: _currency,
              investmentId: investment.id,
            ));
      case InvestmentAction.edit:
        _openEditSheet(investment);
      case InvestmentAction.sell:
        await _sell(investment);
      case InvestmentAction.delete:
        final confirmed = await _confirmDelete(investment);
        if (confirmed && mounted) {
          _dispatchDelete(investment, sell: false);
        }
    }
  }

  // =========================================================== hedef eylemleri

  void _showGoalForm({GoalEntity? goal}) {
    final bloc = context.read<InvestmentBloc>();
    GoalFormSheet.show(
      context,
      userId: _userId,
      walletId: _walletId,
      walletCurrency: _currency,
      goalToEdit: goal,
      onSave: (saved) => bloc.add(SaveGoalEvent(saved)),
    );
  }

  Future<void> _confirmDeleteGoal(GoalProgress progress) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: context.l10n.hedefSilOnayBaslik(progress.goal.name),
      message: context.l10n.hedefSilOnayMesaj(progress.members.length),
      confirmText: context.l10n.hedefiSil,
      cancelText: context.l10n.vazgec,
      danger: true,
    );
    if (!confirmed || !mounted) return;
    context.read<InvestmentBloc>().add(DeleteGoalEvent(progress.goal));
  }

  /// Hedefe ULAŞMA anını yakalar: küme büyüdüyse kutla. İlk yüklemede
  /// (referans kümesi yokken) kutlama yok — açılışta konfeti atmasın.
  void _celebrateNewlyReachedGoals(InvestmentLoaded state) {
    final reached = <String>{
      for (final p in buildGoalProgress(state.goals, state.investments))
        if (p.isReached) p.goal.id,
    };
    final previous = _reachedGoalIds;
    if (previous != null && reached.difference(previous).isNotEmpty) {
      _confettiController.play();
    }
    _reachedGoalIds = reached;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvestmentBloc, InvestmentState>(
      listener: (context, state) {
        if (state is InvestmentLoaded) {
          _celebrateNewlyReachedGoals(state);
        } else if (state is InvestmentActionSuccess) {
          showDeletionMessage(
            context,
            message: investmentNoticeText(context, state.notice,
                cashOk: state.cashOk),
            undo: state.undo,
            // Kısmi satış silme değil: geri alınınca "silme geri alındı"
            // demek kullanıcıyı yanıltıyordu.
            undoneMessage: state.notice is InvestmentPartiallySoldNotice
                ? context.l10n.kismiSatisGeriAlindi
                : null,
          );
          _loadInvestments();
        } else if (state is InvestmentError) {
          AppMessenger.error(investmentNoticeText(context, state.notice));
        }
      },
      builder: (context, investmentState) {
        final loaded =
            investmentState is InvestmentLoaded ? investmentState : null;
        final investments = loaded?.investments ?? const <InvestmentEntity>[];
        final goals = loaded?.goals ?? const <GoalEntity>[];
        final goalProgress = buildGoalProgress(goals, investments);
        final unassigned = unassignedInvestments(investments, goals);

        return Stack(
          children: [
            Scaffold(
              body: investmentState is InvestmentLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: investments.isEmpty && goals.isEmpty
                            ? _buildEmptyState(context)
                            : _buildContent(
                                context,
                                loaded: loaded,
                                investments: investments,
                                goalProgress: goalProgress,
                                unassigned: unassigned,
                              ),
                      ),
                    ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2, // downwards
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required InvestmentLoaded? loaded,
    required List<InvestmentEntity> investments,
    required List<GoalProgress> goalProgress,
    required List<InvestmentEntity> unassigned,
  }) {
    final canRefreshAny = investments.any((i) => i.canRefreshPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SummaryCard(
          totalInvestment: loaded?.totalAmount ?? 0.0,
          totalCurrentValue: loaded?.totalCurrentValue ?? 0.0,
          totalProfit: loaded?.totalProfit ?? 0.0,
          totalProfitPercentage: loaded?.totalProfitPercentage ?? 0.0,
          currency: _currency,
        ),
        const SizedBox(height: 20),
        if (investments.isNotEmpty) ...[
          InvestmentChart(investments: investments),
          const SizedBox(height: 20),
        ],
        _sectionHeader(
          context,
          title: context.l10n.hedeflerim,
          trailing: Row(
            children: [
              if (canRefreshAny)
                IconButton(
                  tooltip: context.l10n.tooltipFiyatlariGuncelle,
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      context.read<InvestmentBloc>().add(RefreshPricesEvent(
                            userId: _userId,
                            walletId: _walletId,
                            walletCurrency: _currency,
                          )),
                  icon: const Icon(Icons.refresh_rounded,
                      size: 20, color: Colors.teal),
                ),
              TextButton.icon(
                onPressed: () => _showGoalForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                // Kısa etiket: uzun hâli ("Yeni hedef oluştur") yenileme
                // ikonuyla birlikte başlık satırını taşırıyordu.
                label: Text(context.l10n.hedefEkleKisa),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (goalProgress.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              context.l10n.hedefYokAciklama,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...goalProgress.map(
            (progress) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GoalGroupCard(
                progress: progress,
                currency: _currency,
                expanded: _expandedGoals.contains(progress.goal.id),
                onToggle: () => setState(() {
                  if (!_expandedGoals.remove(progress.goal.id)) {
                    _expandedGoals.add(progress.goal.id);
                  }
                }),
                onMemberTap: _showActionSheet,
                onAddAsset: () =>
                    _chooseTypeAndCreate(goalId: progress.goal.id),
                onEdit: () => _showGoalForm(goal: progress.goal),
                onDelete: () => _confirmDeleteGoal(progress),
              ),
            ),
          ),
        if (unassigned.isNotEmpty) ...[
          const SizedBox(height: 10),
          _sectionHeader(
            context,
            title: context.l10n.bagsizVarliklar,
            trailing: Text(
              context.l10n.investmentsLengthYatirim(unassigned.length),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 10),
          ...unassigned.map(
            (investment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _showActionSheet(investment),
                child: InvestmentCard(
                  investment: investment,
                  currency: _currency,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required Widget trailing,
  }) {
    return Row(
      children: [
        // Başlık kısalabilir, eylemler kısalamaz: 360dp'de ikisi birlikte
        // satırı 20px taşırıyordu (ölçüldü).
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }

  /// Portföy boşken: sıfırlarla dolu özet kartı yerine ne yapılacağını
  /// söyleyen bir kart. Ekleme yolu yalnız alttaki kaydırmalı menüdeydi;
  /// yeni kullanıcı için görünmez bir kapıydı.
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: AppCard(
        section: AppSection.savings,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.savings_rounded,
                    size: 42, color: scheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.birikimBosBaslik,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.birikimBosAciklama,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _showGoalForm(),
              icon: const Icon(Icons.flag_rounded, size: 20),
              label: Text(context.l10n.yeniHedefOlustur),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _chooseTypeAndCreate(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(context.l10n.varlikEkle),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
