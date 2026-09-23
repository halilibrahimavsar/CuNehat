import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

enum TransactionAction {
  edit,
  delete,

  /// Düz satırı bir kaydın (birikim, borç, transfer) nakit bacağı yap —
  /// bkz. `startLinkTransactionFlow`.
  link,

  /// Çift kimliği olan transferi iki bacağıyla kaldır — bkz.
  /// `TransferService.unlinkTransfer`.
  removeTransfer,
}

/// Transfer bacağı mı ve sonradan kaldırılabilir mi: çift kimliği (şema 11)
/// olmayan eski transferlerin bacakları güvenle eşlenemez.
bool isRemovableTransferLeg(TransactionEntity t) =>
    t.isSystem &&
    t.tag == CashMovementTags.transfer &&
    t.linkedRecordId != null;

class TransactionActionSheet extends StatelessWidget {
  final TransactionEntity transaction;
  final Color accent;

  const TransactionActionSheet({
    super.key,
    required this.transaction,
    required this.accent,
  });

  static Future<TransactionAction?> show(
    BuildContext context, {
    required TransactionEntity transaction,
    required Color accent,
  }) {
    return showModalBottomSheet<TransactionAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionActionSheet(
        transaction: transaction,
        accent: accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Material (Container değil): içerideki ListTile zeminini ve ink dalgasını
    // en yakın Material'a boyar. Renkli bir DecoratedBox araya girerse dalga
    // görünmez olur ve Flutter debug'da assertion atar.
    return Material(
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      transaction.isIncome
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      transaction.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (transaction.isSystem) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: _systemNotice(context, cs),
              ),
              if (isRemovableTransferLeg(transaction))
                _tile(
                  context,
                  icon: Icons.link_off_rounded,
                  color: Colors.red,
                  title: context.l10n.transferiKaldir,
                  subtitle: context.l10n.transferiKaldirAciklama,
                  action: TransactionAction.removeTransfer,
                ),
            ] else ...[
              _tile(
                context,
                icon: Icons.edit_rounded,
                color: Colors.blueGrey,
                title: context.l10n.duzenle,
                subtitle: context.l10n.duzenleSubtitle,
                action: TransactionAction.edit,
              ),
              if (transaction.id != null)
                _tile(
                  context,
                  icon: Icons.link_rounded,
                  color: cs.primary,
                  title: context.l10n.baglaEylemi,
                  subtitle: context.l10n.baglaEylemiAciklama,
                  action: TransactionAction.link,
                ),
              _tile(
                context,
                icon: Icons.delete_outline_rounded,
                color: Colors.red,
                title: context.l10n.islemiSil,
                subtitle: context.l10n.silSubtitle,
                action: TransactionAction.delete,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Detay sayfasındaki (`single_transaction_detail_page.dart`) bilgi
  /// notuyla aynı görsel dil: kilitli işlemlerde Düzenle/Sil yerine gösterilir.
  Widget _systemNotice(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurfaceVariant.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurfaceVariant.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              systemNoticeText(context, transaction),
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required TransactionAction action,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: action == TransactionAction.delete ||
                  action == TransactionAction.removeTransfer
              ? Colors.red
              : cs.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      onTap: () => Navigator.pop(context, action),
    );
  }
}

/// Kilitli satırın bilgi notu: bağlanmış (benimsenmiş) satır ve transfer
/// bacağı "otomatik oluşturuldu" DEĞİLDİR — ilki kullanıcının kendi (çoğu
/// zaman ekstreden gelen) satırı, ikincisi kendi cüzdanları arası para.
String systemNoticeText(BuildContext context, TransactionEntity t) {
  if (t.tag == CashMovementTags.transfer && t.linkedRecordId != null) {
    return context.l10n.bagliTransferNotu;
  }
  if (t.isAdopted) return context.l10n.bagliSatirKisaNotu;
  return context.l10n.buIslemOtomatikOlusturuldu;
}
