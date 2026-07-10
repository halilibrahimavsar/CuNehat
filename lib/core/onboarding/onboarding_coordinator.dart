import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import 'onboarding_flow.dart';

/// Üç ana ekranın (yatırım/işlemler/borç) interaktif turlarını yönetir.
///
/// Her sayfa kendi tur adımlarının [GlobalKey]'lerini [registerKeys] ile bir
/// kez kaydeder; hem "ilk kez görüldüğünde otomatik başlat" (sayfanın kendi
/// initState'i) hem de "Ayarlar'dan tekrar oynat" ([resetAndReplay]) aynı key
/// listesini kullanır. [pendingFlow], Ayarlar'dan tetiklenen tekrar oynatma
/// isteğini HomePage'e taşır (Settings ayrı bir route olduğundan, HomePage
/// zaten dinlediği bu bildirim üzerinden slider'ı ilgili ekrana getirip
/// showcase'i başlatır).
@lazySingleton
class OnboardingCoordinator extends ChangeNotifier {
  final SharedPreferences _prefs;

  OnboardingCoordinator(this._prefs);

  static String _seenKey(OnboardingFlow flow) =>
      'onboarding_${flow.name}_seen';

  final Map<OnboardingFlow, List<GlobalKey>> _registeredKeys = {};

  OnboardingFlow? _pendingFlow;
  OnboardingFlow? get pendingFlow => _pendingFlow;

  /// HomePage tarafından set edilir: drawer/cüzdan diyaloğu geçiş dönüşümü
  /// (translate/scale/rotate) sürerken true döner. Bu sırada hedef
  /// widget'ların global konumu her frame değiştiğinden showcase overlay'i
  /// yanlış yere çizilir — bkz. [waitUntilStable].
  bool Function()? isBlocked;

  /// Herhangi bir turu başlatmadan önce çağrılır: içeriği kaydıran geçiş
  /// animasyonu bitene kadar (her frame yeniden kontrol ederek) bekler.
  /// Sabit bir gecikme yerine gerçek animasyon durumunu izlediğinden, hem
  /// gereksiz beklemez hem de animasyon süresi değişse de kırılmaz.
  Future<void> waitUntilStable() async {
    while (isBlocked?.call() ?? false) {
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  // ==================== SIRALAMA (kaç ekran/sheet artık bağımsız kendi
  // initState'inde otomatik tur tetikleyebiliyor; ikisi aynı ilk frame'de
  // tetiklenirse showcaseview'un tekil, global ShowcaseView'ı ikinci
  // çağrıda birincisini yarıda kesip üzerine yazar. Bu kuyruk, her turun
  // sırayla ve tam bitene kadar gösterilmesini garanti eder. ====================
  Completer<void>? _activeTour;

  /// [AppInitialization]'da `ShowcaseView.register(onFinish:, onDismiss:)`
  /// ile bağlanır: bir tur bitince veya kullanıcı erken kapatınca çağrılır.
  void handleShowcaseIdle() {
    final tour = _activeTour;
    _activeTour = null;
    tour?.complete();
  }

  /// Bir turu başlatmak isteyen her çağrı buradan geçer. O anda başka bir
  /// tur gösteriliyorsa, o bitene kadar (sırayla) bekler.
  Future<void> requestStartShowCase(List<GlobalKey> keys) async {
    if (keys.isEmpty) return;
    while (_activeTour != null) {
      await _activeTour!.future;
    }
    final completer = Completer<void>();
    _activeTour = completer;
    ShowcaseView.get().startShowCase(keys);
    await completer.future;
  }

  bool isSeen(OnboardingFlow flow) => _prefs.getBool(_seenKey(flow)) ?? false;

  Future<void> markSeen(OnboardingFlow flow) =>
      _prefs.setBool(_seenKey(flow), true);

  void registerKeys(OnboardingFlow flow, List<GlobalKey> keys) {
    _registeredKeys[flow] = keys;
  }

  List<GlobalKey> keysFor(OnboardingFlow flow) =>
      _registeredKeys[flow] ?? const [];

  /// Ayarlar'dan "turu tekrar göster": bayrağı sıfırlar, [pendingFlow]'u
  /// set edip dinleyicileri (HomePage) bilgilendirir.
  Future<void> resetAndReplay(OnboardingFlow flow) async {
    await _prefs.remove(_seenKey(flow));
    _pendingFlow = flow;
    notifyListeners();
  }

  void consumePendingFlow() {
    _pendingFlow = null;
  }

  /// Ayarlar'daki "Tüm Turları Sıfırla": her akışın bayrağını temizler,
  /// böylece o ekrana bir sonraki gidişte turu tekrar otomatik başlar.
  /// Ana 3 ekranın aksine burada slider'ı taşımaya gerek yok; alt sayfa
  /// turları zaten o sayfaya gidildiğinde kendiliğinden tetiklenir.
  Future<void> resetAll() async {
    for (final flow in OnboardingFlow.values) {
      await _prefs.remove(_seenKey(flow));
    }
  }
}
