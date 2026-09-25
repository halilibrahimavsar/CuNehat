import 'package:flutter/material.dart' show DateTimeRange, ValueChanged;
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
/// Dönem de buradan taşınır: istek sayfa kurulmadan önce gelebilir, sayfa
/// kurulunca ortak `TransactionFilterCubit`'e uygular. (Eskiden İşlemler
/// sayfası KENDİ süzgeç cubit'ini kuruyordu ve uygulama seviyesindekine
/// yazılan dönem hiçbir yere ulaşmıyordu; artık tek örnek var.)
@lazySingleton
class HomeNavigationRequests extends ChangeNotifier {
  /// İşlemler / İçgörü / Rapor sekme şeridinin isteklerini ana sayfaya
  /// ileten işleyici. Ana sayfa kurulunca bağlar, kapanınca çözer; sekme
  /// şeridi alt sayfaların içinde yaşadığı için gezinme denetleyicisine
  /// doğrudan erişemez (o, ana sayfanın durumunda).
  ValueChanged<TransactionsSection>? sectionHandler;

  /// Sekme şeridinden bir bölüme geç.
  void openSection(TransactionsSection section) =>
      sectionHandler?.call(section);

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

/// İşlemler sekmesinin üç yüzü: defter (ana görünüm) ve iki alt görünüm.
/// Sıra alt görünüm indeksidir (`SubMenuConfig.viewIndex`): 0 = ana görünüm.
enum TransactionsSection { ledger, insights, report }
