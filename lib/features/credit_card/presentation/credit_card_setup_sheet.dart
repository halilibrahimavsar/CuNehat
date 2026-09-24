import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/credit_card/presentation/card_reminders.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';

/// Kredi kartı kurulumu — "sorular": kart adı, banka, son 4 hane, limit,
/// hesap kesim günü, son ödeme günü, şu anki borç, (isteğe bağlı) son ekstre
/// ve kartın hangi cüzdana bağlı olduğu.
///
/// Kart bir cüzdanın İÇİNDEDİR (bkz. `card_family.dart`): bağlı olduğu
/// cüzdan ([CreditCardInfo.paymentWalletId]) aynı zamanda varsayılan ödeme
/// kaynağıdır. Kurulum genelde o cüzdanın kutusundan açılır ([ownerWalletId]).
///
/// Üç kip:
/// - **Yeni kart** ([wallet] `null`): yeni (kart) cüzdanı açılır; açılış
///   bakiyesi = −(şu anki borç). Aktif cüzdan DEĞİŞMEZ.
/// - **Çevir** ([wallet] düz cüzdan): kartını şimdiye kadar ayrı cüzdan
///   olarak tutmuş kullanıcı; bakiye ve defter olduğu gibi kalır. Yeni kart
///   formundaki bağlantıyla da bu kipe geçilir.
/// - **Ayarlar** ([wallet] kart): kart bilgileri düzenlenir.
class CreditCardSetupSheet extends StatefulWidget {
  final String userId;

  /// Kullanıcının tüm cüzdanları (ödeme cüzdanı seçimi + kategori kümesi).
  final List<WalletEntity> wallets;

  /// Çevrilecek ya da düzenlenecek cüzdan; yeni kartta `null`.
  final WalletEntity? wallet;

  /// Yeni kartın birimi (bağlı cüzdan seçilirse onunki kullanılır).
  final String defaultCurrency;

  /// Önceden seçili bağlı cüzdan (kart o cüzdanın kutusundan ekleniyor).
  final String? ownerWalletId;

  /// "Bugün" — test edilebilirlik için.
  final DateTime? today;

  const CreditCardSetupSheet({
    super.key,
    required this.userId,
    required this.wallets,
    this.wallet,
    required this.defaultCurrency,
    this.ownerWalletId,
    this.today,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String userId,
    required List<WalletEntity> wallets,
    WalletEntity? wallet,
    required String defaultCurrency,
    String? ownerWalletId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreditCardSetupSheet(
        userId: userId,
        wallets: wallets,
        wallet: wallet,
        defaultCurrency: defaultCurrency,
        ownerWalletId: ownerWalletId,
      ),
    );
  }

  @override
  State<CreditCardSetupSheet> createState() => _CreditCardSetupSheetState();
}

class _CreditCardSetupSheetState extends State<CreditCardSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bank = TextEditingController();
  final _last4 = TextEditingController();
  final _limit = TextEditingController();
  final _debt = TextEditingController();
  final _statementBalance = TextEditingController();
  final _minimum = TextEditingController();

  int _closingDay = 15;
  int _dueDay = CreditCardInfo.defaultDueDayFor(15);

  /// Son ödeme günü kullanıcı tarafından seçildi mi; seçilmediyse kesim günü
  /// değişince varsayılan (kesim + 10) izler.
  bool _dueTouched = false;
  String? _paymentWalletId;
  bool _saving = false;

  /// Çevrilecek/düzenlenecek cüzdan; yeni kartta `null`. Yeni kart formundan
  /// "var olan cüzdanı kart yap"a geçilince bu ayarlanır.
  WalletEntity? _target;

  bool get _isNew => _target == null;
  bool get _isEdit => _target?.isCreditCard ?? false;

  DateTime get _today => widget.today ?? DateTime.now();

  List<WalletEntity> get _payers => [
        for (final w in widget.wallets)
          if (w.id != null && w.id != _target?.id && !w.isCreditCard) w,
      ];

  /// Karta çevrilebilecek cüzdanlar: düz, bağlı cüzdan olarak seçili
  /// olmayan ve kendi kartı olmayan (kart kartın sahibi olamaz).
  List<WalletEntity> get _convertible => [
        for (final w in widget.wallets)
          if (w.id != null &&
              !w.isCreditCard &&
              w.id != _paymentWalletId &&
              cardsOf(w.id, widget.wallets).isEmpty)
            w,
      ];

  @override
  void initState() {
    super.initState();
    _target = widget.wallet;
    _paymentWalletId = widget.ownerWalletId;
    _prefill();
  }

  void _prefill() {
    final w = _target;
    if (w != null) {
      _name.text = w.name;
      final card = w.creditCard;
      if (card != null) {
        _bank.text = card.bankName ?? '';
        _last4.text = card.last4 ?? '';
        if (card.limit != null) _limit.text = formatAmountForInput(card.limit!);
        _closingDay = card.closingDay;
        _dueDay = card.dueDay;
        _dueTouched = true;
        _paymentWalletId = card.paymentWalletId;
      }
    }
    if (_paymentWalletId != null &&
        !_payers.any((p) => p.id == _paymentWalletId)) {
      _paymentWalletId = null;
    }
  }

  /// Yeni kart formundan "var olan cüzdanı kart yap": seçilen cüzdan bu
  /// formun hedefi olur (bağlı cüzdan seçimi korunur).
  Future<void> _pickConvertTarget() async {
    final picked = await showModalBottomSheet<WalletEntity>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                context.l10n.kkCevirBaslik,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(context.l10n.kkCevirAciklama),
            ),
            for (final w in _convertible)
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(w.name),
                subtitle: Text(formatMoney(w.balance, currency: w.currency)),
                onTap: () => Navigator.of(sheet).pop(w),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final owner = _paymentWalletId;
    setState(() {
      _target = picked;
      _prefill();
      _paymentWalletId = owner;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _bank,
      _last4,
      _limit,
      _debt,
      _statementBalance,
      _minimum,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Önceki (en yakın geçmiş) kesim — "son ekstre" sorusu bu kesim içindir.
  DateTime get _lastClosing => CardCycle(
        CreditCardInfo(closingDay: _closingDay, dueDay: _dueDay),
      ).lastClosing(_today);

  String? _optionalMoney(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = parseMoneyInput(text);
    if (parsed == null || parsed < 0) return context.l10n.gecerliTutarGirin;
    return null;
  }

  double? _money(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : parseMoneyInput(text);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final bloc = context.read<WalletBloc>();

    final statementBalance = _money(_statementBalance);
    final lastClosing = _lastClosing;
    final info = CreditCardInfo(
      bankName: _bank.text.trim().isEmpty ? null : _bank.text.trim(),
      last4: _last4.text.trim().isEmpty ? null : _last4.text.trim(),
      limit: _money(_limit),
      closingDay: _closingDay,
      dueDay: _dueDay,
      paymentWalletId: _paymentWalletId,
      lastStatement: statementBalance == null
          ? _target?.creditCard?.lastStatement
          : CardStatement(
              closingDate: lastClosing,
              dueDate: CardCycle(CreditCardInfo(
                closingDay: _closingDay,
                dueDay: _dueDay,
              )).dueFor(lastClosing),
              statementBalance: roundToCents(statementBalance),
              minimumPayment: _money(_minimum),
              recordedAt: DateTime.now(),
            ),
    );

    final w = _target;
    if (w == null) {
      final payer = _payers.where((p) => p.id == _paymentWalletId).firstOrNull;
      final currency = payer?.currency ?? widget.defaultCurrency;
      final opening = -roundToCents(_money(_debt) ?? 0);
      final categoryIds = await _categoryIdsFor(payer);
      if (!mounted) return;
      final created = WalletEntity(
        id: UidGenerator.generateV7(),
        userId: widget.userId,
        name: _name.text.trim(),
        balance: opening,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: _nextCardColor(payer),
        iconName: 'credit_card',
        createdAt: DateTime.now(),
        openingBalance: opening,
        currency: currency,
        categoryIds: categoryIds,
        creditCard: info,
      );
      bloc.add(CreateWalletEvent(created, activate: false));
      resyncCardReminders(created);
    } else {
      final updated = w.copyWith(
        name: _name.text.trim(),
        creditCard: info,
        iconName: _isEdit ? null : 'credit_card',
      );
      bloc.add(UpdateWalletEvent(
        updated,
        // Bakiye alanı bu sayfada yok: defter olduğu gibi kalır.
        baselineBalance: w.balance,
      ));
      resyncCardReminders(updated);
    }
    if (!mounted) return;
    // Başarı/hata mesajını cüzdan bloc'unun dinleyicisi (ana sayfa) gösterir.
    Navigator.of(context).pop(true);
  }

  /// Kartın görünür kategorileri: ödendiği cüzdanınkiler. O cüzdan kürasyonsuzsa
  /// (`null` = hepsi) TÜM kategori kimlikleri açıkça verilir — yeni cüzdan
  /// `null`u boş kümeye çevirir ve kart her harcamada kategori seçtirirdi.
  Future<List<String>> _categoryIdsFor(WalletEntity? payer) async {
    final source = payer ??
        widget.wallets.where((w) => w.isActive).firstOrNull ??
        widget.wallets.firstOrNull;
    final ids = source?.categoryIds;
    if (ids != null) return ids;
    try {
      final all = await fetchAllCategories(getIt<CategoryRepository>());
      return [for (final c in all) c.id];
    } catch (_) {
      return const [];
    }
  }

  /// Kart renkleri (koyu: beyaz yazı okunur). Aynı cüzdanın kartları sırayla
  /// farklı renk alır — destede üst üste binince ayırt edilsinler (cihazda
  /// ölçüldü: iki arduvaz kart kapalı destede tek kart gibi görünüyordu).
  static const _cardColors = [
    '0xFF37474F', // arduvaz
    '0xFF1A237E', // lacivert
    '0xFF7B1F3A', // bordo
    '0xFF1B5E20', // orman yeşili
    '0xFF4A148C', // mor
    '0xFF5D4037', // bronz
  ];

  String _nextCardColor(WalletEntity? owner) {
    final used = {
      for (final c in cardsOf(owner?.id, widget.wallets)) c.colorHex,
    };
    return _cardColors.firstWhere(
      (c) => !used.contains(c),
      orElse: () => _cardColors[used.length % _cardColors.length],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final title = _isNew
        ? l10n.kkKurulumBaslik
        : (_isEdit ? l10n.kkAyarlarBaslik : l10n.kkCevirBaslik);
    final currency =
        _payers.where((p) => p.id == _paymentWalletId).firstOrNull?.currency ??
            _target?.currency ??
            widget.defaultCurrency;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.credit_card_rounded, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_isEdit) ...[
                    const SizedBox(height: 8),
                    Text(l10n.kkKurulumAciklama,
                        style: theme.textTheme.bodySmall),
                  ],
                  if (_isNew && _convertible.isNotEmpty)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        key: const ValueKey('kk-convert-link'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _pickConvertTarget,
                        child: Text(l10n.kkMevcutCevir),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration(
                      label: l10n.kkKartAdi,
                      hint: l10n.kkKartAdiIpucu,
                      icon: Icons.badge_outlined,
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? l10n.kkKartAdiGerekli : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _bank,
                          textCapitalization: TextCapitalization.words,
                          decoration: _decoration(
                            label: l10n.kkBanka,
                            icon: Icons.account_balance_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _last4,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: _decoration(label: l10n.kkSon4),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            return t.isEmpty || t.length == 4
                                ? null
                                : l10n.kkSon4Hatasi;
                          },
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(l10n.kkSon4Aciklama,
                        style: theme.textTheme.bodySmall),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _limit,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountInputFormatter()],
                    decoration: _decoration(
                      label: l10n.kkLimit,
                      icon: Icons.speed_rounded,
                      suffix: currencySymbol(currency),
                    ),
                    validator: _optionalMoney,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _dayField(
                          label: l10n.kkKesimGunu,
                          value: _closingDay,
                          onChanged: (d) => setState(() {
                            _closingDay = d;
                            if (!_dueTouched) {
                              _dueDay = CreditCardInfo.defaultDueDayFor(d);
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _dayField(
                          label: l10n.kkSonOdemeGunu,
                          value: _dueDay,
                          onChanged: (d) => setState(() {
                            _dueDay = d;
                            _dueTouched = true;
                          }),
                        ),
                      ),
                    ],
                  ),
                  if (_isNew) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _debt,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [AmountInputFormatter()],
                      decoration: _decoration(
                        label: l10n.kkGuncelBorc,
                        hint: '0',
                        icon: Icons.account_balance_wallet_outlined,
                        suffix: currencySymbol(currency),
                      ),
                      validator: _optionalMoney,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(l10n.kkGuncelBorcAciklama,
                          style: theme.textTheme.bodySmall),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (_payers.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      // Çevir kipine geçişte seçim yeniden okunsun.
                      key: ValueKey('kk-owner-${_target?.id}'),
                      initialValue: _paymentWalletId,
                      isExpanded: true,
                      decoration: _decoration(
                        label: l10n.kkOdemeCuzdani,
                        icon: Icons.account_balance_rounded,
                      ),
                      items: [
                        for (final w in _payers)
                          DropdownMenuItem<String?>(
                            value: w.id,
                            child:
                                Text(w.name, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      // Kart bir cüzdanın içinde durur: bağlı cüzdan
                      // zorunlu (yetim kart listede ayrı cüzdan gibi durur).
                      validator: (v) =>
                          v == null ? l10n.kkBagliCuzdanGerekli : null,
                      onChanged: (v) => setState(() => _paymentWalletId = v),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(l10n.kkBagliCuzdanAciklama,
                          style: theme.textTheme.bodySmall),
                    ),
                  ],
                  if (!_isEdit) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.kkSonEkstre,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.kkSonEkstreAciklama(
                          AppFormatters.dateShort.format(_lastClosing)),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _statementBalance,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [AmountInputFormatter()],
                            decoration: _decoration(
                              label: l10n.kkDonemBorcu,
                              suffix: currencySymbol(currency),
                            ),
                            validator: _optionalMoney,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _minimum,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [AmountInputFormatter()],
                            decoration: _decoration(
                              label: l10n.kkAsgariOdeme,
                              suffix: currencySymbol(currency),
                            ),
                            validator: _optionalMoney,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.kaydet),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  InputDecoration _decoration({
    required String label,
    String? hint,
    IconData? icon,
    String? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon),
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _dayField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(label: label),
      items: [
        for (var d = 1; d <= 31; d++)
          DropdownMenuItem(value: d, child: Text('$d')),
      ],
      onChanged: (d) {
        if (d != null) onChanged(d);
      },
    );
  }
}
