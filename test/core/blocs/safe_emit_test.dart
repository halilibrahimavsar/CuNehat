import 'package:bloc/bloc.dart';
import 'package:cunehat/core/blocs/safe_emit.dart';
import 'package:flutter_test/flutter_test.dart';

class _SafeCubit extends Cubit<int> with SafeEmitMixin<int> {
  _SafeCubit() : super(0);

  void set(int value) => emit(value);
}

class _PlainCubit extends Cubit<int> {
  _PlainCubit() : super(0);

  void set(int value) => emit(value);
}

void main() {
  test('açık cubit durum yaymaya devam eder', () async {
    final cubit = _SafeCubit();
    final states = <int>[];
    final subscription = cubit.stream.listen(states.add);

    cubit.set(1);
    await Future<void>.delayed(Duration.zero);

    expect(states, [1]);
    await subscription.cancel();
    await cubit.close();
  });

  test('kapanmış cubit emit çağrısında fırlatmaz, durum değişmez', () async {
    final cubit = _SafeCubit();
    await cubit.close();

    expect(() => cubit.set(1), returnsNormally);
    expect(cubit.state, 0);
  });

  test('mixin olmadan kapanmış cubit emit çağrısında StateError fırlatır',
      () async {
    // Mixin'in dayandığı bloc davranışı: değişirse bu test haber verir.
    final cubit = _PlainCubit();
    await cubit.close();

    expect(() => cubit.set(1), throwsStateError);
  });
}
