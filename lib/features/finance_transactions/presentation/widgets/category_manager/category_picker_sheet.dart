import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/recent_categories_service.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/utils/text_search.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_form_sheet.dart';
import 'package:flutter/material.dart';

/// Ağaç yapısını gösteren, PAYLAŞILAN kategori seçici.
///
/// İşlem formu ve banka ekstresi incelemesi eskiden iki ayrı seçici
/// kullanıyordu; hiyerarşi gelince aynı ağaç mantığı iki yerde yazılacaktı.
///
/// **Düzen: iki sütun (master-detail), akordeon DEĞİL.** Eski sürüm her ana
/// kategoriyi bir `ExpansionTile` içinde sunuyordu ve alt kategori seçmek şuna
/// mal oluyordu: kaydır → anaya dokun → **liste 6 satır büyür, altı aşağı
/// kayar** → gerekirse tekrar kaydır → alta dokun. Ölçüldü (29 Ağu 2026):
/// gider tarafında 10 ana + 31 alt = 41 satır, ana başına ≤5 alt. Bu sayılarla
/// iki sütun neredeyse kaydırmasız sığıyor ve ana değiştirmek tek dokunuş —
/// reflow da geri gitme de yok.
///
/// Ayrıca **arama eklendi.** Filtre ağacında (`category_filter_tree.dart`)
/// arama zaten vardı, seçicide yoktu: aynı ağaç iki farklı yetenek
/// konuşuyordu. Aynı Türkçe-duyarlı katlama (`matchesFolded`) kullanılıyor.
///
/// Eski *"Doğrudan «Fatura» seç"* italik satırı kaldırıldı: ana kategorinin
/// kendisi sağ sütunun ilk satırıdır ve altında "ana kategori" açıklaması
/// taşır — aynı şeyi iki kez sunan geliştirici dili yerine tek satır.
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

/// Arama sonucu satırı: kategori + hangi bağlamda gösterileceği.
typedef _PickerRow = ({CategoryEntity category, String? caption});

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  final CategoryRepository _repository = getIt<CategoryRepository>();
  final RecentCategoriesService _recents = getIt<RecentCategoriesService>();
  final TextEditingController _searchController = TextEditingController();

  late bool _isExpense = widget.isExpense;
  List<CategoryNode> _tree = const [];
  List<CategoryEntity> _recent = const [];

  /// Sağ sütunda gösterilen ana kategori. Arama açıkken kullanılmaz.
  String? _activeRootId;
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final categories = await _repository.getCategories(_isExpense);
    if (!mounted) return;
    final tree = buildCategoryTree(categories);

    // Silinmiş kategorilerin kimlikleri önbellekte kalabilir; eşleşmeyenler
    // sessizce düşer, bu yüzden kategori silmede ayrı bir temizlik gerekmez.
    final byId = {for (final c in categories) c.id: c};
    final recent = <CategoryEntity>[
      for (final id in _recents.ids(_isExpense))
        if (byId[id] != null) byId[id]!,
    ];

    setState(() {
      _tree = tree;
      _recent = recent;
      _activeRootId = _initialRootId(tree);
      _loading = false;
    });
  }

  /// Seçimin TEK çıkışı: önbelleği tazeler, sonra kapatır. Satırlar, çipler ve
  /// yeni oluşturulan kategori hepsi buradan geçer — biri atlanırsa şerit
  /// sessizce eksik kalır.
  Future<void> _select(CategoryEntity category) async {
    await _recents.remember(category.id, _isExpense);
    if (!mounted) return;
    Navigator.pop(context, category);
  }

  /// Açılışta sağ sütunda hangi ana kategori duracak: seçili kategoriyi
  /// İÇEREN kök, yoksa ilk kök. Kullanıcı seçiciyi açtığında bulunduğu yeri
  /// görsün — aksi halde her açılışta yönünü yeniden bulması gerekir.
  String? _initialRootId(List<CategoryNode> tree) {
    if (tree.isEmpty) return null;
    final current = widget.currentId;
    if (current != null) {
      for (final node in tree) {
        if (node.category.id == current ||
            node.children.any((c) => c.id == current)) {
          return node.category.id;
        }
      }
    }
    return tree.first.category.id;
  }

  CategoryNode? get _activeNode {
    for (final node in _tree) {
      if (node.category.id == _activeRootId) return node;
    }
    return _tree.isEmpty ? null : _tree.first;
  }

  /// Arama sonuçları DÜZ liste: hiyerarşi kırıntıya iner. Ana kategoriler de
  /// aranır; çocuklar ana kategorilerinin adıyla etiketlenir ki aynı adlı iki
  /// alt kategori ("Su" hem Market hem Fatura altında) ayırt edilebilsin.
  List<_PickerRow> _searchRows(String anaLabel) {
    final rows = <_PickerRow>[];
    for (final node in _tree) {
      if (matchesFolded(node.category.name, _query)) {
        rows.add((category: node.category, caption: anaLabel));
      }
      for (final child in node.children) {
        if (matchesFolded(child.name, _query)) {
          rows.add((category: child, caption: node.category.name));
        }
      }
    }
    return rows;
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
        // Arama kutusu eklendiği için 0.75'ten yükseltildi: iki sütunun da
        // kaydırmasız sığması buna bağlı (10 kök × ~46dp).
        height: MediaQuery.of(context).size.height * 0.85,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _header(accent),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _searchBox(),
              ),
              // Arama açıkken gizlenir: sonuç listesi zaten kısayolun yerini
              // tutuyor ve şerit dikey alanı boşuna yiyor.
              if (_query.isEmpty && _recent.isNotEmpty) _recentStrip(accent),
              const Divider(height: 1),
              Expanded(child: _body(accent)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(Color accent) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_tree.isEmpty) return _notice(context.l10n.henuzKategoriYok);

    if (_query.isNotEmpty) {
      final rows = _searchRows(context.l10n.anaKategoriEtiketi);
      if (rows.isEmpty) return _notice(context.l10n.txFilterCategoryNoMatch);
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          for (final row in rows)
            _selectableRow(row.category, accent, caption: row.caption),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 42, child: _rootPane(accent)),
        const VerticalDivider(width: 1),
        Expanded(flex: 58, child: _childPane(accent)),
      ],
    );
  }

  /// Sol sütun: ana kategoriler. Dokunmak SEÇMEZ, yalnız sağ sütunu değiştirir
  /// — kural tek: seçim her zaman sağda yapılır. (Çocuksuz kökte doğrudan
  /// seçmek bir dokunuş kazandırırdı ama aynı jestin bazen seçip bazen
  /// seçmemesi öğrenilebilirliği bozar.)
  Widget _rootPane(Color accent) {
    final scheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: _tree.length,
      itemBuilder: (_, index) {
        final node = _tree[index];
        final root = node.category;
        final isActive = root.id == _activeRootId;
        final holdsSelection = widget.currentId == root.id ||
            node.children.any((c) => c.id == widget.currentId);

        // Ink (Container değil): InkWell dalgasını en yakın Material'a boyar,
        // renkli bir Container çocuk olarak araya girerse dalgayı örter.
        return Ink(
          color: isActive ? accent.withValues(alpha: 0.10) : null,
          child: InkWell(
            onTap: () => setState(() => _activeRootId = root.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              child: Row(
                children: [
                  Icon(
                    AppIcons.getIconData(root.iconName),
                    size: 20,
                    color: isActive ? accent : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      root.name,
                      // İki satıra sarar: kullanıcının kendi uzun adları
                      // ("Sağlık ve Kişisel Bakım") dar sütunda kırpılmasın.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? accent : null,
                      ),
                    ),
                  ),
                  if (holdsSelection)
                    Icon(Icons.check, size: 15, color: accent)
                  else if (node.children.isNotEmpty)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Sağ sütun: seçili ana kategorinin KENDİSİ (ilk satır) + alt kategorileri.
  Widget _childPane(Color accent) {
    final node = _activeNode;
    if (node == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: [
        _selectableRow(
          node.category,
          accent,
          caption: context.l10n.anaKategoriEtiketi,
        ),
        if (node.children.isNotEmpty)
          const Divider(height: 1, indent: 14, endIndent: 14),
        for (final child in node.children) _selectableRow(child, accent),
      ],
    );
  }

  Widget _selectableRow(
    CategoryEntity category,
    Color accent, {
    String? caption,
  }) {
    final selected = widget.currentId == category.id;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      visualDensity: VisualDensity.compact,
      leading: Icon(
        AppIcons.getIconData(category.iconName),
        size: 20,
        color: selected ? accent : scheme.onSurfaceVariant,
      ),
      title: Text(
        category.name,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? accent : null,
        ),
      ),
      subtitle: caption == null
          ? null
          : Text(
              caption,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
      trailing: selected ? Icon(Icons.check, color: accent, size: 18) : null,
      onTap: () => _select(category),
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

  Widget _searchBox() {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = foldTr(value)),
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

  /// Son kullanılanlar: gerçek kullanımda kategori seçimi çok tekrarlı, bu
  /// şerit vakaların çoğunu SIFIR gezinmeye indirir.
  Widget _recentStrip(Color accent) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recent.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final category = _recent[index];
          return ActionChip(
            visualDensity: VisualDensity.compact,
            avatar: Icon(
              AppIcons.getIconData(category.iconName),
              size: 16,
              color: accent,
            ),
            label: Text(category.name, style: const TextStyle(fontSize: 12)),
            onPressed: () => _select(category),
          );
        },
      ),
    );
  }

  Widget _notice(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );

  Future<void> _createCategory() async {
    final created = await showCategoryForm(
      context: context,
      isExpense: _isExpense,
    );
    if (created == null || !mounted) return;
    widget.onCreated?.call(created);
    // Oluşturulan kategori doğrudan seçilir: kullanıcı zaten onu atamak için
    // yaratıyor, listeye dönüp bir kez daha dokunması gereksiz.
    await _select(created);
  }
}
