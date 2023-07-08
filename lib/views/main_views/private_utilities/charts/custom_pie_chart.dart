import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartSample extends StatelessWidget {
  final Map<String, double> data = {"a": 1.5, "b": 5, "c": 8};
  PieChartSample({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<PieChartSectionData> sections = [];

    data.forEach((key, value) {
      sections.add(PieChartSectionData(
          title: key, value: value, color: getRandomColor()));
    });

    return PieChart(
      swapAnimationCurve: Curves.decelerate,
      swapAnimationDuration: const Duration(seconds: 2),
      PieChartData(
        sections: sections,
        borderData: FlBorderData(
          show: false,
        ),
        pieTouchData: PieTouchData(
          touchCallback: (p0, p1) {},
        ),
        centerSpaceRadius: 40,
        sectionsSpace: 0,
      ),
    );
  }
}

Color getRandomColor() {
  Random random = Random();
  int r = random.nextInt(256);
  int g = random.nextInt(256);
  int b = random.nextInt(256);
  return Color.fromRGBO(r, g, b, 1.0);
}
