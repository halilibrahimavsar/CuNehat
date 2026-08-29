import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/bank_import/data/description_grouper.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/bank_import/presentation/import_category_labels.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_picker_sheet.dart';

/// Benzer açıklamalı satırları gruplayıp gruba TEK dokunuşla kategori atatan
/// sayfa.
///
/// Neden ayrı bir yüzey: arama+filtre ile toplu atama, kullanıcının aranacak
/// metni ÖNCEDEN bilmesini gerektiriyor ("MIGROS" yaz, süz, ata). Gerçek bir
/// ekstrede 85 satır ve onlarca farklı üye işyeri var; hangi adların tekrar
/// ettiğini kullanıcı ancak listeyi baştan sona okuyarak keşfedebiliyordu.
/// Burada tekrarları uygulama buluyor ve en kalabalık grup en üstte duruyor.
///
/// Kapsam anahtarı bilinçli: "yalnız kategorisiz" varsayılan, çünkü hedef
/// kalan boşlukları kapatmak. "Tümü" kipinde ise doğru tahmin edilmiş satırlar
/// da görünür ve gruba bakıp toptan düzeltmek mümkün olur — ama bu kipte
/// atamanın kategorili satırların ÜZERİNE yazacağı sayaçtan görülür.
Future<void> showSimilarGroupSheet(BuildContext context) {
  final cubit = context.read<BankImportCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider<BankImportCubit>.value(
      value: cubit,
      child: const SimilarGroupSheet(),
    ),
  );
}

class SimilarGroupSheet extends StatefulWidget {
  const SimilarGroupSheet({super.key});

  @override
  State<SimilarGroupSheet> createState() => _SimilarGroupSheetState();
}

class _SimilarGroupSheetState extends State<SimilarGroupSheet> {
  /// `null` → henüz karar verilmedi; ilk çizimde duruma göre seçilir
  /// (kategorisiz satır varsa oradan başlanır).
  bool? _onlyUncategorized;

  BankImportCubit get _cubit => context.read<BankImportCubit>();

  ({List<CategoryEntity> expense, List<CategoryEntity> income})? _labelKey;
  Map<String, String> _expenseLabels = const {};
  Map<String, String> _incomeLabels = const {};

  /// `id → gösterilecek kategori adı`, TÜR BAŞINA.
  ///
  /// Tür başına olması şart: inceleme listesi de (`BankImportReviewView
  /// ._categoryLabels`) böyle kuruyor. Gelir ve gideri tek listede saymak
  /// belirsizlik sayımını değiştirir ve aynı kategori bir ekranda "Su",
  /// diğerinde "Fatura › Su" görünürdü.
  ///
  /// Liste kimliğine göre önbelleklenir: kategoriler yalnız inceleme sırasında
  /// yeni kategori kurulunca değişiyor, her grup satırı için yeniden kurmak
  /// boşuna iş (aynı gerekçe inceleme listesinde de yazılı).
  Map<String, String> _labelsFor(BankImportReview state, bool isIncome) {
    if (_labelKey?.expense != state.expenseCategories ||
        _labelKey?.income != state.incomeCategories) {
      _labelKey =
          (expense: state.expenseCategories, income: state.incomeCategories);
      _expenseLabels = buildImportCategoryLabels(state.expenseCategories);
      _incomeLabels = buildImportCategoryLabels(state.incomeCategories);
    }
    return isIncome ? _incomeLabels : _expenseLabels;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: SafeArea(
          top: false,
          child: BlocBuilder<BankImportCubit, BankImportState>(
            builder: (context, state) {
              if (state is! BankImportReview) return const SizedBox.shrink();
              return _content(context, state);
            },
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, BankImportReview state) {
    // Kategorisiz satır kalmadıysa "yalnız kategorisiz" kipi sessizce "tümü"ne
    // döner; aksi halde kullanıcı sayfayı boş görüp neden hiçbir grup
    // olmadığını anlamıyor (aynı davranış inceleme listesinin süzgecinde de
    // var: `BankImportReviewView._effectiveFilter`).
    final onlyUncategorized = (_onlyUncategorized ??=
            state.uncategorizedCount > 0) &&
        state.uncategorizedCount > 0;
    final scope = onlyUncategorized
        ? [
            for (var i = 0; i < state.drafts.length; i++)
              if (state.drafts[i].categoryId == null) i,
          ]
        : null;
    final groups = groupSimilarDrafts(state.drafts, scope: scope);

    return Column(
      children: [
        _header(context, state, onlyUncategorized: onlyUncategorized),
        const Divider(height: 1),
        Expanded(
          child: groups.isEmpty
              ? _empty(context)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (_, i) => _groupTile(context, state, groups[i]),
                ),
        ),
      ],
    );
  }

  Widget _header(
    BuildContext context,
    BankImportReview state, {
    required bool onlyUncategorized,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.bankImportGroupSimilarTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            context.l10n.bankImportGroupSimilarHint,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          // `Row` DEĞİL `Wrap`: iki çipin Türkçe etiketi dar telefonda satıra
          // sığmıyor (ölçüldü: 360dp'de 29px taşma) ve metin ölçeği büyütülünce
          // durum kötüleşir. Yatay kaydırma yerine alt satıra sarılıyor —
          // ikinci çip ekran dışında saklanmasın.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _scopeChip(
                context,
                label: context.l10n.bankImportGroupScopeUncategorized,
                value: true,
                selected: onlyUncategorized,
                enabled: state.uncategorizedCount > 0,
              ),
              _scopeChip(
                context,
                label: context.l10n.bankImportGroupScopeAll,
                value: false,
                selected: !onlyUncategorized,
                enabled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scopeChip(
    BuildContext context, {
    required String label,
    required bool value,
    required bool selected,
    required bool enabled,
  }) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      visualDensity: VisualDensity.compact,
      onSelected:
          enabled ? (_) => setState(() => _onlyUncategorized = value) : null,
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            context.l10n.bankImportGroupEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );

  Widget _groupTile(
    BuildContext context,
    BankImportReview state,
    DraftGroup group,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final rows = [for (final i in group.indexes) state.drafts[i]];
    final labels = _labelsFor(state, group.isIncome);
    final summary = _categorySummary(context, rows, labels);
    final dominant = _dominantCategoryId(rows);
    final missing = rows.where((d) => d.categoryId == null).length;
    final currency = state.walletCurrency ?? kDefaultCurrency;

    return InkWell(
      onTap: () => _assignToGroup(state, group),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _countBadge(context, group.indexes.length),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _samples(rows),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        group.isIncome
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          formatMoney(group.totalAmount, currency: currency),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          summary.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: summary.color(scheme)),
                        ),
                      ),
                    ],
                  ),
                  // Grubun çoğunluğu zaten bir kategoride ve kalanı boşsa:
                  // seçiciyi hiç açmadan kapatmanın yolu. Yanlışlıkla
                  // kategorili satırların üzerine yazmaz — yalnız boşları
                  // doldurur.
                  if (dominant != null && missing > 0) ...[
                    const SizedBox(height: 4),
                    // `TextButton.icon` DEĞİL: etiketi kendi Row'unda esnek
                    // değil ve kullanıcının uzun kategori adıyla dar telefonda
                    // taşıyor (ölçüldü: 360dp'de 29px).
                    InkWell(
                      onTap: () => _fillRest(state, group, dominant),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_fix_high_rounded,
                                size: 14, color: scheme.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                context.l10n.bankImportGroupFillRest(
                                    labels[dominant] ?? dominant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _countBadge(BuildContext context, int count) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 34,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: scheme.primary),
      ),
    );
  }

  /// Gruptaki en fazla satırın taşıdığı kategori; hiç kategorili satır yoksa
  /// `null`. Eşitlikte ilk gelen kazanır (kararlı sonuç).
  static String? _dominantCategoryId(List<ImportDraft> rows) {
    final counts = <String, int>{};
    for (final d in rows) {
      final id = d.categoryId;
      if (id != null) counts.update(id, (v) => v + 1, ifAbsent: () => 1);
    }
    String? best;
    var bestCount = 0;
    counts.forEach((id, count) {
      if (count > bestCount) {
        bestCount = count;
        best = id;
      }
    });
    return best;
  }

  ({String text, Color Function(ColorScheme) color}) _categorySummary(
    BuildContext context,
    List<ImportDraft> rows,
    Map<String, String> labels,
  ) {
    final ids = rows.map((d) => d.categoryId).toSet();
    if (ids.length == 1) {
      final id = ids.first;
      if (id == null) {
        return (
          text: context.l10n.bankImportGroupNone,
          color: (scheme) => scheme.error,
        );
      }
      return (
        text: labels[id] ?? id,
        color: (scheme) => scheme.onSurfaceVariant,
      );
    }
    return (
      text: context.l10n.bankImportGroupMixed,
      color: (scheme) => scheme.tertiary,
    );
  }

  /// Gruptaki farklı açıklamalardan ilk ikisi — kullanıcı neyin toplandığını
  /// GÖRMEDEN toplu atama yapmasın.
  static String _samples(List<ImportDraft> rows) {
    final seen = <String>{};
    for (final d in rows) {
      final text = d.description.trim();
      if (text.isNotEmpty) seen.add(text);
      if (seen.length == 2) break;
    }
    return seen.join('  ·  ');
  }

  Future<void> _assignToGroup(BankImportReview state, DraftGroup group) async {
    final picked = await showCategoryPickerSheet(
      context: context,
      isExpense: !group.isIncome,
      onCreated: _cubit.registerCreatedCategory,
    );
    if (picked == null || !mounted) return;
    _apply(group.indexes, picked.id, picked.isExpense == !group.isIncome,
        isIncome: group.isIncome);
  }

  void _fillRest(BankImportReview state, DraftGroup group, String categoryId) {
    final targets = [
      for (final i in group.indexes)
        if (state.drafts[i].categoryId == null) i,
    ];
    _apply(targets, categoryId, true, isIncome: group.isIncome);
  }

  void _apply(
    List<int> targets,
    String categoryId,
    bool typeMatches, {
    required bool isIncome,
  }) {
    if (!typeMatches || targets.isEmpty) {
      AppMessenger.warning(context.l10n.bankImportAssignTypeMismatch);
      return;
    }
    _cubit.applyCategoryToIndexes(targets, categoryId);
    final fresh = _cubit.state;
    final label = fresh is BankImportReview
        ? _labelsFor(fresh, isIncome)[categoryId]
        : null;
    AppMessenger.success(context.l10n
        .bankImportAssignVisibleDone(targets.length, label ?? categoryId));
  }
}
