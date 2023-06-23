// for now, we not using this widget in the application
import 'package:flutter/material.dart';

/// Show total income and expense yearly, monthly, daily
class Dashboard extends StatelessWidget {
  final Map<String, double> incomeMap;
  final Map<String, double> expenseMap;
  const Dashboard(
      {super.key, required this.incomeMap, required this.expenseMap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        color: Colors.blueGrey,
        elevation: 100,
        shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(100))),
        shadowColor: Colors.grey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            DashboardShowWidget(
              header: "DETAYLAR",
              expenseTotal: 0.5,
              incomeTotal: 25.5,
              remaining: 56,
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardShowWidget extends StatefulWidget {
  final String header;
  final double expenseTotal;
  final double incomeTotal;
  final double remaining;

  const DashboardShowWidget({
    super.key,
    required this.header,
    required this.expenseTotal,
    required this.incomeTotal,
    required this.remaining,
  });

  @override
  State<DashboardShowWidget> createState() => _DashboardShowWidgetState();
}

class _DashboardShowWidgetState extends State<DashboardShowWidget> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.blueGrey.shade900,
        elevation: 25,
        shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(100))),
        shadowColor: Colors.grey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              widget.header,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "GİDER : - ${widget.expenseTotal}",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  "GELİR : + ${widget.incomeTotal}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            Text(
              "KALAN = ${widget.remaining}",
              style: const TextStyle(
                color: Colors.tealAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
