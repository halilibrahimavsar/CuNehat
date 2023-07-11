import 'package:cunehat/services/firestore/firestore_service.dart';
import 'package:cunehat/views/main_views/private_utilities/filtering/filter_constants.dart';
import 'package:intl/intl.dart';

class UnableToFindRightValueForArgument implements Exception {}

/// Use this function for filter [Expense] or [Income] data by their dates.
/// [filter] arg can accept only "yearly", "monthly" and "daily"
Map<String, double> filterByDateFrVisData({
  required Iterable<ModelProvider>? allData,
  FilterDataByDate filter = FilterDataByDate.monthly,
}) {
  Map<String, double> filteredData = {};
  for (var data in allData!) {
    final DateTime date = data.date.toDate();
    String formattedDate = '${date.year}';

    // in here the key is data for obtain daily data or mothly data or maybe yearly data
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

Map<String, double> filterTagValues({required Iterable allData}) {
  Map<String, double> filteredData = {};
  for (var data in allData) {
    if (filteredData.containsKey(data.tag)) {
      filteredData.update(data.tag, (value) => data.amount + value);
    } else {
      filteredData[data.tag] = data.amount;
    }
  }
  print(filteredData);

  return filteredData;
}
