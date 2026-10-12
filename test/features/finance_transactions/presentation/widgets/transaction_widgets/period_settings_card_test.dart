import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/period_preferences.dart';
import 'package:cunehat/features/finance_transactions/domain/transaction_period.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/period_settings_card.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_widgets/transaction_period_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Dönem birimi yalnız Ayarlar'da düzenlenir (dönem sayfasından kaldırıldı);
/// bu test o tek yolun ortak süzgeci gerçekten değiştirdiğini kilitler.
void main() {
  setUpAll(() => Intl.defaultLocale = 'tr');

  testWidgets('Hafta + Çarşamba seçilince ortak dönem o haftaya geçer',
      (tester) async {
    final cubit = TransactionFilterCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(BlocProvider<TransactionFilterCubit>.value(
      value: cubit,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('tr'), Locale('en')],
        locale: Locale('tr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: PeriodSettingsCard(),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hafta'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('week-start-3')));
    await tester.pumpAndSettle();

    const prefs =
        PeriodPreferences(unit: PeriodUnit.week, weekStart: DateTime.wednesday);
    final expected = prefs.periodContaining(DateTime.now());
    final label =
        periodLabel(expected, lookupAppLocalizations(const Locale('tr')));

    expect(find.text('Bu dönem: $label'), findsOneWidget);
    expect(cubit.periodPreferences.unit, PeriodUnit.week);
    expect(cubit.periodPreferences.weekStart, DateTime.wednesday);
    expect(isSameDayValue(cubit.period.start, expected.start), isTrue);
    expect(isSameDayValue(cubit.period.end, expected.end), isTrue);
  });
}
