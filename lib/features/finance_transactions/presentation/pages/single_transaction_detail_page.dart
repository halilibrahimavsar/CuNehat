import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

/// Tek bir işlemin premium detay ekranı.
///
/// Karttan [Navigator.push] ile açılır; düzenleme/silme için aktif
/// [TransactionBloc] `BlocProvider.value` ile sağlanmalıdır.
class SingleTransactionDetailPage extends StatelessWidget {
  final TransactionWithBalance item;
  final IconData? categoryIcon;

  /// Hero animasyonunun karttaki ikonla eşleşmesi için benzersiz etiket.
  final String heroTag;

  const SingleTransactionDetailPage({
    super.key,
    required this.item,
    required this.heroTag,
    this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final t = item.transaction;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = t.isIncome ? AppGradients.savings : AppGradients.debt;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('İşlem Detayı'),
        actions: [
          if (!t.isSystem)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Düzenle',
              onPressed: () => _edit(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero ikon + tutar
            Center(
              child: Column(
                children: [
                  Hero(
                    tag: heroTag,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withValues(alpha: 0.22),
                            accent.withValues(alpha: 0.06),
                          ],
                        ),
                        border: Border.all(
                            color: accent.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Icon(
                        categoryIcon ??
                            (t.isIncome
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded),
                        color: accent,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SignedAmountDisplay(
                    amount: t.amount,
                    isExpense: t.isExpense,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 36,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (t.isSystem) ...[
                    const SizedBox(height: 8),
                    _systemBadge(scheme),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Bilgi kartı
            AppCard(
              accent: accent,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(
                children: [
                  _infoRow(context,
                      icon: Icons.sell_rounded, label: 'Kategori', value: t.tag),
                  _divider(scheme),
                  _infoRow(context,
                      icon: Icons.event_rounded,
                      label: 'Tarih',
                      value: AppFormatters.dateLong.format(t.date)),
                  _divider(scheme),
                  _infoRow(context,
                      icon: Icons.schedule_rounded,
                      label: 'Saat',
                      value: AppFormatters.time.format(t.date)),
                  _divider(scheme),
                  _infoRow(context,
                      icon: t.isIncome
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      label: 'Tür',
                      value: t.isIncome ? 'Gelir' : 'Gider',
                      valueColor: accent),
                  _divider(scheme),
                  _infoRow(context,
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'İşlem sonrası bakiye',
                      valueWidget: AmountDisplay(
                        amount: item.balanceAfter,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: item.balanceAfter >= 0
                              ? scheme.onSurface
                              : AppGradients.debt,
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Aksiyonlar
            if (t.isSystem)
              _systemNotice(scheme)
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _delete(context),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Sil'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppGradients.debt,
                        side: BorderSide(
                            color: AppGradients.debt.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _edit(context),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Düzenle'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context) {
    final t = item.transaction;
    if (t.isSystem) return;
    TransactionSheetHandler.showSheet(
      context: context,
      userId: t.userId,
      walletId: t.walletId,
      type: t.type,
      initialTransaction: t,
    );
  }

  Future<void> _delete(BuildContext context) async {
    final t = item.transaction;
    final confirmed = await IboDialog.showConfirmation(
      context,
      'İşlem Sil',
      '${t.title} işlemini silmek istediğinizden emin misiniz?',
    );
    if (confirmed == true && context.mounted && t.id != null) {
      context.read<TransactionBloc>().add(DeleteTransactionEvent(t.id!));
      Navigator.of(context).pop();
    }
  }

  Widget _systemBadge(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            'Otomatik işlem',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemNotice(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: scheme.onSurfaceVariant.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bu işlem otomatik oluşturuldu. İlgili borç/yatırım/alacak kaydından düzenleyin veya silin.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme scheme) => Divider(
        height: 1,
        thickness: 1,
        color: scheme.onSurface.withValues(alpha: 0.06),
      );

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
    Color? valueColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          valueWidget ??
              Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? scheme.onSurface,
                ),
              ),
        ],
      ),
    );
  }
}
