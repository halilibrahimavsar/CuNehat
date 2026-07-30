import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/messaging/deletion_undo_message.dart';
import 'package:cunehat/core/services/deletion_undo_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDeletionUndoService extends Mock implements DeletionUndoService {}

Widget _app() => MaterialApp(
      scaffoldMessengerKey: appMessengerKey,
      theme: ThemeData.light().copyWith(
        extensions: const <ThemeExtension<dynamic>>[AppSurface.light],
      ),
      home: const Scaffold(body: SizedBox.expand()),
    );

void main() {
  late MockDeletionUndoService service;

  final undo = TransactionDeletionUndo(
    transaction: TransactionEntity(
      id: 'tx_1',
      userId: 'user_1',
      walletId: 'wallet_1',
      title: 'Market',
      tag: 'Food',
      amount: 150,
      date: DateTime(2026, 3, 4),
      type: TransactionTypeModel.expense,
    ),
    userId: 'user_1',
    walletId: 'wallet_1',
  );

  setUpAll(() {
    // DeletionUndo sealed olduğu için Fake türetilemez; fallback olarak
    // gerçek bir alt tür kullanılır.
    registerFallbackValue(TransactionDeletionUndo(
      transaction: TransactionEntity(
        id: 'fallback',
        userId: 'u',
        walletId: 'w',
        title: 't',
        tag: 'g',
        amount: 0,
        date: DateTime(2026, 1, 1),
        type: TransactionTypeModel.expense,
      ),
      userId: 'u',
      walletId: 'w',
    ));
    getIt.allowReassignment = true;
  });

  setUp(() {
    service = MockDeletionUndoService();
    getIt.registerSingleton<DeletionUndoService>(service);
    when(() => service.commit(any())).thenAnswer((_) async {});
    when(() => service.restore(any())).thenAnswer((_) async => true);
  });

  tearDown(() => getIt.reset());

  void show({DeletionUndo? payload}) => showDeletionMessageWithTexts(
        message: 'Market silindi',
        undo: payload,
        undoLabel: 'Geri al',
        undoneMessage: 'Silme geri alındı',
        undoFailedMessage: 'Geri alma başarısız',
      );

  testWidgets('"Geri al" dokunuşu restore çağırır ve commit ETMEZ',
      (tester) async {
    await tester.pumpWidget(_app());

    show(payload: undo);
    await tester.pumpAndSettle();
    expect(find.text('Market silindi'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();

    verify(() => service.restore(undo)).called(1);
    // Kesinleştirme yapılırsa fiş dosyası silinir; geri alındığında olmamalı.
    verifyNever(() => service.commit(any()));
    expect(find.text('Silme geri alındı'), findsOneWidget);
  });

  testWidgets('restore başarısızsa hata mesajı gösterilir', (tester) async {
    when(() => service.restore(any())).thenAnswer((_) async => false);
    await tester.pumpWidget(_app());

    show(payload: undo);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();

    expect(find.text('Geri alma başarısız'), findsOneWidget);
  });

  testWidgets('pencere kendiliğinden kapanınca silme kesinleşir',
      (tester) async {
    await tester.pumpWidget(_app());

    show(payload: undo);
    await tester.pumpAndSettle();
    verifyNever(() => service.commit(any()));

    // Süre dolar → snackbar kapanır → kalıcı yan etkiler uygulanır.
    await tester.pump(AppMessenger.actionDuration);
    await tester.pumpAndSettle();

    verify(() => service.commit(undo)).called(1);
    verifyNever(() => service.restore(any()));
  });

  testWidgets('yeni mesaj devraldığında da silme kesinleşir', (tester) async {
    await tester.pumpWidget(_app());

    show(payload: undo);
    await tester.pumpAndSettle();

    // Başka bir mesaj snackbar'ı devralır: geri alma penceresi kapandı.
    AppMessenger.info('başka bir şey');
    await tester.pumpAndSettle();

    verify(() => service.commit(undo)).called(1);
  });

  testWidgets('undo null ise düz mesaj gösterilir, eylem yok', (tester) async {
    await tester.pumpWidget(_app());

    show();
    await tester.pumpAndSettle();

    expect(find.text('Market silindi'), findsOneWidget);
    expect(find.text('Geri al'), findsNothing);
    verifyNever(() => service.commit(any()));
    verifyNever(() => service.restore(any()));
  });

  testWidgets('messenger bağlı değilse silme hemen kesinleşir', (tester) async {
    // Hiç MaterialApp yok → geri alma penceresi de yok. Kesinleştirme
    // atlanırsa fiş dosyası sonsuza dek öksüz kalırdı.
    show(payload: undo);
    await tester.pump();

    verify(() => service.commit(undo)).called(1);
  });
}
