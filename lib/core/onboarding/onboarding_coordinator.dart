import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import 'onboarding_flow.dart';

/// HomePage kabuğunun o anki durumu. [OnboardingCoordinator] bunu turların
/// "benim yüzeyim şu an gerçekten ekranda ve duruyor mu" sorusunu yanıtlamak
/// için okur.
@immutable
class OnboardingShellStatus {
  /// Dikey yığının indeksi (0 ana görünüm, 1+ alt sayfalar).
  final int stackIndex;

  /// Yatay veya dikey geçiş animasyonu sürüyor mu.
  final bool isAnimating;

  /// Drawer / cüzdan sheet'i içeriği ölçekleyip kaydırmış durumda mı. Yalnız
  /// animasyon sırasında değil, açık kaldığı SÜRECE true'dur: bu haldeyken
  /// kabuktaki hedeflerin ekran konumu gerçek konumları değildir.
  final bool isTransformed;

  const OnboardingShellStatus({
    required this.stackIndex,
    required this.isAnimating,
    required this.isTransformed,
  });
}

/// Bekleyen bir tur isteği: turun anahtarları + sahibinin canlılık ve
/// görünürlük yordamları.
@immutable
class _PendingTour {
  /// İsteği açan State nesnesi. Aynı akış yeniden mount olduğunda eski
  /// örneğin `dispose`'u yeni isteği silmesin diye kimlik olarak tutulur.
  final Object owner;
  final List<GlobalKey> keys;
  final bool Function() isAlive;
  final bool Function() isReady;

  const _PendingTour({
    required this.owner,
    required this.keys,
    required this.isAlive,
    required this.isReady,
  });
}

/// İnteraktif turların tek sahibi.
///
/// Tasarım: **istek + kapı**, kuyruk değil. Her yüzey (sayfa/sheet) mount
/// olduğunda turunu ister; tur ancak o yüzey KULLANICININ O AN GÖRDÜĞÜ ve
/// DURAN yüzeyken oynatılır. Böylece bir tur asla başka bir sayfanın üstünde
/// açılmaz — eski FIFO kuyruk, sırası gelen turu o anda hangi ekran açıksa
/// orada başlatıyordu.
///
/// Kapı koşulları [OnboardingTour] içinde toplanır (route güncel mi, giriş
/// animasyonu bitti mi, kabuk doğru konumda ve duruyor mu, hedefler ağaçta
/// mı). Koordinatör yalnızca "hazır olan ilk isteği başlat, aynı anda tek tur
/// oynat" kuralını uygular.
///
/// Yeniden değerlendirme olay güdümlüdür ([notifyMaybeReady]): kabuk
/// animasyonları, route geçişleri ve tur bitişleri tetikler. Eski sürümdeki
/// `await endOfFrame` döngüsü yoktur — o döngü sheet/drawer açık kaldığı
/// sürece 60fps kare zamanlıyor ve hiç sonlanmıyordu.
@lazySingleton
class OnboardingCoordinator extends ChangeNotifier {
  final SharedPreferences _prefs;

  OnboardingCoordinator(this._prefs);

  static String _seenKey(OnboardingFlow flow) => 'onboarding_${flow.name}_seen';

  /// HomePage tarafından set edilir. null ise kabuk henüz kurulmamıştır ve
  /// kabuğa bağlı tur (bkz. [OnboardingFlowSurface.requiresHomeShellAtRoot])
  /// beklemede kalır.
  OnboardingShellStatus Function()? shellStatusProvider;

  /// Testlerde gerçek overlay'i kurmadan turun başladığını gözlemleyebilmek
  /// için ayrılmış dikiş.
  @visibleForTesting
  void Function(List<GlobalKey> keys)? startShowcaseOverride;

  final Map<OnboardingFlow, _PendingTour> _pending = {};

  /// Bu oturumda başlatılmış turlar. Kalıcı bayrak yazımı asenkron olduğundan
  /// (ve tur BAŞLARKEN yazıldığından) senkron bir ikinci kaynak gerekir.
  final Set<OnboardingFlow> _seenInSession = {};

  OnboardingFlow? _running;
  bool _evaluateScheduled = false;
  bool _disposed = false;

  /// O an oynayan tur (yoksa null).
  OnboardingFlow? get runningFlow => _running;

  bool isPending(OnboardingFlow flow) => _pending.containsKey(flow);

  bool isSeen(OnboardingFlow flow) =>
      _seenInSession.contains(flow) ||
      (_prefs.getBool(_seenKey(flow)) ?? false);

  Future<void> markSeen(OnboardingFlow flow) {
    _seenInSession.add(flow);
    return _prefs.setBool(_seenKey(flow), true);
  }

  // ==================== İSTEK / İPTAL ====================

  /// Bir yüzeyin turunu ister. Akış başına EN FAZLA BİR istek tutulur; aynı
  /// akış iki kez mount olsa da (küp geçişlerinde olabiliyor) tur bir kez
  /// oynar.
  void requestTour(
    OnboardingFlow flow, {
    required Object owner,
    required List<GlobalKey> keys,
    required bool Function() isAlive,
    required bool Function() isReady,
  }) {
    if (keys.isEmpty || isSeen(flow) || _running == flow) return;
    _pending[flow] = _PendingTour(
      owner: owner,
      keys: keys,
      isAlive: isAlive,
      isReady: isReady,
    );
    _scheduleEvaluate();
  }

  /// Yüzey ağaçtan kalkarken isteğini geri çeker. Aynı akış bu arada yeniden
  /// mount olduysa (yeni sahip) istek korunur.
  void cancelTour(OnboardingFlow flow, Object owner) {
    if (identical(_pending[flow]?.owner, owner)) _pending.remove(flow);
  }

  /// "Görünürlük koşulları değişmiş olabilir, bekleyenleri yeniden
  /// değerlendir." Kabuk animasyonları, route geçişleri, sheet açılıp
  /// kapanması ve tur bitişleri çağırır.
  void notifyMaybeReady() => _scheduleEvaluate();

  /// [AppInitialization]'da `ShowcaseView.register(onFinish:, onDismiss:)`
  /// ile bağlanır: tur bitince ya da kullanıcı erken kapatınca sıradaki
  /// hazır tur değerlendirilir.
  void handleShowcaseIdle() {
    _running = null;
    _scheduleEvaluate();
  }

  // ==================== DEĞERLENDİRME ====================

  void _scheduleEvaluate() {
    if (_disposed || _pending.isEmpty || _evaluateScheduled) return;
    _evaluateScheduled = true;
    // Kare sonuna ertelenir: mount/layout bitmeden hedeflerin ağaçta olup
    // olmadığı ve kabuğun nihai konumu güvenilir okunamaz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluateScheduled = false;
      _evaluate();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _evaluate() {
    if (_disposed || _pending.isEmpty) return;
    _pending.removeWhere((_, tour) => !tour.isAlive());
    if (_running != null) return;

    // Bildirim sırası önceliktir (bkz. OnboardingFlow).
    for (final flow in OnboardingFlow.values) {
      final tour = _pending[flow];
      if (tour == null) continue;
      if (isSeen(flow)) {
        _pending.remove(flow);
        continue;
      }
      if (!tour.isReady()) continue;
      _pending.remove(flow);
      _start(flow, tour.keys);
      return;
    }
  }

  void _start(OnboardingFlow flow, List<GlobalKey> keys) {
    _running = flow;
    // Bayrak turun BAŞINDA yazılır. Tur oynarken sayfa yeniden mount olursa
    // (küp geçişi, cüzdan değişimi) ikinci bir istek açılmasın diye; eski
    // sürümde bayrak turun SONUNDA yazıldığı için aynı tanıtım arka arkaya
    // iki kez oynayabiliyordu.
    unawaited(markSeen(flow));
    final start = startShowcaseOverride ??
        (List<GlobalKey> k) => ShowcaseView.get().startShowCase(k);
    start(keys);
  }

  // ==================== KABUK DURUMU ====================

  /// Kabuğa bağlı tek tur ([OnboardingFlow.shell]) ancak kabuk kökte —
  /// alt sayfa açık değil — ve durur haldeyken oynayabilir.
  bool isHomeShellAtRoot() {
    final status = shellStatusProvider?.call();
    if (status == null) return false;
    if (status.isAnimating || status.isTransformed) return false;
    return status.stackIndex == 0;
  }

  // ==================== AYARLAR'DAN TEKRAR OYNATMA ====================

  /// Bayrağı sıfırlar; [notifyListeners] canlı [OnboardingTour]'ların
  /// isteklerini yeniden açmasını sağlar. Turun kendisi başlatılmaz —
  /// kullanıcı o yüzeye döndüğünde kapı kendiliğinden açılır.
  Future<void> resetAndReplay(OnboardingFlow flow) async {
    _seenInSession.remove(flow);
    await _prefs.remove(_seenKey(flow));
    notifyListeners();
  }

  /// Ayarlar'daki "Tüm Turları Sıfırla".
  Future<void> resetAll() async {
    _seenInSession.clear();
    for (final flow in OnboardingFlow.values) {
      await _prefs.remove(_seenKey(flow));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pending.clear();
    shellStatusProvider = null;
    super.dispose();
  }
}
