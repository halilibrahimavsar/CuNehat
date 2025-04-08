import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PieChartSample extends StatelessWidget {
  final Map<String, double> data;
  const PieChartSample({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber,
      child: PieChart(
        swapAnimationDuration: const Duration(seconds: 4),
        PieChartData(
          sections: getSections(data),
          startDegreeOffset: .1,
          centerSpaceRadius: 20,
          sectionsSpace: 0,
        ),
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

List<PieChartSectionData> getSections(data) {
  List<PieChartSectionData> sections = [];

  data.forEach((key, value) {
    sections.add(PieChartSectionData(
      title: key,
      value: value,
      color: getRandomColor(),
    ));
  });

  return sections;
}
