/// Düz bir defter satırını bir alan kaydına BAĞLAMA akışı ("benimseme"):
/// satır ikinci kez yazılmaz, seçilen kaydın nakit bacağı olur.
///
/// **Neden:** ekstreden gelen "MIDAS MENKUL −5.000" ya da "KREDI TAKSIT
/// −2.500" düz gider olarak defterde dururken aynı alım/ödeme modülüne de
/// girilince kuplaj ikinci bir hareket yazıyordu ve para iki kez düşüyordu.
/// Modüllerin ekleme sayfaları "Defterdeki işlem" seçeneğini zaten sunar; bu
/// akış aynı işi SATIRDAN başlatır — kullanıcının aklına gelen yer çoğu
/// zaman ekstreden gelen satırın kendisidir.
///
/// Birden çok özelliği (birikim, borç, cüzdan) birbirine bağlayan tek yer
/// burasıdır; özellikler birbirini tanımaz. Olaylar uygulama geneli
/// [InvestmentBloc] / [DebtBloc]'a gider ve SONUÇ burada bildirilir: kaydın
/// kendi sayfası (mesajı gösteren dinleyici) o an açık olmayabilir.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/core/services/transfer_service.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/repositories/debt_repository.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/debt_payment_dialog.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/ledger_transaction_picker.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/repositories/goal_repository.dart';
import 'package:cunehat/features/investments/domain/repositories/investment_repository.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/investment_notice_text.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_custom_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_gold_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_stock_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/contribute_sheet.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';

/// Satırın bağlanabileceği kayıt türü.
enum LinkTarget {
  newInvestment,
  investmentContribution,
  debtPayment,
  debtPrincipal,
  transfer,
}

/// Satır bağlanabilir mi: düz (sistem hareketi değil) ve kaydedilmiş. Sistem
/// satırı zaten bir kaydın malıdır.
bool canLinkTransaction(TransactionEntity t) => !t.isSystem && t.id != null;

/// Satırın yönüne göre sunulan hedefler: gider bir ALIM ya da ÖDEMEDİR,
/// gelir bir borç GİRİŞİ ya da başka cüzdandan gelen para.
List<LinkTarget> linkTargetsFor(TransactionEntity t) => t.isIncome
    ? const [LinkTarget.debtPrincipal, LinkTarget.transfer]
    : const [
        LinkTarget.newInvestment,
        LinkTarget.investmentContribution,
        LinkTarget.debtPayment,
        LinkTarget.transfer,
      ];

/// Transferin iki bacağı en çok bu kadar gün ayrı düşebilir (banka EFT'si
/// ertesi iş gününe, kart ödemesi karta bir iki gün sonra yansır).
const int kMaxTransferDayDistance = 3;

/// Karşı cüzdanda aynı para taşımasının ÖBÜR bacağı olabilecek düz satırlar,
/// en olası önce: ters yön, en çok [kMaxTransferDayDistance] gün uzak; aynı
/// birimde tutar kuruşu kuruşuna aynı (farklı birimde o günün kuru
/// bilinmediği için tutar karşılaştırılmaz). Saf fonksiyon.
List<TransactionEntity> transferCounterpartCandidates(
  Iterable<TransactionEntity> counterpartLedger, {
  required TransactionEntity leg,
  required bool sameCurrency,
}) {
  int day(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  final legDay = day(leg.date);
  return [
    for (final t in rankLedgerCandidates(
      counterpartLedger,
      isIncome: !leg.isIncome,
      amountHint: sameCurrency ? leg.amount : null,
      dateHint: leg.date,
    ))
      if ((day(t.date) - legDay).abs() <= kMaxTransferDayDistance &&
          (!sameCurrency || moneyEquals(t.amount, leg.amount)))
        t,
  ];
}

/// Akışın girişi: hedef seçtirilir, ardından o hedefin kendi sayfası satır
/// önceden seçili açılır.
Future<void> startLinkTransactionFlow(
  BuildContext context, {
  required TransactionEntity transaction,
  required String currency,
}) async {
  if (!canLinkTransaction(transaction)) return;
  final choice = await showModalBottomSheet<LinkChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        LinkTargetSheet(transaction: transaction, currency: currency),
  );
  if (choice == null || !context.mounted) return;
  switch (choice.target) {
    case LinkTarget.newInvestment:
      await _linkNewInvestment(
        context,
        transaction,
        currency,
        choice.investmentType ?? InvestmentType.custom,
      );
    case LinkTarget.investmentContribution:
      await _linkContribution(context, transaction, currency);
    case LinkTarget.debtPayment:
      await _linkDebtPayment(context, transaction, currency);
    case LinkTarget.debtPrincipal:
      await _linkDebtPrincipal(context, transaction, currency);
    case LinkTarget.transfer:
      await _linkTransfer(context, transaction);
  }
}

/// Hedef seçimi (yeni birikimde türüyle birlikte).
class LinkChoice {
  final LinkTarget target;
  final InvestmentType? investmentType;

  const LinkChoice(this.target, {this.investmentType});
}

// ─── Birikim ────────────────────────────────────────────────────────────────

Future<void> _linkNewInvestment(
  BuildContext context,
  TransactionEntity tx,
  String currency,
  InvestmentType type,
) async {
  final bloc = context.read<InvestmentBloc>();
  final l10n = context.l10n;
  final goals = await _goalsOf(tx);
  if (!context.mounted) return;

  void onSave(InvestmentEntity investment, CashSource cashSource) {
    _reportInvestmentOutcome(bloc, l10n);
    bloc.add(CreateInvestmentEvent(
      investment: investment,
      userId: tx.userId,
      walletId: tx.walletId,
      cashSource: cashSource,
    ));
  }

  switch (type) {
    case InvestmentType.gold:
      await AddGoldSheet.show(
        context,
        walletId: tx.walletId,
        userId: tx.userId,
        walletCurrency: currency,
        goals: goals,
        initialLedgerTransaction: tx,
        onSave: onSave,
      );
    case InvestmentType.stock:
      await AddStockSheet.show(
        context,
        walletId: tx.walletId,
        userId: tx.userId,
        walletCurrency: currency,
        goals: goals,
        initialLedgerTransaction: tx,
        onSave: onSave,
      );
    case InvestmentType.custom:
      await AddCustomSheet.show(
        context,
        walletId: tx.walletId,
        userId: tx.userId,
        walletCurrency: currency,
        goals: goals,
        initialLedgerTransaction: tx,
        onSave: onSave,
      );
  }
}

Future<void> _linkContribution(
  BuildContext context,
  TransactionEntity tx,
  String currency,
) async {
  final l10n = context.l10n;
  final investments = await _investmentsOf(tx);
  if (!context.mounted) return;
  final investment = await _choose<InvestmentEntity>(
    context,
    title: l10n.baglaBirikimSec,
    emptyText: l10n.baglaBirikimYok,
    items: investments,
    label: (i) => i.name,
    detail: (i) => formatMoney(i.currentValue, currency: currency),
  );
  if (investment == null || !context.mounted) return;

  final bloc = context.read<InvestmentBloc>();
  await ContributeSheet.show(
    context,
    investment: investment,
    walletCurrency: currency,
    initialLedgerTransaction: tx,
    onSave: (updated, cashSource) {
      _reportInvestmentOutcome(bloc, l10n);
      bloc.add(UpdateInvestmentEvent(
        investment: updated,
        userId: tx.userId,
        walletId: tx.walletId,
        // Birikim sayfasındaki katkıyla aynı kural: defteri yalnız İŞLENMİŞ
        // maliyetin değişimi ilgilendirir; para satırın gününde çıktı
        // (kullanıcı satırı sayfada kaldırdıysa bugün).
        prevAmount: investment.bookedCost,
        newAmount: updated.bookedCost,
        bookingDate: switch (cashSource) {
          AdoptedCashMovement(:final transaction) => transaction.date,
          _ => DateTime.now(),
        },
        cashSource: cashSource,
      ));
    },
  );
}

/// Sonucu dinlemeye olay gönderilmeden ÖNCE başlanır: sonuç, olayı gönderen
/// sayfa kapandıktan sonra gelir.
void _reportInvestmentOutcome(InvestmentBloc bloc, AppLocalizations l10n) {
  final watch = OutcomeWatch<InvestmentState>(
    bloc.stream,
    (s) => s is InvestmentActionSuccess || s is InvestmentError,
  );
  unawaited(watch.result.then((s) {
    switch (s) {
      case InvestmentActionSuccess(:final notice, :final cashOk):
        AppMessenger.success(
            investmentNoticeTextOf(l10n, notice, cashOk: cashOk));
      case InvestmentError(:final notice):
        AppMessenger.error(investmentNoticeTextOf(l10n, notice));
      default:
        break;
    }
  }));
}

Future<List<GoalEntity>> _goalsOf(TransactionEntity tx) async {
  try {
    return (await getIt<GoalRepository>()
            .getGoals(userId: tx.userId, walletId: tx.walletId))
        .getOrElse(() => const []);
  } catch (_) {
    // Hedef seçici yalnız kolaylık; okunamazsa "hedefsiz" açılır.
    return const [];
  }
}

Future<List<InvestmentEntity>> _investmentsOf(TransactionEntity tx) async {
  final list = (await getIt<InvestmentRepository>()
          .getInvestments(userId: tx.userId, walletId: tx.walletId))
      .getOrElse(() => const []);
  return [...list]..sort((a, b) => a.name.compareTo(b.name));
}

// ─── Borç ───────────────────────────────────────────────────────────────────

Future<void> _linkDebtPayment(
  BuildContext context,
  TransactionEntity tx,
  String currency,
) async {
  final l10n = context.l10n;
  final debts = await _openDebtsOf(tx);
  if (!context.mounted) return;
  final debt = await _choose<DebtEntity>(
    context,
    title: l10n.baglaBorcSec,
    emptyText: l10n.baglaBorcYok,
    items: debts,
    label: (d) => d.title.isNotEmpty ? d.title : d.counterparty,
    detail: (d) => d.counterparty,
  );
  if (debt == null || !context.mounted) return;

  final watch = _watchDebt(context.read<DebtBloc>());
  final sent = await DebtPaymentDialog.show(
    context,
    debt,
    currency: currency,
    initialLedgerTransaction: tx,
  );
  _reportDebtOutcome(watch, sent: sent == true);
}

Future<void> _linkDebtPrincipal(
  BuildContext context,
  TransactionEntity tx,
  String currency,
) async {
  final watch = _watchDebt(context.read<DebtBloc>());
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddEntrySheet(
      walletId: tx.walletId,
      userId: tx.userId,
      currency: currency,
      initialPrincipalTransaction: tx,
    ),
  );
  _reportDebtOutcome(watch, sent: sent == true);
}

OutcomeWatch<DebtState> _watchDebt(DebtBloc bloc) => OutcomeWatch<DebtState>(
      bloc.stream,
      (s) => s is DebtOperationSuccess || s is DebtError,
    );

void _reportDebtOutcome(OutcomeWatch<DebtState> watch, {required bool sent}) {
  if (!sent) {
    // Vazgeçildi: sonradan gelen ilgisiz bir borç sonucu burada
    // bildirilmesin.
    watch.cancel();
    return;
  }
  unawaited(watch.result.then((s) {
    switch (s) {
      case DebtOperationSuccess(:final message):
        AppMessenger.success(message);
      case DebtError(:final message):
        AppMessenger.error(message);
      default:
        break;
    }
  }));
}

Future<List<DebtEntity>> _openDebtsOf(TransactionEntity tx) async {
  final list = (await getIt<DebtRepository>().getDebtsByWalletId(tx.walletId))
      .getOrElse(() => const []);
  return [
    for (final d in list)
      if (!d.isPaid) d,
  ];
}

// ─── Transfer ───────────────────────────────────────────────────────────────

Future<void> _linkTransfer(BuildContext context, TransactionEntity tx) async {
  final l10n = context.l10n;
  final wallets = (await getIt<WalletRepository>().getWallets(tx.userId))
      .getOrElse(() => const []);
  if (!context.mounted) return;
  final own = wallets.where((w) => w.id == tx.walletId).firstOrNull;
  if (own == null) return;
  final counterpart = await _choose<WalletEntity>(
    context,
    title: l10n.baglaCuzdanSec,
    emptyText: l10n.baglaCuzdanYok,
    items: [
      for (final w in wallets)
        if (w.id != null && w.id != own.id) w,
    ],
    label: (w) => w.name,
    detail: (w) => formatMoney(w.balance, currency: w.currency),
  );
  if (counterpart == null || !context.mounted) return;

  final ledger = (await getIt<TransactionsRepository>().getTransactions(
    userId: tx.userId,
    walletId: counterpart.id!,
  ))
      .getOrElse(() => const []);
  if (!context.mounted) return;
  final candidates = transferCounterpartCandidates(
    ledger,
    leg: tx,
    sameCurrency: own.currency == counterpart.currency,
  );
  final pick = await showModalBottomSheet<_CounterpartPick>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CounterpartSheet(
      candidates: candidates,
      currency: counterpart.currency,
    ),
  );
  if (pick == null) return;

  final service = getIt<TransferService>();
  final existing = pick.existing;
  final TransferOutcome outcome;
  if (existing == null) {
    outcome = await service.adoptAsTransfer(
      transaction: tx,
      wallet: own,
      counterpart: counterpart,
    );
  } else {
    final outgoingIsTx = tx.isExpense;
    outcome = await service.adoptPair(
      outgoing: outgoingIsTx ? tx : existing,
      from: outgoingIsTx ? own : counterpart,
      incoming: outgoingIsTx ? existing : tx,
      to: outgoingIsTx ? counterpart : own,
    );
  }
  _reportTransferOutcome(service, outcome, l10n);
}

/// Çift kimliği olan bir transferi (bacaklarından [leg] ile) onay alıp
/// kaldırır: benimsenmiş bacaklar özgün hâline döner, yazılanlar silinir
/// (bkz. `TransferService.unlinkTransfer`).
Future<void> confirmAndRemoveTransfer(
  BuildContext context,
  TransactionEntity leg,
) async {
  final pairId = leg.linkedRecordId;
  if (pairId == null) return;
  final l10n = context.l10n;
  final confirmed = await ConfirmDialog.show(
    context,
    title: l10n.transferiKaldir,
    message: l10n.transferiKaldirOnay,
    confirmText: l10n.transferiKaldir,
    danger: true,
  );
  if (!confirmed) return;
  final ok = await getIt<TransferService>().unlinkTransfer(pairId);
  if (ok) {
    AppMessenger.success(l10n.transferKaldirildi);
  } else {
    AppMessenger.error(l10n.transferKaldirilamadi);
  }
}

void _reportTransferOutcome(
  TransferService service,
  TransferOutcome outcome,
  AppLocalizations l10n,
) {
  switch (outcome.result) {
    case TransferResult.success:
      AppMessenger.success(
        l10n.transferBaglandi,
        action: outcome.canUndo
            ? AppMessageAction(
                label: l10n.geriAl,
                onPressed: () async {
                  final ok = await service.undoTransfer(outcome);
                  if (ok) {
                    AppMessenger.success(l10n.transferGeriAlindi);
                  } else {
                    AppMessenger.error(l10n.transferGeriAlinamadi);
                  }
                },
              )
            : null,
      );
    case TransferResult.rateUnavailable:
      AppMessenger.error(l10n.transferKurYok);
    case TransferResult.adoptionFailed:
      AppMessenger.error(l10n.benimsemeYapilamadiMesaji);
    case TransferResult.failed:
      AppMessenger.error(l10n.transferBasarisiz);
    case TransferResult.refundFailed:
      AppMessenger.error(l10n.transferIadeBasarisiz);
  }
}

class _CounterpartPick {
  /// Karşı cüzdanda zaten duran bacak; `null` → karşı bacak yazılsın.
  final TransactionEntity? existing;
  const _CounterpartPick(this.existing);
}

class _CounterpartSheet extends StatelessWidget {
  final List<TransactionEntity> candidates;
  final String currency;

  const _CounterpartSheet({required this.candidates, required this.currency});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return _SheetFrame(
      title: l10n.baglaKarsiSatirBaslik,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            candidates.isEmpty
                ? l10n.baglaKarsiSatirAdayYok
                : l10n.baglaKarsiSatirAciklama,
            style: theme.textTheme.bodySmall,
          ),
        ),
        for (final t in candidates)
          LedgerTransactionTile(
            transaction: t,
            currency: currency,
            onTap: () => Navigator.of(context).pop(_CounterpartPick(t)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton.tonalIcon(
            onPressed: () =>
                Navigator.of(context).pop(const _CounterpartPick(null)),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.baglaKarsiSatirOlustur),
          ),
        ),
      ],
    );
  }
}

// ─── Ortak parçalar ─────────────────────────────────────────────────────────

/// Bir bloc akışında [isOutcome]'u sağlayan İLK durumu bekler; [timeout]
/// içinde gelmezse `null`. Dinleme oluşturulduğu AN başlar — olay
/// gönderilmeden önce kurulmalı.
class OutcomeWatch<S> {
  final _completer = Completer<S?>();
  late final StreamSubscription<S> _sub;
  late final Timer _timer;

  OutcomeWatch(
    Stream<S> stream,
    bool Function(S) isOutcome, {
    Duration timeout = const Duration(seconds: 20),
  }) {
    _sub = stream.listen((s) {
      if (isOutcome(s)) _finish(s);
    });
    _timer = Timer(timeout, () => _finish(null));
  }

  Future<S?> get result => _completer.future;

  void cancel() => _finish(null);

  void _finish(S? value) {
    _timer.cancel();
    _sub.cancel();
    if (!_completer.isCompleted) _completer.complete(value);
  }
}

Future<T?> _choose<T>(
  BuildContext context, {
  required String title,
  required String emptyText,
  required List<T> items,
  required String Function(T) label,
  String Function(T)? detail,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _SheetFrame(
      title: title,
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(emptyText, textAlign: TextAlign.center),
          ),
        for (final item in items)
          ListTile(
            title: Text(
              label(item),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: detail == null ? null : Text(detail(item)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(sheetContext).pop(item),
          ),
      ],
    ),
  );
}

/// Akıştaki alt sayfaların ortak kabuğu: başlık + kapat + kaydırılabilir
/// içerik, ekranın en çok %85'i.
class _SheetFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? leading;

  const _SheetFrame({
    required this.title,
    required this.children,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                child: Row(
                  children: [
                    if (leading != null) leading! else const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.iptal,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 8),
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hedef seçimi: satırın özeti, ne olacağının açıklaması ve yönüne uygun
/// hedefler. "Yeni birikim alımı" türü aynı sayfada sorar.
class LinkTargetSheet extends StatefulWidget {
  final TransactionEntity transaction;
  final String currency;

  const LinkTargetSheet({
    super.key,
    required this.transaction,
    required this.currency,
  });

  @override
  State<LinkTargetSheet> createState() => _LinkTargetSheetState();
}

class _LinkTargetSheetState extends State<LinkTargetSheet> {
  bool _pickingInvestmentType = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = widget.transaction;
    if (_pickingInvestmentType) {
      return _SheetFrame(
        title: l10n.baglaBirikimTuruSec,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _pickingInvestmentType = false),
        ),
        children: [
          _typeTile(Icons.workspace_premium_rounded, l10n.altinYatirimi,
              InvestmentType.gold),
          _typeTile(Icons.show_chart_rounded, l10n.hisseYatirimi,
              InvestmentType.stock),
          _typeTile(
              Icons.category_rounded, l10n.ozelYatirimi, InvestmentType.custom),
        ],
      );
    }
    final theme = Theme.of(context);
    return _SheetFrame(
      title: l10n.baglaBaslik,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            '“${t.title}” · ${t.isIncome ? '+' : '−'}'
            '${formatMoney(t.amount, currency: widget.currency)} · '
            '${AppFormatters.dateShort.format(t.date)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(l10n.baglaAciklama, style: theme.textTheme.bodySmall),
        ),
        for (final target in linkTargetsFor(t)) _targetTile(target),
      ],
    );
  }

  Widget _typeTile(IconData icon, String label, InvestmentType type) =>
      ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).pop(
          LinkChoice(LinkTarget.newInvestment, investmentType: type),
        ),
      );

  Widget _targetTile(LinkTarget target) {
    final l10n = context.l10n;
    final (icon, title, subtitle) = switch (target) {
      LinkTarget.newInvestment => (
          Icons.savings_rounded,
          l10n.baglaYeniBirikim,
          l10n.baglaYeniBirikimAciklama,
        ),
      LinkTarget.investmentContribution => (
          Icons.add_chart_rounded,
          l10n.baglaBirikimeKatki,
          l10n.baglaBirikimeKatkiAciklama,
        ),
      LinkTarget.debtPayment => (
          Icons.payments_rounded,
          l10n.baglaBorcOdemesi,
          l10n.baglaBorcOdemesiAciklama,
        ),
      LinkTarget.debtPrincipal => (
          Icons.account_balance_rounded,
          l10n.baglaBorcAnaparasi,
          l10n.baglaBorcAnaparasiAciklama,
        ),
      LinkTarget.transfer => widget.transaction.isIncome
          ? (
              Icons.swap_horiz_rounded,
              l10n.baglaTransferGiris,
              l10n.baglaTransferGirisAciklama,
            )
          : (
              Icons.swap_horiz_rounded,
              l10n.baglaTransferCikis,
              l10n.baglaTransferCikisAciklama,
            ),
    };
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        if (target == LinkTarget.newInvestment) {
          setState(() => _pickingInvestmentType = true);
          return;
        }
        Navigator.of(context).pop(LinkChoice(target));
      },
    );
  }
}
