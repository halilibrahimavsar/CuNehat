import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Direction of cube transition
enum CubeDirection {
  left, // Horizontal: slide left
  right, // Horizontal: slide right
  up, // Vertical: slide up (going to higher index)
  down, // Vertical: slide down (going to lower index)
}

/// Unified cube transition widget supporting all directions
///
/// Supports both horizontal (main menu) and vertical (subview list) transitions
class UnifiedCubeTransition extends StatelessWidget {
  final AnimationController controller;
  final Widget outgoingView;
  final Widget incomingView;
  final CubeDirection direction;
  final bool useFade;

  const UnifiedCubeTransition({
    super.key,
    required this.controller,
    required this.outgoingView,
    required this.incomingView,
    required this.direction,
    this.useFade = true,
  });

  bool get _isHorizontal =>
      direction == CubeDirection.left || direction == CubeDirection.right;

  Matrix4 _perspective() => Matrix4.identity()..setEntry(3, 2, 0.001);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;

        // Calculate sign based on direction
        // right/down = normal (-1 for outgoing rotation to go right/down)
        // left/up = reverse (1 for outgoing rotation to go left/up)
        final sign = (direction == CubeDirection.right ||
                direction == CubeDirection.down)
            ? -1.0
            : 1.0;

        // Rotations
        final outgoingRotation = Tween(
          begin: 0.0,
          end: sign * math.pi / 2.2,
        ).transform(value);

        final incomingRotation = Tween(
          begin: -sign * math.pi / 2.2,
          end: 0.0,
        ).transform(value);

        // Offsets
        final Offset outgoingOffset;
        final Offset incomingOffset;

        if (_isHorizontal) {
          // Horizontal movement
          outgoingOffset = Tween<Offset>(
            begin: Offset.zero,
            end: Offset(sign * 1.0, 0.0),
          ).transform(value);

          incomingOffset = Tween<Offset>(
            begin: Offset(-sign * 1.0, 0.0),
            end: Offset.zero,
          ).transform(value);
        } else {
          // Vertical movement
          outgoingOffset = Tween<Offset>(
            begin: Offset.zero,
            end: Offset(0.0, sign * 1.0),
          ).transform(value);

          incomingOffset = Tween<Offset>(
            begin: Offset(0.0, -sign * 1.0),
            end: Offset.zero,
          ).transform(value);
        }

        // Alignment points for rotation
        final Alignment outgoingAlignment;
        final Alignment incomingAlignment;

        if (_isHorizontal) {
          outgoingAlignment =
              sign < 0 ? Alignment.centerRight : Alignment.centerLeft;
          incomingAlignment =
              sign < 0 ? Alignment.centerLeft : Alignment.centerRight;
        } else {
          outgoingAlignment =
              sign < 0 ? Alignment.bottomCenter : Alignment.topCenter;
          incomingAlignment =
              sign < 0 ? Alignment.topCenter : Alignment.bottomCenter;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outgoing view
            Visibility(
              visible: value < 0.95,
              child: FractionalTranslation(
                translation: outgoingOffset,
                child: Transform(
                  alignment: outgoingAlignment,
                  transform: _perspective()
                    ..multiply(_isHorizontal
                        ? Matrix4.rotationY(outgoingRotation)
                        : Matrix4.rotationX(outgoingRotation)),
                  child: useFade
                      ? Opacity(opacity: 1.0 - value, child: outgoingView)
                      : outgoingView,
                ),
              ),
            ),
            // Incoming view
            Visibility(
              visible: value > 0.05,
              child: FractionalTranslation(
                translation: incomingOffset,
                child: Transform(
                  alignment: incomingAlignment,
                  transform: _perspective()
                    ..multiply(_isHorizontal
                        ? Matrix4.rotationY(incomingRotation)
                        : Matrix4.rotationX(incomingRotation)),
                  child: useFade
                      ? Opacity(opacity: value, child: incomingView)
                      : incomingView,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Manager for vertical list-style transitions
///
/// Treats views as a vertical stack:
/// - Index 0: MainView
/// - Index 1+: SubViews
///
/// Down (index increase): View comes from bottom
/// Up (index decrease): View comes from top
class VerticalListTransitionManager extends ChangeNotifier {
  late final AnimationController _controller;

  final List<Widget> _views = [];
  int _currentIndex = 0;
  int? _previousIndex;
  bool _isTransitioning = false;

  VerticalListTransitionManager(TickerProvider vsync, {Duration? duration}) {
    _controller = AnimationController(
      vsync: vsync,
      duration: duration ?? const Duration(milliseconds: 500),
    );
    _controller.addStatusListener(_onStatusChanged);
  }

  AnimationController get controller => _controller;
  int get currentIndex => _currentIndex;
  bool get isTransitioning => _isTransitioning;
  bool get isAtMainView => _currentIndex == 0;

  /// Register available views
  void setViews(List<Widget> views) {
    _views.clear();
    _views.addAll(views);
    // Removed notifyListeners() to prevent 'markNeedsBuild() called during build' exception.
    // The widget calling this is already rebuilding, so the UI will update naturally.
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _previousIndex = null;
      _isTransitioning = false;
      notifyListeners();
    }
  }

  /// Navigate to a specific index
  Future<void> navigateTo(int index) async {
    if (_isTransitioning || index < 0 || index >= _views.length) return;
    if (index == _currentIndex) return;

    _isTransitioning = true;
    _previousIndex = _currentIndex;
    _currentIndex = index;
    notifyListeners();

    await _controller.forward(from: 0.0);
  }

  /// Go to next view (down)
  Future<void> next() async {
    if (_currentIndex < _views.length - 1) {
      await navigateTo(_currentIndex + 1);
    }
  }

  /// Go to previous view (up)
  Future<void> previous() async {
    if (_currentIndex > 0) {
      await navigateTo(_currentIndex - 1);
    }
  }

  /// Build the current transition
  Widget buildTransition({bool useFade = true}) {
    // Safety check: ensure views list is populated and indices are valid
    if (_views.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isTransitioning && _previousIndex != null) {
      // Validate indices before accessing list
      if (_previousIndex! >= _views.length || _currentIndex >= _views.length) {
        return const SizedBox.shrink();
      }

      final direction = _currentIndex > _previousIndex!
          ? CubeDirection.down
          : CubeDirection.up;

      return UnifiedCubeTransition(
        controller: _controller,
        outgoingView: _views[_previousIndex!],
        incomingView: _views[_currentIndex],
        direction: direction,
        useFade: useFade,
      );
    }

    // Return current view if not transitioning
    if (_currentIndex < _views.length) {
      return _views[_currentIndex];
    }

    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
