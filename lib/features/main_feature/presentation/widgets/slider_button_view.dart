import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

enum SliderState { expense, compare, income }

class MiniButtonData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  MiniButtonData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class SliderButtonEnhanced extends StatefulWidget {
  final AnimationController controller;
  final ValueChanged<double>? onValueChanged;
  final ValueChanged<SliderState>? onTap;
  final Map<SliderState, List<MiniButtonData>> miniButtons;

  const SliderButtonEnhanced({
    super.key,
    required this.controller,
    this.onValueChanged,
    this.onTap,
    this.miniButtons = const {},
  });

  @override
  State<SliderButtonEnhanced> createState() => _SliderButtonEnhancedState();
}

class _SliderButtonEnhancedState extends State<SliderButtonEnhanced> {
  bool _dragging = false;
  double _widgetWidth = 0.0;
  bool _showMiniButtons = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _knobKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (_dragging && _showMiniButtons) {
        _hideMiniButtons();
      }
    });
  }

  @override
  void dispose() {
    _removeMiniButtons();
    super.dispose();
  }

  SliderState _getCurrentState(double value) {
    if (value < 0.33) return SliderState.expense;
    if (value > 0.66) return SliderState.income;
    return SliderState.compare;
  }

  Color _getActiveColor(double value) {
    if (value < 0.33) return const Color(0xFFE53935);
    if (value > 0.66) return const Color(0xFF43A047);
    return const Color(0xFF1E88E5);
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
      builder: (context) => _MiniButtonsOverlay(
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

          return SizedBox(
            height: 76,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // --- TRACK ---
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: activeColor.withValues(alpha: 0.1),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.1),
                          blurRadius: 10,
                        )
                      ],
                    ),
                  ),
                ),

                // --- ALT BİLGİ METİNLERİ ---
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomLabel("Gider", state == SliderState.expense,
                          const Color(0xFFE53935), 0.0),
                      _buildBottomLabel("Kıyasla", state == SliderState.compare,
                          const Color(0xFF1E88E5), 0.5),
                      _buildBottomLabel("Gelir", state == SliderState.income,
                          const Color(0xFF43A047), 1.0),
                    ],
                  ),
                ),

                // --- KNOB ---
                Positioned(
                  bottom: 30,
                  left: 25 + (value * (_widgetWidth - 100)),
                  child: GestureDetector(
                    key: _knobKey,
                    onHorizontalDragStart: (_) =>
                        setState(() => _dragging = true),
                    onHorizontalDragUpdate: (details) {
                      double newValue = (widget.controller.value +
                              details.delta.dx / (_widgetWidth - 60))
                          .clamp(0.0, 1.0);
                      widget.controller.value = newValue;
                      widget.onValueChanged?.call(newValue);
                    },
                    onHorizontalDragEnd: (_) {
                      setState(() => _dragging = false);
                      double target =
                          value < 0.33 ? 0.0 : (value > 0.66 ? 1.0 : 0.5);
                      widget.controller.animateTo(
                        target,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                      );
                      HapticFeedback.lightImpact();
                    },
                    onTap: () {
                      _toggleMiniButtons();
                      widget.onTap?.call(state);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor,
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.4),
                            blurRadius: _dragging ? 20 : 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        state == SliderState.expense
                            ? Icons.remove
                            : (state == SliderState.income
                                ? Icons.add
                                : Icons.compare_arrows),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildBottomLabel(
      String text, bool isActive, Color color, double targetValue) {
    return GestureDetector(
      onTap: () {
        widget.controller.animateTo(
          targetValue,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
        );
        widget.onValueChanged?.call(targetValue);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        transform: Matrix4.translationValues(0, isActive ? 45 : 0, 0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isActive ? color : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: isActive ? 14 : 12,
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }
}

// Overlay widget'ı - TÜM DİĞER WİDGET'LARIN ÜSTÜNDE GÖRÜNÜR
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
          // Şeffaf arka plan - dokunulunca kapat
          Container(color: Colors.transparent),

          // Mini butonlar
          ...List.generate(widget.buttons.length, (index) {
            double baseAngle = math.pi / 2; // Yukarı doğru
            double spread = 0.9;

            if (widget.sliderValue < 0.2) baseAngle -= 0.4;
            if (widget.sliderValue > 0.8) baseAngle += 0.4;

            double angle =
                baseAngle + (index - (widget.buttons.length - 1) / 2) * spread;
            double distance = 80.0;

            double offsetX = math.cos(angle) * distance;
            double offsetY = -math.sin(angle) * distance;

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final curvedValue =
                    Curves.bounceOut.transform(_controller.value);
                return Positioned(
                  left: widget.position.dx +
                      widget.knobSize.width / 2 +
                      (offsetX * curvedValue) -
                      25,
                  top: widget.position.dy +
                      widget.knobSize.height / 2 +
                      (offsetY * curvedValue) -
                      25,
                  child: Opacity(
                    opacity: _controller.value,
                    child: GestureDetector(
                      onTap: () => widget.onButtonTap(index),
                      child: Container(
                        width: 50,
                        height: 70,
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: widget.buttons[index].color
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.buttons[index].color
                                        .withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Icon(
                                widget.buttons[index].icon,
                                color: widget.buttons[index].color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.buttons[index].label,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
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
