import 'package:shared_preferences/shared_preferences.dart';
import 'package:cunehat/features/finance_transactions/domain/period_preferences.dart';
import 'package:cunehat/features/finance_transactions/data/period_preferences_store.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/widgets/app_date_range_picker.dart';
import 'package:cunehat/core/utils/date_range_helper.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
  applyStoredPeriodPreferences(context.read<TransactionFilterCubit>());
  context.read<TransactionFilterCubit>()
    ..bindWallet(wallet?.id)
    ..useStatementCycle(FeatureFlags.creditCards ? wallet?.creditCard : null);
}

/// Kayıtlı dönem birimini (gün / hafta / 2 hafta / ay) süzgece uygular.
/// Kalıcı bir ayar: uygulama her açılışta kullanıcının birimiyle başlar.
void applyStoredPeriodPreferences(TransactionFilterCubit cubit) {
  if (!getIt.isRegistered<SharedPreferences>()) return;
  cubit.usePeriodPreferences(
      PeriodPreferencesStore(getIt<SharedPreferences>()).read());
}

/// Tercihi hem saklar hem ortak süzgece uygular.
Future<void> savePeriodPreferences(
    TransactionFilterCubit cubit, PeriodPreferences prefs) async {
  cubit.usePeriodPreferences(prefs);
  if (!getIt.isRegistered<SharedPreferences>()) return;
  await PeriodPreferencesStore(getIt<SharedPreferences>()).write(prefs);
}

/// Ortak dönem sayfası: hazır aralıklar ve takvim. Kart bağlamında ekstre
/// seçenekleri başta gelir.
///
/// Dönem BİRİMİ (gün / hafta / 2 hafta / ay + başlangıç) burada
/// DÜZENLENMEZ, yalnız Ayarlar'da ([PeriodSettingsCard]). Eskiden sayfanın
/// en üstünde duruyordu: "hangi tarihe bakayım" diye gelen kullanıcı önce
/// kalıcı bir ayarla karşılaşıyor, birime dokununca seçtiği aralık da
/// değişiyordu (kullanıcı şikâyeti, 12 Eki 2026). Sayfada yalnız geçerli
/// birimi söyleyen ve Ayarlar'a götüren tek satır kaldı.
Future<void> pickSharedPeriod(BuildContext context) async {
  final cubit = context.read<TransactionFilterCubit>();
  final l10n = context.l10n;
  final current = cubit.currentStatementPeriod();
  final cycle = cubit.statementCycle;

  final quickOptions = [
    if (current != null && cycle != null) ...[
      IboDateRangeQuickOption(label: l10n.kkBuEkstre, range: current),
      IboDateRangeQuickOption(
        label: l10n.kkOncekiEkstre,
        range: () {
          final p =
              cycle.periodEndingAt(cycle.shiftClosing(dayOf(current.end), -1));
          return DateTimeRange(
            start: p.start,
            end: DateTime(p.end.year, p.end.month, p.end.day, 23, 59, 59),
          );
        }(),
      ),
    ],
    ...DateRangeHelper.buildDateRangeQuickOptions(l10n),
  ];

  final result = await showModalBottomSheet<_PeriodSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PeriodSheet(
      unit: cubit.periodPreferences.unit,
      quickOptions: quickOptions,
    ),
  );
  if (result == null || !context.mounted) return;
  if (result.openSettings) {
    // Yönlendiricisiz ağaçta (yalıtılmış sayfa testleri) sessizce geçilir.
    GoRouter.maybeOf(context)?.push(AppRoutes.settings);
    return;
  }
  if (result.range != null) {
    cubit.setPeriod(result.range!);
    return;
  }
  final picked =
      await AppDateRangePicker.pick(context, initialDateRange: cubit.period);
  if (picked != null) cubit.setPeriod(picked);
}

class _PeriodSheetResult {
  final DateTimeRange? range;
  final bool openSettings;
  const _PeriodSheetResult.range(DateTimeRange this.range)
      : openSettings = false;
  const _PeriodSheetResult.calendar()
      : range = null,
        openSettings = false;
  const _PeriodSheetResult.settings()
      : range = null,
        openSettings = true;
}

/// [unit]'in kısa adı ("Ay", "Hafta" …).
String periodUnitName(PeriodUnit unit, AppLocalizations l10n) => switch (unit) {
      PeriodUnit.day => l10n.periodUnitDay,
      PeriodUnit.week => l10n.periodUnitWeek,
      PeriodUnit.biweek => l10n.periodUnitBiweek,
      PeriodUnit.month => l10n.periodUnitMonth,
    };

class _PeriodSheet extends StatelessWidget {
  /// Geçerli dönem birimi — yalnız bilgi olarak gösterilir.
  final PeriodUnit unit;
  final List<IboDateRangeQuickOption> quickOptions;

  const _PeriodSheet({required this.unit, required this.quickOptions});

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.8),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Material(
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      Icon(Icons.date_range_rounded,
                          size: 20, color: cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text(
                        l10n.periodSheetTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionLabel(context, l10n.periodQuickSection),
                for (final option in quickOptions)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    onTap: () => Navigator.of(context)
                        .pop(_PeriodSheetResult.range(option.range)),
                  ),
                Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: cs.onSurface.withValues(alpha: 0.10),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: Icon(Icons.calendar_today_rounded,
                      size: 20, color: cs.primary),
                  title: Text(
                    l10n.takvimdenSec,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  onTap: () => Navigator.of(context)
                      .pop(const _PeriodSheetResult.calendar()),
                ),
                Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: cs.onSurface.withValues(alpha: 0.10),
                ),
                ListTile(
                  key: const ValueKey('period-unit-settings'),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: Icon(Icons.tune_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                  title: Text(
                    l10n.periodUnitCurrent(periodUnitName(unit, l10n)),
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  trailing: Text(
                    l10n.periodUnitChangeInSettings,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  onTap: () => Navigator.of(context)
                      .pop(const _PeriodSheetResult.settings()),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
