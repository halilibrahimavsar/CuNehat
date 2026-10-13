import 'package:cunehat/core/shared/animations/unified_cube_transition.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/helpers/drag_settle.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/helpers/slider_state_helper.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Ana kaydırıcının oturma süresi/eğrisi.
///
/// 380 ms denendi (Material'ın 300–500 ms aralığı gerekçesiyle) ve cihazda
/// **fazla hızlı** bulundu; küp geçişi kısa sürede okunmuyor. Paketin
/// `SliderConfig.animationDuration` değeriyle aynı tutulmalı: ikisi de aynı
/// ekseni sürüyor.
const Duration kMainSettleDuration = Duration(milliseconds: 600);
const Curve kMainSettleCurve = Curves.easeOutCubic;

/// Alt sayfa (dikey küp) geçişi. Süre eski değerinde; kazanılan tek şey
/// eğri — yığın eskiden `forward()` ile DOĞRUSAL ilerliyordu.
const Duration kSubViewTransitionDuration = Duration(milliseconds: 500);

/// Simplified navigation controller using vertical list paradigm
///
/// View Stack:
/// Index 0: MainView (Investment/Transactions/Debt pages)
/// Index 1+: SubViews (Detail, Report, Pending, etc.)
///
/// Navigation:
/// - Horizontal swipe: Changes main menu (Yatırım ↔ İşlemler ↔ Borç)
/// - Vertical navigation: Moves through view stack (Main ↓ Sub1 ↓ Sub2 ↑ Main)
class HomeNavigationController extends ChangeNotifier {
  // Horizontal: Main menu navigation
  late final AnimationController _horizontalController;

  // Vertical: View stack navigation (main + subviews)
  late final VerticalListTransitionManager _viewStack;

  // State
  final Map<SliderState, int> _selectedSubIndices = {};
  bool _isDisposed = false;
  bool _reduceMotion = false;

  /// Sistemde "animasyonları kaldır" açıksa küp geçişleri ANINDA olur.
  ///
  /// Eskiden 600/500 ms'lik küp dönüşleri bu ayarı hiç dinlemiyordu (bkz.
  /// `AppMotion`). Denetleyici `BuildContext` görmediği için değeri ana sayfa
  /// `MediaQuery`'den besler. Parmakla sürükleme etkilenmez: o, hareketi
  /// kullanıcının kendisinin ürettiği bir jest.
  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    _viewStack.controller.duration =
        value ? Duration.zero : kSubViewTransitionDuration;
    _horizontalController.duration =
        value ? Duration.zero : kMainSettleDuration;
  }

  Duration get _settleDuration =>
      _reduceMotion ? Duration.zero : kMainSettleDuration;

  HomeNavigationController(TickerProvider vsync) {
    _horizontalController = AnimationController(
      vsync: vsync,
      duration: kMainSettleDuration,
      value: 0.5, // Start at transactions
    );

    _viewStack = VerticalListTransitionManager(
      vsync,
      duration: kSubViewTransitionDuration,
    );

    _horizontalController.addListener(_onHorizontalChanged);
  }

  // ==================== GETTERS ====================

  AnimationController get horizontalController => _horizontalController;
  VerticalListTransitionManager get viewStack => _viewStack;

  bool get isAtMainView => _viewStack.isAtMainView;

  // ==================== ETKİN BÖLÜMLER ====================

  Set<SliderState> _enabledStates = SliderState.values.toSet();

  /// Ana ekranda gezilebilen bölümler (bkz. `SectionVisibility`).
  Set<SliderState> get enabledStates => Set.unmodifiable(_enabledStates);

  /// Yatay gezinmenin bir anlamı var mı: tek bölümde kaydıracak yer yoktur.
  bool get hasHorizontalRange => _enabledStates.length > 1;

  double _targetOf(SliderState state) =>
      SliderStateHelper.getTargetValue(state, SliderState.values.length);

  List<SliderState> get _orderedEnabled => [
        for (final state in SliderState.values)
          if (_enabledStates.contains(state)) state,
      ];

  double get _minValue => _targetOf(_orderedEnabled.first);
  double get _maxValue => _targetOf(_orderedEnabled.last);

  /// Gezilebilen bölümleri değiştirir.
  ///
  /// **Eksen yeniden ölçeklenmez, DARALTILIR.** Üç bölüm küpte sabit
  /// yuvalarda durur (Birikim 0 · İşlemler 0,5 · Borç 1) ve İşlemler ortada
  /// olduğu için uçlardan birini ya da ikisini kapatmak onun değerini
  /// değiştirmez: yalnız eksenin gezilebilen aralığı kısalır. Bölüm sonradan
  /// açıldığında aralık genişler; İşlemler sayfası yerinden oynamaz, yeniden
  /// kurulmaz. (Yuvaları etkin bölüm sayısına göre yeniden dizmek tam da
  /// `HorizontalCubeAnimationView`'ın başında anlatılan hatayı geri getirirdi:
  /// sayfa yeniden mount olur, bloc'lar sıfırlanır, tur ikinci kez oynar.)
  ///
  /// Kapatılan bölümün üstünde durulurken çağrılırsa İşlemler'e dönülür.
  void setEnabledStates(Set<SliderState> states) {
    if (_isDisposed || setEquals(states, _enabledStates)) return;
    assert(states.contains(SliderState.transactions),
        'İşlemler her zaman etkindir');
    _enabledStates = {...states, SliderState.transactions};

    final value = _horizontalController.value;
    if (value < _minValue || value > _maxValue) {
      _horizontalController.value = _targetOf(SliderState.transactions);
    }
    notifyListeners();
  }

  Map<SliderState, int> get selectedSubIndices =>
      Map.unmodifiable(_selectedSubIndices);

  /// Kabuk "duruyor" mu? İnteraktif tur (bkz. `OnboardingShellStatus`) bunun
  /// false olmasını bekler; hedeflerin ekran konumu ancak o zaman geçerli.
  ///
  /// `AnimationController.isAnimating` YETMEZ: hem knob hem içerik jesti
  /// değeri `animateTo` ile değil **doğrudan** yazıyor (`value = ...`), o da
  /// `isAnimating`i false bırakıyor. Yani parmak ekrandayken tur açılabilirdi.
  /// Ölçüt bu yüzden "eksen park edilmiş mi": her sürükleme `settleMain` /
  /// `_navigateToState` ile tam bir durum değerine oturuyor.
  bool get isAnimating =>
      _horizontalController.isAnimating ||
      _viewStack.isTransitioning ||
      !_isHorizontalParked;

  bool get _isHorizontalParked {
    final target = SliderStateHelper.getTargetValue(
      currentSliderState,
      SliderState.values.length,
    );
    return (_horizontalController.value - target).abs() < 0.001;
  }

  /// Single source of truth for the current state: delegates to the package
  /// helper so the controller, the navbar and the appbar all use the same
  /// (0.25/0.75) boundaries.
  SliderState get currentSliderState => SliderStateHelper.getStateFromValue(
        _horizontalController.value,
        SliderState.values.length,
      );

  // ==================== NAVIGATION ====================

  /// Navigate to a specific view in the stack
  ///
  /// [viewIndex]: 0 = Main, 1+ = SubViews
  Future<void> navigateToView(int viewIndex, {SliderState? sliderState}) async {
    if (_isDisposed) return;

    if (sliderState != null && viewIndex > 0) {
      _selectedSubIndices[sliderState] = viewIndex - 1; // -1 because main is 0
      notifyListeners(); // DynamicSlider carousel'i yeni seçimle senkronlansın
    }

    await _viewStack.navigateTo(viewIndex);
  }

  /// Close all subviews and return to main
  ///
  /// Seçim hatırlama yok ("unut" davranışı): ana görünüme dönüldüğünde
  /// saklanan alt menü seçimleri de silinir; yoksa paket sınır geçişinde
  /// carousel'i bayat seçime geri kaydırıp knob ile ekranı ayrıştırır.
  Future<void> closeToMain() async {
    if (_selectedSubIndices.isNotEmpty) {
      _selectedSubIndices.clear();
      notifyListeners();
    }
    await _viewStack.navigateTo(0);
  }

  /// Bir sayfanın denetleyici ekseninde kapladığı aralık. Üç durum iki geçiş
  /// demek: 0.0 → 0.5 → 1.0.
  static double get pageSpan => 1.0 / (SliderState.values.length - 1);

  /// İçerik alanından gelen yatay sürükleme.
  ///
  /// Parmakla **1:1**: bir tam ekran genişliği tam bir sayfa eder. Knob'un
  /// kendi sürüklemesi parkur genişliğine bölündüğü için ~3,4× kazançla
  /// çalışıyor ve parmaktan kopuyor; içerik jesti doğrudan hissedilir.
  void dragMainBy({required double deltaX, required double width}) {
    if (_isDisposed || width <= 0) return;
    _horizontalController.value =
        (_horizontalController.value - (deltaX / width) * pageSpan)
            .clamp(_minValue, _maxValue);
  }

  /// Sürükleme bitince oturt.
  ///
  /// [velocityX] ekrandaki yatay hız (px/s). İçeriği SOLA hızla itmek bir
  /// sonraki sayfaya geçirir; konum eşiğini geçmemiş olsa bile. Hız
  /// okunmadığında %20 yol almış hızlı fiske hiçbir şey yapmıyordu.
  void settleMain({double velocityX = 0}) {
    if (_isDisposed) return;
    final maxIndex = SliderState.values.length - 1;
    final enabled = _orderedEnabled;
    final target = resolveDragTarget(
      position: _horizontalController.value * maxIndex,
      // İçerik sola giderken (negatif dx) indeks artar: işaret ters.
      direction: flingDirection(-velocityX),
      maxIndex: maxIndex,
      // Fiske, kapalı bir bölüme oturtamaz.
    ).clamp(enabled.first.index, enabled.last.index);
    _horizontalController.animateTo(
      SliderStateHelper.getTargetValue(
        SliderState.values[target],
        SliderState.values.length,
      ),
      duration: _settleDuration,
      curve: kMainSettleCurve,
    );
  }

  /// Alt sayfaları kapatıp [state] ana sayfasına kayar (dışarıdan gezinme
  /// isteği; bkz. `HomeNavigationRequests`).
  Future<void> showMain(SliderState state) async {
    if (_isDisposed || !_enabledStates.contains(state)) return;
    await closeToMain();
    if (_isDisposed) return;
    await _horizontalController.animateTo(
      SliderStateHelper.getTargetValue(state, SliderState.values.length),
      duration: _settleDuration,
      curve: kMainSettleCurve,
    );
  }

  /// Set up the view stack for current slider state
  void setupViewStack({
    required Widget mainView,
    required List<Widget> subViews,
  }) {
    final views = [mainView, ...subViews];
    _viewStack.setViews(views);
  }

  /// Reset when wallet changes
  void onWalletChanged() {
    closeToMain();
    _selectedSubIndices.clear();
  }

  // ==================== PRIVATE ====================

  void _onHorizontalChanged() {
    // Close subviews when main slider moves. isAnimating guard'ı YOK:
    // durum butonuna tap ile başlayan animateTo sırasında da alt sayfa hemen
    // kapanmalı; eski guard sınır geçilene dek eski alt sayfayı ekranda
    // bırakıyordu. navigateTo isTransitioning'i kuyruklayıp _currentIndex'i
    // hemen 0 yaptığı için tekrarlı çağrı oluşmaz.
    if (!isAtMainView) {
      closeToMain();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _horizontalController.removeListener(_onHorizontalChanged);
    _horizontalController.dispose();
    _viewStack.dispose();
    super.dispose();
  }
}
