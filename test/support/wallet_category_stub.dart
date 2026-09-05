import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:mocktail/mocktail.dart';

class MockWalletCategoryService extends Mock implements WalletCategoryService {}

/// Kapsam servisini **kürasyonsuz cüzdan** gibi davranacak şekilde `getIt`'e
/// kaydeder: `categoriesFor` küresel listeyi aynen döner, `include` no-op.
///
/// Cüzdan görünürlüğünü ölçmeyen testler için — o davranışın kendi testleri
/// var (`wallet_category_scope_test.dart`, `wallet_category_service_test.dart`).
/// Böylece kategori yüzeylerinin testleri, konusu olmayan bir bağımlılığı
/// yeniden kurmak zorunda kalmıyor.
MockWalletCategoryService registerUncuratedWalletCategories(
  CategoryRepository repository,
) {
  final service = MockWalletCategoryService();
  getIt.registerSingleton<WalletCategoryService>(service);

  when(() => service.categoriesFor(
            walletId: any(named: 'walletId'),
            isExpense: any(named: 'isExpense'),
            alwaysInclude: any(named: 'alwaysInclude'),
          ))
      .thenAnswer((invocation) => repository
          .getCategories(invocation.namedArguments[#isExpense] as bool));

  when(() => service.visibleIds(any())).thenAnswer((_) async => null);

  when(() => service.include(
        walletId: any(named: 'walletId'),
        categoryIds: any(named: 'categoryIds'),
      )).thenAnswer((_) async => 0);

  when(() => service.setVisibility(
        walletId: any(named: 'walletId'),
        categoryId: any(named: 'categoryId'),
        visible: any(named: 'visible'),
      )).thenAnswer((_) async {});

  return service;
}
