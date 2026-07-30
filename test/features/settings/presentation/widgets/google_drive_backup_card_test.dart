import 'package:bloc_test/bloc_test.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/services/auto_backup_service.dart';
import 'package:cunehat/core/services/categories_changed_notifier.dart';
import 'package:cunehat/core/services/drive_backup_result.dart';
import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/settings/presentation/widgets/google_drive_backup_card.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDrive extends Mock implements GoogleDriveBackupService {}

class MockAccount extends Mock implements GoogleSignInAccount {}

class MockAppAuthBloc extends MockBloc<AppAuthEvent, AppAuthState>
    implements AppAuthBloc {}

class MockWalletBloc extends MockBloc<WalletEvent, WalletState>
    implements WalletBloc {}

DriveBackupFile _file({
  String id = 'f1',
  BackupOrigin origin = BackupOrigin.manual,
}) =>
    DriveBackupFile(
      id: id,
      name: 'cunehat_backup_20260730_120000.json',
      sizeBytes: 4096,
      modifiedTime: DateTime(2026, 7, 30, 14, 5),
      md5Checksum: 'abc',
      schemaVersion: 4,
      transactionCount: 42,
      walletCount: 2,
      origin: origin,
    );

void main() {
  late MockDrive drive;
  late MockAccount account;
  late AutoBackupService autoBackup;
  late MockAppAuthBloc authBloc;
  late MockWalletBloc walletBloc;

  setUpAll(() {
    getIt.allowReassignment = true;
    registerFallbackValue(BackupOrigin.manual);
  });

  Future<void> registerAll({Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sharedPrefs = await SharedPreferences.getInstance();
    autoBackup = AutoBackupService(drive, sharedPrefs);

    getIt.registerSingleton<GoogleDriveBackupService>(drive);
    getIt.registerSingleton<AutoBackupService>(autoBackup);
    getIt.registerSingleton<TransactionsChangedNotifier>(
        TransactionsChangedNotifier());
    getIt.registerSingleton<CategoriesChangedNotifier>(
        CategoriesChangedNotifier());
  }

  setUp(() async {
    drive = MockDrive();
    account = MockAccount();
    authBloc = MockAppAuthBloc();
    walletBloc = MockWalletBloc();

    when(() => account.email).thenReturn('kullanici@ornek.com');
    when(() => drive.currentUser).thenReturn(account);
    when(() => drive.isSignedIn).thenReturn(true);
    whenListen(authBloc, const Stream<AppAuthState>.empty(),
        initialState: const AppAuthInitial());
    whenListen(walletBloc, const Stream<WalletState>.empty(),
        initialState: const WalletInitialSt());

    await registerAll();
  });

  tearDown(() async {
    autoBackup.dispose();
    await getIt.reset();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      scaffoldMessengerKey: appMessengerKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr'), Locale('en')],
      locale: const Locale('tr'),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AppAuthBloc>.value(value: authBloc),
          BlocProvider<WalletBloc>.value(value: walletBloc),
        ],
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  void stubConnected({List<DriveBackupFile> files = const []}) {
    when(() => drive.silentSignIn())
        .thenAnswer((_) async => DriveResult.success(account));
    when(() => drive.listBackups(interactive: any(named: 'interactive')))
        .thenAnswer((_) async => DriveResult.success(files));
  }

  testWidgets('bağlı değilken bağlan düğmesi gösterilir', (tester) async {
    when(() => drive.silentSignIn()).thenAnswer(
      (_) async => const DriveResult<GoogleSignInAccount>.failure(
        DriveOperationStatus.notSignedIn,
      ),
    );

    await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
    await tester.pumpAndSettle();

    expect(find.text('Google Drive\'a Bağlan'), findsOneWidget);
    // "Bağlı değil" beklenen durum: arıza bandı çıkmamalı.
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  // B2 REGRESYON: OAuth istemcisi yanlış yapılandırıldığında kart yalnızca
  // "bağlı değil" diyebiliyordu; sebep hiçbir yerde görünmüyordu.
  testWidgets('yapılandırma hatası kalıcı bant olarak gösterilir',
      (tester) async {
    when(() => drive.silentSignIn()).thenAnswer(
      (_) async => const DriveResult<GoogleSignInAccount>.failure(
        DriveOperationStatus.configError,
      ),
    );

    await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.textContaining('OAuth istemcisi'), findsOneWidget);
  });

  // C3 REGRESYON: "son yedekleme" yerel prefs'te biçimlenmiş bir metindi;
  // uygulama yeniden kurulunca yedek Drive'da dururken "hiç yedek yok"
  // görünüyordu. Artık doğruluk kaynağı Drive metadata'sı.
  testWidgets('son yedekleme Drive modifiedTime\'ından okunur', (tester) async {
    stubConnected(files: [_file()]);

    await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
    await tester.pumpAndSettle();

    expect(find.text('kullanici@ornek.com'), findsOneWidget);
    expect(find.text('30.07.2026 14:05'), findsOneWidget);
    expect(find.textContaining('1 kopya saklanıyor'), findsOneWidget);
  });

  testWidgets('yedek yokken geri yükle devre dışı ve "hiç yedek yok" yazar',
      (tester) async {
    stubConnected();

    await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
    await tester.pumpAndSettle();

    expect(find.text('Hiç yedekleme yapılmadı'), findsOneWidget);
    final restore = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Geri Yükle'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(restore.onPressed, isNull);
  });

  // A1 REGRESYON: boş veriyle "Yedekle" Drive'daki dolu tek kopyayı eziyordu.
  // Artık ne olacağı söylenip karar kullanıcıya bırakılır.
  testWidgets('boş veri kapısı onay diyaloğu açar', (tester) async {
    stubConnected(files: [_file()]);
    when(() => drive.backup(
          origin: any(named: 'origin'),
          allowEmpty: any(named: 'allowEmpty'),
          interactive: any(named: 'interactive'),
          skipIfContentMd5Matches: any(named: 'skipIfContentMd5Matches'),
        )).thenAnswer((_) async => const DriveResult<DriveBackupFile>.failure(
          DriveOperationStatus.emptyLocalData,
        ));

    await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yedekle'));
    await tester.pumpAndSettle();

    expect(find.text('Boş yedek alınsın mı?'), findsOneWidget);
    expect(find.textContaining('boş bir yedek yazılır'), findsOneWidget);
  });

  // B1 REGRESYON: her hata "Yedek dosyası bulunamadı" oluyordu.
  testWidgets('yedekleme hatası gerçek sebebiyle gösterilir', (tester) async {
    stubConnected(files: [_file()]);
    when(() => drive.backup(
          origin: any(named: 'origin'),
          allowEmpty: any(named: 'allowEmpty'),
          interactive: any(named: 'interactive'),
          skipIfContentMd5Matches: any(named: 'skipIfContentMd5Matches'),
        )).thenAnswer((_) async => const DriveResult<DriveBackupFile>.failure(
          DriveOperationStatus.quotaExceeded,
        ));

    await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yedekle'));
    await tester.pumpAndSettle();

    expect(find.textContaining('depolama alanınız dolu'), findsOneWidget);
    expect(find.textContaining('Yedek dosyası bulunamadı'), findsNothing);
  });

  testWidgets('otomatik yedek ayarı kalıcı yazılır', (tester) async {
    stubConnected(files: [_file()]);

    await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
    await tester.pumpAndSettle();

    expect(autoBackup.frequency, AutoBackupFrequency.off);

    await tester.tap(find.text('Günlük'));
    await tester.pumpAndSettle();

    expect(autoBackup.frequency, AutoBackupFrequency.daily);
    // Sınır açıkça yazılmalı: "koruma altındasınız" izlenimi verilmemeli.
    expect(find.textContaining('Uygulamayı hiç açmazsanız'), findsOneWidget);
  });

  testWidgets('üst üste otomatik yedek hatası kalıcı uyarı bandı gösterir',
      (tester) async {
    await getIt.reset();
    await registerAll(prefs: {
      'auto_backup_frequency': 'daily',
      'auto_backup_failure_streak': 3,
    });
    stubConnected(files: [_file()]);

    await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.sync_problem_rounded), findsOneWidget);
    expect(find.textContaining('otomatik yedekleme denemesi başarısız'),
        findsOneWidget);
  });

  /// Geri sayımlı onay: `Timer.periodic` sahte saatte adım adım ilerletilir.
  Future<void> waitOutCountdown(WidgetTester tester, [int seconds = 5]) async {
    for (var i = 0; i < seconds; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  group('bağlantıyı kes', () {
    setUp(() {
      when(() => drive.signOut()).thenAnswer((_) async {});
    });

    // Birden çok Google hesabı olan kullanıcı, yedeklerinin hangi hesapta
    // kaldığını burada görmezse tekrar bağlanırken yanlış hesabı seçip
    // "yedeklerim kayboldu" sanır.
    testWidgets('onay ister ve çıkılan hesabı gösterir', (tester) async {
      stubConnected(files: [_file()]);

      await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bağlantıyı Kes'));
      await tester.pump();

      expect(find.text('Bağlantı kesilsin mi?'), findsOneWidget);
      // Kart zaten e-postayı gösteriyor; aranan şey DİYALOĞUN onu söylemesi.
      expect(find.textContaining('kullanici@ornek.com hesabından çıkılacak'),
          findsOneWidget);
      // Yedeklerin silinmediği açıkça söylenmeli.
      expect(find.textContaining('SİLİNMEZ'), findsOneWidget);
      verifyNever(() => drive.signOut());
    });

    testWidgets('onay düğmesi 5 saniye boyunca kapalıdır', (tester) async {
      stubConnected(files: [_file()]);

      await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bağlantıyı Kes'));
      await tester.pump();

      // Geri sayım etiketi + devre dışı düğme.
      expect(find.textContaining('Bağlantıyı Kes (5)'), findsOneWidget);
      await waitOutCountdown(tester, 2);
      expect(find.textContaining('Bağlantıyı Kes (3)'), findsOneWidget);

      await waitOutCountdown(tester, 3);
      await tester.pumpAndSettle();
      verifyNever(() => drive.signOut());
    });

    testWidgets('iptal edilirse oturum kapatılmaz', (tester) async {
      stubConnected(files: [_file()]);

      await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bağlantıyı Kes'));
      await tester.pump();
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      verifyNever(() => drive.signOut());
      expect(find.text('30.07.2026 14:05'), findsOneWidget);
    });

    // C4 REGRESYON: bağlantı kesilince son-yedek göstergesi ve otomatik yedek
    // geçmişi duruyordu; başka bir hesaba bağlanan kullanıcı öncekinin yedek
    // saatini görüyordu.
    testWidgets('onaylanınca yedek durumu ve geçmiş temizlenir',
        (tester) async {
      await getIt.reset();
      await registerAll(prefs: {
        'auto_backup_frequency': 'daily',
        'auto_backup_last_success_at': DateTime(2026, 7, 1).toIso8601String(),
      });
      stubConnected(files: [_file()]);
      when(() => drive.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
      await tester.pumpAndSettle();
      expect(find.text('30.07.2026 14:05'), findsOneWidget);

      await tester.tap(find.text('Bağlantıyı Kes'));
      await tester.pump();
      await waitOutCountdown(tester);
      await tester.tap(find.text('Bağlantıyı Kes').last);
      await tester.pumpAndSettle();

      expect(find.text('30.07.2026 14:05'), findsNothing);
      expect(find.text('Google Drive\'a Bağlan'), findsOneWidget);
      expect(autoBackup.lastSuccessAt, isNull);
    });
  });

  group('tüm yedekleri sil', () {
    // "Tüm veriyi sil" ile aynı iki adımlı kapı: bu eylem kullanıcının TEK
    // kurtarma yolunu yok eder.
    testWidgets('iki adımlı onay ister ve ikinci adım geri sayım kapılıdır',
        (tester) async {
      stubConnected(files: [_file(), _file(id: 'f2')]);
      when(() => drive.deleteAllBackups())
          .thenAnswer((_) async => const DriveResult<void>.success());

      await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tüm Yedekleri Sil'));
      await tester.pump();

      // 1. adım
      expect(find.textContaining('kalıcı olarak silinecek'), findsOneWidget);
      verifyNever(() => drive.deleteAllBackups());
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      // 2. adım: geri sayımlı, kopya sayısını söyleyen uyarı
      expect(find.text('Bu İşlem Geri Alınamaz'), findsOneWidget);
      expect(find.textContaining('2 yedek kopyasının tamamı'), findsOneWidget);
      expect(find.textContaining('Sil (5)'), findsOneWidget);
      verifyNever(() => drive.deleteAllBackups());

      await waitOutCountdown(tester);
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      verify(() => drive.deleteAllBackups()).called(1);
    });

    testWidgets('ilk adımda iptal edilirse hiçbir şey silinmez',
        (tester) async {
      stubConnected(files: [_file()]);
      when(() => drive.deleteAllBackups())
          .thenAnswer((_) async => const DriveResult<void>.success());

      await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tüm Yedekleri Sil'));
      await tester.pump();
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      verifyNever(() => drive.deleteAllBackups());
      expect(find.text('Bu İşlem Geri Alınamaz'), findsNothing);
    });
  });

  // Drive API projede kapalıysa 403 gelir ama bu bir izin sorunu DEĞİLDİR;
  // kullanıcıya "izin vermedin" demek onu olmayan bir ekrana gönderirdi.
  testWidgets('API kapalı hatası izin hatasından ayrı anlatılır',
      (tester) async {
    stubConnected(files: [_file()]);
    when(() => drive.backup(
          origin: any(named: 'origin'),
          allowEmpty: any(named: 'allowEmpty'),
          interactive: any(named: 'interactive'),
          skipIfContentMd5Matches: any(named: 'skipIfContentMd5Matches'),
        )).thenAnswer((_) async => const DriveResult<DriveBackupFile>.failure(
          DriveOperationStatus.apiNotEnabled,
        ));

    await tester.pumpWidget(wrap(const GoogleDriveBackupCard()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Yedekle'));
    await tester.pumpAndSettle();

    expect(find.textContaining('etkinleştirilmemiş'), findsOneWidget);
    expect(find.textContaining('izin verilmedi'), findsNothing);
  });
}
