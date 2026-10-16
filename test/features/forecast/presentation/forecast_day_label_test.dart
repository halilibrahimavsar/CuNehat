import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/forecast/presentation/widgets/forecast_path_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR');
    Intl.defaultLocale = 'tr_TR';
  });

  final tr = lookupAppLocalizations(const Locale('tr'));
  final today = DateTime(2026, 11, 10, 15);

  test('tek başına büyük harfle, cümle içinde küçük harfle', () {
    expect(forecastDayLabel(tr, DateTime(2026, 11, 10), today), 'Bugün');
    expect(forecastDayLabel(tr, DateTime(2026, 11, 11), today), 'Yarın');
    // Cihazda görüldü: "Bu hızla Bugün dolar".
    expect(forecastDayLabel(tr, DateTime(2026, 11, 10), today, inline: true),
        'bugün');
    expect(
        tr.forecastBudgetFillsOn(
            forecastDayLabel(tr, DateTime(2026, 11, 11), today, inline: true)),
        'Bu hızla yarın dolar');
    expect(forecastDayLabel(tr, DateTime(2026, 11, 25), today), '25 Kas');
  });
}
