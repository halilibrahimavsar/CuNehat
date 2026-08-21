/// Sürükleme bitişinde hedef indeks.
///
/// Eskiden hem yatay hem dikey eksende YALNIZ konuma bakılıyordu
/// (`(offset / extent).round()`), hız hiç okunmuyordu: %20 yol almış hızlı bir
/// fiske hiçbir şey yapmadan geri yaslanıyordu. Modern sayfa geçişlerinde
/// (bkz. `PageView`) hızlı fiske kısa yol almış olsa bile bir adım ilerletir.
///
/// [position] kesirli indeks (ör. 0.35 = birinci ile ikinci öğe arasında).
/// [direction] fiskenin yönü: +1 artan indeks, -1 azalan indeks, 0 fiske yok.
/// Yön eşiği çağıranda belirlenir; çünkü eşik eksenin kendi biriminde
/// (px/s) anlamlıdır.
int resolveDragTarget({
  required double position,
  required int direction,
  required int maxIndex,
}) {
  final int target;
  if (direction > 0) {
    target = position.floor() + 1;
  } else if (direction < 0) {
    target = position.ceil() - 1;
  } else {
    target = position.round();
  }
  return target.clamp(0, maxIndex);
}

/// Bir eksendeki hızı yöne çevirir. [velocity] artan indeks yönünde pozitif
/// olacak şekilde çağıran tarafından normalize edilmelidir.
int flingDirection(double velocity, {double threshold = kFlingVelocity}) {
  if (velocity > threshold) return 1;
  if (velocity < -threshold) return -1;
  return 0;
}

/// Fiske sayılmak için gereken en küçük hız (px/s). Flutter'ın kendi
/// `PageView`'ında kullanılan eşikle aynı mertebede.
const double kFlingVelocity = 400.0;
