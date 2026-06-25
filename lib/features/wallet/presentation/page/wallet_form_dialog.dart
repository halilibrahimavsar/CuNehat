// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:unified_flutter_features/unified_flutter_features.dart';

/// **Cüzdan Oluşturma/Düzenleme Dialog'unu Göster**
///
/// [wallet] null ise → Yeni Cüzdan Oluştur
/// [wallet] dolu ise → Mevcut Cüzdanı Düzenle
Future<void> showCreateEditDialog({
  required BuildContext context,
  required String userId,
  WalletEntity? wallet,
  required VoidCallback onSuccess,
  required Function(String error) onError,
}) async {
  await IboDialog.showCustomDialog(
    context,
    title: wallet != null
        ? context.l10n.cuzdanDuzenleTitle
        : context.l10n.yeniCuzdanEkleTitle,
    content: BlocProvider.value(
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

/// **Cüzdan Form Dialog Widget**
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
  bool _isLoading = false;

  // ========== GETTERS ==========
  bool get isEditMode => widget.wallet != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeState();
  }

  /// Controller'ları başlat
  void _initializeControllers() {
    _nameController = TextEditingController(
      text: widget.wallet?.name ?? '',
    );
    _balanceController = TextEditingController(
      text: widget.wallet?.balance.toStringAsFixed(2) ?? '0.00',
    );
  }

  /// State değerlerini başlat
  void _initializeState() {
    _selectedColorHex = widget.wallet?.colorHex ?? '0xFF2196F3';
    _selectedIconName = widget.wallet?.iconName ?? 'wallet';
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
      child: _buildForm(),
    );
  }

  /// Form içeriği
  Widget _buildForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameField(),
            const SizedBox(height: 16),
            _buildBalanceField(),
            if (isEditMode) ...[
              const SizedBox(height: 16),
              _buildDerivedMetricsSummary(),
            ],
            const SizedBox(height: 16),
            _buildColorPicker(),
            const SizedBox(height: 16),
            _buildIconPicker(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActions(),
            ),
          ],
        ),
      ),
    );
  }

  /// İsim alanı
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: context.l10n.labelCuzdanAdi,
        hintText: context.l10n.hintOrnAnaCuzdanTatil,
        border: const OutlineInputBorder(),
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
      textCapitalization: TextCapitalization.words,
      maxLength: 30,
    );
  }

  /// Bakiye alanı
  Widget _buildBalanceField() {
    return TextFormField(
      controller: _balanceController,
      decoration: InputDecoration(
        labelText: isEditMode
            ? context.l10n.bakiyeLabel
            : context.l10n.baslangicBakiyesiLabel,
        hintText: '0.00',
        border: const OutlineInputBorder(),
        suffixText: '₺',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

  /// Türetilmiş metrikler — kayıtlardan OTOMATİK hesaplanır, düzenlenemez.
  /// (Eskiden elle girilebiliyordu; sonraki sync değerleri ezip kafa
  /// karıştırıyordu.)
  Widget _buildDerivedMetricsSummary() {
    final w = widget.wallet!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.otomatikHesaplananDegerler,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.borcAlacakYatirimKayitlarindan,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        _derivedRow(
            context.l10n.borcLabel, w.debt, Icons.arrow_downward, Colors.red),
        _derivedRow(context.l10n.alacakLabel, w.credit, Icons.arrow_upward,
            Colors.green),
        _derivedRow(context.l10n.birikimLabel, w.investment, Icons.savings,
            Colors.orange),
      ],
    );
  }

  Widget _derivedRow(String label, double value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            AppFormatters.currency.format(value),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Renk seçici
  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.renkSecin,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...WalletColors.presetColors.map((color) {
              final hex = WalletColors.colorToHex(color);
              final isSelected = _selectedColorHex == hex;

              return GestureDetector(
                onTap: () => setState(() => _selectedColorHex = hex),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }),
            // Özel renk seçici
            GestureDetector(
              onTap: _showCustomColorPicker,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WalletColors.hexToColor(_selectedColorHex),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: !WalletColors.presetColors.any(
                      (c) => WalletColors.colorToHex(c) == _selectedColorHex,
                    )
                        ? Colors.black
                        : Colors.grey.shade300,
                    width: !WalletColors.presetColors.any(
                      (c) => WalletColors.colorToHex(c) == _selectedColorHex,
                    )
                        ? 3
                        : 1,
                  ),
                  boxShadow: !WalletColors.presetColors.any(
                    (c) => WalletColors.colorToHex(c) == _selectedColorHex,
                  )
                      ? [
                          BoxShadow(
                            color: WalletColors.hexToColor(_selectedColorHex)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: const Icon(
                  Icons.palette,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// İkon seçici
  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.ikonSecin2,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: WalletColors.hexToColor(_selectedColorHex).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: WalletColors.hexToColor(_selectedColorHex),
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showIconPickerDialog,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.getIconData(_selectedIconName),
                      color: WalletColors.hexToColor(_selectedColorHex),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.ikonDegistir,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Dialog aksiyonları (butonlar)
  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: Text(context.l10n.iptal),
      ),
      ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(isEditMode ? context.l10n.kaydet : context.l10n.olustur),
      ),
    ];
  }

  // ========== ACTIONS ==========

  /// Form gönderimini işle
  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final balance = parseAmount(_balanceController.text) ?? 0.0;
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
      );
      context.read<WalletBloc>().add(CreateWalletEvent(wallet));
    }
  }

  /// İkon seçici dialog'unu göster
  void _showIconPickerDialog() {
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

  /// Özel renk seçici dialog'unu göster
  void _showCustomColorPicker() {
    Color selectedColor = WalletColors.hexToColor(_selectedColorHex);

    IboDialog.showCustomDialog(
      context,
      title: context.l10n.ozelRenkSecin,
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: selectedColor,
          onColorChanged: (color) {
            selectedColor = color;
          },
          enableAlpha: false,
          displayThumbColor: true,
          showLabel: true,
          pickerAreaHeightPercent: 0.8,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.iptal),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() =>
                _selectedColorHex = WalletColors.colorToHex(selectedColor));
            Navigator.pop(context);
          },
          child: Text(context.l10n.tamam),
        ),
      ],
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
