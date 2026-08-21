import 'package:cunehat/features/main_feature/utils/slider_peek_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('başlangıçta tüm durumlar tanıtım bekler', () async {
    final store = SliderPeekStore(await SharedPreferences.getInstance());
    expect(store.pending(), SliderState.values.toSet());
  });

  test('bayrak durum BAŞINA tutulur', () async {
    final store = SliderPeekStore(await SharedPreferences.getInstance());
    await store.markSeen(SliderState.transactions);

    // İşlemler'i kullanan ama Borç'a hiç girmeyen kullanıcı, Borç'a ilk
    // girdiğinde tanıtımı orada da görmeli.
    expect(store.pending(), {SliderState.savedMoney, SliderState.debt});
  });

  test('bayrak kalıcıdır', () async {
    final prefs = await SharedPreferences.getInstance();
    await SliderPeekStore(prefs).markSeen(SliderState.debt);

    final reopened = SliderPeekStore(await SharedPreferences.getInstance());
    expect(reopened.pending(), isNot(contains(SliderState.debt)));
  });
}
