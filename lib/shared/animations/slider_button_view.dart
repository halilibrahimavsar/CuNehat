import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 1. Durumları temsil eden Enum'ı tanımlıyoruz
enum SliderState { expense, compare, income }

class SliderButtonEnhanced extends StatefulWidget {
  final AnimationController controller;
  final ValueChanged<double>? onValueChanged;

  // 2. onTap artık boş değil, SliderState tipinde veri taşıyan bir fonksiyon
  final ValueChanged<SliderState>? onTap;

  const SliderButtonEnhanced({
    super.key,
    required this.controller,
    this.onValueChanged,
    this.onTap,
  });

  @override
  State<SliderButtonEnhanced> createState() => _SliderButtonEnhancedState();
}

class _SliderButtonEnhancedState extends State<SliderButtonEnhanced> {
  bool _dragging = false;
  double _widgetWidth = 0.0;
  int _lastZone = 1;

  @override
  void initState() {
    super.initState();
    _updateZone(widget.controller.value);
    widget.controller.addListener(() {
      if (!_dragging) {
        _updateZone(widget.controller.value);
      }
    });
  }

  void _updateZone(double value) {
    int currentZone;
    if (value < 0.33) {
      currentZone = 0;
    } else if (value > 0.66) {
      currentZone = 2;
    } else {
      currentZone = 1;
    }

    if (currentZone != _lastZone) {
      HapticFeedback.selectionClick();
      _lastZone = currentZone;
    }
  }

  void _notifyValueChanged(double value) {
    widget.onValueChanged?.call(value);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final dx = details.localPosition.dx;
    final newValue = (dx / _widgetWidth).clamp(0.0, 1.0);
    widget.controller.value = newValue;
    _updateZone(newValue);
    _notifyValueChanged(newValue);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    double target;

    if (velocity.abs() > 300) {
      if (velocity > 0) {
        target = 1.0;
      } else {
        target = 0.0;
      }
    } else {
      double value = widget.controller.value;
      if (value < 0.33) {
        target = 0.0;
      } else if (value > 0.66) {
        target = 1.0;
      } else {
        target = 0.5;
      }
    }

    widget.controller.animateTo(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
    );

    setState(() => _dragging = false);
    _notifyValueChanged(target);
    HapticFeedback.lightImpact();
  }

  // Yardımcı metod: Mevcut double değerini Enum'a çevirir
  SliderState _getCurrentState(double value) {
    if (value < 0.33) return SliderState.expense;
    if (value > 0.66) return SliderState.income;
    return SliderState.compare;
  }

  Color _getTrackColor(double value) {
    if (value < 0.5) {
      return Color.lerp(
          const Color(0xFFFFEBEE), const Color(0xFFE3F2FD), value * 2)!;
    } else {
      return Color.lerp(
          const Color(0xFFE3F2FD), const Color(0xFFE8F5E9), (value - 0.5) * 2)!;
    }
  }

  Color _getActiveColor(double value) {
    if (value < 0.33) return Colors.redAccent;
    if (value > 0.66) return Colors.green;
    return Colors.blueAccent;
  }

  IconData _getIcon(double value) {
    if (value < 0.33) return Icons.remove;
    if (value > 0.66) return Icons.add;
    return Icons.compare_arrows_rounded;
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

            return GestureDetector(
              onHorizontalDragStart: (_) => setState(() => _dragging = true),
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onTapUp: (details) {
                // Track üzerine tıklandığında animasyonla oraya gitme
                final tapPosition = details.localPosition.dx / _widgetWidth;
                double target;
                if (tapPosition < 0.33) {
                  target = 0.0;
                } else if (tapPosition > 0.66) {
                  target = 1.0;
                } else {
                  target = 0.5;
                }
                widget.controller.animateTo(target,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutQuint);
              },
              child: SizedBox(
                height: 72,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // --- TRACK (ARKA PLAN ÇUBUĞU) ---
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: _getTrackColor(value),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            offset: const Offset(-2, -2),
                            blurRadius: 4,
                          ),
                          BoxShadow(
                              color: Colors.grey.shade300,
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                              blurStyle: BlurStyle.inner),
                        ],
                      ),
                    ),

                    // --- METİNLER (LABEL) ---
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 66,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDynamicLabel(
                                text: "Gider",
                                targetPos: 0.0,
                                currentPos: value,
                                activeColor: Colors.red[800]!),
                            _buildDynamicLabel(
                                text: "Karşılaştır",
                                targetPos: 0.5,
                                currentPos: value,
                                activeColor: Colors.blue[800]!),
                            _buildDynamicLabel(
                                text: "Gelir",
                                targetPos: 1.0,
                                currentPos: value,
                                activeColor: Colors.green[800]!),
                          ],
                        ),
                      ),
                    ),

                    // --- HAREKETLİ DÜĞME (KNOB) ---
                    Positioned(
                      bottom: 4,
                      left: 32,
                      right: 32,
                      child: Align(
                        alignment: Alignment(value * 2 - 1, 0),
                        child: GestureDetector(
                          // 3. Butona tıklandığında o anki durumu (Enum) gönderiyoruz
                          onTap: () {
                            if (widget.onTap != null) {
                              widget.onTap!(_getCurrentState(value));
                            }
                          },
                          child: Transform.scale(
                            scale: _dragging ? 1.05 : 1.0,
                            child: Container(
                              height: 56,
                              width: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                    color:
                                        _getActiveColor(value).withOpacity(0.5),
                                    width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                      color: _getActiveColor(value)
                                          .withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                      spreadRadius: 2),
                                ],
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, anim) =>
                                    RotationTransition(
                                  turns: Tween<double>(begin: 0.75, end: 1.0)
                                      .animate(anim),
                                  child: ScaleTransition(
                                      scale: anim, child: child),
                                ),
                                child: Icon(
                                  _getIcon(value),
                                  key: ValueKey(
                                      'icon_${value < 0.33 ? 'rem' : value > 0.66 ? 'add' : 'compare'}'),
                                  color: _getActiveColor(value),
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDynamicLabel({
    required String text,
    required double targetPos,
    required double currentPos,
    required Color activeColor,
  }) {
    double distance = (currentPos - targetPos).abs();
    const double threshold = 0.25;

    double translateY = 0.0;
    double scale = 1.0;
    double opacity = 0.6;
    FontWeight fontWeight = FontWeight.normal;
    Color color = Colors.grey[600]!;

    if (distance < threshold) {
      double proximityFactor = 1.0 - (distance / threshold);
      translateY = -40.0 * proximityFactor;
      scale = 1.0 + (0.2 * proximityFactor);
      opacity = 0.6 + (0.4 * proximityFactor);
      color = Color.lerp(Colors.grey[600], activeColor, proximityFactor)!;
      if (proximityFactor > 0.5) {
        fontWeight = FontWeight.bold;
      }
    }

    return Expanded(
      child: Transform.translate(
        offset: Offset(0, translateY),
        child: Transform.scale(
          scale: scale,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color.withOpacity(opacity.clamp(0.0, 1.0)),
              fontWeight: fontWeight,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
