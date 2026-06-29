import 'dart:async';

import 'package:injectable/injectable.dart';

/// Bir işlem defteri değişiminin bağlamı: hangi kullanıcı/cüzdan etkilendi.
/// App-ömürlü dinleyiciler (ör. bütçe uyarı monitörü) doğru cüzdanın bütçesini
/// kontrol edebilsin diye taşınır. Çoğu dinleyici yalnız "değişti" sinyalini
/// kullanır ve bu bağlamı yok sayar; alanlar bu yüzden opsiyoneldir.
class TransactionsChange {
  final String? userId;
  final String? walletId;

  const TransactionsChange({this.userId, this.walletId});
}

/// İşlem defteri değiştiğinde (ekleme/silme/güncelleme, recurring onayı,
/// CSV import) ilgilenen bloc'ların kendilerini yenilemesi için yayın kanalı.
/// Bloc'lar arası doğrudan bağımlılık kurmadan stale-state'i önler.
@lazySingleton
class TransactionsChangedNotifier {
  final _controller = StreamController<TransactionsChange>.broadcast();

  Stream<TransactionsChange> get stream => _controller.stream;

  void notify({String? userId, String? walletId}) {
    if (!_controller.isClosed) {
      _controller.add(TransactionsChange(userId: userId, walletId: walletId));
    }
  }

  @disposeMethod
  void dispose() => _controller.close();
}
