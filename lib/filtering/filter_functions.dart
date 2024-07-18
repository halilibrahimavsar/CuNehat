import 'package:cunehat/firestore/firestore_service.dart';
import 'package:cunehat/filtering/filter_constants.dart';
import 'package:cunehat/filtering/filter_exceptions.dart';
import 'package:intl/intl.dart';

/// Use this function for summon monthly, yearly or daily [Expense] or [Income] data.
/// [filter] arg can accept only "yearly", "monthly" and "daily"
Map<String, double> sumDailyMonthlyYearly({
  required Iterable<ModelProvider>? allData,
  FilterDataByDate filter = FilterDataByDate.monthly,
}) {
  Map<String, double> filteredData = {};
  for (var data in allData!) {
    final DateTime date = data.date.toDate();
    String formattedDate = '${date.year}';

    // Summon all data by giving date.
    if (filter == FilterDataByDate.yearly) {
      formattedDate = DateFormat('yyyy', 'tr').format(date);
    } else if (filter == FilterDataByDate.monthly) {
      formattedDate = DateFormat('MM-yyyy', 'tr').format(date);
    } else if (filter == FilterDataByDate.daily) {
      formattedDate = DateFormat('dd-MM-yyyy', 'tr').format(date);
    } else {
      throw UnableToFindRightValueForArgument();
    }

    if (filteredData.containsKey(formattedDate)) {
      filteredData.update(formattedDate, (value) => data.amount + value);
    } else {
      filteredData[formattedDate] = data.amount;
    }
  }

  return filteredData;
}

Map<String, double> sumTagValues({required Iterable allData}) {
  Map<String, double> filteredData = {};
  for (var data in allData) {
    if (filteredData.containsKey(data.tag)) {
      filteredData.update(data.tag, (value) => data.amount + value);
    } else {
      filteredData[data.tag] = data.amount;
    }
  }

  return filteredData;
}
