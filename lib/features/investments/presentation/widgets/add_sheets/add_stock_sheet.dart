import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/onboarding/onboarding_tour.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/investment_sheet_widgets.dart';
import 'package:cunehat/features/investments/presentation/widgets/goal_category.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class AddStockSheet extends StatefulWidget {
  final String walletId;
  final String userId;
  final InvestmentEntity? investmentToEdit;
  final Function(InvestmentEntity) onSave;

  const AddStockSheet({
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
      builder: (context) => AddStockSheet(
        walletId: walletId,
        userId: userId,
        onSave: onSave,
        investmentToEdit: investmentToEdit,
      ),
    );
  }

  @override
  State<AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<AddStockSheet> {
  static const _accent = Colors.blue;

  bool _isEditing = false;
  bool _isLoading = false;
  String? _error;
  String? _fetchedPriceMessage;
  Color _fetchedPriceColor = Colors.blue;

  /// Son başarılı fiyat sorgusunun para birimi; kayıtta saklanır ki
  /// sonraki yenilemelerde TL çevrimi bilinçli yapılabilsin.
  String? _fetchedCurrency;
  String? _selectedGoalCategory;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _currentValueController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _symbolController = TextEditingController();
  final FocusNode _symbolFocusNode = FocusNode();

  Color _selectedColor = Colors.blue;

  final List<Color> _colorOptions = [
    Colors.blue,
    Colors.indigo,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
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
        // Adet hassas kalır (kesirli lot); paradan farklı olarak 4 hane.
        _quantityController.text =
            formatAmountForInput(item.quantity!, decimalDigits: 4);
      }
      _selectedGoalCategory = item.goalCategory;
      _fetchedCurrency = item.currency;
      _selectedColor = item.color;
      _symbolController.text = item.symbol ?? '';
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
    _symbolController.dispose();
    _symbolFocusNode.dispose();
    super.dispose();
  }

  String _fmt(double v) => formatAmountForInput(v);

  // Para alanları kuruşa yuvarlanır; adet (quantity) hassas kalır.
  double? get _parsedAmount => parseMoneyInput(_amountController.text);
  double? get _parsedQuantity => parseAmountInput(_quantityController.text);
  double? get _parsedCurrentValue =>
      parseMoneyInput(_currentValueController.text);
  double? get _parsedTargetAmount =>
      parseMoneyInput(_targetAmountController.text);

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  /// Her tuş vuruşunda tetiklendiği için üst sınır kısa: yanıt gecikirse
  /// öneri listesi boş kalır, kullanıcı sembolü elle yazmaya devam eder.
  /// Paylaşılan (DI) client kullanılır — üst düzey `http.get` her çağrıda
  /// yeni bağlantı açıp kapatırdı.
  static const _searchTimeout = Duration(seconds: 8);

  Future<Iterable<String>> _searchStockSymbols(String query) async {
    if (query.length < 2) return [];
    try {
      final url = Uri.parse(
          'https://query2.finance.yahoo.com/v1/finance/search?q=$query');
      final response =
          await getIt<http.Client>().get(url).timeout(_searchTimeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quotes = data['quotes'] as List;
        return quotes
            .map((e) =>
                "${e['symbol']} - ${e['shortname'] ?? e['longname'] ?? ''}")
            .toList();
      }
    } catch (e) {
      debugPrint('Symbol search error: $e');
    }
    return [];
  }

  Future<void> _fetchLivePrice() async {
    final symbol = _symbolController.text.split(' - ')[0].trim().toUpperCase();
    if (symbol.isEmpty) {
      setState(() {
        _fetchedPriceMessage = context.l10n.sembolGirin;
        _fetchedPriceColor = Colors.red;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _fetchedPriceMessage = context.l10n.fiyatAliniyor;
      _fetchedPriceColor = Colors.blue;
    });

    final result = await getIt<GetLiveQuoteUseCase>()(
      symbol: symbol,
      type: InvestmentType.stock,
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
          _fetchedCurrency = quote.currency;
          _fetchedPriceMessage = quote.currency == 'TRY'
              ? context.l10n.guncelFiyatFormatTry(formatMoney(quote.priceTl))
              : context.l10n.guncelFiyatFormatForeign(
                  formatMoney(quote.price, currency: quote.currency),
                  formatMoney(quote.priceTl),
                );
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

    final symbol = _symbolController.text.isNotEmpty
        ? _symbolController.text.split(' - ')[0].trim().toUpperCase()
        : null;

    final investment = InvestmentEntity(
      id: widget.investmentToEdit?.id ?? UidGenerator.generateV7(),
      userId: widget.userId,
      walletId: widget.walletId,
      name: _nameController.text.trim().isEmpty
          ? context.l10n.hisseYatirimi
          : _nameController.text.trim(),
      amount: _parsedAmount!,
      currentValue: _parsedCurrentValue!,
      type: InvestmentType.stock,
      color: _selectedColor,
      dateAdded: widget.investmentToEdit?.dateAdded ?? DateTime.now(),
      symbol: symbol,
      returnRate: 0,
      targetAmount: _parsedTargetAmount,
      quantity: _parsedQuantity ?? widget.investmentToEdit?.quantity,
      goalCategory: _parsedTargetAmount != null ? _selectedGoalCategory : null,
      currency: _fetchedCurrency,
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
      keys: [OnboardingKeys.investmentAddForm],
      enabled: !_isEditing,
      child: _buildContent(context, surface, cs),
    );
  }

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
                  icon: Icons.trending_up_rounded,
                  title: _isEditing
                      ? context.l10n.hisseYatiriminiDuzenle
                      : context.l10n.yeniHisseEkle,
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
                          valueColor: Colors.indigo,
                          controller: _currentValueController,
                          onChanged: _clearError,
                        ),
                      ),
                      InvestmentHintCaption(context.l10n.mevcutDegerAciklama),
                      const SizedBox(height: 14),
                      // Toplam Maliyet: Mevcut Değer'in hemen altında durur ki
                      // "ne ödedim / bugün ne ediyor" yan yana okunabilsin.
                      InvestmentFilledField(
                        controller: _amountController,
                        hint: context.l10n.maliyetYatirilanAnaPara,
                        icon: Icons.payments_rounded,
                        accent: _accent,
                        onChanged: _clearError,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [AmountInputFormatter()],
                      ),
                      InvestmentHintCaption(context.l10n.toplamMaliyetAciklama),
                      const SizedBox(height: 20),
                      InvestmentSectionLabel(context.l10n.hisseSenediBul),
                      const SizedBox(height: 10),
                      _buildSymbolSearch(cs),
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
                        hint: context.l10n.hisseNotHint,
                        icon: Icons.notes_rounded,
                        accent: _accent,
                        onChanged: _clearError,
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
                        inputFormatters: [AmountInputFormatter()],
                      ),
                      if (_targetAmountController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        InvestmentSectionLabel(context.l10n.hedefKategorisi),
                        const SizedBox(height: 10),
                        GoalCategorySelector(
                          selectedKey: _selectedGoalCategory,
                          onChanged: (key) =>
                              setState(() => _selectedGoalCategory = key),
                          accentColor: Colors.blue.shade600,
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

  Widget _buildSymbolSearch(ColorScheme cs) {
    return RawAutocomplete<String>(
      textEditingController: _symbolController,
      focusNode: _symbolFocusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        return _searchStockSymbols(textEditingValue.text);
      },
      onSelected: (String selection) {
        _symbolController.text = selection;
        _nameController.text = selection.split(' - ').length > 1
            ? selection.split(' - ')[1]
            : selection;
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: context.l10n.hintSembolOrnAaplThyao,
            hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
            filled: true,
            fillColor: cs.onSurface.withValues(alpha: 0.04),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.blue, width: 1.6),
            ),
          ),
          onSubmitted: (String value) {
            onFieldSubmitted();
          },
        );
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(14),
            color: cs.surface,
            child: SizedBox(
              height: 200.0,
              width: MediaQuery.of(context).size.width - 40,
              child: ListView.separated(
                padding: const EdgeInsets.all(8.0),
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1, color: cs.onSurface.withValues(alpha: 0.1)),
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(option,
                        style: TextStyle(
                            color: cs.onSurface, fontWeight: FontWeight.w500)),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
