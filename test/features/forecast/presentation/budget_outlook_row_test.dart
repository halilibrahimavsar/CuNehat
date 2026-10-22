import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/features/forecast/domain/forecast_models.dart';
import 'package:cunehat/features/forecast/presentation/bloc/forecast_estimates_cubit.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gelecek ve Rapor'un ortak bütçe satırı: durum PLANA dayanır, tahmin
/// açıkken hızın yorumu altına MOR satır olarak eklenir.
void main() {
  setUp(() => Intl.defaultLocale = 'tr_TR');
  final today = DateTime(2026, 11, 10);
  const money = MoneyWriter(currency: 'TRY', visible: true);

  // Harcanan 900, planlı 200 (20 Kas), hızla 25 Kas'ta doluyor; limit 1.000.
  final outlook = BudgetOutlook(
    id: 'food',
    walletId: 'w',
    categoryId: 'food',
    limit: 1000,
    spent: 900,
    knownRemaining: 200,
    paceRemaining: 500,
    paceRemainingHigh: 600,
    fillDate: DateTime(2026, 11, 12),
    plannedFillDate: DateTime(2026, 11, 20),
    requiredDaily: null,
    periodStart: DateTime(2026, 11, 1),
    periodEnd: DateTime(2026, 11, 30),
    status: BudgetOutlookStatus.atRisk,
  );

  Future<AppLocalizations> pump(WidgetTester tester,
      {bool? estimates, ForecastEstimatesCubit? cubit}) async {
    final row = BudgetOutlookRow(
      outlook: outlook,
      money: money,
      today: today,
      categoryLabels: const {'food': 'Yeme'},
      estimates: estimates,
    );
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body:
            cubit == null ? row : BlocProvider.value(value: cubit, child: row),
      ),
    ));
    await tester.pumpAndSettle();
    return AppLocalizations.delegate.load(const Locale('tr'));
  }

  testWidgets('PLAN: planlılarla dolma günü; hız yorumu yok', (tester) async {
    final l10n = await pump(tester, estimates: false);
    expect(
        find.text(l10n.forecastBudgetPlannedFillsOn('20 Kas')), findsOneWidget);
    expect(find.text(l10n.forecastBudgetFillsOn('12 Kas')), findsNothing);
    expect(find.byKey(const ValueKey('forecast-budget-estimate-food')),
        findsNothing);
  });

  testWidgets('TAHMİN: plan durumu kalır, hız yorumu mor satır',
      (tester) async {
    final l10n = await pump(tester, estimates: true);
    expect(
        find.text(l10n.forecastBudgetPlannedFillsOn('20 Kas')), findsOneWidget);
    final line = find.byKey(const ValueKey('forecast-budget-estimate-food'));
    expect(line, findsOneWidget);
    expect(
        tester.widget<Text>(line).data, l10n.forecastBudgetFillsOn('12 Kas'));
  });

  testWidgets('bayrak verilmezse uygulama ayarını izler (Rapor)',
      (tester) async {
    SharedPreferences.setMockInitialValues({ForecastEstimatesCubit.key: true});
    final cubit = ForecastEstimatesCubit(await SharedPreferences.getInstance());
    addTearDown(cubit.close);
    await pump(tester, cubit: cubit);
    expect(find.byKey(const ValueKey('forecast-budget-estimate-food')),
        findsOneWidget);

    await cubit.set(false);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('forecast-budget-estimate-food')),
        findsNothing);
  });
}
