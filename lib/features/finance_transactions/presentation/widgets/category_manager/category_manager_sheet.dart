import 'package:cunehat/core/shared/widgets/dismissable_widget.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:cunehat/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_form_sheet.dart';
import 'package:flutter/material.dart';

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

class CategoryManagerSheet extends StatefulWidget {
  final bool isExpense;

  const CategoryManagerSheet({
    super.key,
    required this.isExpense,
  });

  @override
  State<CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<CategoryManagerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CategoryRepository _categoryService = getIt<CategoryRepository>();
  List<CategoryEntity> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _categoryService.getCategories(widget.isExpense);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        IboSnackbar.showError(
            context, context.l10n.kategorilerYuklenemedi(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isExpense ? Colors.red : Colors.green;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(color),
          _buildTabs(color),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryList(false),
                _buildCategoryList(true),
              ],
            ),
          ),
          _buildAddButton(color),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
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
                      context.l10n.categoriesWhereCC(
                        _categories.where((c) => !c.isDefault).length,
                        _categories.where((c) => c.isDefault).length,
                      ),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(Color color) {
    return TabBar(
      controller: _tabController,
      labelColor: color,
      unselectedLabelColor: Colors.grey,
      indicatorColor: color,
      tabs: [
        Tab(text: context.l10n.ozelKategoriler),
        Tab(text: context.l10n.varsayilanKategoriler),
      ],
    );
  }

  Widget _buildCategoryList(bool showDefaults) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredCategories =
        _categories.where((c) => c.isDefault == showDefaults).toList();

    if (filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showDefaults ? Icons.lock_outline : Icons.category_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              showDefaults
                  ? context.l10n.varsayilanKategoriYok
                  : context.l10n.henuzOzelKategoriYok,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            if (!showDefaults) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.asagidakiButondanEkleyebilirsiniz,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredCategories.length,
        itemBuilder: (context, index) {
          final category = filteredCategories[index];
          if (!category.isDefault) {
            return DismissableWidget<CategoryEntity>(
              item: category,
              dismissKey: category.id,
              onDelete: (item) => _confirmDelete(item),
              onEdit: (item) => _editCategory(item),
              child: _buildCategoryCard(category),
            );
          }
          return _buildCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(CategoryEntity category) {
    final color = widget.isExpense ? Colors.red : Colors.green;
    final isDefaultTab = _tabController.index == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: category.isDefault
              ? Colors.grey.shade200
              : color.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            AppIcons.getIconData(category.iconName),
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          category.id,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: category.isDefault && !isDefaultTab
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.varsayilan,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : category.isDefault && isDefaultTab
                ? IconButton(
                    icon:
                        Icon(Icons.edit, size: 20, color: Colors.blue.shade700),
                    onPressed: () => _editCategory(category),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                    ),
                  )
                : const Icon(Icons.more_horiz),
      ),
    );
  }

  Widget _buildAddButton(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addCategory,
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

  Future<void> _addCategory() async {
    final result = await showCategoryForm(
      context: context,
      isExpense: widget.isExpense,
    );

    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _editCategory(CategoryEntity category) async {
    final result = await showCategoryForm(
      context: context,
      isExpense: widget.isExpense,
      category: category,
    );

    if (result == true) {
      _loadCategories();
    }
  }

  Future<bool> _confirmDelete(CategoryEntity category) async {
    final confirmed = await IboDialog.showConfirmation(
      context,
      context.l10n.kategoriSilTitle,
      context.l10n.kategoriSilConfirmMessage(category.id),
      confirmText: context.l10n.sil,
      cancelText: context.l10n.iptal,
      style: IboDialogStyle(
        confirmButtonStyle: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _categoryService.deleteCategory(category.id, widget.isExpense);
        if (widget.isExpense) {
          // Kategorinin bütçesi kalmasın (hayalet bütçe önlemi);
          // bütçeler cüzdan bazlı olduğundan tüm cüzdanlarda temizlenir.
          await getIt<DeleteBudgetsForCategoryUsecase>()(category.id);
        }
        _loadCategories();
        if (mounted) {
          IboSnackbar.showSuccess(
              context, '🗑️ ${context.l10n.kategoriSilindi}');
        }
        return true;
      } catch (e) {
        if (mounted) {
          IboSnackbar.showError(context, context.l10n.hataError(e.toString()));
        }
        return false;
      }
    }
    return false;
  }
}
