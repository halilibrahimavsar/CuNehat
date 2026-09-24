import 'package:flutter/widgets.dart';

/// Uygulamanın hareket jetonları: süreler, eğriler ve azaltılmış hareket.
///
/// İşlemler, İçgörü ve Rapor sayfalarında süreler dağınık sabitlerdi (110,
/// 180, 220, 240, 280, 500, 600 ms) ve `MediaQuery.disableAnimations` yalnız
/// iki yerde (kart şeridi, işlem formu) dikkate alınıyordu: sistemde
/// "animasyonları kaldır" açık olan kullanıcı küp geçişlerini, segment
/// kaymasını ve iskelet nabzını yine görüyordu.
///
/// Kullanım: `AppMotion.of(context).d(AppMotion.medium)` — azaltılmış
/// harekette [Duration.zero] döner, yani geçiş anında olur ama DAVRANIŞ
/// (hangi içerik görünür) değişmez.
@immutable
class AppMotion {
  /// Küçük durum değişimleri: ikon dönüşü, basma geri bildirimi.
  static const Duration short = Duration(milliseconds: 150);

  /// İçerik değişimi: dönem geçişi, mod/görünüm değişimi, açılır satır.
  static const Duration medium = Duration(milliseconds: 250);

  /// Büyük yerleşim değişimi: sayfa içi büyük bölüm geçişleri.
  static const Duration long = Duration(milliseconds: 400);

  /// Girişte vurgulu yavaşlama (Material 3 "emphasized decelerate"e yakın).
  static const Curve enter = Curves.easeOutCubic;

  /// Çıkışta hızlanma.
  static const Curve exit = Curves.easeInCubic;

  /// Yerinde durum değişimi (segment göstergesi gibi).
  static const Curve standard = Curves.easeInOutCubic;

  /// Kullanıcı sistemde hareketi azaltmayı seçmiş mi?
  final bool reduced;

  const AppMotion({required this.reduced});

  factory AppMotion.of(BuildContext context) => AppMotion(
        reduced: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
      );

  /// [duration] ya da azaltılmış harekette [Duration.zero].
  Duration d(Duration duration) => reduced ? Duration.zero : duration;
}
