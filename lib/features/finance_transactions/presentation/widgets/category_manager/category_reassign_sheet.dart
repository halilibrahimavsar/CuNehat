import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:flutter/material.dart';

/// Silinecek kategorideki işlemlerin taşınacağı hedefi sorar.
///
/// Kategori zorunlu bir alandır: silinen kategorinin işlemleri kategorisiz
/// bırakılamaz, bir hedef seçilmeden silme yapılmaz. Seçim yapılmadan
/// kapatılırsa `null` döner ve silme iptal edilir.
Future<CategoryEntity?> showCategoryReassignSheet({
  required BuildContext context,
  required CategoryEntity deleted,
  required int usageCount,
  required int childCount,
  required List<CategoryEntity> candidates,
}) {
  return showModalBottomSheet<CategoryEntity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CategoryReassignSheet(
      deleted: deleted,
      usageCount: usageCount,
      childCount: childCount,
      candidates: candidates,
    ),
  );
}

class _CategoryReassignSheet extends StatelessWidget {
  final CategoryEntity deleted;
  final int usageCount;
  final int childCount;
  final List<CategoryEntity> candidates;

  const _CategoryReassignSheet({
    required this.deleted,
    required this.usageCount,
    required this.childCount,
    required this.candidates,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Material: ListTile mürekkebini en yakın Material'a boyar; araya renkli
    // bir DecoratedBox girerse Flutter uyarı fırlatır.
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.kategoriSilTasiTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // İmza (name, count) — sıra ters verilirse mesaj
                      // "7 kategorisinde Elektrik işlem var" olur.
                      context.l10n
                          .kategoriSilTasiMessage(deleted.name, usageCount),
                      style:
                          TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    if (childCount > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.kategoriSilAltKategorilerDe(childCount),
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final c = candidates[index];
                    return ListTile(
                      // Alt kategoriler girintili görünür ki hangi ana kategoriye
                      // taşındığı seçim anında belli olsun.
                      contentPadding: EdgeInsets.only(
                        left: c.isRoot ? 20 : 44,
                        right: 20,
                      ),
                      leading: Icon(AppIcons.getIconData(c.iconName)),
                      title: Text(c.name),
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.iptal),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
