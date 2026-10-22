import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/forecast/presentation/bloc/forecast_estimates_cubit.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_estimates_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('varsayılan KAPALI (önce plan)', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = ForecastEstimatesCubit(await SharedPreferences.getInstance());
    expect(cubit.state, isFalse);
  });

  test('kayıtlı tercih kurucuda EŞZAMANLI okunur', () async {
    SharedPreferences.setMockInitialValues({ForecastEstimatesCubit.key: true});
    final cubit = ForecastEstimatesCubit(await SharedPreferences.getInstance());
    expect(cubit.state, isTrue);
  });

  test('set yazar; yeni örnek aynı değeri okur', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await ForecastEstimatesCubit(prefs).set(true);
    expect(prefs.getBool(ForecastEstimatesCubit.key), isTrue);
    expect(ForecastEstimatesCubit(prefs).state, isTrue);
  });

  testWidgets('anahtar cubit\'i çevirir; sağlayıcı yoksa görünmez',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = ForecastEstimatesCubit(await SharedPreferences.getInstance());
    Widget app(Widget child) => MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        );

    await tester.pumpWidget(app(const ForecastEstimatesSwitch()));
    expect(
        find.byKey(const ValueKey('forecast-estimates-switch')), findsNothing);

    await tester.pumpWidget(app(BlocProvider.value(
      value: cubit,
      child: const ForecastEstimatesSwitch(),
    )));
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    expect(find.text(l10n.forecastEstimatesOffDesc), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('forecast-estimates-switch')));
    await tester.pumpAndSettle();
    expect(cubit.state, isTrue);
    expect(find.text(l10n.forecastEstimatesOnDesc), findsOneWidget);
  });
}
