import 'package:cunehat/features/main_feature/widgets/mini_button_data.dart';
import 'package:cunehat/features/main_feature/widgets/slider_state.dart';
import 'package:cunehat/features/main_feature/widgets/sub_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';

class SliderButtonEnhanced extends StatefulWidget {
  final AnimationController controller;
  final ValueChanged<double>? onValueChanged;
  final ValueChanged<SliderState>? onTap;
  final Map<SliderState, List<MiniButtonData>> miniButtons;
  final Map<SliderState, List<SubMenuItem>>? subMenuItems;

  const SliderButtonEnhanced({
    super.key,
    required this.controller,
    this.onValueChanged,
    this.onTap,
    this.miniButtons = const {},
    this.subMenuItems,
  });

  @override
  State<SliderButtonEnhanced> createState() => _SliderButtonEnhancedState();
}

class _SliderButtonEnhancedState extends State<SliderButtonEnhanced>
    with TickerProviderStateMixin {
  bool _dragging = false;
  double _widgetWidth = 0.0;
  bool _showMiniButtons = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _knobKey = GlobalKey();

  int? _selectedSubMenuIndex;
  SliderState? _lastState;

  @override
  void initState() {
    super.initState();
    _lastState = _getCurrentState(widget.controller.value);
    widget.controller.addListener(() {
      if (_dragging && _showMiniButtons) {
        _hideMiniButtons();
      }

      final currentState = _getCurrentState(widget.controller.value);
      if (_lastState != currentState) {
        HapticFeedback.heavyImpact();
        _lastState = currentState;
        _selectedSubMenuIndex = null;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _removeMiniButtons();
    super.dispose();
  }

  SliderState _getCurrentState(double value) {
    if (value < 0.33) return SliderState.savedMoney;
    if (value > 0.66) return SliderState.debt;
    return SliderState.transactions;
  }

  Color _getActiveColor(double value) {
    if (value < 0.33) return const Color(0xFF43A047);
    if (value > 0.66) return const Color(0xFFE53935);
    return const Color(0xFF1E88E5);
  }

  String _getStateLabel(SliderState state) {
    switch (state) {
      case SliderState.savedMoney:
        return 'BİRİKİM';
      case SliderState.transactions:
        return 'İŞLEMLER';
      case SliderState.debt:
        return 'BORÇ';
    }
  }

  IconData _getStateIcon(SliderState state) {
    switch (state) {
      case SliderState.savedMoney:
        return Icons.savings_outlined;
      case SliderState.transactions:
        return Icons.swap_horiz_rounded;
      case SliderState.debt:
        return Icons.account_balance_wallet_outlined;
    }
  }

  void _showMiniButtonsOverlay() {
    final state = _getCurrentState(widget.controller.value);
    final buttons = widget.miniButtons[state] ?? [];
    if (buttons.isEmpty) return;

    final RenderBox? renderBox =
        _knobKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final sliderValue = widget.controller.value;

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: _MiniButtonsOverlay(
          position: position,
          knobSize: size,
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

  void _navigateToState(double target) {
    widget.controller.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
    );
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _widgetWidth = constraints.maxWidth;
      return AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          final value = widget.controller.value;
          final state = _getCurrentState(value);
          final activeColor = _getActiveColor(value);
          final subItems = widget.subMenuItems?[state] ?? [];

          String knobLabel = _getStateLabel(state);
          if (_selectedSubMenuIndex != null &&
              _selectedSubMenuIndex! < subItems.length) {
            knobLabel = subItems[_selectedSubMenuIndex!].label.toUpperCase();
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ANA SLIDER - YATAY BÜYÜK
              SizedBox(
                height: 80,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // --- TRACK (Arka plan) ---
                    Positioned(
                      top: 5,
                      bottom: 5,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(35),
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
                    ),

                    // --- ÜÇ DURUM (Sol, Orta, Sağ) ---
                    // Sol - BİRİKİM
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildStateSection(
                        SliderState.savedMoney,
                        state == SliderState.savedMoney,
                        () {
                          if (state == SliderState.savedMoney) {
                            setState(() => _selectedSubMenuIndex = null);
                            widget.onTap?.call(SliderState.savedMoney);
                          }
                          _navigateToState(0.0);
                        },
                      ),
                    ),

                    // Orta - İŞLEMLER
                    Positioned(
                      left: _widgetWidth / 3,
                      top: 0,
                      bottom: 0,
                      child: _buildStateSection(
                        SliderState.transactions,
                        state == SliderState.transactions,
                        () {
                          if (state == SliderState.transactions) {
                            setState(() => _selectedSubMenuIndex = null);
                            widget.onTap?.call(SliderState.transactions);
                          }
                          _navigateToState(0.5);
                        },
                      ),
                    ),

                    // Sağ - BORÇ
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: _buildStateSection(
                        SliderState.debt,
                        state == SliderState.debt,
                        () {
                          if (state == SliderState.debt) {
                            setState(() => _selectedSubMenuIndex = null);
                            widget.onTap?.call(SliderState.debt);
                          }
                          _navigateToState(1.0);
                        },
                      ),
                    ),

                    // --- KNOB (Gezici gösterge) ---
                    Positioned(
                      left: 5 + (value * (_widgetWidth - 70)),
                      top: 10,
                      child: GestureDetector(
                        key: _knobKey,
                        onHorizontalDragStart: (_) =>
                            setState(() => _dragging = true),
                        onHorizontalDragUpdate: (details) {
                          double newValue = (widget.controller.value +
                                  details.delta.dx / (_widgetWidth - 70))
                              .clamp(0.0, 1.0);
                          widget.controller.value = newValue;
                          widget.onValueChanged?.call(newValue);
                        },
                        onHorizontalDragEnd: (_) {
                          setState(() => _dragging = false);
                          double target =
                              value < 0.33 ? 0.0 : (value > 0.66 ? 1.0 : 0.5);
                          _navigateToState(target);
                          HapticFeedback.heavyImpact();
                        },
                        onTap: () {
                          _toggleMiniButtons();
                          widget.onTap?.call(state);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                activeColor,
                                activeColor.withValues(alpha: 0.8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.6),
                                blurRadius: _dragging ? 30 : 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -12,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.15),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: activeColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                      scale: animation, child: child),
                                ),
                                child: AnimatedDefaultTextStyle(
                                  key: ValueKey(knobLabel),
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _dragging ? 12 : 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  child: Text(knobLabel),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- ALT MENÜ (Tag tarzı - küçük ve kompakt) ---
              if (subItems.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildSubMenuTags(subItems, activeColor),
              ],
            ],
          );
        },
      );
    });
  }

  Widget _buildStateSection(
      SliderState targetState, bool isActive, VoidCallback onTap) {
    final label = _getStateLabel(targetState);
    final icon = _getStateIcon(targetState);
    final baseColor = targetState == SliderState.savedMoney
        ? const Color(0xFF43A047)
        : targetState == SliderState.debt
            ? const Color(0xFFE53935)
            : const Color(0xFF1E88E5);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: _widgetWidth / 3,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.transparent,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isActive ? 0.0 : 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? baseColor : baseColor.withValues(alpha: 0.9),
                size: isActive ? 24 : 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: isActive ? 11 : 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color:
                      isActive ? baseColor : baseColor.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenuTags(List<SubMenuItem> items, Color activeColor) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(items.length, (index) {
        final isSelected = _selectedSubMenuIndex == index;
        return GestureDetector(
          onTap: () {
            if (isSelected) {
              setState(() => _selectedSubMenuIndex = null);
              widget.onTap?.call(_getCurrentState(widget.controller.value));
            } else {
              setState(() => _selectedSubMenuIndex = index);
              items[index].onTap();
            }
            HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(
                      color: activeColor.withValues(alpha: 0.3), width: 1)
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  items[index].icon,
                  size: 16,
                  color: isSelected
                      ? activeColor
                      : Colors.grey.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  items[index].label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? activeColor
                        : Colors.grey.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// Overlay widget'ı
class _MiniButtonsOverlay extends StatefulWidget {
  final Offset position;
  final Size knobSize;
  final List<MiniButtonData> buttons;
  final double sliderValue;
  final Function(int) onButtonTap;
  final VoidCallback onDismiss;

  const _MiniButtonsOverlay({
    required this.position,
    required this.knobSize,
    required this.buttons,
    required this.sliderValue,
    required this.onButtonTap,
    required this.onDismiss,
  });

  @override
  State<_MiniButtonsOverlay> createState() => _MiniButtonsOverlayState();
}

class _MiniButtonsOverlayState extends State<_MiniButtonsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          ...List.generate(widget.buttons.length, (index) {
            double baseAngle = math.pi / 2;
            double spread = 0.8;

            if (widget.sliderValue < 0.2) baseAngle -= 0.3;
            if (widget.sliderValue > 0.8) baseAngle += 0.3;

            double angle =
                baseAngle + (index - (widget.buttons.length - 1) / 2) * spread;
            double distance = 90.0;

            double offsetX = math.cos(angle) * distance;
            double offsetY = -math.sin(angle) * distance;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final curvedValue =
                    Curves.easeOutBack.transform(_controller.value);
                return Positioned(
                  left: widget.position.dx +
                      widget.knobSize.width / 2 +
                      (offsetX * curvedValue) -
                      30,
                  top: widget.position.dy +
                      widget.knobSize.height / 2 +
                      (offsetY * curvedValue) -
                      30,
                  child: Opacity(
                    opacity: _controller.value,
                    child: GestureDetector(
                      onTap: () => widget.onButtonTap(index),
                      child: SizedBox(
                        width: 60,
                        height: 80,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    widget.buttons[index].color,
                                    widget.buttons[index].color
                                        .withValues(alpha: 0.7),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.buttons[index].color
                                        .withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Icon(
                                widget.buttons[index].icon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                              child: Text(
                                widget.buttons[index].label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: widget.buttons[index].color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
