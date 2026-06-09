import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/features/finance_transactions/data/models/category_model.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_manager_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final ValueChanged<TransactionEntity> onSave;
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
      title: _c.titleController.text.trim(),
      tag: _c.categoryId.value!,
      amount: _c.parsedAmount!,
      date: when,
      type: widget.isExpense
          ? TransactionTypeModel.expense
          : TransactionTypeModel.income,
    );
    widget.onSave(transaction);
  }

  @override
  Widget build(BuildContext context) {
    final surface =
        Theme.of(context).extension<AppSurface>() ?? AppSurface.light;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                _AmountHero(
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
                      _CategoryPicker(
                        controller: _c,
                        accent: _accent,
                        isExpense: widget.isExpense,
                      ),
                      const SizedBox(height: 22),
                      _WhenRow(controller: _c, accent: _accent),
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

// ============================================================ Amount hero

class _AmountHero extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;
  final bool isExpense;
  final bool isEdit;
  final FocusNode focusNode;
  final VoidCallback onClose;

  const _AmountHero({
    required this.controller,
    required this.accent,
    required this.isExpense,
    required this.isEdit,
    required this.focusNode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = isExpense ? 'Gider' : 'Gelir';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isEdit
                          ? Icons.edit_outlined
                          : (isExpense
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded),
                      size: 15,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEdit ? '$label Düzenle' : '$label Ekle',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  focusNode.unfocus();
                  onClose();
                },
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: TextField(
                    controller: controller.amountController,
                    focusNode: focusNode,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) {
                      if (controller.error.value != null) {
                        controller.error.value = null;
                      }
                    },
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      height: 1.0,
                    ),
                    cursorColor: accent,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: accent.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    AppConstants.currency,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: accent.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        hintText: 'Başlık · örn. Market alışverişi',
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

// ============================================================ Category picker

class _CategoryPicker extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;
  final bool isExpense;

  const _CategoryPicker({
    required this.controller,
    required this.accent,
    required this.isExpense,
  });

  Future<void> _openManager(BuildContext context) async {
    await showCategoryManager(context: context, isExpense: isExpense);
    await controller.loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Kategori',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _openManager(context),
              icon: Icon(Icons.tune_rounded, size: 16, color: accent),
              label: Text('Düzenle',
                  style: TextStyle(
                      fontSize: 12,
                      color: accent,
                      fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<bool>(
          valueListenable: controller.categoriesLoading,
          builder: (context, loading, _) {
            return ValueListenableBuilder<List<CategoryModel>>(
              valueListenable: controller.categories,
              builder: (context, categories, __) {
                if (loading && categories.isEmpty) {
                  return const SizedBox(
                    height: 96,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      if (index == categories.length) {
                        return _AddCategoryTile(
                          accent: accent,
                          onTap: () => _openManager(context),
                        );
                      }
                      final cat = categories[index];
                      return ValueListenableBuilder<String?>(
                        valueListenable: controller.categoryId,
                        builder: (context, selectedId, ___) {
                          return _CategoryTile(
                            category: cat,
                            selected: selectedId == cat.id,
                            accent: accent,
                            onTap: () => controller.categoryId.value = cat.id,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.18)
                    : cs.onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.getIconData(category.iconName),
                size: 20,
                color: selected ? accent : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              category.id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryTile extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _AddCategoryTile({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cs.onSurface.withValues(alpha: 0.14),
            width: 1.4,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded,
                  size: 22, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              'Yeni',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================ Date & time

class _WhenRow extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;

  const _WhenRow({required this.controller, required this.accent});

  Future<void> _pickDate(BuildContext context) async {
    final current = controller.dateTime.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.dateTime.value = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final current = controller.dateTime.value;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked != null) {
      controller.dateTime.value = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: controller.dateTime,
      builder: (context, when, _) {
        return Row(
          children: [
            Expanded(
              child: _WhenPill(
                icon: Icons.calendar_today_rounded,
                label: AppFormatters.dateLong.format(when),
                accent: accent,
                onTap: () => _pickDate(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _WhenPill(
                icon: Icons.schedule_rounded,
                label: AppFormatters.time.format(when),
                accent: accent,
                onTap: () => _pickTime(context),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WhenPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _WhenPill({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.onSurface.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
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
                              isEdit
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
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
