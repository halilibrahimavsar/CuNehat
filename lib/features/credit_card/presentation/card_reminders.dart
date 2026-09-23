import 'dart:async';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';

/// Kart bilgisi (kesim/son ödeme günü, ekstre beyanı) değişince son ödeme
/// hatırlatmalarını yeniden kurdurur. Defter değişmediği için kendiliğinden
/// tetiklenmez (bkz. `ReminderSyncService` defter dinleyicisi). Kayıtlı servis
/// yoksa (yalıtılmış testler) sessizce geçer.
void resyncCardReminders(WalletEntity wallet) {
  if (!getIt.isRegistered<ReminderSyncService>()) return;
  unawaited(getIt<ReminderSyncService>().syncCard(wallet));
}
