import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unified_flutter_features/core/texts/slider_texts.dart';
import 'models/slider_models.dart';
import 'constants/slider_config.dart';
import 'helpers/slider_state_helper.dart';
import 'widgets/mini_buttons_overlay.dart';
import 'widgets/slider_knob.dart';

/// A 2D navigation slider with state transitions and mini button/sub-menu support.
///
/// Example usage:
/// ```dart
/// class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
///   late final AnimationController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = AnimationController(vsync: this, value: 0.0);
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return DynamicSlider(
///       controller: _controller,
///       onStateTap: (state) {
///         // triggered when state changes
///       },
///       miniButtons: {
///         SliderState.savedMoney: [
///           MiniButtonData(
///             icon: Icons.add,
///             label: 'Add',
///             color: Colors.green,
///             onTap: () {},
///           ),
///         ],
///       },
///       subMenuItems: {
///         SliderState.transactions: [
///           SubMenuItem(
///             icon: Icons.list,
///             label: 'All Transactions',
///             onTap: () {},
///             isDefault: true,
///           ),
///         ],
///       },
///     );
///   }
/// }
/// ```
class DynamicSlider extends StatefulWidget {
  /// Animation controller that controls the slider position (0.0 to 1.0).
  final AnimationController controller;

  /// Callback when the slider value changes during dragging.
  final ValueChanged<double>? onValueChanged;

  /// Callback when a slider state is tapped or becomes active.
  final ValueChanged<SliderState>? onStateTap;

  /// Mini buttons that appear when tapping the knob for specific states.
  final Map<SliderState, List<MiniButtonData>> miniButtons;

  /// Sub-menu items that appear in vertical carousel for specific states.
  final Map<SliderState, List<SubMenuItem>> subMenuItems;

  /// Selected sub-menu index for each state (0-based, excluding title item).
  final Map<SliderState, int> selectedSubIndex;

  /// Localized texts for the slider labels.
  final SliderTexts texts;

  const DynamicSlider({
    super.key,
    required this.controller,
    this.onValueChanged,
    this.onStateTap,
    this.miniButtons = const {},
    this.subMenuItems = const {},
    this.selectedSubIndex = const {},
    this.texts = const SliderTexts(),
  });

  @override
  State<DynamicSlider> createState() => _DynamicSliderState();
}

class _DynamicSliderState extends State<DynamicSlider> {
  bool _isDragging = false;
  bool _isVerticalDragging = false;
  double _widgetWidth = 0.0;
  SliderState? _lastState;

  late FixedExtentScrollController _carouselController;
  bool _showUpArrow = false;
  bool _showDownArrow = false;

  /// Whether the centered carousel item is the main title (index 0). Drives the
  /// add ('+') affordance and mini-button availability. Tracked in state so it
  /// refreshes on every carousel settle, not only when arrow visibility flips.
  bool _isMainSelected = true;

  // Mini buttons overlay state
  bool _showMiniButtons = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _knobKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _carouselController = FixedExtentScrollController();
    _lastState = _getCurrentState();
    widget.controller.addListener(_onControllerChange);
    _carouselController.addListener(_updateArrowVisibility);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateArrowVisibility();
      _syncCarouselToSelection(animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant DynamicSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
      _lastState = _getCurrentState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncCarouselToSelection(animate: false);
        _updateArrowVisibility();
      });
    }
    if (!mapEquals(oldWidget.selectedSubIndex, widget.selectedSubIndex) ||
        oldWidget.subMenuItems != widget.subMenuItems) {
      _syncCarouselToSelection();
    }
  }

  @override
  void dispose() {
    _removeMiniButtons();
    _carouselController.removeListener(_updateArrowVisibility);
    _carouselController.dispose();
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  SliderState _getCurrentState() {
    return SliderStateHelper.getStateFromValue(
      widget.controller.value,
      SliderState.values.length,
    );
  }

  void _onControllerChange() {
    final currentState = _getCurrentState();

    // Hide mini buttons when dragging
    if (_isDragging && _showMiniButtons) {
      _hideMiniButtons();
    }

    if (_lastState != currentState) {
      HapticFeedback.heavyImpact();
      _lastState = currentState;

      // Execute default/main title callback when state changes
      _executeDefaultCallback(currentState);

      _resetCarouselForState(currentState);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateArrowVisibility();
      });
    }
  }

  void _resetCarouselForState(SliderState state) {
    final subItems = widget.subMenuItems[state] ?? [];
    if (subItems.isEmpty) return;

    final selectedIndex = widget.selectedSubIndex[state];
    final targetIndex = selectedIndex != null
        ? (selectedIndex + 1).clamp(0, subItems.length)
        : 0;

    if (!_carouselController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _resetCarouselForState(state);
      });
      return;
    }

    _carouselController.animateToItem(
      targetIndex,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _syncCarouselToSelection({bool animate = true}) {
    if (_isVerticalDragging) return;

    final state = _getCurrentState();
    final subItems = widget.subMenuItems[state] ?? [];
    if (subItems.isEmpty) return;

    // null seçim = ana başlık: uygulama seçimi temizlediğinde (closeToMain)
    // carousel de başlığa dönmeli; yoksa knob alt menü etiketinde asılı kalır
    // ve ekran (ana görünüm) ile çelişir.
    final selectedIndex = widget.selectedSubIndex[state];
    final targetIndex = selectedIndex != null
        ? (selectedIndex + 1).clamp(0, subItems.length)
        : 0;

    if (!_carouselController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncCarouselToSelection(animate: animate);
      });
      return;
    }

    if (_carouselController.selectedItem == targetIndex) return;

    if (animate) {
      _carouselController.animateToItem(
        targetIndex,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      _carouselController.jumpToItem(targetIndex);
    }
  }

  void _executeDefaultCallback(SliderState state) {
    final subItems = widget.subMenuItems[state] ?? [];

    // Find main title or default item and execute its callback
    for (final item in subItems) {
      if (item.isMainTitle || item.isDefault) {
        item.onTap();
        break;
      }
    }

    // If no main/default item found, execute main state callback
    if (subItems.isEmpty ||
        !subItems.any((item) => item.isMainTitle || item.isDefault)) {
      widget.onStateTap?.call(state);
    }
  }

  void _showMiniButtonsOverlay() {
    final state = _getCurrentState();
    final buttons = widget.miniButtons[state] ?? [];
    if (buttons.isEmpty) return;

    final RenderBox? renderBox =
        _knobKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final sliderValue = widget.controller.value;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: MiniButtonsOverlay(
          position: position,
          knobSize: const Size(SliderConfig.knobWidth, SliderConfig.knobHeight),
          buttons: buttons,
          sliderValue: sliderValue,
          onButtonTap: (index) {
            buttons[index].onTap();
            _hideMiniButtons();
          },
          onDismiss: _hideMiniButtons,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMiniButtons() {
    setState(() => _showMiniButtons = false);
    _removeMiniButtons();
  }

  void _removeMiniButtons() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleMiniButtons() {
    if (_showMiniButtons) {
      _hideMiniButtons();
    } else {
      setState(() => _showMiniButtons = true);
      _showMiniButtonsOverlay();
    }
  }

  void _updateArrowVisibility() {
    final state = _getCurrentState();
    final subItems = widget.subMenuItems[state] ?? [];

    if (subItems.isEmpty) {
      if (mounted && (_showUpArrow || _showDownArrow || !_isMainSelected)) {
        setState(() {
          _showUpArrow = false;
          _showDownArrow = false;
          _isMainSelected = true;
        });
      }
      return;
    }

    if (!_carouselController.hasClients) {
      if (mounted && (_showUpArrow || !_showDownArrow || !_isMainSelected)) {
        setState(() {
          _showUpArrow = false;
          _showDownArrow = true;
          _isMainSelected = true;
        });
      }
      return;
    }

    final position = _carouselController.position;
    final canScrollUp = position.pixels > position.minScrollExtent + 0.1;
    final canScrollDown = position.pixels < position.maxScrollExtent - 0.1;
    final isMainSelected = _carouselController.selectedItem == 0;

    if (mounted &&
        (_showUpArrow != canScrollUp ||
            _showDownArrow != canScrollDown ||
            _isMainSelected != isMainSelected)) {
      setState(() {
        _showUpArrow = canScrollUp;
        _showDownArrow = canScrollDown;
        _isMainSelected = isMainSelected;
      });
    }
  }

  double _calculateTransitionProgress(double value) {
    if (SliderState.values.length <= 1) return 1.0;

    final step = 1.0 / (SliderState.values.length - 1);
    final closestIndex = (value / step).round();
    final closestValue = closestIndex * step;
    final distance = (value - closestValue).abs();
    final maxDist = step / 2;

    if (maxDist <= 0) return 1.0;

    final t = 1.0 - (distance / maxDist).clamp(0.0, 1.0);
    return Curves.easeOutCirc.transform(t);
  }

  void _navigateToState(SliderState state) {
    final target =
        SliderStateHelper.getTargetValue(state, SliderState.values.length);
    widget.controller.animateTo(
      target,
      duration: SliderConfig.animationDuration,
      curve: SliderConfig.animationCurve,
    );
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _widgetWidth = constraints.maxWidth;

        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, child) {
            final value = widget.controller.value;
            final state = _getCurrentState();
            final activeColor = SliderStateHelper.getColorForState(state);
            final subItems = widget.subMenuItems[state] ?? [];
            // The add ('+') affordance and the mini-button tap are only valid
            // when the main title (carousel index 0) is centered. In subviews
            // the centered item is a submenu entry, so hide/disable them.
            // Tracked in state (see _updateArrowVisibility) so it stays in sync
            // on every carousel settle.
            final isMainSelected = _isMainSelected;
            final sectionWidth = _widgetWidth / SliderState.values.length;
            final knobPosition = SliderConfig.trackPadding +
                (value * (_widgetWidth - SliderConfig.knobWidth)) -
                8;
            final transitionProgress = _calculateTransitionProgress(value);

            return SizedBox(
              height: SliderConfig.sliderHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track background
                  _buildTrack(activeColor),

                  // State sections
                  for (int i = 0; i < SliderState.values.length; i++)
                    _buildStateSection(
                      SliderState.values[i],
                      i * sectionWidth,
                      sectionWidth,
                      state == SliderState.values[i],
                    ),

                  // Knob
                  Positioned(
                    left: knobPosition,
                    top: 0,
                    bottom: 0,
                    child: SliderKnob(
                      knobKey: _knobKey,
                      currentState: state,
                      activeColor: activeColor,
                      subMenuItems: subItems,
                      carouselController: _carouselController,
                      isDragging: _isDragging,
                      transitionProgress: transitionProgress,
                      showUpArrow: _showUpArrow,
                      showDownArrow: _showDownArrow,
                      showAddButton: isMainSelected,
                      texts: widget.texts,
                      onTap: isMainSelected
                          ? () {
                              _toggleMiniButtons();
                            }
                          : () {},
                      onMainTitleTap: () => widget.onStateTap?.call(state),
                      onHorizontalDragStart: () =>
                          setState(() => _isDragging = true),
                      onHorizontalDrag: (details) {
                        final trackWidth =
                            _widgetWidth - SliderConfig.knobWidth;
                        if (trackWidth <= 0) return;
                        final newValue = (widget.controller.value +
                                details.delta.dx / trackWidth)
                            .clamp(0.0, 1.0);
                        widget.controller.value = newValue;
                        widget.onValueChanged?.call(newValue);
                      },
                      onHorizontalDragEnd: () {
                        setState(() => _isDragging = false);
                        _navigateToState(state);
                        HapticFeedback.heavyImpact();
                      },
                      onVerticalDrag: subItems.isNotEmpty
                          ? (details) {
                              if (!_carouselController.hasClients) return;
                              _isVerticalDragging = true;
                              final position = _carouselController.position;
                              final newOffset =
                                  (position.pixels - details.delta.dy)
                                      .clamp(
                                        position.minScrollExtent,
                                        position.maxScrollExtent,
                                      )
                                      .toDouble();
                              _carouselController.jumpTo(newOffset);
                            }
                          : null,
                      onVerticalDragEnd: subItems.isNotEmpty
                          ? (details) {
                              _isVerticalDragging = false;
                              const itemHeight =
                                  SliderConfig.carouselItemHeight;
                              int targetIndex =
                                  (_carouselController.offset / itemHeight)
                                      .round();
                              final carouselItems = [
                                SubMenuItem(
                                    icon: Icons.title,
                                    label: SliderStateHelper.getLabelForState(
                                        state, widget.texts),
                                    onTap: () {}),
                                ...subItems
                              ];
                              targetIndex = targetIndex.clamp(
                                  0, carouselItems.length - 1);
                              _carouselController.animateToItem(
                                targetIndex,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.linear,
                              );
                              if (targetIndex == 0) {
                                widget.onStateTap?.call(state);
                                return;
                              }
                              if (targetIndex > 0) {
                                carouselItems[targetIndex].onTap();
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrack(Color activeColor) {
    return Positioned(
      top: SliderConfig.trackPaddingVertical,
      bottom: SliderConfig.trackPaddingVertical,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SliderConfig.trackRadius),
          color: activeColor.withValues(alpha: 0.08),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStateSection(
    SliderState targetState,
    double left,
    double width,
    bool isActive,
  ) {
    final label = SliderStateHelper.getLabelForState(targetState, widget.texts);

    final icon = SliderStateHelper.getIconForState(targetState);
    final color = SliderStateHelper.getColorForState(targetState);

    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () {
          if (isActive) widget.onStateTap?.call(targetState);
          _navigateToState(targetState);
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isActive ? 0.0 : 1.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? color : color.withValues(alpha: 0.9),
                  size: isActive ? 24 : 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isActive ? 13 : 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? color : color.withValues(alpha: 0.4),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
