import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// Ana sayfanın DIŞINDAN (itilmiş bir rotadan) ana sayfaya gezinme isteği.
///
/// Ana sayfanın sekme denetleyicisi ([HomeNavigationController]) sayfanın
/// kendi durumunda yaşar; üstüne itilen bir sayfa ona erişemez. Ekstre
/// içe aktarımının "Eklenenleri göster" düğmesi kapanırken buradan istek
/// bırakır, ana sayfa dinler ve İşlemler sekmesine geçer. Eskiden bitiş
/// ekranı yalnız "tarih filtresini genişlet" diyor, işi kullanıcıya
/// bırakıyordu.
///
/// Dönem de buradan taşınır, uygulama seviyesindeki `TransactionFilterCubit`
/// üzerinden DEĞİL: İşlemler sayfası KENDİ süzgeç cubit'ini kuruyor
/// (`TransactionsPage`), uygulama seviyesindekine yazılan dönem hiçbir yere
/// ulaşmıyordu — cihazda ölçüldü, liste kartın cari ekstresinde açılıyordu.
@lazySingleton
class HomeNavigationRequests extends ChangeNotifier {
  DateTimeRange? _period;

  /// Bekleyen dönem isteği (henüz bir İşlemler sayfası uygulamadıysa).
  DateTimeRange? get pendingPeriod => _period;

  /// İşlemler sekmesini (alt sayfalar kapalı) göster; [period] verilirse
  /// liste o aralıkla açılır.
  void showTransactions({DateTimeRange? period}) {
    _period = period;
    notifyListeners();
  }

  /// Bekleyen dönem isteğini TÜKETİR (bir kez uygulanır).
  DateTimeRange? takePeriod() {
    final p = _period;
    _period = null;
    return p;
  }
}
