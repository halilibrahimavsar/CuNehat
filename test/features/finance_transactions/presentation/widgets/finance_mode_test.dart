import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FinanceMode', () {
    test('icon getter returns correct icons', () {
      expect(FinanceMode.expense.icon, Icons.trending_down_rounded);
      expect(FinanceMode.income.icon, Icons.trending_up_rounded);
      expect(FinanceMode.compare.icon, Icons.compare_arrows_rounded);
    });

    test('vurgu renkleri kartlarla aynı paletten gelir', () {
      expect(FinanceMode.expense.primaryColor, AppGradients.debt);
      expect(FinanceMode.income.primaryColor, AppGradients.savings);
      expect(FinanceMode.compare.primaryColor, AppGradients.transactions);
    });

    test('etiketler l10n\'den gelir (sabit Türkçe metin değil)', () async {
      final tr = await AppLocalizations.delegate.load(const Locale('tr'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));

      expect(FinanceMode.expense.label(tr), 'Giderler');
      expect(FinanceMode.income.label(tr), 'Gelirler');
      expect(FinanceMode.compare.label(tr), 'Karşılaştırma');

      expect(FinanceMode.expense.label(en), 'Expenses');
      expect(FinanceMode.income.label(en), 'Income');
      expect(FinanceMode.compare.label(en), 'Compare');
    });
  });
}
