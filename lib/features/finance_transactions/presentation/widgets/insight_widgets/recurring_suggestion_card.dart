import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_pattern_detector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tespit edilen tekrarlayan ödeme öneri kartı.
///
/// İki eylem taşır. "Yoksay" olmadan öneri **kalıcıydı**: kullanıcı istemediği
/// bir örüntüyü (nakit çekme, arkadaşa gönderilen sabit tutar) her açılışta
/// yeniden görüyordu ve tek kurtuluşu şablonu gerçekten eklemekti.
class RecurringSuggestionCard extends StatelessWidget {
  final RecurringSuggestion suggestion;
  final MoneyWriter money;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  const RecurringSuggestionCard({
    super.key,
    required this.suggestion,
    required this.money,
    required this.onAdd,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = suggestion.type == TransactionTypeModel.income
        ? AppGradients.savings
        : AppGradients.debt;
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.autorenew_rounded, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  money(suggestion.amount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              // Sıradaki vade de yazılır: "aylık · 4 kez tekrarlandı" öneriyi
              // anlatıyor ama şablonun İLK NE ZAMAN işleyeceğini söylemiyordu,
              // oysa ekleme düğmesinin sonucu tam olarak bu.
              '${suggestion.frequency.displayName} • '
              '${context.l10n.kezTekrarlandi(suggestion.occurrenceCount)} • '
              '${DateFormat.yMMMd(locale).format(suggestion.nextExecutionDate)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            // [Row] DEĞİL [Wrap]: iki düğme 360dp'de yan yana sığmıyordu.
            // Ölçüldü — "Yoksay" + ikonlu "Düzenli Ödeme olarak ekle" satırı
            // 296dp'lik kart içinde **16px taşıyordu**. İkon kaldırıldı
            // (metin zaten eylemi söylüyor) ve satır artık taşmak yerine
            // alta iniyor; metin ölçeği büyütülmüş cihazlarda da güvenli.
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: onDismiss,
                  child: Text(context.l10n.insightDismissSuggestion),
                ),
                FilledButton.tonal(
                  onPressed: onAdd,
                  child: Text(context.l10n.duzenliOdemeOlarakEkle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
