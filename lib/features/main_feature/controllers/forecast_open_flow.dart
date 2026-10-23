import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';

/// Bildirimden Gelecek'i açma akışı — ana sayfanın durumundan ayrılmış,
/// widget'sız test edilebilen durum makinesi (QA O8: akışın testi yoktu).
///
/// Gelecek cüzdana özel: bildirim başka bir cüzdanınsa önce ona geçilir,
/// Gelecek geçiş TAMAMLANINCA açılır. Soğuk açılışta cüzdanlar yüklenene
/// kadar beklenir: yığın o an boştur ve gezinme sessizce boşa giderdi.
///
/// Ana sayfa [begin]'i bildirimin bölüm isteğinde, [step]'i her cüzdan
/// değişiminde, [fail]'i bildirimin cüzdanına geçilemeyince çağırır. Yan
/// etkiler geri çağrılarla yapılır ([switchWallet], [open]).
class ForecastOpenFlow {
  final HomeNavigationRequests _requests;

  /// Aktif cüzdanı [walletId] yap (ana sayfa cüzdan bloc'una iletir).
  final void Function(String walletId) switchWallet;

  /// Gelecek görünümünü aç.
  final void Function() open;

  final DateTime Function() _clock;

  ForecastOpenFlow(
    this._requests, {
    required this.switchWallet,
    required this.open,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  bool _waiting = false;
  String? _switchTo;

  /// İstek uygulanmayı bekliyor: cüzdanlar yüklenmedi ya da bildirimin
  /// cüzdanına geçiliyor.
  bool get waiting => _waiting;

  /// Geçişi istenen cüzdan (aynı geçiş ikinci kez gönderilmesin); yoksa
  /// `null`.
  String? get switchingTo => _switchTo;

  /// Bildirimden Gelecek isteği geldi: beklemeye al ve ilk adımı dene.
  void begin({
    required Iterable<String>? walletIds,
    required String? activeWalletId,
  }) {
    _waiting = true;
    step(walletIds: walletIds, activeWalletId: activeWalletId);
  }

  /// Bekleyen isteği uygular. [walletIds] yüklü cüzdanlar (`null` =
  /// yüklenmedi).
  void step({
    required Iterable<String>? walletIds,
    required String? activeWalletId,
  }) {
    if (!_waiting) return;
    final request = _requests.peekForecastOpen(now: _clock());
    if (request == null) {
      // Bekleme bildirim isteğinin ömrünü aştı: düşer. Yoksa saatler sonraki
      // bir elle cüzdan değişimi Gelecek'i kendiliğinden açardı.
      _reset();
      return;
    }
    final target = request.walletId;
    switch (forecastOpenAction(
      targetWalletId: target,
      walletIds: walletIds,
      activeWalletId: activeWalletId,
    )) {
      case ForecastOpenAction.wait:
        return;
      case ForecastOpenAction.switchWallet:
        if (_switchTo == target) return;
        _switchTo = target;
        switchWallet(target!);
      case ForecastOpenAction.open:
        _reset();
        final taken = _requests.takeForecastOpen(now: _clock());
        if (taken != null) {
          _requests.focusForecast(day: taken.day, now: _clock());
        }
        open();
    }
  }

  /// Bildirimin cüzdanına geçilemedi: istek düşer; sonraki bir elle cüzdan
  /// değişimi Gelecek'i açmasın.
  void fail() {
    if (_switchTo == null) return;
    _reset();
    _requests.takeForecastOpen(now: _clock());
  }

  void _reset() {
    _waiting = false;
    _switchTo = null;
  }
}
