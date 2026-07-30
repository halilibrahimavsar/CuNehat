import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/single_transaction_detail_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_action_sheet.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

/// Premium işlem kartı: kategori glyph'i, marka renkleri, baskın tutar.
/// Dokununca tek-işlem detay sayfasını açar; basılı tutunca sil/düzenle menüsü açar.
class TransactionCard extends StatelessWidget {
  final BuildContext context;
  final TransactionWithBalance item;
  final bool isListView;
  final IconData? categoryIcon;

  /// Kategorinin çözülmüş görünen adı (`categoryIcon` ile aynı kanal).
  /// null ise `tag` l10n'a düşer — sistem etiketleri ve silinmiş
  /// kategorilerden kalan tag'ler için doğru davranış budur.
  final String? categoryLabel;

  const TransactionCard({
    super.key,
    required this.context,
    required this.item,
    required this.isListView,
    this.categoryIcon,
    this.categoryLabel,
  });

  String get _heroTag => 'tx_${item.transaction.id ?? item.hashCode}';

  Future<void> _showActionSheet(BuildContext context, Color accent) async {
    final t = item.transaction;

    final action = await TransactionActionSheet.show(
      context,
      transaction: t,
      accent: accent,
    );
    if (action == null || !context.mounted) return;

    // Kilitli (isSystem) işlemler için TransactionActionSheet zaten
    // Düzenle/Sil yerine bir bilgi notu gösterir; bu action'lar hiç
    // dönmez, o yüzden burada tekrar isSystem kontrolüne gerek yok.
    switch (action) {
      case TransactionAction.edit:
        TransactionSheetHandler.showSheet(
          context: context,
          userId: t.userId,
          walletId: t.walletId,
          type: t.type,
          initialTransaction: t,
        );
        break;
      case TransactionAction.delete:
        // Onay diyaloğu YOK: silme anında yapılır, snackbar 6 saniye boyunca
        // "Geri al" sunar (bkz. showDeletionMessage). İşlem silme en sık ve
        // en hafif yıkıcı eylem; modal onay burada geri almanın yerini
        // tutmuyor, yalnız akışı yavaşlatıyordu. Borç/alacak/birikim ödeme
        // geçmişi taşıdığı için onaylarını KORUR.
        if (t.id != null) {
          context.read<TransactionBloc>().add(DeleteTransactionEvent(t.id!));
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = item.transaction;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = t.isIncome ? AppGradients.savings : AppGradients.debt;

    return AppCard(
      accent: accent,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => _openDetail(context),
      onLongPress: () => _showActionSheet(context, accent),
      child: Row(
        children: [
          // Kategori glyph'i (yoksa yön oku fallback)
          Hero(
            tag: _heroTag,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Icon(
                categoryIcon ??
                    (t.isIncome
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded),
                color: accent,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Başlık + kategori chip + saat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (t.isSystem) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (t.tag.isNotEmpty)
                      _categoryChip(context, scheme, accent, t.tag),
                    const SizedBox(width: 8),
                    Text(
                      AppFormatters.time.format(t.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Baskın tutar
          SignedMoneyText(
            amount: t.amount,
            isExpense: t.isExpense,
            currency: context.activeWalletCurrency,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(
      BuildContext context, ColorScheme scheme, Color accent, String tag) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          categoryLabel ?? context.translateCategory(tag),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: accent.withValues(alpha: 0.95),
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<TransactionBloc>(),
          child: SingleTransactionDetailPage(
            item: item,
            heroTag: _heroTag,
            categoryIcon: categoryIcon,
            categoryLabel: categoryLabel,
          ),
        ),
      ),
    );
  }
}
