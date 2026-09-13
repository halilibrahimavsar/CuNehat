import 'package:bloc/bloc.dart';

/// Kapanmış bir Cubit'e gelen `emit`'i düşürür.
///
/// Neden: sayfaya bağlı Cubit'ler (`BlocProvider(create:)`) sayfa kapanınca
/// kapanır, ama başlattıkları iş (dosya ayrıştırma, deftere toplu yazım, geri
/// yükleme) sürmeye devam eder. Cubit'in `emit`i kapanıştan sonra
/// `StateError` fırlatıyor (bloc 9.1.0, `BlocBase.emit`) ve hata işin
/// ORTASINDA fırladığı için kalan adımlar hiç çalışmıyordu: ekstre içe
/// aktarımında geri tuşuna basılınca kalan satırlar yazılmıyor, bakiye
/// senkronu ve defter bildirimi atlanıyordu.
///
/// Bloc'un kendi `Emitter`ı kapanıştan sonra zaten sessizce düşürür; bu mixin
/// Cubit'lere aynı davranışı verir. Düşen şey yalnız artık kimsenin
/// dinlemediği bir UI durumudur — yazımlar ve bildirimler sürer.
mixin SafeEmitMixin<S> on BlocBase<S> {
  @override
  void emit(S state) {
    if (isClosed) return;
    super.emit(state);
  }
}
