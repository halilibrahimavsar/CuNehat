import 'dart:async';

import 'package:injectable/injectable.dart';

/// Bütçe limitleri değiştiğinde (ekleme, güncelleme, silme) açık sayfaların
/// kendi kopyalarını tazelemesi için yayın kanalı.
///
/// Rapor sayfası bütçeleri `initState`'te BİR KEZ okuyor. Alt görünümler
/// kaydırma yığınında canlı kaldığı için, kullanıcı Bütçeler sayfasında bir
/// limiti değiştirip rapora geri kaydırdığında `initState` yeniden çalışmıyor
/// ve rapor eski limiti göstermeye devam ediyordu — kategori yeniden
/// adlandırmada çözülen hatanın aynısı.
///
/// [CategoriesChangedNotifier] ile aynı desen; bütçe değişimi ne defteri ne de
/// kategori listesini değiştirdiği için ayrı bir kanaldır.
@lazySingleton
class BudgetsChangedNotifier {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  @disposeMethod
  void dispose() => _controller.close();
}
