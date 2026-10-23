import 'dart:async';

import 'package:injectable/injectable.dart';

/// Tahminin PLAN girdileri değişince (düzenli şablon, borç/kredi, alacak,
/// cüzdan ve kart ayarları) açık tahmin yüzeylerinin tazelenmesi için yayın
/// kanalı.
///
/// Gelecek ve Bakiye Hattı defter ve bütçe değişimini dinliyordu; ama yeni
/// bir kira şablonu, kredi ya da kartın kesim günü defteri değiştirmez.
/// İşlemler açıkken eklenen 1 Ara kira şablonu, uygulama arka plana atılıp
/// dönülene kadar hatta görünmüyordu (QA O3). [BudgetsChangedNotifier] ile
/// aynı desen; ayrı kanal, çünkü bu değişimler ne defteri ne bütçeyi
/// etkiler.
@lazySingleton
class PlansChangedNotifier {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  @disposeMethod
  void dispose() => _controller.close();
}
