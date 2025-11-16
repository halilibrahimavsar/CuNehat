import 'dart:ui';

import 'package:flutter/material.dart';

class SliderButtonExpenseIncome extends StatefulWidget {
  final AnimationController controller;
  final ValueChanged<double>? onValueChanged; // Yeni callback eklendi

  const SliderButtonExpenseIncome({
    super.key,
    required this.controller,
    this.onValueChanged, // Yeni parametre
  });

  @override
  State<SliderButtonExpenseIncome> createState() =>
      _SliderButtonExpenseIncomeState();
}

class _SliderButtonExpenseIncomeState extends State<SliderButtonExpenseIncome> {
  bool _dragging = false;
  double _widgetWidth = 0.0;

  // Değer değiştiğinde callback'i çağır
  void _notifyValueChanged(double value) {
    if (widget.onValueChanged != null) {
      widget.onValueChanged!(value);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    // ... mevcut kod ...
    final velocity = details.primaryVelocity ?? 0;
    double target;

    final currentValue = widget.controller.value;

    // Hızlı kaydırma durumunda en yakın mantıksal noktaya git
    if (velocity.abs() > 300) {
      target = velocity > 0
          ? 0.0
          : 1.0; // Sağa kaydırma 0'a, sola kaydırma 1'e gider
      if ((currentValue - 0.5).abs() < (target - 0.5).abs()) {
        target = 0.5; // Eğer orta noktaya daha yakınsa, ortaya git
      }
    } else {
      target = (currentValue * 2).round() /
          2.0; // En yakın 0.0, 0.5 veya 1.0 değerine yuvarla
    }

    widget.controller.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
    );

    setState(() => _dragging = false);
    _notifyValueChanged(target); // Hedef değer değiştiğinde bildir
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

            final knobRotation = lerpDouble(0, 0, value)!;
            // ... geri kalan mevcut kod ...
            final trackColor = value < 0.5
                ? Color.lerp(Colors.red[100], Colors.blue[100], value * 2)
                : Color.lerp(
                    Colors.blue[100], Colors.green[100], (value - 0.5) * 2);

            final expenseOpacity = (1.0 - value * 2).clamp(0.0, 1.0);
            final incomeOpacity = (value * 2 - 1.0).clamp(0.0, 1.0);
            final compareOpacity =
                (1.0 - (value - 0.5).abs() * 2).clamp(0.0, 1.0);

            final IconData knobIcon;
            final Color knobIconColor;

            if (value > 0.75) {
              knobIcon = Icons.arrow_forward_ios;
              knobIconColor = Colors.green;
            } else if (value < 0.25) {
              knobIcon = Icons.arrow_back_ios_new;
              knobIconColor = Colors.red;
            } else {
              knobIcon = Icons.compare_arrows;
              knobIconColor = Colors.blue;
            }

            return GestureDetector(
              onHorizontalDragStart: (_) => setState(() => _dragging = true),
              onHorizontalDragUpdate: (details) {
                final newValue =
                    (1.0 - (details.localPosition.dx / _widgetWidth))
                        .clamp(0.0, 1.0);
                widget.controller.value = newValue;
                _notifyValueChanged(newValue); // Sürükleme sırasında bildir
              },
              onHorizontalDragEnd: _onDragEnd,
              child: AnimatedContainer(
                // ... mevcut container kodu ...
                duration: const Duration(milliseconds: 300),
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: trackColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ... mevcut stack children kodu ...
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: incomeOpacity,
                          child: Text(
                            "Gelir",
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: expenseOpacity,
                          child: Text(
                            "Gider",
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.lerp(
                          Alignment.centerRight, Alignment.centerLeft, value)!,
                      child: Transform.rotate(
                        angle: knobRotation,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 60,
                          width: 60,
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _dragging ? Colors.white : Colors.grey[200],
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: (1.0 - compareOpacity).clamp(0.0, 1.0),
                                child: Icon(
                                  knobIcon,
                                  color: knobIconColor,
                                ),
                              ),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: compareOpacity,
                                child: Text(
                                  "Karşılaştır",
                                  style: TextStyle(
                                      color: Colors.blue[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
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
            );
          },
        );
      },
    );
  }
}
