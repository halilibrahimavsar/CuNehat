import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// İşlemler ekranının bakış açısı: yalnız gelirler, yalnız giderler ya da
/// ikisi birden.
enum FinanceMode {
  expense,
  income,
  compare;

  IconData get icon {
    switch (this) {
      case FinanceMode.expense:
        return Icons.trending_down_rounded;
      case FinanceMode.income:
        return Icons.trending_up_rounded;
      case FinanceMode.compare:
        return Icons.compare_arrows_rounded;
    }
  }

  /// Modun vurgu rengi. Kartların kullandığı [AppGradients] paletinden gelir:
  /// eskiden `Colors.red.shade700`/`green.shade700` sabitleriydi ve aynı
  /// ekrandaki işlem kartlarının kırmızısıyla tutmuyordu.
  Color get primaryColor {
    switch (this) {
      case FinanceMode.expense:
        return AppGradients.debt;
      case FinanceMode.income:
        return AppGradients.savings;
      case FinanceMode.compare:
        return AppGradients.transactions;
    }
  }
}

/// Modun kullanıcıya gösterilen adı.
///
/// Enum'un içinde sabit Türkçe metin olarak duruyordu; uygulama iki dilli
/// olduğu için İngilizce arayüzde de Türkçe görünüyordu.
extension FinanceModeLabel on FinanceMode {
  String label(AppLocalizations l10n) {
    switch (this) {
      case FinanceMode.expense:
        return l10n.txModeExpense;
      case FinanceMode.income:
        return l10n.txModeIncome;
      case FinanceMode.compare:
        return l10n.txModeCompare;
    }
  }
}
