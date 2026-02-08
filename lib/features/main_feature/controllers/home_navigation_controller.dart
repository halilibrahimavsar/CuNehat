import 'package:cunehat/core/shared/animations/unified_cube_transition.dart';
import 'package:flutter/material.dart';
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

  int get currentStackIndex => _viewStack.currentIndex;
  bool get isAtMainView => _viewStack.isAtMainView;
  bool get isSubViewOpen => !_viewStack.isAtMainView;

  Map<SliderState, int> get selectedSubIndices =>
      Map.unmodifiable(_selectedSubIndices);

  bool get isAnimating =>
      _horizontalController.isAnimating || _viewStack.isTransitioning;

  SliderState get currentSliderState {
    final value = _horizontalController.value;
    if (value < 0.3) return SliderState.savedMoney;
    if (value < 0.7) return SliderState.transactions;
    return SliderState.debt;
  }

  // ==================== NAVIGATION ====================

  /// Navigate horizontally between main menus
  Future<void> navigateToSlider(SliderState state) async {
    final targetValue = _getSliderTargetValue(state);
    await _horizontalController.animateTo(
      targetValue,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  /// Navigate to a specific view in the stack
  ///
  /// [viewIndex]: 0 = Main, 1+ = SubViews
  Future<void> navigateToView(int viewIndex, {SliderState? sliderState}) async {
    if (_isDisposed) return;

    if (sliderState != null && viewIndex > 0) {
      _selectedSubIndices[sliderState] = viewIndex - 1; // -1 because main is 0
    }

    await _viewStack.navigateTo(viewIndex);
  }

  /// Go to next view (down)
  Future<void> nextView() async {
    await _viewStack.next();
  }

  /// Go to previous view (up)
  Future<void> previousView() async {
    await _viewStack.previous();
  }

  /// Close all subviews and return to main
  Future<void> closeToMain() async {
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
    // Close subviews when main slider moves
    if (!isAtMainView && !isAnimating) {
      closeToMain();
    }
  }

  double _getSliderTargetValue(SliderState state) {
    return switch (state) {
      SliderState.savedMoney => 0.15,
      SliderState.transactions => 0.5,
      SliderState.debt => 0.85,
    };
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
