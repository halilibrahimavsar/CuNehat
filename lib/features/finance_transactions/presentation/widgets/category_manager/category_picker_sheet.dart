import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_form_sheet.dart';
import 'package:flutter/material.dart';

/// Ağaç yapısını gösteren, PAYLAŞILAN kategori seçici.
///
/// İşlem formu ve banka ekstresi incelemesi eskiden iki ayrı seçici
/// kullanıyordu; hiyerarşi gelince aynı ağaç mantığı iki yerde yazılacaktı.
/// Tek yüzey: ana kategoriler liste, alt kategoriler açılır blok içinde.
///
/// [allowTypeSwitch] gelir/gider arasında geçişe izin verir (ekstre incelemesi
/// satırın türünü de değiştirebiliyor). [onCreated] yeni kategori oluşturulduğu
/// anda çağrılır — çağıranın önbelleğini tazelemesi için.
Future<CategoryEntity?> showCategoryPickerSheet({
  required BuildContext context,
  required bool isExpense,
  String? currentId,
  bool allowTypeSwitch = false,
  ValueChanged<CategoryEntity>? onCreated,
}) {
  return showModalBottomSheet<CategoryEntity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CategoryPickerSheet(
      isExpense: isExpense,
      currentId: currentId,
      allowTypeSwitch: allowTypeSwitch,
      onCreated: onCreated,
    ),
  );
}

class CategoryPickerSheet extends StatefulWidget {
  final bool isExpense;
  final String? currentId;
  final bool allowTypeSwitch;
  final ValueChanged<CategoryEntity>? onCreated;

  const CategoryPickerSheet({
    super.key,
    required this.isExpense,
    this.currentId,
    this.allowTypeSwitch = false,
    this.onCreated,
  });

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  final CategoryRepository _repository = getIt<CategoryRepository>();

  late bool _isExpense = widget.isExpense;
  List<CategoryNode> _tree = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final categories = await _repository.getCategories(_isExpense);
    if (!mounted) return;
    setState(() {
      _tree = buildCategoryTree(categories);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isExpense ? Colors.red : Colors.green;

    // Material (Container+BoxDecoration değil): ListTile mürekkebini en yakın
    // Material'a boyar; araya renkli bir DecoratedBox girerse Flutter
    // "ink splashes may be invisible" ile şikâyet eder.
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _header(accent),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _tree.isEmpty
                        ? _empty()
                        : ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: [
                              for (final node in _tree) _nodeTile(node, accent),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.labelKategori,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (widget.allowTypeSwitch)
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(context.l10n.menuExpense),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(context.l10n.menuIncome),
                ),
              ],
              selected: {_isExpense},
              onSelectionChanged: (value) {
                setState(() => _isExpense = value.first);
                _load();
              },
            ),
          IconButton(
            tooltip: context.l10n.yeniKategoriEkle,
            icon: Icon(Icons.add, color: accent),
            onPressed: _createCategory,
          ),
        ],
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context.l10n.henuzKategoriYok,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );

  Widget _nodeTile(CategoryNode node, Color accent) {
    final root = node.category;

    if (node.children.isEmpty) {
      return _leafTile(root, accent, indented: false);
    }

    // İşlem doğrudan ana kategoriye de yazılabildiği için ("Fatura" başlığı
    // seçilebilir bir kalemdir) açılır blok hem başlığı hem çocukları sunar.
    final containsSelection = widget.currentId == root.id ||
        node.children.any((c) => c.id == widget.currentId);

    return ExpansionTile(
      initiallyExpanded: containsSelection,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Icon(AppIcons.getIconData(root.iconName), color: accent),
      title: Text(
        root.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      children: [
        _leafTile(
          root,
          accent,
          indented: true,
          labelOverride: context.l10n.dogrudanKategoriSec(root.name),
        ),
        for (final child in node.children)
          _leafTile(child, accent, indented: true),
      ],
    );
  }

  Widget _leafTile(
    CategoryEntity category,
    Color accent, {
    required bool indented,
    String? labelOverride,
  }) {
    final selected = widget.currentId == category.id;

    return ListTile(
      contentPadding: EdgeInsets.only(left: indented ? 52 : 16, right: 16),
      leading: indented && labelOverride == null
          ? Icon(
              AppIcons.getIconData(category.iconName),
              size: 20,
              color: selected
                  ? accent
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : (indented
              ? null
              : Icon(AppIcons.getIconData(category.iconName), color: accent)),
      title: Text(
        labelOverride ?? category.name,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: selected ? accent : null,
          fontStyle: labelOverride != null ? FontStyle.italic : null,
        ),
      ),
      trailing: selected ? Icon(Icons.check, color: accent) : null,
      onTap: () => Navigator.pop(context, category),
    );
  }

  Future<void> _createCategory() async {
    final created = await showCategoryForm(
      context: context,
      isExpense: _isExpense,
    );
    if (created == null || !mounted) return;
    widget.onCreated?.call(created);
    // Oluşturulan kategori doğrudan seçilir: kullanıcı zaten onu atamak için
    // yaratıyor, listeye dönüp bir kez daha dokunması gereksiz.
    Navigator.pop(context, created);
  }
}
