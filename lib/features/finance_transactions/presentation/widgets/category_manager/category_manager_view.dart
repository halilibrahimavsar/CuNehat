import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
import 'package:cunehat/core/shared/widgets/dismissable_widget.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/delete_category_usecase.dart';
import 'package:cunehat/features/finance_transactions/domain/wallet_category_scope.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_error_text.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_form_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_reassign_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_starter_pack_sheet.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/core/shared/layout/system_bar_insets.dart';
import 'package:cunehat/core/shared/widgets/scrollable_center.dart';
import 'package:flutter/material.dart';

/// Tek türün (gelir **ya da** gider) kategori yönetim gövdesi.
///
/// İki yerde kullanılır: kategoriler sayfası (yan menü) ve işlem formundaki
/// "Yönet" alt sayfası. Gövde ortak, çerçeve değil — sayfada AppBar + sekme,
/// alt sayfada tutamaç + kapat düğmesi var.
///
/// **Liste küreseldir, anahtar cüzdana aittir.** Burada o türün TÜM
/// kategorileri görünür; satırdaki anahtar yalnız [walletId] cüzdanında
/// görünüp görünmeyeceğini belirler (bkz. `wallet_category_scope.dart`).
/// Gizli bir kategoriyi yalnız görünür kategorileri listeleyen bir yüzeyden
/// geri açmak mümkün olmazdı — bu yüzden kürasyon yüzeyi filtresizdir.
class CategoryManagerView extends StatefulWidget {
  /// Görünürlük anahtarlarının yazılacağı cüzdan.
  final String walletId;

  final bool isExpense;

  /// Kategori listesi ya da görünürlük kümesi DEĞİŞTİĞİNDE tetiklenir —
  /// çağıran (form / sayfa) kendi listesini tazelesin diye.
  final VoidCallback? onChanged;

  /// Her başarılı yüklemeden sonra "bu cüzdanda görünür / toplam" sayacı.
  ///
  /// [onChanged]'dan AYRI: çerçevedeki başlık ilk açılışta da sayacı
  /// göstermeli, ama ilk yükleme bir değişiklik değildir — ikisi tek geri
  /// çağrıya bindirilseydi alt sayfa hiç dokunulmadan da "değişti" derdi.
  final void Function(int visible, int total)? onCounts;

  const CategoryManagerView({
    super.key,
    required this.walletId,
    required this.isExpense,
    this.onChanged,
    this.onCounts,
  });

  @override
  State<CategoryManagerView> createState() => CategoryManagerViewState();
}

class CategoryManagerViewState extends State<CategoryManagerView> {
  final CategoryRepository _categoryRepository = getIt<CategoryRepository>();
  final WalletCategoryService _walletCategories =
      getIt<WalletCategoryService>();

  List<CategoryNode> _tree = const [];

  /// Cüzdanın görünürlük kümesi; `null` = kürasyon yok → hepsi görünür.
  List<String>? _visibleIds;

  bool _isLoading = true;

  /// Görünürlük yazımı süren kategoriler — anahtar o süre kilitli.
  ///
  /// Yeniden giriş koruması: hızlı iki dokunuş aynı cüzdana iki eşzamanlı
  /// oku-değiştir-yaz başlatır ve biri diğerini bayat kümeyle ezer.
  final Set<String> _pending = {};

  /// Sıralama kipi: liste sürüklenebilir tutamaçlı satırlara döner; silme
  /// kaydırması ve görünürlük anahtarı o sırada yoktur (sürükleme ile
  /// kaydırarak silme aynı harekete talip olurdu).
  bool _reordering = false;

  /// Sıralama kipinde alt kategorileri açık olan kökler.
  final Set<String> _reorderExpanded = {};

  /// Yükleme kuşağı: `walletId` değişince yeni bir yükleme başlıyor ve ESKİ
  /// yüklemenin geç dönen sonucu yeni cüzdanın listesini ezebilirdi (tam da
  /// `didUpdateWidget`'ın çözdüğü hatanın yarış hâli).
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant CategoryManagerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.walletId == widget.walletId &&
        oldWidget.isExpense == widget.isExpense) {
      return;
    }
    // `didUpdateWidget` BUILD FAZIDIR: `load()`'un senkron `setState`'i
    // elemanı kendi build'i sırasında kirletir (bkz. `assert(!_dirty)` turu).
    // Alan doğrudan yazılıyor; devam eden build zaten yeni değeri görecek.
    _isLoading = true;
    _reload();
  }

  /// Dışarıdan (sayfanın "yeni kategori" düğmesi) da çağrılabilsin diye
  /// public.
  Future<void> load() async {
    setState(() => _isLoading = true);
    await _reload();
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    try {
      final categories =
          await _categoryRepository.getCategories(widget.isExpense);
      final visible = await _walletCategories.visibleIds(widget.walletId);
      if (!mounted || generation != _generation) return;
      setState(() {
        _tree = buildCategoryTree(categories);
        _visibleIds = visible;
        _isLoading = false;
      });
      widget.onCounts?.call(visibleCount, totalCount);
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() => _isLoading = false);
      AppMessenger.error(context.l10n.kategorilerYuklenemedi(e.toString()));
    }
  }

  int get rootCount => _tree.length;
  int get childCount =>
      _tree.fold(0, (sum, node) => sum + node.children.length);
  int get totalCount => rootCount + childCount;

  /// Bu cüzdanda görünür olan (bu türdeki) kategori sayısı.
  int get visibleCount {
    final ids = _visibleIds;
    if (ids == null) return totalCount;
    final set = ids.toSet();
    return _flat.where((c) => set.contains(c.id)).length;
  }

  List<CategoryEntity> get _flat =>
      _tree.expand((node) => [node.category, ...node.children]).toList();

  bool _isVisible(CategoryEntity category) =>
      _visibleIds?.contains(category.id) ?? true;

  /// Kürasyona hiç dokunulmamış cüzdanda "hiçbiri görünmüyor" durumu YOKTUR
  /// (`null` = hepsi görünür); uyarı yalnız gerçekten boş kümede anlamlı.
  bool get _walletHasNoVisibleCategory =>
      isCuratedWallet(_visibleIds) && visibleCount == 0 && totalCount > 0;

  void _notifyChanged() => widget.onChanged?.call();

  bool get isReordering => _reordering;

  /// Sıralanacak bir şey var mı: en az iki kök ya da iki çocuklu bir kök.
  bool get _canReorder =>
      _tree.length > 1 || _tree.any((node) => node.children.length > 1);

  void _setReordering(bool value) => setState(() {
        _reordering = value;
        if (!value) _reorderExpanded.clear();
      });

  /// Kökleri yeniden sıralar ve yazar. Liste önce YERELDE değişir (sürüklenen
  /// satır bırakıldığı yerde kalsın), yazım başarısız olursa depodan yeniden
  /// okunur. [newIndex] satır çıkarıldıktan SONRAKİ konumdur
  /// (`onReorderItem` sözleşmesi).
  Future<void> _reorderRoots(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final next = [..._tree];
    next.insert(newIndex, next.removeAt(oldIndex));
    setState(() => _tree = next);
    await _persistOrder([for (final node in next) node.category.id]);
  }

  Future<void> _reorderChildren(
      CategoryEntity root, int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final at = _tree.indexWhere((node) => node.category.id == root.id);
    if (at < 0) return;
    final children = [..._tree[at].children];
    children.insert(newIndex, children.removeAt(oldIndex));
    setState(() {
      _tree = [..._tree]..[at] =
          (category: _tree[at].category, children: children);
    });
    await _persistOrder([for (final c in children) c.id]);
  }

  Future<void> _persistOrder(List<String> orderedSiblingIds) async {
    try {
      await _categoryRepository.reorder(orderedSiblingIds);
      if (!mounted) return;
      // `sortOrder` değerleri değişti: yerel kopya depoyla eşitlensin
      // (spinner'sız — liste zaten doğru sırada duruyor).
      await _reload();
      _notifyChanged();
    } catch (e) {
      if (!mounted) return;
      AppMessenger.error(categoryFailureMessage(context, e));
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_tree.isEmpty) return _buildEmptyState();

    final color = widget.isExpense ? Colors.red : Colors.green;

    if (_reordering) return _buildReorderList(color);

    return RefreshIndicator(
      onRefresh: load,
      child: ListView.builder(
        // Sayfanın `FloatingActionButton.extended`'i (48dp) son kategoriyi
        // örtüyordu.
        padding: const EdgeInsets.all(16)
            .plusSystemBottom(context)
            .plusFabClearance(fabHeight: 48),
        // +1: en üstteki kapsam açıklaması. Liste öğesi olarak duruyor ki
        // sabit yükseklik yemesin — 0,85 ekranlık alt sayfada her dp sayılı.
        itemCount: _tree.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildScopeHint();
          final node = _tree[index - 1];
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

  Widget _buildScopeHint() {
    final cs = Theme.of(context).colorScheme;
    // Cüzdan adı bilinmiyorsa (WalletBloc ağaçta yok) ADSIZ cümle kullanılır.
    // `context.l10n.wallet`e düşmek "Cüzdan cüzdanında hangilerinin
    // görüneceğini belirler" üretiyordu — ölçüldü.
    final walletName = context.walletById(widget.walletId)?.name;
    final text = walletName == null
        ? context.l10n.kategoriCuzdanKapsamiAciklamaBu
        : context.l10n.kategoriCuzdanKapsamiAciklama(walletName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ),
              // Açıklamanın YANINDA, altında değil: ayrı bir satır 0,85
              // ekranlık alt sayfada bir kategori satırını aşağı itiyordu.
              if (_canReorder)
                TextButton.icon(
                  key: const ValueKey('category-reorder-start'),
                  onPressed: () => _setReordering(true),
                  icon: const Icon(Icons.swap_vert_rounded, size: 18),
                  label: Text(context.l10n.kategoriSirala),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          // Kategorisi olan ama bu cüzdanda hiçbiri açık olmayan durum:
          // başlangıç paketini atlayan yeni cüzdan. Seçici boş görüneceği
          // için sebebi burada söylenir, çözüm de yanında durur.
          if (_walletHasNoVisibleCategory) ...[
            const SizedBox(height: 10),
            Text(
              context.l10n.kategoriBuCuzdandaHicYok,
              style: TextStyle(fontSize: 12, color: cs.error),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: openStarterPack,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(context.l10n.oneriSetindenBasla),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================ sıralama kipi

  Widget _buildReorderList(Color color) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Icon(Icons.swap_vert_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.kategoriSiralaAciklama,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
              FilledButton.tonal(
                key: const ValueKey('category-reorder-done'),
                onPressed: () => _setReordering(false),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(context.l10n.tamam),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            // Tutamaç AÇIKÇA verilir: varsayılan (satırın tamamına uzun
            // basma) iç içe listede kök ile çocuğun sürüklemesini karıştırır.
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16)
                .plusSystemBottom(context)
                .plusFabClearance(fabHeight: 48),
            itemCount: _tree.length,
            onReorderItem: _reorderRoots,
            itemBuilder: (context, index) {
              final node = _tree[index];
              final root = node.category;
              final open = _reorderExpanded.contains(root.id);
              return Column(
                key: ValueKey('reorder-root-${root.id}'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _reorderTile(
                    root,
                    color,
                    index: index,
                    trailing: node.children.length < 2
                        ? null
                        : IconButton(
                            key: ValueKey('reorder-expand-${root.id}'),
                            tooltip: context.l10n
                                .starterPackChildCount(node.children.length),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() {
                              if (!_reorderExpanded.remove(root.id)) {
                                _reorderExpanded.add(root.id);
                              }
                            }),
                            icon: Icon(open
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded),
                          ),
                  ),
                  if (open)
                    ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(left: 24),
                      itemCount: node.children.length,
                      onReorderItem: (o, n) => _reorderChildren(root, o, n),
                      itemBuilder: (context, i) => KeyedSubtree(
                        key: ValueKey('reorder-child-${node.children[i].id}'),
                        child: _reorderTile(node.children[i], color, index: i),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _reorderTile(
    CategoryEntity category,
    Color color, {
    required int index,
    Widget? trailing,
  }) {
    final isChild = !category.isRoot;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        accent: color,
        padding: EdgeInsets.fromLTRB(4, isChild ? 2 : 4, 6, isChild ? 2 : 4),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Semantics(
                label: context.l10n.kategoriSiralaTutamac(category.name),
                child: SizedBox(
                  key: ValueKey('reorder-handle-${category.id}'),
                  width: 44,
                  height: 44,
                  child: Icon(Icons.drag_indicator_rounded,
                      color: cs.onSurfaceVariant),
                ),
              ),
            ),
            Icon(AppIcons.getIconData(category.iconName),
                color: color, size: isChild ? 18 : 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isChild ? FontWeight.w500 : FontWeight.w700,
                  fontSize: isChild ? 14 : 15,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return ScrollableCenter(
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
            onPressed: openStarterPack,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(context.l10n.oneriSetindenBasla),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    CategoryEntity category,
    Color color, {
    required int childCount,
  }) {
    final isChild = !category.isRoot;
    final visible = _isVisible(category);
    final cs = Theme.of(context).colorScheme;

    return DismissableWidget<CategoryEntity>(
      item: category,
      // UUID olduğu için ana ve alt kategoriler aynı listede güvenle tekil.
      dismissKey: category.id,
      onDelete: confirmDelete,
      onEdit: _editCategory,
      child: Padding(
        padding: EdgeInsets.only(left: isChild ? 24 : 0, bottom: 8),
        child: Opacity(
          // Gizli satır listede KALIR (geri açmanın tek yolu o), ama solgun
          // durur: "bu cüzdanda yok" bilgisi anahtarı okumadan da görünsün.
          opacity: visible ? 1 : 0.45,
          child: AppCard(
            accent: color,
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isChild ? 6 : 10,
            ),
            child: Row(
              children: [
                if (isChild)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.subdirectory_arrow_right,
                      size: 16,
                      color: cs.onSurfaceVariant,
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
                          fontWeight:
                              isChild ? FontWeight.w500 : FontWeight.w700,
                          fontSize: isChild ? 14 : 15,
                        ),
                      ),
                      if (childCount > 0)
                        Text(
                          context.l10n.starterPackChildCount(childCount),
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isChild)
                  IconButton(
                    tooltip: context.l10n.altKategoriEkle,
                    icon: const Icon(Icons.add, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => addCategory(parentId: category.id),
                  ),
                Semantics(
                  // Çıplak anahtar ekran okuyucuda "açık/kapalı"dan başka bir
                  // şey söylemiyor; satırın adı ayrı bir düğümde.
                  label: visible
                      ? context.l10n.kategoriBuCuzdandaGizle
                      : context.l10n.kategoriBuCuzdandaGoster,
                  child: Switch(
                    value: visible,
                    // 360dp'de satır dar: varsayılan dokunma hedefi (48dp)
                    // satıra 16dp daha ekliyor ve ad kutusunu ezmeye başlıyor.
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    // Yazım sürerken kilitli: ikinci dokunuş eşzamanlı bir
                    // oku-değiştir-yaz başlatıp birincisini ezerdi.
                    onChanged: _pending.contains(category.id)
                        ? null
                        : (value) => _toggleVisibility(category, value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Kategoriyi bu cüzdanda gösterir/gizler. Kategori SİLİNMEZ — başka
  /// cüzdanlarda ve raporlarda olduğu gibi kalır.
  ///
  /// **Tam yeniden yükleme YOK.** `load()` çağrılırken `_isLoading` true'ya
  /// dönüyor ve her dokunuşta liste yerini spinner'a bırakıyordu; üstelik
  /// kategori listesi hiç değişmediği hâlde yeniden okunuyordu. Yalnız
  /// görünürlük kümesi tazeleniyor — kural (kök kapanınca alt ağacın düşmesi)
  /// serviste, burada kopyalanmıyor.
  ///
  /// **Başarı bildirimi de yok:** kürasyon toplu bir iş; 48 kalemi düzenlemek
  /// 48 snackbar demekti. Anahtarın kendisi zaten geri bildirim; ekranda
  /// görünen tek şey HATA.
  Future<void> _toggleVisibility(CategoryEntity category, bool visible) async {
    if (_pending.contains(category.id)) return;
    // Cüzdan başta yakalanır: iş sürerken `widget.walletId` değişirse yazım
    // yine ESKİ cüzdana gitmeli, sonucu da yeni cüzdanın listesine yazılmamalı.
    final walletId = widget.walletId;
    final generation = _generation;
    setState(() => _pending.add(category.id));
    try {
      await _walletCategories.setVisibility(
        walletId: walletId,
        categoryId: category.id,
        visible: visible,
      );
      final refreshed = await _walletCategories.visibleIds(walletId);
      if (!mounted) return;
      if (generation != _generation) {
        setState(() => _pending.remove(category.id));
        return;
      }
      setState(() {
        _visibleIds = refreshed;
        _pending.remove(category.id);
      });
      widget.onCounts?.call(visibleCount, totalCount);
      _notifyChanged();
    } catch (e) {
      if (!mounted) return;
      // Yazım başarısız: anahtar ESKİ hâline dönsün. Servis artık `Left`
      // yutmuyor, fırlatıyor — eskiden burası sessizce "gizlendi" diyordu.
      setState(() => _pending.remove(category.id));
      AppMessenger.error(categoryFailureMessage(context, e));
    }
  }

  Future<void> openStarterPack() async {
    final touched =
        await showCategoryStarterPack(context, walletId: widget.walletId);
    if (touched != null && touched > 0) {
      await load();
      _notifyChanged();
    }
  }

  Future<void> addCategory({String? parentId}) async {
    final result = await showCategoryForm(
      context: context,
      isExpense: widget.isExpense,
      parentId: parentId,
      walletId: widget.walletId,
    );

    if (result != null) {
      await load();
      _notifyChanged();
    }
  }

  Future<void> _editCategory(CategoryEntity category) async {
    final result = await showCategoryForm(
      context: context,
      isExpense: widget.isExpense,
      category: category,
      walletId: widget.walletId,
    );

    if (result != null) {
      await load();
      _notifyChanged();
    }
  }

  /// Silme akışı: kullanımdaki kategori yetim veri bırakmadan silinir.
  ///
  /// İşlem varsa önce hedef sorulur; ana kategori siliniyorsa alt kategorileri
  /// ve onların işlemleri de aynı hedefe taşınır (bkz. [DeleteCategoryUseCase]).
  ///
  /// Silme KÜRESELDİR: kategori tüm cüzdanlardan kalkar. Yalnız bu cüzdandan
  /// çıkarmak isteyen kullanıcının aracı satırdaki anahtar.
  Future<bool> confirmDelete(CategoryEntity category) async {
    final all = _flat;
    final subtree = subtreeIds(category.id, all);
    final childCountOfDeleted = subtree.length - 1;

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
        childCount: childCountOfDeleted,
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
          if (childCountOfDeleted > 0)
            context.l10n.kategoriSilAltKategorilerDe(childCountOfDeleted),
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
          // Görünürlük onarımı (silinen kimlikleri düşür, taşıma hedefini
          // kat) `DeleteCategoryUseCase`'te — retag TÜM cüzdanlarda oluyor,
          // burada yalnız aktif cüzdanı düzeltmek eksik kalıyordu.
          load();
          _notifyChanged();
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
