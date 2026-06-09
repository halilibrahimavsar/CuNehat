import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransactionFilterCubit extends Cubit<CombinedFilter> {
  TransactionFilterCubit() : super(_createDefaultFilter());

  static CombinedFilter _createDefaultFilter() {
    final monthRange = _getCurrentMonthRange();
    return CombinedFilter(
      viewFilter: ViewFilter(
        financeMode: FinanceMode.compare,
        startDate: monthRange.start,
        endDate: monthRange.end,
      ),
      dataFilter: const DataFilter(),
    );
  }

  /// Returns a DateTimeRange for the current month
  static DateTimeRange _getCurrentMonthRange() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return DateTimeRange(start: firstDayOfMonth, end: lastDayOfMonth);
  }

  void updateFilter(CombinedFilter newFilter) {
    emit(newFilter);
  }
}
