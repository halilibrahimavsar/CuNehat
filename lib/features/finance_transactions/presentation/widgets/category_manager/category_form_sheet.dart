import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_error_text.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

/// Kategori ekleme/düzenleme sayfasını açar. Kaydedildiyse KAYDEDİLEN kategori
/// döner (iptal/hata → `null`): çağıran yalnız "değişti mi" bilgisiyle
/// yetinmek zorunda kalmasın — banka ekstresi incelemesi yeni kategoriyi
/// oluşturur oluşturmaz o satıra atamak zorunda.
///
/// [parentId] verilirse form alt kategori kipinde açılır (üst kategori önceden
/// seçili gelir); kullanıcı yine de değiştirebilir.
Future<CategoryEntity?> showCategoryForm({
  required BuildContext context,
  required bool isExpense,
  CategoryEntity? category,
  String? parentId,
}) async {
  return await showModalBottomSheet<CategoryEntity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CategoryFormSheet(
      isExpense: isExpense,
      category: category,
      parentId: parentId,
    ),
  );
}

class CategoryFormSheet extends StatefulWidget {
  final bool isExpense;
  final CategoryEntity? category;
  final String? parentId;

  const CategoryFormSheet({
    super.key,
    required this.isExpense,
    this.category,
    this.parentId,
  });

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();

  String _selectedIcon = 'category';
  bool _isLoading = false;

  /// Üst kategori seçicisinin seçenekleri: aynı türdeki ANA kategoriler.
  List<CategoryEntity> _roots = const [];
  String? _parentId;

  bool get _isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.category;
    if (existing != null) {
      _selectedIcon = existing.iconName;
      _nameController.text = existing.name;
      _parentId = existing.parentId;
    } else {
      _parentId = widget.parentId;
    }
    _loadRoots();
  }

  Future<void> _loadRoots() async {
    final all = await _categoryRepository.getCategories(widget.isExpense);
    if (!mounted) return;
    setState(() {
      // Kategori kendi üst kategorisi olamaz; alt kategorisi olanlar da
      // seçenek listesinde durur — kural ihlali kaydetmede anlaşılır bir
      // mesajla reddedilir.
      _roots =
          all.where((c) => c.isRoot && c.id != widget.category?.id).toList();

      // Seçili üst kategori artık listede yoksa (silinmiş ya da kendisi alt
      // kategori olmuş) seçim düşürülür: aksi halde açılır liste "üst yok"
      // gösterirken kayıt hâlâ eski üstle yazılırdı.
      if (_parentId != null && !_roots.any((c) => c.id == _parentId)) {
        _parentId = null;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isExpense ? Colors.red : Colors.green;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(color),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildParentField(),
                      const SizedBox(height: 24),
                      _buildIconSection(color),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(color),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_isEditMode ? Icons.edit : Icons.add, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditMode
                  ? context.l10n.kategoriDuzenle
                  : context.l10n.yeniKategori,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: context.l10n.labelKategoriAdi,
        hintText: context.l10n.hintOrnMarketKiraMaas,
        prefixIcon: const Icon(Icons.label),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      textCapitalization: TextCapitalization.words,
      maxLength: 20,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return context.l10n.kategoriAdiBosOlamaz;
        }
        if (value.trim().length < 2) {
          return context.l10n.enAz2KarakterOlmali;
        }
        // Ad tekilliği kardeş kapsamlıdır ve üst kategoriye bağlıdır; tek
        // doğru yeri veri katmanı (bkz. validateCategory). Burada tekrarlanmaz.
        return null;
      },
    );
  }

  /// Üst kategori seçici. Hiyerarşi iki seviyeyle sınırlı olduğundan seçenekler
  /// yalnız ANA kategorilerdir.
  Widget _buildParentField() {
    // Kökler yüklenmeden `initialValue` vermek DropdownButtonFormField'ı
    // "değer öğeler arasında yok" iddiasıyla düşürür (alt kategori ekleme
    // akışında parentId ilk kareden itibaren dolu gelir).
    final loadedValue = _roots.any((c) => c.id == _parentId) ? _parentId : null;

    return DropdownButtonFormField<String?>(
      initialValue: loadedValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: context.l10n.ustKategori,
        prefixIcon: const Icon(Icons.account_tree_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(context.l10n.ustKategoriYok),
        ),
        for (final root in _roots)
          DropdownMenuItem<String?>(
            value: root.id,
            child: Row(
              children: [
                Icon(AppIcons.getIconData(root.iconName), size: 18),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(root.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
      onChanged:
          _isLoading ? null : (value) => setState(() => _parentId = value),
    );
  }

  Widget _buildIconSection(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.ikonSecin,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showIconPicker,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    AppIcons.getIconData(_selectedIcon),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    context.l10n.ikonDegistirmekIcinDokun,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(context.l10n.iptal),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditMode ? context.l10n.kaydet : context.l10n.ekle),
            ),
          ),
        ],
      ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => IconPicker(
        selectedIcon: _selectedIcon,
        onIconSelected: (icon) {
          setState(() => _selectedIcon = icon);
          Navigator.pop(context);
        },
        iconColor: widget.isExpense ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();

      /// Sayfayı kapatırken geri verilecek kayıt (bkz. [showCategoryForm]).
      final CategoryEntity saved;

      if (_isEditMode) {
        // `id` DEĞİŞMEZ: deftere `tag`, bütçeye `walletId::categoryId` olarak
        // yazılıdır. Yeniden adlandırma yalnız `name`'i değiştirir.
        //
        // `clearParent` gerekli: alt kategoriyi ana kategoriye yükseltirken
        // `parentId: null` geçmek copyWith'in `?? this.parentId`'sine takılır.
        saved = widget.category!.copyWith(
          name: name,
          iconName: _selectedIcon,
          parentId: _parentId,
          clearParent: _parentId == null,
        );
        await _categoryRepository.updateCategory(saved);
      } else {
        // Kimliği repository üretir (UUID) — çağıran kimlik uydurmaz.
        saved = await _categoryRepository.addCategory(
          name: name,
          iconName: _selectedIcon,
          isExpense: widget.isExpense,
          parentId: _parentId,
        );
      }

      if (mounted) {
        final message = _isEditMode
            ? '✅ ${context.l10n.kategoriGuncellendi}'
            : '✅ ${context.l10n.kategoriOlusturuldu}';
        Navigator.pop(context, saved);
        // Bir sonraki frame'de göstermek için Future.microtask kullan
        Future.microtask(() {
          if (mounted) {
            AppMessenger.success(message);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppMessenger.error(categoryFailureMessage(context, e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
