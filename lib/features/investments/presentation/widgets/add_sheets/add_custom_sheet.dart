import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/onboarding/onboarding_tour.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/investment_form_validation.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/investment_sheet_widgets.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

class AddCustomSheet extends StatefulWidget {
  final String walletId;
  final String userId;
  final InvestmentEntity? investmentToEdit;
  final Function(InvestmentEntity) onSave;

  /// Cüzdanın birikim hedefleri — "hedefe bağla" seçicisini besler.
  final List<GoalEntity> goals;

  /// Yeni kayıt hedeften açıldıysa ön seçili hedef.
  final String? initialGoalId;

  /// Cüzdanın para birimi: maliyet ve güncel değer bu birimdedir. Özel
  /// varlığın canlı fiyat kaynağı yoktur, değerler elle girilir.
  final String walletCurrency;

  const AddCustomSheet({
    super.key,
    required this.walletId,
    required this.userId,
    required this.onSave,
    required this.walletCurrency,
    this.goals = const [],
    this.initialGoalId,
    this.investmentToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required String walletId,
    required String userId,
    required Function(InvestmentEntity) onSave,
    required String walletCurrency,
    List<GoalEntity> goals = const [],
    String? initialGoalId,
    InvestmentEntity? investmentToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCustomSheet(
        walletId: walletId,
        userId: userId,
        onSave: onSave,
        walletCurrency: walletCurrency,
        goals: goals,
        initialGoalId: initialGoalId,
        investmentToEdit: investmentToEdit,
      ),
    );
  }

  @override
  State<AddCustomSheet> createState() => _AddCustomSheetState();
}

class _AddCustomSheetState extends State<AddCustomSheet> {
  static const _accent = Colors.purple;

  bool _isEditing = false;
  String? _error;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _currentValueController = TextEditingController();

  /// Alım tarihi: kayıt açılırken seçilir, gider bu tarihe yazılır.
  DateTime _purchaseDate = DateTime.now();

  /// "Bu varlık zaten bende": maliyet cüzdandan düşülmez
  /// (bkz. `InvestmentEntity.unbookedCost`).
  bool _alreadyOwned = false;

  Color _selectedColor = Colors.purple;
  String? _goalId;

  final List<Color> _colorOptions = [
    Colors.purple,
    Colors.deepPurple,
    Colors.pink,
    Colors.red,
    Colors.orange,
    Colors.teal,
    Colors.cyan,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.investmentToEdit != null) {
      _isEditing = true;
      final item = widget.investmentToEdit!;
      _nameController.text = item.name;
      _amountController.text = _fmt(item.amount);
      _currentValueController.text = _fmt(item.currentValue);
      _goalId = item.goalId;
      _selectedColor = item.color;
      _purchaseDate = item.dateAdded;
    }
    // Alım özeti ("şu kadarı cüzdandan düşülecek") maliyetten türer.
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _currentValueController.dispose();
    super.dispose();
  }

  String _fmt(double v) => formatAmountForInput(v);

  double? get _parsedAmount => parseMoneyInput(_amountController.text);
  double? get _parsedCurrentValue =>
      parseMoneyInput(_currentValueController.text);

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  String? _validate() => validateInvestmentForm(
        context,
        cost: _parsedAmount,
        currentValue: _parsedCurrentValue,
      );

  void _save() {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    FocusScope.of(context).unfocus();

    final investment = InvestmentEntity(
      id: widget.investmentToEdit?.id ?? UidGenerator.generateV7(),
      userId: widget.userId,
      walletId: widget.walletId,
      name: _nameController.text.trim().isEmpty
          ? context.l10n.ozelYatirimi
          : _nameController.text.trim(),
      amount: _parsedAmount!,
      currentValue: _parsedCurrentValue!,
      type: InvestmentType.custom,
      color: _selectedColor,
      dateAdded: widget.investmentToEdit?.dateAdded ?? _purchaseDate,
      symbol: null,
      returnRate: 0,
      quantity: widget.investmentToEdit?.quantity,
      goalId: _goalId,
      // Özel varlığın canlı fiyat kaynağı yok; `currency` fiyat KAYNAĞININ
      // birimidir, değerleme birimi cüzdandan gelir → boş bırakılır.
      currency: null,
      // "Zaten bende" seçilirse maliyetin tamamı deftere işlenmez; sonraki
      // katkılar (ödenen tutar) normal şekilde cüzdandan düşer.
      unbookedCost: _resolveUnbookedCost(_parsedAmount ?? 0.0),
    );

    widget.onSave(investment);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final surface =
        Theme.of(context).extension<AppSurface>() ?? AppSurface.light;
    final cs = Theme.of(context).colorScheme;

    return OnboardingTour(
      flow: OnboardingFlow.investmentAdd,
      keys: _tourKeys,
      enabled: !_isEditing,
      child: _buildContent(context, surface, cs),
    );
  }

  /// Mevcut değer → toplam maliyet. Özel yatırımda miktar alanı olmadığı için
  /// üçüncü adım yok; akış bayrağı üç sheet'te ortaktır, adım listesi değil.
  static final List<GlobalKey> _tourKeys = [
    OnboardingKeys.investmentAddForm,
    OnboardingKeys.investmentAddCost,
  ];

  Widget _buildContent(
      BuildContext context, AppSurface surface, ColorScheme cs) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InvestmentSheetHeader(
                  accent: _accent,
                  icon: Icons.account_balance_wallet_rounded,
                  title: _isEditing
                      ? context.l10n.ozelYatiriminiDuzenle
                      : context.l10n.yeniOzelYatirimEkle,
                  onClose: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Showcase(
                        key: OnboardingKeys.investmentAddForm,
                        title: context.l10n.onboardingInvestmentAddTitle,
                        description: context.l10n.onboardingInvestmentAddDesc,
                        child: InvestmentAmountCard(
                          accent: _accent,
                          valueColor: Colors.deepPurple,
                          controller: _currentValueController,
                          onChanged: _clearError,
                          currency: widget.walletCurrency,
                        ),
                      ),
                      const SizedBox(height: 20),
                      InvestmentSectionLabel(context.l10n.yatirimDetaylari),
                      const SizedBox(height: 10),
                      InvestmentFilledField(
                        controller: _nameController,
                        hint: context.l10n.customNotHint,
                        icon: Icons.notes_rounded,
                        accent: _accent,
                        onChanged: _clearError,
                      ),
                      const SizedBox(height: 14),
                      Showcase(
                        key: OnboardingKeys.investmentAddCost,
                        title: context.l10n.onboardingInvestmentAddCostTitle,
                        description:
                            context.l10n.onboardingInvestmentAddCostDesc,
                        child: InvestmentFilledField(
                          controller: _amountController,
                          hint: context.l10n.maliyetYatirilanAnaPara,
                          icon: Icons.payments_rounded,
                          accent: _accent,
                          onChanged: _clearError,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [AmountInputFormatter()],
                        ),
                      ),
                      ...?_purchaseRowSlot(),
                      const SizedBox(height: 14),
                      InvestmentSectionLabel(context.l10n.hedefAlaniEtiketi),
                      const SizedBox(height: 10),
                      InvestmentGoalPicker(
                        goals: widget.goals,
                        selectedGoalId: _goalId,
                        accent: _accent,
                        walletCurrency: widget.walletCurrency,
                        onChanged: (id) => setState(() => _goalId = id),
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 14),
                        const InvestmentCostEditWarning(),
                      ],
                      const SizedBox(height: 20),
                      InvestmentSectionLabel(context.l10n.renkSecimi),
                      const SizedBox(height: 10),
                      InvestmentColorSelector(
                        options: _colorOptions,
                        selected: _selectedColor,
                        onSelected: (c) => setState(() => _selectedColor = c),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        InvestmentErrorBanner(_error!),
                      ],
                      const SizedBox(height: 22),
                      InvestmentSaveButton(
                        accent: _accent,
                        radius: surface.radius,
                        isEditing: _isEditing,
                        onSave: _save,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Alım tarihi + "zaten bende" satırı yalnız YENİ kayıtta gösterilir:
  /// düzenlemede alım defterde çoktan yazılı, tarihi geriye almak o kaydı
  /// bulup taşımaz — sessizce tutarsızlık üretirdi.
  List<Widget>? _purchaseRowSlot() {
    if (_isEditing) return null;
    final cost = _parsedAmount;
    return [
      const SizedBox(height: 14),
      InvestmentPurchaseRow(
        accent: _accent,
        date: _purchaseDate,
        onDateChanged: (d) => setState(() => _purchaseDate = d),
        alreadyOwned: _alreadyOwned,
        onAlreadyOwnedChanged: (v) => setState(() => _alreadyOwned = v),
        costText: (cost == null || cost <= 0)
            ? null
            : formatMoney(cost, currency: widget.walletCurrency),
      ),
    ];
  }

  /// Kaydın deftere işlenmemiş maliyeti.
  ///
  /// Yeni kayıtta "zaten bende" anahtarının kendisi. DÜZENLEMEDE: kayıt
  /// tamamen işlenmemişse (uygulamadan önce alınmış) maliyet değişse de öyle
  /// kalır — o para uygulamadan önce çıktığı için farkı bugün cüzdana
  /// yazmak hayali gelir/gider üretirdi. Kısmen işlenmiş kayıtta işlenmemiş
  /// kısım sabit tutulur, fark defteri etkiler.
  double _resolveUnbookedCost(double cost) {
    final item = widget.investmentToEdit;
    if (item == null) return _alreadyOwned ? cost : 0.0;
    if (item.amount > 0 && item.unbookedCost >= item.amount) return cost;
    return item.unbookedCost > cost ? cost : item.unbookedCost;
  }
}
