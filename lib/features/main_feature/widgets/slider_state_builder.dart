import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/helpers/slider_state_helper.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Kaydırıcının SÜREKLİ değerinden AYRIK durumu türetir ve yalnız durum
/// değişince yeniden kurar.
///
/// Kaydırıcıya bağlı ağaçların çoğu (üst çubuğun başlığı, cüzdan tutarı, tur
/// hedefleri) ham değeri değil yalnız aktif durumu kullanıyor. Doğrudan
/// `AnimatedBuilder` kullanıldığında bunlar kaydırma boyunca saniyede 60 kez
/// yeniden kuruluyordu; oysa durum tam bir sürüşte yalnız iki kez değişir.
class SliderStateBuilder extends StatefulWidget {
  const SliderStateBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  final Animation<double> animation;
  final Widget Function(BuildContext context, SliderState state) builder;

  @override
  State<SliderStateBuilder> createState() => _SliderStateBuilderState();
}

class _SliderStateBuilderState extends State<SliderStateBuilder> {
  late SliderState _state;

  @override
  void initState() {
    super.initState();
    _state = _resolve();
    widget.animation.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant SliderStateBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeListener(_onChanged);
      widget.animation.addListener(_onChanged);
      _onChanged();
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_onChanged);
    super.dispose();
  }

  SliderState _resolve() => SliderStateHelper.getStateFromValue(
        widget.animation.value,
        SliderState.values.length,
      );

  void _onChanged() {
    final next = _resolve();
    if (next == _state) return;
    setState(() => _state = next);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _state);
}
