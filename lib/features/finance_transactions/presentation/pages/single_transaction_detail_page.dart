import 'dart:io';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/receipt_viewer_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_bloc.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
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

  /// Kategorinin çözülmüş görünen adı (karttan taşınır). null ise `tag`
  /// l10n'a düşer — sistem etiketleri için doğru davranış budur.
  final String? categoryLabel;

  /// Hero animasyonunun karttaki ikonla eşleşmesi için benzersiz etiket.
  final String heroTag;

  const SingleTransactionDetailPage({
    super.key,
    required this.item,
    required this.heroTag,
    this.categoryIcon,
    this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionActionSuccess) {
          final isDeleted = !state.currentTransactions
              .any((tx) => tx.id == item.transaction.id);
          if (isDeleted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },
      builder: (context, state) {
        final tList = state.currentTransactions;
        final t = tList.firstWhere(
          (x) => x.id == item.transaction.id,
          orElse: () => item.transaction,
        );

        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final accent = t.isIncome ? AppGradients.savings : AppGradients.debt;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(context.l10n.islemDetayi),
            actions: [
              if (!t.isSystem)
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: context.l10n.duzenle,
                  onPressed: () => _edit(context, t),
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
                                color: accent.withValues(alpha: 0.3),
                                width: 1.5),
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
                        currencySymbol: context.activeWalletCurrencySymbol,
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
                        _systemBadge(context, scheme),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Bilgi kartı
                AppCard(
                  accent: accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  child: Column(
                    children: [
                      _infoRow(context,
                          icon: Icons.sell_rounded,
                          label: context.l10n.labelKategori,
                          value: categoryLabel ??
                              context.translateCategory(t.tag)),
                      _divider(scheme),
                      _infoRow(context,
                          icon: Icons.event_rounded,
                          label: context.l10n.detailLabelTarih,
                          value: AppFormatters.dateLong.format(t.date)),
                      _divider(scheme),
                      _infoRow(context,
                          icon: Icons.schedule_rounded,
                          label: context.l10n.detailLabelSaat,
                          value: AppFormatters.time.format(t.date)),
                      _divider(scheme),
                      _infoRow(context,
                          icon: t.isIncome
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          label: context.l10n.detailLabelTur,
                          value: t.isIncome
                              ? context.l10n.detailLabelGelir
                              : context.l10n.detailLabelGider,
                          valueColor: accent),
                      _divider(scheme),
                      _infoRow(context,
                          icon: Icons.account_balance_wallet_rounded,
                          label: context.l10n.detailLabelIslemSonrasiBakiye,
                          valueWidget: AmountDisplay(
                            amount: item.balanceAfter,
                            currencySymbol: context.activeWalletCurrencySymbol,
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

                if (t.receiptFileName != null) ...[
                  const SizedBox(height: 24),
                  _ReceiptCard(fileName: t.receiptFileName!, accent: accent),
                ],

                const SizedBox(height: 24),

                // Aksiyonlar
                if (t.isSystem)
                  _systemNotice(context, scheme)
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _delete(context, t),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(context.l10n.sil),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppGradients.debt,
                            side: BorderSide(
                                color:
                                    AppGradients.debt.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _edit(context, t),
                          icon: const Icon(Icons.edit_rounded),
                          label: Text(context.l10n.duzenle),
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
      },
    );
  }

  void _edit(BuildContext context, TransactionEntity t) {
    if (t.isSystem) return;
    TransactionSheetHandler.showSheet(
      context: context,
      userId: t.userId,
      walletId: t.walletId,
      type: t.type,
      initialTransaction: t,
    );
  }

  /// Onay diyaloğu YOK: silme anında yapılır, snackbar 6 saniye boyunca
  /// "Geri al" sunar (bkz. `showDeletionMessage`). Sayfa silme sonrası
  /// kapandığı için mesaj listenin üstünde görünür.
  void _delete(BuildContext context, TransactionEntity t) {
    if (t.id != null) {
      context.read<TransactionBloc>().add(DeleteTransactionEvent(t.id!));
    }
  }

  Widget _systemBadge(BuildContext context, ColorScheme scheme) {
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
            context.l10n.otomatikIslem,
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

  Widget _systemNotice(BuildContext context, ColorScheme scheme) {
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
              context.l10n.buIslemOtomatikOlusturuldu,
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

/// İşleme iliştirilmiş fişin önizleme kartı. Dosya bu cihazda yoksa (geri
/// yüklenen yedek — binary taşınmaz) "görsel bu cihazda yok" gösterir.
class _ReceiptCard extends StatelessWidget {
  final String fileName;
  final Color accent;

  const _ReceiptCard({required this.fileName, required this.accent});

  Future<File?> _resolve() async {
    final f = await getIt<ReceiptStorageService>().fileFor(fileName);
    return await f.exists() ? f : null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<File?>(
      future: _resolve(),
      builder: (context, snap) {
        final file = snap.data;
        final missing =
            snap.connectionState == ConnectionState.done && file == null;
        return AppCard(
          accent: accent,
          padding: const EdgeInsets.all(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: file == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReceiptViewerPage(imageFile: file),
                      ),
                    ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: file != null
                        ? Image.file(file, fit: BoxFit.cover)
                        : ColoredBox(
                            color: scheme.onSurface.withValues(alpha: 0.06),
                            child: Icon(Icons.image_not_supported_rounded,
                                color: scheme.onSurfaceVariant),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    missing
                        ? context.l10n.fisCihazdaYok
                        : context.l10n.fisGoruntule,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          missing ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                  ),
                ),
                if (file != null)
                  Icon(Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }
}
