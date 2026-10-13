import 'dart:ui' show lerpDouble;

import 'package:cunehat/core/shared/motion/app_motion.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/amount_visibility.dart';

/// Tutarı değiştiğinde eskisinden yenisine SAYARAK giden [MoneyText].
///
/// Üst çubuktaki bakiye için: kayıt yazılınca rakam bir anda değişiyordu ve
/// kullanıcı "ne oldu?" sorusunun yanıtını kendi çıkarıyordu. Sayma, kaydın
/// bakiyeye ne yaptığını gösterir.
///
/// Yalnız AYNI şeyin tutarı değişince sayar: [identity] değişirse (başka
/// cüzdan, başka bölüm) yeni tutar doğrudan yazılır — iki cüzdanın bakiyesi
/// arasında saymak anlamsız bir hareket olurdu. İlk kurulumda da sayılmaz.
///
/// Sistemde "animasyonları kaldır" açıksa tutar doğrudan yazılır.
class AnimatedMoneyText extends StatefulWidget {
  const AnimatedMoneyText({
    super.key,
    required this.amount,
    required this.currency,
    required this.identity,
    this.style,
    this.obscureMode = AmountObscureMode.replace,
    this.alignment = Alignment.centerLeft,
    this.animationCurve = Curves.easeOut,
  });

  final double amount;
  final String currency;

  /// Tutarın NEYE ait olduğu (ör. cüzdan kimliği + bölüm).
  final Object identity;

  final TextStyle? style;
  final AmountObscureMode obscureMode;
  final AlignmentGeometry alignment;
  final Curve animationCurve;

  /// Sayma süresi: göz takip edebilsin ama beklemesin.
  static const Duration duration = Duration(milliseconds: 500);

  @override
  State<AnimatedMoneyText> createState() => _AnimatedMoneyTextState();
}

class _AnimatedMoneyTextState extends State<AnimatedMoneyText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AnimatedMoneyText.duration,
    value: 1,
  );
  late double _from = widget.amount;
  late double _to = widget.amount;

  double get _shown {
    final t = AppMotion.enter.transform(_controller.value);
    return lerpDouble(_from, _to, t)!;
  }

  @override
  void didUpdateWidget(covariant AnimatedMoneyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sameThing = oldWidget.identity == widget.identity &&
        oldWidget.currency == widget.currency;
    if (!sameThing || MediaQuery.disableAnimationsOf(context)) {
      _from = _to = widget.amount;
      _controller.value = 1;
      return;
    }
    if (widget.amount == _to) return;
    // Sayma sürerken yeni kayıt gelirse o anda görünen rakamdan devam eder.
    _from = _shown;
    _to = widget.amount;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => MoneyText(
        amount: _controller.isAnimating ? _shown : _to,
        currency: widget.currency,
        style: widget.style,
        obscureMode: widget.obscureMode,
        alignment: widget.alignment,
        animationCurve: widget.animationCurve,
      ),
    );
  }
}
