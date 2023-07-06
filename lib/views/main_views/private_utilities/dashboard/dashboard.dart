import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class Dashboard extends StatelessWidget {
  final Map<String, double> incomeMap;
  final Map<String, double> expenseMap;
  final Timestamp startDate;
  final Timestamp endDate;

  const Dashboard({
    super.key,
    required this.incomeMap,
    required this.expenseMap,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.cyan.shade800,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(startDate, endDate),
              const SizedBox(height: 20),
              _buildStatRow('Gelir', sumMap(incomeMap), Colors.green.shade300),
              const SizedBox(height: 10),
              _buildStatRow('Gider', sumMap(expenseMap), Colors.red.shade300),
              const SizedBox(height: 10),
              const Divider(color: Colors.white),
              const SizedBox(height: 10),
              _buildStatRow(
                'Kalan',
                sumMap(incomeMap) - sumMap(expenseMap),
                Colors.tealAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double sumMap(Map<String, double> dictionary) {
    double total = 0.0;
    for (double i in dictionary.values) {
      total += i;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  Widget _buildStatRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          amount.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    final Timestamp startDate,
    final Timestamp endDate,
  ) {
    // find the range of dates (Start point and End point)
    var start =
        '${startDate.toDate().day}-${startDate.toDate().month}-${startDate.toDate().year}';
    var end =
        '${endDate.toDate().day}-${endDate.toDate().month}-${endDate.toDate().year}';

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            start,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          NeumorphicIcon(
            Icons.arrow_forward_ios,
            size: 26,
          ),
          Text(
            end,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
