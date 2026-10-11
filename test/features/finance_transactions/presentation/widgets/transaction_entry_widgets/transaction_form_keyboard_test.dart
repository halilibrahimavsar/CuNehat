import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../../support/wallet_category_stub.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

/// Klavye açıkken formun birincil eylemi.
///
/// ÖLÇÜM (11 Eki 2026, 360×800, klavye 300dp): Kaydet düğmesi kaydırılan
/// içeriğin sonundaydı; tutar alanı açılışta odaklandığı için klavye hep
/// açıktı ve düğme görünür alanın (500dp) altında kalıyordu — her kayıtta
/// ya klavyeyi kapatmak ya da kaydırmak gerekiyordu.
void main() {
  late _MockCategoryRepository categories;

  const screen = Size(360, 800);
  const keyboard = 300.0;

  setUpAll(() {
    getIt.allowReassignment = true;
    ShowcaseView.register();
  });

  setUp(() {
    categories = _MockCategoryRepository();
    getIt.registerSingleton<CategoryRepository>(categories);
    registerUncuratedWalletCategories(categories);
    when(() => categories.getCategories(true)).thenAnswer(
      (_) async => [
        for (var i = 0; i < 8; i++)
          CategoryEntity(
            id: 'c$i',
            name: 'Kategori $i',
            iconName: 'fastfood',
            isExpense: true,
          ),
      ],
    );
  });

  tearDown(getIt.reset);

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        // Alt sayfanın gördüğü ortam: `viewInsets` MediaQuery'de DURUR ve
        // form onu kendi dolgusuyla karşılar (bkz. `showModalBottomSheet`,
        // `isScrollControlled`).
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: TransactionFormSheet(
              isExpense: true,
              walletId: 'wallet_123',
              userId: 'user_123',
              onSave: (_, __) {},
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('klavye açıkken Kaydet görünür alanda ve dokunulabilir',
      (tester) async {
    await pumpForm(tester);

    final save = tester.getRect(find.text('Kaydet'));
    final visibleBottom = screen.height - keyboard;
    debugPrint('Kaydet: top=${save.top} bottom=${save.bottom} '
        '(görünür alan 0..$visibleBottom)');

    expect(save.bottom, lessThanOrEqualTo(visibleBottom),
        reason: 'Kaydet klavyenin altında kalmamalı');
    expect(find.text('Kaydet').hitTestable(), findsOneWidget);
  });

  // Sabit Kaydet satırı ilk denemede kategori şeridini yarıdan kesiyordu
  // (cihazda görüldü): zorunlu alan, isteğe bağlı notun altındaydı.
  testWidgets('klavye açıkken kategori şeridi Kaydet satırının ÜSTÜNDE',
      (tester) async {
    await pumpForm(tester);

    final tile = tester.getRect(find.text('Kategori 0'));
    final save = tester.getRect(find.text('Kaydet'));
    debugPrint(
        'kategori etiketi: bottom=${tile.bottom}; Kaydet: top=${save.top}');

    expect(find.text('Kategori 0').hitTestable(), findsOneWidget);
    expect(tile.bottom, lessThan(save.top - 16),
        reason: 'karo etiketi düğme satırının arkasında kalmamalı');
  });
}
