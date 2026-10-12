import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/finance_transactions/domain/period_preferences.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/period_unit_editor.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/shared_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ayarlar'daki "Dönem" kartı — dönem biriminin TEK düzenlendiği yer (dönem
/// sayfası yalnız geçerli birimi söyler ve buraya yönlendirir).
class PeriodSettingsCard extends StatefulWidget {
  const PeriodSettingsCard({super.key});

  @override
  State<PeriodSettingsCard> createState() => _PeriodSettingsCardState();
}

class _PeriodSettingsCardState extends State<PeriodSettingsCard> {
  late final TransactionFilterCubit _cubit =
      context.read<TransactionFilterCubit>();
  late PeriodPreferences _prefs;

  @override
  void initState() {
    super.initState();
    // Ayarlar İşlemler'den önce açılmış olabilir: kayıtlı tercih buradan da
    // yüklenir.
    applyStoredPeriodPreferences(_cubit);
    _prefs = _cubit.periodPreferences;
  }

  Future<void> _change(PeriodPreferences next) async {
    setState(() => _prefs = next);
    await savePeriodPreferences(_cubit, next);
    _cubit.setPeriod(_cubit.basePeriod());
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: PeriodUnitEditor(value: _prefs, onChanged: _change),
    );
  }
}
