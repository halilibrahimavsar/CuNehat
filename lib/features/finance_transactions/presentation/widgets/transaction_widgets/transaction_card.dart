import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/confirm_dialog.dart';
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
///
/// Dokununca tek-işlem detay sayfasını açar. Düzenle/sil için iki yol vardır ve
/// ikisi de aynı eylemlere çıkar:
/// - **uzun bas → eylem sayfası** ([TransactionActionSheet])
/// - detay sayfasındaki düğmeler
///
/// **Kaydırma eylemleri KALDIRILDI (29 Ağu 2026, cihaz duman testi).** Sola
/// kaydırmak onaysız siliyordu ve %32'lik eşik listede gezinirken yanlışlıkla
/// aşılabiliyordu: tek bir kazara jest bir kaydı yok ediyordu. Kaydırma
/// bir zamanlar "uzun basmanın görsel ipucu yok" diye eklenmişti; o boşluğu
/// kapatmanın yolu yıkıcı bir eylemi tek jeste bağlamak değil.
///
/// **Görsel ipucu artık var (3 Eyl 2026):** kartın sağındaki kalıcı ⋮
/// düğmesi aynı eylem sayfasını açar. Uzun bas da çalışmaya devam eder ama
/// tek keşif yolu olmaktan çıktı — kaydırma kalktığından beri ekranda
/// düzenle/sil'e giden hiçbir görünür işaret kalmamıştı.
///
/// Yan etki: satırlar artık yatay sürüklemeyi yutmuyor, yani `MainContentSwipe`
/// sayfa jesti liste üzerinde de çalışır.
class TransactionCard extends StatelessWidget {
  final TransactionWithBalance item;
  final IconData? categoryIcon;

  /// Kategorinin çözülmüş görünen adı (`categoryIcon` ile aynı kanal).
  /// null ise `tag` l10n'a düşer — sistem etiketleri ve silinmiş
  /// kategorilerden kalan tag'ler için doğru davranış budur.
  final String? categoryLabel;

  const TransactionCard({
    super.key,
    required this.item,
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
        _edit(context);
      case TransactionAction.delete:
        await _delete(context);
    }
  }

  void _edit(BuildContext context) {
    final t = item.transaction;
    TransactionSheetHandler.showSheet(
      context: context,
      userId: t.userId,
      walletId: t.walletId,
      type: t.type,
      initialTransaction: t,
    );
  }

  /// Onay VE geri alma birlikte; ikisi farklı hataları yakalar: onay
  /// *yanlışlıkla* silmeyi durdurur, snackbar'daki "Geri al" (bkz.
  /// [showDeletionMessage]) *bilerek* verilip pişman olunan kararı kurtarır.
  ///
  /// Bu yorumun eski hali "onay diyaloğu YOK" diyordu ve gerekçesi "kaydırma
  /// hızlı yol, modal onu yavaşlatıyor"du. Kaydırma kaldırıldı (bkz. sınıf
  /// dokümanı), yani o gerekçe de kalktı.
  Future<void> _delete(BuildContext context) async {
    final id = item.transaction.id;
    if (id == null) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: context.l10n.islemiSil,
      message: context.l10n.islemSilOnayMesaji(item.transaction.title),
      confirmText: context.l10n.sil,
      danger: true,
    );
    if (!confirmed || !context.mounted) return;

    context.read<TransactionBloc>().add(DeleteTransactionEvent(id));
  }

  @override
  Widget build(BuildContext context) => _buildCard(context);

  Widget _buildCard(BuildContext context) {
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
      // Satır yazı ölçeğine duyarlı olmalı: ölçek 2.0'da "−18.500,00 ₺"
      // 17px yerine 34px çiziliyor ve başlık sütununu 40dp'ye düşürüp satırı
      // 24px taşırıyordu (ölçüldü). Tutar artık satırın en çok [_amountShare]
      // kadarını alabilir, fazlası `scaleDown` ile küçülür.
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
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
                  // Saat en az değerli veri: gün zaten yapışkan başlıkta yazılı.
                  // Sütun daraldığında (büyük yazı ölçeği) kategori çipine yer
                  // açmak için düşer — kırpılmış bir "1…" kimseye bir şey
                  // söylemez.
                  LayoutBuilder(
                    builder: (context, inner) => Row(
                      children: [
                        if (t.tag.isNotEmpty)
                          _categoryChip(context, accent, t.tag),
                        if (inner.maxWidth >= _timeMinWidth) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              AppFormatters.time.format(t.date),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Baskın tutar
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: constraints.maxWidth * _amountShare),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: SignedMoneyText(
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
              ),
            ),

            // Eylem menüsü: uzun basmanın GÖRÜNÜR karşılığı.
            _ActionButton(onTap: () => _showActionSheet(context, accent)),
          ],
        ),
      ),
    );
  }

  /// Tutarın satırdan alabileceği en büyük pay. Normal ölçekte tutar bunun
  /// altında kalır (ölçüldü: 328dp'lik kartta "-749,90 ₺" 69dp), yani sınır
  /// yalnız yazı büyüdüğünde devreye girer.
  static const double _amountShare = 0.45;

  /// Saatin çizilmesi için başlık sütununda gereken en az genişlik.
  static const double _timeMinWidth = 110;

  Widget _categoryChip(BuildContext context, Color accent, String tag) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          categoryLabel ?? context.translateSystemTag(tag),
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

/// Kartın sağındaki ⋮ — [TransactionActionSheet]'i açar.
///
/// Kartın kendi `onTap`'i (detay sayfası) DIŞARIDA bir `GestureDetector`;
/// buradaki `InkResponse` daha içeride olduğu için dokunma arenasını o
/// kazanır ve ⋮'ye basmak detayı açmaz.
class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ActionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: context.l10n.txRowActions,
      child: Tooltip(
        message: context.l10n.txRowActions,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 20,
          child: SizedBox(
            width: 30,
            height: 40,
            child: Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
