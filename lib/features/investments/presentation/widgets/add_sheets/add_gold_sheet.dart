import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/investment_sheet_widgets.dart';
import 'package:cunehat/features/investments/presentation/widgets/goal_category.dart';
import 'package:flutter/material.dart';

class AddGoldSheet extends StatefulWidget {
  final String walletId;
  final String userId;
  final InvestmentEntity? investmentToEdit;
  final Function(InvestmentEntity) onSave;

  const AddGoldSheet({
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
      builder: (context) => AddGoldSheet(
        walletId: walletId,
        userId: userId,
        onSave: onSave,
        investmentToEdit: investmentToEdit,
      ),
    );
  }

  @override
  State<AddGoldSheet> createState() => _AddGoldSheetState();
}

class _AddGoldSheetState extends State<AddGoldSheet> {
  static const _accent = Colors.amber;

  bool _isEditing = false;
  bool _isLoading = false;
  String? _error;
  String? _fetchedPriceMessage;
  Color _fetchedPriceColor = Colors.orange;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _targetAmountController = TextEditingController();

  String _selectedGoldType = 'gram-altin';
  String? _selectedGoalCategory;

  static const _goldTypeKeys = {
    'gram-altin',
    'ceyrek-altin',
    'yarim-altin',
    'tam-altin',
    'cumhuriyet-altini',
    'ata-altin',
  };

  Map<String, String> get _goldTypes => {
        'gram-altin': context.l10n.gramAltin,
        'ceyrek-altin': context.l10n.ceyrekAltin,
        'yarim-altin': context.l10n.yarimAltin,
        'tam-altin': context.l10n.tamAltin,
        'cumhuriyet-altini': context.l10n.cumhuriyetAltini,
        'ata-altin': context.l10n.ataAltin,
      };

  Color _selectedColor = Colors.amber;

  final List<Color> _colorOptions = [
    Colors.amber,
    Colors.orange,
    Colors.yellow.shade700,
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.teal,
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
      if (item.quantity != null) {
        _quantityController.text = _fmt(item.quantity!);
      }
      _selectedGoalCategory = item.goalCategory;
      _selectedColor = item.color;
      if (item.symbol != null && _goldTypeKeys.contains(item.symbol)) {
        _selectedGoldType = item.symbol!;
      }
    }
    // Kategori satırı hedef tutar girildiğinde görünür hale gelir.
    _targetAmountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _currentValueController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double? get _parsedAmount => parseAmount(_amountController.text);
  double? get _parsedQuantity => parseAmount(_quantityController.text);
  double? get _parsedCurrentValue => parseAmount(_currentValueController.text);
  double? get _parsedTargetAmount => parseAmount(_targetAmountController.text);

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _fetchLivePrice() async {
    setState(() {
      _isLoading = true;
      _fetchedPriceMessage = context.l10n.fiyatAliniyor;
      _fetchedPriceColor = Colors.orange;
    });

    final result = await getIt<GetLiveQuoteUseCase>()(
      symbol: _selectedGoldType,
      type: InvestmentType.gold,
    );
    // Sheet, yanıt gelmeden kapatılmış olabilir; unmounted setState
    // release'te çöker.
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _fetchedPriceMessage = context.l10n.fiyatAlinamadi;
        _fetchedPriceColor = Colors.red;
        _isLoading = false;
      }),
      (quote) {
        final qty = _parsedQuantity ?? 0.0;
        if (qty > 0) {
          final total = quote.priceTl * qty;
          _currentValueController.text = _fmt(total);
          if (_amountController.text.isEmpty) {
            _amountController.text = _fmt(total);
          }
        }
        setState(() {
          _fetchedPriceMessage =
              context.l10n.guncelFiyatFormatTry(_fmt(quote.priceTl));
          _fetchedPriceColor = Colors.green;
          _isLoading = false;
        });
      },
    );
  }

  String? _validate() {
    // if (_nameController.text.trim().isEmpty) return 'Lütfen bir isim girin';
    if (_parsedAmount == null) {
      return context.l10n.gecerliYatirimMiktariGirin;
    }
    if (_parsedCurrentValue == null) {
      return context.l10n.gecerliMevcutDegerGirin;
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
          ? context.l10n.altinYatirimi
          : _nameController.text.trim(),
      amount: _parsedAmount!,
      currentValue: _parsedCurrentValue!,
      type: InvestmentType.gold,
      color: _selectedColor,
      dateAdded: widget.investmentToEdit?.dateAdded ?? DateTime.now(),
      symbol: _selectedGoldType,
      returnRate: 0,
      targetAmount: _parsedTargetAmount,
      quantity: _parsedQuantity ?? widget.investmentToEdit?.quantity,
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
                  icon: Icons.monetization_on_rounded,
                  title: _isEditing
                      ? context.l10n.altinYatiriminiDuzenle
                      : context.l10n.yeniAltinEkle,
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
                        valueColor: Colors.orange,
                        controller: _currentValueController,
                        onChanged: _clearError,
                      ),
                      const SizedBox(height: 20),
                      InvestmentSectionLabel(
                          context.l10n.altinTuruVeOtomatikFiyat),
                      const SizedBox(height: 10),
                      _buildGoldTypeSelector(cs),
                      const SizedBox(height: 14),
                      InvestmentQuantityAndFetch(
                        accent: _accent,
                        quantityController: _quantityController,
                        onQuantityChanged: _clearError,
                        isLoading: _isLoading,
                        fetchedMessage: _fetchedPriceMessage,
                        fetchedColor: _fetchedPriceColor,
                        onFetch: _fetchLivePrice,
                      ),
                      const SizedBox(height: 20),
                      InvestmentSectionLabel(context.l10n.yatirimDetaylari),
                      const SizedBox(height: 10),
                      InvestmentFilledField(
                        controller: _nameController,
                        hint: context.l10n.altinNotHint,
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
                          accentColor: Colors.amber.shade700,
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

  Widget _buildGoldTypeSelector(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGoldType,
          isExpanded: true,
          dropdownColor: cs.surface,
          icon: Icon(Icons.arrow_drop_down_rounded, color: cs.onSurfaceVariant),
          items: _goldTypes.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text(
                e.value,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedGoldType = val);
          },
        ),
      ),
    );
  }
}
