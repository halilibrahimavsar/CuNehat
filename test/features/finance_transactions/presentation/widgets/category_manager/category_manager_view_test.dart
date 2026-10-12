import 'dart:async';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/delete_category_usecase.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_manager_view.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/real_font.dart';
import '../../../../../support/wallet_category_stub.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class MockDeleteCategoryUseCase extends Mock implements DeleteCategoryUseCase {}

class MockRecurringRepository extends Mock
    implements RecurringTransactionRepository {}

/// Kürasyon yüzeyinin DAVRANIŞ testleri: anahtarın ne yazdığı, ne zaman
/// kilitlendiği, hata yolunda ne dediği. Ağaç çizimi ve silme akışı kardeş
/// dosyada (`category_manager_sheet_test.dart`).
void main() {
  late MockCategoryRepository repository;
  late MockWalletCategoryService walletCategories;

  CategoryEntity cat(String id, String name, {String? parentId}) =>
      CategoryEntity(
        id: id,
        name: name,
        iconName: 'category',
        isExpense: true,
        parentId: parentId,
      );

  // Fatura(Elektrik) · Market
  final tree = [
    cat('f', 'Fatura'),
    cat('f-e', 'Elektrik', parentId: 'f'),
    cat('m', 'Market'),
  ];

  setUpAll(() async {
    getIt.allowReassignment = true;
    await loadRealRoboto();
  });

  setUp(() {
    repository = MockCategoryRepository();
    getIt.registerSingleton<CategoryRepository>(repository);
    walletCategories = registerUncuratedWalletCategories(repository);
    getIt.registerSingleton<TransactionsRepository>(
        MockTransactionsRepository());
    getIt.registerSingleton<DeleteCategoryUseCase>(MockDeleteCategoryUseCase());
    getIt.registerSingleton<RecurringTransactionRepository>(
        MockRecurringRepository());

    when(() => repository.getCategories(any())).thenAnswer((_) async => tree);
  });

  tearDown(() => getIt.reset());

  Widget host(Widget child) => MaterialApp(
        // `AppMessenger` global anahtar üzerinden yazıyor; bağlanmazsa hata
        // snackbar'ı hiçbir ağaca düşmez ve test onu göremez.
        scaffoldMessengerKey: appMessengerKey,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr'), Locale('en')],
        locale: const Locale('tr'),
        home: Scaffold(body: child),
      );

  Future<void> pump(WidgetTester tester, {String walletId = 'w1'}) async {
    await tester.pumpWidget(
      host(CategoryManagerView(walletId: walletId, isExpense: true)),
    );
    await tester.pumpAndSettle();
  }

  group('anahtar', () {
    testWidgets('yazım SÜRERKEN kilitli: ikinci dokunuş ikinci yazım açmaz',
        (tester) async {
      // Yeniden giriş koruması: iki eşzamanlı oku-değiştir-yaz aynı cüzdana
      // gider ve biri diğerini bayat kümeyle ezer.
      final gate = Completer<void>();
      when(() => walletCategories.setVisibility(
            walletId: any(named: 'walletId'),
            categoryId: any(named: 'categoryId'),
            visible: any(named: 'visible'),
          )).thenAnswer((_) => gate.future);

      await pump(tester);

      await tester.tap(find.byType(Switch).first);
      await tester.pump();
      await tester.tap(find.byType(Switch).first, warnIfMissed: false);
      await tester.pump();

      verify(() => walletCategories.setVisibility(
            walletId: 'w1',
            categoryId: 'f',
            visible: false,
          )).called(1);

      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('TAM yeniden yükleme yok: kategori listesi bir kez okunur',
        (tester) async {
      // `load()` çağrılsaydı `_isLoading` true'ya döner, liste her dokunuşta
      // spinner'a dönerdi — üstelik kategoriler hiç değişmemişken.
      await pump(tester);
      clearInteractions(repository);
      clearInteractions(walletCategories);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      verifyNever(() => repository.getCategories(any()));
      verify(() => walletCategories.visibleIds('w1')).called(1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('başarıda BİLDİRİM YOK (48 kalem = 48 snackbar değil)',
        (tester) async {
      await pump(tester);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('yazım BAŞARISIZSA hata gösterilir ve anahtar geri döner',
        (tester) async {
      // Eskiden servis `Left`'i yutuyordu: ekranda anahtar geri dönüyor ama
      // snackbar "gizlendi" diyordu.
      when(() => walletCategories.setVisibility(
            walletId: any(named: 'walletId'),
            categoryId: any(named: 'categoryId'),
            visible: any(named: 'visible'),
          )).thenThrow(CacheException('disk dolu'));

      await pump(tester);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      final first = tester.widgetList<Switch>(find.byType(Switch)).first;
      expect(first.value, isTrue, reason: 'yazılamadı, açık kalmalı');
      expect(first.onChanged, isNotNull, reason: 'kilit çözülmeli');
    });
  });

  group('kapsam', () {
    testWidgets('walletId DEĞİŞİNCE liste tazelenir', (tester) async {
      // State aynı kaldığı için `didUpdateWidget` olmadan eski cüzdanın
      // kümesi ekranda kalırdı.
      await pump(tester);
      clearInteractions(walletCategories);

      await tester.pumpWidget(
        host(const CategoryManagerView(walletId: 'w2', isExpense: true)),
      );
      await tester.pumpAndSettle();

      verify(() => walletCategories.visibleIds('w2')).called(1);
    });

    testWidgets('cüzdan adı bilinmiyorsa "Cüzdan cüzdanında" demez',
        (tester) async {
      // WalletBloc ağaçta yok → `walletById` null. Ada düşen eski metin
      // "Cüzdan cüzdanında hangilerinin görüneceğini belirler" üretiyordu.
      await pump(tester);

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .toList();
      expect(texts.any((t) => t.contains('Cüzdan cüzdanında')), isFalse);
      expect(
        texts.any((t) => t.contains('yalnız bu cüzdanda')),
        isTrue,
      );
    });

    testWidgets('küme BOŞKEN uyarı ve hazır set kısayolu çıkar',
        (tester) async {
      // Başlangıç paketini atlayan yeni cüzdan: seçici boş görünecek,
      // sebebi burada söylenmeli.
      when(() => walletCategories.visibleIds(any()))
          .thenAnswer((_) async => const []);

      await pump(tester);

      expect(find.textContaining('henüz kategori seçilmedi'), findsOneWidget);
      expect(find.text('Öneri setinden başla'), findsOneWidget);
    });

    testWidgets('kürasyonsuz cüzdanda BOŞ uyarısı çıkmaz', (tester) async {
      // `null` = hepsi görünür; "hiçbiri seçilmedi" demek yalan olurdu.
      await pump(tester);

      expect(find.textContaining('henüz kategori seçilmedi'), findsNothing);
    });
  });

  testWidgets('360dp: uzun kategori adları + anahtar taşırmaz', (tester) async {
    when(() => repository.getCategories(any())).thenAnswer((_) async => [
          cat('r', 'Ulaşım ve Akaryakıt Giderleri'),
          cat('c', 'Otoyol ve Köprü Geçiş Ücretleri', parentId: 'r'),
        ]);

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Ulaşım ve Akaryakıt Giderleri'), findsOneWidget);
  });

  group('sıralama kipi', () {
    // Fatura(Doğalgaz, Elektrik) · Kira · Market
    final wide = [
      cat('f', 'Fatura'),
      cat('f-d', 'Doğalgaz', parentId: 'f'),
      cat('f-e', 'Elektrik', parentId: 'f'),
      cat('k', 'Kira'),
      cat('m', 'Market'),
    ];

    setUp(() {
      when(() => repository.getCategories(any())).thenAnswer((_) async => wide);
      when(() => repository.reorder(any())).thenAnswer((_) async {});
    });

    Future<void> dragHandle(
        WidgetTester tester, String id, Offset offset) async {
      final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(ValueKey('reorder-handle-$id'))));
      await tester.pump();
      // Birkaç adımda sürükle: tek sıçrama yerleşimi güncellemeden bırakır.
      for (var i = 0; i < 5; i++) {
        await gesture.moveBy(offset / 5);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('"Sırala" kipi açar: anahtarlar ve kaydırarak silme çekilir',
        (tester) async {
      await pump(tester);
      expect(find.byType(Switch), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('category-reorder-start')));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsNothing);
      expect(find.byType(Dismissible), findsNothing);
      expect(find.byKey(const ValueKey('reorder-handle-f')), findsOneWidget);
      // Alt kategoriler kök açılana kadar gizli.
      expect(find.text('Elektrik'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('category-reorder-done')));
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('kök sürüklenince yeni sıra depoya yazılır ve bildirilir',
        (tester) async {
      var changed = 0;
      await tester.pumpWidget(host(CategoryManagerView(
        walletId: 'w1',
        isExpense: true,
        onChanged: () => changed++,
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category-reorder-start')));
      await tester.pumpAndSettle();

      // Market en alttan en üste.
      final top =
          tester.getCenter(find.byKey(const ValueKey('reorder-handle-f')));
      final from =
          tester.getCenter(find.byKey(const ValueKey('reorder-handle-m')));
      await dragHandle(tester, 'm', Offset(0, top.dy - from.dy - 20));

      final ids = verify(() => repository.reorder(captureAny())).captured.single
          as List<String>;
      expect(ids, ['m', 'f', 'k']);
      expect(changed, 1);
    });

    testWidgets('alt kategoriler kendi ana kategorisinin içinde sıralanır',
        (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('category-reorder-start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reorder-expand-f')));
      await tester.pumpAndSettle();

      final first =
          tester.getCenter(find.byKey(const ValueKey('reorder-handle-f-d')));
      final second =
          tester.getCenter(find.byKey(const ValueKey('reorder-handle-f-e')));
      await dragHandle(tester, 'f-e', Offset(0, first.dy - second.dy - 20));

      final ids = verify(() => repository.reorder(captureAny())).captured.single
          as List<String>;
      expect(ids, ['f-e', 'f-d']);
    });

    testWidgets('yazım başarısızsa hata gösterilir ve liste depodan tazelenir',
        (tester) async {
      when(() => repository.reorder(any()))
          .thenThrow(CacheException('disk dolu'));
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('category-reorder-start')));
      await tester.pumpAndSettle();
      clearInteractions(repository);

      final top =
          tester.getCenter(find.byKey(const ValueKey('reorder-handle-f')));
      final from =
          tester.getCenter(find.byKey(const ValueKey('reorder-handle-m')));
      await dragHandle(tester, 'm', Offset(0, top.dy - from.dy - 20));

      expect(find.byType(SnackBar), findsOneWidget);
      // Depo eski sırayı döndü: Market yeniden en altta.
      verify(() => repository.getCategories(true)).called(1);
      expect(
          tester.getCenter(find.byKey(const ValueKey('reorder-handle-m'))).dy,
          greaterThan(tester
              .getCenter(find.byKey(const ValueKey('reorder-handle-k')))
              .dy));
    });

    testWidgets('sıralanacak bir şey yokken "Sırala" çıkmaz', (tester) async {
      when(() => repository.getCategories(any()))
          .thenAnswer((_) async => [cat('m', 'Market')]);
      await pump(tester);

      expect(
          find.byKey(const ValueKey('category-reorder-start')), findsNothing);
    });
  });
}
