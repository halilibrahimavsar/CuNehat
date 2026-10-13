import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/features/main_feature/utils/section_visibility.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

enum TransactionAction {
  edit,

  /// Aynı içerikle, bugünün tarihiyle YENİ kayıt aç (form dolu gelir).
  duplicate,
  delete,

  /// Düz satırı bir kaydın (birikim, borç, transfer) nakit bacağı yap —
  /// bkz. `startLinkTransactionFlow`.
  link,

  /// Çift kimliği olan transferi iki bacağıyla kaldır — bkz.
  /// `TransferService.unlinkTransfer`.
  removeTransfer,

  /// Defterde çoklu seçimi bu satırla başlat (toplu kategori değiştirme).
  select,
}

/// Transfer bacağı mı ve sonradan kaldırılabilir mi: çift kimliği (şema 11)
/// olmayan eski transferlerin bacakları güvenle eşlenemez.
bool isRemovableTransferLeg(TransactionEntity t) =>
    t.isSystem &&
    t.tag == CashMovementTags.transfer &&
    t.linkedRecordId != null;

/// "Bağla…" bu kurulumda bir anlam taşıyor mu?
///
/// Eylem dört şeyden söz eder: birikim alımı, kasaya aktarım, borç ödemesi,
/// cüzdanlar arası transfer. Birikim ve Borç bölümleri kapalıyken ve tek
/// cüzdan varken hiçbiri mümkün değildir — yeni kullanıcı her satırın
/// menüsünde anlamını bilmediği, hiçbir şeye bağlayamayacağı bir satır
/// görüyordu (cihazda görüldü). Bölüm açılınca ya da ikinci cüzdan gelince
/// eylem de gelir.
///
/// Bilgi yoksa (bölüm deposu kayıtlı değil, cüzdan bloc'u ağaçta yok) eylem
/// GÖSTERİLİR: yanlışlıkla gizlemek, gereksiz göstermekten kötüdür.
bool transactionLinkApplicable(BuildContext context) {
  if (!getIt.isRegistered<SectionVisibility>()) return true;
  if (!getIt<SectionVisibility>().hasOnlyTransactions) return true;
  try {
    final state = context.read<WalletBloc>().state;
    return state is! WalletLoadedSt || state.wallets.length >= 2;
  } on Object {
    return true;
  }
}

class TransactionActionSheet extends StatelessWidget {
  final TransactionEntity transaction;
  final Color accent;

  /// "Birden çok seç" sunulsun mu: yalnız çoklu seçimi olan yüzeyde (defter).
  final bool canSelect;

  const TransactionActionSheet({
    super.key,
    required this.transaction,
    required this.accent,
    this.canSelect = false,
    this.canLink = true,
  });

  /// "Bağla…" sunulsun mu (bkz. [transactionLinkApplicable]).
  final bool canLink;

  static Future<TransactionAction?> show(
    BuildContext context, {
    required TransactionEntity transaction,
    required Color accent,
    bool canSelect = false,
  }) {
    final canLink = transactionLinkApplicable(context);
    return showRowActionSheet<TransactionAction>(
      context,
      builder: (context) => TransactionActionSheet(
        transaction: transaction,
        accent: accent,
        canSelect: canSelect,
        canLink: canLink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return RowActionSheet<TransactionAction>(
      title: transaction.title,
      icon: transaction.isIncome
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded,
      accent: accent,
      // Kilitli işlemde Düzenle/Sil yerine neden kilitli olduğu yazar.
      notice: transaction.isSystem ? _systemNotice(context, cs) : null,
      actions: [
        if (transaction.isSystem) ...[
          if (isRemovableTransferLeg(transaction))
            RowAction(
              value: TransactionAction.removeTransfer,
              icon: Icons.link_off_rounded,
              title: l10n.transferiKaldir,
              subtitle: l10n.transferiKaldirAciklama,
              destructive: true,
            ),
        ] else ...[
          RowAction(
            value: TransactionAction.edit,
            icon: Icons.edit_rounded,
            color: Colors.blueGrey,
            title: l10n.duzenle,
            subtitle: l10n.duzenleSubtitle,
          ),
          RowAction(
            value: TransactionAction.duplicate,
            icon: Icons.content_copy_rounded,
            color: Colors.blueGrey,
            title: l10n.yenidenEkle,
            subtitle: l10n.yenidenEkleAciklama,
          ),
          if (transaction.id != null && canLink)
            RowAction(
              value: TransactionAction.link,
              icon: Icons.link_rounded,
              color: cs.primary,
              title: l10n.baglaEylemi,
              subtitle: l10n.baglaEylemiAciklama,
            ),
          if (canSelect && transaction.id != null && !transaction.isAdopted)
            RowAction(
              value: TransactionAction.select,
              icon: Icons.checklist_rounded,
              color: cs.primary,
              title: l10n.birdenCokSec,
              subtitle: l10n.birdenCokSecAciklama,
            ),
          RowAction(
            value: TransactionAction.delete,
            icon: Icons.delete_outline_rounded,
            title: l10n.islemiSil,
            subtitle: l10n.silSubtitle,
            destructive: true,
          ),
        ],
      ],
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
