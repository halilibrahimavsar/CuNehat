import 'package:cunehat/core/utilities/date_range_helper.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/finance_mode.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_view_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransactionFilterCubit extends Cubit<CombinedFilter> {
  TransactionFilterCubit() : super(_createDefaultFilter());

  static CombinedFilter _createDefaultFilter() {
    final monthRange = DateRangeHelper.getMonthRange(DateTime.now());
    return CombinedFilter(
      viewFilter: ViewFilter(
        financeMode: FinanceMode.compare,
        viewType: TransactionViewType.timeline,
        startDate: monthRange.start,
        endDate: monthRange.end,
      ),
      dataFilter: const DataFilter(),
    );
  }

  void updateFilter(CombinedFilter newFilter) {
    emit(newFilter);
  }

  void resetFilters() {
    emit(_createDefaultFilter());
  }
}
