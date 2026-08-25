import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/utils/tr_case.dart';
import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/install_starter_pack_usecase.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_error_text.dart';
import 'package:flutter/material.dart';

/// Başlangıç paketini gösterir; kurulan kategori sayısını döner (atlandıysa
/// `null`).
///
/// Kategori zorunlu bir alan olduğundan sıfır kategoriyle açılan uygulama
/// hiçbir işlem kaydedemez. Bu sayfa o boşluğu "varsayılan kategori" kavramı
/// olmadan doldurur: seçilen her şey normal, silinebilir kullanıcı
/// kategorisidir.
Future<int?> showCategoryStarterPack(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    // Kapatmak serbest: sayfanın kendi "Şimdilik atla" düğmesi var ve atlayan
    // kullanıcı kategori yöneticisinin boş durumundan geri dönebiliyor.
    // (`isDismissible: false` yalnız dışa dokunuşu engelliyor, sürükleme ve
    // geri jestini engellemiyordu — bayrak olduğundan güçlü görünüyordu.)
    backgroundColor: Colors.transparent,
    builder: (_) => const CategoryStarterPackSheet(),
  );
}

class CategoryStarterPackSheet extends StatefulWidget {
  const CategoryStarterPackSheet({super.key});

  @override
  State<CategoryStarterPackSheet> createState() =>
      _CategoryStarterPackSheetState();
}

class _CategoryStarterPackSheetState extends State<CategoryStarterPackSheet> {
  /// Seçili grupların anahtarı: `"gider|Fatura"`. Ad tür içinde tekil olduğu
  /// için bileşik anahtar yeterli.
  final Set<String> _selected = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Kullanıcının çoğu için doğru cevap "hepsi": boş listeyle başlamak
    // sayfanın amacını (hızlı kurulum) baştan bozar.
    _selectAll();
  }

  String _keyOf(StarterPackGroup g, bool isExpense) =>
      '${isExpense ? 'gider' : 'gelir'}|${g.name}';

  void _selectAll() {
    _selected
      ..clear()
      ..addAll([
        for (final g in CategoryStarterPack.expense) _keyOf(g, true),
        for (final g in CategoryStarterPack.income) _keyOf(g, false),
      ]);
  }

  Iterable<StarterPackSelection> get _selection sync* {
    for (final g in CategoryStarterPack.expense) {
      if (_selected.contains(_keyOf(g, true))) {
        yield (group: g, isExpense: true);
      }
    }
    for (final g in CategoryStarterPack.income) {
      if (_selected.contains(_keyOf(g, false))) {
        yield (group: g, isExpense: false);
      }
    }
  }

  int get _totalCount =>
      _selection.fold(0, (sum, s) => sum + CategoryStarterPack.sizeOf(s.group));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _header(cs),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                children: [
                  _sectionLabel(context.l10n.menuExpense, cs),
                  for (final g in CategoryStarterPack.expense)
                    _groupTile(g, isExpense: true),
                  const SizedBox(height: 12),
                  _sectionLabel(context.l10n.menuIncome, cs),
                  for (final g in CategoryStarterPack.income)
                    _groupTile(g, isExpense: false),
                ],
              ),
            ),
            const Divider(height: 1),
            _actions(cs),
          ],
        ),
      ),
    );
  }

  Widget _header(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            context.l10n.starterPackTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.starterPackSubtitle,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _isSaving
                  ? null
                  : () => setState(() {
                        if (_selected.isEmpty) {
                          _selectAll();
                        } else {
                          _selected.clear();
                        }
                      }),
              icon: Icon(
                _selected.isEmpty
                    ? Icons.select_all_rounded
                    : Icons.deselect_rounded,
                size: 18,
              ),
              label: Text(
                _selected.isEmpty
                    ? context.l10n.starterPackSelectAll
                    : context.l10n.starterPackClearAll,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, ColorScheme cs) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
        child: Text(
          upperTr(text),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: cs.onSurfaceVariant,
          ),
        ),
      );

  Widget _groupTile(StarterPackGroup group, {required bool isExpense}) {
    final key = _keyOf(group, isExpense);
    final checked = _selected.contains(key);
    final accent = isExpense ? Colors.red : Colors.green;

    return CheckboxListTile(
      value: checked,
      onChanged: _isSaving
          ? null
          : (value) => setState(() {
                if (value ?? false) {
                  _selected.add(key);
                } else {
                  _selected.remove(key);
                }
              }),
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: Icon(AppIcons.getIconData(group.iconName), color: accent),
      title: Text(
        group.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: group.children.isEmpty
          ? null
          : Text(
              group.children.map((c) => c.name).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
    );
  }

  Widget _actions(ColorScheme cs) {
    final count = _totalCount;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: Text(context.l10n.starterPackSkip),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _isSaving || count == 0 ? null : _install,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(context.l10n.starterPackCreate(count)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _install() async {
    setState(() => _isSaving = true);
    try {
      final created =
          await getIt<InstallStarterPackUseCase>()(_selection.toList());
      if (!mounted) return;
      final message = context.l10n.starterPackCreated(created);
      Navigator.pop(context, created);
      Future.microtask(() => AppMessenger.success('✅ $message'));
    } catch (e) {
      if (mounted) {
        AppMessenger.error(categoryFailureMessage(context, e));
        setState(() => _isSaving = false);
      }
    }
  }
}
