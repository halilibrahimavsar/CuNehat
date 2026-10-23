import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/features/credit_card/presentation/card_reminders.dart';
import 'package:cunehat/features/credit_card/presentation/card_statement_sheet.dart';
import 'package:cunehat/features/credit_card/presentation/card_status.dart';
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
      useSafeArea: true,
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
  final _monthlyRate = TextEditingController();
  final _lateRate = TextEditingController();

  int _closingDay = 15;
  int _dueDay = CreditCardInfo.defaultDueDayFor(15);

  /// Son ödeme nasıl belirleniyor: ayın sabit bir günü mü, kesimden N gün
  /// sonrası mı ([CreditCardInfo.dueOffsetDays]).
  _DueMode _dueMode = _DueMode.fixedDay;
  int _dueOffset = 10;

  /// Ayarlarda borç alanının AÇILIŞ metni. Kullanıcı alana dokunmadıysa
  /// (metin aynıysa) bakiye yazılmaz: form açıkken defter değişmiş olabilir.
  String _debtInitial = '';

  /// Son ödeme günü kullanıcı tarafından seçildi mi; seçilmediyse kesim günü
  /// değişince varsayılan (kesim + 10) izler.
  bool _dueTouched = false;
  String? _paymentWalletId;
  bool _saving = false;

  /// "Daha fazla ayrıntı" açık mı (yalnız yeni kart / çevirme; ayarlarda
  /// alanlar hep açık).
  bool _showMore = false;

  /// Kullanıcının seçtiği kart rengi; `null` = seçmedi (yeni kartta sıradaki
  /// kullanılmamış renk, çevirmede cüzdanın kendi rengi).
  String? _color;
  bool get _moreOpen => _isEdit || _showMore;

  Duration _motion(BuildContext context) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : const Duration(milliseconds: 260);

  /// Çevrilecek/düzenlenecek cüzdan; yeni kartta `null`. Yeni kart formundan
  /// "var olan cüzdanı kart yap"a geçilince bu ayarlanır.
  WalletEntity? _target;

  bool get _isNew => _target == null;
  bool get _isEdit => _target?.isCreditCard ?? false;

  DateTime get _today => widget.today ?? DateTime.now();

  /// Bağlı (ödeyen) cüzdan adayları. Yeni kart ödeyenin birimini alır; ama
  /// çevrilen ya da düzenlenen kart KENDİ birimini korur ve onu yalnız aynı
  /// birimdeki cüzdan ödeyebilir: tahmin kur bilmez, 1.000 USD'lik ekstreyi
  /// TRY hesaptan 1.000 ₺ düşüyordu (QA K3). Düzenlemede kayıtlı, birimi
  /// farklı eski bağ listede KALIR — kart sessizce cüzdanından kopmasın;
  /// altında uyarı çıkar.
  List<WalletEntity> get _payers {
    final target = _target;
    final saved = widget.wallet?.creditCard?.paymentWalletId;
    return [
      for (final w in widget.wallets)
        if (w.id != null &&
            w.id != target?.id &&
            !w.isCreditCard &&
            (target == null || w.currency == target.currency || w.id == saved))
          w,
    ];
  }

  /// Seçili bağlı cüzdan kartla aynı birimde değil (yalnız düzenlemede
  /// korunan eski bağ olabilir).
  bool get _payerCurrencyDiffers {
    final target = _target;
    if (target == null) return false;
    final payer =
        widget.wallets.where((w) => w.id == _paymentWalletId).firstOrNull;
    return payer != null && payer.currency != target.currency;
  }

  /// Birim süzgeci yüzünden hiç aday kalmadı (başka düz cüzdan var ama
  /// hiçbiri kartın biriminde değil).
  bool get _noPayerInCurrency =>
      _target != null &&
      _payers.isEmpty &&
      widget.wallets
          .any((w) => w.id != null && w.id != _target?.id && !w.isCreditCard);

  /// Karta çevrilebilecek cüzdanlar: düz, bağlı cüzdan olarak seçili
  /// olmayan ve kendi kartı olmayan (kart kartın sahibi olamaz). Bağlı
  /// cüzdan seçiliyse yalnız onun birimindekiler (bkz. [_payers]).
  List<WalletEntity> get _convertible {
    final ownerCurrency = widget.wallets
        .where((w) => w.id == _paymentWalletId)
        .firstOrNull
        ?.currency;
    return [
      for (final w in widget.wallets)
        if (w.id != null &&
            !w.isCreditCard &&
            w.id != _paymentWalletId &&
            cardsOf(w.id, widget.wallets).isEmpty &&
            (ownerCurrency == null || w.currency == ownerCurrency))
          w,
    ];
  }

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
        if (card.dueOffsetDays case final offset?) {
          _dueMode = _DueMode.offset;
          _dueOffset = offset;
        } else {
          // Kip değiştirilirse bankanın beyanından türetilen farkla açılsın.
          _dueOffset = CardCycle(card).declaredDueOffsetDays ?? 10;
        }
        _monthlyRate.text = _rateText(card.monthlyInterestRate);
        _lateRate.text = _rateText(card.lateInterestRate);
        // Borç = eksi bakiye. Kart alacaklıysa (fazla ödeme) alan boş açılır.
        _debtInitial = w.balance < 0 ? formatAmountForInput(-w.balance) : '';
        _debt.text = _debtInitial;
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
      // Bağlı cüzdan yeni hedefin biriminde değilse seçim düşer.
      _paymentWalletId = _payers.any((p) => p.id == owner) ? owner : null;
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
      _monthlyRate,
      _lateRate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _rateText(double? rate) =>
      rate == null ? '' : formatAmountForInput(rate, decimalDigits: 4);

  /// Yüzde alanı: boş → `null` (ayarlanmamış).
  double? _rate(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : parseAmountInput(text);
  }

  String? _optionalRate(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = parseAmountInput(text);
    if (parsed == null || parsed < 0 || parsed > 100) {
      return context.l10n.kkFaizOraniHatasi;
    }
    return null;
  }

  /// Formdaki kurallar (kesim + son ödeme) — beyan olmadan.
  CreditCardInfo get _rules => CreditCardInfo(
        closingDay: _closingDay,
        dueDay: _dueDay,
        dueOffsetDays: _dueMode == _DueMode.offset ? _dueOffset : null,
      );

  /// Kaydedilecek sabit son ödeme günü. "Kesimden N gün sonra" kipinde de
  /// DOLU ve tutarlı yazılır (son kesim + N'in günü): ayar bir gün
  /// kaldırılırsa kart anlamlı bir güne düşsün.
  int get _savedDueDay => _dueMode == _DueMode.offset
      ? CardCycle(_rules).dueFor(_lastClosing).day
      : _dueDay;

  /// Düzenlenen kartın bloc'taki GÜNCEL hâli. Ekstre bilgisi bu sayfa
  /// açıkken değişebilir ("Son ekstre › Düzenle"); kaydederken açılıştaki
  /// kopyanın beyanını yazmak o değişikliği geri alırdı.
  WalletEntity? _liveTarget(BuildContext context) {
    final id = _target?.id;
    if (id == null) return _target;
    try {
      final state = context.read<WalletBloc>().state;
      if (state is WalletLoadedSt) {
        return state.wallets.where((w) => w.id == id).firstOrNull ?? _target;
      }
    } on ProviderNotFoundException {
      // WalletBloc'suz ağaç (yalıtılmış testler).
    }
    return _target;
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
    final rules = _rules;
    final info = CreditCardInfo(
      bankName: _bank.text.trim().isEmpty ? null : _bank.text.trim(),
      last4: _last4.text.trim().isEmpty ? null : _last4.text.trim(),
      limit: _money(_limit),
      closingDay: _closingDay,
      dueDay: _savedDueDay,
      paymentWalletId: _paymentWalletId,
      lastStatement: statementBalance == null
          ? _liveTarget(context)?.creditCard?.lastStatement
          : CardStatement(
              closingDate: lastClosing,
              dueDate: CardCycle(rules).dueFor(lastClosing),
              statementBalance: roundToCents(statementBalance),
              minimumPayment: _money(_minimum),
              recordedAt: DateTime.now(),
            ),
      dueOffsetDays: rules.dueOffsetDays,
      monthlyInterestRate: _rate(_monthlyRate),
      lateInterestRate: _rate(_lateRate),
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
        colorHex: _color ?? _nextCardColor(payer),
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
      // Ayarlarda borç alanına DOKUNULDUYSA bakiye düzeltilir: fark açılış
      // bakiyesine yansır (cüzdan formunun bakiye düzeltmesiyle aynı yol),
      // deftere işlem yazılmaz. Dokunulmadıysa bakiye olduğu gibi kalır.
      final debtEdited = _isEdit && _debt.text.trim() != _debtInitial;
      final updated = w.copyWith(
        name: _name.text.trim(),
        creditCard: info,
        iconName: _isEdit ? null : 'credit_card',
        // Çevirmede renk yalnız kullanıcı seçtiyse değişir (cüzdanın kendi
        // rengi korunur); ayarlarda seçilen renk yazılır.
        colorHex: _color,
        balance: debtEdited ? -roundToCents(_money(_debt) ?? 0) : null,
      );
      bloc.add(UpdateWalletEvent(
        updated,
        // Taban = sayfa açılırken görülen bakiye; bloc farkı buna göre ölçer.
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
          child: Form(
            key: _formKey,
            // Kaydet kaydırılan içeriğin DIŞINDA: ayarlarda alan sayısı
            // arttı ve düğme klavyenin/katlanmanın altında kalıyordu.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
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
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? l10n.kkKartAdiGerekli
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _PairOrStack(
                          children: [
                            Expanded(
                              child: _dayField(
                                label: l10n.kkKesimGunu,
                                value: _closingDay,
                                onChanged: (d) => setState(() {
                                  _closingDay = d;
                                  if (!_dueTouched) {
                                    _dueDay =
                                        CreditCardInfo.defaultDueDayFor(d);
                                  }
                                }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _dueMode == _DueMode.offset
                                  ? _dayField(
                                      key: const ValueKey('kk-due-offset'),
                                      label: l10n.kkKesimdenKacGun,
                                      value: _dueOffset,
                                      onChanged: (d) =>
                                          setState(() => _dueOffset = d),
                                    )
                                  : _dayField(
                                      key: const ValueKey('kk-due-day'),
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
                        const SizedBox(height: 8),
                        // Bankaların çoğu son ödemeyi "kesimden N gün sonra" diye
                        // belirler; sabit gün 31 çeken aylardan sonra bir gün
                        // kayıyordu.
                        LabeledSegment<_DueMode>(
                          selected: _dueMode,
                          onChanged: (mode) => setState(() => _dueMode = mode),
                          items: [
                            SegmentItem(
                                value: _DueMode.fixedDay,
                                label: l10n.kkSonOdemeKipiGun),
                            SegmentItem(
                                value: _DueMode.offset,
                                label: l10n.kkSonOdemeKipiFark),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            l10n.kkSonOdemeOnizleme(
                              // Ay ADIYLA: iki rakam tarih yan yana hangisinin
                              // kesim, hangisinin son ödeme olduğunu
                              // söylemiyor.
                              DateFormat.MMMd(Intl.defaultLocale)
                                  .format(_lastClosing),
                              DateFormat.MMMd(Intl.defaultLocale).format(
                                  CardCycle(_rules).dueFor(_lastClosing)),
                            ),
                            key: const ValueKey('kk-due-preview'),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ColorRow(
                          selected: _color ??
                              (_isNew
                                  ? _nextCardColor(_payers
                                      .where((p) => p.id == _paymentWalletId)
                                      .firstOrNull)
                                  : _target!.colorHex),
                          colors: _cardColors,
                          onSelect: (c) => setState(() => _color = c),
                        ),
                        if (_isNew || _isEdit) ...[
                          // Ayarlarda borç ve limit kendi bölümünde, EN GÖRÜNÜR
                          // yerde: eskiden borç yalnız kart kurulurken soruluyordu
                          // ve limit "ayrıntı"ların arasındaydı.
                          if (_isEdit)
                            _sectionLabel(l10n.kkBolumTutarlar)
                          else
                            const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('kk-debt'),
                            controller: _debt,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
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
                            child: Text(
                                _isEdit
                                    ? l10n.kkGuncelBorcDuzeltAciklama
                                    : l10n.kkGuncelBorcAciklama,
                                style: theme.textTheme.bodySmall),
                          ),
                          if (_isEdit) ...[
                            const SizedBox(height: 12),
                            _limitField(currency),
                          ],
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
                                  child: Text(w.name,
                                      overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            // Kart bir cüzdanın içinde durur: bağlı cüzdan
                            // zorunlu (yetim kart listede ayrı cüzdan gibi durur).
                            validator: (v) =>
                                v == null ? l10n.kkBagliCuzdanGerekli : null,
                            onChanged: (v) =>
                                setState(() => _paymentWalletId = v),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(l10n.kkBagliCuzdanAciklama,
                                style: theme.textTheme.bodySmall),
                          ),
                          if (_payerCurrencyDiffers)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 4),
                              child: Text(
                                l10n.kkOdemeBirimFarkli,
                                key: const ValueKey('kk-owner-currency'),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.error),
                              ),
                            ),
                        ],
                        if (_noPayerInCurrency)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              l10n.kkOdemeBirimYok,
                              key: const ValueKey('kk-owner-none'),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        if (!_isEdit) ...[
                          // Temel olmayan alanlar katlanır (yeni kartta 9 alan
                          // birden kalabalıktı); ayarlarda hep açık.
                          const SizedBox(height: 4),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              key: const ValueKey('kk-more-toggle'),
                              onPressed: () =>
                                  setState(() => _showMore = !_showMore),
                              icon: AnimatedRotation(
                                turns: _moreOpen ? 0.5 : 0,
                                duration: _motion(context),
                                child: const Icon(Icons.expand_more_rounded),
                              ),
                              label: Text(l10n.kkDahaFazlaAyrinti),
                            ),
                          ),
                        ],
                        AnimatedSize(
                          duration: _motion(context),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: !_moreOpen
                              ? const SizedBox(width: double.infinity)
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 12),
                                    _PairOrStack(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: TextFormField(
                                            controller: _bank,
                                            textCapitalization:
                                                TextCapitalization.words,
                                            decoration: _decoration(
                                              label: l10n.kkBanka,
                                              icon: Icons
                                                  .account_balance_outlined,
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
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                  4),
                                            ],
                                            decoration:
                                                _decoration(label: l10n.kkSon4),
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
                                      padding: const EdgeInsets.only(
                                          top: 4, left: 4),
                                      child: Text(l10n.kkSon4Aciklama,
                                          style: theme.textTheme.bodySmall),
                                    ),
                                    // Ayarlarda limit yukarıda, "Tutarlar"da.
                                    if (!_isEdit) ...[
                                      const SizedBox(height: 12),
                                      _limitField(currency),
                                    ],
                                    ..._rateFields(theme),
                                    if (_isEdit) _statementRow(theme),
                                    if (!_isEdit) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.kkSonEkstre,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.kkSonEkstreAciklama(AppFormatters
                                            .dateShort
                                            .format(_lastClosing)),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 8),
                                      _PairOrStack(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: _statementBalance,
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true),
                                              inputFormatters: [
                                                AmountInputFormatter()
                                              ],
                                              decoration: _decoration(
                                                label: l10n.kkDonemBorcu,
                                                suffix:
                                                    currencySymbol(currency),
                                              ),
                                              validator: _optionalMoney,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _minimum,
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                  decimal: true),
                                              inputFormatters: [
                                                AmountInputFormatter()
                                              ],
                                              decoration: _decoration(
                                                label: l10n.kkAsgariOdeme,
                                                suffix:
                                                    currencySymbol(currency),
                                              ),
                                              validator: _optionalMoney,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: FilledButton.icon(
                    key: const ValueKey('kk-save'),
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.kaydet),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );

  /// Faiz oranları: yalnız TAHMİN için (bkz. `estimateCardInterest`).
  List<Widget> _rateFields(ThemeData theme) {
    final l10n = context.l10n;
    Widget field(TextEditingController c, String label, Key key) =>
        TextFormField(
          key: key,
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [AmountInputFormatter(decimalDigits: 4)],
          decoration: _decoration(label: label, suffix: '%'),
          validator: _optionalRate,
        );
    return [
      _sectionLabel(l10n.kkBolumFaiz),
      _PairOrStack(
        children: [
          Expanded(
            child: field(_monthlyRate, l10n.kkAylikFaiz,
                const ValueKey('kk-monthly-rate')),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: field(
                _lateRate, l10n.kkGecikmeFaizi, const ValueKey('kk-late-rate')),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text(l10n.kkFaizAciklama, style: theme.textTheme.bodySmall),
      ),
    ];
  }

  /// Ayarlarda "son ekstre" satırı: bankanın beyanı (dönem borcu / asgari)
  /// ve onu düzenleyen sayfaya giden yol. Kartın GÜNCEL hâlinden okur.
  Widget _statementRow(ThemeData theme) {
    final l10n = context.l10n;
    final WalletEntity? live;
    try {
      final state = context.watch<WalletBloc>().state;
      final id = _target?.id;
      live = state is WalletLoadedSt
          ? (state.wallets.where((w) => w.id == id).firstOrNull ?? _target)
          : _target;
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    if (live == null || !live.isCreditCard) return const SizedBox.shrink();
    final card = live;
    final statement = card.creditCard!.lastStatement;
    final money = MoneyWriter(currency: card.currency, visible: true);
    final summary = statement == null
        ? l10n.kkEkstreHenuzYok
        : statement.minimumPayment == null
            ? l10n.kkEkstreOzetAsgarisiz(money(statement.statementBalance))
            : l10n.kkEkstreOzetSatiri(
                money(statement.statementBalance),
                money(statement.minimumPayment!),
              );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(l10n.kkBolumEkstre),
        CardStatusBuilder(
          card: card,
          today: widget.today,
          builder: (context, status) => Row(
            children: [
              Expanded(
                child: Text(
                  summary,
                  key: const ValueKey('kk-statement-summary'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                key: const ValueKey('kk-statement-edit'),
                // Durum defterden okunur; gelene kadar düğme bekler.
                onPressed: status == null
                    ? null
                    : () => CardStatementSheet.show(
                          context,
                          card: card,
                          status: status,
                        ),
                child: Text(l10n.duzenle),
              ),
            ],
          ),
        ),
      ],
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

  Widget _limitField(String currency) => TextFormField(
        key: const ValueKey('kk-limit'),
        controller: _limit,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [AmountInputFormatter()],
        decoration: _decoration(
          label: context.l10n.kkLimit,
          icon: Icons.speed_rounded,
          suffix: currencySymbol(currency),
        ),
        validator: _optionalMoney,
      );

  Widget _dayField({
    Key? key,
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: key,
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

/// Son ödemenin belirlenme biçimi.
enum _DueMode {
  /// Ayın sabit bir günü ([CreditCardInfo.dueDay]).
  fixedDay,

  /// Kesimden N gün sonra ([CreditCardInfo.dueOffsetDays]).
  offset,
}

/// Kart rengi seçici: koyu kart renkleri; seçili olan beyaz halkalı ve
/// hafif büyütülmüş (hareket azaltmada animasyonsuz).
class _ColorRow extends StatelessWidget {
  final String selected;
  final List<String> colors;
  final ValueChanged<String> onSelect;

  const _ColorRow({
    required this.selected,
    required this.colors,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Row(
      children: [
        Text(
          context.l10n.kkKartRengi,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final hex in colors)
                Semantics(
                  button: true,
                  selected: hex == selected,
                  child: GestureDetector(
                    key: ValueKey('kk-color-$hex'),
                    onTap: () => onSelect(hex),
                    child: AnimatedScale(
                      scale: hex == selected ? 1.12 : 1,
                      duration: reduce
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: WalletColors.hexToColor(hex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hex == selected
                                ? cs.primary
                                : cs.outlineVariant,
                            width: hex == selected ? 3 : 1,
                          ),
                        ),
                        child: hex == selected
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// İki alanı yan yana dizer; her birine [_minField] (yazı ölçeğiyle
/// büyütülmüş) yer kalmıyorsa alt alta. `Row`'da 320dp + büyük yazıda
/// etiketler "Hesap kesim…" / "Son ödeme g…", "Banka (i…" / "Son 4 …",
/// "Aylık akdi…" / "Aylık geci…" diye kesiliyor, hangi alana ne yazılacağı
/// görünmüyordu.
class _PairOrStack extends StatelessWidget {
  final List<Widget> children;

  const _PairOrStack({required this.children});

  static const double _minField = 150;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final fields = children.whereType<Expanded>().toList();
      final min = MediaQuery.textScalerOf(context).scale(_minField);
      final gaps = (children.length - fields.length) * 10;
      final narrowest = fields.isEmpty
          ? double.infinity
          : fields
              .map((f) =>
                  (constraints.maxWidth - gaps) *
                  f.flex /
                  fields.fold<int>(0, (a, e) => a + e.flex))
              .reduce((a, b) => a < b ? a : b);
      if (narrowest >= min) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in children)
            if (c is Expanded)
              c.child
            else if (c is SizedBox)
              SizedBox(height: c.width)
            else
              c,
        ],
      );
    });
  }
}
