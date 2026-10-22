import 'package:flutter/material.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/text_search.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';

/// Cüzdandaki DÜZ (sistem dışı) bir işlemi seçtirir — bir kaydın (birikim
/// alımı, katkı, borç ödemesi, anapara) ödemesi defterde ZATEN duruyorsa o
/// satırı bulmak için. Seçilen satır "benimsenir": yeni hareket yazılmaz
/// (bkz. `WalletMetricsService.adoptCashMovement`).
///
/// [amountHint]/[dateHint] verilirse tutarı ve tarihi en yakın satırlar
/// üstte gelir; kullanıcı çoğu zaman aradığını ilk birkaç satırda bulur.
Future<TransactionEntity?> showLedgerTransactionPicker(
  BuildContext context, {
  required String userId,
  required String walletId,
  required String currency,
  required bool isIncome,
  double? amountHint,
  DateTime? dateHint,
}) {
  return showModalBottomSheet<TransactionEntity>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LedgerTransactionPicker(
      userId: userId,
      walletId: walletId,
      currency: currency,
      isIncome: isIncome,
      amountHint: amountHint,
      dateHint: dateHint,
    ),
  );
}

/// Seçilebilecek satırlar: yönü tutan, sistem hareketi OLMAYAN (kuplaj
/// hareketi zaten bir kaydın malı; benimsenemez) işlemler, en olası önce.
///
/// Sıra: tutar ipucu varsa kuruş farkı, eşitlikte gün farkı; ipucu yoksa en
/// yeni önce. Saf fonksiyon (test edilebilir).
List<TransactionEntity> rankLedgerCandidates(
  Iterable<TransactionEntity> transactions, {
  required bool isIncome,
  double? amountHint,
  DateTime? dateHint,
}) {
  final pool = [
    for (final t in transactions)
      if (!t.isSystem && t.isIncome == isIncome && t.id != null) t,
  ];
  int cents(double v) => (v.abs() * 100).round();
  int days(DateTime d) => dateHint == null
      ? 0
      : DateTime.utc(d.year, d.month, d.day)
          .difference(DateTime.utc(dateHint.year, dateHint.month, dateHint.day))
          .inDays
          .abs();
  pool.sort((a, b) {
    if (amountHint != null) {
      final target = cents(amountHint);
      final byAmount = (cents(a.amount) - target)
          .abs()
          .compareTo((cents(b.amount) - target).abs());
      if (byAmount != 0) return byAmount;
    }
    if (dateHint != null) {
      final byDays = days(a.date).compareTo(days(b.date));
      if (byDays != 0) return byDays;
    }
    return b.date.compareTo(a.date);
  });
  return pool;
}

class LedgerTransactionPicker extends StatefulWidget {
  final String userId;
  final String walletId;
  final String currency;
  final bool isIncome;
  final double? amountHint;
  final DateTime? dateHint;

  const LedgerTransactionPicker({
    super.key,
    required this.userId,
    required this.walletId,
    required this.currency,
    required this.isIncome,
    this.amountHint,
    this.dateHint,
  });

  @override
  State<LedgerTransactionPicker> createState() =>
      _LedgerTransactionPickerState();
}

class _LedgerTransactionPickerState extends State<LedgerTransactionPicker> {
  late final Future<List<TransactionEntity>> _candidates = _load();
  String _query = '';

  Future<List<TransactionEntity>> _load() async {
    final result = await getIt<TransactionsRepository>().getTransactions(
      userId: widget.userId,
      walletId: widget.walletId,
    );
    return result.fold(
      (_) => const <TransactionEntity>[],
      (list) => rankLedgerCandidates(
        list,
        isIncome: widget.isIncome,
        amountHint: widget.amountHint,
        dateHint: widget.dateHint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.defterSatiriSecBaslik,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.iptal,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  context.l10n.defterSatiriSecAciklama,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = foldTr(v)),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    hintText: context.l10n.bankImportSearchHint,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<TransactionEntity>>(
                  future: _candidates,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final rows = [
                      for (final t in snapshot.data!)
                        if (_matches(t)) t,
                    ];
                    if (rows.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            context.l10n.defterSatiriYok,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (context, i) => LedgerTransactionTile(
                        transaction: rows[i],
                        currency: widget.currency,
                        onTap: () => Navigator.of(context).pop(rows[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matches(TransactionEntity t) {
    if (_query.isEmpty) return true;
    return matchesFolded(t.title, _query) ||
        (t.reference != null && matchesFolded(t.reference!, _query));
  }
}

/// Defter satırının seçici görünümü: başlık, işaretli tutar, tarih ve
/// ekstreden geldiyse rozet. Seçicilerde ortak (bkz. "Bağla…" akışı).
class LedgerTransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final String currency;
  final VoidCallback onTap;

  const LedgerTransactionTile({
    super.key,
    required this.transaction,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final cs = Theme.of(context).colorScheme;
    final fromStatement =
        t.origin == TransactionOrigin.bankImport || t.reference != null;
    return ListTile(
      onTap: onTap,
      title: Text(
        t.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${t.isIncome ? '+' : '−'}'
            '${formatMoney(t.amount, currency: currency)} · '
            '${AppFormatters.dateShort.format(t.date)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (fromStatement)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                context.l10n.ekstredenRozeti,
                style: TextStyle(fontSize: 11, color: cs.primary),
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
