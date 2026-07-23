# Gemini için Smoke Test Görev Talimatı — CuNehat

Sen, CuNehat (kişisel finans, Flutter, Türkçe) uygulamasının **smoke testini bizzat
çalıştıran** bir QA ajanısın. Görevin, [`SMOKE_TEST_REPORT.md`](./SMOKE_TEST_REPORT.md)
dosyasındaki senaryoları gerçek bir Android emülatöründe **kendi elinle** çalıştırıp
raporu **gerçek gözlemlere** göre güncellemektir.

---

## 🚫 Mutlak Kural: Durumu Script'le Değiştirme

- Senaryo durumlarını (`⏳ → ✅`) **toplu bir betikle (python/regex/sed) GÜNCELLEME.**
  Daha önceki `update_reports.py` gibi "durum-uyduran" betikler **silindi** ve
  yasaktır. Her durum değişikliğini, o senaryoyu **gerçekten çalıştırıp gözlemledikten
  sonra** raporda **elle** yaparsın.
- Bir senaryo yalnızca; adımları uygulandı **VE** beklenen sonuç gözlemlendi **VE**
  bunu kanıtlayan bir ekran görüntüsü alındıysa `✅` olur. Aksi halde `⏳`, kısmi ise
  `🔄`, başarısızsa `❌` (ve "Tespit Edilen Hatalar" bölümüne yazılır).
- **İzin verilen betik yalnızca fixture (girdi verisi) üretimidir:** `make_fixtures.py`
  ile `mock_statement.csv/.xlsx/.pdf` üretebilirsin. Bu, test sonucu değil, test
  girdisidir. Sonuç/durum asla betikle yazılmaz.

---

## Ortam ve Araçlar

- **Cihaz:** Android Emulator (Android 15 / API 35). Paket: `dev.halilibrahim.cunehat`.
- **Etkileşim:** `adb` + `uiautomator`. Tercih ettiğin akış:
  - `adb shell uiautomator dump` → ekran ağacını al, düğüm sınırlarını (bounds) oku.
  - `adb shell input tap X Y` / `adb shell input swipe ...` / `adb shell input text ...`
  - `adb exec-out screencap -p > test_screenshots/<anlamli_ad>.png`
- **Bilinen otomasyon tuzağı:** Ana ekrandaki alt eylem çubuğu bir **karusel**; "Rapor"
  sekmesi ADB kaydırmayla tam ortalanamayabilir. `uiautomator dump`'tan koordinatı
  hesaplayıp doğrudan tıkla (bkz. rapordaki Hata #2).

---

## Her Senaryo İçin İş Akışı

1. **Önkoşulu kur** (gerekiyorsa cüzdan/işlem/fixture oluştur).
2. **Adımları uygula** (gerçek dokunuşlar/girişler).
3. **Ekran görüntüsü al**, `test_screenshots/` altına **anlamlı adla** kaydet
   (örn. `recurring_template_created.png`).
4. **Beklenen sonucu doğrula** (değerleri, bakiyeyi, durum metnini gözlemle).
5. **`SMOKE_TEST_REPORT.md`'yi elle güncelle** — ilgili senaryonun altına:
   - `- **Durum:** ✅ Tamamlandı` (veya `❌`/`🔄`)
   - `- **Kanıt:** <dosya adları> — <tek cümle gerçek gözlem>`
   - Başarısızsa `- **Gözlem:**` ile ne olduğunu yaz ve **"Tespit Edilen Hatalar"**
     bölümüne madde ekle.
6. **Baştaki sayaçları ve "Kapsam Özeti" tablosunu güncel tut** (X / 61 doğrulandı).

> Şablon olarak **Senaryo 5.2**'nin `Notlar:` biçimini örnek al — gerçek gözlem +
> atlanan adımın gerekçesi.

---

## Öncelik Sırası

1. **Hiç başlanmamış bölümler (en yüksek değer):** 7 (Tekrarlayan), 8 (Yatırım),
   9 (Ayarlar/Güvenlik), 10 (Onboarding), 11 (Ana Ekran/Slider), 12 (Negatif durumlar).
2. **Yeni banka senaryoları:** 4.6 (Excel/.xlsx), 4.7 (mükerrer), 4.8 (para birimi
   uyarısı), 4.9 (kolon eşleme hatırlama), 4.10 (geçmişten kategori öğrenme).
3. **Riskli olanların yeniden doğrulanması:** 4.5'i **yeni gerçekçi PDF fixture'ıyla**
   tekrar koş (Bakiye sütunu ↔ Tutar ayrımı ve çok-satırlı açıklamanın kaybolmadığını
   doğrula). 3.5 (cüzdan-bazlı bütçe izolasyonu) ve 9.7 (uyumsuz yedek reddi) mantık
   açısından kritik.
4. **Kanıtı eksik ✅ senaryolar:** 1.1, 1.3, 1.4, 1.7, 2.5, 2.6, 3.4, 4.4 için adanmış
   ekran görüntüsü ekle (durumları zaten ✅, yalnız `Kanıt` güçlendirilecek).

---

## Fixture Hazırlığı

- Çalıştır: `python3 make_fixtures.py` → `mock_statement.csv`, `mock_statement.xlsx`,
  `mock_statement.pdf` üretilir (TR ondalık `1.234,56`, `;` ayraç, Akbank başlıklı PDF,
  Bakiye sütunu, çok-satıra saran maaş açıklaması).
- Emülatöre gönder: `adb push mock_statement.pdf /sdcard/Download/` (csv/xlsx için de).
- Negatif senaryolar (12.2) için bozuk/boş dosyaları elle oluşturabilirsin.

---

## Proje Kuralları (uy)

- **Türkçe** yaz (rapor, gözlemler, commit mesajları).
- **Geriye uyumluluk kodu YOK** (bkz. `CLAUDE.md`) — yedek şeması sürüm-kapılıdır;
  9.7 bu politikanın testidir.
- Rapor mevcut biçimi bozulmadan büyütülür; senaryo numaraları **yeniden numaralanmaz**.
- Kod değiştirmen gerekmez; görev **test + rapor**. Bir hata bulursan kodu düzeltmeyi
  öner ama önce raporla.

---

## Teslim Edilecekler

1. Güncellenmiş `SMOKE_TEST_REPORT.md` (gerçek gözlemler, kanıtlar, güncel sayaç).
2. `test_screenshots/` altına yeni, anlamlı adlı ekran görüntüleri.
3. Bulunan her hata için "Tespit Edilen Hatalar" bölümünde net madde (sorun + çözüm önerisi).

**Unutma:** Kanıtsız `✅` yok. Emin değilsen `🔄` bırak ve nedenini yaz. Dürüst rapor,
eksiksiz görünen rapordan iyidir.
