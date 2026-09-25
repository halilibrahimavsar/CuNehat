import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/investments/domain/cash_pot_math.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:flutter/material.dart';

/// Birikimin NAKİT KASALARI ([InvestmentType.cash]) için arayüz parçaları:
/// kasa satırı, oluştur/düzenle sayfası, para ekle/çek sayfası, eylem menüsü
/// ve bunları bloc olaylarına çeviren yardımcılar.
///
/// Kasa ↔ cüzdan aktarımı mevcut yollardan geçer (yeni bir muhasebe yolu
/// yok): para ekleme = maliyet artışı (UpdateInvestmentEvent), çekme = kısmi
/// satış (PartialSellInvestmentEvent). Kasadan başka kasaya aktarım da kısmi
/// satışın bedelinin o kasaya girmesidir.

/// Kasaların varsayılan rengi (grafikte ve satırda).
const Color kCashPotColor = Color(0xFF26A69A);

/// Bir kayıt listesinden kasalar.
List<InvestmentEntity> cashPotsOf(Iterable<InvestmentEntity> investments) => [
      for (final i in investments)
        if (i.type == InvestmentType.cash) i,
    ];

// ============================================================ bloc yardımcıları

/// Yeni kasa aç. [initialGoalId] hedefin "varlık ekle"sinden gelinmişse.
Future<void> showCreateCashPot(
  BuildContext context, {
  required InvestmentBloc bloc,
  required String userId,
  required String walletId,
  required String currency,
  required List<GoalEntity> goals,
  String? initialGoalId,
}) async {
  final result = await CashPotFormSheet.show(
    context,
    goals: goals,
    currency: currency,
    initialGoalId: initialGoalId,
  );
  if (result == null) return;
  final initial = roundToCents(result.initialAmount);
  bloc.add(CreateInvestmentEvent(
    investment: InvestmentEntity(
      id: null,
      userId: userId,
      walletId: walletId,
      name: result.name,
      amount: initial,
      currentValue: initial,
      type: InvestmentType.cash,
      color: kCashPotColor,
      dateAdded: DateTime.now(),
      goalId: result.goalId,
    ),
    userId: userId,
    walletId: walletId,
    // Açılış bakiyesi cüzdandan gelir ("Birikime aktarım"); 0 ise hareket
    // yazılmaz.
    cashSource: const NewCashMovement(),
  ));
}

/// Kasanın adını / hedefini düzenle. Bakiye burada değişmez.
Future<void> showEditCashPot(
  BuildContext context, {
  required InvestmentBloc bloc,
  required InvestmentEntity pot,
  required String currency,
  required List<GoalEntity> goals,
}) async {
  final result = await CashPotFormSheet.show(
    context,
    goals: goals,
    currency: currency,
    potToEdit: pot,
  );
  if (result == null) return;
  final renamed = pot.copyWith(name: result.name);
  final updated = result.goalId == null
      ? renamed.clearGoal()
      : renamed.copyWith(goalId: result.goalId);
  bloc.add(UpdateInvestmentEvent(
    investment: updated,
    userId: pot.userId,
    walletId: pot.walletId,
    prevAmount: pot.bookedCost,
    newAmount: updated.bookedCost,
    bookingDate: pot.dateAdded,
  ));
}

/// Cüzdandan kasaya para koy.
Future<void> showDepositToPot(
  BuildContext context, {
  required InvestmentBloc bloc,
  required InvestmentEntity pot,
  required String currency,
}) async {
  final result = await CashPotMoveSheet.show(
    context,
    pot: pot,
    currency: currency,
    deposit: true,
  );
  if (result == null) return;
  final updated = putIntoPot(pot, result.amount, booked: result.amount);
  bloc.add(UpdateInvestmentEvent(
    investment: updated,
    userId: pot.userId,
    walletId: pot.walletId,
    prevAmount: pot.bookedCost,
    newAmount: updated.bookedCost,
    bookingDate: DateTime.now(),
    cashSource: const NewCashMovement(),
  ));
}

/// Kasadan cüzdana ya da başka bir kasaya para çek.
Future<void> showWithdrawFromPot(
  BuildContext context, {
  required InvestmentBloc bloc,
  required InvestmentEntity pot,
  required String currency,
  required List<InvestmentEntity> otherPots,
}) async {
  final result = await CashPotMoveSheet.show(
    context,
    pot: pot,
    currency: currency,
    deposit: false,
    otherPots: otherPots,
  );
  if (result == null) return;
  bloc.add(PartialSellInvestmentEvent(
    previous: pot,
    remaining: withdrawFromPot(pot, result.amount),
    proceeds: result.amount,
    userId: pot.userId,
    walletId: pot.walletId,
    targetPot: result.target,
  ));
}

// ================================================================ kasa satırı

/// Birikim sayfasındaki kasa satırı: ad, (varsa) hedef, bakiye ve iki hızlı
/// düğme. Satıra dokunmak eylem menüsünü açar.
class CashPotTile extends StatelessWidget {
  final InvestmentEntity pot;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;

  const CashPotTile({
    super.key,
    required this.pot,
    required this.currency,
    required this.onTap,
    required this.onDeposit,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Kayıt kendi cüzdanının biriminde (bkz. InvestmentCard notu).
    final money =
        MoneyWriter(currency: currency, visible: context.amountsVisible);
    return AppCard(
      section: AppSection.savings,
      padding: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('cash-pot-${pot.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kCashPotColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.savings_rounded,
                    color: kCashPotColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      money(pot.currentValue),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('cash-pot-deposit-${pot.id}'),
                tooltip: context.l10n.kasaParaEkle,
                onPressed: onDeposit,
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: kCashPotColor,
              ),
              IconButton(
                key: ValueKey('cash-pot-withdraw-${pot.id}'),
                tooltip: context.l10n.kasaParaCek,
                onPressed: pot.currentValue > 0 ? onWithdraw : null,
                icon: const Icon(Icons.north_east_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================== eylem menüsü

enum CashPotAction { deposit, withdraw, edit, close }

class CashPotActionSheet extends StatelessWidget {
  final InvestmentEntity pot;
  final String currency;

  const CashPotActionSheet({
    super.key,
    required this.pot,
    required this.currency,
  });

  static Future<CashPotAction?> show(
    BuildContext context, {
    required InvestmentEntity pot,
    required String currency,
  }) {
    return showModalBottomSheet<CashPotAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => CashPotActionSheet(pot: pot, currency: currency),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final money =
        MoneyWriter(currency: currency, visible: context.amountsVisible);
    Widget tile(CashPotAction action, IconData icon, String title,
            {String? subtitle, Color? color, bool enabled = true}) =>
        ListTile(
          key: ValueKey('cash-pot-action-${action.name}'),
          enabled: enabled,
          leading: Icon(icon, color: enabled ? color : null),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          onTap: () => Navigator.of(context).pop(action),
        );
    return Material(
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Handle(),
            ListTile(
              leading: const Icon(Icons.savings_rounded, color: kCashPotColor),
              title: Text(pot.name,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(l10n.kasaBakiyeSade(money(pot.currentValue))),
            ),
            const Divider(height: 1),
            tile(CashPotAction.deposit, Icons.add_circle_outline_rounded,
                l10n.kasaParaEkle,
                subtitle: l10n.kasaParaEkleAciklama, color: kCashPotColor),
            tile(CashPotAction.withdraw, Icons.north_east_rounded,
                l10n.kasaParaCek,
                subtitle: l10n.kasaParaCekAciklama,
                enabled: pot.currentValue > 0),
            tile(CashPotAction.edit, Icons.edit_rounded, l10n.kasaDuzenle),
            tile(CashPotAction.close, Icons.delete_outline_rounded,
                l10n.kasayiKapat,
                subtitle: pot.currentValue > 0
                    ? l10n.kasayiKapatAciklama(money(pot.currentValue))
                    : null,
                color: cs.error),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ====================================================== oluştur / düzenle

typedef CashPotFormResult = ({
  String name,
  String? goalId,
  double initialAmount
});

class CashPotFormSheet extends StatefulWidget {
  final List<GoalEntity> goals;
  final String currency;
  final InvestmentEntity? potToEdit;
  final String? initialGoalId;

  const CashPotFormSheet({
    super.key,
    required this.goals,
    required this.currency,
    this.potToEdit,
    this.initialGoalId,
  });

  static Future<CashPotFormResult?> show(
    BuildContext context, {
    required List<GoalEntity> goals,
    required String currency,
    InvestmentEntity? potToEdit,
    String? initialGoalId,
  }) {
    return showModalBottomSheet<CashPotFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CashPotFormSheet(
        goals: goals,
        currency: currency,
        potToEdit: potToEdit,
        initialGoalId: initialGoalId,
      ),
    );
  }

  @override
  State<CashPotFormSheet> createState() => _CashPotFormSheetState();
}

class _CashPotFormSheetState extends State<CashPotFormSheet> {
  late final _nameController =
      TextEditingController(text: widget.potToEdit?.name ?? '');
  final _amountController = TextEditingController();
  late String? _goalId =
      _validGoal(widget.potToEdit?.goalId ?? widget.initialGoalId);
  String? _error;

  bool get _isEdit => widget.potToEdit != null;

  /// Silinmiş bir hedefe işaret eden kimlik açılır listeyi kırar.
  String? _validGoal(String? id) =>
      widget.goals.any((g) => g.id == id) ? id : null;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.kasaAdiGerekli);
      return;
    }
    final text = _amountController.text.trim();
    final amount = text.isEmpty ? 0.0 : parseAmountInput(text);
    if (amount == null || amount < 0) {
      setState(() => _error = context.l10n.gecerliTutarGirin);
      return;
    }
    Navigator.of(context)
        .pop((name: name, goalId: _goalId, initialAmount: amount));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SheetFrame(
      title: _isEdit ? l10n.kasaDuzenle : l10n.yeniKasa,
      children: [
        if (!_isEdit)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(l10n.kasaAciklama,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        TextField(
          key: const ValueKey('cash-pot-name'),
          controller: _nameController,
          autofocus: !_isEdit,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.kasaAdi,
            hintText: l10n.kasaAdiOrnek,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
        if (!_isEdit) ...[
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('cash-pot-initial'),
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [AmountInputFormatter()],
            decoration: InputDecoration(
              labelText: l10n.kasaAcilisTutari,
              helperText: l10n.kasaAcilisTutariYardim,
              suffixText: widget.currency,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
        ],
        if (widget.goals.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            key: const ValueKey('cash-pot-goal'),
            initialValue: _goalId,
            decoration: InputDecoration(
              labelText: l10n.kasaHedefi,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<String?>(
                  value: null, child: Text(l10n.kasaHedefYok)),
              for (final g in widget.goals)
                DropdownMenuItem<String?>(value: g.id, child: Text(g.name)),
            ],
            onChanged: (v) => setState(() => _goalId = v),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 18),
        FilledButton(
          key: const ValueKey('cash-pot-save'),
          onPressed: _submit,
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: kCashPotColor),
          child: Text(_isEdit ? l10n.kaydet : l10n.kasaOlustur),
        ),
      ],
    );
  }
}

// ============================================================ para ekle / çek

typedef CashPotMoveResult = ({double amount, InvestmentEntity? target});

class CashPotMoveSheet extends StatefulWidget {
  final InvestmentEntity pot;
  final String currency;

  /// true → cüzdandan kasaya; false → kasadan cüzdana / başka kasaya.
  final bool deposit;
  final List<InvestmentEntity> otherPots;

  const CashPotMoveSheet({
    super.key,
    required this.pot,
    required this.currency,
    required this.deposit,
    this.otherPots = const [],
  });

  static Future<CashPotMoveResult?> show(
    BuildContext context, {
    required InvestmentEntity pot,
    required String currency,
    required bool deposit,
    List<InvestmentEntity> otherPots = const [],
  }) {
    return showModalBottomSheet<CashPotMoveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CashPotMoveSheet(
        pot: pot,
        currency: currency,
        deposit: deposit,
        otherPots: [
          for (final p in otherPots)
            if (p.id != pot.id) p,
        ],
      ),
    );
  }

  @override
  State<CashPotMoveSheet> createState() => _CashPotMoveSheetState();
}

class _CashPotMoveSheetState extends State<CashPotMoveSheet> {
  final _controller = TextEditingController();

  /// Çekişin hedefi; null → cüzdan (varsayılan: kasadan ÇEKMEK çoğunlukla
  /// harcamak için cüzdana almaktır).
  InvestmentEntity? _target;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final amount = parseAmountInput(_controller.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = l10n.gecerliTutarGirin);
      return;
    }
    if (!widget.deposit && amount > widget.pot.currentValue + 0.004) {
      setState(() => _error = l10n.kasaYetersizUyari(MoneyWriter(
          currency: widget.currency, visible: true)(widget.pot.currentValue)));
      return;
    }
    Navigator.of(context).pop((amount: roundToCents(amount), target: _target));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money =
        MoneyWriter(currency: widget.currency, visible: context.amountsVisible);
    final pot = widget.pot;
    return _SheetFrame(
      title: widget.deposit
          ? l10n.kasayaParaEkleBaslik(pot.name)
          : l10n.kasadanParaCekBaslik(pot.name),
      children: [
        Text(l10n.kasaBakiyeSade(money(pot.currentValue)),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('cash-pot-move-amount'),
                controller: _controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [AmountInputFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.kasaTutar,
                  suffixText: widget.currency,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            if (!widget.deposit) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() {
                  _controller.text = formatAmountForInput(pot.currentValue);
                  _error = null;
                }),
                child: Text(l10n.satTumunuSec),
              ),
            ],
          ],
        ),
        if (!widget.deposit && widget.otherPots.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.satisHedefiBaslik,
                  style: Theme.of(context).textTheme.labelMedium),
              ChoiceChip(
                key: const ValueKey('pot-move-to-wallet'),
                label: Text(l10n.satisHedefiCuzdan),
                selected: _target == null,
                onSelected: (_) => setState(() => _target = null),
              ),
              for (final p in widget.otherPots)
                ChoiceChip(
                  key: ValueKey('pot-move-to-${p.id}'),
                  label: Text(p.name),
                  selected: _target?.id == p.id,
                  onSelected: (_) => setState(() => _target = p),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Text(
          widget.deposit
              ? l10n.kasaParaEkleAciklama
              : _target == null
                  ? l10n.kasaParaCekAciklama
                  : l10n.kasalarArasiAciklama(_target!.name),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 18),
        FilledButton(
          key: const ValueKey('cash-pot-move-save'),
          onPressed: _submit,
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: kCashPotColor),
          child: Text(widget.deposit ? l10n.kasaParaEkle : l10n.kasaParaCek),
        ),
      ],
    );
  }
}

// ================================================================== ortak çerçeve

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

class _SheetFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SheetFrame({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: _Handle()),
                const SizedBox(height: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface)),
                const SizedBox(height: 10),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
