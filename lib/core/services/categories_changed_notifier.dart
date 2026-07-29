import 'dart:async';

import 'package:injectable/injectable.dart';

/// Kategori listesi değiştiğinde (ekleme, yeniden adlandırma, ikon, silme)
/// açık sayfaların görüntüleme indeksini tazelemesi için yayın kanalı.
///
/// Etiket/ikon haritaları sayfa seviyesinde `initState`'te BİR KEZ kuruluyordu.
/// Rapor / Analiz / Bütçeler route yığınında dururken kullanıcı bir kategoriyi
/// yeniden adlandırdığında `initState` yeniden çalışmadığı için sayfa geri
/// dönüldüğünde hâlâ eski adı basıyordu — yeniden adlandırma özelliği ancak
/// sayfa yeniden kurulduğunda görünür oluyordu.
///
/// Defter tarafındaki `TransactionsChangedNotifier` ile aynı desen; kategori
/// değişimi defteri değiştirmediği için ayrı bir kanaldır.
@lazySingleton
class CategoriesChangedNotifier {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  @disposeMethod
  void dispose() => _controller.close();
}
