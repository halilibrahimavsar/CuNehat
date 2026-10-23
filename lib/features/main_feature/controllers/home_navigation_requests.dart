import 'package:flutter/material.dart' show DateTimeRange, ValueChanged;
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

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

  /// Bir bölüme geç. Ana sayfa henüz kurulmadıysa (bildirime dokunarak
  /// soğuk açılış) istek BEKLETİLİR ve ana sayfa bağlanınca uygulanır.
  void openSection(TransactionsSection section) {
    final handler = sectionHandler;
    if (handler == null) {
      _pendingSection = section;
      return;
    }
    handler(section);
  }

  TransactionsSection? _pendingSection;

  /// Bekleyen bölüm isteğini TÜKETİR (bir kez uygulanır).
  TransactionsSection? takePendingSection() {
    final s = _pendingSection;
    _pendingSection = null;
    return s;
  }

  /// Ana bölümler (Birikim / İşlemler / Borç) arasında geçiş isteğini ana
  /// sayfaya ileten işleyici; [sectionHandler] ile aynı yaşam döngüsü.
  ValueChanged<SliderState>? mainHandler;

  /// [state] ana bölümünü göster. Çekmecedeki "Birikim tutmaya başla" gibi
  /// satırlar bölümü açtıktan sonra buradan oraya götürür.
  void openMain(SliderState state) => mainHandler?.call(state);

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

  /// Bildirimden Gelecek'i açma isteği: [walletId] aktif değilse ana sayfa
  /// önce o cüzdana geçer (Gelecek cüzdana özel), sonra Gelecek'i açıp
  /// [focusForecast]'i bırakır. Ana sayfa yoksa bölüm isteği de bekletilir.
  void openForecast({DateTime? day, String? walletId, DateTime? now}) {
    _forecastOpen = ForecastFocusRequest(
        day: day, walletId: walletId, requestedAt: now ?? DateTime.now());
    openSection(TransactionsSection.forecast);
  }

  ForecastFocusRequest? _forecastOpen;

  /// Bekleyen açma isteği (tüketmeden); bayatsa `null`.
  ForecastFocusRequest? peekForecastOpen({DateTime? now}) {
    final f = _forecastOpen;
    if (f == null) return null;
    final age = (now ?? DateTime.now()).difference(f.requestedAt);
    return age > forecastFocusTtl ? null : f;
  }

  /// Bekleyen açma isteğini TÜKETİR.
  ForecastFocusRequest? takeForecastOpen({DateTime? now}) {
    final f = peekForecastOpen(now: now);
    _forecastOpen = null;
    return f;
  }

  /// Gelecek'i bir tahmin bildiriminden açma isteği. AYRI bildirici: bu
  /// sınıfın kendi dinleyicisi (ana sayfa) her bildirimi "İşlemler'e dön"
  /// sayar. Gelecek kuruluyorsa isteği kurulurken alır; zaten açıksa buradan
  /// dinler.
  final ValueNotifier<ForecastFocusRequest?> forecastFocus =
      ValueNotifier(null);

  /// Bayat istek düşer: bildirim Gelecek'i hiç açamadıysa (ör. bölüm o an
  /// yoktu) sonraki ELLE açılış tahmini kendiliğinden göstermemeli. Süre PIN
  /// kilidini açmaya yetecek kadar uzun.
  static const Duration forecastFocusTtl = Duration(minutes: 10);

  void focusForecast({DateTime? day, DateTime? now}) => forecastFocus.value =
      ForecastFocusRequest(day: day, requestedAt: now ?? DateTime.now());

  /// Bekleyen Gelecek isteğini TÜKETİR (bir kez uygulanır).
  ForecastFocusRequest? takeForecastFocus({DateTime? now}) {
    final f = forecastFocus.value;
    if (f == null) return null;
    forecastFocus.value = null;
    final age = (now ?? DateTime.now()).difference(f.requestedAt);
    return age > forecastFocusTtl ? null : f;
  }
}

/// Gelecek'i bildirimden açma isteği: tahmin O AÇILIŞ için görünür (kalıcı
/// ayar değişmez), ufuk [day]'i kapsar — bildirim tahmine dayanır ve
/// "Ayrıntısı Gelecek sayfasında" der; varsayılan plan görünümü ve dönem
/// sonu ufku onu göstermiyordu.
@immutable
class ForecastFocusRequest {
  /// Bildirimin sözünü ettiği bakiye günü; yoksa `null`.
  final DateTime? day;

  /// Bildirimin cüzdanı ([HomeNavigationRequests.openForecast]); Gelecek
  /// sayfasına bırakılan odak isteğinde kullanılmaz — sayfa açıldığında
  /// doğru cüzdan zaten aktiftir.
  final String? walletId;
  final DateTime requestedAt;

  const ForecastFocusRequest(
      {this.day, this.walletId, required this.requestedAt});
}

/// Bildirimden Gelecek isteğinin sıradaki adımı (bkz. [forecastOpenAction]).
enum ForecastOpenAction {
  /// Cüzdanlar henüz yüklenmedi (soğuk açılış) ya da aktif cüzdan yok.
  wait,

  /// Önce bildirimin cüzdanına geçilmeli.
  switchWallet,

  /// Gelecek açılabilir.
  open,
}

/// Gelecek açma isteğinin sıradaki adımı — SAF (ana sayfa uygular).
///
/// [walletIds] yüklü cüzdanlar (`null` = yüklenmedi). Bildirimin cüzdanı
/// silinmişse aktif cüzdanda açılır.
ForecastOpenAction forecastOpenAction({
  required String? targetWalletId,
  required Iterable<String>? walletIds,
  required String? activeWalletId,
}) {
  if (walletIds == null || activeWalletId == null) {
    return ForecastOpenAction.wait;
  }
  if (targetWalletId == null ||
      targetWalletId == activeWalletId ||
      !walletIds.contains(targetWalletId)) {
    return ForecastOpenAction.open;
  }
  return ForecastOpenAction.switchWallet;
}

/// İşlemler sekmesinin dört yüzü: defter (ana görünüm) ve üç alt görünüm.
/// Sıra alt görünüm indeksidir (`SubMenuConfig.viewIndex`): 0 = ana görünüm.
enum TransactionsSection { ledger, insights, report, forecast }
