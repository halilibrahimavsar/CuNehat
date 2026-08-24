import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:flutter/widgets.dart';

/// [InvestmentNotice]'ın kullanıcıya gösterilecek metni. Bloc metin üretmez;
/// çeviri burada, sunum katmanında çözülür.
///
/// [cashOk] false ise sona nakit uyarısı eklenir: kayıt yazıldı ama cüzdan
/// bakiyesi güncellenemedi (bkz. `CashCouplingMixin.cashWarning`).
String investmentNoticeText(
  BuildContext context,
  InvestmentNotice notice, {
  bool cashOk = true,
}) {
  final l10n = context.l10n;
  final text = switch (notice) {
    RawFailureNotice(:final message) => message,
    GoalSavedNotice() => l10n.hedefKaydedildiMesaji,
    GoalDeletedNotice() => l10n.hedefSilindiMesaji,
    InvestmentAddedNotice() => l10n.yatirimEklendiMesaji,
    InvestmentUpdatedNotice() => l10n.yatirimGuncellendiMesaji,
    InvestmentSoldNotice() => l10n.yatirimSatildiMesaji,
    InvestmentPartiallySoldNotice() => l10n.yatirimKismenSatildiMesaji,
    InvestmentDeletedNotice() => l10n.yatirimSilindiDuzeltildiMesaji,
    NoRefreshablePricesNotice() => l10n.yenilenebilirYatirimYokMesaji,
    PricesUnavailableNotice() => l10n.fiyatlarAlinamadiMesaji,
    PricesRefreshedNotice(:final updated, :final failed) => failed == 0
        ? l10n.fiyatlarGuncellendiMesaji(updated)
        : l10n.fiyatlarKismenGuncellendiMesaji(updated, failed),
  };
  return cashOk ? text : '$text${l10n.bakiyeGuncellenemediUyarisi}';
}
