import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class InvestmentChart extends StatelessWidget {
  final List<InvestmentEntity> investments;

  const InvestmentChart({
    super.key,
    required this.investments,
  });

  @override
  Widget build(BuildContext context) {
    if (investments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Grafik için yatırım bulunmuyor'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dağılım',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _buildSections(),
                centerSpaceRadius: 40,
                sectionsSpace: 4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final totalValue = investments.fold(
      0.0,
      (sum, investment) => sum + investment.currentValue,
    );

    return investments.map((investment) {
      final percentage =
          totalValue > 0 ? (investment.currentValue / totalValue) * 100 : 0;

      return PieChartSectionData(
        color: investment.color,
        value: investment.currentValue,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend() {
    return investments.map((investment) {
      final percentage =
          investments.fold(0.0, (sum, i) => sum + i.currentValue) > 0
              ? (investment.currentValue /
                      investments.fold(0.0, (sum, i) => sum + i.currentValue) *
                      100)
                  .toStringAsFixed(1)
              : '0.0';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: investment.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                investment.name,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Text(
              '%$percentage',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
