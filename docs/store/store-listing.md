# ÇuNehat — Play Store listing metinleri

Adım 8'in eksik parçası. Karakter sınırları Play Console'un dayattığı sert
sınırlardır; aşarsan form kaydetmez.

> ⚠️ **Politika notu:** Play'in Finansal Hizmetler politikası "kredi verme",
> "borç para verme", "faizsiz kredi" gibi ifadelerde ek beyan istiyor. Aşağıdaki
> metinlerde borç/alacak bilinçli olarak **takip** fiiliyle anlatıldı — uygulama
> finansal ürün sunmuyor, yalnız kayıt tutuyor. Bu dili bozma.

---

## Marka adı: ÇuNehat, `Ç` ile

Uygulamanın adı **ÇuNehat**. Bir dönem `C` ile yazılıyordu; bunun teknik bir
gerekçesi olduğu sanılıyordu, yoktu — Play Console'un uygulama adı alanı da
`AndroidManifest.xml`'deki `android:label` de Unicode kabul ediyor.

**Ç olan yerler** (2026-08-26'da geçildi): Play Console uygulama adı,
`android:label`, `MaterialApp.title`, tüm l10n metinleri, çekmecedeki sürüm
satırı, gizlilik politikası ve tanıtım görselindeki kelime işareti.

**ASCII kalan yerler ve nedenleri — bunlara dokunma:**

| Yer | Değer | Neden |
|---|---|---|
| `applicationId` | `dev.halilibrahim.cunehat` | ASCII zorunlu; **yayından sonra asla değişmez** |
| Dart tanımlayıcıları | `CuNehatApp`, `cunehat_app.dart` | kod, marka değil |
| Yedek dosya adı | `cunehat_backup_YYYYMMDD_HHmm.json` | paylaşım/dosya sistemi tuzağı |

**Simge `Ç` olmadı ve olmamalı.** İşaret bir "C" halkası gibi okunuyor ama
harf değil marka işaretidir. Sedilla eklemek 48dp'de kuyruk ekler ve işaretin
dış çapının tuvalin %72'si olması kuralını bozar (bkz. ikon turu notları).

**ASO tarafı: her iki yazımı da indeksle.** Play'in Türkçe aramada ç/c
normalizasyonu garanti değil; kullanıcı "cunehat" da yazabilir. Bu yüzden uzun
açıklamanın **ilk cümlesinde** parantez içinde `(CuNehat)` duruyor. Başlıkta
durmasın — orada 10 karakter, aranan terime gitmeli.

---

## ASO stratejisi — neden metinler böyle yazıldı

Play üç alanı da anahtar kelime için indeksler ama **ağırlıkları eşit değil:**
başlık > kısa açıklama > uzun açıklama. 2024–2026 arasında algoritma ayrıca
kurulum *öncesi* sinyallerden (anahtar kelime, ham indirme) kurulum *sonrası*
sinyallere (tutunma, listeden kuruluma dönüşüm) kaydı — yani metin seni arama
sonucuna sokar, **elde tutan şey ürün.**

**Bu listelemedeki en büyük tek kayıp başlıktı.** Play Console'un uygulama adı
alanı 30 karakter ve "ÇuNehat" bunun 7'sini kullanıp **sıfır arama hacmi**
getiriyor: kimse "ÇuNehat" aramıyor, çünkü kimse bilmiyor. Türkiye pazarındaki
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
klon var; ÇuNehat'i ayıran şey **banka ekstresi okuma** (PDF/CSV/Excel + taranmış
PDF için cihaz içi OCR) — Türkiye pazarında neredeyse hiçbir rakipte yok. Ama
"ekstre" arama hacmi "gelir gider"in yanında küçük. Doğru kurgu: **aramaya ana
terimle gir, dönüşümü farkla al.**

---

## Türkçe (tr-TR — varsayılan dil)

### Uygulama adı (sınır 30) — **en ağır alan**

```
ÇuNehat: Gelir Gider Takibi
```

*27 karakter.* Marka + ana terim. "Gelir gider" bu kategorinin baş terimi;
"takibi" ifadeyi doğal bitiriyor.

> **Değerlendirilip elenen alternatif:** `ÇuNehat: Gelir Gider Bütçe` (26) bir
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
> kancayı taşımalı. Aşağıdaki açılış **169 karakter** ve cümle sınırında
> bitiyor; parantezli `(CuNehat)` de oraya sığdı, yani ikinci yazım da
> indekseniyor.

```
ÇuNehat (CuNehat); gelir gider takibi, bütçe ve borç takibi için yapılmış
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

ÇuNehat bir banka ya da finans kuruluşu değildir; kredi, yatırım veya ödeme
hizmeti sunmaz. Yalnızca kendi kayıtlarını tutmana yarayan bir defterdir.
```

*~2.950 karakter — sınırın rahat altında.*

---

## English (en-US — ikincil dil, isteğe bağlı)

### App name (limit 30)

```
ÇuNehat: Budget & Expenses
```

*26 karakter.* Aynı mantık: marka + baş terim. Marka `Ç` ile, İngilizce
listelemede de — tek marka, tek yazım.

> `ÇuNehat: Expense & Budget Tracker` doğal olurdu ama **33 karakter** — sınırı
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
ÇuNehat (CuNehat) is an ad-free personal finance app for expense tracking,
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
transaction can carry a note, a tag and a receipt photo.

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

ÇuNehat is not a bank or a financial institution and offers no credit, investment
or payment services. It is simply a ledger for keeping your own records.
```

---

## Sürüm notları — v1.0.0

### Türkçe (sınır 500)

```
ÇuNehat'in ilk sürümü.

Cüzdanlar ve çoklu para birimi, gelir/gider takibi, kategoriler, bütçeler,
borç ve alacak takibi, yinelenen işlemler ve hatırlatıcılar, raporlar ve
grafikler, birikim hedefleri ve yatırım takibi, banka ekstresi içe aktarma,
fiş fotoğrafı ve OCR, Google Drive yedekleme, biyometrik/PIN kilit.

Reklamsız ve aboneliksiz. Verilerin cihazında kalır.
```

### English (limit 500)

```
The first release of ÇuNehat.

Wallets and multi-currency, income and expense tracking, categories, budgets,
debt and receivable tracking, recurring transactions and reminders, reports and
charts, savings goals and investment tracking, bank statement import, receipt
photos with OCR, Google Drive backup, biometric/PIN lock.

No ads, no subscriptions. Your data stays on your device.
```

---

## Ekran görüntüleri — ✅ ÜRETİLDİ (26 Ağu 2026)

**8 görsel hazır:** `docs/store/screenshots/` (`01_…` – `08_…`). Ham cihaz
çekimleri `tools/store_screenshots.py` ile 1080×1920 (tam 9:16) tuvale, marka
zemini, başlık şeridi ve **özellik çipleriyle** yerleştirildi.

> **Değişiklik gerekirse betikten geç, elle düzenleme:**
> `python3 tools/store_screenshots.py` (tamamı) veya
> `python3 tools/store_screenshots.py 3 5` (yalnız 3 ve 5). Şerit metni ya da
> renk değişince 8 görselin hepsi tek komutla yeniden üretilir.

**Kalan iş:** görselleri Play Console → Mağaza girişi'ne yüklemek.

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
| 1 | İşlem defteri | *Gelir ve giderin **tek defterde*** | Takvim görünümü · Arama ve filtre · Çoklu cüzdan |
| 2 | Banka ekstresi inceleme | *Ekstreni at, **satırlar hazır** gelsin* | PDF ve Excel · Fotoğraftan OCR · Aritmetik doğrulama |
| 3 | Birikim hedefleri | *Hedefini kur, **varlıklarını** bağla* | Altın, hisse ve fon · Canlı fiyat · Kâr/zarar takibi |
| 4 | Portföy | *Portföyün **ne kadar** kazandırdı?* | Maliyet muhasebesi · Kısmi satış · Çoklu para birimi |
| 5 | Bütçe | *Bütçeni **aşınca** hemen gör* | Kategori limitleri · Aşım uyarısı · Gelir–gider raporu |
| 6 | Borç/alacak | *Borcunu ve alacağını **unutma*** | Taksit ve vade · Kısmi ödeme · Gecikme faizi |
| 7 | Düzenli işlemler | *Kira, maaş, abonelik — **kendiliğinden** gelsin* | Aylık şablonlar · Onay bekleyenler · Bildirim hatırlatması |
| 8 | Gizlilik / yedek | *Verilerin **sende** kalır* | Google Drive yedeği · CSV dışa aktarım · Reklam yok |

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
  markalı arama ("ÇuNehat") için indekslenen bir dış sinyal olur. Play URL'i
  ancak yayından sonra oluşacağı için bu iş production çıkışına ertelenmeli.
