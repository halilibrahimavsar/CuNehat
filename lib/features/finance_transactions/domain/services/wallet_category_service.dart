import 'package:cunehat/core/error/exceptions.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/wallet_category_scope.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// "Bu cüzdanda hangi kategoriler var?" sorusunun TEK cevabı.
///
/// Kategori kayıtları küreseldir ([CategoryRepository]); cüzdan yalnız bir
/// görünürlük kümesi tutar ([WalletEntity.categoryIds]). Kural
/// `wallet_category_scope.dart`'ta saf fonksiyon olarak duruyor; burası onu
/// iki depoyla birleştiren ince katman.
///
/// Kategori DEPOSU değildir: ekleme/yeniden adlandırma/silme yine
/// [CategoryRepository] ve `DeleteCategoryUseCase` üzerinden yürür.
///
/// **Yazma hataları YUTULMAZ:** cüzdan yazılamazsa [CacheException] fırlatır.
/// `updateWallet` fırlatmaz, `Left` döner; sonucu atmak hatayı görünmez
/// yapıyordu ve çağıran kullanıcıya "gizlendi" deyip ekranda tersini
/// gösteriyordu.
@lazySingleton
class WalletCategoryService {
  final CategoryRepository _categories;
  final WalletRepository _wallets;

  WalletCategoryService(this._categories, this._wallets);

  /// Cüzdanın görünürlük kümesi; `null` = kürasyon yapılmamış (hepsi görünür).
  ///
  /// Cüzdan okunamazsa da `null` döner: seçicinin boş kalması, listenin
  /// eksiksiz kalmasından çok daha kötü — kategori zorunlu bir alan, boş
  /// seçici işlem kaydını tamamen bloklar.
  Future<List<String>?> visibleIds(String walletId) async {
    final result = await _wallets.getWalletById(walletId);
    return result.fold((_) => null, (wallet) => wallet?.categoryIds);
  }

  /// Bu cüzdanda görünür, tek türün kategorileri — ağaç sırasında.
  ///
  /// [alwaysInclude] kümede olmasa bile listeye katılır; bkz.
  /// [scopeCategoriesToWallet].
  Future<List<CategoryEntity>> categoriesFor({
    required String walletId,
    required bool isExpense,
    String? alwaysInclude,
  }) async {
    final all = await _categories.getAllCategories();
    final visible = await visibleIds(walletId);
    return scopeCategoriesToWallet(
      all.where((c) => c.isExpense == isExpense),
      visible,
      alwaysInclude: alwaysInclude,
    );
  }

  /// Tek kategoriyi bu cüzdanda gösterir/gizler.
  ///
  /// **Kürasyona geçiş burada olur:** kümesi `null` olan cüzdan ("hepsi
  /// görünür") ilk gizlemede önce MEVCUT tüm kategorilerle doldurulur, sonra
  /// çıkarma uygulanır. Doğrudan `[categoryId]` çıkarılsaydı küme
  /// "yalnız bu kategori gizli" değil "yalnız bu kategori görünür"ün tersi
  /// olurdu ve cüzdan tek hamlede boşalırdı.
  Future<void> setVisibility({
    required String walletId,
    required String categoryId,
    required bool visible,
  }) async {
    final all = await _categories.getAllCategories();
    await _commit(
      walletId,
      all,
      (current) => applyCategoryVisibility(
        current,
        all,
        categoryId: categoryId,
        visible: visible,
      ),
    );
  }

  /// [categoryIds] (ve alt kategoriyse kökleri) kümeye katılır.
  ///
  /// Başlangıç paketi kurulumu, "yeni kategori oluştur" ve ekstre öneri onayı
  /// bunu kullanır: az önce yaratılan kategori, yaratıldığı cüzdanda
  /// görünmezse özellik kırık görünür.
  ///
  /// Kürasyonsuz (`null`) cüzdanda NO-OP: zaten hepsi görünüyor, kümeyi
  /// maddileştirmek cüzdanı gereksiz yere kürasyona sokardı.
  ///
  /// Kümeye YENİ giren kimlik sayısını döner (no-op'ta 0).
  Future<int> include({
    required String walletId,
    required Iterable<String> categoryIds,
  }) async {
    if (categoryIds.isEmpty) return 0;
    final all = await _categories.getAllCategories();
    var added = 0;
    await _commit(
      walletId,
      all,
      (current) {
        final next = includeCategories(current, all, categoryIds);
        added = next.length - current.length;
        return next;
      },
      // Kürasyonsuz cüzdan kürasyona SOKULMAZ.
      materializeUncurated: false,
    );
    return added;
  }

  /// Silinen kategorilerin kimliklerini HER cüzdanın kümesinden düşürür ve
  /// (varsa) taşıma hedefini o cüzdanlara katar.
  ///
  /// **Neden tüm cüzdanlar:** silme küreseldir ve `retagTransactions` etiketi
  /// TÜM cüzdanlarda değiştirir (bkz. `TransactionsRepository.countByTags`).
  /// Yalnız aktif cüzdan onarılsaydı başka cüzdanlardaki taşınmış işlemler
  /// orada GÖRÜNMEYEN bir kategoriye düşerdi.
  ///
  /// Ölü kimlikler okuma tarafında zaten sessizce eleniyor
  /// ([scopeCategoriesToWallet]); burada temizlenmelerinin sebebi kümenin
  /// yıllar içinde ölü kimlikle şişmemesi.
  ///
  /// Kürasyonsuz (`null`) cüzdanlarda onarılacak bir şey yok.
  Future<void> onCategoriesDeleted({
    required Set<String> removedIds,
    String? replacementId,
  }) async {
    if (removedIds.isEmpty) return;

    final walletsResult = await _wallets.getAllWallets();
    final wallets = walletsResult.fold(
      (failure) {
        debugPrint('Kategori görünürlüğü onarılamadı: ${failure.message}');
        return const <WalletEntity>[];
      },
      (list) => list,
    );

    // Hedefin KÖKÜNÜ de katabilmek için silme SONRASI güncel liste.
    final all = await _categories.getAllCategories();

    for (final wallet in wallets) {
      final current = wallet.categoryIds;
      if (current == null) continue;
      if (!current.any(removedIds.contains)) continue;

      var next = current.where((id) => !removedIds.contains(id)).toList();
      if (replacementId != null) {
        next = includeCategories(next, all, [replacementId]);
      }
      await _write(wallet.copyWith(categoryIds: next));
    }
  }

  /// Oku → dönüştür → **taze oku, yeniden dönüştür** → yaz.
  ///
  /// İkinci okuma iki şeyi birden korur:
  /// 1. Cüzdanın PARA alanları (`balance`/`debt`/`credit`/`investment`).
  ///    `WalletMetricsService` aynı kutuya cüzdan başına bir kuyrukla yazıyor
  ///    (`_serialized`); bu servis o kuyruğun DIŞINDA. Bayat kopyayı geri
  ///    yazmak bakiyeyi geri sarardı — `syncBalance` da tam bu yüzden
  ///    yazmadan hemen önce taze okuyup yalnız kendi alanını uyguluyor.
  /// 2. Kendi kümemiz: dönüşüm taze küme üzerinde YENİDEN uygulandığı için
  ///    araya giren başka bir görünürlük yazımı ezilmez.
  ///
  /// Pencereyi **daraltır, kaldırmaz**: `box.get` ile `box.put` arasında hâlâ
  /// bir await noktası var. Kuyruğu paylaşmak `WalletMetricsService`'e zorunlu
  /// bir yapıcı parametresi (35 test kurulumu) ya da sessiz bir varsayılan
  /// gerektiriyordu; bu turun bedeline değmedi.
  ///
  /// Ölçüldü: metrik yazıcılarının HEPSİ (`syncBalance`, `syncDebt`,
  /// `syncCredit`, `syncInvestment`) zaten yazmadan hemen önce taze okuyup
  /// yalnız KENDİ alanını uyguluyor. Bu servis de artık öyle yaptığı için
  /// kalan risk simetrik ve dar: iki taraf da yalnız o son `get`–`put`
  /// aralığında birbirini ezebilir.
  ///
  /// [materializeUncurated] false ise kürasyonsuz cüzdana hiç dokunulmaz.
  Future<void> _commit(
    String walletId,
    List<CategoryEntity> all,
    List<String> Function(List<String> current) transform, {
    bool materializeUncurated = true,
  }) async {
    List<String>? plan(WalletEntity wallet) {
      final curated = wallet.categoryIds;
      if (curated == null && !materializeUncurated) return null;
      final current = curated ?? flattenTree(all).map((c) => c.id).toList();
      final next = transform(current);
      // Kürasyonsuz cüzdanda "değişiklik yok" bile YAZILIR: kümenin
      // maddileşmesi kürasyona geçişin kendisidir.
      if (curated != null && _sameIds(curated, next)) return null;
      return next;
    }

    final wallet = await _wallet(walletId);
    if (wallet == null) return;
    if (plan(wallet) == null) return;

    final fresh = await _wallet(walletId);
    // İki okuma arasında silindiyse bayat kopyayı geri yazma: `put` silinmiş
    // cüzdanı diriltir (aynı gerekçe: `WalletMetricsService.syncBalance`).
    if (fresh == null) return;
    final next = plan(fresh);
    if (next == null) return;

    await _write(fresh.copyWith(categoryIds: next));
  }

  Future<WalletEntity?> _wallet(String walletId) async {
    final result = await _wallets.getWalletById(walletId);
    return result.fold((_) => null, (wallet) => wallet);
  }

  Future<void> _write(WalletEntity wallet) async {
    final result = await _wallets.updateWallet(wallet);
    result.fold(
      (failure) => throw CacheException(
        'Kategori görünürlüğü yazılamadı: ${failure.message}',
      ),
      (_) {},
    );
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
