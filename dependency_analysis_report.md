# Bağımlılık Ağacı & Ölü Kod Raporu

Proje: `/home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat`  ·  Üretildi: `python3 tool/analyze_deps.py`

## Özet

- `lib/` Dart dosyası: **154**
- `main.dart` import ağacından erişilebilir: **150** (%97)
- **Orphan dosya** (hiç import edilmiyor): **4**
- Bildirim (düğüm): **2249**  ·  canlı: **2125**
- **🟢 Güvenli silme adayı** (her metinsel geçişi statik açıklandı): **51**
- 🟡 Korundu — belirsiz (dynamic/string/constructor/benzersiz-değil): **73**
- 🔢 Kullanılmayan enum sabiti (elle incele): **0**
- Sadece testlerce kullanılan üye: **0**

## Feature Bazında Erişilebilirlik

| Alan | Erişilebilir / Toplam |
|------|----------------------|
| `config` | 7 / 8  ⚠️ |
| `core` | 23 / 26  ⚠️ |
| `features/debt_and_receivable` | 25 / 25 |
| `features/finance_transactions` | 36 / 36 |
| `features/investments` | 22 / 22 |
| `features/main_feature` | 10 / 10 |
| `features/settings` | 12 / 12 |
| `features/wallet` | 14 / 14 |
| `main.dart` | 1 / 1 |

## 🔴 Orphan Dosyalar (silme adayı)

Ne üretim ne de test ağacından import ediliyor.

- [ ] `lib/config/theme/custom_theme.dart`
- [ ] `lib/core/shared/widgets/app_list_entrance.dart`
- [ ] `lib/core/shared/widgets/app_shimmer.dart`
- [ ] `lib/core/utils/error_handler.dart`

## 🟢 Güvenli Silme Adayları

Mark-and-sweep ile erişilemeyen VE adının kod tabanındaki her metinsel geçişi statik bir referansla açıklanan üyeler. `dynamic`/string/reflection ile erişim ihtimali ELENMİŞTİR — bu liste güvenli kabul edilir. Yine de silmeden önce her satır incelenmeli.

### `lib/core/constants/app_constants.dart` — 18 öğe

| Tür | Üye | Satır | Neden |
|-----|-----|-------|-------|
| CLASS | `HiveBoxes` | 7 | hiç referans yok |
| FIELD | `HiveBoxes.expenses` | 8 | hiç referans yok |
| FIELD | `HiveBoxes.incomes` | 9 | hiç referans yok |
| FIELD | `HiveBoxes.pendingOperations` | 10 | hiç referans yok |
| CLASS | `WalletDefaults` | 16 | hiç referans yok |
| FIELD | `WalletDefaults.defaultWalletId` | 17 | hiç referans yok |
| FIELD | `WalletDefaults.defaultWalletName` | 18 | hiç referans yok |
| FIELD | `WalletDefaults.defaultColorHex` | 19 | hiç referans yok |
| FIELD | `WalletDefaults.defaultIconName` | 20 | hiç referans yok |
| FIELD | `AppConstants.appName` | 85 | hiç referans yok |
| FIELD | `AppConstants.appVersion` | 86 | hiç referans yok |
| FIELD | `AppConstants.apiTimeout` | 89 | hiç referans yok |
| FIELD | `AppConstants.cacheTimeout` | 90 | hiç referans yok |
| FIELD | `AppConstants.maxTransactionsPerPage` | 93 | hiç referans yok |
| FIELD | `AppConstants.maxTransactionAmount` | 94 | hiç referans yok |
| FIELD | `AppConstants.currencyCode` | 98 | hiç referans yok |
| FIELD | `AppFormatters.number` | 113 | hiç referans yok |
| FIELD | `AppRoutes.forgotPassword` | 124 | hiç referans yok |

### `lib/features/finance_transactions/domain/entities/filter_entity.dart` — 6 öğe

| Tür | Üye | Satır | Neden |
|-----|-----|-------|-------|
| FIELD | `DataFilter.empty` | 66 | hiç referans yok |
| METHOD | `DataFilter.matchesSearch` | 100 | hiç referans yok |
| METHOD | `ViewFilter.isTodayRange` | 133 | hiç referans yok |
| METHOD | `ViewFilter.isThisWeekRange` | 143 | hiç referans yok |
| METHOD | `ViewFilter.isThisMonthRange` | 149 | hiç referans yok |
| GETTER | `ViewFilter.dateRangeText` | 154 | hiç referans yok |

### `lib/features/finance_transactions/presentation/widgets/finance_mode.dart` — 6 öğe

| Tür | Üye | Satır | Neden |
|-----|-----|-------|-------|
| GETTER | `FinanceMode.description` | 19 | hiç referans yok |
| GETTER | `FinanceMode.secondaryColor` | 63 | hiç referans yok |
| GETTER | `FinanceMode.darkColor` | 74 | hiç referans yok |
| GETTER | `FinanceMode.gradientColors` | 85 | hiç referans yok |
| GETTER | `FinanceMode.sliderValue` | 108 | hiç referans yok |
| GETTER | `FinanceMode.gradientAppBarColor` | 119 | hiç referans yok |

### `lib/features/main_feature/controllers/home_navigation_controller.dart` — 4 öğe

| Tür | Üye | Satır | Neden |
|-----|-----|-------|-------|
| GETTER | `HomeNavigationController.currentStackIndex` | 46 | hiç referans yok |
| GETTER | `HomeNavigationController.isSubViewOpen` | 48 | hiç referans yok |
| METHOD | `HomeNavigationController.nextView` | 80 | hiç referans yok |
| METHOD | `HomeNavigationController.previousView` | 85 | hiç referans yok |

### `lib/core/shared/animations/unified_cube_transition.dart` — 3 öğe

| Tür | Üye | Satır | Neden |
|-----|-----|-------|-------|
| GETTER | `VerticalListTransitionManager.currentIndex` | 175 | yalnızca ölü kod tarafından kullanılıyor (ör. currentStackIndex) |
| METHOD | `VerticalListTransitionManager.next` | 209 | yalnızca ölü kod tarafından kullanılıyor (ör. nextView) |
| METHOD | `VerticalListTransitionManager.previous` | 216 | yalnızca ölü kod tarafından kullanılıyor (ör. previousView) |

### `lib/features/main_feature/config/menu_configuration.dart` — 3 öğe

| Tür | Üye | Satır | Neden |
|-----|-----|-------|-------|
| METHOD | `MenuConfigs.getConfig` | 152 | hiç referans yok |
| METHOD | `MenuConfigs.getSubMenus` | 154 | hiç referans yok |
| METHOD | `MenuConfigs.getMiniButtons` | 158 | hiç referans yok |

### Diğer — 11 öğe (7 dosya)

| Tür | Üye | Dosya:Satır | Neden |
|-----|-----|-------------|-------|
| FIELD | `AppSurface.aurora` | `lib/config/theme/app_surface_theme.dart`:56 | yalnızca ölü kod tarafından kullanılıyor (ör. auroraTheme) |
| CLASS | `CustomeAppThemes` | `lib/config/theme/custom_theme.dart`:8 | hiç referans yok |
| FIELD | `CustomeAppThemes.auroraTheme` | `lib/config/theme/custom_theme.dart`:12 | hiç referans yok |
| CLASS | `ErrorHandler` | `lib/core/utils/error_handler.dart`:5 | hiç referans yok |
| METHOD | `ErrorHandler.handleException` | `lib/core/utils/error_handler.dart`:7 | hiç referans yok |
| METHOD | `CategoryService.resetCategories` | `lib/features/finance_transactions/data/datasources/category_service.dart`:189 | hiç referans yok |
| METHOD | `TransactionFilterCubit.resetFilters` | `lib/features/finance_transactions/presentation/bloc/filtering/transaction_filter_cubit.dart`:35 | hiç referans yok |
| METHOD | `TransactionSheetHandler.showExpenseSheet` | `lib/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart`:51 | hiç referans yok |
| METHOD | `TransactionSheetHandler.showIncomeSheet` | `lib/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart`:66 | hiç referans yok |
| FIELD | `AppBorderRadius.small` | `lib/features/main_feature/utils/app_constants.dart`:12 | hiç referans yok |
| FIELD | `AppBorderRadius.large` | `lib/features/main_feature/utils/app_constants.dart`:14 | hiç referans yok |

## 🟡 Korundu — Belirsiz (silme adayı DEĞİL)

Mark-and-sweep ölü dedi ama güvenlik filtresi eledi. Gerçekten ölü olabilirler ama statik olarak kanıtlanamıyor — otomatik silinmez.

| Eleme nedeni | Adet |
|--------------|------|
| constructor | 43 |
| ad benzersiz değil | 28 |
| açıklanamayan metinsel geçiş (dynamic/string) | 2 |

Toplam **73**. Tam liste `dead_symbols.cache.json` → `kept_uncertain`.

## 🔢 Kullanılmayan Enum Sabitleri (elle incele)

`.values` / `fromJson` / kalıcı veri ile runtime'da erişilebilir — statik sayım bunu göremez. Otomatik silinmez.

_Yok._

## 🧪 Sadece Testlerce Kullanılan Üyeler

Üretimde kullanılmıyor; silinmez (testler bozulur), incelenir.

_Yok._

## Yöntem & Kısıtlar

**Dosya seviyesi:** `import`/`export`/`part` grafiği — statik kesin.
**Üye seviyesi:** Dart Analysis Server (OUTLINE + NAVIGATION) ile tüm bildirimler düğüm, kullanımlar kenar yapılır; gerçek giriş noktalarından erişilemeyen her şey **mark-and-sweep** ile ölü işaretlenir. `getTypeHierarchy` ile override aileleri uzlaştırılır.
**Güvenlik filtresi:** `dynamic` erişim / string / reflection statik analizle çözülemez. Bu yüzden bir adın kod tabanındaki HER metinsel geçişi çözülmüş bir referansla açıklanamıyorsa o üye **silme adayı OLMAZ** (→ Korundu). Hata yönü güvenli: fazladan saklanır, kullanılan kod asla silinmez.
**Sınır:** yaklaşım conservative'dir — yanlış-pozitif ≈ 0, ama bazı gerçek ölü kod "Korundu"da kalır (eksiklik). Amaç güvenli silme.
Üretilen dosyalar (`*.g.dart`, `app_localizations*`) silme dışıdır.

