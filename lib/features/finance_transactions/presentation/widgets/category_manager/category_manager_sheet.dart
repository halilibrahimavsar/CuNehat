import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_manager_view.dart';
import 'package:flutter/material.dart';

/// İşlem formundan açılan kategori yönetimi; değişiklik olduysa `true` döner.
///
/// Gövde [CategoryManagerView] ile ortak — yan menüdeki kategoriler sayfası da
/// aynı listeyi kullanır. Buradaki fark yalnız çerçeve: form üstünde tek türle
/// (formun türüyle) açılır, sayfada iki sekme vardır.
Future<bool?> showCategoryManager({
  required BuildContext context,
  required String walletId,
  required bool isExpense,
}) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        CategoryManagerSheet(walletId: walletId, isExpense: isExpense),
  );
}

/// Kategori yönetimi — iki seviyeli ağaç, satır başına cüzdan görünürlüğü.
class CategoryManagerSheet extends StatefulWidget {
  final String walletId;
  final bool isExpense;

  const CategoryManagerSheet({
    super.key,
    required this.walletId,
    required this.isExpense,
  });

  @override
  State<CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<CategoryManagerSheet> {
  final GlobalKey<CategoryManagerViewState> _viewKey = GlobalKey();

  /// Sayfa kapanırken çağırana "değişiklik oldu" bilgisi döner.
  bool _changed = false;

  int _visibleCount = 0;
  int _totalCount = 0;

  void _onChanged() => _changed = true;

  void _onCounts(int visible, int total) {
    if (!mounted) return;
    if (visible == _visibleCount && total == _totalCount) return;
    setState(() {
      _visibleCount = visible;
      _totalCount = total;
    });
  }

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
            Expanded(
              child: CategoryManagerView(
                key: _viewKey,
                walletId: widget.walletId,
                isExpense: widget.isExpense,
                onChanged: _onChanged,
                onCounts: _onCounts,
              ),
            ),
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
                      // Sayaç artık "kaç kategori var" değil "kaçı BU
                      // CÜZDANDA görünür": listedeki satırların bir kısmı
                      // başka cüzdanlara ait olabilir.
                      context.l10n
                          .kategoriGorunurSayisi(_visibleCount, _totalCount),
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
            onPressed: () => _viewKey.currentState?.addCategory(),
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
}
