import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/widgets/app_date_range_picker.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

// İşlemler, İçgörü ve Rapor TEK dönemi paylaşır: sahibi uygulama düzeyindeki
// [TransactionFilterCubit].
//
// Eskiden her sayfa kendi dönemini tutuyordu. Cihazda aynı anda İşlemler
// "29 Haz – 24 Eyl", İçgörü "Eylül 2026", Rapor "Ağustos 2026" gösterdi:
// kullanıcı bir sayfada ay değiştirip yan sayfaya geçtiğinde başka bir ayın
// rakamlarına bakıyordu. Kart ekstre dönemini de yalnız İşlemler biliyordu.
// Arama ve kategori süzgeci PAYLAŞILMAZ, onları yalnız İşlemler okur.

/// Kart bağlamında ekstre dönemindeyken "Ekstre · 16 Eyl – 15 Eki";
/// değilse `null` (çubuk dönemin kendi etiketini yazar).
String? statementPeriodLabel(
    TransactionFilterCubit cubit, AppLocalizations l10n) {
  if (!cubit.isStatementPeriod) return null;
  return l10n.kkEkstreDonemEtiketi(periodLabel(cubit.period, l10n));
}

/// Ortak süzgeci sayfanın cüzdanına bağlar: arama/kategori cüzdana özeldir
/// ([TransactionFilterCubit.bindWallet]), kart bağlamında dönem EKSTRE
/// döngüsünü izler ([TransactionFilterCubit.useStatementCycle]).
///
/// Üç sayfa da kurulurken çağırır. Eskiden yalnız İşlemler çağırıyordu; o
/// sayfa alt görünüm açıkken güncellenmediği için Rapor'dan karta geçen
/// kullanıcı takvim ayına bakmaya devam ediyordu (cihazda görüldü).
void bindSharedPeriodTo(BuildContext context, WalletEntity? wallet) {
  context.read<TransactionFilterCubit>()
    ..bindWallet(wallet?.id)
    ..useStatementCycle(FeatureFlags.creditCards ? wallet?.creditCard : null);
}

/// Ortak dönem seçicisi. Kart bağlamında ekstre seçenekleri başta gelir.
Future<void> pickSharedPeriod(BuildContext context) async {
  final cubit = context.read<TransactionFilterCubit>();
  final l10n = context.l10n;
  final current = cubit.currentStatementPeriod();
  final cycle = cubit.statementCycle;

  final dateRange = await AppDateRangePicker.pick(
    context,
    initialDateRange: cubit.period,
    quickOptions: [
      if (current != null && cycle != null) ...[
        IboDateRangeQuickOption(label: l10n.kkBuEkstre, range: current),
        IboDateRangeQuickOption(
          label: l10n.kkOncekiEkstre,
          range: () {
            final p = cycle
                .periodEndingAt(cycle.shiftClosing(dayOf(current.end), -1));
            return DateTimeRange(
              start: p.start,
              end: DateTime(p.end.year, p.end.month, p.end.day, 23, 59, 59),
            );
          }(),
        ),
      ],
      ...DateRangeHelper.buildDateRangeQuickOptions(l10n),
    ],
  );

  if (dateRange != null) cubit.setPeriod(dateRange);
}

/// Ortak dönemi gösteren ve değiştiren `‹ Eylül 2026 ›` çubuğu.
class SharedPeriodBar extends StatelessWidget {
  const SharedPeriodBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<TransactionFilterCubit>();
    return TransactionPeriodBar(
      range: cubit.period,
      label: statementPeriodLabel(cubit, context.l10n),
      onStep: cubit.stepPeriod,
      onPick: () => pickSharedPeriod(context),
    );
  }
}
