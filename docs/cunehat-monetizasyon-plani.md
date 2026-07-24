# CuNehat — Monetizasyon Analizi ve Önerileri

> Felsefe: **İnsanlara yararlı olmak, soymak değil.** Bu doküman, benzer finans
> uygulamalarına göre geliri kasıtlı olarak **yarıya kadar düşük** tutan, karanlık
> desen içermeyen bir modeli hedefler. Kaynak koddan doğrulanmış gerçeklere dayanır.

**Tarih:** 2026-07-25 · **Durum:** Öneri (henüz uygulanmadı) · **Sürüm:** v1.0.0 yayın öncesi

---

## 1. Mevcut Durum

**Uygulamada şu anda hiçbir monetizasyon yok.** Kaynak koddan doğrulandı:

- `pubspec.yaml`'da reklam / satın alma / abonelik paketi **yok** (admob, in_app_purchase, revenuecat, stripe — hiçbiri).
- Koddaki "premium" kelimesi yalnızca **UI stil yorumlarında** geçiyor ("premium işlem kartı" gibi), bir ödeme katmanı değil.
- Paywall, "pro", "unlock", abonelik akışı — hiçbiri yok.

Yani uygulama şu an **tamamen ücretsiz ve reklamsız**. Sıfırdan bir model kurulacak; bozulacak bir gelir yapısı yok — bu bir avantaj.

---

## 2. Kritik Gerçek: Kullanıcı Başına Sunucu Maliyetin ~Sıfır

Bu, tüm strateji için en önemli veri. Monetizasyon kararı, **maliyet yapısından** çıkmalı — "herkes abonelik yapıyor" diye değil.

| Servis | Kaynak | Kime maliyeti var? |
|---|---|---|
| Döviz + altın kuru | `finans.truncgil.com/today.json` (ücretsiz, anahtarsız) | Yok |
| Hisse fiyatları | `query1.finance.yahoo.com` (ücretsiz, anahtarsız) | Yok |
| Bulut yedek | Google Drive `appDataFolder` | **Kullanıcının kendi** Drive kotası |
| Giriş | `google_sign_in` | Yok |
| Veri, OCR, PDF/Excel, raporlar | Hive + ML Kit + saf Dart — hepsi **cihaz-içi** | Yok |

**Sonuç:** Yeni kullanıcı sana neredeyse hiç para harcatmıyor. Yinelenen bir masrafı finanse etmen gerekmiyor.

**Bunun etik anlamı:** Abonelik, genelde "süregelen maliyet/değer" karşılığıdır (sunucu, veri akışı, ekip). Burada süregelen maliyet yok. Dolayısıyla **yinelenen tahsilat (özellikle aylık) etik olarak zayıf** ve tam da "soymak" hissi veren kısımdır. Tek-seferlik satın alma bu uygulamanın maliyet yapısına dürüstçe oturur.

---

## 3. Önerilen Model

**Ücretsiz çekirdek (kalıcı) + tek-seferlik "Destekçi/Pro" kilidi + isteğe bağlı bağış kavanozu. Reklam yok, aylık abonelik yok.**

Üç kural:
1. **Kullanıcının kendi verisini ve para takibinin özünü asla paywall'lama.** Takip, bütçe, dışa aktarma, güvenlik — hepsi ücretsiz kalır.
2. **Para = yalnızca kolaylık/otomasyon için.** Zaman kazandıran güç özellikleri (ekstre içe aktarma, OCR, otomatik yedek) tek seferlik Pro'da.
3. **Fiyat çıpası = benzer uygulamaların ~yarısı**, üstelik yinelenen değil tek seferlik + bölgesel fiyatla Türkiye için daha da düşük.

**Neden abonelik değil?** (§2'deki maliyet yapısı) Yinelenen masrafın yok; aboneliği haklı çıkaracak süregelen bir gider yok. Tek seferlik satın alma hem dürüst hem de kullanıcı dostu. *(Yüksek enflasyon nedeniyle sürdürülebilirlik kaygısı varsa, §5'te "düşük yıllık destekçi" alternatifi ve koşulları var — ama varsayılan öneri tek seferlik.)*

---

## 4. Özellik → Katman Tablosu

Efsane: 🟢 **Ücretsiz (kalıcı)** — asla kilitlenmez · 🔵 **Pro (tek seferlik kilit)** — kolaylık/otomasyon · 💛 **Bağış** — işlevsel kilit yok

| # | Özellik | Katman | Gerekçe / Not |
|---|---|:--:|---|
| 1 | Cüzdanlar (çoklu para birimi TRY/USD/EUR, transfer, kur dönüşümü) | 🟢 | Çekirdek. Uygulamanın kalbi; asla kilitlenmez. |
| 2 | Gelir/Gider işlemleri + kategoriler + kategori yöneticisi | 🟢 | Çekirdek para takibi. |
| 3 | Bütçeler (cüzdan bazlı) + bütçe uyarıları | 🟢 | Çekirdek. İnsanlara asıl faydayı bu verir. |
| 4 | Borç & Alacak takibi | 🟢 | Çekirdek. |
| 5 | Yinelenen işlemler + hatırlatıcılar | 🟢 | Çekirdek. |
| 6 | Temel raporlar & grafikler | 🟢 | Görünürlük herkesin hakkı. |
| 7 | Yerel JSON dışa/içe aktarma | 🟢 | **Etik zorunluluk:** Kendi verisine erişim asla ücretli olamaz (kilitlenme/lock-in yaratır). |
| 8 | CSV dışa aktarma & paylaşım | 🟢 | Veri taşınabilirliği ücretsiz kalır. |
| 9 | Güvenlik (biyometrik + PIN) | 🟢 | **Güvenlik asla paywall'lanmaz.** |
| 10 | Tema (açık/koyu) + çoklu dil (TR/EN) | 🟢 | Temel deneyim. |
| 11 | Bildirimler (bütçe/yinelenen) | 🟢 | Temel deneyim. |
| 12 | **Banka ekstresi içe aktarma** (Excel/PDF, mutabakat, kategori öğrenme) | 🔵 | En büyük zaman kazandıran güç özelliği. Klasik "Pro" adayı. |
| 13 | **Fiş eki + OCR tarama** (ML Kit) | 🔵 | Kolaylık otomasyonu. Manuel giriş her zaman ücretsiz. |
| 14 | **Google Drive otomatik/zamanlanmış yedek** | 🔵 | *Otomatik* kısım Pro; **manuel yedek/dışa aktarma (#7) daima ücretsiz.** |
| 15 | **Yatırımlar — canlı fiyat yenileme + gelişmiş değerleme** | 🔵 | Manuel yatırım kaydı ücretsiz kalabilir; *canlı fiyat otomatik yenileme + katkı muhasebesi/detay* Pro. (Bkz. not ↓) |
| 16 | **Gelişmiş raporlar** (özel tarih aralığı, PDF rapor çıktısı, derin analiz) | 🔵 | Temel rapor ücretsiz; "pro analiz" katmanı ek değer. |
| 17 | **Ekstra temalar / kişiselleştirme** | 🔵 | Salt kozmetik; kimseyi işlevden mahrum etmez. |
| 18 | (Gelecek) Cihazlar arası senkron | 🔵/💛 | *Kendi* sunucunu gerektirirse gerçek maliyet doğar — o zaman düşük yıllık ücret **haklı** olur. |
| 19 | Destekçi rozeti / teşekkür | 💛 | Sadece minnet; işlevsel kilit yok. |

> **#15 hakkında karar noktası:** İki seçenek var — (a) tüm yatırım modülü ücretsiz, sadece #12–14 Pro (en cömert); (b) manuel yatırım ücretsiz + canlı fiyat otomasyonu Pro. Cömertlik felsefene (a) daha uygun; sürdürülebilirlik istiyorsan (b). Öneri: **(a) ile başla**, Pro'yu ekstre içe aktarma + OCR + otomatik yedek üçlüsüne yasla — bunlar zaten net "kolaylık" algısı taşır.

**Özet ilke:** *Kendi paran, kendi verin, güvenliğin = ücretsiz. Otomasyon ve kolaylık = tek seferlik Pro. Fazlası = bağış.*

---

## 5. Fiyatlandırma

### Çıpa: "benzerlerin yarısı"

Karşılaştırmalı yıllık ücretler (2025–2026, kabaca): YNAB ~$110, Monarch/Copilot ~$95–100, PocketGuard ~$75, Spendee ~$45, Wallet by BudgetBakers ~$25–40. Medyan ≈ **$60–80/yıl**.

**Formül:** Hedef = (benzer uygulamaların medyan *yıllık* ücreti) × **0.5**, ama **tek seferlik** olarak ve **Play bölgesel fiyatıyla** Türkiye için daha da aşağı.

| Model | Tutar (küresel çıpa) | Not |
|---|---|---|
| ✅ **Önerilen: Tek seferlik Pro kilidi** | ≈ **$10–15 karşılığı**, ömür boyu | "Yarısı" çıpasının altında; bir kez öde, hep senin. Play'de **bölgesel fiyat** ile TR'de belirgin düşük ₺. |
| ⚠️ Alternatif: Düşük **yıllık** destekçi | ≈ **$12–20/yıl**, **aylık YOK** | Sadece enflasyon sürdürülebilirlik kaygısı ağır basarsa. Aylık sunma — "damla" etkisi tam da soyma hissini yaratır. |
| 💛 Bağış kavanozu | Kullanıcı belirler | Her modelin üstüne eklenebilir. |

### Türkiye / enflasyon notları
- **Play Console bölgesel fiyatlandırma kullan.** Dolar fiyatını otomatik ₺'ye çevirmek Türk kullanıcı için fahiş olur; Play'in yerel/PPP fiyatını kullan.
- **Google Play kesintisi:** Yıllık <$1M gelir için **%15** (standart %30 değil — "reduced service fee" programına kaydol). Fiyatı buna göre değerlendir.
- **Enflasyonla başa çıkma (tek seferlik modelde):** ₺ fiyatını periyodik güncelle; süregelen bakımı finanse etmenin dürüst yolu, birkaç yılda bir **ücretli büyük sürüm yükseltmesi** (v2) — mevcut kullanıcıyı zorla abone etmeden.

---

## 6. Kaçınılacak Karanlık Desenler

"Soymak değil" ilkesinin somut kuralları:

- ❌ **Reklam yok.** Finansal veri + reklam ağı = mahremiyet ihlali. Bu kategoride reklam kırmızı çizgi.
- ❌ **Ücretsiz deneme → sessiz otomatik tahsilat** tuzağı yok.
- ❌ **Aylık abonelik** yok (varsayılan olarak) — birikerek soyma hissi veren kısım.
- ❌ **Veri fidyesi** yok: dışa aktarma/yedek asla kilitlenmez; kullanıcı istediği an verisini alıp gidebilir.
- ❌ **Sahte aciliyet / bitmeyen paywall açılır pencereleri** yok.
- ✅ İptal kolay, hatırlatma net, ücretsiz katman **gerçekten kullanılabilir** (crippleware değil, kalıcı yuva).

---

## 7. Gerçekçi Gelir Beklentisi

Dürüst olmak gerekirse bu model "zengin etmez"; **"masrafı çıkarır + emeğe hak ettiği katkıyı sağlar"** hedefidir — ki bu senin değerlerinle örtüşür.

- Freemium finans uygulamalarında ücretliye dönüşüm tipik olarak **aktif kullanıcıların ~%1–5'i**.
- Bağış kavanozu dönüşümü çok daha düşük (~%0.5–2), ama sıfır baskıyla gelir.
- Türkçe-öncelikli niş kitle + bilinçli düşük fiyat = mütevazı ama **temiz** bir gelir. Ölçek yerine güven kazandırır (ki uzun vadede daha değerli).

---

## 8. Uygulama Adımları

**Teknik:**
1. `in_app_purchase` (resmî Flutter eklentisi) ekle — hem Play Billing hem App Store'u karılar; RevenueCat şart değil (küçük ölçek + tek seferlik ürün için gereksiz bağımlılık).
2. Tek bir non-consumable ürün: `cunehat_pro_lifetime`. Satın alım durumunu **cihazda** (secure storage / Hive) tut; sunucu doğrulaması ölçeğe gelene kadar şart değil.
3. `entitlement` bayrağını DI ile (GetIt) tek yerden ver; Pro özellikleri (#12–17) bu bayrağı kontrol etsin.
4. Yedek şemasına (`DataSerializationService`) satın alım durumunu **yazma** — cihaz-yerel entitlement kalsın (yedeği taşıyınca ödeme "sıçramasın"; Play/App Store zaten hesabı geri-yükler).
5. Nazik bir "Pro'yu Keşfet" ekranı: özellik listesi + tek buton + "geri yükle" (restore) linki. Tek seferlik, kapatılabilir.

**Yasal/idari (Türkiye):**
- Play/App Store'da ücretli ürün satmak için geliştirici hesabı + **vergi kaydı** (şahıs şirketi vb.) gerekir. Yayından önce netleştir.
- `docs/privacy-policy.html` zaten var — satın alma eklerken güncelle (ödeme sağlayıcısı = platform; sen kart verisi görmezsin).

---

## 9. Özet Karar

- **Şimdi:** Monetizasyon yok — temiz sayfa.
- **Öneri:** Cömert **ücretsiz çekirdek** + **tek seferlik Pro** (ekstre içe aktarma, OCR, otomatik yedek üzerine kurulu) + isteğe bağlı **bağış**. **Reklamsız, aylık aboneliksiz.**
- **Fiyat:** Benzerlerin yıllık medyanının **~yarısı**, ama **tek seferlik** ve **TR için bölgesel** olarak daha da düşük (≈ $10–15 karşılığı, ömür boyu).
- **Neden bu:** Sıfır sunucu maliyetin (§2) aboneliği dürüst kılmıyor; tek seferlik model hem maliyet yapına oturur hem de "yararlı ol, soyma" ilkeni koda döker.

> Kırmızı çizgi tek cümle: **Kullanıcının kendi parası, verisi ve güvenliği hiçbir zaman satılık değildir; yalnızca ona zaman kazandıran otomasyon, bir kez ve gönüllü olarak.**
