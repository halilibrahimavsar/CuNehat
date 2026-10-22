// lib/features/debt_and_receivable/presentation/widgets/debt_payment_dialog.dart

import 'dart:math' as math;

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/ledger_transaction_picker.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/installment_progress.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/overdue_interest.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/bloc/debt_bloc/debt_bloc.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/payment_edit_dialog.dart';
import 'package:cunehat/core/shared/widgets/app_dialog_surface.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/focus.dart';

/// Borç Ödeme Dialog'u - Kullanıcının borç ödemesi yapmasını sağlar.
///
/// Kabuk [AppDialogSurface]'tir: onay/bilgi diyaloglarıyla aynı düz yüzeyi
/// paylaşır (eskiden IboDialog'un cam kabuğundaydı, ekranın geri kalanıyla
/// ilgisiz duruyordu).
class DebtPaymentDialog extends StatefulWidget {
  final DebtEntity debt;

  /// Borcun ait olduğu cüzdanın para birimi; tutarların tamamı bu birimdedir
  /// (taksit aritmetiği birimden bağımsız, yalnız gösterim bunu kullanır).
  final String currency;

  /// "Bağla…" akışından açıldıysa ödemesi defterde ZATEN duran satır:
  /// diyalog o satır seçili açılır, tutar ve tarih ondan gelir.
  final TransactionEntity? initialLedgerTransaction;

  const DebtPaymentDialog({
    super.key,
    required this.debt,
    required this.currency,
    this.initialLedgerTransaction,
  });

  /// Static show metodu - Dialog'u açar. Ödeme gönderildiyse `true` döner.
  static Future<bool?> show(
    BuildContext context,
    DebtEntity debt, {
    required String currency,
    TransactionEntity? initialLedgerTransaction,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DebtPaymentDialog(
        debt: debt,
        currency: currency,
        initialLedgerTransaction: initialLedgerTransaction,
      ),
    );
  }

  @override
  State<DebtPaymentDialog> createState() => _DebtPaymentDialogState();
}

class _DebtPaymentDialogState extends State<DebtPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _paymentDate;
  double? _activeQuickPay;
  bool _showInstallmentPlan = false;
  bool _showPaymentHistory = false;

  /// Ekranda gösterilen borç. `widget.debt` diyalog AÇILDIĞI andaki donmuş
  /// kopyadır; ödeme silme/düzenleme listeyi tazelediği için her build'de
  /// bloc'tan yeniden çözülür (aynı desen: single_transaction_detail_page).
  /// Kayıt bulunamazsa (yükleme/hata durumları) donmuş kopya korunur —
  /// ekran boşaltılmaz.
  late DebtEntity _debt;

  /// Ödeme defterde ZATEN duruyorsa (ekstredeki "KREDI TAKSIT −2.500") o
  /// satır: tutar ve tarih ondan gelir ve kilitlenir, yeni gider yazılmaz.
  TransactionEntity? _ledgerTx;

  /// Nakit bacağı benimsenmiş bir ekstre satırı olan ödemeler: rozetle
  /// gösterilir, tutarı/tarihi düzenlenmez (bankanın satırından gelir).
  Set<String> _adoptedPaymentIds = const {};

  @override
  void initState() {
    super.initState();
    _debt = widget.debt;
    _loadAdoptedPayments();
    // Alan başlatıcısı widget'a erişemediği için varsayılan "bugün"dü; borcun
    // başlangıcı gelecekteyse bu, seçicinin `firstDate`inin ALTINDA kalıyor ve
    // showDatePicker assertion ile düşüyordu.
    _paymentDate = _clampToPickerRange(DateTime.now());
    final ledgerTx = widget.initialLedgerTransaction;
    if (ledgerTx != null) {
      _ledgerTx = ledgerTx;
      _amountController.text = formatAmountForInput(ledgerTx.amount);
      _paymentDate =
          DateTime(ledgerTx.date.year, ledgerTx.date.month, ledgerTx.date.day);
    }
  }

  Future<void> _loadAdoptedPayments() async {
    final ids = {for (final p in _debt.payments) p.id};
    if (ids.isEmpty || !getIt.isRegistered<WalletMetricsService>()) return;
    try {
      final adopted = await getIt<WalletMetricsService>().adoptedOwners(
        walletId: _debt.walletId,
        recordIds: ids,
      );
      if (mounted) setState(() => _adoptedPaymentIds = adopted);
    } catch (_) {
      // Rozet yalnız bilgi; okunamazsa bloc yine düzenlemeyi reddeder.
    }
  }

  Future<void> _pickLedgerRow() async {
    final picked = await showLedgerTransactionPicker(
      context,
      userId: _debt.userId,
      walletId: _debt.walletId,
      currency: widget.currency,
      isIncome: false,
      amountHint: parseMoneyInput(_amountController.text),
      dateHint: _paymentDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _ledgerTx = picked;
      _activeQuickPay = null;
      _amountController.text = formatAmountForInput(picked.amount);
      _paymentDate =
          DateTime(picked.date.year, picked.date.month, picked.date.day);
    });
  }

  /// "Ödemesi defterde zaten var": satırı seçme/gösterme/kaldırma.
  Widget _buildLedgerPayment(ColorScheme cs) {
    final tx = _ledgerTx;
    if (tx == null) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: _pickLedgerRow,
          icon: const Icon(Icons.receipt_long_rounded, size: 18),
          label: Text(context.l10n.katkiDefterdeVarDugme),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“${tx.title}” · −${_plainMoney(tx.amount)} · '
                  '${AppFormatters.dateShort.format(tx.date)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                Text(
                  context.l10n.borcOdemesiDefterdenKarsilanacak,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _ledgerTx = null),
            child: Text(context.l10n.katkiDefterSatiriKaldir),
          ),
        ],
      ),
    );
  }

  /// Ödeme, borcun başlangıcından önce yapılmış olamaz.
  DateTime get _pickerFirst => _debt.startDate;

  /// Bir yıl ileriye kadar; ama başlangıç daha da ileride ise ona kenetlenir
  /// (aksi halde `lastDate < firstDate` olur ve seçici yine düşer).
  DateTime get _pickerLast {
    final byNow = DateTime.now().add(const Duration(days: 365));
    return byNow.isBefore(_pickerFirst) ? _pickerFirst : byNow;
  }

  DateTime _clampToPickerRange(DateTime d) {
    if (d.isBefore(_pickerFirst)) return _pickerFirst;
    if (d.isAfter(_pickerLast)) return _pickerLast;
    return d;
  }

  /// Göz düğmesinin son okunan durumu.
  ///
  /// `context.amountsVisible` `watch` kullandığı için YALNIZ build sırasında
  /// okunabilir; oysa [_money] build'den sonra da çağrılıyor (silme onayı
  /// mesajı gibi geri çağrılardan). Değeri build'de bir kez alıp saklıyoruz:
  /// geri çağrıda son çizilen karenin görünürlüğü zaten doğru cevap.
  bool _amountsVisible = true;

  /// Diyalogdaki her tutar borcun cüzdan biriminde yazılır ve göz düğmesine
  /// uyar. Bu kısayol maskesiz kaldığı sürece "tutarları gizle" borç ödeme
  /// ekranında hiçbir işe yaramıyordu: özet kartı, taksit planı ve ödeme
  /// geçmişi dahil 17 tutar buradan geçiyor.
  String _money(double amount) =>
      MoneyWriter(currency: widget.currency, visible: _amountsVisible)(amount);

  /// Girdi alanının SINIRINI söyleyen metinler bilerek maskelenmez:
  /// "En fazla **** ₺" yazan bir yardım metni formu kullanılamaz hale
  /// getirir. Aynı karar birikim modülündeki sheet'lerde de verilmişti.
  String _plainMoney(double amount) =>
      formatMoney(amount, currency: widget.currency);

  void _applyQuickPay(double amount) {
    // Önce kuruşa yuvarla: metin, seçili chip ve kaydedilecek tutar
    // birebir aynı değer olsun (314.5599… → 314.56).
    final r = roundToCents(amount);
    setState(() {
      _activeQuickPay = r;
      _amountController.text = formatAmountForInput(r);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Ödeme tarihi itibarıyla kapanmamış gecikme faizi.
  ///
  /// `DateTime.now()` DEĞİL, [_paymentDate] üzerinden hesaplanır: geçmişe
  /// tarihli bir ödemede bugünkü (daha yüksek) tahakkuk üst sınır olarak
  /// kullanılsaydı, mahsup o tarihteki daha küçük faizi düşer ve fazlası ana
  /// paraya giderek kalanı eksiye çekerdi.
  double get _outstandingInterest =>
      outstandingOverdueInterest(_debt, now: _paymentDate);

  /// Borcu bu tarihte tamamen kapatmak için gereken tutar.
  double get _payoff =>
      roundToCents(_debt.remainingAmount + _outstandingInterest);

  void _handlePayment() {
    if (!_formKey.currentState!.validate()) return;

    var amount = parseMoneyInput(_amountController.text)!;
    // Yarım kuruş içindeki fazlalığı kapanış tutarına kıskaçla: kayıtlı
    // ödemeler toplamı borcu asla aşmasın (negatif kalan oluşmasın).
    final payoff = _payoff;
    if (amount > payoff && !moneyGreaterThan(amount, payoff)) {
      amount = payoff;
    }

    // Faiz/ana para ayrımı ve `isPaid` burada HESAPLANMAZ: ikisi de
    // DebtBloc'taki tek normalizasyon noktasından geçer (bkz. `_normalize`).
    // Ödeme düzenleme/silme de aynı yoldan geçtiği için paylar her zaman
    // kronolojik olarak yeniden dağıtılır.
    final newPayment = Payment(
      id: UidGenerator.generateV7(),
      date: _paymentDate,
      amount: amount,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final updatedDebt = _debt.copyWith(
      payments: [..._debt.payments, newPayment],
    );

    final ledgerTx = _ledgerTx;
    context.read<DebtBloc>().add(PayDebtEvent(
          updatedDebt,
          amount,
          paymentDate: _paymentDate,
          paymentId: newPayment.id,
          cashSource: ledgerTx == null
              ? const NewCashMovement()
              : AdoptedCashMovement(ledgerTx),
        ));
    Navigator.of(context).pop(true);
  }

  Future<void> _selectDate() async {
    releaseInputFocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _clampToPickerRange(_paymentDate),
      firstDate: _pickerFirst,
      lastDate: _pickerLast,
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
        // Tahakkuk tarihe bağlı → seçili hızlı-ödeme tutarı bayatlar.
        _activeQuickPay = null;
      });
    }
  }

  /// Bloc'taki güncel kaydı bulur; yoksa elindeki kopyayı korur.
  DebtEntity _resolveDebt(BuildContext context) {
    final state = context.watch<DebtBloc>().state;
    if (state is DebtLoaded) {
      for (final d in state.debts) {
        if (d.id == _debt.id) return d;
      }
    }
    return _debt;
  }

  @override
  Widget build(BuildContext context) {
    _debt = _resolveDebt(context);
    _amountsVisible = context.amountsVisible;
    final mq = MediaQuery.of(context);
    // Diyalog kabuğu içeriğe sonsuz yükseklik veriyor; ConstrainedBox bunu
    // filtreler ve SingleChildScrollView sınırlı alanda scroll eder → taşma yok.
    // Alt sınır YOK: 380'e sabitlenen taban 568dp'lik telefonda diyaloğu
    // 64px taşırıyor, "Ödemeyi kaydet" düğmesini diyalogun dışına itiyordu.
    // Kaydırma alanı ayrıca `Flexible`: kalan yükseklikten fazlasını almaz.
    final maxH =
        (mq.size.height - mq.viewInsets.bottom - 250).clamp(120.0, 700.0);

    final remaining = _debt.remainingAmount;
    final totalDebt = _debt.totalDebtAmount;
    final totalPaid = _debt.totalPaidAmount;
    // Tahakkuk hesabı liste/plan üzerinden döndüğü için build başına BİR kez
    // ölçülür; getter'lar her çağrıda yeniden hesaplardı.
    final outstandingInterest = _outstandingInterest;
    final payoff = roundToCents(remaining + outstandingInterest);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return AppDialogSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: 12),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Borç Özeti
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? cs.primary.withValues(alpha: 0.15)
                              : cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? cs.primary.withValues(alpha: 0.35)
                                : cs.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _debt.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(context.l10n.toplamBorcLabel,
                                _money(totalDebt)),
                            _buildInfoRow(
                                context.l10n.odenenLabel, _money(totalPaid),
                                color: Colors.green),
                            const Divider(height: 16),
                            // Gecikme faizi borcun KENDİSİ değil; kalan ana para
                            // ile ayrı satırlarda durur, ikisinin toplamı
                            // "ödenecek toplam"dır.
                            _buildInfoRow(
                                context.l10n.kalanLabel, _money(remaining),
                                color: Colors.red,
                                isBold: !moneyIsPositive(outstandingInterest)),
                            if (moneyIsPositive(outstandingInterest)) ...[
                              _buildInfoRow(context.l10n.gecikmeFaiziLabel,
                                  _money(outstandingInterest),
                                  color: Colors.red),
                              const Divider(height: 16),
                              _buildInfoRow(context.l10n.odenecekToplamLabel,
                                  _money(payoff),
                                  color: Colors.red, isBold: true),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Hızlı seçim chip'leri — defterden satır seçiliyken tutar
                      // o satırındır, çip onu değiştiremez.
                      if (_ledgerTx == null) ...[
                        _buildQuickPayOptions(payoff, outstandingInterest),
                        const SizedBox(height: 12),
                      ],

                      // Ödeme Tutarı
                      TextFormField(
                        controller: _amountController,
                        readOnly: _ledgerTx != null,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [AmountInputFormatter()],
                        onChanged: (_) {
                          // Faiz payı önizlemesi tutara bağlı → her değişimde
                          // yeniden çiz.
                          setState(() => _activeQuickPay = null);
                        },
                        decoration: InputDecoration(
                          labelText: context.l10n.labelOdemeTutari,
                          hintText: '0,00',
                          prefixIcon: const Icon(Icons.attach_money),
                          suffixText: currencySymbol(widget.currency),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          helperText: context.l10n.maksimumFormatmoneyRemaining(
                              _plainMoney(payoff)),
                        ),
                        validator: (value) => validateAmountInput(
                          value ?? '',
                          max: payoff,
                          maxExceededMessage:
                              moneyIsPositive(outstandingInterest)
                                  ? context.l10n.odenecekTutardanFazlaOlamaz
                                  : context.l10n.kalanTutardanFazlaOlamaz,
                        ),
                      ),

                      // Mahsup sırası kullanıcıya görünür olmalı: girilen tutarın
                      // bir kısmı borcu değil faizi kapatıyor.
                      if (moneyIsPositive(outstandingInterest))
                        _buildAllocationHint(outstandingInterest),

                      _buildLedgerPayment(cs),

                      const SizedBox(height: 16),

                      // Ödeme Tarihi — defterden seçilen satırın günü kilitlidir.
                      InkWell(
                        onTap: _ledgerTx == null ? _selectDate : null,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: context.l10n.labelOdemeTarihi,
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            AppFormatters.dateLong.format(_paymentDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notlar
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: context.l10n.labelNotOpsiyonel,
                          hintText: context.l10n.hintOdemeIleIlgiliNotlar,
                          prefixIcon: const Icon(Icons.note_alt),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      // Taksit Planı (foldable)
                      if (_debt.termMonths > 1) ...[
                        const SizedBox(height: 8),
                        _buildCollapsibleSection(
                          cs: cs,
                          title: context.l10n
                              .taksitPlaniFormat(_debt.termMonths.toString()),
                          icon: Icons.calendar_month_rounded,
                          isExpanded: _showInstallmentPlan,
                          onToggle: () => setState(() =>
                              _showInstallmentPlan = !_showInstallmentPlan),
                          child: _buildInstallmentPlanList(isDark),
                        ),
                      ],

                      // Ödeme Geçmişi (foldable)
                      if (_debt.payments.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildCollapsibleSection(
                          cs: cs,
                          title: context.l10n.odemeGecmisiFormat(
                              _debt.payments.length.toString()),
                          icon: Icons.history_rounded,
                          isExpanded: _showPaymentHistory,
                          onToggle: () => setState(
                              () => _showPaymentHistory = !_showPaymentHistory),
                          child: _buildPaymentHistoryList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildActions(context),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- Header

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.green.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.payment,
            color: isDark ? Colors.greenAccent : Colors.green.shade700,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.l10n.odemeYap,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- Actions

  Widget _buildActions(BuildContext context) {
    // OverflowBar: dar ekranda iki düğme sığmazsa alt alta (Row'da 69px
    // taşıyordu).
    return OverflowBar(
      alignment: MainAxisAlignment.end,
      overflowAlignment: OverflowBarAlignment.end,
      spacing: 8,
      overflowSpacing: 4,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.iptal),
        ),
        ElevatedButton.icon(
          onPressed: _handlePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_circle, size: 20),
          label: Text(context.l10n.odemeyiKaydet),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- Sections

  Widget _buildCollapsibleSection({
    required ColorScheme cs,
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isExpanded ? child : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildInstallmentPlanList(bool isDark) {
    // Durum ödenen TUTARdan gelir, ödeme SAYISINDAN değil: aradan geçen
    // kısmi/fazla ödemeler planı kaydırmaz (bkz. buildInstallmentPlan).
    final plan = buildInstallmentPlanFor(_debt);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in plan)
          Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor:
                    _statusColor(row).withValues(alpha: isDark ? 0.25 : 0.12),
                child:
                    Icon(_statusIcon(row), size: 16, color: _statusColor(row)),
              ),
              title: Text(
                context.l10n.iTaksitAppformattersDateshort(
                    row.number, AppFormatters.dateShort.format(row.dueDate)),
                style: const TextStyle(fontSize: 13),
              ),
              // Gecikme faizi satır başına DAĞITILMAZ (mahsup havuzludur:
              // ödeme tek bir taksitin faizine değil toplam faize gider), bu
              // yüzden burada tutar değil yalnız gecikme SÜRESİ yazar.
              subtitle: Text(
                row.isOverdue
                    ? context.l10n.taksitGecikmeGun(_money(row.scheduledAmount),
                        DateTime.now().difference(row.dueDate).inDays)
                    : context.l10n
                        .formatMoneyMonthlyamount(_money(row.scheduledAmount)),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              trailing: Text(
                _statusText(row),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(row),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _statusColor(InstallmentProgress row) => switch (row.status) {
        InstallmentStatus.paid => Colors.green,
        _ => row.isOverdue ? Colors.red : Colors.orange,
      };

  IconData _statusIcon(InstallmentProgress row) => switch (row.status) {
        InstallmentStatus.paid => Icons.check_circle_rounded,
        _ => row.isOverdue
            ? Icons.warning_rounded
            : (row.status == InstallmentStatus.partial
                ? Icons.incomplete_circle_rounded
                : Icons.schedule_rounded),
      };

  /// Kısmi ödemede tutar gösterilir ("300,00 ₺ / 1.000,00 ₺"); gecikme
  /// ayrı bir eksen olduğundan renk/ikon uyarıyı ayrıca taşır.
  String _statusText(InstallmentProgress row) => switch (row.status) {
        InstallmentStatus.paid => _money(row.paidAmount),
        InstallmentStatus.partial =>
          '${_money(row.paidAmount)} / ${_money(row.scheduledAmount)}',
        InstallmentStatus.unpaid =>
          row.isOverdue ? context.l10n.gecikmis : context.l10n.bekleniyor,
      };

  Future<void> _deletePayment(Payment payment) async {
    final bloc = context.read<DebtBloc>();
    final confirmed = await ConfirmDialog.show(
      context,
      title: context.l10n.odemeSilBaslik,
      message: context.l10n.odemeSilOnayMesaji(_money(payment.amount)),
      confirmText: context.l10n.sil,
      danger: true,
    );
    if (!confirmed) return;

    bloc.add(DeleteDebtPaymentEvent(
      _debt.copyWith(
        payments: [
          for (final p in _debt.payments)
            if (p.id != payment.id) p
        ],
      ),
      removedAmount: payment.amount,
      removedDate: payment.date,
      removedPaymentId: payment.id,
    ));
  }

  Future<void> _editPayment(Payment payment) async {
    final bloc = context.read<DebtBloc>();
    // Kendi katkısı geri sayılmalı: aksi hâlde tutarı değiştirmeyen bir
    // düzenleme bile "kalandan fazla" diye reddedilirdi.
    final maxAmount = roundToCents(_payoff + payment.amount);
    final result = await PaymentEditDialog.show(
      context,
      payment: payment,
      currency: widget.currency,
      maxAmount: maxAmount,
      firstDate: _pickerFirst,
      lastDate: _pickerLast,
    );
    if (result == null) return;

    bloc.add(UpdateDebtPaymentEvent(
      _debt.copyWith(
        payments: [
          for (final p in _debt.payments)
            if (p.id == payment.id) result else p
        ],
      ),
      prevAmount: payment.amount,
      prevDate: payment.date,
      newAmount: result.amount,
      newDate: result.date,
      paymentId: payment.id,
    ));
  }

  Widget _buildPaymentHistoryList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _debt.payments.asMap().entries.map((entry) {
        final index = entry.key;
        final payment = entry.value;
        final adopted = _adoptedPaymentIds.contains(payment.id);
        // ListTile değil: dar diyalogda (320dp + büyük yazı) önde numara,
        // sonda iki düğme başlığa ~10dp bırakıyor, tutar "5. / 0 / 0 …" diye
        // karakter karakter alt alta diziliyordu. Tutar ve tarih tam
        // genişlikte, düğmeler altlarında sağda.
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      context.l10n.index(index + 1),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _money(payment.amount),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Başlıktaki tutar cüzdandan ÇIKAN tam tutar; bunun ne kadarının
                      // borcu değil gecikme faizini kapattığı burada yazar.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            moneyIsPositive(payment.overdueInterestPart)
                                ? context.l10n.odemeIcindeGecikmeFaizi(
                                    AppFormatters.dateShort
                                        .format(payment.date),
                                    _money(payment.overdueInterestPart),
                                  )
                                : AppFormatters.dateShort.format(payment.date),
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (adopted)
                            Text(
                              context.l10n.odemeDefterSatirinaBagli,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (payment.notes != null)
                              Tooltip(
                                message: payment.notes!,
                                child: const Icon(Icons.info_outline, size: 16),
                              ),
                            // Yanlış girilen bir ödemenin tek çıkış yolu, borcun tamamını
                            // silmekti: deftere yazılan karşılığı sistem işlemi olduğu
                            // için işlemler sayfasından da silinemiyordu.
                            // Satır içi İKİ düğme. Eskiden burada bir açılır menü
                            // vardı (uygulamadaki son açılır menü): diyalogun üstüne
                            // alt sayfa açmak iki katmanlı modal olurdu, o yüzden eylem
                            // sayfasına da taşınamıyordu. İki eylem için menü gereksiz —
                            // doğrudan düğme bir dokunuş kısaltır. Silme onay sorar.
                            IconButton(
                              key: ValueKey('payment-edit-${payment.id}'),
                              tooltip: context.l10n.duzenle,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(
                                  minWidth: 40, minHeight: 40),
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              // Benimsenmiş ödemenin tutarı/tarihi bankanın satırından
                              // gelir (bloc da reddeder).
                              onPressed:
                                  adopted ? null : () => _editPayment(payment),
                              icon: const Icon(Icons.edit_rounded),
                            ),
                            IconButton(
                              key: ValueKey('payment-delete-${payment.id}'),
                              tooltip: context.l10n.sil,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(
                                  minWidth: 40, minHeight: 40),
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () => _deletePayment(payment),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------- Quick pay

  /// Girilen tutarın ne kadarının faize, ne kadarının ana paraya sayılacağı.
  Widget _buildAllocationHint(double outstandingInterest) {
    final entered = parseMoneyInput(_amountController.text) ?? 0;
    if (!moneyIsPositive(entered)) return const SizedBox.shrink();
    final interestPart = roundToCents(math.min(entered, outstandingInterest));
    final principalPart = roundToCents(entered - interestPart);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.l10n.odemeMahsupAciklama(
                  _money(interestPart), _money(principalPart)),
              style: TextStyle(
                fontSize: 11.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPayOptions(double payoff, double outstandingInterest) {
    // Tutarlar plandan okunur, yeniden hesaplanmaz. Elle `toplam / vade`
    // bölmek aynı diyalogda İKİ ayrı "bir taksit" tanımı yaratıyordu: plan
    // satırları kuruşa yuvarlanıp artığı son taksite yüklerken (1.000/3 →
    // 333,33 / 333,33 / 333,34) chip 333,33333… öneriyordu. Chip'lerle ödeyen
    // kullanıcı son taksiti hiçbir zaman "ödendi"ye çeviremiyor, borç kuruşu
    // kapanmadan açık kalıyordu.
    final plan = buildInstallmentPlanFor(_debt);
    final unpaid = plan
        .where((r) => r.status != InstallmentStatus.paid)
        .toList(growable: false);

    /// Sıradaki [count] ödenmemiş taksiti GERÇEKTEN kapatan tutar.
    ///
    /// Kapanmamış gecikme faizi eklenir: mahsup önce faizi kapattığı için,
    /// yalnız taksit tutarı kadar ödeme yapıldığında taksit kapanmaz — chip
    /// vaat ettiğini yerine getirmemiş olurdu.
    double? nextInstallments(int count) {
      if (unpaid.length < count) return null;
      final sum = unpaid
          .take(count)
          .fold<double>(0, (acc, r) => acc + r.remainingAmount);
      final capped = roundToCents(math.min(sum + outstandingInterest, payoff));
      return capped > 0 ? capped : null;
    }

    final oneInstallment = _debt.termMonths > 1 ? nextInstallments(1) : null;
    final twoInstallments = _debt.termMonths > 1 ? nextInstallments(2) : null;

    final options = <({String label, double amount})>[
      // Yalnız birikmiş gecikme faizini kapat.
      if (moneyIsPositive(outstandingInterest))
        (label: context.l10n.gecikmeFaiziChip, amount: outstandingInterest),
      if (oneInstallment != null)
        (label: context.l10n.taksit1, amount: oneInstallment),
      // Tamamıyla aynı tutara düşen ikinci chip kullanıcıya bir şey sunmaz.
      if (twoInstallments != null && twoInstallments < payoff)
        (label: context.l10n.taksit2, amount: twoInstallments),
      // payoff zaten kuruşa yuvarlı
      (label: context.l10n.tamaminiOde, amount: payoff),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isActive = _activeQuickPay == opt.amount;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _applyQuickPay(opt.amount),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(alpha: 0.15)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? Colors.green : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  context.l10n
                      .optLabelFormatmoneyOpt(opt.label, _money(opt.amount)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.greenAccent
                            : Colors.green.shade700)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------- Info row

  Widget _buildInfoRow(String label, String value,
      {Color? color, bool isBold = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color resolvedColor;
    if (color != null) {
      if (color == Colors.green) {
        resolvedColor = isDark ? Colors.greenAccent : Colors.green.shade700;
      } else if (color == Colors.red) {
        resolvedColor = isDark ? Colors.redAccent : Colors.red.shade700;
      } else {
        resolvedColor = color;
      }
    } else {
      resolvedColor = isDark ? theme.colorScheme.onSurface : Colors.black87;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      // Wrap: sığmazsa tutar alt satıra (sağa) iner. Row'da dar diyalogda
      // etiket "Kalan" / ":" diye harf harf bölünüyordu.
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : Colors.grey.shade700,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: resolvedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
