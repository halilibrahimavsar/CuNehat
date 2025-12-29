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

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (_dragging && _showMiniButtons) {
        setState(() => _showMiniButtons = false);
      }
    });
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

  // Mini butonları oluşturan yardımcı metod
  List<Widget> _buildRadialButtons(double sliderValue, SliderState state) {
    final buttons = widget.miniButtons[state] ?? [];
    if (buttons.isEmpty) return [];

    return List.generate(buttons.length, (index) {
      // Slider kenardayken butonların dışarı taşmaması için açı hesabı
      double baseAngle = -math.pi / 2; // Tam yukarı
      double spread = 2; // Butonlar arası açıklık

      // Kenar kontrolü: Eğer slider en soldaysa sağa, en sağdaysa sola yatık açıl
      if (sliderValue < 0.2) baseAngle += 0.4;
      if (sliderValue > 0.8) baseAngle -= 0.4;

      double angle = baseAngle + (index - (buttons.length - 1) / 2) * spread;
      double distance = _showMiniButtons ? 55.0 : 0.0;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 400),
        curve: Curves.bounceOut,
        bottom: 28 + (math.sin(angle) * distance).abs(),
        left: (math.cos(angle) * distance),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showMiniButtons ? 1.0 : 0.0,
          child: GestureDetector(
            onTap: () {
              buttons[index].onTap();
              setState(() => _showMiniButtons = false);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: buttons[index].color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: buttons[index].color.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: Offset(0, 4))
                    ],
                  ),
                  child: Icon(buttons[index].icon,
                      color: buttons[index].color, size: 20),
                ),
                const SizedBox(height: 4),
                Material(
                  color: Colors.transparent,
                  child: Text(
                    buttons[index].label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    });
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
            height: 100, // Yelpaze ve alt metinler için yeterli alan
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // --- TRACK (ARKA PLAN) ---
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
                            blurRadius: 10)
                      ],
                    ),
                  ),
                ),

                // --- ALT BİLGİ METİNLERİ ---
                Positioned(
                  bottom: 45,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomLabel("Gider", state == SliderState.expense,
                          const Color(0xFFE53935)),
                      _buildBottomLabel("Kıyasla", state == SliderState.compare,
                          const Color(0xFF1E88E5)),
                      _buildBottomLabel("Gelir", state == SliderState.income,
                          const Color(0xFF43A047)),
                    ],
                  ),
                ),

                // --- KNOB VE MİNİ BUTONLAR ---
                Positioned(
                  bottom: 30,
                  left: 25 + (value * (_widgetWidth - 100)),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Mini Butonlar (Knob'un arkasından fırlarlar)
                      ..._buildRadialButtons(value, state),

                      // Ana Buton (Knob)
                      GestureDetector(
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
                          widget.controller.animateTo(target,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutBack);
                          HapticFeedback.lightImpact();
                        },
                        onTap: () {
                          setState(() => _showMiniButtons = !_showMiniButtons);
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
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildBottomLabel(String text, bool isActive, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      transform: Matrix4.translationValues(0, isActive ? 40 : 0, 0),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          color: isActive ? color : Colors.grey[600],
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          fontSize: isActive ? 14 : 12,
        ),
        child: Text(text),
      ),
    );
  }
}
