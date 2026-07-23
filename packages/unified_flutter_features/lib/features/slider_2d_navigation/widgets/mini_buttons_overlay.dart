import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../models/slider_models.dart';
import '../constants/slider_config.dart';

class MiniButtonsOverlay extends StatefulWidget {
  final Offset position;
  final Size knobSize;
  final List<MiniButtonData> buttons;
  final double sliderValue;
  final ValueChanged<int> onButtonTap;
  final VoidCallback onDismiss;

  const MiniButtonsOverlay({
    super.key,
    required this.position,
    required this.knobSize,
    required this.buttons,
    required this.sliderValue,
    required this.onButtonTap,
    required this.onDismiss,
  });

  @override
  State<MiniButtonsOverlay> createState() => _MiniButtonsOverlayState();
}

class _MiniButtonsOverlayState extends State<MiniButtonsOverlay>
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
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          ...List.generate(widget.buttons.length, (index) {
            // Fan layout around the knob. Center stays top; edges tilt diagonally.
            double baseAngle = math.pi / 2; // 90 degrees (top)
            if (widget.sliderValue < 0.2) baseAngle = math.pi / 3; // 60 degrees
            if (widget.sliderValue > 0.8) baseAngle = 2 * math.pi / 3; // 120

            final angle = baseAngle +
                (index - (widget.buttons.length - 1) / 2) *
                    SliderConfig.miniButtonSpread;
            const distance = SliderConfig.miniButtonDistance;
            const extraUp = 6.0;

            final offsetX = math.cos(angle) * distance;
            final offsetY = -math.sin(angle) * distance - extraUp;

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
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onButtonTap(index),
                      child: SizedBox(
                        width: 70,
                        height: 80,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: SliderConfig.miniButtonSize,
                              height: SliderConfig.miniButtonSize,
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
