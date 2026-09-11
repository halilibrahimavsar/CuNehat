import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/data/statement_date_parser.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';

/// CSV/Excel için "dosyayı nasıl okuyalım?" adımı.
///
/// **Yalnız otomatik eşlemeye güvenilemediğinde açılır** (bkz.
/// `MappingAssessment.isConfident`); başlıkları tanınan, satırları okunan,
/// bakiyesi tutan dosyalar doğrudan incelemeye geçer.
///
/// Eski ekran "hangi alan hangi sütun?" diye alan başına açılır menüler ve
/// ayrı bir "Tutar işareti (Tek sütun / Borç-Alacak)" seçimi gösteriyor,
/// sonucu en altta ham bir tablo olarak veriyordu: kullanıcı teknik bir
/// karar veriyor ama kararın NE ÜRETTİĞİNİ göremiyordu. Bu ekran sırayı
/// tersine çevirir:
///
/// 1. **Önce sonuç** — kaç hareket okunacak, kaçı gelir/gider, bakiye tutuyor
///    mu, ilk hareketler nasıl görünüyor.
/// 2. **Sonra sütunlar** — her sütun örnek değerleriyle bir kart; soru sütun
///    başına ve sade dille: "bu sütun ne?". İşaret kipi ayrı bir soru
///    değildir, "Tutar" ya da "Giden/Gelen para" seçiminden çıkar.
/// 3. **Tarih sırası yalnız gerçekten belirsizse** sorulur, örnekle
///    ("03/04/2026 → 3 Nisan mı, 4 Mart mı?").
class BankImportMappingView extends StatelessWidget {
  final BankImportMapping state;
  const BankImportMappingView({super.key, required this.state});

  RawTable get _table => state.table;
  ColumnMapping get _m => state.mapping;
  MappingAssessment get _a => state.assessment;

  void _update(BuildContext context, ColumnMapping m) =>
      context.read<BankImportCubit>().updateMapping(m);

  @override
  Widget build(BuildContext context) {
    final problems = _problems(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              Text(context.l10n.bankImportMapTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(context.l10n.bankImportMapHint,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              _ResultCard(assessment: _a, problems: problems),
              if (_a.ambiguousDateSample case final sample?) ...[
                const SizedBox(height: 12),
                _DateOrderCard(
                  sample: sample,
                  selected: _m.dateFormat,
                  onChanged: (f) =>
                      _update(context, _m.copyWith(dateFormat: f)),
                ),
              ],
              const SizedBox(height: 20),
              Text(context.l10n.bankImportMapColumnsTitle,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(context.l10n.bankImportMapColumnsHint,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              _ColumnStrip(
                table: _table,
                mapping: _m,
                onPick: (col) => _pickRole(context, col),
              ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: problems.isEmpty
                  ? () => context.read<BankImportCubit>().applyMapping()
                  : null,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(context.l10n.bankImportContinue),
            ),
          ),
        ),
      ],
    );
  }

  /// Devam etmeyi engelleyen eksikler, kullanıcının diliyle.
  List<String> _problems(BuildContext context) {
    final l10n = context.l10n;
    final missingAmount = switch (_m.signMode) {
      SignMode.signedAmount => (_m.amountCol ?? -1) < 0,
      SignMode.debitCreditColumns =>
        (_m.debitCol ?? -1) < 0 && (_m.creditCol ?? -1) < 0,
    };
    return [
      if (_m.dateCol < 0) l10n.bankImportMapNeedDate,
      if (_m.descCol < 0) l10n.bankImportMapNeedDesc,
      if (missingAmount) l10n.bankImportMapNeedAmount,
      if (_m.isValid && _a.result.drafts.isEmpty) l10n.bankImportMapNoRows,
    ];
  }

  Future<void> _pickRole(BuildContext context, int col) async {
    final picked = await showModalBottomSheet<ColumnRole>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _RoleSheet(
        columnLabel: columnLabel(ctx, _table, _m, col),
        current: _m.roleOf(col),
      ),
    );
    if (picked == null || !context.mounted) return;
    _update(context, _m.withRole(col, picked));
  }
}

/// Sütunun gösterilecek adı: başlık hücresi, yoksa "3. sütun".
///
/// Başlık satırı tablonun İLK satırı olmak zorunda değil: gerçek ekstrelerde
/// önce hesap künyesi (Şube/IBAN/Bakiye) gelir. Etiket, tespit edilen başlık
/// satırından okunur (bkz. `ColumnMapping.headerRowIndex`).
@visibleForTesting
String columnLabel(
    BuildContext context, RawTable table, ColumnMapping m, int col) {
  if (m.hasHeaderRow && m.headerRowIndex < table.rows.length) {
    final header = table.rows[m.headerRowIndex];
    if (col < header.length) {
      final h = header[col].trim();
      if (h.isNotEmpty) return h;
    }
  }
  return context.l10n.bankImportColumnN(col + 1);
}

// ================================================================ Sonuç

class _ResultCard extends StatelessWidget {
  final MappingAssessment assessment;
  final List<String> problems;
  const _ResultCard({required this.assessment, required this.problems});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final a = assessment;
    final drafts = a.result.drafts;
    final allIncome = drafts.length > 1 &&
        a.expenseCount == 0 &&
        a.mapping.balanceCol == null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.bankImportMapResultTitle,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final p in problems)
            _Line(icon: Icons.error_outline_rounded, color: cs.error, text: p),
          if (drafts.isNotEmpty)
            _Line(
              icon: Icons.check_circle_outline_rounded,
              color: cs.primary,
              text: l10n.bankImportMapRowsRead(
                  drafts.length, a.incomeCount, a.expenseCount),
            ),
          if (a.result.skippedRows > 0)
            _Line(
              icon: Icons.warning_amber_rounded,
              color: Colors.orange.shade800,
              text: l10n.bankImportMapSkipped(a.result.skippedRows),
            ),
          if (a.balanceVerified)
            _Line(
              icon: Icons.verified_rounded,
              color: Colors.green,
              text: l10n.bankImportMapBalanceOk,
            ),
          if (a.balanceMismatch)
            _Line(
              icon: Icons.error_outline_rounded,
              color: cs.error,
              text: l10n.bankImportMapBalanceBad,
            ),
          if (allIncome)
            _Line(
              icon: Icons.info_outline_rounded,
              color: Colors.orange.shade800,
              text: l10n.bankImportMapAllIncome,
            ),
          if (drafts.isNotEmpty) ...[
            const Divider(height: 20),
            for (final d in drafts.take(4))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(AppFormatters.dateShort.format(d.date),
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.description.isEmpty ? '—' : d.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${d.isIncome ? '+' : '−'}${formatMoneyNumber(d.amount)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: d.isIncome
                            ? AppGradients.savings
                            : AppGradients.debt,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Line({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ========================================================= Tarih sırası

class _DateOrderCard extends StatelessWidget {
  final String sample;
  final StatementDateFormat selected;
  final ValueChanged<StatementDateFormat> onChanged;
  const _DateOrderCard({
    required this.sample,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final longDate = DateFormat.yMMMMd(Intl.defaultLocale);
    String read(StatementDateFormat f) {
      final d = parseStatementDate(sample, f);
      return d == null ? '—' : longDate.format(d);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_rounded,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.bankImportMapDateQuestion(sample),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in const [
                StatementDateFormat.dayFirst,
                StatementDateFormat.monthFirst,
              ])
                ChoiceChip(
                  label: Text(read(f)),
                  // `auto` (eski kayıtlarda kalmış olabilir) gün-önce okunur.
                  selected: f == selected ||
                      (selected == StatementDateFormat.auto &&
                          f == StatementDateFormat.dayFirst),
                  onSelected: (_) => onChanged(f),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================= Sütunlar

/// Sütun kartları yan yana, yatay kaydırmalı. Hem başlıkta hem verisinde
/// hiçbir şey olmayan sütunlar (CSV'nin sonundaki boş `;;`) gösterilmez.
class _ColumnStrip extends StatelessWidget {
  final RawTable table;
  final ColumnMapping mapping;
  final ValueChanged<int> onPick;
  const _ColumnStrip({
    required this.table,
    required this.mapping,
    required this.onPick,
  });

  static const int _sampleCount = 3;

  List<String> _samples(int col) {
    final out = <String>[];
    for (var r = mapping.firstDataRow; r < table.rows.length; r++) {
      final row = table.rows[r];
      if (col >= row.length) continue;
      final v = row[col].trim();
      if (v.isEmpty) continue;
      out.add(v);
      if (out.length == _sampleCount) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final columns = <(int, List<String>)>[
      for (var c = 0; c < table.columnCount; c++)
        if (_samples(c) case final samples
            when samples.isNotEmpty ||
                mapping.roleOf(c) != ColumnRole.ignore ||
                columnLabel(context, table, mapping, c) !=
                    context.l10n.bankImportColumnN(c + 1))
          (c, samples),
    ];
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: columns.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, k) {
          final (col, samples) = columns[k];
          return _ColumnCard(
            label: columnLabel(context, table, mapping, col),
            samples: samples,
            role: mapping.roleOf(col),
            onTap: () => onPick(col),
          );
        },
      ),
    );
  }
}

class _ColumnCard extends StatelessWidget {
  final String label;
  final List<String> samples;
  final ColumnRole role;
  final VoidCallback onTap;
  const _ColumnCard({
    required this.label,
    required this.samples,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final used = role != ColumnRole.ignore;
    return SizedBox(
      width: 148,
      child: Material(
        color: used
            ? cs.primaryContainer.withValues(alpha: 0.35)
            : cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: used ? cs.primary : cs.outlineVariant,
                width: used ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 6),
                for (final s in samples)
                  Text(
                    s,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                const Spacer(),
                Row(
                  children: [
                    Icon(roleIcon(role),
                        size: 15,
                        color: used ? cs.primary : cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        roleLabel(context, role),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: used ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(Icons.edit_outlined,
                        size: 14, color: cs.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================ Rol seçimi

@visibleForTesting
IconData roleIcon(ColumnRole role) => switch (role) {
      ColumnRole.date => Icons.event_rounded,
      ColumnRole.description => Icons.notes_rounded,
      ColumnRole.amount => Icons.swap_vert_rounded,
      ColumnRole.debit => Icons.remove_circle_outline_rounded,
      ColumnRole.credit => Icons.add_circle_outline_rounded,
      ColumnRole.balance => Icons.account_balance_wallet_outlined,
      ColumnRole.tag => Icons.label_outline_rounded,
      ColumnRole.reference => Icons.tag_rounded,
      ColumnRole.ignore => Icons.block_rounded,
    };

@visibleForTesting
String roleLabel(BuildContext context, ColumnRole role) {
  final l10n = context.l10n;
  return switch (role) {
    ColumnRole.date => l10n.bankImportRoleDate,
    ColumnRole.description => l10n.bankImportRoleDesc,
    ColumnRole.amount => l10n.bankImportRoleAmountLabel,
    ColumnRole.debit => l10n.bankImportRoleDebitLabel,
    ColumnRole.credit => l10n.bankImportRoleCreditLabel,
    ColumnRole.balance => l10n.bankImportRoleBalance,
    ColumnRole.tag => l10n.bankImportRoleTag,
    ColumnRole.reference => l10n.bankImportRoleReference,
    ColumnRole.ignore => l10n.bankImportRoleIgnore,
  };
}

String _roleDescription(BuildContext context, ColumnRole role) {
  final l10n = context.l10n;
  return switch (role) {
    ColumnRole.date => l10n.bankImportRoleDateDesc,
    ColumnRole.description => l10n.bankImportRoleDescDesc,
    ColumnRole.amount => l10n.bankImportRoleAmountDesc,
    ColumnRole.debit => l10n.bankImportRoleDebitDesc,
    ColumnRole.credit => l10n.bankImportRoleCreditDesc,
    ColumnRole.balance => l10n.bankImportRoleBalanceDesc,
    ColumnRole.tag => l10n.bankImportRoleTagDesc,
    ColumnRole.reference => l10n.bankImportRoleReferenceDesc,
    ColumnRole.ignore => l10n.bankImportRoleIgnoreDesc,
  };
}

class _RoleSheet extends StatelessWidget {
  final String columnLabel;
  final ColumnRole current;
  const _RoleSheet({required this.columnLabel, required this.current});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                context.l10n.bankImportMapRoleSheetTitle(columnLabel),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final role in ColumnRole.values)
              ListTile(
                leading: Icon(roleIcon(role),
                    color: role == current ? cs.primary : null),
                title: Text(
                  roleLabel(context, role),
                  style: TextStyle(
                    fontWeight:
                        role == current ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                subtitle: Text(_roleDescription(context, role)),
                trailing: role == current
                    ? Icon(Icons.check_rounded, color: cs.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(role),
              ),
          ],
        ),
      ),
    );
  }
}
