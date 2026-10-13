import 'package:cunehat/core/error/error_log.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/backup_summary.dart';
import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/install_starter_pack_usecase.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/first_wallet_setup.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWalletRepository extends Mock implements WalletRepository {}

class _MockInstallStarterPack extends Mock
    implements InstallStarterPackUseCase {}

class _FakeWallet extends Fake implements WalletEntity {}

void main() {
  late _MockWalletRepository wallets;
  late _MockInstallStarterPack installPack;
  late FirstWalletSetup setup;

  setUpAll(() {
    registerFallbackValue(_FakeWallet());
    registerFallbackValue(<StarterPackSelection>[]);
  });

  setUp(() {
    ErrorLog.instance.resetForTest();
    wallets = _MockWalletRepository();
    installPack = _MockInstallStarterPack();

    when(() => wallets.createWallet(any())).thenAnswer(
      (inv) async =>
          Right((inv.positionalArguments.single as WalletEntity).id!),
    );
    when(() => wallets.setActiveWallet(
          userId: any(named: 'userId'),
          newActiveWalletId: any(named: 'newActiveWalletId'),
        )).thenAnswer((_) async => const Right(null));
    when(() => installPack(
          any(),
          languageCode: any(named: 'languageCode'),
          walletId: any(named: 'walletId'),
        )).thenAnswer((_) async => (created: 40, attached: 40));

    setup = FirstWalletSetup(
      WalletCreateUseCase(wallets),
      WalletSetActiveUseCase(wallets),
      installPack,
    );
  });

  tearDown(ErrorLog.instance.resetForTest);

  Future<Either<Failure, String>> run({double openingBalance = 0}) => setup(
        userId: 'local_user',
        name: 'Cüzdanım',
        openingBalance: openingBalance,
        currency: 'TRY',
        languageCode: 'tr',
        now: DateTime(2026, 10, 13, 9),
      );

  WalletEntity createdWallet() =>
      verify(() => wallets.createWallet(captureAny())).captured.single
          as WalletEntity;

  group('"Başla" tek dokunuşla kurar', () {
    test('cüzdan verilen ad, birim ve açılış bakiyesiyle doğar', () async {
      final result = await run(openingBalance: 1500.5);

      final wallet = createdWallet();
      expect(result, Right<Failure, String>(wallet.id!));
      expect(wallet.name, 'Cüzdanım');
      expect(wallet.userId, 'local_user');
      expect(wallet.currency, 'TRY');
      expect(wallet.balance, 1500.5);
      // Defter değişmezi: balance = opening + Σtx; henüz işlem yok.
      expect(wallet.openingBalance, wallet.balance);
      expect(wallet.debt, 0);
      expect(wallet.credit, 0);
      expect(wallet.investment, 0);
      expect(wallet.isCreditCard, isFalse);
    });

    test('tutar boş geçildiyse bakiye sıfırdır', () async {
      await run();

      // `captured.single`: cüzdan yalnız BİR kez yazılır.
      expect(createdWallet().balance, 0);
    });

    test('bakiye kuruşa yuvarlanarak yazılır', () async {
      await run(openingBalance: 10.005000001);

      final wallet = createdWallet();
      expect(wallet.balance, 10.01);
      expect(wallet.openingBalance, 10.01);
    });

    test('cüzdan küratörlü doğar: görünürlük kümesi boş başlar, paket doldurur',
        () async {
      await run();

      // `null` "kürasyon yok, hepsi görünür" demektir; ikinci cüzdan kurulunca
      // birincisi onun kategorilerini de gösterirdi.
      expect(createdWallet().categoryIds, isEmpty);
    });

    test('yeni cüzdan aktif yapılır', () async {
      await run();

      final wallet = createdWallet();
      verify(() => wallets.setActiveWallet(
            userId: 'local_user',
            newActiveWalletId: wallet.id!,
          )).called(1);
    });

    test('hazır kategori setinin TAMAMI o cüzdana, seçili dilde kurulur',
        () async {
      await run();

      final wallet = createdWallet();
      final call = verify(() => installPack(
            captureAny(),
            languageCode: 'tr',
            walletId: wallet.id!,
          ))
        ..called(1);
      final selections =
          (call.captured.single as Iterable<StarterPackSelection>).toList();

      expect(
        selections.where((s) => s.isExpense).map((s) => s.group.key),
        CategoryStarterPack.expense.map((g) => g.key),
      );
      expect(
        selections.where((s) => !s.isExpense).map((s) => s.group.key),
        CategoryStarterPack.income.map((g) => g.key),
      );
      // Kategorisi olmayan türde kayıt girilemez (kategori zorunlu alan).
      expect(selections.any((s) => s.isExpense), isTrue);
      expect(selections.any((s) => !s.isExpense), isTrue);
    });

    test('sıra: önce cüzdan, sonra aktiflik, en son kategoriler', () async {
      await run();

      verifyInOrder([
        () => wallets.createWallet(any()),
        () => wallets.setActiveWallet(
              userId: any(named: 'userId'),
              newActiveWalletId: any(named: 'newActiveWalletId'),
            ),
        () => installPack(
              any(),
              languageCode: any(named: 'languageCode'),
              walletId: any(named: 'walletId'),
            ),
      ]);
    });
  });

  group('hata', () {
    test('cüzdan yazılamazsa hata döner; aktiflik ve kategori denenmez',
        () async {
      when(() => wallets.createWallet(any()))
          .thenAnswer((_) async => const Left(CacheFailure('disk dolu')));

      final result = await run();

      expect(result.isLeft(), isTrue);
      verifyNever(() => wallets.setActiveWallet(
            userId: any(named: 'userId'),
            newActiveWalletId: any(named: 'newActiveWalletId'),
          ));
      verifyNever(() => installPack(
            any(),
            languageCode: any(named: 'languageCode'),
            walletId: any(named: 'walletId'),
          ));
    });

    test(
        'kategori kurulumu fırlatsa da cüzdan geri alınmaz: akış başarılıdır, '
        'hata günlüğe düşer', () async {
      // Kategori deposu `Either` değil exception fırlatır.
      when(() => installPack(
            any(),
            languageCode: any(named: 'languageCode'),
            walletId: any(named: 'walletId'),
          )).thenThrow(StateError('kategori kutusu açılamadı'));

      final result = await run();

      expect(result.isRight(), isTrue);
      expect(
        ErrorLog.instance.entries.single.source,
        'İlk cüzdan · kategori seti',
      );
    });

    test('aktifleştirme başarısız olsa da kategoriler kurulur', () async {
      // Aktif cüzdan yoksa `WalletBloc` ilk cüzdana kendisi düşer.
      when(() => wallets.setActiveWallet(
            userId: any(named: 'userId'),
            newActiveWalletId: any(named: 'newActiveWalletId'),
          )).thenAnswer((_) async => const Left(CacheFailure('yazılamadı')));

      final result = await run();

      expect(result.isRight(), isTrue);
      verify(() => installPack(
            any(),
            languageCode: any(named: 'languageCode'),
            walletId: any(named: 'walletId'),
          )).called(1);
      expect(
        ErrorLog.instance.entries.single.source,
        'İlk cüzdan · aktifleştirme',
      );
    });
  });

  group('neden açılışta sessizce cüzdan OLUŞTURULMAZ', () {
    BackupSummary summary({required int walletCount}) => BackupSummary(
          schemaVersion: 16,
          createdAt: null,
          walletCount: walletCount,
          transactionCount: 0,
          investmentCount: 0,
          debtCount: 0,
          receivableCount: 0,
          budgetCount: 0,
          recurringCount: 0,
          categoryCount: 0,
          goalCount: 0,
          wallets: const [],
          firstTransactionDate: null,
          lastTransactionDate: null,
          totalIncome: 0,
          totalExpense: 0,
          transactionsWithReceipt: 0,
        );

    test(
        'tek bir boş cüzdan bile cihazı "boş" olmaktan çıkarır — otomatik '
        'yedeğin "boş veriyle Drive\'ı ezme" kapısı buna bakar', () {
      expect(summary(walletCount: 0).isEmpty, isTrue);
      expect(summary(walletCount: 1).isEmpty, isFalse);
    });
  });
}
