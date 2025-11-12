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
    // ... existing code ...
    final velocity = details.primaryVelocity ?? 0;
    final currentValue = widget.controller.value;
    double target; // Hedef değer (0.0, 0.5, veya 1.0)

    // Yüksek hızda kaydırma (Fling)
    if (velocity.abs() > 300) {
      if (velocity > 0) {
        // Sağa (Expense'ten Compare'e doğru) Fling (value azalıyor)
        if (currentValue > 0.5) {
          target = 0.5; // Gelir'den Karşılaştır'a
        } else {
          target = 0.0; // Karşılaştır'dan Gider'e
        }
      } else {
        // Sola (Income'a doğru) Fling (value artıyor)
        if (currentValue < 0.5) {
          target = 0.5; // Gider'den Karşılaştır'a
        } else {
          target = 1.0; // Karşılaştır'dan Gelir'e
        }
      }
    } else {
      // Yavaş sürükleme (Snap)
      // En yakın kilitlenme noktasını bul
      if (currentValue > 0.75) {
        target = 1.0; // Gelir'e en yakın
      } else if (currentValue < 0.25) {
        target = 0.0; // Gider'e en yakın
      } else {
        target = 0.5; // Karşılaştır'a en yakın
      }
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
            final value = widget
                .controller.value; // 0.0=Gider, 0.5=Karşılaştır, 1.0=Gelir
            final knobRotation = lerpDouble(0, 0, value)!;

            // Arka plan rengi (Değişiklik yok)
            final trackColor = value < 0.5
                ? Color.lerp(Colors.red[100], Colors.blue[100],
                    value * 2) // 0.0 -> 0.5 (Gider -> Karşılaştır)
                : Color.lerp(Colors.blue[100], Colors.green[100],
                    (value - 0.5) * 2); // 0.5 -> 1.0 (Karşılaştır -> Gelir)

            // --- DEĞİŞİKLİK: Arka plandaki yazı opaklıkları (Restore Edildi) ---
            // Gider yazısı (Sağda, value=0.0): value 0.0'dan 0.5'e gittikçe solmalı.
            final expenseOpacity = (1.0 - value * 2).clamp(0.0, 1.0);

            // Gelir yazısı (Solda, value=1.0): value 1.0'dan 0.5'e gittikçe solmalı.
            final incomeOpacity = (value * 2 - 1.0).clamp(0.0, 1.0);

            // Topuz içindeki Karşılaştır yazısı opaklığı
            final compareOpacity =
                (1.0 - (value - 0.5).abs() * 2).clamp(0.0, 1.0);

            // İkon mantığı (Renkler ve yönler düzeltildi: 0.0=Red, 1.0=Green)
            final IconData knobIcon;
            final Color knobIconColor;

            // value=1.0 Gelir (Sol, Yeşil)
            if (value > 0.75) {
              knobIcon = Icons.arrow_back_ios_new;
              knobIconColor = Colors.green;
              // value=0.0 Gider (Sağ, Kırmızı)
            } else if (value < 0.25) {
              knobIcon = Icons.arrow_forward_ios;
              knobIconColor = Colors.red;
              // value=0.5 Karşılaştır (Orta, Mavi)
            } else {
              knobIcon = Icons.compare_arrows;
              knobIconColor = Colors.blue;
            }

            return GestureDetector(
              onHorizontalDragStart: (_) => setState(() => _dragging = true),
              onHorizontalDragUpdate: (details) {
                // ... existing code ...
                // value=1.0 (Gelir) solda, value=0.0 (Gider) sağda olduğu için
                // sürükleme yönü ters görünüyor.
                // dx arttıkça (sağa sürükleme) value azalmalı (Gider'e gitmeli)
                // dx azaldıkça (sola sürükleme) value artmalı (Gelir'e gitmeli)

                // Formül: 1.0 - (x_pozisyonu / toplam_genişlik)
                // x=0 (Sol): value = 1.0 - 0 = 1.0 (Gelir)
                // x=genişlik (Sağ): value = 1.0 - 1.0 = 0.0 (Gider)
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
                    // ... existing code ...
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
                    // --- ARKA PLAN YAZILARI (Restore Edildi) ---

                    // GELİR Yazısı (Solda)
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

                    // GİDER Yazısı (Sağda)
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

                    // --- TOPUZ (KNOB) ---

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
                            // ... existing code ...
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
                          // --- Topuzun İçi (Compare/Karşılaştır yazısı veya İkon) ---
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // İkonlar (Sadece kenarlarda görünür)
                              // Opaklığı, compareOpacity'nin tersidir.
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: (1.0 - compareOpacity).clamp(0.0, 1.0),
                                child: Icon(
                                  knobIcon,
                                  color: knobIconColor,
                                ),
                              ),
                              // Karşılaştır Metni (Sadece ortada görünür)
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: compareOpacity,
                                child: Text(
                                  "Karşılaştır", // Türkçe
                                  style: TextStyle(
                                      color: Colors.blue[800],
                                      // Yazının 60px'lik daireye sığması için
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
