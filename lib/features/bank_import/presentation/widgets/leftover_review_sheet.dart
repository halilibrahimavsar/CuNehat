import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/bank_import/presentation/widgets/duplicate_match_panel.dart';

/// "Karşılığı bulunamayan kayıtlar" sayfasını açar.
///
/// [categoryLabels] inceleme listesinin kullandığı `kategori kimliği → ad`
/// eşlemesidir (aynı kategori iki ekranda farklı adla görünmesin).
Future<void> showLeftoverReviewSheet(
  BuildContext context, {
  required Map<String, String> categoryLabels,
}) {
  final cubit = context.read<BankImportCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider<BankImportCubit>.value(
      value: cubit,
      child: LeftoverReviewSheet(categoryLabels: categoryLabels),
    ),
  );
}

/// Ekstre döneminde defterde duran ama hiçbir satırla otomatik eşleşmemiş
/// kayıtlar ve olası banka satırları, gerekçeleriyle.
///
/// Neden ayrı bir karar yüzeyi: otomatik eşleşme bilinçli olarak temkinli
/// (eşik gevşerse gerçek bir harcama "tekrar" sanılıp sessizce atlanır).
/// Eşiğin altında kalan elle kayıt — yuvarlanmış tutar, günler sonra
/// girilmiş, not boş — bu yüzden bulunamıyor ve ekstre satırı ikinci kez
/// ekleniyordu. Burada karar kullanıcınındır: "bu satırla aynı" ya da
/// "hiçbiri"; hiçbir satır onaysız düşmez.
///
/// Sayfa cubit'i canlı dinler: çözülen kayıt listeden düşer, son öneri de
/// çözülünce sayfa kendiliğinden kapanır.
class LeftoverReviewSheet extends StatelessWidget {
  final Map<String, String> categoryLabels;

  const LeftoverReviewSheet({super.key, required this.categoryLabels});

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
          child: BlocConsumer<BankImportCubit, BankImportState>(
            listenWhen: (_, s) => s is! BankImportReview || s.leftovers.isEmpty,
            listener: (context, _) => Navigator.of(context).maybePop(),
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
    final currency = state.walletCurrency ?? kDefaultCurrency;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.bankImportLeftoverSheetTitle,
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
            context.l10n.bankImportLeftoverSheetHint,
            style: theme.textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            itemCount: state.leftovers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _LeftoverCard(
              leftover: state.leftovers[i],
              drafts: state.drafts,
              currency: currency,
              categoryLabels: categoryLabels,
            ),
          ),
        ),
      ],
    );
  }
}

class _LeftoverCard extends StatelessWidget {
  final LedgerLeftover leftover;
  final List<ImportDraft> drafts;
  final String currency;
  final Map<String, String> categoryLabels;

  const _LeftoverCard({
    required this.leftover,
    required this.drafts,
    required this.currency,
    required this.categoryLabels,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entry = leftover.entry;
    final cubit = context.read<BankImportCubit>();
    // Sistem kaydının etiketi bir kategori kimliği değil, kuplaj sabitidir
    // ("Borç Ödemesi"); arayüz dilinde gösterilir.
    final label = categoryLabels[entry.tag] ??
        (entry.isSystem ? context.translateSystemTag(entry.tag) : null);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                leftover.isCoupling
                    ? Icons.account_balance_wallet_outlined
                    : Icons.edit_note_rounded,
                size: 18,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ledgerEntryLine(
                    title: entry.title,
                    categoryLabel: label,
                    amount: entry.amount,
                    isIncome: entry.isIncome,
                    date: entry.date,
                    currency: currency,
                  ),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (leftover.isCoupling)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 2),
              child: Text(
                context.l10n.bankImportLeftoverCoupling,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 6),
          for (final c in leftover.candidates)
            _CandidateRow(
              candidate: c,
              draft: drafts[c.draftIndex],
              currency: currency,
              onSame: () => cubit.linkLeftover(entry.id!, c.draftIndex),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => cubit.dismissLeftover(entry.id!),
              child: Text(context.l10n.bankImportLeftoverNone),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  final LeftoverCandidate candidate;
  final ImportDraft draft;
  final String currency;
  final VoidCallback onSame;

  const _CandidateRow({
    required this.candidate,
    required this.draft,
    required this.currency,
    required this.onSame,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sign = draft.isIncome ? '+' : '−';
    final reasons = duplicateReasonLabels(
      context,
      amountPattern: candidate.amountPattern,
      amountDelta: candidate.amountDelta,
      dayDistance: candidate.dayDistance,
      sharedWord: candidate.sharedWord,
      categoryMatches: candidate.categoryMatches,
      currency: currency,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.description.isEmpty ? '—' : draft.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            '$sign${formatMoney(draft.amount, currency: currency)} · '
            '${AppFormatters.dateShort.format(draft.date)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final r in reasons) DuplicateReasonChip(label: r),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onSame,
              icon: const Icon(Icons.link_rounded, size: 18),
              label: Text(context.l10n.bankImportLeftoverSame),
            ),
          ),
        ],
      ),
    );
  }
}
