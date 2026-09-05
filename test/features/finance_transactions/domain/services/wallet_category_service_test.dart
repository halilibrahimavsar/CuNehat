import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockWalletRepository extends Mock implements WalletRepository {}

class FakeWalletEntity extends Fake implements WalletEntity {}

void main() {
  late MockCategoryRepository categories;
  late MockWalletRepository wallets;
  late WalletCategoryService service;

  CategoryEntity cat(String id, {String? parentId, bool isExpense = true}) =>
      CategoryEntity(
        id: id,
        name: id,
        iconName: 'category',
        isExpense: isExpense,
        parentId: parentId,
      );

  // Fatura(Elektrik) · Market   +   gelir: Maaş
  final all = [
    cat('fatura'),
    cat('elektrik', parentId: 'fatura'),
    cat('market'),
    cat('maas', isExpense: false),
  ];

  WalletEntity wallet({List<String>? categoryIds, double balance = 0}) =>
      WalletEntity(
        id: 'w1',
        userId: 'u1',
        name: 'İş',
        balance: balance,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: '0xFF000000',
        iconName: 'wallet',
        createdAt: DateTime(2026, 1, 1),
        openingBalance: 0,
        categoryIds: categoryIds,
      );

  /// `updateWallet`'a yazılan cüzdanın görünürlük kümesi.
  List<String>? writtenIds() =>
      (verify(() => wallets.updateWallet(captureAny())).captured.single
              as WalletEntity)
          .categoryIds;

  setUpAll(() => registerFallbackValue(FakeWalletEntity()));

  setUp(() {
    categories = MockCategoryRepository();
    wallets = MockWalletRepository();
    service = WalletCategoryService(categories, wallets);

    when(() => categories.getAllCategories()).thenAnswer((_) async => all);
    when(() => wallets.updateWallet(any()))
        .thenAnswer((_) async => const Right(null));
  });

  void seedWallet({List<String>? categoryIds, double balance = 0}) {
    when(() => wallets.getWalletById(any())).thenAnswer(
        (_) async => Right(wallet(categoryIds: categoryIds, balance: balance)));
  }

  /// Ardışık okumalara FARKLI cüzdan döndürür — "iki okuma arasında başkası
  /// yazdı" senaryosu.
  void seedWalletSequence(List<WalletEntity?> reads) {
    var i = 0;
    when(() => wallets.getWalletById(any())).thenAnswer((_) async {
      final value = reads[i < reads.length ? i : reads.length - 1];
      i++;
      return Right(value);
    });
  }

  WalletEntity? writtenWallet() =>
      verify(() => wallets.updateWallet(captureAny())).captured.single
          as WalletEntity?;

  group('okuma', () {
    test('kürasyonsuz cüzdanda türün TAMAMI döner', () async {
      seedWallet();

      final result =
          await service.categoriesFor(walletId: 'w1', isExpense: true);

      expect(result.map((c) => c.id), ['fatura', 'elektrik', 'market']);
    });

    test('küratörlü cüzdanda yalnız kümedekiler döner', () async {
      seedWallet(categoryIds: ['market']);

      final result =
          await service.categoriesFor(walletId: 'w1', isExpense: true);

      expect(result.map((c) => c.id), ['market']);
    });

    test('tür süzgeci kümeden BAĞIMSIZ uygulanır', () async {
      seedWallet(categoryIds: ['market', 'maas']);

      final result =
          await service.categoriesFor(walletId: 'w1', isExpense: false);

      expect(result.map((c) => c.id), ['maas']);
    });

    test('cüzdan okunamazsa liste EKSİLMEZ (kürasyonsuz sayılır)', () async {
      // Seçicinin boş kalması, listenin eksiksiz kalmasından çok daha kötü:
      // kategori zorunlu bir alan, boş seçici işlem kaydını tamamen bloklar.
      when(() => wallets.getWalletById(any()))
          .thenAnswer((_) async => const Left(CacheFailure('okunamadı')));

      final result =
          await service.categoriesFor(walletId: 'w1', isExpense: true);

      expect(result, hasLength(3));
    });
  });

  group('setVisibility', () {
    test('KÜRASYONA GEÇİŞ: null küme önce tümüyle doldurulur, sonra çıkarılır',
        () async {
      // Doğrudan çıkarma yapılsaydı küme `['market']` değil `[]`-eksi-market
      // olurdu ve cüzdan tek hamlede boşalırdı.
      seedWallet();

      await service.setVisibility(
        walletId: 'w1',
        categoryId: 'fatura',
        visible: false,
      );

      // Küme TÜRDEN BAĞIMSIZDIR: gelir kategorisi de içinde. Ağaç sırası
      // (`flattenTree`) sortOrder eşitken ada göre: maas < market.
      expect(writtenIds(), ['maas', 'market']);
    });

    test('kök kapatmak alt ağacı da düşürür', () async {
      seedWallet(categoryIds: ['fatura', 'elektrik', 'market']);

      await service.setVisibility(
        walletId: 'w1',
        categoryId: 'fatura',
        visible: false,
      );

      expect(writtenIds(), ['market']);
    });

    test('çocuk açmak kökü de katar', () async {
      seedWallet(categoryIds: const []);

      await service.setVisibility(
        walletId: 'w1',
        categoryId: 'elektrik',
        visible: true,
      );

      expect(writtenIds(), ['fatura', 'elektrik']);
    });

    test('değişiklik yoksa YAZILMAZ', () async {
      seedWallet(categoryIds: ['market']);

      await service.setVisibility(
        walletId: 'w1',
        categoryId: 'market',
        visible: true,
      );

      verifyNever(() => wallets.updateWallet(any()));
    });

    test('cüzdan bulunamazsa yazma denenmez', () async {
      when(() => wallets.getWalletById(any()))
          .thenAnswer((_) async => const Right(null));

      await service.setVisibility(
        walletId: 'yok',
        categoryId: 'market',
        visible: false,
      );

      verifyNever(() => wallets.updateWallet(any()));
    });
  });

  group('bayat yazım koruması (para alanları)', () {
    test('yazmadan ÖNCE taze okur: araya giren bakiye yazımı EZİLMEZ', () {
      // `WalletMetricsService` aynı kutuya kendi kuyruğuyla yazıyor, bu servis
      // o kuyruğun dışında. İlk okumadaki bayat kopya geri yazılsaydı
      // bakiye 250'den 100'e geri sarardı — para kaybı sınıfı bir hata.
      seedWalletSequence([
        wallet(categoryIds: ['fatura', 'market'], balance: 100),
        wallet(categoryIds: ['fatura', 'market'], balance: 250),
      ]);

      return expectLater(
        service
            .setVisibility(walletId: 'w1', categoryId: 'market', visible: false)
            .then((_) => writtenWallet()!.balance),
        completion(250),
      );
    });

    test('dönüşüm TAZE küme üzerinde yeniden uygulanır', () async {
      // Araya giren başka bir görünürlük yazımı da ezilmemeli: ilk okumadan
      // sonra 'elektrik' eklenmiş; biz 'market'i kapatıyoruz.
      seedWalletSequence([
        wallet(categoryIds: ['fatura', 'market']),
        wallet(categoryIds: ['fatura', 'market', 'elektrik']),
      ]);

      await service.setVisibility(
          walletId: 'w1', categoryId: 'market', visible: false);

      expect(writtenWallet()!.categoryIds, ['fatura', 'elektrik']);
    });

    test('iki okuma arasında cüzdan SİLİNDİYSE yazmaz', () async {
      // `put` silinmiş cüzdanı diriltirdi.
      seedWalletSequence([
        wallet(categoryIds: ['fatura', 'market']),
        null
      ]);

      await service.setVisibility(
          walletId: 'w1', categoryId: 'market', visible: false);

      verifyNever(() => wallets.updateWallet(any()));
    });
  });

  group('hata yolu', () {
    test('yazım başarısızsa CacheException FIRLATIR (sessizce dönmez)',
        () async {
      // Eskiden `Either` sonucu atılıyordu: çağıran "gizlendi" diyor, ekran
      // tersini gösteriyordu.
      seedWallet(categoryIds: ['fatura', 'market']);
      when(() => wallets.updateWallet(any()))
          .thenAnswer((_) async => const Left(CacheFailure('disk dolu')));

      expect(
        () => service.setVisibility(
            walletId: 'w1', categoryId: 'market', visible: false),
        throwsA(isA<CacheException>()),
      );
    });
  });

  group('onCategoriesDeleted', () {
    WalletEntity other(String id, {List<String>? categoryIds}) => WalletEntity(
          id: id,
          userId: 'u1',
          name: id,
          balance: 0,
          debt: 0,
          credit: 0,
          investment: 0,
          colorHex: '0xFF000000',
          iconName: 'wallet',
          createdAt: DateTime(2026, 1, 1),
          openingBalance: 0,
          categoryIds: categoryIds,
        );

    List<WalletEntity> writtenWallets() =>
        verify(() => wallets.updateWallet(captureAny()))
            .captured
            .cast<WalletEntity>();

    test('silinen kimlikler TÜM cüzdanlardan düşer, hedef katılır', () async {
      // Retag tüm cüzdanlarda oluyor; yalnız aktif cüzdanı onarmak, başka
      // cüzdanlardaki taşınmış işlemleri görünmez kategoriye düşürüyordu.
      when(() => wallets.getAllWallets()).thenAnswer((_) async => Right([
            other('w1', categoryIds: ['fatura', 'elektrik', 'market']),
            other('w2', categoryIds: ['elektrik']),
          ]));

      await service.onCategoriesDeleted(
        removedIds: {'elektrik'},
        replacementId: 'market',
      );

      final written = writtenWallets();
      expect(written.map((w) => w.id), ['w1', 'w2']);
      expect(written[0].categoryIds, ['fatura', 'market']);
      expect(written[1].categoryIds, ['market']);
    });

    test('hedef bir ALT kategoriyse kökü de katılır', () async {
      when(() => wallets.getAllWallets()).thenAnswer((_) async => Right([
            other('w1', categoryIds: ['market'])
          ]));

      await service.onCategoriesDeleted(
        removedIds: {'market'},
        replacementId: 'elektrik',
      );

      expect(writtenWallets().single.categoryIds, ['fatura', 'elektrik']);
    });

    test('KÜRASYONSUZ cüzdana dokunulmaz', () async {
      when(() => wallets.getAllWallets())
          .thenAnswer((_) async => Right([other('w1')]));

      await service
          .onCategoriesDeleted(removedIds: {'market'}, replacementId: 'fatura');

      verifyNever(() => wallets.updateWallet(any()));
    });

    test('silinen kimliği TAŞIMAYAN cüzdan yazılmaz', () async {
      when(() => wallets.getAllWallets()).thenAnswer((_) async => Right([
            other('w1', categoryIds: ['fatura'])
          ]));

      await service.onCategoriesDeleted(
          removedIds: {'market'}, replacementId: 'elektrik');

      verifyNever(() => wallets.updateWallet(any()));
    });

    test('hedef yoksa yalnız temizlik yapılır', () async {
      when(() => wallets.getAllWallets()).thenAnswer((_) async => Right([
            other('w1', categoryIds: ['fatura', 'market'])
          ]));

      await service.onCategoriesDeleted(removedIds: {'market'});

      expect(writtenWallets().single.categoryIds, ['fatura']);
    });

    test('boş küme depoya hiç gitmez', () async {
      await service.onCategoriesDeleted(removedIds: const {});
      verifyNever(() => wallets.getAllWallets());
    });
  });

  group('include', () {
    test('küratörlü cüzdanda kimlikleri katar ve SAYIYI döner', () async {
      seedWallet(categoryIds: ['market']);

      final added =
          await service.include(walletId: 'w1', categoryIds: ['elektrik']);

      expect(added, 2, reason: 'elektrik + kökü fatura');
      expect(writtenIds(), ['market', 'fatura', 'elektrik']);
    });

    test('KÜRASYONSUZ cüzdanda no-op: zaten hepsi görünüyor', () async {
      // Kümeyi maddileştirmek cüzdanı istemeden kürasyona sokardı; o andan
      // sonra eklenen her yeni kategori o cüzdanda görünmez olurdu.
      seedWallet();

      final added =
          await service.include(walletId: 'w1', categoryIds: ['elektrik']);

      expect(added, 0);
      verifyNever(() => wallets.updateWallet(any()));
    });

    test('zaten kümede olan kimlik yazım tetiklemez', () async {
      seedWallet(categoryIds: ['fatura', 'elektrik']);

      final added =
          await service.include(walletId: 'w1', categoryIds: ['elektrik']);

      expect(added, 0);
      verifyNever(() => wallets.updateWallet(any()));
    });

    test('boş liste depoya hiç gitmez', () async {
      final added =
          await service.include(walletId: 'w1', categoryIds: const []);

      expect(added, 0);
      verifyNever(() => wallets.getWalletById(any()));
    });
  });
}
