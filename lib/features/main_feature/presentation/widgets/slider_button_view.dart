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
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (_dragging && _showMiniButtons) {
        _hideMiniButtons();
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

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final buttons =
            widget.miniButtons[_getCurrentState(widget.controller.value)] ?? [];
        if (buttons.isEmpty) return const SizedBox.shrink();

        return Positioned.fill(
          child: GestureDetector(
            onTap: _hideMiniButtons,
            behavior: HitTestBehavior.opaque,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-72,
                  -72), // 200x200'lük alanı 56x56'lık butona ortalamak için: (56-200)/2
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  height: 200,
                  child: Stack(
                    children: [
                      ...List.generate(buttons.length, (index) {
                        final button = buttons[index];

                        double baseAngle = -math.pi / 2;
                        double spread = math.pi / (buttons.length + 1);
                        double angle = baseAngle +
                            (index - (buttons.length - 1) / 2) * spread * 0.8;
                        double distance = 70.0;

                        double left = 100 + (math.cos(angle) * distance);
                        double top = 100 +
                            (math.sin(angle) *
                                distance); // .abs() kaldırıldı, yukarı doğru açılması için

                        return Positioned(
                          left: left - 20,
                          top: top - 20,
                          child: GestureDetector(
                            onTap: () {
                              button.onTap();
                              _hideMiniButtons();
                              HapticFeedback.selectionClick();
                            },
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 300),
                              curve: _showMiniButtons
                                  ? Curves.elasticOut
                                  : Curves.easeOut,
                              scale: _showMiniButtons ? 1.0 : 0.0,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: _showMiniButtons ? 1.0 : 0.0,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: button.color
                                            .withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: button.color
                                                .withValues(alpha: 0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        button.icon,
                                        color: button.color,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        button.label,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Animasyonu tetiklemek için bir frame bekle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _showMiniButtons = true);
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  void _hideMiniButtons() {
    if (_overlayEntry == null) return;

    setState(() => _showMiniButtons = false);
    _overlayEntry?.markNeedsBuild();

    // Animasyonun bitmesini bekle sonra kaldır
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_showMiniButtons && _overlayEntry != null) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
    });
  }

  void _toggleMiniButtons() {
    bool willOpen = !_showMiniButtons;
    if (_showMiniButtons) {
      _hideMiniButtons();
    } else if (_overlayEntry != null) {
      // Kapanırken tekrar açılmak istenirse
      setState(() => _showMiniButtons = true);
      _overlayEntry?.markNeedsBuild();
    } else {
      _showOverlay();
    }
    widget.onTap?.call(_getCurrentState(widget.controller.value));
    if (willOpen) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    super.dispose();
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
            height: 100,
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
                          blurRadius: 10,
                        ),
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
                      _buildBottomLabel(
                        "Gider",
                        state == SliderState.expense,
                        const Color(0xFFE53935),
                        0.0,
                      ),
                      _buildBottomLabel(
                        "Kıyasla",
                        state == SliderState.compare,
                        const Color(0xFF1E88E5),
                        0.5,
                      ),
                      _buildBottomLabel(
                        "Gelir",
                        state == SliderState.income,
                        const Color(0xFF43A047),
                        1.0,
                      ),
                    ],
                  ),
                ),

                // --- KNOB ---
                Positioned(
                  bottom: 30,
                  left: 25 + (value * (_widgetWidth - 100)),
                  child: CompositedTransformTarget(
                    link: _layerLink,
                    child: GestureDetector(
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
                        if (!_dragging) {
                          _toggleMiniButtons();
                        }
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
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildBottomLabel(
    String text,
    bool isActive,
    Color color,
    double targetValue,
  ) {
    return GestureDetector(
      onTap: () {
        widget.controller.animateTo(
          targetValue,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
        );
        widget.onValueChanged?.call(targetValue);
        _hideMiniButtons();
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
