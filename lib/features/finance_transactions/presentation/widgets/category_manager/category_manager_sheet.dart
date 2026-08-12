import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/dismissable_widget.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/delete_category_usecase.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_error_text.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_form_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_reassign_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_starter_pack_sheet.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

Future<bool?> showCategoryManager({
  required BuildContext context,
  required bool isExpense,
}) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CategoryManagerSheet(isExpense: isExpense),
  );
}

/// Kategori yönetimi — iki seviyeli ağaç.
///
/// Eskiden "Özel / Varsayılan" iki sekmesi vardı; varsayılan kategori kavramı
/// kalkınca ayrım da kalktı. Şimdi tek liste: ana kategoriler ve altlarında
/// girintili alt kategorileri.
class CategoryManagerSheet extends StatefulWidget {
  final bool isExpense;

  const CategoryManagerSheet({
    super.key,
    required this.isExpense,
  });

  @override
  State<CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<CategoryManagerSheet> {
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();
  List<CategoryNode> _tree = const [];
  bool _isLoading = true;

  /// Sayfa kapanırken çağırana "değişiklik oldu" bilgisi döner.
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories =
          await _categoryRepository.getCategories(widget.isExpense);
      if (!mounted) return;
      setState(() {
        _tree = buildCategoryTree(categories);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppMessenger.error(context.l10n.kategorilerYuklenemedi(e.toString()));
    }
  }

  int get _rootCount => _tree.length;
  int get _childCount =>
      _tree.fold(0, (sum, node) => sum + node.children.length);

  @override
  Widget build(BuildContext context) {
    final color = widget.isExpense ? Colors.red : Colors.green;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(color),
            Expanded(child: _buildBody(color)),
            _buildAddButton(color),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: .18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.isExpense ? Icons.trending_down : Icons.trending_up,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isExpense
                          ? context.l10n.giderKategorileri
                          : context.l10n.gelirKategorileri,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      context.l10n.kategoriSayisiOzeti(_rootCount, _childCount),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, _changed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Color color) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_tree.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tree.length,
        itemBuilder: (context, index) {
          final node = _tree[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildRow(node.category, color, childCount: node.children.length),
              for (final child in node.children)
                _buildRow(child, color, childCount: 0),
              const SizedBox(height: 4),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              context.l10n.henuzKategoriYok,
              style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.asagidakiButondanEkleyebilirsiniz,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            // Başlangıç paketini atlayan kullanıcının geri dönebileceği tek yol.
            FilledButton.tonalIcon(
              onPressed: _openStarterPack,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(context.l10n.oneriSetindenBasla),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    CategoryEntity category,
    Color color, {
    required int childCount,
  }) {
    final isChild = !category.isRoot;

    return DismissableWidget<CategoryEntity>(
      item: category,
      // UUID olduğu için ana ve alt kategoriler aynı listede güvenle tekil.
      dismissKey: category.id,
      onDelete: _confirmDelete,
      onEdit: _editCategory,
      child: Padding(
        padding: EdgeInsets.only(left: isChild ? 24 : 0, bottom: 8),
        child: AppCard(
          accent: color,
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: isChild ? 10 : 14,
          ),
          child: Row(
            children: [
              if (isChild)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.subdirectory_arrow_right,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              Container(
                width: isChild ? 34 : 44,
                height: isChild ? 34 : 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AppIcons.getIconData(category.iconName),
                  color: color,
                  size: isChild ? 18 : 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isChild ? FontWeight.w500 : FontWeight.w700,
                        fontSize: isChild ? 14 : 15,
                      ),
                    ),
                    if (childCount > 0)
                      Text(
                        context.l10n.starterPackChildCount(childCount),
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isChild)
                IconButton(
                  tooltip: context.l10n.altKategoriEkle,
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _addCategory(parentId: category.id),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _addCategory(),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.yeniKategoriEkle),
          ),
        ),
      ),
    );
  }

  Future<void> _openStarterPack() async {
    final created = await showCategoryStarterPack(context);
    if (created != null && created > 0) {
      _changed = true;
      await _loadCategories();
    }
  }

  Future<void> _addCategory({String? parentId}) async {
    final result = await showCategoryForm(
      context: context,
      isExpense: widget.isExpense,
      parentId: parentId,
    );

    if (result != null) {
      _changed = true;
      await _loadCategories();
    }
  }

  Future<void> _editCategory(CategoryEntity category) async {
    final result = await showCategoryForm(
      context: context,
      isExpense: widget.isExpense,
      category: category,
    );

    if (result != null) {
      _changed = true;
      await _loadCategories();
    }
  }

  /// Silme akışı: kullanımdaki kategori yetim veri bırakmadan silinir.
  ///
  /// İşlem varsa önce hedef sorulur; ana kategori siliniyorsa alt kategorileri
  /// ve onların işlemleri de aynı hedefe taşınır (bkz. [DeleteCategoryUseCase]).
  Future<bool> _confirmDelete(CategoryEntity category) async {
    final all = _tree
        .expand((node) => [node.category, ...node.children])
        .toList(growable: false);
    final subtree = subtreeIds(category.id, all);
    final childCount = subtree.length - 1;

    final countResult =
        await getIt<TransactionsRepository>().countByTags(subtree);
    if (!mounted) return false;

    var usageCount = countResult.fold((failure) {
      AppMessenger.error(failure.message);
      return -1;
    }, (count) => count);
    if (usageCount < 0) return false;

    // Düzenli işlem şablonları da SAYILIR. Şablon onaylandığında etiketini
    // olduğu gibi deftere yazar (`ApproveRecurringTransactionUsecase`); hiç
    // işlemi olmayan ama şablonu olan bir kategori hedefsiz silinseydi şablon
    // her ay silinmiş kimliği geri diriltirdi.
    final templatesResult =
        await getIt<RecurringTransactionRepository>().getAllTemplates();
    if (!mounted) return false;
    usageCount += templatesResult.fold(
      (_) => 0,
      (templates) => templates.where((t) => subtree.contains(t.tag)).length,
    );

    String? reassignToId;

    if (usageCount > 0) {
      final candidates =
          all.where((c) => !subtree.contains(c.id)).toList(growable: false);
      if (candidates.isEmpty) {
        AppMessenger.error(context.l10n.kategoriSilHedefYok);
        return false;
      }

      final target = await showCategoryReassignSheet(
        context: context,
        deleted: category,
        usageCount: usageCount,
        childCount: childCount,
        candidates: candidates,
      );
      if (target == null) return false;
      reassignToId = target.id;
    } else {
      if (!mounted) return false;
      final confirmed = await ConfirmDialog.show(
        context,
        title: context.l10n.kategoriSilTitle,
        message: [
          context.l10n.kategoriSilConfirmMessage(category.name),
          if (childCount > 0)
            context.l10n.kategoriSilAltKategorilerDe(childCount),
        ].join('\n\n'),
        confirmText: context.l10n.sil,
        danger: true,
      );
      if (!confirmed) return false;
    }

    try {
      final result = await getIt<DeleteCategoryUseCase>()(
        categoryId: category.id,
        reassignToId: reassignToId,
      );
      if (!mounted) return false;

      return result.fold(
        (failure) {
          AppMessenger.error(failure.message);
          return false;
        },
        (_) {
          _changed = true;
          _loadCategories();
          AppMessenger.success('🗑️ ${context.l10n.kategoriSilindi}');
          return true;
        },
      );
    } catch (e) {
      if (mounted) {
        AppMessenger.error(categoryFailureMessage(context, e));
      }
      return false;
    }
  }
}
