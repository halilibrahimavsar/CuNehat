import 'package:bloc/bloc.dart';
import 'package:cunehat/core/error/app_bloc_observer.dart';
import 'package:cunehat/core/error/error_log.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProbeCubit extends Cubit<int> {
  _ProbeCubit() : super(0);

  void fail() => addError(StateError('handler patladı'), StackTrace.current);
}

void main() {
  late BlocObserver originalObserver;

  setUp(() {
    originalObserver = Bloc.observer;
    ErrorLog.instance.resetForTest();
  });

  tearDown(() {
    Bloc.observer = originalObserver;
    ErrorLog.instance.resetForTest();
  });

  test('bloc hatası doğduğu bloc tipiyle günlüğe yazılır', () async {
    // Gözlemci bloc KURULURKEN yakalanır; önce atanmalı.
    Bloc.observer = const AppBlocObserver();
    final cubit = _ProbeCubit();

    cubit.fail();

    final entry = ErrorLog.instance.entries.single;
    expect(entry.source, 'Bloc _ProbeCubit');
    expect(entry.message, contains('handler patladı'));
    await cubit.close();
  });
}
