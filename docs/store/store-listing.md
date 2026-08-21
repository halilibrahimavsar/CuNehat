# CuNehat — Play Store listing metinleri

Adım 8'in eksik parçası. Karakter sınırları Play Console'un dayattığı sert
sınırlardır; aşarsan form kaydetmez.

> ⚠️ **Politika notu:** Play'in Finansal Hizmetler politikası "kredi verme",
> "borç para verme", "faizsiz kredi" gibi ifadelerde ek beyan istiyor. Aşağıdaki
> metinlerde borç/alacak bilinçli olarak **takip** fiiliyle anlatıldı — uygulama
> finansal ürün sunmuyor, yalnız kayıt tutuyor. Bu dili bozma.

---

## ASO stratejisi — neden metinler böyle yazıldı

Play üç alanı da anahtar kelime için indeksler ama **ağırlıkları eşit değil:**
başlık > kısa açıklama > uzun açıklama. 2024–2026 arasında algoritma ayrıca
kurulum *öncesi* sinyallerden (anahtar kelime, ham indirme) kurulum *sonrası*
sinyallere (tutunma, listeden kuruluma dönüşüm) kaydı — yani metin seni arama
sonucuna sokar, **elde tutan şey ürün.**

**Bu listelemedeki en büyük tek kayıp başlıktı.** Play Console'un uygulama adı
alanı 30 karakter ve "CuNehat" bunun 7'sini kullanıp **sıfır arama hacmi**
getiriyor: kimse "CuNehat" aramıyor, çünkü kimse bilmiyor. Türkiye pazarındaki
rakiplerin tamamı ana terimi başlığa koyuyor — *Gelir Gider Takibi*,
*GiderimVar - Gelir Gider Bütçe*, *Bütçe Yönetimi Gelir & Gider*,
*Hızlı Bütçe – Gider Yöneticisi*. Marka adı tek başına başlıkta durduğu sürece
organik aramadan pay alınamaz.

> **Play Console'daki "Uygulama adı" ≠ telefondaki simge adı.** Mağaza adı
> indekslenen alandır; ana ekranda görünen isim `AndroidManifest.xml`'deki
> `android:label` (= `CuNehat`) ve **öyle kalmalı.** İkisinin farklı olması
> normaldir, kod değişikliği gerektirmez.

**Alan başına anahtar kelime paylaşımı** (aynı kelimeyi iki alanda tekrarlamak
israf; her alan yeni terim taşımalı):

| Alan | Taşıdığı terimler |
|---|---|
| Başlık | gelir, gider, takip |
| Kısa açıklama | bütçe, harcama, borç, banka ekstresi |
| Uzun açıklama | cüzdan, kredi kartı, fiş, OCR, yatırım, döviz, altın, taksit, rapor, yedek |

**Ana terimi kazan, farkı ekran görüntüsünde göster.** Bu kategoride onlarca
klon var; CuNehat'i ayıran şey **banka ekstresi okuma** (PDF/CSV/Excel + taranmış
PDF için cihaz içi OCR) — Türkiye pazarında neredeyse hiçbir rakipte yok. Ama
"ekstre" arama hacmi "gelir gider"in yanında küçük. Doğru kurgu: **aramaya ana
terimle gir, dönüşümü farkla al.**

---

## Türkçe (tr-TR — varsayılan dil)

### Uygulama adı (sınır 30) — **en ağır alan**

```
CuNehat: Gelir Gider Takibi
```

*27 karakter.* Marka + ana terim. "Gelir gider" bu kategorinin baş terimi;
"takibi" ifadeyi doğal bitiriyor.

> **Değerlendirilip elenen alternatif:** `CuNehat: Gelir Gider Bütçe` (26) bir
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
> kancayı taşımalı. Önceki açılış — *"CuNehat, paranın nereye gittiğini gerçekten
> görmek isteyenler için yapılmış bir kişisel finans defteridir."* — güzel bir
> cümleydi ama içinde tek bir aranan terim yoktu. Aşağıdaki açılış 168 karakter,
> kesmeden önce bitiyor.

```
CuNehat; gelir gider takibi, bütçe yönetimi ve borç takibi için yapılmış
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
seç. Her işleme not, etiket ve fiş fotoğrafı ekleyebilirsin.

BANKA EKSTRESİNİ İÇE AKTAR
PDF, CSV, Excel (.xls/.xlsx) ekstrelerini doğrudan oku. Taranmış PDF'ler bile
cihaz içi metin tanıma ile çözülür. Aynı işlemi iki kez eklemeni önleyen
yinelenen kayıt denetimi var; içe aktarmadan önce her satırı gözden geçirip
düzenleyebilirsin.

FİŞ FOTOĞRAFI VE OCR
Fişin fotoğrafını çek; tutar ve tarih otomatik doldurulsun. Metin tanıma
tamamen telefonunda çalışır, görsel hiçbir yere yüklenmez.

BÜTÇELER
Kategori bazında aylık bütçe belirle, aşmaya yaklaşınca uyarı al. Bütçeler
cüzdan bazlıdır — her hesabın kendi sınırı olabilir.

BORÇ VE ALACAK TAKİBİ
Kime ne kadar borçlusun, kimden ne kadar alacağın var, tek ekranda gör. Taksit
planı, faiz ve gecikme hesabı, kısmi ödeme kaydı desteklenir. Vadesi yaklaşan
kayıtlar için hatırlatma alırsın.

YİNELENEN İŞLEMLER VE HATIRLATICILAR
Kira, abonelik, maaş gibi düzenli hareketleri bir kez tanımla; zamanı gelince
hatırlatma gelsin, onayınla deftere işlensin.

YATIRIM TAKİBİ
Döviz, altın ve hisse pozisyonlarını takip et. Güncel fiyatlarla değerleme
cüzdanının para biriminde yapılır, kâr/zararını doğru para biriminde görürsün.

RAPORLAR VE GRAFİKLER
Aylık akış, kategori dağılımı, dönem karşılaştırması. Nereye ne kadar
harcadığını rakamla ve grafikle gör.

GÜVENLİK
Parmak izi / yüz tanıma veya PIN ile kilitle. Kilit uygulamanın kendisindedir,
bir hesaba bağlı değildir.

YEDEKLEME VE DIŞA AKTARMA
Google Drive'a yedekle ve geri yükle — yedek senin kendi Drive alanında,
uygulamaya özel klasörde tutulur. Ayrıca JSON ve CSV olarak dışa aktarabilirsin.
Verini istediğin an alıp gidebilirsin; dışa aktarma hiçbir zaman kilitlenmez.

TÜRKÇE VE İNGİLİZCE
Arayüz her iki dilde. Açık ve koyu tema desteği var.

---

GİZLİLİK HAKKINDA AÇIK KONUŞALIM

Bu uygulama verini satmaz, reklam ağına bağlanmaz, analitik SDK'sı taşımaz.
Finansal kayıtların telefonunun içindeki veritabanında durur. Google ile giriş
yalnızca Drive yedeğini açmak istersen sorulur ve tamamen isteğe bağlıdır —
diğer tüm özellikler girişsiz çalışır.

CuNehat bir banka ya da finans kuruluşu değildir; kredi, yatırım veya ödeme
hizmeti sunmaz. Yalnızca kendi kayıtlarını tutmana yarayan bir defterdir.
```

*2.795 karakter — sınırın rahat altında.*

---

## English (en-US — ikincil dil, isteğe bağlı)

### App name (limit 30)

```
CuNehat: Budget & Expenses
```

*26 karakter.* Aynı mantık: marka + baş terim.

> `CuNehat: Expense & Budget Tracker` doğal olurdu ama **33 karakter** — sınırı
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
CuNehat is an ad-free personal finance app for expense tracking, budgeting and
debt tracking. It reads your bank statements, and your data stays on your phone.

No ads. No subscriptions. No account required. Your data stays on your phone and
is never sent to any server.

WALLETS AND MULTI-CURRENCY
Cash, bank accounts, credit cards — create as many wallets as you need. Each
wallet works in its own currency (TRY, USD, EUR). Transfers between wallets
apply the current exchange rate automatically, and balances stay cent-accurate.

INCOME, EXPENSES AND CATEGORIES
Sort transactions into categories, create your own, pick icons and colours. Every
transaction can carry a note, a tag and a receipt photo.

BANK STATEMENT IMPORT
Read PDF, CSV and Excel (.xls/.xlsx) statements directly. Even scanned PDFs are
handled through on-device text recognition. Duplicate detection stops you adding
the same transaction twice, and you can review and edit every row before import.

RECEIPT PHOTOS AND OCR
Photograph a receipt and let the amount and date fill themselves in. Text
recognition runs entirely on your phone; the image is never uploaded.

BUDGETS
Set monthly budgets per category and get warned as you approach the limit.
Budgets are per wallet, so each account can have its own ceiling.

DEBT AND RECEIVABLE TRACKING
See who you owe and who owes you on one screen. Instalment plans, interest and
late-payment calculation, and partial payments are all supported. You get
reminders as due dates approach.

RECURRING TRANSACTIONS AND REMINDERS
Define rent, subscriptions or salary once; get reminded when they are due and
record them into the ledger with a tap.

INVESTMENT TRACKING
Track currency, gold and stock positions. Valuation uses live prices and is
reported in your wallet's currency, so profit and loss are shown in the right
unit.

REPORTS AND CHARTS
Monthly flow, category breakdown, period comparison. See where your money went,
in numbers and in charts.

SECURITY
Lock the app with fingerprint, face unlock or a PIN. The lock belongs to the app
itself and is not tied to any account.

BACKUP AND EXPORT
Back up to Google Drive and restore — the backup lives in your own Drive, in the
app's private folder. You can also export to JSON and CSV. You can take your data
and leave whenever you want; export is never locked behind a payment.

TURKISH AND ENGLISH
The interface is available in both languages, with light and dark themes.

---

A STRAIGHT WORD ABOUT PRIVACY

This app does not sell your data, does not connect to ad networks and carries no
analytics SDK. Your financial records sit in a database inside your phone.
Signing in with Google is only asked for if you choose to enable Drive backup,
and it is entirely optional — every other feature works without signing in.

CuNehat is not a bank or a financial institution and offers no credit, investment
or payment services. It is simply a ledger for keeping your own records.
```

---

## Sürüm notları — v1.0.0

### Türkçe (sınır 500)

```
CuNehat'in ilk sürümü.

Cüzdanlar ve çoklu para birimi, gelir/gider takibi, kategoriler, bütçeler,
borç ve alacak takibi, yinelenen işlemler ve hatırlatıcılar, raporlar ve
grafikler, yatırım takibi, banka ekstresi içe aktarma, fiş fotoğrafı ve OCR,
Google Drive yedekleme, biyometrik/PIN kilit.

Reklamsız ve aboneliksiz. Verilerin cihazında kalır.
```

### English (limit 500)

```
The first release of CuNehat.

Wallets and multi-currency, income and expense tracking, categories, budgets,
debt and receivable tracking, recurring transactions and reminders, reports and
charts, investment tracking, bank statement import, receipt photos with OCR,
Google Drive backup, biometric/PIN lock.

No ads, no subscriptions. Your data stays on your device.
```

---

## Ekran görüntüleri — ✅ ÜRETİLDİ (18 Ağu 2026)

**8 görsel hazır:** `docs/store/screenshots/` (`01_…` – `08_…`). Ham cihaz
çekimleri `tools/store_screenshots.py` ile 1080×1920 (tam 9:16) tuvale, marka
zemini ve başlık şeridiyle yerleştirildi.

> **Değişiklik gerekirse betikten geç, elle düzenleme:**
> `python3 tools/store_screenshots.py` (tamamı) veya
> `python3 tools/store_screenshots.py 3 5` (yalnız 3 ve 5). Şerit metni ya da
> renk değişince 8 görselin hepsi tek komutla yeniden üretilir.

**Kalan iş:** görselleri Play Console → Mağaza girişi'ne yüklemek.

Aşağıdaki bölüm görsellerin **neden bu sırada ve bu şeritlerle** üretildiğini
anlatıyor — yeniden çekmen gerekirse kadraj referansı olarak duruyor.

Play en az 2, en çok 8 telefon ekran görüntüsü istiyor.

**Metin şeridi olmadan yükleme.** Bağımsız geliştiricilerin en sık yaptığı hata
ham ekran görüntüsü yüklemek. Arama sonucunda görsel küçücük görünür; içindeki
arayüz metni okunmaz, kullanıcı ne gördüğünü anlamaz. Her görselin üstüne
**3–5 kelimelik bir başlık şeridi** koy (uygulamanın kendi renkleriyle, tek
tip). Okunan şey o şerit; ekran görüntüsü onun kanıtı.

**İlk 3 görsel arama sonucunda görünüyor** — kaydırmadan görülen tek şey onlar.
Bu yüzden sıralama, "en güzel ekran" değil **"en ikna edici üç iddia"** mantığıyla
kurulmalı. Farkı en başa koy: ekstre okuma rakiplerde yok, ana ekran ise herkeste
var.

| # | Ekran | Şerit metni (öneri) |
|---|---|---|
| 1 | **Banka ekstresi inceleme** — ayrıştırılmış satırlar | *Ekstreni oku, tek tek girme* |
| 2 | **Rapor grafiği** — kategori dağılımı | *Paran nereye gidiyor, gör* |
| 3 | **Ana ekran** — dolu cüzdan kartları | *Tüm hesapların tek ekranda* |
| 4 | **Bütçe ekranı** — ilerleme çubukları | *Bütçeni aşmadan önce uyarır* |
| 5 | **Borç/alacak** — taksit planı görünür kayıt | *Kime ne borçlusun, unutma* |
| 6 | **Fiş fotoğrafı + OCR** | *Fişi çek, tutar kendi dolsun* |
| 7 | **Yatırım listesi** — döviz/altın | *Döviz ve altın, güncel kurla* |
| 8 | **Gizlilik/yedek ayarları** | *Reklam yok. Veri telefonunda.* |

> Ekran görüntülerinde **gerçek kişisel verini gösterme.** Temiz bir kurulumda
> makul görünen örnek veri oluştur; hem mahremiyet hem de daha derli toplu
> görünüm için. Rakamlar da inandırıcı olsun — 3 işlemlik boş bir liste
> "kimse kullanmıyor" izlenimi verir.

**Tanıtım videosu (isteğe bağlı, güçlü):** Feature graphic yalnızca YouTube
tanıtım videosu eklediğinde listelemenin tepesinde görünür — video yoksa çoğu
yerleşimde hiç gösterilmez. 30 saniyelik bir ekran kaydı bile
`play-feature-graphic-1024x500.png` varlığını çalışır hale getirir.

---

## Yayın sonrası ASO kaldıraçları (v1'i bloke etmez)

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
  markalı arama ("CuNehat") için indekslenen bir dış sinyal olur. Play URL'i
  ancak yayından sonra oluşacağı için bu iş production çıkışına ertelenmeli.
