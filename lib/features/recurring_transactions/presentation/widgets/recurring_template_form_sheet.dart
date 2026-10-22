import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/focus.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_picker_sheet.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';

/// Sıklığın ekrana yazılan adı. (`RecurringFrequency.displayName` sabit
/// Türkçedir; arayüz bunu kullanır.)
String recurringFrequencyLabel(RecurringFrequency f, AppLocalizations l10n) =>
    switch (f) {
      RecurringFrequency.daily => l10n.daily,
      RecurringFrequency.weekly => l10n.weekly,
      RecurringFrequency.monthly => l10n.monthly,
      RecurringFrequency.yearly => l10n.yearly,
    };

/// Düzenli işlem şablonu formu: [template] verilirse düzenler, verilmezse
/// yenisini kurar. Kaydedilecek şablonu döner; vazgeçilirse `null`.
///
/// Eskiden şablonun TEK kurulma yolu bir işlem eklerken "tekrar" seçmekti ve
/// kurulan şablon hiç düzenlenemiyordu: kirası artan kullanıcı şablonu silip
/// (işlem yazmadan kuramadığı için) yeni bir kira işlemi girerek baştan
/// kurmak zorundaydı.
///
/// Düzenlemede cüzdan ve tür KİLİTLİDİR: ikisi de kategorinin kapsamını
/// belirler (gider kategorisi gelir şablonuna yazılamaz, kategoriler cüzdana
/// göre görünür); değiştirmek = sil + yeniden kur.
Future<RecurringTransactionEntity?> showRecurringTemplateForm(
  BuildContext context, {
  required List<WalletEntity> wallets,
  RecurringTransactionEntity? template,
  String? initialWalletId,
}) {
  return showModalBottomSheet<RecurringTransactionEntity>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _RecurringTemplateFormSheet(
      wallets: wallets,
      template: template,
      initialWalletId: initialWalletId,
    ),
  );
}

class _RecurringTemplateFormSheet extends StatefulWidget {
  final List<WalletEntity> wallets;
  final RecurringTransactionEntity? template;
  final String? initialWalletId;

  const _RecurringTemplateFormSheet({
    required this.wallets,
    required this.template,
    required this.initialWalletId,
  });

  @override
  State<_RecurringTemplateFormSheet> createState() =>
      _RecurringTemplateFormSheetState();
}

class _RecurringTemplateFormSheetState
    extends State<_RecurringTemplateFormSheet> {
  final _title = TextEditingController();
  final _amount = TextEditingController();

  late TransactionTypeModel _type;
  late String? _walletId;
  late RecurringFrequency _frequency;
  late DateTime _date;

  /// Kullanıcı vadeyi elle değiştirdi mi. Değiştirdiyse şablonun çapası
  /// (ayın kaçı) yeni güne taşınır; değiştirmediyse KORUNUR — 31'inde
  /// tekrarlayan bir şablonun vadesi Şubat'ta 28'e kenetlenmiş olabilir ve
  /// formu açıp kaydetmek onu kalıcı olarak 28'e çekmemeli.
  bool _dateTouched = false;

  String? _categoryId;
  Map<String, String> _labels = const {};
  String? _error;

  bool get _isEdit => widget.template != null;
  bool get _isExpense => _type == TransactionTypeModel.expense;

  /// Seçilebilir cüzdanlar, aile sırasında (kart sahibinin altında).
  late final List<WalletEntity> _choices = walletsInFamilyOrder(widget.wallets);

  WalletEntity? get _wallet {
    for (final w in widget.wallets) {
      if (w.id == _walletId) return w;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    if (t != null) {
      _title.text = t.title;
      _amount.text = formatAmountForInput(t.amount);
      _type = t.type;
      _walletId = t.walletId;
      _frequency = t.frequency;
      _date = t.nextExecutionDate;
      _categoryId = t.tag;
    } else {
      _type = TransactionTypeModel.expense;
      _walletId = _choices.any((w) => w.id == widget.initialWalletId)
          ? widget.initialWalletId
          : (_choices.isEmpty ? null : _choices.first.id);
      _frequency = RecurringFrequency.monthly;
      final now = DateTime.now();
      _date = DateTime(now.year, now.month, now.day);
    }
    _loadLabels();
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// Seçili kategorinin adını basabilmek için `id → ad` haritası.
  Future<void> _loadLabels() async {
    try {
      final cats = await getIt<CategoryRepository>().getAllCategories();
      if (!mounted) return;
      setState(() => _labels = buildCategoryLabelMap(cats));
    } catch (e, st) {
      // Kategori deposu `Either` DEĞİL, EXCEPTION fırlatır. Ad çözülemezse
      // etiket l10n'a/ham değere düşer; form yine kullanılabilir.
      reportError('Şablon formu · kategori adları', e, st);
    }
  }

  Future<void> _pickCategory() async {
    final walletId = _walletId;
    if (walletId == null) return;
    releaseInputFocus();
    final picked = await showCategoryPickerSheet(
      context: context,
      isExpense: _isExpense,
      walletId: walletId,
      currentId: _categoryId,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _categoryId = picked.id;
      _labels = {..._labels, picked.id: picked.name};
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = _date.isBefore(today)
        ? DateTime(_date.year, _date.month, _date.day)
        : today;
    releaseInputFocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: first,
      lastDate: DateTime(today.year + 10, today.month, today.day),
      helpText: context.l10n.tarihSec,
    );
    if (picked == null || !mounted) return;
    setState(() {
      // Saat korunur: vade "o günün" aynı anında kalır.
      _date = DateTime(
          picked.year, picked.month, picked.day, _date.hour, _date.minute);
      _dateTouched = true;
    });
  }

  void _save() {
    final l10n = context.l10n;
    final title = _title.text.trim();
    final amount = parseMoneyInput(_amount.text);
    final wallet = _wallet;
    final categoryId = _categoryId;
    final String? error;
    if (title.isEmpty) {
      error = l10n.baslikGirin;
    } else if (amount == null || amount <= 0) {
      error = l10n.gecerliTutarGirin;
    } else if (wallet == null || categoryId == null) {
      error = l10n.kategoriSecmeUyarisi;
    } else {
      error = null;
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final t = widget.template;
    final RecurringTransactionEntity result;
    if (t != null) {
      result = t.copyWith(
        title: title,
        amount: amount,
        tag: categoryId,
        frequency: _frequency,
        nextExecutionDate: _date,
        anchorDay: _dateTouched ? _date.day : t.anchorDay,
      );
    } else {
      result = RecurringTransactionEntity.startingOn(
        id: UidGenerator.generateV7(),
        userId: wallet!.userId,
        walletId: wallet.id!,
        title: title,
        tag: categoryId!,
        amount: amount!,
        type: _type,
        frequency: _frequency,
        firstExecutionDate: _date,
      );
    }
    Navigator.pop(context, result);
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final wallet = _wallet;
    final categoryId = _categoryId;

    // Alanlar kaydırılır, düğmeler SABİT kalır: klavye açıkken Kaydet
    // klavyenin altına düşüyordu (cihazda görüldü) ve kullanıcı kaydetmek
    // için önce klavyeyi kapatmak zorunda kalıyordu.
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + sheetBottomInset(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEdit ? l10n.sablonuDuzenle : l10n.yeniDuzenliIslem,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  if (!_isEdit) ...[
                    LabeledSegment<TransactionTypeModel>(
                      key: const ValueKey('template-type'),
                      items: [
                        SegmentItem(
                          value: TransactionTypeModel.expense,
                          label: l10n.detailLabelGider,
                          color: AppGradients.debt,
                        ),
                        SegmentItem(
                          value: TransactionTypeModel.income,
                          label: l10n.detailLabelGelir,
                          color: AppGradients.savings,
                        ),
                      ],
                      selected: _type,
                      onChanged: (type) => setState(() {
                        if (type == _type) return;
                        _type = type;
                        // Gider kategorisi gelir şablonuna yazılamaz.
                        _categoryId = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    if (_choices.length > 1) ...[
                      DropdownButtonFormField<String>(
                        key: const ValueKey('template-wallet'),
                        initialValue: _walletId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.wallet,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final w in _choices)
                            DropdownMenuItem(
                              value: w.id,
                              child: Text(
                                familyLabel(w, widget.wallets),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (id) => setState(() {
                          if (id == _walletId) return;
                          _walletId = id;
                          // Kategoriler cüzdana göre görünür.
                          _categoryId = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  TextField(
                    key: const ValueKey('template-title'),
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => _clearError(),
                    decoration: InputDecoration(
                      labelText: l10n.sablonBaslikLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('template-amount'),
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [AmountInputFormatter()],
                    onChanged: (_) => _clearError(),
                    decoration: InputDecoration(
                      labelText: l10n.tutarHint,
                      // Şablon tutarı, ait olduğu cüzdanın biriminde tutulur.
                      suffixText:
                          currencySymbol(wallet?.currency ?? kDefaultCurrency),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldTile(
                    key: const ValueKey('template-category'),
                    icon: Icons.label_outline_rounded,
                    label: l10n.labelKategori,
                    value: categoryId == null
                        ? l10n.bankImportPickCategoryHint
                        : context.categoryLabelForTag(categoryId,
                            labels: _labels),
                    missing: categoryId == null,
                    onTap: _pickCategory,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.tekrarSikligiLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final f in RecurringFrequency.values)
                        ChoiceChip(
                          label: Text(recurringFrequencyLabel(f, l10n)),
                          selected: _frequency == f,
                          onSelected: (_) => setState(() => _frequency = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FieldTile(
                    key: const ValueKey('template-date'),
                    icon: Icons.event_rounded,
                    label: _isEdit ? l10n.sonrakiVadeLabel : l10n.ilkVadeLabel,
                    value: AppFormatters.dateLong.format(_date),
                    onTap: _pickDate,
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.error,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            key: const ValueKey('template-actions'),
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.iptal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: Text(_isEdit ? l10n.guncelle : l10n.kaydet),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Dokununca seçici açan alan satırı (kategori, tarih).
class _FieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  /// Değer henüz seçilmedi: çağrı metni vurgulanır.
  final bool missing;

  const _FieldTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.missing = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.onSurface.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: missing ? cs.error : cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
