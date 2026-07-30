import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart'
    show CashMovementTags;
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/category_label.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

Future<bool?> showCategoryForm({
  required BuildContext context,
  required bool isExpense,
  CategoryEntity? category,
}) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CategoryFormSheet(
      isExpense: isExpense,
      category: category,
    ),
  );
}

class CategoryFormSheet extends StatefulWidget {
  final bool isExpense;
  final CategoryEntity? category;

  const CategoryFormSheet({
    super.key,
    required this.isExpense,
    this.category,
  });

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final CategoryRepository _categoryService = getIt<CategoryRepository>();

  String _selectedIcon = 'category';
  bool _isLoading = false;
  bool _nameSeeded = false;

  /// Aynı türdeki mevcut kategoriler. Çift-ad koruması, kullanıcının GÖRDÜĞÜ
  /// adlar üzerinden çalışmalı; varsayılanların l10n karşılığı yalnız burada
  /// bilinir (veri katmanı ham `displayName ?? id` görür). Kaydet anında
  /// senkron harita kurabilmek için önden yüklenir.
  List<CategoryEntity> _siblings = const [];

  bool get _isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _selectedIcon = widget.category!.iconName;
    }
    _loadSiblings();
  }

  Future<void> _loadSiblings() async {
    final list = await _categoryService.getCategoriesWithDefaults(
      widget.isExpense,
    );
    if (!mounted) return;
    setState(() => _siblings = list);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ad alanı GÖRÜNEN adla dolar (id ile değil): varsayılanlarda id bir
    // anahtardır ve seçili dile göre çevrilir. l10n context gerektirdiğinden
    // initState'te değil burada, bir kez tohumlanır.
    if (_isEditMode && !_nameSeeded) {
      _nameSeeded = true;
      _nameController.text = context.categoryLabel(widget.category!);
    }
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
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
        fillColor: Colors.grey.shade50,
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
        // Sistem etiketleri (Borç Ödemesi, Transfer...) kategori adı olamaz;
        // bütçe/rapor `tag == categoryId` eşleşmesi otomatik hareketleri bu
        // kategoriye sayardı. Düzenlemede DEĞİŞMEYEN ad serbest kalır
        // (eski veriyle açılan kayıt ikon düzenlemesine kilitlenmesin).
        final unchanged = _isEditMode &&
            value.trim() == context.categoryLabel(widget.category!);
        if (!unchanged && CashMovementTags.isReserved(value)) {
          return context.l10n.kategoriAdiRezerve;
        }
        return null;
      },
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
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
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
                Text(
                  context.l10n.ikonDegistirmekIcinDokun,
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey.shade400),
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
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
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

  /// id → kullanıcının GÖRDÜĞÜ ad. `buildCategoryLabelMap` l10n'a çevrilmiş
  /// varsayılan adları da içerir; veri katmanı bunları kendi başına bilemez.
  Map<String, String> _displayLabels() =>
      buildCategoryLabelMap(context, _siblings);

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final sortOrder = DateTime.now().millisecondsSinceEpoch;

      if (_isEditMode) {
        // Yalnız GÖRÜNEN ad değişir; `id` sabit kalır. id'yi yeni ada
        // çevirmek hem kaydı bulunamaz yapıyordu (updateCategory kaydı id ile
        // arar) hem de o kategoriye yazılmış tüm işlemleri (`tag`) ve
        // bütçeleri (`walletId::categoryId`) yetim bırakırdı.
        //
        // Ad, id'nin l10n karşılığıyla AYNIYSA `displayName` null bırakılır:
        // alan görünen adla tohumlandığından (bkz. didChangeDependencies),
        // İngilizce'de yalnız ikonu değiştiren kullanıcı "Groceries"i kalıcı
        // olarak yazar ve kategori o dile kilitlenirdi — copyWith'in
        // `displayName ?? this.displayName`'i null'a dönüşe izin vermediği
        // için geri alınamayan bir kayıptı. Bu yüzden copyWith değil, alanı
        // açıkça kuran bir yapıcı kullanılır.
        final localizedDefault = context.translateCategory(widget.category!.id);
        final updatedCategory = CategoryEntity(
          id: widget.category!.id,
          displayName: name == localizedDefault ? null : name,
          iconName: _selectedIcon,
          isExpense: widget.category!.isExpense,
          isDefault: widget.category!.isDefault,
          sortOrder: widget.category!.sortOrder,
        );
        await _categoryService.updateCategory(
          updatedCategory,
          // Hedef ad kendi id'si altında taşınır: kullanıcının GİRDİĞİ ad
          // henüz kaydedilmemiş olsa da çakışma ona göre aranır.
          displayLabels: {..._displayLabels(), widget.category!.id: name},
        );
      } else {
        // Yeni kategoride kimlik bu an donar: id = ilk verilen ad.
        final newCategory = CategoryEntity(
          id: name,
          displayName: name,
          iconName: _selectedIcon,
          isExpense: widget.isExpense,
          isDefault: false,
          sortOrder: sortOrder,
        );
        await _categoryService.addCategory(
          newCategory,
          displayLabels: _displayLabels(),
        );
      }

      if (mounted) {
        final message = _isEditMode
            ? '✅ ${context.l10n.kategoriGuncellendi}'
            : '✅ ${context.l10n.kategoriOlusturuldu}';
        Navigator.pop(context, true);
        // Bir sonraki frame'de göstermek için Future.microtask kullan
        Future.microtask(() {
          if (mounted) {
            AppMessenger.success(message);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppMessenger.error(context.l10n.hataError(e.toString()));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
