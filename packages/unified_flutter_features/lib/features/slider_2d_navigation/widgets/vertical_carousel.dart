import 'package:flutter/material.dart';
import '../constants/slider_config.dart';

class VerticalCarousel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final List<Widget> children;
  final ValueChanged<int>? onItemTapped;
  final ScrollPhysics? physics;

  const VerticalCarousel({
    super.key,
    required this.controller,
    required this.children,
    this.onItemTapped,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SliderConfig.carouselTotalHeight,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: SliderConfig.carouselItemHeight,
        perspective: 0.009,
        diameterRatio: 1.5,
        physics: physics ?? const FixedExtentScrollPhysics(),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: children.length,
          builder: (context, index) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                controller.animateToItem(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                onItemTapped?.call(index);
              },
              child: Center(
                child: SizedBox(
                  height: SliderConfig.carouselItemHeight,
                  width: double.infinity,
                  child: children[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
