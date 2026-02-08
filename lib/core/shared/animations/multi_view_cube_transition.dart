import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Direction of cube transition
enum CubeDirection {
  left,
  right,
  up,
  down,
}

/// Unified multi-view cube transition
///
/// Supports:
/// - 2 views: Bidirectional transitions (left/right/up/down)
/// - 3+ views: Sequential transitions with automatic direction
///
/// Usage for 2 views:
/// ```dart
/// MultiViewCubeTransition(
///   controller: animationController,
///   views: [view1, view2],
///   currentIndex: 0,
///   nextIndex: 1,
///   direction: CubeDirection.right,
/// )
/// ```
///
/// Usage for 3+ views:
/// ```dart
/// MultiViewCubeTransition(
///   controller: animationController,
///   views: [page1, page2, page3],
///   currentIndex: currentPage,
///   nextIndex: nextPage,
/// )
/// ```
class MultiViewCubeTransition extends StatelessWidget {
  final AnimationController controller;
  final List<Widget> views;
  final int currentIndex;
  final int nextIndex;
  final CubeDirection? explicitDirection;
  final bool useFade;

  const MultiViewCubeTransition({
    super.key,
    required this.controller,
    required this.views,
    required this.currentIndex,
    required this.nextIndex,
    this.explicitDirection,
    this.useFade = true,
  })  : assert(views.length >= 2, 'At least 2 views required'),
        assert(currentIndex >= 0 && currentIndex < views.length),
        assert(nextIndex >= 0 && nextIndex < views.length);

  bool get _isHorizontal {
    if (explicitDirection != null) {
      return explicitDirection == CubeDirection.left ||
          explicitDirection == CubeDirection.right;
    }
    // Auto-detect: for 2 views use horizontal, for 3+ use vertical
    return views.length == 2;
  }

  CubeDirection get _direction {
    if (explicitDirection != null) return explicitDirection!;

    if (views.length == 2) {
      // For 2 views: horizontal
      return nextIndex > currentIndex
          ? CubeDirection.right
          : CubeDirection.left;
    } else {
      // For 3+ views: vertical (stack paradigm)
      return nextIndex > currentIndex ? CubeDirection.down : CubeDirection.up;
    }
  }

  Matrix4 _perspective() => Matrix4.identity()..setEntry(3, 2, 0.001);

  @override
  Widget build(BuildContext context) {
    // Safety check
    if (currentIndex >= views.length || nextIndex >= views.length) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;
        final direction = _direction;
        final isHorizontal = _isHorizontal;

        // Calculate sign
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

        if (isHorizontal) {
          outgoingOffset = Tween<Offset>(
            begin: Offset.zero,
            end: Offset(sign * 1.0, 0.0),
          ).transform(value);

          incomingOffset = Tween<Offset>(
            begin: Offset(-sign * 1.0, 0.0),
            end: Offset.zero,
          ).transform(value);
        } else {
          outgoingOffset = Tween<Offset>(
            begin: Offset.zero,
            end: Offset(0.0, sign * 1.0),
          ).transform(value);

          incomingOffset = Tween<Offset>(
            begin: Offset(0.0, -sign * 1.0),
            end: Offset.zero,
          ).transform(value);
        }

        // Alignments
        final Alignment outgoingAlignment;
        final Alignment incomingAlignment;

        if (isHorizontal) {
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

        final outgoingView = views[currentIndex];
        final incomingView = views[nextIndex];

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
                    ..multiply(isHorizontal
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
                    ..multiply(isHorizontal
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

/// Manager for view stack transitions
///
/// Handles navigation through a stack of views with proper animations
class ViewStackTransitionManager extends ChangeNotifier {
  late final AnimationController _controller;

  List<Widget> _views = [];
  int _currentIndex = 0;
  int? _previousIndex;
  bool _isTransitioning = false;

  ViewStackTransitionManager(TickerProvider vsync, {Duration? duration}) {
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
  List<Widget> get views => List.unmodifiable(_views);

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _previousIndex = null;
      _isTransitioning = false;
      notifyListeners();
    }
  }

  /// Set the view stack
  ///
  /// [preserveIndex]: Keep current index if possible (default: reset to 0)
  void setViews(List<Widget> views, {bool preserveIndex = false}) {
    _views = List.from(views);

    if (!preserveIndex || _currentIndex >= _views.length) {
      _currentIndex = 0;
    }

    notifyListeners();
  }

  /// Navigate to specific index
  Future<void> navigateTo(int index, {CubeDirection? direction}) async {
    if (_isTransitioning || index < 0 || index >= _views.length) return;
    if (index == _currentIndex) return;

    _isTransitioning = true;
    _previousIndex = _currentIndex;
    _currentIndex = index;
    notifyListeners();

    await _controller.forward(from: 0.0);
  }

  /// Navigate to next view
  Future<void> next() async {
    if (_currentIndex < _views.length - 1) {
      await navigateTo(_currentIndex + 1);
    }
  }

  /// Navigate to previous view
  Future<void> previous() async {
    if (_currentIndex > 0) {
      await navigateTo(_currentIndex - 1);
    }
  }

  /// Reset to main view (index 0)
  Future<void> reset() async {
    await navigateTo(0);
  }

  /// Build the transition widget
  Widget buildTransition({bool useFade = true}) {
    // Safety checks
    if (_views.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_currentIndex >= _views.length) {
      return const SizedBox.shrink();
    }

    // During transition
    if (_isTransitioning && _previousIndex != null) {
      if (_previousIndex! >= _views.length) {
        return const SizedBox.shrink();
      }

      return MultiViewCubeTransition(
        controller: _controller,
        views: _views,
        currentIndex: _previousIndex!,
        nextIndex: _currentIndex,
        useFade: useFade,
      );
    }

    // Static view
    return _views[_currentIndex];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
