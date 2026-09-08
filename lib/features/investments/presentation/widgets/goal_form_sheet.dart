import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/investment_sheet_widgets.dart';
import 'package:cunehat/features/investments/presentation/widgets/goal_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Birikim hedefi ekleme/düzenleme.
///
/// Hedef bir KAP: para hareketi yaratmaz, defterle ilişkisi yoktur. Bu yüzden
/// form kısa — ad, tutar, kategori, renk. Varlıklar hedefe kendi
/// formlarından ya da hedefin "varlık ekle" düğmesinden bağlanır.
class GoalFormSheet extends StatefulWidget {
  final String userId;
  final String walletId;
  final String walletCurrency;
  final GoalEntity? goalToEdit;
  final ValueChanged<GoalEntity> onSave;

  const GoalFormSheet({
    super.key,
    required this.userId,
    required this.walletId,
    required this.walletCurrency,
    required this.onSave,
    this.goalToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String walletId,
    required String walletCurrency,
    required ValueChanged<GoalEntity> onSave,
    GoalEntity? goalToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalFormSheet(
        userId: userId,
        walletId: walletId,
        walletCurrency: walletCurrency,
        onSave: onSave,
        goalToEdit: goalToEdit,
      ),
    );
  }

  @override
  State<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<GoalFormSheet> {
  static const _accent = Colors.teal;

  final _nameController = TextEditingController();
  final _targetController = TextEditingController();

  /// Kullanıcı kendi kategorisini yazdığında kaydedilecek metin.
  ///
  /// Ayrı bir controller: hazır chip'lere geri dönüp tekrar "Özel"e basan
  /// kullanıcı yazdığını kaybetmesin.
  final _customCategoryController = TextEditingController();

  /// Hazır seçenek seçildiğinde saklanacak anahtar. Özel kipte KULLANILMAZ —
  /// o zaman kayda [_customCategoryController]'ın metni gider.
  String _category = 'diger';

  /// Özel kategori kipi. Düzenlemede, kaydın kategorisi hazır anahtarlardan
  /// biri değilse açık başlar.
  bool _isCustomCategory = false;
  Color _color = Colors.teal;
  String? _error;

  bool get _isEditing => widget.goalToEdit != null;

  final List<Color> _colorOptions = [
    Colors.teal,
    Colors.green,
    Colors.amber,
    Colors.orange,
    Colors.pink,
    Colors.purple,
    Colors.indigo,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    final goal = widget.goalToEdit;
    if (goal != null) {
      _nameController.text = goal.name;
      _targetController.text = formatAmountForInput(goal.targetAmount);
      if (GoalCategory.isCustom(goal.category)) {
        _isCustomCategory = true;
        _customCategoryController.text = goal.category;
      } else {
        _category = goal.category;
      }
      _color = goal.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.hedefAdiGirin);
      return;
    }
    final target = parseMoneyInput(_targetController.text);
    if (target == null || target <= 0) {
      setState(() => _error = context.l10n.gecerliHedefTutarGirin);
      return;
    }
    // Özel kip açıkken boş metin kaydedilirse kategori sessizce kaybolur ve
    // kart bayrak ikonuna düşerdi; kullanıcı bunu hiç anlamazdı.
    final customCategory = _customCategoryController.text.trim();
    if (_isCustomCategory && customCategory.isEmpty) {
      setState(() => _error = context.l10n.hedefKategoriOzelBos);
      return;
    }
    FocusScope.of(context).unfocus();

    final existing = widget.goalToEdit;
    widget.onSave(
      GoalEntity(
        id: existing?.id ?? UidGenerator.generateV7(),
        userId: widget.userId,
        walletId: widget.walletId,
        name: name,
        targetAmount: target,
        category: _isCustomCategory ? customCategory : _category,
        color: _color,
        createdAt: existing?.createdAt ?? DateTime.now(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InvestmentSheetHeader(
                  accent: _accent,
                  icon: Icons.flag_rounded,
                  title: _isEditing
                      ? context.l10n.hedefiDuzenle
                      : context.l10n.yeniHedefOlustur,
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
                      InvestmentFilledField(
                        controller: _nameController,
                        hint: context.l10n.hedefAdiHint,
                        icon: Icons.flag_rounded,
                        accent: _accent,
                        onChanged: _clearError,
                      ),
                      const SizedBox(height: 14),
                      InvestmentFilledField(
                        controller: _targetController,
                        hint: context.l10n.hedefTutariHint,
                        icon: Icons.savings_rounded,
                        accent: _accent,
                        onChanged: _clearError,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [AmountInputFormatter()],
                      ),
                      const SizedBox(height: 20),
                      InvestmentSectionLabel(context.l10n.hedefKategorisi),
                      const SizedBox(height: 10),
                      GoalCategorySelector(
                        selectedKey: _category,
                        customSelected: _isCustomCategory,
                        onChanged: (key) => setState(() {
                          _isCustomCategory = false;
                          _category = key ?? 'diger';
                        }),
                        onCustomSelected: () => setState(() {
                          _isCustomCategory = true;
                          _clearError();
                        }),
                        accentColor: _color,
                      ),
                      if (_isCustomCategory) ...[
                        const SizedBox(height: 10),
                        InvestmentFilledField(
                          controller: _customCategoryController,
                          hint: context.l10n.hedefKategoriOzelHint,
                          icon: Icons.edit_rounded,
                          accent: _accent,
                          onChanged: _clearError,
                          // Kategori adı hedef kartının başlığının üstünde
                          // tek satırda çiziliyor; sınırsız metin orayı
                          // kırpardı. Sayaç göstermeyen sınır (maxLength
                          // alanın altına "12/30" ekler) için formatter.
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(30),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      InvestmentSectionLabel(context.l10n.renkSecimi),
                      const SizedBox(height: 10),
                      InvestmentColorSelector(
                        options: _colorOptions,
                        selected: _color,
                        onSelected: (c) => setState(() => _color = c),
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
}
