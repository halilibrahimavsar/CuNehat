# Smoke test — rakam doğruluğu (Faz 1: İşlemler · Rapor · İçgörü · Kredi kartı)

Amaç: uygulamanın gösterdiği **her rakamı**, elle hesaplanmış bir beklenene karşı
ölçmek. Tüm beklenenler aşağıdaki **altın veri setinden** türetilmiştir ve
kodun kurallarına göre hesaplanmıştır (kaynak satırlar her bölümde belirtildi).

- **Test günü: 15 Ekim 2026 (Perşembe).** "Yaşanmış gün"e bağlı rakamlar
  (günlük ortalama, kıyas rozeti, sıçrama, günlük hedef) yalnız bu gün geçerlidir.
  Başka bir gün koşulursa formülle yeniden hesapla.
- Ortam: `.dev` derleme (kart bayrağı `CUHAT_CREDIT_CARDS` debug'da açık),
  emülatörde **geçici kullanıcı** (`pm create-user`) — gerçek veriye dokunma.
- Sonuç sütunu: ✅ / ❌ (gördüğün rakamı yaz) / ⚠️ (karar gerekiyor).

---

## 0. Altın veri seti

Kategoriler: **Market**, **Fatura** (alt: **Elektrik**, **Su**), **Yemek**,
**Ulaşım**, **Maaş** (gelir), **Elektronik**.

### Cüzdan A — "Banka" (TRY, açılış 10.000,00)

| # | Tarih | Başlık | Kategori | Tür | Tutar |
|---|---|---|---|---|---|
| A1 | 01 Eyl | Maaş | Maaş | Gelir | 30.000,00 |
| A2 | 04 Eyl | Market | Market | Gider | 1.000,00 |
| A3 | 08 Eyl | Elektrik | Elektrik | Gider | 700,00 |
| A4 | 12 Eyl | Yemek | Yemek | Gider | 300,00 |
| A5 | 20 Eyl | Market | Market | Gider | 900,00 |
| A6 | 01 Eki | Maaş | Maaş | Gelir | 30.000,00 |
| A7 | 02 Eki | Market | Market | Gider | 1.200,00 |
| A8 | 02 Eki | **Kart ödemesi** (Banka → Kart) | — | sistem | 1.500,00 |
| A9 | 03 Eki | Elektrik | Elektrik | Gider | 800,00 |
| A10 | 03 Eki | Su | Su | Gider | 200,00 |
| A11 | 06 Eki | Yemek | Yemek | Gider | 450,00 |
| A12 | 10 Eki | Market | Market | Gider | 650,00 |
| A13 | 12 Eki | **Transfer** Banka → Nakit | — | sistem | 2.000,00 |
| A14 | 14 Eki | Ulaşım | Ulaşım | Gider | 300,00 |

Bütçe (Banka): **Market aylık 2.000,00**.

### Cüzdan B — "Nakit" (TRY, açılış 2.000,00)

| # | Tarih | Başlık | Tür | Tutar |
|---|---|---|---|---|
| B1 | 12 Eki | Transfer (A13'ün karşı bacağı) | sistem gelir | 2.000,00 |
| B2 | 13 Eki | Market | Gider | 150,00 |

### Cüzdan K — "Kart" (Banka'nın kartı)

Kesim günü **25**, son ödeme **kesimden 10 gün sonra**, limit **50.000,00**,
açılış borcu **0**, oluşturma **1 Eylül 2026** (son kesimden önce → defter güvenilir).
Faiz alanları boş (Bölüm 4.3'te doldurulacak).

| # | Kayıt tarihi | Başlık | Tür | Tutar | Girdiği ekstre (kesim) | Ödeme günü |
|---|---|---|---|---|---|---|
| K1 | 10 Eyl | Market | Gider | 1.000,00 | 25 Eyl | 05 Eki |
| K2 | 20 Eyl | Yemek | Gider | 500,00 | 25 Eyl | 05 Eki |
| K3 | 26 Eyl | Telefon (1/3) | Gider · taksit | 1.000,00 | 25 Eki | 04 Kas |
| K4 | 26 Eki | Telefon (2/3) | Gider · taksit (ileri tarih) | 1.000,00 | 25 Kas | 05 Ara |
| K5 | 26 Kas | Telefon (3/3) | Gider · taksit (ileri tarih) | 1.000,00 | 25 Ara | 04 Oca |
| K6 | 02 Eki | Ödeme (A8'in karşı bacağı) | sistem gelir | 1.500,00 | — | (gerçek tarih) |
| K7 | 10 Eki | Market | Gider | 400,00 | 25 Eki | 04 Kas |

K3–K5: 26 Eyl'de tek kayıt olarak **3.000,00 · 3 taksit** girilir (uygulama böler).

> Son ödeme günleri: 25 Eyl+10 = 05 Eki · 25 Eki+10 = 04 Kas · 25 Kas+10 = 05 Ara ·
> 25 Ara+10 = 04 Oca (`CardCycle.dueFor`).

---

## 1. İşlemler ekranı

Kaynak: `transaction_filtering.dart`, `daily_spending_summary_service.dart`,
`transaction_page.dart:_topCategories`, `isSpendingMovement` (sistem hareketi
harcama sayılmaz).

### 1.1 Bakiye ve defter

| ID | Adım | Beklenen | Sonuç |
|---|---|---|---|
| T-01 | Banka cüzdan bakiyesi | **60.000,00** (10.000 + 27.100 Eyl + 22.900 Eki) | |
| T-02 | Nakit bakiyesi | **3.850,00** | |
| T-03 | Kart bakiyesi / borcu | Borç **3.400,00** (ileri tarihli taksitler dahil) | |
| T-04 | Banka defter, satır altı yürüyen bakiye | 30 Eyl sonu 37.100 · 01 Eki 67.100 · 03 Eki sonu 63.400 · 06 Eki 62.950 · 10 Eki 62.300 · 12 Eki 60.300 · 14 Eki **60.000** | |
| T-05 | Dönemi Eylül'e al, en alttaki satırın bakiyesi | 01 Eyl sonrası 40.000,00; Eylül sonu 37.100,00 | |

### 1.2 Dönem özeti şeridi (Banka, Ekim 2026)

| ID | Adım | Beklenen | Sonuç |
|---|---|---|---|
| T-10 | Gelir | **30.000,00** | |
| T-11 | Gider | **3.600,00** (A8 ve A13 sayılmaz) | |
| T-12 | Gelir − gider | **26.400,00** | |
| T-13 | "N para taşıma sayılmadı" notu | **2** | |
| T-14 | İşlem sayısı | 9 satır (sistem dahil liste ile birebir) | |
| T-15 | "En çok:" satırı | **Market %51 · Fatura %28 · Yemek %13** (1.850 / 1.000 / 450 ÷ 3.600; Elektrik+Su köke toplanır) | |
| T-16 | Eylül'e geç | Gelir 30.000 · Gider **2.900** · Net 27.100 · En çok: Market %66 · Elektrik/Fatura %24 · Yemek %10 | |
| T-17 | Nakit, Ekim | Gelir **0** (transfer sayılmaz) · Gider 150 · "En çok" satırı **görünmez** (tek kategori) | |

### 1.3 Gün şeridi

| ID | Gün | Beklenen | Sonuç |
|---|---|---|---|
| T-20 | 02 Eki | Gider **1.200** (1.500'lük kart ödemesi çubuğa girmez), sayı 2 | |
| T-21 | 03 Eki | Gider **1.000** | |
| T-22 | 12 Eki | Gider **0**, sayı 1 (yalnız transfer) — "işlem yok" denmemeli | |
| T-23 | En koyu gün | 02 Eki (12 Eki DEĞİL) | |

### 1.4 Filtre ve arama (Banka, Ekim)

| ID | Filtre | Beklenen satırlar | Sonuç |
|---|---|---|---|
| T-30 | Yalnız gider | A7, A8, A9, A10, A11, A12, A13, A14 (sistem giderleri listede durur) | |
| T-31 | Para taşıma: gizle | A6, A7, A9–A12, A14 (7 satır) | |
| T-32 | Para taşıma: yalnız | A8, A13 | |
| T-33 | Kategori = Market | A7, A12 → toplam 1.850 | |
| T-34 | Tutar aralığı 400–900 | A9 (800), A11 (450), A12 (650) | |
| T-35 | Arama "elektr" | A9 (başlık) | |
| T-36 | Arama "fatura" | **boş** — arama kategori ADINDA eşleşir, Elektrik'in adı "Elektrik"; kök adı aranmaz (⚠️ beklenti bu mu?) | |
| T-37 | Arama "500" | Tutara göre ARAMAZ → boş | |
| T-38 | Filtreler açıkken özet şeridi | Görünen satırlardan hesaplanır (T-33'te gider 1.850) | |

### 1.5 Dönem kaydırma

| ID | Adım | Beklenen | Sonuç |
|---|---|---|---|
| T-40 | Ay: Ekim ‹ | 1–30 Eyl | |
| T-41 | Hafta (Pzt başlar), 15 Eki | 12–18 Eki: gider 300 (A14) + sayı 2 (A13 dahil) | |
| T-42 | Özel 10 gün (06–15 Eki) ‹ | 26 Eyl – 05 Eki | |
| T-43 | Ay sonu: 31 Ocak 2027'ye kayıt ekle, Şubat'a kaydır | Şubat 1–28; Mart'a geçince 1–31 (kenetleme birikmemeli) | |

### 1.6 Yazma akışları (rakamın canlı güncellenmesi)

| ID | Adım | Beklenen | Sonuç |
|---|---|---|---|
| T-50 | A12'yi 650 → 1.650 yap | Gider 4.600, Market %62, bakiye 59.000 — **sayfa yenilemeden** | |
| T-51 | Geri al (T-50'yi eski haline) | Tüm rakamlar T-10…T-15'e döner | |
| T-52 | A14'ü sil → snackbar "Geri al" | Gider 3.300 → geri alınca 3.600; bakiye 60.300 → 60.000 | |
| T-53 | 20 Eki'ye (ileri tarih) Market 500 ekle | Ekim gider **4.100**; bakiye satırı 59.500 | |
| T-54 | Saat sınırı: 31 Eki 23:59'a 10,00 gider | Ekim'de görünür, Kasım'da görünmez | |
| T-55 | Kuruş: 0,10 + 0,20 gider | Toplam **0,30** (0,30000000000000004 değil) | |

---

## 2. Rapor

Kaynak: `transaction_report_service.dart`, `report_series_service.dart`
(≤35 gün → günlük kova, ≤182 → haftalık, üstü → aylık),
`report_summary_cards.dart`, `report_category_data.dart` (pasta eşiği **%3**),
`comparisonWindowFor` (kıyas = önceki dönemin **aynı sayıda yaşanmış günü**),
`report_budget_summary_card.dart` + `DateRangeHelper.monthlyLimitFactor`.

### 2.1 Özet kartları (Banka, Ekim, bugün 15 Eki)

| ID | Kart | Beklenen | Sonuç |
|---|---|---|---|
| R-01 | Gelir | **30.000,00**, rozet **%0** (1–15 Eyl gelir 30.000) | |
| R-02 | Gider | **3.600,00**, rozet **↑ %80** (1–15 Eyl gider 2.000 = A2+A3+A4; A5 20 Eyl pencere DIŞI) — kötü renk | |
| R-03 | Net | **26.400,00**, alt satır "%88 birikim" | |
| R-04 | Eylül (geçmiş dönem) | Gelir 30.000 · Gider 2.900 · Net 27.100 · "%90 birikim"; Ağustos boş → rozet yüzdesiz "yeni" | |
| R-05 | Nakit, Ekim | Gelir 0 → net alt satırı "gelir yok, oran yok" (**%0 birikim YAZMAMALI**) | |
| R-06 | Net negatif: Banka'ya 20 Eki 30.000 gider ekle | Net −3.600 → "gelirin %12 üzerinde" (−%12 birikim değil) | |

### 2.2 Kategori dağılımı (Banka, Ekim)

| ID | Adım | Beklenen | Sonuç |
|---|---|---|---|
| R-10 | Sıralama + tutar | Market 1.850 (%51,4) · Fatura 1.000 (%27,8) · Yemek 450 (%12,5) · Ulaşım 300 (%8,3) | |
| R-11 | Fatura'ya in | Elektrik 800 · Su 200 (toplam 1.000) | |
| R-12 | Market dilimine dokun | Liste: A7, A12 — toplam 1.850 | |
| R-13 | "Diğer" kovası: 15 Eki Kırtasiye 50 + Kahve 40 ekle | Toplam 3.690; ikisi de <%3 → tek **"Diğer" 90**; kendi "Diğer" kategorin varsa karışmamalı | |
| R-14 | Yalnız Kırtasiye 50 eklenmiş hali | Tek kalem eşik altında → **Diğer kurulmaz**, "Kırtasiye" görünür | |
| R-15 | Gelir kırılımı | Maaş 30.000 (%100) | |

### 2.3 Kapsam çipleri (para taşıma / kartlar)

| ID | Çipler | Ekim gideri | Sonuç |
|---|---|---|---|
| R-20 | ikisi kapalı | **3.600** | |
| R-21 | Para taşıma AÇIK | **7.100** (3.600 + transfer 2.000 + kart ödemesi 1.500) | |
| R-22 | Kartlar dahil AÇIK | **5.100** (3.600 + kartın EKİM'de ödenen harcaması K1+K2 = 1.500) | |
| R-23 | İkisi AÇIK | **7.100** — kart ödeme bacağı (A8) çıkar, kart harcaması girer. **8.600 görürsen çift sayım hatası** | |
| R-24 | Kartlar dahil, Kasım | Kart 1.400 (K3+K7) | |
| R-25 | Bakiye çizgisi kartlar dahilken | DEĞİŞMEZ (Banka'nın kendi defteri: 37.100 → 60.000) | |

### 2.4 Zaman çizgisi

| ID | Adım | Beklenen | Sonuç |
|---|---|---|---|
| R-30 | Ekim, kova birimi | Günlük, 31 kova | |
| R-31 | Birikimli gider, 14 Eki noktası | 3.600; önceki dönem (kesikli) 14. noktada **2.000** | |
| R-32 | Bakiye ölçüsü | 37.100'den başlar, 15 Eki'de 60.000; kesikli önceki dönem çizgisi **yok** | |
| R-33 | "Bu Yıl" | Aylık kova (12); Eylül kovası gider 2.900, Ekim 3.600 | |
| R-34 | Son 3 ay (~92 gün) | Haftalık kova | |
| R-35 | Gelecek kovalar (16–31 Eki) | Sıfır akış; çizgi "düzleşmiş" görünmeli ama yanlış veri değil | |

### 2.5 Bütçe kartı (Market limiti 2.000/ay)

| ID | Dönem | Beklenen | Sonuç |
|---|---|---|---|
| R-40 | Ekim | 1.850 / 2.000 = **%92,5**, orantılama notu YOK | |
| R-41 | Hafta 05–11 Eki | Limit 2.000 × 7/30,4375 = **459,96**; harcama 650 → **%141 aşıldı**; "7 günlük döneme orantılandı" notu | |
| R-42 | 15 Eyl – 14 Eki (ay uzunluğu) | Limit **2.000** (orantılanmaz); Market 1.850 + A5 900 = 2.750 → %137,5 | |
| R-43 | Bu Yıl | Limit 2.000 × 365/30,4375 = **23.983,57** (kod yorumu "12 katı" diyor → 24.000 beklenir) ⚠️ karar | |
| R-44 | Elektrik'e 500 bütçe | 800/500 = %160 (alt kategori kendi bütçesiyle ölçülür) | |

---

## 3. İçgörü

Kaynak: `transaction_analytics_service.dart`. **Toplamlar** dönemin tamamından,
**hızlar/kıyaslar** yaşanmış pencereden (1–15 Eki). Ortalamanın böleni ilk
kayıttan öncesine uzanmaz (`trackingSince`).

### 3.1 Banka, "Bu Ay" (Ekim), bugün 15 Eki

| ID | Kart | Beklenen | Hesap | Sonuç |
|---|---|---|---|---|
| I-01 | Gelir / Gider / Net | 30.000 / **3.600** / 26.400 | sistem hariç | |
| I-02 | Birikim oranı | **%88** | 26.400 / 30.000 | |
| I-03 | Günlük ortalama | **240,00** "15 gün üzerinden" | 3.600 / 15 | |
| I-04 | En çok harcanan gün | **Cumartesi, 825,00** (2 Cumartesi) | Cmt 3+10 Eki = 1.650 / 2; Cuma 600; Salı 225; Çrş 150 | |
| I-05 | En çok kategori | Market 1.850 | | |
| I-06 | En büyük harcama | Market 1.200 (02 Eki) — transfer 2.000 **olmamalı** | | |
| I-07 | Günde ne kadar harcayabilirim | **1.552,94** × 17 gün | 26.400 / (15→31 Eki = 17 gün) | |
| I-08 | Sıçrama uyarısı | **Market %85** "önceki 15 gün" (1.850 vs 1.000) | Fatura %43, Yemek %50; Ulaşım öncesi 0 → aday değil | |
| I-09 | Kıyas rozetleri | Rapor R-01/R-02 ile **aynı** (%0, ↑%80) | ortak `comparisonWindowFor` | |
| I-10 | "2 para taşıma sayılmadı" | 2 | | |

### 3.2 Varyasyonlar

| ID | Adım | Beklenen | Sonuç |
|---|---|---|---|
| I-20 | 20 Eki Market 500 (ileri tarih) ekle | Gider **4.100**, ama günlük ortalama **hâlâ 240**, sıçrama hâlâ %85; günlük hedef 25.900/17 = **1.523,53** | |
| I-21 | Düzenli gider: 25 Eki kira 10.000 (tekrarlayan) | Günlük hedef (26.400 − 10.000) / 17 = **964,71** | |
| I-22 | Kira 30.000 olsun | Hedef yerine **açık uyarısı** (harcanabilir −3.600) | |
| I-23 | "Geçen Ay" (Eylül) | Gelir 30.000 · Gider 2.900 · %90 · ortalama **96,67** (/30) · en çok gün **Cuma 250** (Sal 140, Paz 225, Cmt 75) · günlük hedef **yok** · Ağustos boş → sıçrama yok | |
| I-24 | "Son 7 gün" (09–15 Eki) | Gider 950 (A12+A14); günlük hedef yok (bugün biten geriye dönük pencere) | |
| I-25 | YENİ kullanıcı: boş kurulumda 12 Eki 1.320, 15 Eki 4.590 gider | Ortalama **1.477,50** "4 gün üzerinden" (11 kayıtsız gün bölene girmez) · en çok gün **Perşembe 4.590** | |
| I-26 | Sıçrama eşiği | Kategori <50 ise ya da artış <%25 ise uyarı yok (ör. Yemek 300→370 = %23 → yok) | |

### 3.3 Kart cüzdanı İçgörü (ödeme gününe göre)

| ID | Dönem | Beklenen gider | Sonuç |
|---|---|---|---|
| I-30 | Ekim | **1.500** (K1+K2, 05 Eki'de ödenir) | |
| I-31 | Kasım | **1.400** (K3+K7) | |
| I-32 | Aralık / Ocak 2027 | 1.000 / 1.000 | |

---

## 4. Kredi kartı

Kaynak: `card_cycle.dart` (`CardCycle`, `computeCardStatus`, faiz tahminleri),
`card_spending_merge.dart`, `installments.dart`.

### 4.1 Durum (bugün 15 Eki, veri seti olduğu gibi)

| ID | Alan | Beklenen | Hesap | Sonuç |
|---|---|---|---|---|
| C-01 | Son kesim / son ödeme | **25 Eyl / 05 Eki** | | |
| C-02 | Sonraki kesim | **25 Eki** | | |
| C-03 | Dönem borcu (25 Eyl ekstresi) | **1.500,00** | K1+K2 | |
| C-04 | Kesimden sonra ödenen | **1.500,00** | K6 | |
| C-05 | Kalan ekstre borcu | **0** → "ödendi"; 10 gün geçmiş olsa da **gecikti YOK** | | |
| C-06 | Gelecek ekstreye giden (kesimden bugüne) | **1.400,00** | K3+K7 | |
| C-07 | Toplam borç | **3.400,00** | 1.500+3.000+400−1.500 | |
| C-08 | Kullanılabilir limit | **46.600,00** | | |
| C-09 | İleri tarihli taksitler | **2.000,00**; plan: Telefon, kalan 2 taksit | K4+K5 | |
| C-10 | Taksit satırları | 26 Eyl / 26 Eki / 26 Kas, her biri 1.000,00, başlık "(n/3)" | | |

### 4.2 Döngü kenarları

| ID | Senaryo | Beklenen | Sonuç |
|---|---|---|---|
| C-20 | Kesim GÜNÜ harcama (25 Eki 23:00) | 25 Eki ekstresine girer → ödeme 04 Kas | |
| C-21 | Kesimin ertesi günü (26 Eki 00:05) | 25 Kas ekstresi → ödeme 05 Ara | |
| C-22 | Kesim günü 31 olan kart | Şub 2027 kesimi **28 Şub**, Mar **31 Mar** (30'a kaymaz) | |
| C-23 | Ayar yok, `dueDay=5`, kesim 25 | Son ödeme ertesi ayın 5'i | |
| C-24 | Banka beyanı: 25 Eyl kesim, son ödeme **06 Eki** | Ayara rağmen 06 Eki gösterilir (beyan öncelikli); 25 Eki için yine 04 Kas | |
| C-25 | Ayar silinip yalnız beyan (25/09 → 05/10 = 10 gün) kalsın | Kural türetilir: 25 Eki → 04 Kas | |
| C-26 | Beyan farkı 12 gün (25/09 → 07/10) | Sonraki aylar **10 gün** ile hesaplanır (geç göstermemek için) | |
| C-27 | Taksit bölme kuruşu: 1.000,00 × 3 | 333,33 · 333,33 · **333,34** (toplam tam 1.000,00) | |
| C-28 | 31 Ocak'ta 3 taksit | 31 Oca · 28 Şub · **31 Mar** | |
| C-29 | Taksit grubunu düzenle: toplam 3.000 → 3.300 | 1.100 × 3; ileri taksitler + C-09 güncellenir | |

### 4.3 Gecikme, devir, faiz (veri setinde K6 tutarını değiştirerek)

Kart ayarı: akdi faiz **%4,25/ay**, gecikme faizi **%5/ay**. 25 Eyl beyanı:
ekstre **1.500**, asgari **450**, son ödeme 05 Eki.

| ID | Ödeme (K6/A8) | Beklenen | Sonuç |
|---|---|---|---|
| C-30 | 1.500 | Ödendi; faiz tahmini **yok** | |
| C-31 | 1.000 | Kalan 500, asgari karşılandı → **"devrediyor"** (gecikti DEĞİL); faiz tahmini 500 × %4,25 = **21,25** | |
| C-32 | 300 | Kalan 1.200, asgariden kalan 150 → **"10 gün gecikti"**; gecikme faizi tahmini 150 × %5 = **7,50** | |
| C-33 | 300, asgari beyanı YOK | Gecikti (bilinmeyen asgari ödenmiş sayılmaz) | |
| C-34 | K6 hiç yokken ödeme ekranında 450 yaz | "Kalan devreder: 1.050 → faiz ~44,63" (1.050 × %4,25 = 44,625; 44,62 görünürse yuvarlama yönüne bak) | |

### 4.4 Beyan ↔ defter mutabakatı

| ID | Senaryo | Beklenen | Sonuç |
|---|---|---|---|
| C-40 | Beyan ekstre 1.550 (defter 1.500) | Fark **+50** "defterde eksik harcama" | |
| C-41 | Beyan 1.450 | Fark **−50** "fazla/çift kayıt" | |
| C-42 | Beyan 1.500 | Fark uyarısı **yok** | |
| C-43 | Yeni kart, oluşturma **10 Eki**, açılış borcu 3.000, beyan yok | Dönem borcu **bilinmiyor** → kalan 0, **gecikti/bildirim YOK**, "ekstreyi gir" önerisi; toplam borç 3.000 | |

### 4.5 Kart ↔ Banka bağı (rakamların iki yerde tutarlılığı)

| ID | Kontrol | Beklenen | Sonuç |
|---|---|---|---|
| C-50 | A8 ve K6 | Aynı tutar, aynı gün, birbirine bağlı; birini silmek ikisini birden kaldırır | |
| C-51 | A8'i sil | Banka 61.500; kart borcu 4.900, kalan ekstre 1.500 → **gecikti** (10 gün) | |
| C-52 | Kart cüzdanı İşlemler, Ekim özeti | Gider **1.400** (K7 + ileri tarihli K4; KAYIT tarihine göre) — Rapor/İçgörü Ekim'de **1.500** (ÖDEME tarihine göre). ⚠️ Bilinçli fark mı? Kullanıcıya açıklanıyor mu? | |
| C-53 | Kart harcaması Banka bakiyesini | Değiştirmez; yalnız ödeme (A8) değiştirir | |

---

## 5. Çapraz tutarlılık (en değerli kontroller)

Aynı soruya iki ekranın aynı cevabı vermesi:

| ID | Karşılaştırma | Beklenen | Sonuç |
|---|---|---|---|
| X-01 | İşlemler şeridi gider ↔ Rapor gider ↔ İçgörü gider (Banka, Ekim) | **3.600 = 3.600 = 3.600** | |
| X-02 | "En çok:" yüzdeleri ↔ Rapor kategori yüzdeleri | Aynı kırılım (%51/%28/%13) | |
| X-03 | Rapor kıyas rozeti ↔ İçgörü kıyas rozeti | %0 / ↑%80 her ikisinde | |
| X-04 | Rapor bakiye çizgisi sonu ↔ cüzdan bakiyesi | 60.000 = 60.000 | |
| X-05 | Rapor bütçe kartı ↔ Bütçeler sayfası (Ekim) | %92,5 = %92,5 | |
| X-06 | Kart rozeti borcu ↔ kart sayfası ↔ Borç özeti | 3.400 her yerde | |
| X-07 | Kategori alt sayfası toplamı ↔ pasta dilimi | Market 1.850 = 1.850 | |

---

## Notlar

- ⚠️ işaretli satırlar test değil **karar**: R-43 (yıllık bütçe 11,99× mı 12× mı),
  T-36 (arama kök kategori adında eşleşsin mi), C-52 (İşlemler kayıt tarihi,
  Rapor ödeme tarihi — iki farklı "Ekim gideri").
- Bu listenin servis seviyesindeki kısmı (T-1x, R-0x/1x/2x/4x, I-*, C-0x/2x/3x/4x)
  aynı veri setiyle tek bir Dart testine (`currentDateOverride`/`today` sabit)
  çevrilebilir; o zaman yalnız arayüz kontrolleri elle kalır.
