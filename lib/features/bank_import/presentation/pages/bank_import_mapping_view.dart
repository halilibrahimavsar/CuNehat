import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';

/// CSV/Excel için sütun→alan eşleme adımı. Otomatik tahmin gelir; kullanıcı
/// düzeltir. Alt tarafta ilk satırların canlı önizlemesi.
class BankImportMappingView extends StatelessWidget {
  final BankImportMapping state;
  const BankImportMappingView({super.key, required this.state});

  RawTable get _table => state.table;
  ColumnMapping get _m => state.mapping;

  void _update(BuildContext context, ColumnMapping m) =>
      context.read<BankImportCubit>().updateMapping(m);

  /// Başlık satırı tablonun İLK satırı olmak zorunda değil: gerçek ekstrelerde
  /// önce hesap künyesi (Şube/IBAN/Bakiye) gelir. Etiket, tespit edilen
  /// başlık satırından okunur (bkz. `ColumnMapping.headerRowIndex`).
  List<String> get _headerRow =>
      _m.hasHeaderRow && _m.headerRowIndex < _table.rows.length
          ? _table.rows[_m.headerRowIndex]
          : const [];

  String _colLabel(BuildContext context, int i) {
    final header = _headerRow;
    if (i < header.length) {
      final h = header[i].trim();
      if (h.isNotEmpty) return h.length > 22 ? '${h.substring(0, 22)}…' : h;
    }
    return context.l10n.bankImportColumnN(i + 1);
  }

  @override
  Widget build(BuildContext context) {
    final cols = _table.columnCount;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(context.l10n.bankImportMappingTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dropdown(
                        context,
                        context.l10n.bankImportColDate,
                        cols,
                        _m.dateCol,
                        (v) => _update(context, _m.copyWith(dateCol: v))),
                    _dropdown(
                        context,
                        context.l10n.bankImportColDesc,
                        cols,
                        _m.descCol,
                        (v) => _update(context, _m.copyWith(descCol: v))),
                    const Divider(height: 24),
                    Text(context.l10n.bankImportSignMode,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SegmentedButton<SignMode>(
                      segments: [
                        ButtonSegment(
                            value: SignMode.signedAmount,
                            label: Text(context.l10n.bankImportSignSingle)),
                        ButtonSegment(
                            value: SignMode.debitCreditColumns,
                            label:
                                Text(context.l10n.bankImportSignDebitCredit)),
                      ],
                      selected: {_m.signMode},
                      onSelectionChanged: (s) =>
                          _update(context, _m.copyWith(signMode: s.first)),
                    ),
                    const SizedBox(height: 12),
                    if (_m.signMode == SignMode.signedAmount)
                      _dropdown(
                          context,
                          context.l10n.bankImportColAmount,
                          cols,
                          _m.amountCol ?? -1,
                          (v) =>
                              _update(context, _m.copyWith(amountCol: () => v)))
                    else ...[
                      _dropdown(
                          context,
                          context.l10n.bankImportColDebit,
                          cols,
                          _m.debitCol ?? -1,
                          (v) => _update(context,
                              _m.copyWith(debitCol: () => v < 0 ? null : v)),
                          allowNone: true),
                      _dropdown(
                          context,
                          context.l10n.bankImportColCredit,
                          cols,
                          _m.creditCol ?? -1,
                          (v) => _update(context,
                              _m.copyWith(creditCol: () => v < 0 ? null : v)),
                          allowNone: true),
                    ],
                    const Divider(height: 24),
                    _dateFormatDropdown(context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _preview(context),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _m.isValid
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

  Widget _dropdown(BuildContext context, String label, int cols, int value,
      ValueChanged<int> onChanged,
      {bool allowNone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 3,
            child: DropdownButton<int>(
              isExpanded: true,
              value:
                  value >= 0 && value < cols ? value : (allowNone ? -1 : null),
              hint: const Text('—'),
              items: [
                if (allowNone)
                  const DropdownMenuItem(value: -1, child: Text('—')),
                for (var i = 0; i < cols; i++)
                  DropdownMenuItem(
                      value: i, child: Text(_colLabel(context, i))),
              ],
              onChanged: (v) => v == null ? null : onChanged(v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateFormatDropdown(BuildContext context) {
    String label(StatementDateFormat f) => switch (f) {
          StatementDateFormat.auto => context.l10n.bankImportDateAuto,
          StatementDateFormat.dayFirst => 'GG/AA/YYYY',
          StatementDateFormat.monthFirst => 'AA/GG/YYYY',
        };
    return Row(
      children: [
        Expanded(flex: 2, child: Text(context.l10n.bankImportDateFormat)),
        Expanded(
          flex: 3,
          child: DropdownButton<StatementDateFormat>(
            isExpanded: true,
            value: _m.dateFormat,
            items: [
              for (final f in StatementDateFormat.values)
                DropdownMenuItem(value: f, child: Text(label(f))),
            ],
            onChanged: (v) =>
                v == null ? null : _update(context, _m.copyWith(dateFormat: v)),
          ),
        ),
      ],
    );
  }

  /// Eşlemenin hangi alana denk geldiği (sütun → kısa etiket). Önizlemede
  /// başlığın altına yazılır ki kullanıcı "hangi sütun neye gidiyor" sorusunu
  /// açılır menülere bakmadan görebilsin.
  String? _roleOf(BuildContext context, int col) {
    if (col == _m.dateCol) return context.l10n.bankImportRoleDate;
    if (col == _m.descCol) return context.l10n.bankImportRoleDesc;
    if (col == _m.amountCol) return context.l10n.bankImportRoleAmount;
    if (col == _m.debitCol) return context.l10n.bankImportRoleDebit;
    if (col == _m.creditCol) return context.l10n.bankImportRoleCredit;
    if (col == _m.balanceCol) return context.l10n.bankImportRoleBalance;
    return null;
  }

  /// Önizleme: başlık + İLK VERİ satırları. Eskiden `rows.take(6)` ile
  /// tablonun ilk 6 satırı gösteriliyordu; gerçek ekstrelerde bunlar hesap
  /// künyesi olduğu için tek bir hareket bile görünmüyordu.
  Widget _preview(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cols = _table.columnCount;
    final dataRows = _table.rows.skip(_m.firstDataRow).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.bankImportPreviewTitle,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18,
            headingRowHeight: 46,
            dataRowMinHeight: 32,
            dataRowMaxHeight: 40,
            columns: [
              for (var i = 0; i < cols; i++)
                DataColumn(
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_colLabel(context, i),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      if (_roleOf(context, i) case final role?)
                        Text(role,
                            style:
                                TextStyle(fontSize: 10, color: cs.primary)),
                    ],
                  ),
                ),
            ],
            rows: [
              for (final r in dataRows)
                DataRow(
                  cells: [
                    for (var i = 0; i < cols; i++)
                      DataCell(Text(
                        i < r.length ? r[i] : '',
                        style: TextStyle(
                          fontSize: 12,
                          color: _roleOf(context, i) == null
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                      )),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
