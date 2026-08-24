import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
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
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/investment_form_validation.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/investment_sheet_widgets.dart';
import 'package:cunehat/features/investments/presentation/widgets/gold_types.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class AddGoldSheet extends StatefulWidget {
  final String walletId;
  final String userId;
  final InvestmentEntity? investmentToEdit;
  final Function(InvestmentEntity) onSave;

  /// Cüzdanın birikim hedefleri — "hedefe bağla" seçicisini besler.
  final List<GoalEntity> goals;

  /// Yeni kayıt hedeften açıldıysa ön seçili hedef.
  final String? initialGoalId;

  /// Yeni kayıt açılırken ön seçili altın türü (ör. katkı sayfasından
  /// "çeyrek için ayrı kayıt aç" ile gelinmişse). Düzenlemede yok sayılır.
  final String? initialGoldType;

  /// Cüzdanın para birimi: maliyet ve güncel değer bu birimdedir, canlı fiyat
  /// da buna çevrilir (altın fiyatı kaynağında TL'dir).
  final String walletCurrency;

  const AddGoldSheet({
    super.key,
    required this.walletId,
    required this.userId,
    required this.onSave,
    required this.walletCurrency,
    this.goals = const [],
    this.initialGoalId,
    this.investmentToEdit,
    this.initialGoldType,
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
    String? initialGoldType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddGoldSheet(
        walletId: walletId,
        userId: userId,
        onSave: onSave,
        walletCurrency: walletCurrency,
        goals: goals,
        initialGoalId: initialGoalId,
        investmentToEdit: investmentToEdit,
        initialGoldType: initialGoldType,
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

  String _selectedGoldType = 'gram-altin';
  String? _goalId;

  /// Alım tarihi: kayıt açılırken seçilir, gider bu tarihe yazılır.
  DateTime _purchaseDate = DateTime.now();

  /// "Bu varlık zaten bende": maliyet cüzdandan düşülmez
  /// (bkz. `InvestmentEntity.unbookedCost`).
  bool _alreadyOwned = false;

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
      if (item.quantity != null) {
        // Adet hassas kalır (0,125 gr); paradan farklı olarak 4 hane.
        _quantityController.text =
            formatAmountForInput(item.quantity!, decimalDigits: 4);
      }
      _goalId = item.goalId;
      _selectedColor = item.color;
      _purchaseDate = item.dateAdded;
      if (item.symbol != null) {
        _selectedGoldType = item.symbol!;
      }
      _goalId = item.goalId;
    } else {
      _goalId = widget.initialGoalId;
      if (widget.initialGoldType != null) {
        _selectedGoldType = widget.initialGoldType!;
      }
    }
    // Alım özeti ("şu kadarı cüzdandan düşülecek") maliyetten türer.
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _currentValueController.dispose();
    super.dispose();
  }

  String _fmt(double v) => formatAmountForInput(v);

  // Para alanları kuruşa yuvarlanır; adet (quantity) hassas kalır.
  double? get _parsedAmount => parseMoneyInput(_amountController.text);
  double? get _parsedQuantity => parseAmountInput(_quantityController.text);
  double? get _parsedCurrentValue =>
      parseMoneyInput(_currentValueController.text);

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
      targetCurrency: widget.walletCurrency,
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
          final total = quote.convertedPrice * qty;
          _currentValueController.text = _fmt(total);
          if (_amountController.text.isEmpty) {
            _amountController.text = _fmt(total);
          }
        }
        setState(() {
          // Altın TL fiyatlı; TL dışı cüzdanda çevrilmiş fiyatın yanında
          // kaynak fiyat da gösterilir.
          _fetchedPriceMessage = quote.isSameCurrency
              ? context.l10n.guncelFiyatFormat(
                  formatMoney(quote.price, currency: quote.currency))
              : context.l10n.guncelFiyatFormatCevrimli(
                  formatMoney(quote.price, currency: quote.currency),
                  formatMoney(quote.convertedPrice,
                      currency: quote.targetCurrency),
                );
          _fetchedPriceColor = Colors.green;
          _isLoading = false;
        });
      },
    );
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
      // Adsız kayıt türüyle anılır ("Çeyrek Altın"); her altın kaydının
      // "Altın Yatırımı" olması ayrı türleri ayırt edilemez kılıyordu.
      name: _nameController.text.trim().isEmpty
          ? goldTypeLabel(context, _selectedGoldType)
          : _nameController.text.trim(),
      amount: _parsedAmount!,
      currentValue: _parsedCurrentValue!,
      type: InvestmentType.gold,
      color: _selectedColor,
      dateAdded: widget.investmentToEdit?.dateAdded ?? _purchaseDate,
      symbol: _selectedGoldType,
      returnRate: 0,
      // Alanın kendisi kaydın miktarıdır: boşaltılırsa miktar takibi
      // gerçekten kalkar. `?? eskiDeğer` kullanıcının silmesini yok sayıyordu.
      quantity: _parsedQuantity,
      goalId: _goalId,
      currency: 'TRY',
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

  /// Mevcut değer → toplam maliyet → miktar/otomatik fiyat.
  static final List<GlobalKey> _tourKeys = [
    OnboardingKeys.investmentAddForm,
    OnboardingKeys.investmentAddCost,
    OnboardingKeys.investmentAddQuantity,
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
                      Showcase(
                        key: OnboardingKeys.investmentAddForm,
                        title: context.l10n.onboardingInvestmentAddTitle,
                        description: context.l10n.onboardingInvestmentAddDesc,
                        child: InvestmentAmountCard(
                          accent: _accent,
                          valueColor: Colors.orange,
                          controller: _currentValueController,
                          onChanged: _clearError,
                          currency: widget.walletCurrency,
                        ),
                      ),
                      InvestmentHintCaption(context.l10n.mevcutDegerAciklama),
                      const SizedBox(height: 14),
                      // Toplam Maliyet: Mevcut Değer'in hemen altında durur.
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
                      InvestmentHintCaption(context.l10n.toplamMaliyetAciklama),
                      ...?_purchaseRowSlot(),
                      const SizedBox(height: 20),
                      InvestmentSectionLabel(
                          context.l10n.altinTuruVeOtomatikFiyat),
                      const SizedBox(height: 10),
                      _buildGoldTypeSelector(cs),
                      ...?_typeChangeWarningSlot(),
                      const SizedBox(height: 14),
                      Showcase(
                        key: OnboardingKeys.investmentAddQuantity,
                        title:
                            context.l10n.onboardingInvestmentAddQuantityTitle,
                        description:
                            context.l10n.onboardingInvestmentAddQuantityDesc,
                        child: InvestmentQuantityAndFetch(
                          accent: _accent,
                          unitLabel: goldTypeLabel(context, _selectedGoldType),
                          quantityController: _quantityController,
                          onQuantityChanged: _clearError,
                          isLoading: _isLoading,
                          fetchedMessage: _fetchedPriceMessage,
                          fetchedColor: _fetchedPriceColor,
                          onFetch: _fetchLivePrice,
                        ),
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
        // Aynı sorgu "Hesapla" düğmesininki: miktar × güncel fiyat →
        // mevcut değer. Geçmiş tarihli alımda kullanıcı bunu arıyor.
        onCalculateTodayValue: _isLoading ? null : _fetchLivePrice,
      ),
    ];
  }

  Widget _buildGoldTypeSelector(ColorScheme cs) {
    return GoldTypeDropdown(
      value: _selectedGoldType,
      onChanged: (val) => setState(() => _selectedGoldType = val),
    );
  }

  /// Uyarı varsa aralığıyla birlikte döner; yoksa null (satır hiç eklenmez).
  List<Widget>? _typeChangeWarningSlot() {
    final warning = _buildTypeChangeWarning();
    if (warning == null) return null;
    return [const SizedBox(height: 10), warning];
  }

  /// Düzenlemede tür değişirse kayıttaki miktar sessizce yeni türün miktarı
  /// sayılır (10 gram → 10 çeyrek) ve ilk fiyat yenilemesinde değer buna göre
  /// hesaplanır. Kullanıcı bunu görmeden kaydedemesin.
  Widget? _buildTypeChangeWarning() {
    final item = widget.investmentToEdit;
    if (!_isEditing || item == null) return null;
    final quantity = item.quantity;
    if (quantity == null || quantity <= 0) return null;
    if (item.symbol == _selectedGoldType) return null;
    return InvestmentWarningBanner(
      context.l10n.duzenlemeTurDegisikligiUyari(
        formatAmountForInput(quantity, decimalDigits: 4),
        goldTypeLabel(context, _selectedGoldType),
      ),
    );
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
