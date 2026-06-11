import 'package:flutter/material.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_controller.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_amount_hero.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_category_picker.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_when_row.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';

/// Gelir/gider ekleme & düzenleme için sıfırdan tasarlanmış modern sayfa.
///
/// Odak: en üstte büyük tutar girişi, altında sade alanlar. Performans için
/// her parça kendi [ValueNotifier]'ını dinler — tutar yazarken kategori
/// ızgarası yeniden çizilmez.
class TransactionFormSheet extends StatefulWidget {
  final bool isExpense;
  final String walletId;
  final String userId;
  final TransactionEntity? initialTransaction;
  final void Function(
      TransactionEntity transaction, RecurringFrequency? frequency) onSave;
  final VoidCallback onCancel;

  const TransactionFormSheet({
    super.key,
    required this.isExpense,
    required this.walletId,
    required this.userId,
    this.initialTransaction,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  late final TransactionFormController _c;
  final FocusNode _amountFocus = FocusNode();
  Animation<double>? _routeAnimation;

  bool get _isEdit => widget.initialTransaction != null;
  Color get _accent =>
      widget.isExpense ? AppGradients.debt : AppGradients.savings;

  @override
  void initState() {
    super.initState();
    _c = TransactionFormController(isExpense: widget.isExpense);
    if (_isEdit) _c.initialize(widget.initialTransaction!);

    // Açılış animasyonu bitince işle: ne kategori yüklemesi ne de klavye
    // sheet yukarı kayarken devreye girsin (çakışma = takılma).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final anim = ModalRoute.of(context)?.animation;
      if (anim == null || anim.isCompleted) {
        _onEntranceDone();
      } else {
        _routeAnimation = anim..addStatusListener(_onAnimStatus);
      }
    });
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _onEntranceDone();
  }

  void _onEntranceDone() {
    _routeAnimation?.removeStatusListener(_onAnimStatus);
    _routeAnimation = null;
    if (!mounted) return;
    _c.loadCategories();
    if (!_isEdit) _amountFocus.requestFocus();
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onAnimStatus);
    _amountFocus.dispose();
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final err = _c.validate();
    if (err != null) {
      _c.error.value = err;
      return;
    }
    _amountFocus.unfocus();
    _c.error.value = null;
    _c.submitting.value = true;

    final when = _c.dateTime.value;
    final transaction = TransactionEntity(
      id: _isEdit ? widget.initialTransaction!.id : null,
      userId: widget.userId,
      walletId: widget.walletId,
      title: _c.titleController.text.trim().isEmpty
          ? _c.categoryId.value ?? 'İşlem'
          : _c.titleController.text.trim(),
      tag: _c.categoryId.value!,
      amount: _c.parsedAmount!,
      date: when,
      type: widget.isExpense
          ? TransactionTypeModel.expense
          : TransactionTypeModel.income,
    );
    widget.onSave(transaction, _c.recurringFrequency.value);
  }

  @override
  Widget build(BuildContext context) {
    final surface =
        Theme.of(context).extension<AppSurface>() ?? AppSurface.light;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DragHandle(),
                AmountHero(
                  controller: _c,
                  accent: _accent,
                  isExpense: widget.isExpense,
                  isEdit: _isEdit,
                  focusNode: _amountFocus,
                  onClose: widget.onCancel,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleField(controller: _c, accent: _accent),
                      const SizedBox(height: 22),
                      CategoryPicker(
                        controller: _c,
                        accent: _accent,
                        isExpense: widget.isExpense,
                      ),
                      const SizedBox(height: 22),
                      WhenRow(controller: _c, accent: _accent),
                      const SizedBox(height: 22),
                      _RecurringRow(
                          controller: _c, accent: _accent, isEdit: _isEdit),
                      const SizedBox(height: 20),
                      _ErrorBanner(controller: _c),
                      _SaveButton(
                        controller: _c,
                        accent: _accent,
                        isEdit: _isEdit,
                        onSubmit: _submit,
                        radius: surface.radius,
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

// ============================================================ Drag handle

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ============================================================ Title field

class _TitleField extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;

  const _TitleField({required this.controller, required this.accent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller.titleController,
      textCapitalization: TextCapitalization.sentences,
      maxLength: 50,
      onChanged: (_) {
        if (controller.error.value != null) controller.error.value = null;
      },
      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Not (İsteğe bağlı) · örn. Market alışverişi',
        prefixIcon: Icon(Icons.edit_note_rounded,
            color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
      ),
    );
  }
}

// ============================================================ Error banner

class _ErrorBanner extends StatelessWidget {
  final TransactionFormController controller;

  const _ErrorBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller.error,
      builder: (context, error, _) {
        if (error == null) return const SizedBox.shrink();
        final color = AppGradients.debt;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================ Save button

class _SaveButton extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;
  final bool isEdit;
  final VoidCallback onSubmit;
  final double radius;

  const _SaveButton({
    required this.controller,
    required this.accent,
    required this.isEdit,
    required this.onSubmit,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius.clamp(16, 20));
    return ValueListenableBuilder<bool>(
      valueListenable: controller.submitting,
      builder: (context, submitting, _) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: br,
              onTap: submitting ? null : onSubmit,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppGradients.vivid(accent),
                  borderRadius: br,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEdit ? Icons.check_rounded : Icons.add_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEdit ? 'Güncelle' : 'Kaydet',
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
      },
    );
  }
}

// ============================================================ Recurring row

class _RecurringRow extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;
  final bool isEdit;

  const _RecurringRow({
    required this.controller,
    required this.accent,
    required this.isEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (isEdit) {
      return const SizedBox.shrink(); // Düzenlemede tekrarlama seçilemez
    }

    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<RecurringFrequency?>(
      valueListenable: controller.recurringFrequency,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.repeat_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RecurringFrequency?>(
                    value: value,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    hint: const Text('Tekrarlama (İsteğe Bağlı)'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tekrar Etme'),
                      ),
                      ...RecurringFrequency.values.map(
                        (freq) => DropdownMenuItem(
                          value: freq,
                          child: Text(freq.displayName),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      controller.recurringFrequency.value = val;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
