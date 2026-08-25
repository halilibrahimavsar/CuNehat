# ÇuNehat — Derinlemesine Mantıksal Analiz ve Düzeltme Planı (DÜZELTİLMİŞ)

## Context
Kullanıcı, kendi geliştirdiği kişisel finans uygulamasında (ÇuNehat — Flutter, clean architecture + flutter_bloc + Hive + GetIt/injectable + Firebase, ~151 Dart dosyası / ~19.7k satır) **mantıksal hataların kanıtlarıyla** tespitini istedi. Sadece planlama; kod değişikliği henüz yok.

Proje **sağlıklı**: `dart analyze` temiz (yalnız 7 info-lint), derleme hatası yok, mimari tutarlı, finansal matematik (basit faiz, yatırım kâr %'si, işlem bakiye delta'ları) doğru.

> **Önemli dürüstlük notu:** Bu planın ilk sürümü, bazı dosya okumalarının **bozuk/eski içerik** döndürmesi yüzünden 2 yanlış bulgu (#2 cüzdansız çökme, #3 watch aktif sıfırlama) ve birkaç hatalı satır/metot adı içeriyordu. Dosyaların **gerçek** içeriği geldikten sonra hepsi yeniden doğrulandı. Aşağıdaki liste yalnızca **kaynak kodla birebir teyit edilmiş** bulguları içerir; yanlış çıkanlar "Elenenler" bölümünde kanıtıyla listelidir.

---

## Doğrulanmış Bulgular

### #1 [Orta] Filtre aktifken "işlem sonrası bakiye" yanlış  ✅ GERÇEK
**Kanıt:**
- `lib/features/finance_transactions/presentation/widgets/calculate_running_balance_helper.dart:13-38` — `runningBalance = finalBalance`'tan başlayıp listeyi (tam geçmiş varsayımıyla) geriye doğru çözüyor. Doğruluğu, listenin cüzdanın TÜM işlemleri olmasına bağlı.
- `lib/features/finance_transactions/presentation/pages/transaction_page.dart` → `_getFilteredData()` (satır 78-112): önce FinanceMode (82-87), kategori (89-94) ve fiyat aralığı (96-101) filtrelerini uyguluyor; sonra **filtrelenmiş alt kümeyi** `calculateRunningBalance(filtered, widget.wallet.balance)` (106-109) ile çözüyor. Alt küme + tam-bakiye çapası = filtreli görünümde hatalı `balanceAfter`.
- (Sınıf adı `TransactionsPage`/`_TransactionsView`; düzeltilecek metot `_getFilteredData`.)

**Düzeltme (full-list-then-filter — kullanıcı onaylı):** `_getFilteredData` içinde sırayı tersine çevir:
1. `allTransactions`'ı tarihe göre sırala (yeni→eski).
2. **TAM liste** üzerinde `calculateRunningBalance(allSorted, widget.wallet.balance)` çağır → `List<TransactionWithBalance>`.
3. FinanceMode / kategori / fiyat filtrelerini **bu listenin** `.transaction` alanına uygula (`where`).
Böylece `balanceAfter` gerçek geçmişe göre doğru kalır. `DetailedListView` zaten `List<TransactionWithBalance>` alıyor (`detailed_list_view.dart:9`) ve ayrıca kendi içinde FinanceMode filtresi yapıyor (`:30-36`) — bu çift filtre, full-list yaklaşımında da güvenli çalışır.

### #2 [Düşük] Açılışta tema titremesi  ✅ GERÇEK
**Kanıt:** `lib/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart:14-16` — constructor'da `_loadSavedTheme()` await edilmeden çağrılıyor; başlangıç state'i `ThemeStateLight()`. Kayıtlı tema (örn. dark) bir-iki frame sonra `ThemeLoadEvent` ile uygulanıyor → kısa flaş. (Okuma/yazma anahtarları tutarlı; veri kaybı yok.)
**Düzeltme:** Kayıtlı temayı `runApp` öncesi `app_initialization.dart` içinde okuyup `ThemeBloc`'a doğru başlangıç state'i olarak geçir; ilk frame doğru temayla çizilsin.

### #3 [Düşük] Borç geçmişinde kart etiketi/filtre yanıltıcı  ✅ KISMEN GERÇEK
**Kanıt:** `lib/features/debt_and_receivable/presentation/pages/debt_history_page.dart:52` — `d.isPaid || d.remainingAmount <= 0` (OR): kullanıcı işaretlemese de otomatik-kapanan borçlar listeye giriyor (tasarım tercihi olabilir). Kart üzerinde (`:130, :138`) `debt.totalDebtAmount` değeri "Ödendi" etiketiyle gösteriliyor — aşırı/kısmi ödemede yanıltıcı.
> Düzeltme: Özet toplamı (`:58-61`) **doğru** (`totalPaidAmount` kullanıyor) — ilk sürümdeki "totalDebtAmount topluyor" iddiası YANLIŞTI. Yapılacak tek şey: kart üzerinde gerçek ödeneni göstermek (`totalPaidAmount`) ve "ödenmiş" kriterini netleştirmek (`isPaid` mi `remainingAmount<=0` mı).

---

## Lint Temizliği (7 info)
- `lib/features/investments/data/models/investment_model.dart:74` — `copyWith` üzerine `@override` ekle (`annotate_overrides`).
- `dartz` (`depend_on_referenced_packages`, 6 dosya: investments domain/usecases + repository_impl). Ya `pubspec.yaml`'a `dartz`'ı açıkça ekle (a), ya da investments'i projenin `core/error/failure.dart` desenine taşıyıp `dartz`'ı kaldır (b — mimari tutarlılık, daha geniş iş).

---

## Elenen / Yanlış Çıkan Bulgular (kanıtla)
- **(eski #2) "Cüzdansız kullanıcı İşlemler'de çöküyor" — YANLIŞ.** `home_page.dart:121-123` `activeWallet == null` ise `NoWalletView` döndürüp view-stack'i hiç kurmuyor; `_buildContent` default'u da (`:108`) `NoWalletView`. `SubViewFactory` zaten `wallet` parametresi almıyor (sadece `userId`/`walletId` string'leri, `:127`'de null guard'dan SONRA `activeWallet.id!`). Çökme yok.
- **(eski #3) "WatchWalletsEvent aktif cüzdanı `wallets.first`'e sıfırlıyor" — YANLIŞ.** `wallet_bloc.dart:70` `onData` içinde `_findActiveWallet(wallets)` ile kalıcı `isActive` bayrağını okuyor; yalnız hiç aktif yoksa ilk cüzdana düşüyor (ve `SetActiveWalletEvent` yayıyor). Seçim korunuyor.
- **(eski #1b) "Ekleme sonrası bakiye çapası bayat" — GEÇERSİZ (teyit edildi).** `wallet_local_datasource.dart:92-119` `watchWallets`, `walletBox.watch()` + `userBox.watch()` ile her kutu değişiminde yeniden yayıyor. `applyBalanceDelta → updateWallet → box.put` bakiyeyi değiştirince stream taze cüzdanı yayıyor, `home_page` `TransactionsPage`'i taze `wallet.balance` ile yeniden kuruyor; ayrıca `TransactionActionSuccess` dinleyicisi işlemleri yeniden yüklüyor. Bayatlama olmuyor.
- copyWith id kaybı (TransactionModel `:107` aslında `id ?? this.id`), DebtModel `@HiveField` sıra bozulması (indexler tutarlı; `.g.dart` doğru), GoRouter loading→login (loading splash'e gidiyor), yatırım %'de sıfıra bölme (`amount>0` guard'lı), IconData serileştirme (adapter kayıtlı), nav index taşması (`navigateTo` ve `switch` default güvenli) — **hepsi alt-ajan uydurmaları, kaynakta yok.**

---

## Kritik dosyalar
- `lib/features/finance_transactions/presentation/pages/transaction_page.dart` (`_getFilteredData`) + `.../widgets/calculate_running_balance_helper.dart` — #1.
- `lib/features/settings/presentation/blocs/theme_blocs/theme_bloc.dart` (+ `lib/config/initialization/app_initialization.dart`) — #2.
- `lib/features/debt_and_receivable/presentation/pages/debt_history_page.dart` — #3.
- `lib/features/investments/...` + `pubspec.yaml` — lint.

## Önerilen sıra (uygulanırsa)
1. #1 (en görünür doğruluk hatası) → 2. #2, #3 (parlatma) → 3. Lint.

## Doğrulama (uçtan uca)
- **Statik:** Her değişiklikten sonra `dart analyze` → 0 hata.
- **#1:** Gelir+gider karışık işlemler oluştur; filtresiz satır bakiyelerini not al → gelir-only / kategori / fiyat filtrelerini aç → görünen işlemlerin `balanceAfter` değerleri filtresizdekiyle **birebir aynı** kalmalı.
- **#2:** Temayı dark yap, kapat-aç → açılışta light flaşı olmamalı.
- **#3:** Kısmi/aşırı ödemeyle kapanan borç → kartta gösterilen tutar gerçekte ödenenle tutarlı olmalı.
- **Manuel koşu:** `/run` veya `flutter run`. Mümkünse `calculateRunningBalance` için birim test ekle.
