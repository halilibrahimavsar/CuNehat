import 'dart:io';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/error/error_log.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/system_activity_guard.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_controller.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_receipt_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../support/undecodable_image.dart';
import '../../../../../support/wallet_category_stub.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

/// Testte eklenti kaydı çalışmadığı için `ImagePicker` bu kanala düşer.
const _imagePickerChannel = MethodChannel('plugins.flutter.io/image_picker');

void main() {
  late TransactionFormController controller;

  setUpAll(() => getIt.allowReassignment = true);

  setUp(() {
    ErrorLog.instance.resetForTest();
    getIt.registerSingleton<SystemActivityGuard>(SystemActivityGuard());
    registerUncuratedWalletCategories(_MockCategoryRepository());
    controller = TransactionFormController(isExpense: true, walletId: 'w1');
  });

  tearDown(() async {
    controller.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_imagePickerChannel, null);
    ErrorLog.instance.resetForTest();
    await getIt.reset();
  });

  void stubPickerError(PlatformException error) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_imagePickerChannel, (call) async {
      if (call.method == 'pickImage') throw error;
      return null;
    });
  }

  Future<void> pumpRow(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: appMessengerKey,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en')],
          locale: const Locale('tr'),
          home: Scaffold(
            body: ReceiptRow(controller: controller, accent: Colors.teal),
          ),
        ),
      );

  Future<void> pickFromCamera(WidgetTester tester) async {
    await pumpRow(tester);
    await tester.tap(find.text('Fiş/fotoğraf ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kamera'));
    await tester.pumpAndSettle();
  }

  // Kamera izni reddedilince eklenti PlatformException fırlatır. Eskiden
  // yakalanmıyordu ve dokunuş sessizce hiçbir şey yapmıyordu.
  testWidgets('görsel seçici hata verirse kullanıcıya sebep söylenir',
      (tester) async {
    stubPickerError(PlatformException(code: 'camera_access_denied'));

    await pickFromCamera(tester);

    expect(
      find.text(
          'Görsel alınamadı. Kamera ve fotoğraf izinlerini kontrol edin.'),
      findsOneWidget,
    );
    expect(controller.pickedReceipt.value, isNull);
    expect(
      ErrorLog.instance.entries.single.source,
      'Fiş eki · görsel seçici',
    );
  });

  testWidgets('seçici zaten açıksa (çift dokunuş) hata gösterilmez',
      (tester) async {
    stubPickerError(PlatformException(code: 'already_active'));

    await pickFromCamera(tester);

    expect(find.textContaining('Görsel alınamadı'), findsNothing);
    expect(ErrorLog.instance.entries, isEmpty);
  });

  // Seçilen dosya da çözülemeyebilir (bozuk ya da motorun açamadığı bir
  // biçim). İşleyici yokken hata "yakalanmamış" diye raporlanıyordu (test bu
  // durumda kendiliğinden düşer) ve küçük resim boş kalıyordu.
  testWidgets('seçilen görsel çözülemezse kırık görsel ikonu gösterilir',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('fis_satiri');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/bozuk.jpg');
    await writeUndecodableImage(tester, file);
    controller.pickedReceipt.value = XFile(file.path);

    await pumpRow(tester);
    await tester.pump();

    expect(find.byIcon(Icons.broken_image_rounded), findsOneWidget);
  });
}
