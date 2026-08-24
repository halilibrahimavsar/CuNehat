import 'package:flutter/widgets.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/deletion_undo_service.dart';

/// Silme sonrası "Geri al" mesajını gösterir.
///
/// [context] yalnız metinleri okumak için kullanılır (senkron); mesajın
/// yaşam döngüsü çağıran widget'a bağlı DEĞİLDİR (bkz. [AppMessenger]).
/// [undoneMessage] verilmezse "Silme geri alındı" kullanılır; silme dışı geri
/// alınabilir eylemler (ör. kısmi satış) kendi cümlesini geçirir.
void showDeletionMessage(
  BuildContext context, {
  required String message,
  required DeletionUndo? undo,
  String? undoneMessage,
}) {
  final l = context.l10n;
  showDeletionMessageWithTexts(
    message: message,
    undo: undo,
    undoLabel: l.geriAl,
    undoneMessage: undoneMessage ?? l.silmeGeriAlindi,
    undoFailedMessage: l.silmeGeriAlinamadi,
  );
}

/// [showDeletionMessage]'ın metinleri dışarıdan alan çekirdeği: geri alma
/// penceresini yönetir ve pencere kapanınca silmeyi kesinleştirir.
///
/// [undo] null ise (geri alma bilgisi toplanamadı) düz bir başarı mesajı
/// gösterilir — silme yapıldı, yalnız geri alma sunulmaz.
@visibleForTesting
void showDeletionMessageWithTexts({
  required String message,
  required DeletionUndo? undo,
  required String undoLabel,
  required String undoneMessage,
  required String undoFailedMessage,
}) {
  if (undo == null) {
    AppMessenger.success(message);
    return;
  }

  final service = getIt<DeletionUndoService>();

  // Eylem tetiklendi mi? `closed` sebebine bakmak yeterli değil: eylem
  // snackbar'ı `AppMessenger.hide()` ile kapatıyor, bu da
  // `SnackBarClosedReason.hide` üretir — yani "geri alındı" ile "yeni mesaj
  // devraldı" ayırt edilemezdi. Bayrak niyeti doğrudan taşır.
  var undoRequested = false;

  final handle = AppMessenger.success(
    message,
    action: AppMessageAction(
      label: undoLabel,
      onPressed: () async {
        undoRequested = true;
        final ok = await service.restore(undo);
        if (ok) {
          AppMessenger.success(undoneMessage);
        } else {
          AppMessenger.error(undoFailedMessage);
        }
      },
    ),
  );

  if (handle == null) {
    // Mesaj hiç gösterilemedi (messenger bağlı değil) → geri alma penceresi
    // de yok; silmeyi hemen kesinleştir, yoksa fiş dosyası öksüz kalırdı.
    service.commit(undo);
    return;
  }

  handle.closed.then((_) {
    if (!undoRequested) service.commit(undo);
  });
}
