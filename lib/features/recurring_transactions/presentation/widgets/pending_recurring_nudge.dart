import 'package:flutter/material.dart';

import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_dialog_surface.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';

import '../../domain/entities/recurring_transaction_entity.dart';

/// Açılışta çıkan **ince** hatırlatma.
///
/// Onay/atlama/silme gibi eylemler burada değil, Düzenli İşlemler sayfasında:
/// aynı listeyi iki yerde etkileşimli tutmak hem bakım yükü hem de dar bir
/// diyalogda kötü bir deneyimdi. Bu yüzey yalnızca "deftere işlenmemiş kalem
/// var" bilgisini verir ve sayfaya götürür.
///
/// Dönüş değeri: `true` = kullanıcı "Sonra" dedi (aynı bekleyen küme için
/// tekrar gösterilmez), `false`/`null` = incelemeye gitti veya kapandı.
class PendingRecurringNudge extends StatelessWidget {
  final List<RecurringTransactionEntity> pending;

  const PendingRecurringNudge({super.key, required this.pending});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final oldestDelay = _oldestDelayInDays();

    return AppDialogSurface(
      maxWidth: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_active_rounded,
              size: 40, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            l10n.recurringNudgeCount(pending.length),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _totalsLine(context),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          if (oldestDelay > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.recurringNudgeOldest(oldestDelay),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.error,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.sonra),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.incele),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _oldestDelayInDays() {
    final now = DateTime.now();
    var maxDays = 0;
    for (final template in pending) {
      final days = now.difference(template.nextExecutionDate).inDays;
      if (days > maxDays) maxDays = days;
    }
    return maxDays;
  }

  /// Bekleyen tutarların para birimi başına toplamı.
  ///
  /// Cüzdanların para birimi farklı olabilir (TRY/USD/EUR); tek bir TL
  /// rakamına çevirmek kur dalgalanmasını bu sayıya taşırdı, bu yüzden
  /// birimler ayrı gösterilir.
  String _totalsLine(BuildContext context) {
    final totals = <String, double>{};
    for (final template in pending) {
      final currency =
          context.walletById(template.walletId)?.currency ?? kDefaultCurrency;
      totals[currency] = (totals[currency] ?? 0) + template.amount;
    }
    final parts = totals.entries
        .map((e) => formatMoney(e.value, currency: e.key))
        .toList()
      ..sort();
    return parts.join(' · ');
  }
}
