# Smoke test sonuçları — rakam doğruluğu (15 Ekim 2026)

> **Bölüm A** servis testi (otomatik), **Bölüm B** emülatörde gerçek uygulama (sonradan eklendi).

Kapsam: `SMOKE_TEST_RAKAM_DOGRULUGU.md`'nin **servis katmanı** kısmı, altın veri
setiyle otomatik koşuldu: `test/manual/smoke_rakam_dogrulugu_test.dart`
(`flutter test test/manual/smoke_rakam_dogrulugu_test.dart` → **19/19 geçti**).
Test gününü `15 Eki 2026`'ya sabitler (`currentDateOverride` / `now:`).

**Arayüz kontrolleri koşulmadı** (aşağıda). Emülatördeki `Owner` kullanıcıda
gerçek veri var; dokümanın istediği geçici kullanıcı kurulmadı.

## Sonuç: servis katmanında rakam hatası YOK

| Bölüm | Doğrulanan ID'ler | Sonuç |
|---|---|---|
| İşlemler | T-01, T-02, T-04, T-05, T-10…T-17 (veri kısmı), T-20…T-22, T-40…T-43, T-55 | ✅ |
| Rapor | R-01…R-04, R-10, R-15, R-20…R-24 (kart ödeme günü), R-30, R-33, R-34, R-40…R-43 | ✅ |
| İçgörü | I-01…I-10, I-20…I-26, I-30…I-32 | ✅ |
| Kredi kartı | C-01…C-10, C-20…C-29, C-30…C-34, C-40…C-43, C-51 | ✅ |

## Doküman düzeltmeleri / notlar (kod hatası değil)

- **T-14:** "9 satır" doğru; test ilk önce 12 bekledi (benim hatam), kod 9 veriyor.
- **T-55:** `calculateTotals(0,10 + 0,20)` ham değer **0,30000000000000004**.
  Kullanıcıya `formatMoneyNumber` yuvarladığı için "0,30" görünür — beklenen
  davranış sağlandı, ama toplamı karşılaştıran/eşiğe sokan bir kod ham değeri
  görür. Şimdilik zararsız; not olarak bırakıldı.
- **C-34:** 1.050 × %4,25 = 44,625 → kod **44,63** (yarıyı yukarı) veriyor.
  Doküman "44,62 görünürse yuvarlama yönüne bak" diyordu; yön yukarı, tutarlı.
- **C-10:** taksit tarihleri 26 Eyl / 26 Eki / 26 Kas, başlıklar (1/3)…(3/3) ✅.
- **C-27/C-28:** 333,33 · 333,33 · 333,34 ve 31 Oca → 28 Şub → 31 Mar ✅.

## ⚠️ Karar bekleyen maddeler (testin değil, ürünün kararı)

Kod dokümanın **bugünkü** beklentisini veriyor; karar sizin:

- **R-43** Yıllık bütçe: 2.000 × 365/30,4375 = **23.983,57** (24.000 değil).
  Kod yorumu "12 katı" diyor → yorum ile davranış uyuşmuyor.
- **C-52** Kart cüzdanı İşlemler Ekim gideri **1.400** (kayıt tarihi) iken
  Rapor/İçgörü **1.500** (ödeme tarihi). Servis düzeyinde bilinçli; kullanıcıya
  açıklanıp açıklanmadığı arayüzden bakılmalı.
- **T-36** "fatura" araması kök kategori adında eşleşir mi — arayüz/filtre
  kodunda bakılmadı.

## Koşulmayan (arayüz/cihaz gerektiren) maddeler

| ID | Neden |
|---|---|
| T-03, T-13 görünümü, T-23, T-30…T-38 | Filtre/arama `transaction_filtering.dart` + arayüz; widget testi yazılmadı |
| T-50…T-54 | Yazma akışında canlı güncelleme — cihazda elle |
| R-05, R-06, R-11…R-14, R-25, R-31, R-32, R-35, R-44 | Rapor sayfası widget'larında metin/çizgi doğrulaması (alt metin, "Diğer" kovası, kesikli çizgi) |
| C-50, C-53, X-01…X-07 | Çapraz ekran tutarlılığı: üç ekranın aynı rakamı gösterip göstermediği yalnız arayüzde ölçülür |
| Kart ayar ekranı akışları (C-24…C-26 arayüzü, C-34 ödeme ekranı metni, C-43 "ekstreyi gir" önerisi) | Servis değerleri doğru; ekranlardaki metin bakılmadı |

## Sonraki adım (önerim)

1. Geçici kullanıcı (`pm create-user`) + altın veri seti tohumlayıp T-30…T-38,
   T-50…T-54, X-01…X-07'yi cihazda koşmak; ya da
2. Bu maddeleri widget testine çevirmek (özellikle X-01…X-07 — aynı veriyle üç
   sayfanın aynı rakamı vermesi).


---

# Bölüm B — Emülatörde (API 33, `.dev` debug, geçici kullanıcı)

Yöntem: altın veri seti `test/manual/gen_golden_backup.py` ile **şema 16 yedek
JSON**'u olarak üretildi, geçici kullanıcıya (`pm create-user`, kullanıcı 10)
"Yedeğim var → Yedek dosyasını seç" ile **uygulamanın kendi geri yükleme
yoluyla** yüklendi. Cihaz tarihi 15 Eki 2026 (test günüyle aynı). Rakamlar
ekran erişilebilirlik ağacından okundu (ekran görüntüsüyle çapraz kontrol).
İş bitince kullanıcı silindi; asıl kullanıcıya dokunulmadı.

Koşullar: `--dart-define=CUHAT_CREDIT_CARDS=true`, x86_64 debug.

## Sonuç özeti: rakam hatası bulunmadı; 2 küçük gözlem

| ID | Cihazda görülen | Sonuç |
|---|---|---|
| T-01 | Banka başlığı 60.000,00 ₺ | ✅ |
| T-02 | Cüzdanlarım: Nakit 3.850,00 ₺; Net 60.450 = 63.850 hesap − 3.400 kart | ✅ |
| T-04 | Gün sonu bakiyeleri 60.000 · 60.300 · 62.300 · 62.950 · 63.400 · 64.400 · 67.100 | ✅ |
| T-10…T-13, T-15 | Gelir 30.000 · Gider 3.600 · Net 26.400 · "2 para taşıma sayılmadı" · "Market %51, Fatura %28, Yemek %13" | ✅ |
| T-14 | "9 İşlem" | ✅ |
| T-16 | Eylül: 27.100 / 30.000 / 2.900 · Market %66, Fatura %24, Yemek %10 | ✅ |
| T-20…T-22 | 2 Eki gider 1.200 (1.500'lük kart ödemesi hariç) · 3 Eki 1.000 · 12 Eki net 0,00 "1 işlem" ("işlem yok" DEĞİL) | ✅ |
| T-30…T-32 | Filtre: yalnız gider 8 · para taşıma gizle 7 · yalnız bunlar 2 · yalnız gelir 1 | ✅ |
| T-33, T-38 | Kategori Market → 2 işlem; süzülmüş özet "Süzülen" gider 1.850 | ✅ |
| T-35 | "elektr" → gider 800 | ✅ |
| T-36 | "fatura" → "sonuç yok" (⚠️ karar: kök kategori adı aranmıyor) | ⚠️ |
| T-37 | "500" → sonuç yok (tutara göre aranmaz) | ✅ |
| T-40 | Önceki dönem → Eylül 2026 | ✅ |
| T-50 | A12 650→1.650: **sayfa yenilemeden** Banka 59.000, gider 4.600, Market %62 | ✅ |
| T-52 | Ulaşım sil: 59.300 / gider 4.300 → "Geri al" → 59.000 / 4.600 | ✅ |
| R-20 | Rapor pasta toplamı 3.600 | ✅ |
| R-21 | Para taşıma açık: 7.100 | ✅ |
| R-22 | Kartlar dahil: 5.100 | ✅ |
| R-23 | İkisi açık: **7.100** (8.600 çift sayım YOK) | ✅ |
| R-02 / I-09 | Rapor kartı Gider 3.600 "%80 — önceki dönemin aynı noktasına göre" | ✅ |
| R-40 | Bütçe: Market %93, 1.850 / 2.000 (92,5 → 93 yuvarlama) | ✅ |
| I-01, I-03, I-04, I-06 | Gider 3.600 · günlük ortalama 240,00 "15 günün ortalaması" · Cumartesi 825,00 "2 günün ortalaması" · en büyük harcama Market 1.200 | ✅ |
| I-07 | "Günde harcayabileceğin 1.552,94 ₺ … kalan 17 güne" | ✅ |
| I-08 | "Harcama sıçraması +%85 Market 1.850 / Önceki 15 günde 1.000" | ✅ |
| C-01/C-02 | Sonraki kesim 25 Eki; ekstre ödendi | ✅ |
| C-03…C-09 | Dönem borcu 1.500 · toplam borç 3.400 · limit 46.600 · kalan taksit 2.000 · "Telefon 2 taksit kaldı" · bu dönem harcanan 1.400 | ✅ |
| C-10 | "Telefon (1/3)…(3/3)", ödeme günü 4 Kas | ✅ |
| C-29 | Taksit grubu 3.000→3.300: 1.100 × 3; kalan taksit 2.200; toplam borç 3.700 | ✅ |
| C-30 | Beyan 1.500 + ödeme 1.500: kalan 0, faiz notu yok | ✅ |
| C-31 | Ödeme 1.000: kalan 500, "Asgari ödendi" (gecikti DEĞİL), faiz ≈ 21,25 ₺ | ✅ |
| C-32 | Ödeme 300: "10 gün gecikti", kalan 1.200, kalan asgari 150, gecikme faizi ≈ 7,50 ₺ | ✅ |
| C-34 | Kalan 1.050 için ≈ 44,63 ₺ (yarıyı yukarı) | ✅ |
| C-40/C-41/C-42 | Beyan 1.550 / 1.450 / 1.500: fark uyarısı 50 / 50 / yok | ✅ |
| C-51 | Ödeme çifti silinince Banka 61.500; kart "10 gün gecikti" 1.500 | ✅ |
| X-01 | İşlemler = Rapor = İçgörü gider 3.600 | ✅ |
| X-02 | "En çok" yüzdeleri = Rapor pastası | ✅ |
| X-06 | Kart borcu: Borç sayfası 3.400 = kart başlığı 3.400 | ✅ |
| X-07 | Market dilimi 1.850 = kategori süzgeci 1.850 | ✅ |

## Gözlemler (hata değil, küçük pürüz)

1. **Kart ayrıntı sayfasındaki limit çubuğunun etiketi yok.** `3.400 / 50.000`
   = %6,8 dolu çubuk yalnız "7" olarak okunuyor (erişilebilirlik); ne olduğu
   söylenmiyor.
2. **Fark uyarısı yön söylemiyor.** Beyan 1.550 (defterde eksik) ile 1.450
   (fazla/çift) aynı cümleyi alıyor: "50,00 ₺ fark var: eksik ya da fazla işlem
   olabilir." Doküman C-40/C-41 ayrı yön bekliyordu; sayı doğru, metin ortak.
3. **Rapor kıyas rozeti "%80"** — yön ok simgesiyle veriliyor, erişilebilirlik
   metninde yalnız yüzde var ("önceki dönemin aynı noktasına göre"); artış mı
   düşüş mü okunmuyor.

## Cihaz turunda ortaya çıkan, uygulama hatası OLMAYAN şeyler

- İlk fikstürde `colorHex` değerini `FFF44336` yazmıştım (uygulama `0xFFF44336`
  biçimini bekliyor). `WalletColors.hexToColor` `int.parse` ile **çözümsüz
  metinde build sırasında fırlatıyor**; sonuç başlıkta "RenderFlex overflowed
  by 99653 pixels" kırmızı bandı ve her karede `FormatException`. Düzeltilmiş
  fikstürde hata yok. Gerçek kullanıcı verisinde bu biçim oluşmaz (yalnız
  `colorToHex` üretir), ama **yedekten geri yükleme bu alanı doğrulamıyor** —
  elle düzenlenmiş/bozuk bir yedek cüzdan başlığını kırar. İstenirse
  `fromJson`'da doğrulama ya da `hexToColor`'da `tryParse` + varsayılan renk.
- Aynı JSON dosyası öncekinden **kısa** yazılınca (`content write` kırpmıyor)
  yedeğin sonunda çöp kalıyor ve geri yükleme `FormatException` ile reddedildi —
  bozuk dosya sessizce değil, "geri yüklenemedi" ile karşılandı (kayıt
  bozulmadı).

## (Bölüm B'nin "hâlâ koşulmadı" listesi Bölüm C ile kapandı.)

---

# Bölüm C — Kalan maddeler, emülatörde (aynı yöntem, 15 fikstür varyantı)

`test/manual/gen_golden_backup.py` artık varyant üretiyor (`x53 r06 r13 r14 i21
i22 edge cedge newuser cstmt1-4 c43`); her biri temiz kurulumda geri yüklendi.
Cihaz-yazma akışları (form) ayrıca elle sürüldü.

| ID | Cihazda görülen | Sonuç |
|---|---|---|
| T-23 | Gün şeridi: 2 Eki en yüksek/koyu çubuk, 3 Eki ikinci, 12 Eki çubuksuz | ✅ |
| T-34 | Tutar 400–900: 3 işlem, gider 1.900 (A9, A11, A12) | ✅ |
| T-41 | Birim Hafta: "12 – 18 Eki", gider 300, 2 işlem | ✅ |
| T-42 | Özel 6–15 Eki → ‹ → "26 Eyl – 5 Eki" | ✅ |
| T-43 | Ocak 2027 → Şubat → Mart etiketleri sırayla | ✅ (gün sayısı etiketten okunmadı) |
| T-53 / I-20 | 20 Eki Market 500: Ekim gider 4.100, o günün gün sonu 59.500, günlük ortalama 240, hedef 1.523,53, sıçrama %85 | ✅ |
| T-54 | 31 Eki 23:59:59 gider Ekim'de (3.610), 1 Kas 00:00 Kasım'da (20) | ✅ |
| T-55 | 0,10 + 0,20 → Kasım gideri "0,30 ₺"; cüzdan 3.849,70 | ✅ |
| T-17 | Nakit Ekim: gelir 0, gider 150, "En çok" satırı yok | ✅ |
| R-04 | Eylül (Ağustos boş): "En çok" ve kıyas Rapor'da yüzdesiz | ✅ |
| R-05 | Nakit: "Bu dönemde gelir yok" (%0 birikim yazmıyor) | ✅ |
| R-06 | Net −3.600: "Gelirin %12 üzerinde"; gider rozeti "%999+" | ✅ |
| R-11 / R-12 | Fatura → Elektrik 800 (%80) · Su 200 (%20); Market → A12 650 + A7 1.200 = 1.850 | ✅ |
| R-13 | Kırtasiye 50 + Kahve 40 → tek "Diğer 90" (%2), toplam 3.690 | ✅ |
| R-14 | Yalnız Kırtasiye 50 → "Diğer" kurulmuyor, "Kırtasiye" görünüyor | ✅ |
| R-25 | Kartlar dahil: bakiye 60.000, dönem başı 37.100 değişmiyor | ✅ |
| R-31 | Gider çizgisi 14 Eki 3.600; kesikli Eylül çizgisi aynı noktada ≈2.000 | ✅ |
| R-32 | Bakiye: dönem başı 37.100 → 60.000, kesikli çizgi yok | ✅ |
| R-33 / R-34 | "Bu yıl" aylık kova (Eyl 2.900 → Eki 6.500 birikimli) · "Son 3 ay" haftalık | ✅ |
| R-35 | Bu dönem çizgisi bugünde bitiyor (gelecek kovalar çizilmiyor) | ✅ |
| R-41 | Hafta/7 gün: limit 459,96, %141, "7 günlük döneme orantılandı" | ✅ |
| R-42 | 15 Eyl – 14 Eki: limit 2.000 (orantılanmıyor), 2.750 → %138 | ✅ |
| R-43 | Bu yıl: limit **23.983,57** (365 gün), %16 — kod yorumu "12 katı" ile uyuşmuyor | ⚠️ karar |
| R-44 | Elektrik bütçesi 500: 800 → %160 | ✅ |
| X-05 | Bütçeler sayfası Market %93 = Rapor %93; toplam 2.650 / 2.500 | ✅ |
| I-21 | Kira 10.000 (25 Eki): hedef 964,71, "10.000,00 ₺ düzenli ödeme düşüldü" | ✅ |
| I-22 | Kira 30.000: "Bu dönem açıktasın 3.600,00 ₺", hedef gösterilmiyor | ✅ |
| I-23 | Eylül: ortalama 96,67 (30 gün), Cuma 250 (4 günün ort.), hedef yok, sıçrama yok | ✅ |
| I-24 | Son 7 gün: gider 950, günlük hedef yok | ✅ |
| I-25 | Yeni kullanıcı (12 ve 15 Eki): 1.477,50 "4 günün ortalaması", Perşembe 4.590 | ✅ |
| C-20 / C-21 | 25 Eki 23:00 → ekstre 26 Eyl–25 Eki, ödeme 4 Kas · 26 Eki 00:05 → ekstre 26 Eki–25 Kas, ödeme 5 Ara | ✅ |
| C-22 | Kesim 31: Ekim → … → Şubat 2027 → Mart 2027 sırayla (kayma yok); "Sonraki kesim 31 Eki" | ✅ |
| C-23 | Ayar yok, dueDay=5: ödeme 5 Eki / 5 Kas | ✅ |
| C-24 | Beyan 25 Eyl→06 Eki: o ekstre "ödeme 6 Eki", sonraki 4 Kas | ✅ |
| C-25 | Yalnız beyan 25/09→05/10: 25 Eki → 4 Kas türetiliyor | ✅ |
| C-26 | Beyan farkı 12 gün (07/10): o ekstre 7 Eki, sonraki 4 Kas (10 gün) | ✅ |
| C-27 | Formdan 1.000 × 3 taksit: "Her ay 333,33"; 333,33 · 333,33 · 333,34; borç +1.000 | ✅ |
| C-43 | Yeni kart (10 Eki, açılış borcu 3.000): dönem borcu "bilinmiyor", "Ekstreyi gir", gecikti YOK | ✅ |
| C-50 | Transferi kaldır: iki bacak birlikte gidiyor (Banka 61.500, kart 4.900) | ✅ |
| C-53 | Kart harcaması eklenince Banka 60.000 aynı, kart borcu +1.000 | ✅ |

## ⚠️ Cihazda doğrulanan gerçek tutarsızlık: C-52

Kart cüzdanında **aynı dönem etiketi** ("Ekstre · 26 Eyl – 25 Eki") İşlemler
sayfasında gideri **1.400,00 ₺** (kayıt tarihine göre: K3 + K7), İçgörü
sayfasında **1.500,00 ₺** (ödeme tarihine göre: K1 + K2) gösteriyor. Servis
düzeyinde bilinçli, ama kullanıcı iki sekme arasında geçince aynı başlığın altında
iki farklı rakam görüyor ve ekranda açıklama yok. Karar: ya İçgörü/Rapor'da
"ödeme tarihine göre" notu, ya kart bağlamında iki sayfanın aynı bazı kullanması.

## Başka küçük gözlemler

- **Rapor bakiye grafiği ekseni 0'dan başlıyor** (60 B'lik bakiyede ±%10 hareket
  neredeyse düz çizgi; "Son 3 ay" hariç hep düz görünüyor).
- **Tutar aralığı alanı düzenlerken** ("900"→"400") bir kez "4.400" gösterdi;
  adb ile üretilen silme/yazma sırasında olduğu için kesin kök neden
  doğrulanmadı (elle tekrar edilmeli).
- Yeni kullanıcı (tek cüzdan, 2 kayıt) ekranında İçgörü/Rapor tek bir "İçgörü ve
  rapor" düğmesinin arkasında; düzen çok-cüzdanlı ekrandan farklı — hata değil.

## (Bölüm C'nin "hâlâ koşulmayan" listesi Bölüm D ile kapandı.)

---

# Bölüm D — Son 22 madde, emülatörde (15 Eki 2026)

Bölüm B/C'den sonra yönergedeki her kimlik cihaz tablolarıyla tek tek
karşılaştırıldı; cihaz satırı olmayan 22 madde aynı yöntemle (geçici kullanıcı
+ fikstür geri yükleme; yeni varyantlar `c33`, `i26`, `t43`) koşuldu.
**Artık yönergedeki her maddenin cihazda bir sonucu var.**

| ID | Cihazda görülen | Sonuç |
|---|---|---|
| T-03 | Kart borcu 3.400 (ileri tarihli taksitler dahil), Borç sayfası ve kart başlığı | ✅ |
| T-05 | Eylül: 1 Eyl gün sonu 40.000, Eylül sonu (20 Eyl) 37.100 | ✅ |
| T-51 | A12 1.650 → 650 geri düzenlendi: Banka 60.000, gelir 30.000, gider 3.600, net 26.400, "9 İşlem", Market %51 · Fatura %28 · Yemek %13, "2 para taşıma" | ✅ (bkz. not 1) |
| T-43 | Gün şeridi Ocak 31 → Şubat **28** → Mart **31** ile bitiyor (kenetleme birikmiyor) | ✅ |
| R-01 | Gelir sekmesi 30.000; **%0 rozeti görünmüyor** | ✅ (bkz. not 2) |
| R-03 | Net +26.400, alt satır "Gelir 30.000 · Gider 3.600 · %88 birikim" | ✅ |
| R-10 | Market 1.850 (%51) · Fatura 1.000 (%28) · Yemek 450 (%13) · Ulaşım 300 (%8) | ✅ |
| R-15 | Gelir kırılımı: Maaş 30.000 (%100) | ✅ |
| R-24 | Kart harcamaları dahil, Kasım: toplam 1.400 (Elektronik 1.000 + Market 400) | ✅ |
| R-30 | Ekim günlük kova: çizgi ekseni 01–31 Eki; çubuk görünümü geçmiş 15 günü çiziyor ("15 dönem") | ✅ |
| X-04 | Bakiye çizgisi sonu 60.000 = Banka 60.000 | ✅ (bkz. not 3) |
| I-02 / I-05 / X-03 | İçgörü'de artık birikim oranı, "en çok kategori" ve kıyas rozeti kartı **yok** (Acemi turunda Rapor'a/İşlemler "En çok" satırına taşındı). Aynı rakamlar oradan doğrulandı: %88 (R-03), Market 1.850 / %51 (R-10, T-15), ↑%80 (R-02) | ✅ (yüzey değişti, yönerge eski) |
| I-10 | İçgörü: "2 para taşıma hareketi … sayılmadı" | ✅ |
| I-26 | Market 1.100 vs 1.000 (%10), Fatura 700 vs 700, Yemek 370 vs 300 (%23): **sıçrama kartı çıkmıyor** | ✅ |
| I-30…I-32 | Kart cüzdanı İçgörü: Ekim 1.500 · Kasım 1.400 · Aralık 1.000 · Ocak 2027 1.000 | ✅ |
| C-33 | Ekstre 1.500, asgari beyanı yok, ödeme 300: "Kalan dönem borcu 1.200", "**10 gün gecikti**", toplam borç 4.600 | ✅ |
| C-24…C-26 ayar ekranı | Kart ayarları → "Kesimden kaç gün sonra" 10→12: önizleme anında "25 Eyl kesiminin son ödemesi: 7 Eki"; kaydedince sonraki ekstre "ödeme 6 Kas"; beyanlı ekstre 5 Eki'de kaldı (gecikti korunur, beyan öncelikli) | ✅ |
| C-28 (eşdeğeri) | Form ileri tarih kabul etmiyor (aşağı bkz.); 31 **Ağu** 2026'da 900 × 3 taksit: 31 Ağu (1/3) · **30 Eyl** (2/3) · **31 Eki** (3/3), "Her ay 300,00 ₺"; borç 4.600 → 5.500; 3/3 ödemesi 7 Ara (25 Kas + 12) | ✅ |

### Notlar

1. **T-51 — düzenlemede "Geri al" yok.** Düzenleme sonrası snackbar yalnız
   "Market başarıyla güncellendi" diyor; geri alma yalnız silmede
   (`DeletionUndo`, `deletion_undo_service.dart`). Yönergenin "Geri al"ı elle
   eski değere düzenleme olarak koşuldu. Tasarım tercihi; yönerge
   güncellenmeli ya da düzenlemeye de geri alma istenirse ayrı iş.
2. **R-01 — %0 rozeti bilinçli gizli.** `report_trend_card.dart:397`
   `change.abs() >= ReportChangeBadge.minPercent` değilse rozet çizilmiyor.
   Yönergedeki "rozet %0" beklentisi eski.
3. **X-04 — bakiye alt satırı toplanmıyor (yeni küçük gözlem).** "Dönem başı
   37.100 · Net +26.400" yan yana yazıyor; toplamı 63.500, başlıktaki bakiye
   60.000. Aradaki −3.500 para taşıma (kart ödemesi 1.500 + transfer 2.000);
   ekranda bu açıklanmıyor. Kullanıcı iki sayıyı toplarsa tutmuyor.
4. **Yeni bulgu — Gider sekmesinde çubuk grafiğin erişilebilirlik metni
   yanlış.** `report_daily_net_flow_chart.dart:128` Gider sekmesinde geliri
   0'a çekiyor, ama satır 166'daki semantik etiket yine "Gelir–gider grafiği:
   15 dönem, **toplam gelir 0,00 ₺**, toplam gider 3.600,00 ₺" diyor (dönem
   geliri 30.000). Ekran okuyucu kullanıcıya gelir yokmuş gibi okunur.
   Gösterilmeyen seri etiketten çıkarılmalı.
5. **C-28 formdan koşulamaz.** İşlem formunun tarih seçicisi
   `transaction_when_row.dart:21` `lastDate: DateTime.now()` — 31.01.2027
   "Kapsama alanı dışında". Yönergedeki "31 Ocak'ta 3 taksit" yalnız servis
   testinde ✅; cihazda aynı kural (31 → 30 → 31, kenetleme birikmez) 31 Ağu
   ile doğrulandı. Not: bugün başlayan taksitlerin ileri ayları zaten
   gelecekte, yani ileri tarih yalnız *ilk* taksit için kapalı.

## Kapanış

Yönergedeki 125 maddenin hepsi hem servis testinde (Bölüm A) hem cihazda
(B/C/D) koşuldu. **Yanlış rakam bulunmadı.** Karar bekleyenler: C-52 (aynı
ekstre etiketi altında 1.400 / 1.500), R-43 (yıllık bütçe 365 gün vs "12
katı"), T-36 (kök kategori adı aranmıyor). Küçük gözlemler: limit çubuğu
etiketsiz, fark uyarısı/kıyas rozeti yön söylemiyor, bakiye grafiği 0'dan
başlıyor, bakiye alt satırı toplanmıyor (not 3), çubuk grafik semantik etiketi
(not 4), tutar alanında bir kez "4.400" (doğrulanmadı), geri yükleme
`colorHex` doğrulamıyor.
