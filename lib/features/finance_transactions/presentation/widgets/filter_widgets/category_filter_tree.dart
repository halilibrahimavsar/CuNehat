import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/utils/text_search.dart';
import 'package:cunehat/core/utils/tr_case.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:flutter/material.dart';

/// Filtre panelindeki kategori seçimi — hiyerarşik ve aranabilir.
///
/// Önceki hâli tüm kategorileri tek bir `Wrap` içinde düz çip olarak
/// diziyordu. Başlangıç paketi tek başına 43 gider kategorisi kuruyor; ekran
/// bir çip duvarına dönüşüyor, arama yok, ana/alt ilişkisi yalnız küçük bir ok
/// ikonuyla ima ediliyordu. Uygulamada zaten hiyerarşik bir seçici
/// (`CategoryPickerSheet`) varken filtre ayrı bir dil konuşuyordu.
///
/// Seçim kümesi GENİŞLETİLMİŞ tutulur (ana kategori seçilince çocukları da
/// kümeye girer), böylece süzgeç tarafı (`selectedCategories.contains(tag)`)
/// hiyerarşiyi bilmek zorunda kalmaz — bkz. [subtreeIds].
class CategoryFilterTree extends StatefulWidget {
  final List<CategoryEntity> incomeCategories;
  final List<CategoryEntity> expenseCategories;
  final Set<String> selected;
  final bool isLoading;

  /// Yeni seçim kümesi. Alt ağaç genişletmesi widget içinde yapılır.
  final ValueChanged<Set<String>> onChanged;

  /// Gelir ve gider grupları ayrı başlıklarla mı gösterilsin? (Karşılaştırma
  /// modunda ikisi de listelendiği için gerekli.)
  final bool showTypeHeaders;

  /// Grup başlıklarının vurgu rengi (tek türlü modlarda modun rengi).
  final Color accent;

  const CategoryFilterTree({
    super.key,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.selected,
    required this.isLoading,
    required this.onChanged,
    required this.showTypeHeaders,
    required this.accent,
  });

  @override
  State<CategoryFilterTree> createState() => _CategoryFilterTreeState();
}

class _CategoryFilterTreeState extends State<CategoryFilterTree> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// Elle açılmış ana kategoriler. Arama sırasında bu küme atlanır: eşleşen
  /// çocuğu olan her grup zaten açık gösterilir.
  final Set<String> _expanded = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSubtree(String id, List<CategoryEntity> pool) {
    final subtree = subtreeIds(id, pool);
    final next = Set<String>.from(widget.selected);
    // "Hepsi seçili mi" sorusuna göre karar ver: yalnız ana kategorinin
    // kendisine bakmak, çocukları elle seçilmiş bir grupta yanlış yöne
    // götürüyordu.
    if (subtree.every(next.contains)) {
      next.removeAll(subtree);
    } else {
      next.addAll(subtree);
    }
    widget.onChanged(next);
  }

  void _toggleLeaf(String id) {
    final next = Set<String>.from(widget.selected);
    if (!next.remove(id)) next.add(id);
    widget.onChanged(next);
  }

  bool _matches(CategoryEntity c) => matchesFolded(c.name, _query);

  /// Aramaya göre süzülmüş ağaç. Ana kategori eşleşirse çocuklarıyla birlikte
  /// kalır; yalnız çocuk eşleşirse ana kategori başlık olarak korunur ama
  /// yalnız eşleşen çocukları gösterilir.
  List<CategoryNode> _visibleTree(List<CategoryEntity> categories) {
    final tree = buildCategoryTree(categories);
    if (_query.isEmpty) return tree;

    final out = <CategoryNode>[];
    for (final node in tree) {
      if (_matches(node.category)) {
        out.add(node);
        continue;
      }
      final children = node.children.where(_matches).toList();
      if (children.isNotEmpty) {
        out.add((category: node.category, children: children));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    if (widget.incomeCategories.isEmpty && widget.expenseCategories.isEmpty) {
      return _notice(context, l10n.kategoriBulunamadi);
    }

    final incomeTree = _visibleTree(widget.incomeCategories);
    final expenseTree = _visibleTree(widget.expenseCategories);
    final isEmptyAfterSearch = incomeTree.isEmpty && expenseTree.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        const SizedBox(height: 10),
        _searchBox(context),
        const SizedBox(height: 4),
        if (isEmptyAfterSearch)
          _notice(context, l10n.txFilterCategoryNoMatch)
        else ...[
          if (expenseTree.isNotEmpty) ...[
            if (widget.showTypeHeaders)
              _typeHeader(
                  context, l10n.giderKategorileri, Icons.trending_down_rounded),
            ...expenseTree.map((n) => _group(n, widget.expenseCategories)),
          ],
          if (incomeTree.isNotEmpty) ...[
            if (widget.showTypeHeaders) ...[
              const SizedBox(height: 8),
              _typeHeader(
                  context, l10n.gelirKategorileri, Icons.trending_up_rounded),
            ],
            ...incomeTree.map((n) => _group(n, widget.incomeCategories)),
          ],
        ],
        if (widget.selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.txFilterSelectedCount(widget.selected.length),
              style: TextStyle(
                fontSize: 11.5,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.kATEGORIFiltresi,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
        if (widget.selected.isNotEmpty)
          TextButton(
            onPressed: () => widget.onChanged(const {}),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(context.l10n.temizle),
          ),
      ],
    );
  }

  Widget _searchBox(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = foldTr(v)),
      style: TextStyle(fontSize: 14, color: scheme.onSurface),
      decoration: InputDecoration(
        isDense: true,
        hintText: context.l10n.txFilterCategorySearchHint,
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 40),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
        filled: true,
        fillColor: scheme.onSurface.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }

  Widget _typeHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: widget.accent),
          const SizedBox(width: 6),
          Text(
            upperTr(title),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: widget.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(CategoryNode node, List<CategoryEntity> pool) {
    final root = node.category;
    final children = node.children;
    final subtree = subtreeIds(root.id, pool);
    final selectedInSubtree = subtree.where(widget.selected.contains).length;

    final bool? checkboxValue = selectedInSubtree == 0
        ? false
        : (selectedInSubtree == subtree.length ? true : null);

    // Arama sırasında eşleşen çocuklar her zaman görünür olmalı; kullanıcı
    // yazdığı şeyi bulmak için ayrıca grup açmak zorunda kalmasın.
    final isExpanded = children.isNotEmpty &&
        (_query.isNotEmpty || _expanded.contains(root.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(
          checkboxValue: checkboxValue,
          onCheckboxChanged: () => _toggleSubtree(root.id, pool),
          icon: AppIcons.getIconData(root.iconName),
          label: root.name,
          bold: true,
          trailing: children.isEmpty
              ? null
              : _expandAffordance(root.id, isExpanded, children.length,
                  selectedChildren: children
                      .where((c) => widget.selected.contains(c.id))
                      .length),
          onRowTap: children.isEmpty
              ? () => _toggleSubtree(root.id, pool)
              : () => setState(() {
                    if (!_expanded.remove(root.id)) _expanded.add(root.id);
                  }),
        ),
        if (isExpanded)
          for (final child in children)
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: _row(
                checkboxValue: widget.selected.contains(child.id),
                onCheckboxChanged: () => _toggleLeaf(child.id),
                icon: AppIcons.getIconData(child.iconName),
                label: child.name,
                bold: false,
                onRowTap: () => _toggleLeaf(child.id),
              ),
            ),
      ],
    );
  }

  Widget _expandAffordance(
    String id,
    bool isExpanded,
    int total, {
    required int selectedChildren,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.txFilterSubcategoryCount(selectedChildren, total),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selectedChildren > 0
                ? widget.accent
                : scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 2),
        Icon(
          isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          size: 20,
          color: scheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _row({
    required bool? checkboxValue,
    required VoidCallback onCheckboxChanged,
    required IconData icon,
    required String label,
    required bool bold,
    required VoidCallback onRowTap,
    Widget? trailing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onRowTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Checkbox(
              value: checkboxValue,
              tristate: true,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: widget.accent,
              onChanged: (_) => onCheckboxChanged(),
            ),
            const SizedBox(width: 6),
            Icon(
              icon,
              size: bold ? 18 : 16,
              color: checkboxValue == false
                  ? scheme.onSurfaceVariant.withValues(alpha: 0.7)
                  : widget.accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: bold ? 14 : 13.5,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _notice(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
