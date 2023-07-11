import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/private_utilities/charts/custom_pie_chart.dart';
import 'package:cunehat/views/main_views/private_utilities/filtering/filter_constants.dart';
import 'package:cunehat/views/main_views/private_utilities/filtering/filter_db_data.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

class Dashboard extends StatelessWidget {
  final AsyncSnapshot<Iterable<Income>> incomeSnapshot;
  final AsyncSnapshot<Iterable<Expense>> expenseSnapshot;
  final Timestamp startDate;
  final Timestamp endDate;
  final FilterDataByDate filterChronical;

  const Dashboard({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.incomeSnapshot,
    required this.expenseSnapshot,
    required this.filterChronical,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, double> incomeMap = filterByDateFrVisData(
      allData: incomeSnapshot.data,
      filter: filterChronical,
    );

    final Map<String, double> expenseMap = filterByDateFrVisData(
      allData: expenseSnapshot.data,
      filter: filterChronical,
    );

    final expenseTagsValues =
        filterTagValues(allData: expenseSnapshot.data as Iterable<Expense>);
    final incomeTagsValues =
        filterTagValues(allData: incomeSnapshot.data as Iterable<Income>);

    return Container(
      color: Colors.cyan.shade700,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text("GİDER TAG VERİLERİ"),
                  const SizedBox(height: 80),
                  SizedBox.shrink(
                      child: PieChartSample(
                    data: expenseTagsValues,
                  )),
                ],
              ),
              Column(
                children: [
                  const Text("GELİR TAG VERİLERİ"),
                  const SizedBox(height: 80),
                  SizedBox.shrink(
                      child: PieChartSample(
                    data: incomeTagsValues,
                  )),
                ],
              ),
            ],
          ),
        ],
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
