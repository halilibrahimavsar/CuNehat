import 'package:cunehat/core/shared/animations/unified_cube_transition.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/helpers/slider_state_helper.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

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

  HomeNavigationController(TickerProvider vsync) {
    _horizontalController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 750),
      value: 0.5, // Start at transactions
    );

    _viewStack = VerticalListTransitionManager(
      vsync,
      duration: const Duration(milliseconds: 500),
    );

    _horizontalController.addListener(_onHorizontalChanged);
  }

  // ==================== GETTERS ====================

  AnimationController get horizontalController => _horizontalController;
  VerticalListTransitionManager get viewStack => _viewStack;

  bool get isAtMainView => _viewStack.isAtMainView;

  Map<SliderState, int> get selectedSubIndices =>
      Map.unmodifiable(_selectedSubIndices);

  bool get isAnimating =>
      _horizontalController.isAnimating || _viewStack.isTransitioning;

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
