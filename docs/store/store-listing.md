# ÇuHat — Play Store listing metinleri

Adım 8'in eksik parçası. Karakter sınırları Play Console'un dayattığı sert
sınırlardır; aşarsan form kaydetmez.

> ⚠️ **Politika notu:** Play'in Finansal Hizmetler politikası "kredi verme",
> "borç para verme", "faizsiz kredi" gibi ifadelerde ek beyan istiyor. Aşağıdaki
> metinlerde borç/alacak bilinçli olarak **takip** fiiliyle anlatıldı — uygulama
> finansal ürün sunmuyor, yalnız kayıt tutuyor. Bu dili bozma.

---

## Marka adı: ÇuHat (16 Eylül 2026'ya kadar ÇuNehat)

Uygulamanın adı **ÇuHat**. 16 Eylül 2026'da ÇuNehat'tan değişti; uygulama o gün
yalnız kapalı testteydi (13 tester), halka açık bir marka geçmişi yoktu. Paket
adı ve kullanıcı verisine bağlı kimlikler DEĞİŞMEDİ (aşağıdaki ikinci tablo).

**Yazım: uygulamada `Ç`, mağaza başlığında düz `C`.**

| Nerede | Yazım |
|---|---|
| `android:label`, `MaterialApp.title`, l10n, çekmecedeki sürüm satırı, gizlilik politikası, tanıtım görseli | **ÇuHat** |
| Play Console uygulama adı (tr-TR + en-US) | **CuHat** — 30 Ağu 2026'daki düz `C` kararı, ad değişikliğinde yeniden onaylandı |

Neden başlıkta `C`: kullanıcıların çoğu telefonda harf ayarsız yazar ("cuhat")
ve Play'in Türkçe ç/c normalizasyonu garanti değil. Başlık aramanın en ağır
alanı olduğu için ASCII yazımı kesin yakalar; `Ç`'li yazım uzun açıklamanın
**ilk cümlesinde** `ÇuHat (CuHat)` olarak indeksleniyor.

**Türkçe ekler kalın ünlüyle:** `ÇuHat'ı`, `ÇuHat'a`, `ÇuHat'ın`, `ÇuHat'ta` —
"hat → hattı, hatta" gibi okunur. Eski metinler ince ek kullanıyordu
(`ÇuNehat'i`, `'e`, `'in`); ad değişikliğinde her biri tek tek düzeltildi.

**Eski adı taşıyan kalıcı kimlikler — bunlara dokunma:**

| Yer | Değer | Neden |
|---|---|---|
| `applicationId` + Kotlin paketi | `dev.halilibrahim.cunehat` | değişirse Play'de başka bir uygulama olur |
| Drive yedek öneki | `cunehat_backup` | liste sorgusu `name contains`; değişirse mevcut Drive yedekleri görünmez olur |
| Yerel yedek dosya adı | `cunehat_backup_YYYYMMDD_HHmm.json` | Drive önekiyle aynı ad; `.gitignore` bekçisi bu desene bağlı |
| Bildirim kanal kimlikleri | `cunehat_critical` / `_recurring` / `_motivational` | değişirse kullanıcının kanal ayarları kaybolur |
| MethodChannel adları | `dev.halilibrahim.cunehat/…` | iç kimlik, iki taraf birlikte değişmeli |
| Dart paketi ve tanımlayıcılar | `cunehat`, `CuNehatApp` | kod, marka değil |
| GitHub repo adı | `CuNehat` | değişirse Pages eski adresi yönlendirmez; Play'deki gizlilik politikası URL'i 404 olur |

Bu ayrım `test/branding/brand_identity_test.dart` ile kilitli: eski ad görünen
bir yerde kalırsa ya da tablodaki bir kimlik değişirse test kırılır.

**Simge `Ç` olmadı ve olmamalı.** İşaret bir "C" halkası gibi okunuyor ama
harf değil marka işaretidir. Sedilla eklemek 48dp'de kuyruk ekler ve işaretin
dış çapının tuvalin %72'si olması kuralını bozar (bkz. ikon turu notları).

---

## ASO stratejisi — neden metinler böyle yazıldı

Play üç alanı da anahtar kelime için indeksler ama **ağırlıkları eşit değil:**
başlık > kısa açıklama > uzun açıklama. 2024–2026 arasında algoritma ayrıca
kurulum *öncesi* sinyallerden (anahtar kelime, ham indirme) kurulum *sonrası*
sinyallere (tutunma, listeden kuruluma dönüşüm) kaydı — yani metin seni arama
sonucuna sokar, **elde tutan şey ürün.**

**Bu listelemedeki en büyük tek kayıp başlıktı.** Play Console'un uygulama adı
alanı 30 karakter ve marka adı bunun 5'ini kullanıp **sıfır arama hacmi**
getiriyor: kimse "ÇuHat" aramıyor, çünkü kimse bilmiyor. Türkiye pazarındaki
rakiplerin tamamı ana terimi başlığa koyuyor — *Gelir Gider Takibi*,
*GiderimVar - Gelir Gider Bütçe*, *Bütçe Yönetimi Gelir & Gider*,
*Hızlı Bütçe – Gider Yöneticisi*. Marka adı tek başına başlıkta durduğu sürece
organik aramadan pay alınamaz.

**Alan başına anahtar kelime paylaşımı** (aynı kelimeyi iki alanda tekrarlamak
israf; her alan yeni terim taşımalı):

| Alan | Taşıdığı terimler |
|---|---|
| Başlık | gelir, gider, takip |
| Kısa açıklama | bütçe, harcama, borç, banka ekstresi |
| Uzun açıklama | cüzdan, kredi kartı, fiş, OCR, yatırım, döviz, altın, taksit, rapor, yedek |

**Ana terimi kazan, farkı ekran görüntüsünde göster.** Bu kategoride onlarca
klon var; ÇuHat'ı ayıran şey **banka ekstresi okuma** (PDF/CSV/Excel + taranmış
PDF için cihaz içi OCR) — Türkiye pazarında neredeyse hiçbir rakipte yok. Ama
"ekstre" arama hacmi "gelir gider"in yanında küçük. Doğru kurgu: **aramaya ana
terimle gir, dönüşümü farkla al.**

---

## Türkçe (tr-TR — varsayılan dil)

### Uygulama adı (sınır 30) — **en ağır alan**

```
CuHat: Gelir Gider Takibi
```

*25 karakter.* Marka (düz `C`, bkz. *Marka adı*) + ana terim. "Gelir gider" bu kategorinin baş terimi;
"takibi" ifadeyi doğal bitiriyor.

> **Değerlendirilip elenen alternatif:** `CuHat: Gelir Gider Bütçe` (24) bir
> baş terim daha taşıyor ama arama sonucunda anahtar kelime yığını gibi okunuyor.
> Dönüşüm artık sıralamada anahtar kelimeden ağır bastığı için okunabilirlik
> seçildi. İlk kurulumlar geldikten sonra Play Console'un **listeleme deneyleri**
> (ücretsiz A/B) ile ikisini karşılaştır — o zaman tahmin değil ölçüm olur.

### Kısa açıklama (sınır 80)

```
Bütçe, harcama, borç takibi; banka ekstresi okur. Verileriniz cihazınızda.
```

*74 karakter.* Başlıkta olmayan dört terimi taşıyor: bütçe, harcama, borç,
banka ekstresi. Sonundaki gizlilik ifadesi dönüşüm için duruyor.

> **Önceki metin:** `Reklamsız kişisel finans: cüzdan, bütçe, borç takibi. Verin
> cihazında kalır.` (76) — mağazanın **ikinci en ağır** alanının ilk kelimesini
> "Reklamsız"a veriyordu. "Reklamsız" bir satış argümanı ama arama terimi değil;
> baş terimler ("harcama", "gelir gider") hiç geçmiyordu. Reklamsızlık artık
> uzun açıklamanın 3. satırında, yeri orası.

### Uzun açıklama (sınır 4000)

> **Açılıştaki ilk ~170 karakter kritik:** Play listelemede metni orada kesip
> "Devamını oku" koyuyor. Kesilmeden önce görünen kısım hem baş terimleri hem
> kancayı taşımalı. Aşağıdaki açılış **165 karakter** ve cümle sınırında
> bitiyor; parantezli `(CuHat)` de oraya sığdı, yani ikinci yazım da
> indekseniyor.

```
ÇuHat (CuHat); gelir gider takibi, bütçe ve borç takibi için yapılmış
reklamsız bir kişisel finans uygulamasıdır. Banka ekstrenizi okur, veriler
telefonunuzda kalır.

Reklam yok. Abonelik yok. Hesap açma zorunluluğu yok. Verilerin telefonunda
kalır ve hiçbir sunucuya gönderilmez.

CÜZDANLAR VE ÇOKLU PARA BİRİMİ
Nakit, banka hesabı, kredi kartı — ihtiyacın kadar cüzdan oluştur. Her cüzdan
kendi para biriminde çalışır (TL, dolar, euro). Cüzdanlar arası transferlerde
güncel kur otomatik uygulanır, bakiyeler kuruşu kuruşuna tutar.

GELİR, GİDER VE KATEGORİLER
İşlemlerini kategorilere ayır, kendi kategorilerini oluştur, ikonunu ve rengini
seç. Her işleme not, etiket ve fiş fotoğrafı ekleyebilirsin. Kategorilerin yan
menüde kendi sayfası var; her cüzdan yalnız kendi kategori kümesini gösterir.

BANKA EKSTRESİNİ İÇE AKTAR
PDF, CSV, Excel (.xls/.xlsx) ekstrelerini doğrudan oku. Taranmış PDF'ler bile
cihaz içi metin tanıma ile çözülür. Okunan tutarlar ekstrenin kendi bakiye ve
toplam bilgileriyle aritmetik olarak doğrulanır. Aynı işlemi iki kez eklemeni
önleyen yinelenen kayıt denetimi var; içe aktarmadan önce her satırı gözden
geçirip düzenleyebilirsin.

FİŞ FOTOĞRAFI VE OCR
Fişin fotoğrafını çek; tutar ve tarih otomatik doldurulsun. Metin tanıma
tamamen telefonunda çalışır, görsel hiçbir yere yüklenmez.

BÜTÇELER
Kategori bazında aylık bütçe belirle, limitin %80'ini geçince bildirim al,
aşarsan listede kırmızıyla gör. Bütçeler cüzdan bazlıdır — her hesabın kendi
sınırı olabilir.

BORÇ VE ALACAK TAKİBİ
Kime ne kadar borçlusun, kimden ne kadar alacağın var, tek ekranda gör. Taksit
planı, faiz ve gecikme hesabı, kısmi ödeme kaydı desteklenir. Vadesi yaklaşan
kayıtlar için hatırlatma alırsın.

YİNELENEN İŞLEMLER VE HATIRLATICILAR
Kira, abonelik, maaş gibi düzenli hareketleri bir kez tanımla; zamanı gelince
hatırlatma gelsin, onayınla deftere işlensin.

BİRİKİM HEDEFLERİ VE YATIRIM TAKİBİ
Döviz, altın, hisse ve fon pozisyonlarını takip et; istediklerini bir birikim
hedefine bağla, ilerlemeyi tek bakışta gör. Güncel fiyatlarla değerleme
cüzdanının para biriminde yapılır, kâr/zararını doğru para biriminde görürsün.

RAPORLAR VE GRAFİKLER
Aylık akış, kategori dağılımı, dönem karşılaştırması. Nereye ne kadar
harcadığını rakamla ve grafikle gör.

GÜVENLİK
Parmak izi / yüz tanıma veya PIN ile kilitle. Kilit uygulamanın kendisindedir,
bir hesaba bağlı değildir. PIN'ini unutursan veri gitmez: cihaz kilidinle
açabilir ya da 24 saat gecikmeli sıfırlama isteyebilirsin.

YEDEKLEME VE DIŞA AKTARMA
Google Drive'a yedekle ve geri yükle — yedek senin kendi Drive alanında,
uygulamaya özel klasörde tutulur. Ayrıca JSON ve CSV olarak dışa aktarabilirsin.
Verini istediğin an alıp gidebilirsin; dışa aktarma hiçbir zaman kilitlenmez.

TÜRKÇE VE İNGİLİZCE
Arayüz her iki dilde; hazır kategori adları uygulamanın diline göre kurulur.
Açık ve koyu tema desteği var.

---

GİZLİLİK HAKKINDA AÇIK KONUŞALIM

Bu uygulama verini satmaz, reklam ağına bağlanmaz, analitik SDK'sı taşımaz.
Finansal kayıtların telefonunun içindeki veritabanında durur. Google ile giriş
yalnızca Drive yedeğini açmak istersen sorulur ve tamamen isteğe bağlıdır —
diğer tüm özellikler girişsiz çalışır.

ÇuHat bir banka ya da finans kuruluşu değildir; kredi, yatırım veya ödeme
hizmeti sunmaz. Yalnızca kendi kayıtlarını tutmana yarayan bir defterdir.
```

*~3.340 karakter — sınırın rahat altında.*

---

## English (en-US — ikincil dil, isteğe bağlı)

### App name (limit 30)

```
CuHat: Budget & Expenses
```

*24 karakter.* Aynı mantık: marka + baş terim. Marka İngilizce listelemede de
TR başlıktaki gibi düz `C` ile — iki dilde tek karar.

> `CuHat: Expense & Budget Tracker` doğal olurdu ama **31 karakter** — sınırı
> aşıyor, Console kaydetmez. "Tracker" kelimesini kısa açıklamaya bırak.

### Short description (limit 80)

```
Expense tracker, budgets, debts and bank statement import. Ad-free, private.
```

*76 karakter.* Başlıkta olmayan terimleri taşıyor: tracker, debts, bank
statement import.

> **Önceki metin:** `Ad-free personal finance: wallets, budgets, debt tracking.
> Data stays private.` (78) — Türkçedeki hatanın aynısı, en ağır ikinci alanı
> "Ad-free" ile açıyordu. (Not: ilk taslak "…stays on device." tam 80'di —
> sınıra yapışık metin, Console'da tek bir görünmez boşlukta kaydı reddettirir.)

### Long description (limit 4000)

```
ÇuHat (CuHat) is an ad-free personal finance app for expense tracking,
budgeting and debt tracking. It reads your bank statements, and your data stays
on your phone.

No ads. No subscriptions. No account required. Your data stays on your phone and
is never sent to any server.

WALLETS AND MULTI-CURRENCY
Cash, bank accounts, credit cards — create as many wallets as you need. Each
wallet works in its own currency (TRY, USD, EUR). Transfers between wallets
apply the current exchange rate automatically, and balances stay cent-accurate.

INCOME, EXPENSES AND CATEGORIES
Sort transactions into categories, create your own, pick icons and colours. Every
transaction can carry a note, a tag and a receipt photo. Categories have their
own page in the side menu, and each wallet shows only its own set.

BANK STATEMENT IMPORT
Read PDF, CSV and Excel (.xls/.xlsx) statements directly. Even scanned PDFs are
handled through on-device text recognition. The amounts read are checked
arithmetically against the statement's own balance and total lines. Duplicate
detection stops you adding the same transaction twice, and you can review and
edit every row before import.

RECEIPT PHOTOS AND OCR
Photograph a receipt and let the amount and date fill themselves in. Text
recognition runs entirely on your phone; the image is never uploaded.

BUDGETS
Set monthly budgets per category, get notified when you pass 80% of the limit,
and see it in red once you go over. Budgets are per wallet, so each account can
have its own ceiling.

DEBT AND RECEIVABLE TRACKING
See who you owe and who owes you on one screen. Instalment plans, interest and
late-payment calculation, and partial payments are all supported. You get
reminders as due dates approach.

RECURRING TRANSACTIONS AND REMINDERS
Define rent, subscriptions or salary once; get reminded when they are due and
record them into the ledger with a tap.

SAVINGS GOALS AND INVESTMENT TRACKING
Track currency, gold, stock and fund positions, and tie any of them to a savings
goal to watch the progress at a glance. Valuation uses live prices and is
reported in your wallet's currency, so profit and loss are shown in the right
unit.

REPORTS AND CHARTS
Monthly flow, category breakdown, period comparison. See where your money went,
in numbers and in charts.

SECURITY
Lock the app with fingerprint, face unlock or a PIN. The lock belongs to the app
itself and is not tied to any account. Forgetting your PIN doesn't cost you your
data: unlock with your device lock, or request a 24-hour delayed reset.

BACKUP AND EXPORT
Back up to Google Drive and restore — the backup lives in your own Drive, in the
app's private folder. You can also export to JSON and CSV. You can take your data
and leave whenever you want; export is never locked behind a payment.

TURKISH AND ENGLISH
The interface is available in both languages, and built-in category names are
created in your app language. Light and dark themes are supported.

---

A STRAIGHT WORD ABOUT PRIVACY

This app does not sell your data, does not connect to ad networks and carries no
analytics SDK. Your financial records sit in a database inside your phone.
Signing in with Google is only asked for if you choose to enable Drive backup,
and it is entirely optional — every other feature works without signing in.

ÇuHat is not a bank or a financial institution and offers no credit, investment
or payment services. It is simply a ledger for keeping your own records.
```

---

## Sürüm notları — v1.0.0

### Türkçe (sınır 500)

```
ÇuHat'ın ilk sürümü.

Cüzdanlar ve çoklu para birimi, gelir/gider takibi, kategoriler, bütçeler,
borç ve alacak takibi, yinelenen işlemler ve hatırlatıcılar, raporlar ve
grafikler, birikim hedefleri ve yatırım takibi, banka ekstresi içe aktarma,
fiş fotoğrafı ve OCR, Google Drive yedekleme, biyometrik/PIN kilit.

Reklamsız ve aboneliksiz. Verilerin cihazında kalır.
```

### English (limit 500)

```
The first release of ÇuHat.

Wallets and multi-currency, income and expense tracking, categories, budgets,
debt and receivable tracking, recurring transactions and reminders, reports and
charts, savings goals and investment tracking, bank statement import, receipt
photos with OCR, Google Drive backup, biometric/PIN lock.

No ads, no subscriptions. Your data stays on your device.
```

---

## Sürüm notları — 1.0.0 (versionCode 3)

Kapalı testin 3. gününde çıkan ilk güncelleme. Kapsam: `edab5a1..6c9f534`
(ekstre gruplama + alt kategori eşleme, kategori seçici, Drive hata ayrımı).
Hive şeması ve `schemaVersion` **değişmedi (9)** — testerların mevcut verisi ve
Drive'daki yedekleri olduğu gibi çalışır.

### Türkçe (492 karakter, sınır 500)

```
Banka ekstresi
• Benzer hareketler gruplanıyor; grubun tamamına tek seferde kategori atanıyor.
• Otomatik tahmin artık alt kategorileri de eşleştiriyor.
• Türkçe harf hataları giderildi: banka adları tanınıyor, aynı hareket ikinci kez eklenemiyor.

Kategori seçimi
• Seçim işlem formuna taşındı: iki sütunlu, aranabilir, son kullandıkların üstte.
• İşlem kartında kazara silmeye yol açan kaydırma kaldırıldı.

Google Drive
• Yedekleme hataları artık gerçek nedeni ve doğru çözümü gösteriyor.
```

### English (485 karakter, sınır 500)

```
Bank statement import
• Similar transactions are grouped; categorize a whole group at once.
• Auto-detection now matches subcategories too.
• Fixed Turkish letter casing: bank names are recognized, and the same transaction can no longer be imported twice.

Category picking
• Moved into the transaction form: two columns, searchable, recently used first.
• Removed the card swipe that caused accidental deletes.

Google Drive
• Backup errors now show the real cause and the right fix.
```

---

## Sürüm notları — 1.0.0 (versionCode 4)

Kapalı testin 8. gününde çıkan ikinci güncelleme. Kapsam: `v1.0.0+3..HEAD`
(Rapor sayfası elden geçirmesi, İçgörü turu, erişilebilirlik turu, İşlemler
ekranının tek akışa inmesi). Hive şeması ve `schemaVersion` **değişmedi (9)** —
testerların mevcut verisi ve Drive'daki yedekleri olduğu gibi çalışır.

> 500 karakterlik sınır bu aralığın tamamını saymaya yetmiyor; notlar
> testerın EKRANDA göreceği değişikliklere göre yazıldı. Perf ve test
> işleri (memoize, epoch kova araması, smoke testleri) anılmıyor.

### Türkçe (471 karakter, sınır 500)

```
İşlemler ekranı yeniden tasarlandı
• Tek akış: dönem özeti, gün şeridi ve yapışkan gün başlıklı liste bir arada.
• Bir güne dokun, liste oraya gitsin; dönem değişmesin.
• Kartta ⋮ menüsü — düzenle ve sil yeniden görünür.

Raporlar ve İçgörüler
• Zaman ekseni artık gerçek takvim; transfer ve borç ödemesi harcama sayılmıyor.
• Ana/alt kategori dağılımı, aylık seyir, bütçe özeti.
• Göz düğmesi tüm sayfaları gizliyor.

Erişilebilirlik: ekran okuyucu desteği geliştirildi.
```

### English (482 karakter, sınır 500)

```
Transactions screen redesigned
• One flow: period summary, day strip and a list with sticky day headers.
• Tap a day and the list jumps there, without changing the period.
• Card ⋮ menu — edit and delete are visible again.

Reports and Insights
• A real calendar time axis; transfers and debt payments no longer count as spending.
• Category/subcategory breakdown, monthly trend, budget summary.
• The eye button now hides every page.

Accessibility: improved screen reader support.
```

---

## Sürüm notları — 1.0.0 (versionCode 5)

Kapalı testin 12. gününde çıkan üçüncü güncelleme. Kapsam: `v1.0.0+4..HEAD`
(23 commit) — cüzdana göre kategori görünürlüğü, kategorilerin kendi sayfası,
kategori adlarının anahtarla yerelleşmesi, PIN kurtarma + çift biyometrik
düzeltmesi, edge-to-edge yerleşim ve 11 maddelik para doğruluğu turu.

> ⚠️ **Bu turda şema DEĞİŞTİ:** yedek `schemaVersion` **9 → 10**
> (`WalletModel` alan 14 = `categoryIds`). Sürüm kapısı sıkı eşitlikten
> **migrasyon zincirine** döndü: testerların `+4` ile aldığı v9 yedekleri
> `migrateBackup` ile v10'a yükseltilip geri yükleniyor
> (`oldestSupportedBackupVersion = 9`). Hive tarafında eski kayıtlar alan 14'ü
> taşımaz → `null` = "kürasyon yok, hepsi görünür", yani mevcut cüzdanlarda
> davranış değişmiyor. Kullanıcıya duyurulacak bir şey olmadığı için sürüm
> notlarında yer almıyor.

> Kapsamın tamamı 500 karaktere sığmıyor; notlar testerın EKRANDA göreceği
> değişikliklere göre yazıldı. Sertleştirme ve test işleri (eski-kayıt
> adapter'ları, kayıt sırası kilidi) anılmıyor.

### Türkçe (469 karakter, sınır 500)

```
Kategoriler artık senin
• Yan menüde kendi sayfası var; her cüzdan yalnız kendi kategorilerini gösteriyor.
• Kategori adları uygulamanın diline göre kuruluyor.

Şifreni unutursan
• PIN kurtarma eklendi: cihaz kilidinle aç ya da 24 saat gecikmeli sıfırlama iste.
• Biyometrik artık iki kez sormuyor; dosya seçerken kilit ekranı çıkmıyor.

Rakamlar
• Transferler gider sayılmıyor; rapor, bütçe ve içgörü aynı sonucu veriyor.
• Çoklu cüzdan ve döviz toplamları düzeltildi.
```

### English (485 karakter, sınır 500)

```
Categories are yours now
• Their own page in the side menu; each wallet shows only its own set.
• Category names are created in your app language.

If you forget your PIN
• PIN recovery added: unlock with your device lock, or request a 24-hour delayed reset.
• Biometrics no longer asks twice; the lock screen no longer appears while picking a file.

Numbers
• Transfers no longer count as spending — report, budget and insights agree.
• Multi-wallet and foreign-currency totals fixed.
```

---

## Sürüm notları — 1.0.0 (versionCode 6)

Ad değişikliği sürümü (16 Eyl 2026): **ÇuNehat → ÇuHat**. Kapsam `76683c2..`
(`+5` hazırlığından sonrası): bildirim sağlamlığı, rapor dönem çubuğu, borçta
göz düğmesi, ekstre 12. tur, çalışma zamanı hata denetimi (5 kısım) ve ad
değişikliği. Şema DEĞİŞMEDİ (`schemaVersion` 10). İki yeni tercih anahtarı var
(`app_auth_lock_configured`, `error_log_v1`); ikisi de yoksa güvenli varsayılana
düşer.

> ⚠️ Notlar testerların `+5`'i aldığını varsayar. Testerlarda hâlâ `+4` varsa
> `+5` notlarının "Kategoriler artık senin" ve "Şifreni unutursan" bölümleri de
> girmeli; 500 sınırı için "Banka ekstresi" bölümü tek maddeye indirilir.

### Türkçe (476 karakter, sınır 500)

```
Uygulamanın yeni adı: ÇuHat
• Aynı uygulama; verilerin, yedeklerin ve ayarların yerinde.

Hatırlatmalar
• Vadesi geçen kayıt için hatırlatma her sabah yeniden gelir.

Banka ekstresi
• İkinci içe aktarımda kategori tahmini düzeldi; elle girdiğin kayıt tekrar olarak yakalanıyor.
• Kaydederken geri basınca içe aktarım yarıda kalmıyor.

Güvenlik ve kararlılık
• PIN'li uygulama her koşulda kilitli açılır.
• Takılan yükleme ekranları düzeldi; hata günlüğü Ayarlar → Hakkında'da.
```

### English (472 karakter, sınır 500)

```
The app has a new name: ÇuHat
• Same app; your data, backups and settings stay as they are.

Reminders
• Overdue items now remind you again every morning.

Bank statements
• Category guesses on a second import are fixed; entries you added by hand are caught as duplicates.
• Pressing back while saving no longer interrupts the import.

Security and stability
• A PIN-protected app always opens locked.
• Stuck loading screens fixed; an error log is under Settings → About.
```

---

## Ekran görüntüleri — ✅ ÜRETİLDİ (son çekim 9 Eyl 2026)

**8 görsel hazır:** `docs/store/screenshots/` (`01_…` – `08_…`). Ham cihaz
çekimleri `tools/store_screenshots.py` ile 1080×1920 (tam 9:16) tuvale, marka
zemini, başlık şeridi ve **özellik çipleriyle** yerleştirildi.

> **Değişiklik gerekirse betikten geç, elle düzenleme:**
> `python3 tools/store_screenshots.py` (tamamı) veya
> `python3 tools/store_screenshots.py 3 5` (yalnız 3 ve 5). Şerit metni ya da
> renk değişince 8 görselin hepsi tek komutla yeniden üretilir.

**Kalan iş:** görselleri Play Console → Mağaza girişi'ne yüklemek.

> ⚠️ **3. kare (`03_rapor.png`) yükleme öncesi YENİDEN ÇEKİLMELİ.** Rapor
> sayfasının dönem kontrolü tek satırlık ay çubuğuna indi ve sayfa başlığı
> kalktı; karedeki "01 Ağu 2026 - 31 Ağu 2026" bloğu ile çip satırı artık
> uygulamada yok. Çipin "Aylık seyir" olan üçüncü sırası da düzeltildi
> (o kart silindi) — betikteki metin güncel, üretilecek kare değil.

### Kare başına bir EKRAN değil, bir KATEGORİ

Play telefon için en fazla 8 görsel alıyor. İlk sürümde 8 karede 8 ekran vardı,
yani 23 yetenek alanının 6'sı anlatılıyordu. Şimdi her kare bir **tema** ve
başlığın altında o temanın özelliklerini adıyla sayan bir **çip satırı** var:
ekran sayısı sabit kalırken anlatılan özellik sayısı 8'den **24'e** çıktı.

Çipler karenin **temsil ettiği** kategorinin özelliklerini adlandırır, illa o
karede piksel olarak görüneni değil — ama uygulamada **gerçekten bulunmalı** ve
o kategoriye ait olmalı. Olmayan bir özelliği çipe yazmak Play politikasında
yanıltıcı beyandır; "Reklam yok" gibi iddialar da Data safety formundaki
beyanla birebir uyuşmalı.

### Sıra: tanınma → farklılaşma → derinlik → güven

**İlk 3 görsel arama sonucunda görünüyor** — kaydırmadan görülen tek şey onlar.

| # | Ekran | Şerit | Çipler |
|---|---|---|---|
| 1 | İşlem defteri | *Gelir ve giderin **tek defterde*** | Gün gün döküm · Arama ve filtre · Çoklu cüzdan |
| 2 | Banka ekstresi inceleme | *Ekstreni at, **satırlar hazır** gelsin* | PDF ve Excel · Fotoğraftan OCR · Aritmetik doğrulama |
| 3 | Rapor | *Paran **nereye** gitti?* | Kategori çemberi · Dönem karşılaştırma · Gelir–gider akışı |
| 4 | Birikim hedefleri | *Hedefini kur, **varlıklarını** bağla* | Altın, hisse ve fon · Canlı fiyat · Kâr/zarar takibi |
| 5 | Bütçe | *Bütçeni **aşınca** hemen gör* | Kategori limitleri · Aşım uyarısı · Cüzdan bazlı bütçe |
| 6 | Borç/alacak | *Borcunu ve alacağını **unutma*** | Taksit ve vade · Kısmi ödeme · Gecikme faizi |
| 7 | Düzenli işlemler | *Kira, maaş, abonelik — **kendiliğinden** gelsin* | Aylık şablonlar · Onay bekleyenler · Bildirim hatırlatması |
| 8 | Gizlilik / yedek | *Verilerin **sende** kalır* | Google Drive yedeği · CSV dışa aktarım · Reklam yok |

> **Set 9 Eylül 2026'da (`+5` yüklemesinden hemen önce) YENİDEN çekildi.**
> Kural şu: kare/çip denetimi kod değişince değil **her yayın öncesi** yapılır.
> Bu turda denetimin karşılığı çıktı — üç kare uygulamanın güncel hâlini
> göstermiyordu:
>
> 1. **1. kare artık ÜRETİLEMEYEN rakamlar gösteriyordu.** 6 Eylül karesinde
>    ana ekran özeti "↑103.750,00 ↓77.995,53 · net 25.754,47" diyordu; aynı
>    veriyle bugünkü sürüm "↑99.750,00 ↓59.375,53 · net 40.374,47" ve altında
>    "4 kuplaj hareketi (transfer, borç, yatırım) sayılmadı" satırı var
>    (`59c9d63`). Yani vitrindeki rakam yalnız eski değil, **düzeltilmiş bir
>    hatanın çıktısıydı**: transferler gider sayılıyordu. Ölçüm bunu kanıtlıyor
>    — eski karedeki 59.375,53 rakamı zaten 3. karenin (rapor) gider toplamıydı;
>    rapor doğruydu, defter değildi.
> 2. **4. karedeki hedef kartları değişti** (`5270587`): kart artık kategori
>    adını da yazıyor ("Ev / Ev Peşinatı"), yatırım kartı alım tarihi ve
>    maliyeti taşıyor. Eski kare bu satırların hiçbirini göstermiyordu.
> 3. **Geri kalan 5 kare de yeniden çekildi**, çünkü set içi tutarlılık
>    kırılırdı: demo veri tarihe göreli üretiliyor ve üst çubuktaki bakiye
>    6 Eylül'de 98.651,64 ₺, 9 Eylül'de 105.201,30 ₺. Karışık set, carousel'de
>    yan yana iki farklı bakiye demek olurdu.
>
> Kompozisyon iyileştirmeleri: 4. kare artık "Hedeflerim" başlığıyla başlıyor
> (eskisi kartın ortasından başlıyordu), 5. karede AppBar daraltılıp "1 bütçe
> aşıldı" rozeti kadrajın en üstüne alındı, 8. karede bölüm başlığı yerine
> doğrudan Drive kartı görünüyor.
>
> **Demo veride tek düzeltme:** hedef adı "Acil Fon" iken kategori adı da
> "Acil Fon" olduğu için kart bunu iki kez yazıyordu → ad "Yastık Altı" oldu
> (`tools/make_demo_backup.py`). Üreteç tohumlu (`Random(20260821)`), yani
> yeniden üretmek aynı tarihte aynı rakamları veriyor — bu düzeltme başka
> hiçbir kareyi etkilemedi.
>
> **Denetimin ikinci yarısı — 24 çipin tamamı koda karşı kontrol edildi;
> hepsi karşılığını buluyor.** `+4`'ten beri hiçbir özellik silinmedi
> (silinen tek dosya `local_auth_settings_page.dart`, yerine güvenlik ekranı
> uygulama tarafına yeniden yazıldı). `+5` ile GELEN üç özellik — cüzdana göre
> kategori görünürlüğü ve kategorilerin kendi sayfası, PIN kurtarma, kategori
> adlarının dile göre kurulması — 8 karelik yuvada yer bulamadı; uzun
> açıklamada da yoklar. Bkz. aşağıdaki "Uzun açıklamada eksik kalanlar".

> **Set 6 Eylül 2026'da tamamen yeniden çekildi.** İki sebep vardı ve ikincisi
> ilkinden ağır:
>
> 1. **1. karenin çipi yalan söylüyordu.** "Takvim görünümü" yazıyordu; o
>    görünüm `bb8fcbb` (işlemler tek akışa indi) ile **silindi**
>    (`transaction_calendar_view.dart` artık yok), yerine gün şeridi geldi.
>    Vitrinde olmayan bir özelliği adlandırmak Play'de yanıltıcı beyandır.
> 2. **Ham kaynak çekimler kaybolmuştu** (`~/Masaüstü/cunehat emulator shots`
>    silinmiş) — betik tek bir kareyi bile yeniden üretemiyordu. Yani "yalnız
>    bozuk kareyi düzelt" seçeneği pratikte yoktu.
>
> Aynı turda **portföy karesi yerini rapora bıraktı.** Rapor sayfası iki turda
> baştan yazıldı (iki halkalı kategori çemberi, dönem karşılaştırma, aylık
> seyir) ve sette hiç temsil edilmiyordu; birikim tarafını 4. kare zaten
> anlatıyor, portföyün üç iddiası oradaki çiplerde duruyor.

> **1. kare neden defter, ekstre değil?** Önceki sürümde bu dokümanda "farkı en
> başa koy" yazıyordu ve ekstre 1. sıradaydı. Arama sonucundaki ilk karenin işi
> farklılaşma değil **tanınma**: ayrıştırılmış ekstre satırları yoğun ve yabancı
> bir ekran, net durumlu defter ise anında "bu benim para uygulamam" dedirtiyor.
> Fark 2. karede, kaydırmadan hâlâ görünür yerde duruyor.

### Yeniden çekerken düşülen tuzaklar (ölçüldü, 26 Ağu 2026)

- **Durum çubuğu kırpması ekranın içini yiyebiliyor.** `STATUS_BAR` 108'ken
  başlıktaki cüzdan rozeti (kaynakta y≈67–120) ikiye bölünüyor ve geriye render
  hatası gibi duran boş bir yay kalıyordu; aynı kırpma "Banka Ekstresi **İ**çe
  Aktar" başlığında İ'nin noktasını (y≈100–107) kesip cihazda "Içe" okutuyordu.
  Ölçülen doğru değer **52**. Değiştirmeden önce ölç.
- **Yarı kaydırılmış çekim.** Hedefler ve Ayarlar kareleri ilk turda app bar'ın
  altında yarım kart dilimiyle çekilmişti. Çekimden önce listeyi en üste al ya
  da bölümü başlığıyla hizala.
- **Demo veride gerçek kişi adı.** Kişisel borcun karşı tarafı geliştiricinin
  kendi adıydı; jenerikleştirildi (`tools/make_demo_backup.py`).
- **Boş sekme "kimse kullanmıyor" izlenimi veriyor.** Düzenli işlemler karesi 2
  kalemle ekranın %60'ını boş bırakıyordu; üreteç 7 şablon (2 bekleyen +
  5 yaklaşan) üretecek şekilde genişletildi.
- **Şerit, karenin kanıtlayabildiğinden fazlasını iddia etmemeli.** Bütçe
  şeridi "aşmadan **önce** uyarır" diyordu ama karede "1 bütçe aşıldı" rozeti
  ve kırmızı çubuk vardı; üstelik kartın "limite yaklaşıyor" görsel durumu
  uygulamada yok (%80 uyarısı bildirim olarak çıkıyor). Şerit karenin gösterdiği
  iddiaya çekildi, %80 sözü alt satıra taşındı.
- **Ekstre karesinde kategorisiz satır bırakma.** İlk denemede 11 satır
  "KIRTASIYE ODEMESI" olduğu için kategorisiz kalıyor, karede kırmızı bir
  "11 kategorisiz" rozeti ve pasif bir "Ekle" düğmesi görünüyordu. Kök neden
  demo veri değil **uygulamaydı**: `CategoryGuesser` sözlüğü yalnız marka adı
  taşıyordu, bankaların yazdığı jenerik karşılıklar (kirtasiye/kuafor/berber)
  yoktu. Sözlüğe eklendi, testle kilitlendi.
- **Debug yapısına özel kartlar kadraja girmesin.** Ayarlar'daki "Bildirim
  duman testi (yalnız debug)" kartı release'de yok; gizlilik karesi bölüm
  başlığıyla hizalanarak kadraj dışında bırakıldı.

> Ekran görüntülerinde **gerçek kişisel verini gösterme.** `make_demo_backup.py`
> tam bunun için var: inandırıcı ama tamamen uydurma bir defter üretiyor ve
> içinde tek bir gerçek marka adı yok (üçüncü taraf markası Play incelemesinde
> fikri mülkiyet itirazına açık alan bırakır).

**Tanıtım videosu (isteğe bağlı, güçlü):** Feature graphic yalnızca YouTube
tanıtım videosu eklediğinde listelemenin tepesinde görünür — video yoksa çoğu
yerleşimde hiç gösterilmez. 30 saniyelik bir ekran kaydı bile
`play-feature-graphic-1024x500.png` varlığını çalışır hale getirir.
Grafiğin yazı bloğu `tools/make_feature_graphic.py` ile yeniden üretilebilir
(işaret ve zemin korunur, yalnız kelime işareti yeniden çizilir).

---

## Uzun açıklamada eksik kalanlar — ✅ KAPANDI (16 Eyl 2026)

9 Eylül denetiminde uygulamada olup uzun açıklamada olmayan üç özellik —
kategorilerin kendi sayfası ve cüzdana göre görünürlüğü, PIN kurtarma, hazır
kategori adlarının dile göre kurulması — ad değişikliği turunda yukarıdaki TR ve
EN uzun açıklamalara taşındı. Console'a yeni başlıkla aynı gönderimde girer.

**Neden karelere girmedi:** 8 telefon yuvasının tamamı dolu ve mevcut sekiz
tema (defter, ekstre, rapor, birikim, bütçe, borç, düzenli, gizlilik) bu üç
özellikten daha yüksek dönüşüm taşıyor. PIN kurtarma güven tarafına ait ve 8.
karenin çipleri zaten dolu; tablet görselleri eklenirken (aşağıdaki liste)
9./10. bir kare açılırsa ilk aday **güvenlik ekranı** olur.

---

## Yayın sonrası ASO kaldıraçları (v1'i bloke etmez)

- **Tablet görselleri yok.** Play, büyük ekran vitrininde 7"/10" ekran görüntüsü
  olmayan uygulamaları geri plana atıyor. Telefon yayınını bloke etmez; ilk
  güncellemede eklenmeli.
- **Listeleme deneyleri (Store listing experiments).** Play Console'da ücretsiz
  yerleşik A/B testi: simge, kısa açıklama ve ilk ekran görüntüsü için ayrı ayrı
  varyant koşturulur. **Trafik gerektirir** — sıfır kurulumla anlamlı sonuç
  vermez, o yüzden lansmanda değil ilk birkaç yüz kurulumdan sonra aç. İlk
  denenecek: başlıktaki `Takibi` ↔ `Bütçe` varyantı.
- **Yorumlar indeksleniyor.** Kullanıcı yorumlarının metni de arama eşleşmesine
  giriyor. Kapalı testteki 12 kişi production çıkışında yorum bırakabilir;
  onlardan yorum *istemek* meşru, **ne yazacaklarını söylemek değil** — yönlendirilmiş
  yorum Play politikasını ihlal eder ve listelemeyi riske atar.
- **Tutunma = sıralama.** 2024 sonrası algoritma kurulum sonrası sinyallere
  kaydı; 1./7./30. gün tutunma ham indirme sayısından daha belirleyici. Bu,
  monetizasyon kararındaki "ölçüt para değil 30 günlük tutunma" ilkesiyle
  aynı yöne bakıyor — ayrı bir iş değil.
- **Güncelleme sıklığı bir sinyal.** Terk edilmiş görünen uygulamalar geriliyor.
  Kapalı test boyunca sürüm atmak sayacı bozmuyor (bkz. RELEASE_GUIDE Adım 11),
  üstelik bu sinyali besliyor.
- **Site zaten var, tam kullanılmıyor.** `docs/index.html` şu an yalnız gizlilik
  politikasına link veriyor. Play bağlantısı + ekran görüntüleri eklenirse
  markalı arama ("ÇuHat") için indekslenen bir dış sinyal olur. Play URL'i
  ancak yayından sonra oluşacağı için bu iş production çıkışına ertelenmeli.
