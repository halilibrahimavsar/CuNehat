import 'dart:async';

import 'package:injectable/injectable.dart';

/// İşlem defteri değiştiğinde (ekleme/silme/güncelleme, recurring onayı,
/// CSV import) ilgilenen bloc'ların kendilerini yenilemesi için yayın kanalı.
/// Bloc'lar arası doğrudan bağımlılık kurmadan stale-state'i önler.
@lazySingleton
class TransactionsChangedNotifier {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  @disposeMethod
  void dispose() => _controller.close();
}
