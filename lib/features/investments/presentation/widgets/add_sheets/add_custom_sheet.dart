import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/investment_sheet_widgets.dart';
import 'package:cunehat/features/investments/presentation/widgets/goal_category.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

class AddCustomSheet extends StatefulWidget {
  final String walletId;
  final String userId;
  final InvestmentEntity? investmentToEdit;
  final Function(InvestmentEntity) onSave;

  const AddCustomSheet({
    super.key,
    required this.walletId,
    required this.userId,
    required this.onSave,
    this.investmentToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required String walletId,
    required String userId,
    required Function(InvestmentEntity) onSave,
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
  final _targetAmountController = TextEditingController();

  Color _selectedColor = Colors.purple;
  String? _selectedGoalCategory;

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
      if (item.targetAmount != null) {
        _targetAmountController.text = _fmt(item.targetAmount!);
      }
      _selectedGoalCategory = item.goalCategory;
      _selectedColor = item.color;
    }
    // Kategori satırı hedef tutar girildiğinde görünür hale gelir.
    _targetAmountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _currentValueController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double? get _parsedAmount => parseAmount(_amountController.text);
  double? get _parsedCurrentValue => parseAmount(_currentValueController.text);
  double? get _parsedTargetAmount => parseAmount(_targetAmountController.text);

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  String? _validate() {
    // if (_nameController.text.trim().isEmpty) return 'Lütfen bir isim girin';
    if (_parsedAmount == null || _parsedAmount! <= 0) {
      return context.l10n.gecerliYatirimMiktariGirin;
    }
    if (_parsedCurrentValue == null || _parsedCurrentValue! < 0) {
      return context.l10n.gecerliMevcutDegerGirin;
    }
    if (_targetAmountController.text.trim().isNotEmpty &&
        (_parsedTargetAmount == null || _parsedTargetAmount! <= 0)) {
      return context.l10n.gecerliHedefTutarGirin;
    }
    return null;
  }

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
      dateAdded: widget.investmentToEdit?.dateAdded ?? DateTime.now(),
      symbol: null,
      returnRate: 0,
      targetAmount: _parsedTargetAmount,
      quantity: widget.investmentToEdit?.quantity,
      goalCategory: _parsedTargetAmount != null ? _selectedGoalCategory : null,
      currency: 'TRY',
    );

    widget.onSave(investment);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final surface =
        Theme.of(context).extension<AppSurface>() ?? AppSurface.light;
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
                      InvestmentAmountCard(
                        accent: _accent,
                        valueColor: Colors.deepPurple,
                        controller: _currentValueController,
                        onChanged: _clearError,
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
                      InvestmentFilledField(
                        controller: _amountController,
                        hint: context.l10n.maliyetYatirilanAnaPara,
                        icon: Icons.payments_rounded,
                        accent: _accent,
                        onChanged: _clearError,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 14),
                      InvestmentFilledField(
                        controller: _targetAmountController,
                        hint: context.l10n.hedefTutarIstegeBagli,
                        icon: Icons.flag_rounded,
                        accent: _accent,
                        onChanged: _clearError,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      if (_targetAmountController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        InvestmentSectionLabel(context.l10n.hedefKategorisi),
                        const SizedBox(height: 10),
                        GoalCategorySelector(
                          selectedKey: _selectedGoalCategory,
                          onChanged: (key) =>
                              setState(() => _selectedGoalCategory = key),
                          accentColor: Colors.purple.shade600,
                        ),
                      ],
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
}
