// ignore_for_file: deprecated_member_use

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// **Cüzdan Oluşturma/Düzenleme Sayfasını Göster**
///
/// [wallet] null ise → Yeni Cüzdan Oluştur
/// [wallet] dolu ise → Mevcut Cüzdanı Düzenle
///
/// İşlem/borç ekleme sheet'leriyle aynı tema-duyarlı dil: alttan açılan,
/// accent'li (cüzdan rengi) modern bottom sheet.
Future<void> showCreateEditDialog({
  required BuildContext context,
  required String userId,
  WalletEntity? wallet,
  required VoidCallback onSuccess,
  required Function(String error) onError,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<WalletBloc>(),
      child: _WalletFormDialog(
        userId: userId,
        wallet: wallet,
        onSuccess: onSuccess,
        onError: onError,
      ),
    ),
  );
}

/// **Cüzdan Form Sheet Widget**
class _WalletFormDialog extends StatefulWidget {
  final String userId;
  final WalletEntity? wallet;
  final VoidCallback onSuccess;
  final Function(String error) onError;

  const _WalletFormDialog({
    required this.userId,
    this.wallet,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_WalletFormDialog> createState() => _WalletFormDialogState();
}

class _WalletFormDialogState extends State<_WalletFormDialog> {
  // ========== CONTROLLERS ==========
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  final _formKey = GlobalKey<FormState>();

  // ========== STATE ==========
  late String _selectedColorHex;
  late String _selectedIconName;
  late String _selectedCurrency;

  /// Düzenlemede birim kilidi: işlem geçmişi ya da türetilmiş metrik varsa
  /// birim değiştirilemez (geçmiş tutarların anlamı bozulur). Kontrol asenkron
  /// tamamlanana dek kilitli kalır (güvenli varsayılan).
  bool _currencyLocked = false;
  bool _isLoading = false;

  // ========== GETTERS ==========
  bool get isEditMode => widget.wallet != null;

  /// Seçili cüzdan rengi = form accent'i (başlık, alanlar, buton canlı önizleme).
  Color get _accent => WalletColors.hexToColor(_selectedColorHex);

  /// Seçili renk preset'lerden biri değilse "özel renk" aktiftir.
  bool get _isCustomColor => !WalletColors.presetColors
      .any((c) => WalletColors.colorToHex(c) == _selectedColorHex);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeState();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.wallet?.name ?? '');
    _balanceController = TextEditingController(
      text: widget.wallet?.balance.toStringAsFixed(2) ?? '0.00',
    );
  }

  void _initializeState() {
    _selectedColorHex = widget.wallet?.colorHex ?? '0xFF2196F3';
    _selectedIconName = widget.wallet?.iconName ?? 'wallet';
    _selectedCurrency = widget.wallet?.currency ?? kDefaultCurrency;
    if (isEditMode) {
      _currencyLocked = true;
      _resolveCurrencyLock();
    }
  }

  /// Boş cüzdanda (işlem yok + metrikler sıfır) birim serbestçe değişebilir.
  /// Metrik kontrolü, işlemi silinmiş ama borcu kalmış kenar durumunu da yakalar.
  Future<void> _resolveCurrencyLock() async {
    final w = widget.wallet!;
    final hasMetrics = !moneyEquals(w.debt, 0) ||
        !moneyEquals(w.credit, 0) ||
        !moneyEquals(w.investment, 0);
    if (hasMetrics || w.id == null) return; // kilitli kalır

    final result = await getIt<TransactionsRepository>()
        .getTransactions(userId: w.userId, walletId: w.id!);
    if (!mounted) return;
    result.fold(
      (_) {}, // okunamadıysa güvenli taraf: kilitli kal
      (txs) {
        if (txs.isEmpty) setState(() => _currencyLocked = false);
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  // ========== UI BUILD ==========
  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: _handleBlocState,
      child: _buildSheet(context),
    );
  }

  Widget _buildSheet(BuildContext context) {
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHandleAndHeader(cs),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNameField(cs),
                        const SizedBox(height: 14),
                        _buildBalanceField(cs),
                        const SizedBox(height: 20),
                        _sectionLabel(context.l10n.paraBirimiLabel, cs),
                        const SizedBox(height: 12),
                        _buildCurrencyPicker(cs),
                        if (isEditMode) ...[
                          const SizedBox(height: 18),
                          _buildDerivedMetricsSummary(cs),
                        ],
                        const SizedBox(height: 20),
                        _sectionLabel(context.l10n.renkSecin, cs),
                        const SizedBox(height: 12),
                        _buildColorPicker(cs),
                        const SizedBox(height: 20),
                        _sectionLabel(context.l10n.ikonSecin2, cs),
                        const SizedBox(height: 12),
                        _buildIconPicker(cs),
                        const SizedBox(height: 24),
                        _buildSaveButton(surface.radius),
                        const SizedBox(height: 4),
                        _buildCancelButton(cs),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Header

  Widget _buildHandleAndHeader(ColorScheme cs) {
    final title = isEditMode
        ? context.l10n.cuzdanDuzenleTitle
        : context.l10n.yeniCuzdanEkleTitle;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.getIconData(_selectedIconName),
                  color: _accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                      },
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ Form fields

  Widget _buildNameField(ColorScheme cs) {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      maxLength: 30,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
      decoration: _filledDecoration(
        cs,
        label: context.l10n.labelCuzdanAdi,
        hint: context.l10n.hintOrnAnaCuzdanTatil,
        icon: Icons.account_balance_wallet_rounded,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return context.l10n.cuzdanAdiBosOlamaz;
        }
        if (value.trim().length < 2) {
          return context.l10n.cuzdanAdiEnAz2Karakter;
        }
        return null;
      },
    );
  }

  Widget _buildBalanceField(ColorScheme cs) {
    return TextFormField(
      controller: _balanceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
      decoration: _filledDecoration(
        cs,
        label: isEditMode
            ? context.l10n.bakiyeLabel
            : context.l10n.baslangicBakiyesiLabel,
        hint: '0.00',
        icon: Icons.payments_rounded,
        // Seçili birimle canlı: TRY→₺, USD→$, EUR→€
        suffixText: currencySymbol(_selectedCurrency),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return context.l10n.bakiyeBosOlamaz;
        }
        final amount = parseAmount(value);
        if (amount == null) {
          return context.l10n.gecerliBirSayiGirin;
        }
        // Bakiye negatif olabilir (eksiye düşmüş hesap); yalnız büyüklüğü sınırla.
        if (amount.abs() > kMaxAmount) {
          return context.l10n.tutarCokBuyuk;
        }
        return null;
      },
    );
  }

  /// Para birimi seçici (3 çip). Düzenlemede kilitliyse soluk gösterilir ve
  /// altında açıklama yer alır.
  Widget _buildCurrencyPicker(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final code in kSupportedCurrencies) ...[
              Expanded(
                child: GestureDetector(
                  onTap: _currencyLocked || _isLoading
                      ? null
                      : () => setState(() => _selectedCurrency = code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectedCurrency == code
                          ? _accent.withValues(alpha: 0.14)
                          : cs.onSurface.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedCurrency == code
                            ? _accent
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Opacity(
                      opacity: _currencyLocked && _selectedCurrency != code
                          ? 0.4
                          : 1,
                      child: Column(
                        children: [
                          Text(
                            currencySymbol(code),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _selectedCurrency == code
                                  ? _accent
                                  : cs.onSurface,
                            ),
                          ),
                          Text(
                            code,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (code != kSupportedCurrencies.last) const SizedBox(width: 10),
            ],
          ],
        ),
        if (_currencyLocked) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.lock_rounded,
                  size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.paraBirimiKilitliHint,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Türetilmiş metrikler — kayıtlardan OTOMATİK hesaplanır, düzenlenemez.
  Widget _buildDerivedMetricsSummary(ColorScheme cs) {
    final w = widget.wallet!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.otomatikHesaplananDegerler,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.borcAlacakYatirimKayitlarindan,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _derivedRow(cs, context.l10n.borcLabel, w.debt,
              Icons.arrow_downward_rounded, AppGradients.debt),
          _derivedRow(cs, context.l10n.alacakLabel, w.credit,
              Icons.arrow_upward_rounded, AppGradients.savings),
          _derivedRow(cs, context.l10n.birikimLabel, w.investment,
              Icons.savings_rounded, AppGradients.transactions),
        ],
      ),
    );
  }

  Widget _derivedRow(
      ColorScheme cs, String label, double value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, color: cs.onSurface)),
          const Spacer(),
          Text(
            AppFormatters.currency.format(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ Color picker

  Widget _buildColorPicker(ColorScheme cs) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...WalletColors.presetColors.map((color) {
          final hex = WalletColors.colorToHex(color);
          final isSelected = _selectedColorHex == hex;
          return GestureDetector(
            onTap: () => setState(() => _selectedColorHex = hex),
            child: _swatch(
              cs,
              color,
              isSelected,
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        }),
        // Özel renk seçici
        GestureDetector(
          onTap: _showCustomColorPicker,
          child: _swatch(
            cs,
            WalletColors.hexToColor(_selectedColorHex),
            _isCustomColor,
            child: const Icon(Icons.palette, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _swatch(ColorScheme cs, Color color, bool selected, {Widget? child}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? cs.onSurface : cs.onSurface.withValues(alpha: 0.15),
          width: selected ? 3 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: child,
    );
  }

  // ------------------------------------------------------------- Icon picker

  Widget _buildIconPicker(ColorScheme cs) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _showIconPickerDialog,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _accent.withValues(alpha: 0.5),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Icon(AppIcons.getIconData(_selectedIconName),
                  color: _accent, size: 26),
              const SizedBox(width: 12),
              Text(
                context.l10n.ikonDegistir,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- Buttons

  Widget _buildSaveButton(double radius) {
    final br = BorderRadius.circular(radius.clamp(16, 20));
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: br,
          onTap: _isLoading ? null : _handleSubmit,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppGradients.vivid(_accent),
              borderRadius: br,
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            isEditMode
                                ? Icons.check_rounded
                                : Icons.add_rounded,
                            color: Colors.white,
                            size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isEditMode
                              ? context.l10n.kaydet
                              : context.l10n.olustur,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: Text(
          context.l10n.iptal,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ Shared bits

  Widget _sectionLabel(String text, ColorScheme cs) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cs.onSurfaceVariant,
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _filledDecoration(
    ColorScheme cs, {
    required String label,
    required String hint,
    required IconData icon,
    String? suffixText,
  }) {
    OutlineInputBorder line(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      floatingLabelStyle:
          TextStyle(color: _accent, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
      prefixIcon: Icon(icon,
          size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
      filled: true,
      fillColor: cs.onSurface.withValues(alpha: 0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: line(Colors.transparent, 0),
      enabledBorder: line(Colors.transparent, 0),
      focusedBorder: line(_accent, 1.6),
      errorBorder: line(cs.error, 1.2),
      focusedErrorBorder: line(cs.error, 1.6),
    );
  }

  // ========== ACTIONS ==========

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final balance = parseMoney(_balanceController.text) ?? 0.0;
    final colorHex = _selectedColorHex;
    final iconName = _selectedIconName;
    final createdAt = DateTime.now();
    final sortOrder = DateTime.now().millisecondsSinceEpoch;

    if (isEditMode) {
      // Türetilmiş metrikler (debt/credit/investment) bilinçli olarak
      // yazılmıyor — sync* servisleri kayıtlardan hesaplar.
      final WalletEntity wallet = widget.wallet!.copyWith(
        name: name,
        balance: balance,
        colorHex: colorHex,
        iconName: iconName,
        // Kilitliyken mevcut birim korunur (copyWith null = koru).
        currency: _currencyLocked ? null : _selectedCurrency,
      );
      context.read<WalletBloc>().add(UpdateWalletEvent(wallet));
    } else {
      final WalletEntity wallet = WalletEntity(
        id: null, // ID usecase'de oluşturulacak
        userId: widget.userId,
        name: name,
        balance: balance,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: colorHex,
        iconName: iconName,
        createdAt: createdAt,
        sortOrder: sortOrder,
        isActive: false, // Başlangıçta false
        currency: _selectedCurrency,
      );
      context.read<WalletBloc>().add(CreateWalletEvent(wallet));
    }
  }

  /// İkon seçici alt-sayfasını göster
  void _showIconPickerDialog() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => IconPicker(
        selectedIcon: _selectedIconName,
        iconColor: WalletColors.hexToColor(_selectedColorHex),
        onIconSelected: (iconName) {
          setState(() => _selectedIconName = iconName);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Özel renk seçici diyaloğunu göster (temaya uyumlu AlertDialog)
  void _showCustomColorPicker() {
    Color selectedColor = WalletColors.hexToColor(_selectedColorHex);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.ozelRenkSecin),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) => selectedColor = color,
            enableAlpha: false,
            displayThumbColor: true,
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.iptal),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() =>
                  _selectedColorHex = WalletColors.colorToHex(selectedColor));
              Navigator.pop(dialogContext);
            },
            child: Text(context.l10n.tamam),
          ),
        ],
      ),
    );
  }

  /// BLoC state değişikliklerini dinle
  void _handleBlocState(BuildContext context, WalletState state) {
    if (state is WalletLoadedSt) {
      if ((state.messageType != null || state.message != null) && _isLoading) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        widget.onSuccess();
      } else if (state.error != null && _isLoading) {
        setState(() => _isLoading = false);
        widget.onError(state.error!);
      }
    } else if (state is NoWalletSt) {
      if ((state.messageType != null || state.message != null) && _isLoading) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
        widget.onSuccess();
      } else if (state.error != null && _isLoading) {
        setState(() => _isLoading = false);
        widget.onError(state.error!);
      }
    } else if (state is WalletErrorSt && _isLoading) {
      setState(() => _isLoading = false);
      widget.onError(state.err);
    }
  }
}
