// IbreSliderButton kodu (Ters mantık ile) aynı kalmıştır ve doğru çalışmaktadır.
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

class SliderButtonExpenseIncome extends StatefulWidget {
  final AnimationController controller;
  const SliderButtonExpenseIncome({super.key, required this.controller});

  @override
  State<SliderButtonExpenseIncome> createState() =>
      _SliderButtonExpenseIncomeState();
}

class _SliderButtonExpenseIncomeState extends State<SliderButtonExpenseIncome> {
  bool _dragging = false;
  double _widgetWidth = 0.0;

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    double target;

    if (velocity.abs() > 300) {
      target = velocity > 0 ? 0.0 : 1.0;
    } else {
      target = widget.controller.value > 0.5 ? 1.0 : 0.0;
    }

    widget.controller.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
    );

    setState(() => _dragging = false);
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

            final trackColor =
                Color.lerp(Colors.green[100], Colors.red[100], value);

            return GestureDetector(
              onHorizontalDragStart: (_) => setState(() => _dragging = true),
              onHorizontalDragUpdate: (details) {
                final newValue =
                    (1.0 - (details.localPosition.dx / _widgetWidth))
                        .clamp(0.0, 1.0);
                widget.controller.value = newValue;
              },
              onHorizontalDragEnd: _onDragEnd,
              child: AnimatedContainer(
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
                  children: [
                    // Metinler
                    Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: (1 - value).clamp(0.0, 1.0),
                        child: Text(
                          "Income",
                          style: TextStyle(
                              color: Colors.green[800],
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: value.clamp(0.0, 1.0),
                        child: Text(
                          "Expense",
                          style: TextStyle(
                              color: Colors.red[800],
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // Topuzu 'Align' ile konumlandırma
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
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Icon(
                            value > 0.5
                                ? Icons.arrow_forward_ios
                                : Icons.arrow_back_ios_new,
                            color: value > 0.5 ? Colors.green : Colors.red,
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
