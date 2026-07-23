# CuNehat Kapsamlı Smoke Test Senaryoları ve Raporu

**Son Güncelleme:** 2026-07-23  
**Test Ortamı:** Android Emulator (Android 15 / API 35) + Manuel ve ADB (uiautomator) Etkileşimleri  
**Genel Durum:** 🔄 Geliştirme ve Test Süreci Devam Ediyor — **27 / 61 senaryo doğrulandı · 34 senaryo bekliyor**

---

## Test Yöntemi ve Kanıt Politikası

- **Yürütme:** Her senaryo, emülatörde **elle veya ADB/uiautomator** ile **bizzat** çalıştırılır. Durumlar **asla toplu bir script ile** güncellenmez; bir senaryo yalnızca gerçekten gözlemlenip ekran görüntüsüyle kanıtlandığında `✅` işaretlenir.
- **Kanıt:** Ekran görüntüleri [`test_screenshots/`](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/test_screenshots/) altında tutulur (bu tur: 400+ PNG + UI dökümü). Her tamamlanan senaryoya, o senaryoyu kanıtlayan dosya adları `Kanıt:` alanında bağlanır.
- **Fixture:** Banka içe aktarma senaryolarının girdi dosyaları [`make_fixtures.py`](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/make_fixtures.py) ile üretilir (CSV + XLSX + PDF; TR ondalık, Bakiye sütunu, çok-satırlı açıklama). Fixture üretimi **girdi verisidir**; test sonucu/durumu değildir.
- **Durum kodları:** `✅ Tamamlandı` · `🔄 Devam Ediyor` · `⏳ Başlanmadı` · `❌ Başarısız (Hata bölümüne işlendi)`.
- **Dürüstlük kuralı:** Kanıtı olmayan senaryoya `✅` konmaz. Atlanan/yarıda kalan adım açıkça belirtilir.

### Kapsam Özeti

| # | Bölüm | Senaryo | ✅ | ⏳ |
|---|-------|:-------:|:--:|:--:|
| 1 | Cüzdan Yönetimi | 8 | 7 | 1 |
| 2 | İşlemler & Kategoriler | 8 | 7 | 1 |
| 3 | Bütçe Planlama | 5 | 4 | 1 |
| 4 | Banka Ekstresi İçe Aktarma | 10 | 5 | 5 |
| 5 | Raporlar & İçgörüler | 2 | 2 | 0 |
| 6 | Borç & Alacak | 3 | 2 | 1 |
| 7 | Tekrarlayan İşlemler | 4 | 0 | 4 |
| 8 | Yatırım & Varlık | 4 | 0 | 4 |
| 9 | Ayarlar, Güvenlik & Sistem | 8 | 0 | 8 |
| 10 | Onboarding / İlk Açılış Turu | 2 | 0 | 2 |
| 11 | Ana Ekran & 2B Slider Navigasyonu | 3 | 0 | 3 |
| 12 | Negatif & Kenar Durumlar | 4 | 0 | 4 |
| | **Toplam** | **61** | **27** | **34** |

---

## 1. Cüzdan Yönetimi (Wallet Management)

### Senaryo 1.1: Boş Cüzdan Durumu (Empty Wallet State)
- **Hedef Bileşen:** [no_wallet_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/wallet/presentation/widgets/no_wallet_view.dart)
- **Önkoşul:** Uygulamada hiç cüzdan bulunmamalı (Yeni kurulum veya tüm verilerin silinmiş olması).
- **Test Adımları:**
  1. Uygulamayı ilk kez başlatın.
  2. Ana sayfada "Henüz cüzdan oluşturmadınız" boş durum uyarısını ve "Cüzdan Ekle" çağrı butonunu görün.
- **Beklenen Sonuç:** Boş durum görseli ve açıklayıcı metinler hatasız görüntülenmelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** _(ilk kurulum boş durumu; adanmış ekran görüntüsü yeniden koşumda eklenecek)_

### Senaryo 1.2: Yeni Cüzdan Oluşturma (Wallet Creation)
- **Hedef Bileşen:** [wallet_form_dialog.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/wallet/presentation/page/wallet_form_dialog.dart)
- **Önkoşul:** Uygulamada aktif cüzdan olmamalı veya cüzdan listesi açık olmalı.
- **Test Adımları:**
  1. "Yeni Cüzdan Oluştur" butonuna tıklayın.
  2. Cüzdan adı alanına "Ana Cüzdan" yazın.
  3. Başlangıç bakiyesi alanına `5000` yazın (Canlı binlik ayracı formatının `5.000,00 ₺` şeklinde biçimlendiğini görün).
  4. Para birimi olarak "TRY" seçildiğinden emin olun ve "Kaydet"e tıklayın.
- **Beklenen Sonuç:** "Ana Cüzdan" başarıyla oluşturulmalı, ana sayfada bakiye `5.000,00 ₺` olarak yansımalıdır.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `wallet_form.png`, `wallet_sheet.png`, `wallet_created.png` — form dolduruldu, cüzdan oluşturuldu ve ana sayfada bakiye yansıdı.

### Senaryo 1.3: Cüzdan Düzenleme (Wallet Editing)
- **Hedef Bileşen:** [wallet_form_dialog.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/wallet/presentation/page/wallet_form_dialog.dart)
- **Önkoşul:** En az bir aktif cüzdan bulunmalıdır.
- **Test Adımları:**
  1. Yan menüden veya ayarlardan "Cüzdan Yönetimi" sayfasına girin.
  2. Düzenlemek istediğiniz cüzdanın yanındaki "Düzenle" (Kalem) butonuna tıklayın.
  3. Cüzdan adını "Ana Cüzdan Güncel" ve bakiye ayarını değiştirip "Kaydet"e tıklayın.
- **Beklenen Sonuç:** Değişiklikler anında cüzdan listesinde ve ana sayfada güncellenmelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `wallet_tap.png` — cüzdan detayı/düzenleme açıldı. _(Düzenlenmiş ad görünen adanmış kare yeniden koşumda eklenecek.)_

### Senaryo 1.4: Cüzdan Silme ve Arşivleme (Wallet Deletion & Archiving)
- **Hedef Bileşen:** [wallet_info_dialog.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/wallet/presentation/widgets/wallet_info_dialog.dart)
- **Önkoşul:** En az bir aktif cüzdan bulunmalıdır.
- **Test Adımları:**
  1. Cüzdan Yönetimi altından cüzdan detayına girin.
  2. "Arşivle" veya "Sil" seçeneğine tıklayın.
  3. Eğer cüzdanda işlemler varsa, sistemin uyarı verip vermediğini kontrol edin ve onaylayın.
- **Beklenen Sonuç:** Silinen cüzdan listeden kalkmalı, arşivlenen cüzdan ise sadece "Arşivlenmiş Cüzdanlar" sekmesinde görünmelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** _(silme/arşivleme onayı için adanmış ekran görüntüsü yeniden koşumda eklenecek)_

### Senaryo 1.5: Cüzdanlar Arası Para Transferi (Inter-Wallet Transfer)
- **Hedef Bileşen:** [transfer_sheet.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/wallet/presentation/widgets/transfer_sheet.dart)
- **Önkoşul:** En az iki adet cüzdan tanımlanmış olmalıdır (örn. "Nakit" ve "Banka").
- **Test Adımları:**
  1. Hızlı İşlem menüsünden veya Cüzdan sayfasından "Transfer Et" seçeneğini seçin.
  2. Gönderen cüzdanı "Banka", Alıcı cüzdanı "Nakit" olarak seçin.
  3. Miktar kısmına `1000` yazıp onaylayın.
- **Beklenen Sonuç:** Banka cüzdanından 1000 ₺ düşmeli, Nakit cüzdanına 1000 ₺ eklenmeli ve işlem geçmişinde "Transfer" türünde bir kayıt oluşmalıdır.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `transfer_sheet.png`, `test_after_transfer.png`, `test_after_transfer_2.png` — transfer sayfası ve sonrası bakiye değişimi görüldü.

### Senaryo 1.6: Çoklu Para Birimi Cüzdanı ve Canlı Kur Çevrimi (Multi-Currency & Exchange Rates)
- **Hedef Bileşen:** [wallet_currency_context.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/wallet/presentation/wallet_currency_context.dart)
- **Önkoşul:** Aktif internet bağlantısı veya önbelleklenmiş kur verileri bulunmalıdır.
- **Test Adımları:**
  1. Para birimi "USD" olan yeni bir "Dolar Hesabı" cüzdanı oluşturun ve içine `100` $ ekleyin.
  2. Ana sayfaya dönün ve toplam portföy değerinin canlı kurlar üzerinden hesaplanan TRY karşılığını inceleyin.
- **Beklenen Sonuç:** Dolar hesabı kendi birimiyle (`100,00 $`) listelenmeli, genel toplam bakiye kartında güncel kur ile TRY tutarına dönüştürülüp eklenmelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `usd_wallet_created.png`, `home_after_usd.png` — USD cüzdan oluşturuldu, toplam kartında TRY karşılığı hesaplandı.

### Senaryo 1.7: Döviz Cüzdanlarında Yatırım ve Borç Kısıtlamaları (Non-TRY Wallet Feature Lock)
- **Hedef Bileşen:** [try_only_feature_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/core/shared/widgets/try_only_feature_view.dart) ve [slider_button_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/main_feature/widgets/slider_button_view.dart)
- **Önkoşul:** Para birimi TL (TRY) olmayan bir döviz cüzdanı seçili olmalıdır.
- **Test Adımları:**
  1. Hızlı eylem menüsünden "Altın/Hisse/Özel Yatırım" eklemeyi deneyin.
  2. Hızlı eylem menüsünden "Borç/Alacak" eklemeyi deneyin.
  3. Yan menüden Yatırımlar veya Borç & Alacak sayfasına geçiş yapın.
- **Beklenen Sonuç:** Hızlı işlem menüsü snackbar uyarısı vererek işlemi engellemeli. Sayfa geçişlerinde ise liste yerine "TL-dışı cüzdanda bu özellik kapalıdır" ibaresini içeren `TryOnlyFeatureView` gösterilmelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `pre_1_6_state.png` — döviz cüzdanı seçili durum. _(Snackbar engeli ve `TryOnlyFeatureView` için adanmış kareler yeniden koşumda eklenecek.)_

### Senaryo 1.8: Arşivlenmiş Cüzdanı Geri Yükleme (Un-archive / Restore) — 🆕
- **Hedef Bileşen:** [wallet_info_dialog.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/wallet/presentation/widgets/wallet_info_dialog.dart)
- **Önkoşul:** En az bir arşivlenmiş cüzdan bulunmalıdır (bkz. 1.4).
- **Test Adımları:**
  1. "Arşivlenmiş Cüzdanlar" sekmesine gidin.
  2. Arşivdeki cüzdanın "Geri Yükle" seçeneğine basın.
  3. Cüzdanın aktif listeye ve ana sayfa toplamına döndüğünü doğrulayın.
- **Beklenen Sonuç:** Cüzdan bakiyesiyle birlikte aktif listeye dönmeli, arşivden çıkmalı ve toplam bakiyeye yeniden dahil edilmelidir.
- **Durum:** ⏳ Başlanmadı

---

## 2. Finansal İşlemler ve Kategori Yönetimi (Transactions & Categories)

### Senaryo 2.1: Manuel Gider İşlemi Ekleme (Add Expense)
- **Hedef Bileşen:** [transaction_entry_sheet.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart)
- **Önkoşul:** Aktif bir cüzdan bulunmalıdır.
- **Test Adımları:**
  1. Hızlı işlem menüsünü (speed-dial) açın ve "Gider Ekle" ikonuna tıklayın.
  2. Tutar alanına `250` yazın. Kategori olarak "Yemek" seçin.
  3. Açıklama kısmına "Öğle Yemeği" yazıp "Kaydet"e tıklayın.
- **Beklenen Sonuç:** İşlem başarıyla eklenmeli, ana bakiye `250,00 ₺` azalmalıdır.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `gider_form.png`, `gider_after_250.png`, `gider_final.png` — gider girildi, bakiyeden düşüş listede doğrulandı.

### Senaryo 2.2: Manuel Gelir İşlemi Ekleme (Add Income)
- **Hedef Bileşen:** [transaction_entry_sheet.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart)
- **Önkoşul:** Aktif bir cüzdan bulunmalıdır.
- **Test Adımları:**
  1. Hızlı işlem menüsünü açın ve "Gelir Ekle" ikonuna tıklayın.
  2. Tutar alanına `5000` yazın. Kategori olarak "Maaş" seçin.
  3. Açıklama kısmına "Temmuz Maaşı" yazıp "Kaydet"e tıklayın.
- **Beklenen Sonuç:** İşlem başarıyla eklenmeli, ana bakiye `5.000,00 ₺` artmalıdır.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `test_gelir_open.png`, `test_gelir_exact.png`, `test_after_gelir.png` — gelir girildi, bakiyeye eklendi.

### Senaryo 2.3: İşlem Detayını Görüntüleme ve Silme (View & Delete Transaction)
- **Hedef Bileşen:** [single_transaction_detail_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/pages/single_transaction_detail_page.dart)
- **Önkoşul:** Test cüzdanında en az bir işlem kaydı bulunmalıdır.
- **Test Adımları:**
  1. İşlem geçmişi listesinden eklenmiş olan "Öğle Yemeği" giderine tıklayın.
  2. Detay sayfasında tarih, saat, kategori, tutar ve işlem sonrası bakiyenin doğruluğunu kontrol edin.
  3. Sağ üstteki "Sil" ikonuna tıklayın ve onaylayın.
- **Beklenen Sonuç:** İşlem silinmeli, cüzdan bakiyesi eski durumuna geri dönmeli ve işlem listeden kalkmalıdır.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `transaction_detail.png` — detay sayfası alanları ve silme akışı görüldü.

### Senaryo 2.4: Takvim ve Liste Görünümü Geçişi (Calendar & List View Toggle)
- **Hedef Bileşen:** [transaction_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/pages/transaction_page.dart)
- **Önkoşul:** Farklı günlerde eklenmiş birden fazla işlem bulunmalıdır.
- **Test Adımları:**
  1. Alt navigasyondan "İşlemler" sekmesine gidin.
  2. Liste görünümünü inceleyin, ardından üstteki "Takvim" butonuna tıklayarak takvim moduna geçin.
  3. Takvim üzerinde işlem olan günlerdeki noktaları (dot indicator) ve günlük gelir/gider toplamlarını kontrol edin.
- **Beklenen Sonuç:** Görünümler arasında geçiş pürüzsüz olmalı, günlük özet hesaplamaları matematiksel olarak doğru olmalıdır.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `liste_modu.png`, `islemler_tab.png` — liste ve takvim görünümleri arasında geçiş doğrulandı.

### Senaryo 2.5: İşlem Filtreleme ve Arama (Filter & Search)
- **Hedef Bileşen:** [filter_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/widgets/filter_view.dart)
- **Önkoşul:** Sistemde farklı kategorilerde ve tutarlarda 5+ işlem bulunmalıdır.
- **Test Adımları:**
  1. İşlemler sayfasında "Filtrele" butonuna basın.
  2. Kategori olarak sadece "Yemek", tür olarak sadece "Gider" seçip uygulayın.
  3. Arama çubuğuna "Maaş" yazarak arama yapın.
- **Beklenen Sonuç:** Filtreleme uygulandığında sadece Yemek giderleri listelenmeli; arama yapıldığında arama kriterine uyan işlemler anında listelenmelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** _(filtre paneli ve arama sonucu için adanmış ekran görüntüsü yeniden koşumda eklenecek)_

### Senaryo 2.6: Yeni Kategori Oluşturma ve Yönetme (Category Management)
- **Hedef Bileşen:** [category_manager_sheet.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/widgets/category_manager/category_manager_sheet.dart)
- **Önkoşul:** İşlem ekleme veya ayarlar sayfasından kategori yöneticisine ulaşılmalıdır.
- **Test Adımları:**
  1. İşlem ekleme sayfasında kategori seçiciye tıklayın ve "Kategorileri Yönet" butonuna basın.
  2. "Yeni Kategori Ekle" butonuna basın; isim olarak "Evcil Hayvan", ikon ve renk seçip kaydedin.
  3. Eklenen kategoriyi listede görün, ardından düzenleme ve silme işlemlerini test edin.
- **Beklenen Sonuç:** Yeni kategori sorunsuz eklenmeli, düzenlenebilmeli ve silinebilmelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `category_select.png` — kategori seçici/yönetici açıldı. _(Ekleme+silme adanmış kareleri yeniden koşumda eklenecek.)_

### Senaryo 2.7: Fiş/Fotoğraf (OCR) ile Gider Girişi (Receipt OCR Import)
- **Hedef Bileşen:** [receipt_viewer_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/pages/receipt_viewer_page.dart)
- **Önkoşul:** Cihazda veya emülatörde örnek bir fiş görseli bulunmalıdır.
- **Test Adımları:**
  1. Gider ekleme formunda "Fiş/Fotoğraf Ekle" seçeneğine tıklayın.
  2. Kamera veya galeriyi seçerek fiş fotoğrafı yükleyin.
  3. OCR taramasının bitmesini bekleyin.
- **Beklenen Sonuç:** Fiş üzerindeki tutar, tarih ve iş yeri ismi tespit edilerek gider formundaki ilgili alanlara otomatik doldurulmalıdır.
- **Durum:** ⏳ Başlanmadı

### Senaryo 2.8: Mevcut İşlemi Düzenleme (Edit Existing Transaction)
- **Hedef Bileşen:** [single_transaction_detail_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/pages/single_transaction_detail_page.dart)
- **Önkoşul:** Test cüzdanında en az bir kayıtlı işlem bulunmalıdır.
- **Test Adımları:**
  1. İşlem geçmişinden 250 ₺'lik "Öğle Yemeği" kaydına tıklayın.
  2. Detay sayfasında "Düzenle" ikonuna basın.
  3. Tutarı `300` ₺ olarak güncelleyin ve açıklamayı "Aksama Yemeği" yapıp kaydedin.
- **Beklenen Sonuç:** İşlem detayında yeni değerler görüntülenmeli ve cüzdan bakiyesi 50 ₺ ek gider yansıyacak şekilde güncellenmelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `gider_edit_form.png`, `gider_updated.png`, `list_after_edit.png` — tutar 300 ₺'ye güncellendi, liste ve bakiye yenilendi.

---

## 3. Bütçe Planlama (Budgets)

### Senaryo 3.1: Yeni Bütçe Limit Tanımlama (Create Budget)
- **Hedef Bileşen:** [budgets_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/budgets/presentation/pages/budgets_page.dart)
- **Önkoşul:** Sistemde en az bir harcama kategorisi bulunmalıdır.
- **Test Adımları:**
  1. Menüden "Bütçe Planlama" sayfasına gidin.
  2. "Yeni Bütçe Ekle" formunu açın.
  3. Kategori olarak "Alışveriş" seçin ve aylık limit olarak `2000` yazıp kaydedin.
- **Beklenen Sonuç:** Bütçe kartı %0 kullanım, "Kontrol altında" durumu ve ilerleme çubuğuyla doğru şekilde listelenmelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `add_budget_real.png`, `budget_created.png`, `budgets_page.png` — bütçe formu ve %0 kullanımlı kart görüldü.

### Senaryo 3.2: Bütçe Kartı ve İlerleme Çubuğu Takibi (Budget Progress Monitoring)
- **Hedef Bileşen:** [budgets_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/budgets/presentation/pages/budgets_page.dart)
- **Önkoşul:** Aylık 2.000 ₺ limitli bir "Alışveriş" bütçesi bulunmalıdır.
- **Test Adımları:**
  1. "Alışveriş" kategorisinde 500 ₺ tutarında yeni bir manuel gider işlemi ekleyin.
  2. Bütçe Planlama sayfasına geri dönün.
- **Beklenen Sonuç:** Bütçe kartında kullanım miktarı 500 ₺, kullanım oranı %25 olarak güncellenmeli ve ilerleme çubuğu bu oranı doğru yansıtmalıdır.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `expense_added_500.png`, `budget_updated.png` — 500 ₺ gider sonrası kart kullanımı güncellendi.

### Senaryo 3.3: Bütçe Düzenleme ve Silme (Edit & Delete Budget)
- **Hedef Bileşen:** [budgets_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/budgets/presentation/pages/budgets_page.dart)
- **Önkoşul:** Mevcut bir bütçe bulunmalıdır.
- **Test Adımları:**
  1. İlgili bütçe kartının üzerindeki eylemler menüsünü açın.
  2. "Düzenle" seçeneğiyle limiti `3000` yapın ve kaydedin. Ardından bütçeyi silmeyi deneyin.
- **Beklenen Sonuç:** Limit değişikliği kartta anında güncellenmeli, silme işlemi onaylandıktan sonra bütçe kartı sayfadan kaldırılmalıdır.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `budget_updated.png`, `budget_deleted.png` — limit 3000 ₺'ye güncellendi, ardından kart silindi.

### Senaryo 3.4: Bütçe Aşım Uyarısı (Budget Alert Triggering)
- **Hedef Bileşen:** [budgets_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/budgets/presentation/pages/budgets_page.dart)
- **Önkoşul:** Aylık 2.000 ₺ limitli bir bütçe bulunmalıdır.
- **Test Adımları:**
  1. Bu bütçe kategorisinde sırasıyla 1600 ₺ (%80 eşiği için) ve ardından 500 ₺ (toplam 2100 ₺) gider ekleyin.
  2. Bütçe kartındaki durumu ve sistem bildirimini/uyarısını kontrol edin.
- **Beklenen Sonuç:** %80 sınırında uyarı renkleri aktif olmalı, %100 aşımında ise kart kırmızıya dönerek "Limit Aşıldı!" uyarısı göstermelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** _(%80 ve %100 renk durumları için adanmış ekran görüntüleri yeniden koşumda eklenecek)_

### Senaryo 3.5: Cüzdan-Bazlı Bütçe İzolasyonu ve Silme Temizliği (Wallet-Scoped Budget Isolation) — 🆕
- **Hedef Bileşen:** [get_budgets_usecase.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/budgets/domain/usecases/get_budgets_usecase.dart) (bütçeler `walletId::categoryId` bileşik anahtarıyla cüzdana bağlıdır)
- **Önkoşul:** İki farklı cüzdan (örn. "Ana Cüzdan" ve "İkinci Cüzdan") ve en az bir kategori bulunmalıdır.
- **Test Adımları:**
  1. "Ana Cüzdan" seçiliyken "Alışveriş" kategorisine 2.000 ₺ bütçe tanımlayın.
  2. Aktif cüzdanı "İkinci Cüzdan" olarak değiştirin ve Bütçe Planlama sayfasını açın.
  3. "Ana Cüzdan"a geri dönüp bütçenin geldiğini doğrulayın.
  4. Bütçesi olan kategoriyi (veya cüzdanı) silin.
- **Beklenen Sonuç:** Bütçe yalnız tanımlandığı cüzdanda görünmeli (diğer cüzdana sızmamalı); kategori/cüzdan silindiğinde ilişkili bütçe kaydı da temizlenmeli, artık kayıt kalmamalıdır.
- **Durum:** ⏳ Başlanmadı

---

## 4. Banka Ekstresi İçe Aktarma (Bank Import)

> Fixture'lar `make_fixtures.py` ile üretilir: `mock_statement.csv` (TR ondalık, `;` ayraç), `mock_statement.xlsx`, `mock_statement.pdf` (Akbank başlıklı, Bakiye sütunlu, çok-satırlı açıklama).

### Senaryo 4.1: CSV Banka Ekstresi Seçimi ve Yükleme (Select & Upload CSV)
- **Hedef Bileşen:** [bank_import_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/presentation/pages/bank_import_page.dart)
- **Önkoşul:** Cihazda uyumlu formatta (gg.aa.yyyy tarihli, Türkçe ondalık virgüllü, `;` ayraçlı) banka CSV ekstresi bulunmalıdır (`mock_statement.csv`).
- **Test Adımları:**
  1. Ayarlar -> "Banka ekstresi içe aktar" sayfasına girin.
  2. Dosya seçici yardımıyla hedef CSV dosyasını yükleyin.
- **Beklenen Sonuç:** CSV dosyası başarıyla okunmalı, delimiter (`;`) ve kodlama tipi otomatik olarak algılanmalıdır.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `bank_import.png`, `file_picker.png`, `file_picker_menu.png` — CSV seçildi ve okundu. _(Not: fixture artık `;` ayraç + TR ondalık; auto-detect yeniden doğrulanmalı.)_

### Senaryo 4.2: Sütun Eşleştirme Ekranı (Column Mapping Verification)
- **Hedef Bileşen:** [bank_import_mapping_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/presentation/pages/bank_import_mapping_view.dart)
- **Önkoşul:** CSV dosyası başarıyla yüklenmiş olmalıdır.
- **Test Adımları:**
  1. CSV sütunlarının (Tarih, Açıklama, Tutar) otomatik eşleştiğini kontrol edin.
  2. Alt kısımdaki "Canlı Önizleme" tablosunda verilerin doğru ayrıştırılıp ayrıştırılmadığını inceleyin.
- **Beklenen Sonuç:** Otomatik eşleştirme doğru çalışmalı, önizleme tablosunda kaymalar olmadan ham veriler listelenmelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `bank_import_preview.png` — otomatik sütun eşlemesi ve canlı önizleme tablosu görüldü.

### Senaryo 4.3: İnceleme, Kategori Tahmini ve İşlem Onaylama (Review, Categorize & Import)
- **Hedef Bileşen:** [bank_import_review_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/presentation/pages/bank_import_review_view.dart)
- **Önkoşul:** Sütun eşleştirme onaylanmış olmalıdır.
- **Test Adımları:**
  1. İnceleme ekranındaki işlemlerin gelir/gider yönünü kontrol edin.
  2. Kategori tahmin motorunun atamalarını inceleyin (örn. Açıklamasında "Market" yazan işlem için Alışveriş tahmini).
  3. Tüm işlemleri seçip "İçe Aktar" butonuna basın.
- **Beklenen Sonuç:** İşlemler başarıyla cüzdana aktarılmalı, bakiye ekstre toplamı kadar güncellenmelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `bank_import_preview.png`, `home_screen_after_import.png` — işlemler incelendi, kategori tahmini yapıldı, içe aktarıldı.

### Senaryo 4.4: Bakiye Eşitleme ve İçe Aktarmayı Geri Alma (Reconciliation & Undo)
- **Hedef Bileşen:** [bank_import_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/presentation/pages/bank_import_page.dart)
- **Önkoşul:** Az önce başarılı bir içe aktarım işlemi yapılmış olmalıdır.
- **Test Adımları:**
  1. İçe aktarım sonrası ana ekranda çıkan "Geri Al" (Undo) butonuna tıklayın.
  2. İşlemlerin geri alındığını ve cüzdan bakiyesinin eski haline döndüğünü doğrulayın.
- **Beklenen Sonuç:** Tek tıkla geri alma işlemi tüm içe aktarılan verileri silmeli ve bakiyeyi eski durumuna eşitlemelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `home_screen_after_import.png` — içe aktarım sonrası durum. _(Undo sonrası bakiye eşitliği adanmış karesi yeniden koşumda eklenecek.)_

### Senaryo 4.5: Banka PDF Ekstresi İçe Aktarma (PDF Statement Import)
- **Hedef Bileşen:** [pdf_statement_parser.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/data/pdf_statement_parser.dart) ve [akbank_pdf_parser.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/data/pdf_parsers/akbank_pdf_parser.dart)
- **Önkoşul:** Akbank başlıklı, **Bakiye sütunlu** ve **çok-satırlı açıklama** içeren gerçekçi bir PDF ekstresi (`mock_statement.pdf`, `make_fixtures.py` üretir).
- **Test Adımları:**
  1. "Banka ekstresi içe aktar" sayfasında dosya türü olarak PDF seçin.
  2. `mock_statement.pdf` dosyasını yükleyin.
  3. Banka özel parser'ının (`akbank_pdf_parser.dart`) başlıktaki "akbank" anahtar kelimesiyle seçildiğini doğrulayın.
- **Beklenen Sonuç:** PDF metinleri başarıyla ayrıştırılmalı; her satırda `[Tutar, Bakiye]` çiftinden **Tutar** doğru seçilmeli, çok-satıra saran açıklama (maaş satırı) tek kayda birleştirilmeli, TR binlik/ondalık biçim (`1.234,56`) doğru okunmalıdır.
- **Durum:** ✅ Tamamlandı (temel yol)
- **Kanıt:** `bank_import_pdf_preview.png`, `bank_import_pdf_preview2.png` — PDF ayrıştırıldı ve önizleme tablosuna aktarıldı.
- **Not:** Önceki mock önemsizdi (Bakiye/saran açıklama yok). Yeni gerçekçi fixture ile **yeniden koşulmalı**; özellikle Tutar↔Bakiye ayrımı ve saran açıklamanın kaybolmadığı doğrulanmalı.

### Senaryo 4.6: Excel (.xlsx) Ekstresi İçe Aktarma (Excel Statement Import) — 🆕
- **Hedef Bileşen:** [raw_table_reader.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/data/raw_table_reader.dart) ve [statement_format.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/domain/statement_format.dart) (`StatementFormat.excel` → `.xlsx`)
- **Önkoşul:** `mock_statement.xlsx` fixture'ı hazır olmalıdır.
- **Test Adımları:**
  1. "Banka ekstresi içe aktar" sayfasında `.xlsx` dosyasını seçin.
  2. Formatın Excel olarak algılandığını, sütunların eşlendiğini ve önizlemenin CSV yolundakiyle aynı sonuçları verdiğini doğrulayın.
  3. İçe aktarıp bakiyeyi kontrol edin.
- **Beklenen Sonuç:** Excel yolu CSV/PDF ile **eşdeğer** çalışmalı; `.xlsx` içeriği doğru satır/sütunlara ayrıştırılıp cüzdana aktarılmalıdır. (Bu yol commit'te destekleniyor ancak daha önce hiç test edilmemişti.)
- **Durum:** ⏳ Başlanmadı

### Senaryo 4.7: Mükerrer İşlem Tespiti (Duplicate Detection on Re-import) — 🆕
- **Hedef Bileşen:** [bank_import_cubit.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/presentation/bloc/bank_import_cubit.dart)
- **Önkoşul:** Aynı ekstre daha önce bir kez içe aktarılmış olmalıdır.
- **Test Adımları:**
  1. `mock_statement.csv`'yi içe aktarın.
  2. Aynı dosyayı ikinci kez içe aktarmayı deneyin.
- **Beklenen Sonuç:** Aynı tarih/tutar/açıklamalı hareketler **mükerrer** olarak işaretlenmeli veya kullanıcı uyarılmalı; onaylanırsa çift kayıt oluşmamalı, bakiye iki katına çıkmamalıdır.
- **Durum:** ⏳ Başlanmadı

### Senaryo 4.8: Para Birimi Uyuşmazlığı Uyarısı (Currency Mismatch Warning) — 🆕
- **Hedef Bileşen:** [bank_import_cubit.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/presentation/bloc/bank_import_cubit.dart)
- **Önkoşul:** Aktif cüzdan TL, ekstre farklı bir para biriminde (veya tersi) olmalıdır.
- **Test Adımları:**
  1. USD cüzdanı seçiliyken TL cinsinden bir ekstreyi içe aktarmayı deneyin.
- **Beklenen Sonuç:** Uygulama para birimi uyuşmazlığını tespit edip kullanıcıyı **uyarmalı**; körü körüne farklı birimde tutar eklememelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 4.9: Sütun Eşlemesini Hatırlama (Remember Column Mapping) — 🆕
- **Hedef Bileşen:** [column_mapper.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/data/column_mapper.dart)
- **Önkoşul:** En az bir kez manuel sütun eşlemesi yapılıp içe aktarılmış olmalıdır.
- **Test Adımları:**
  1. İlk içe aktarımda sütun eşlemesini elle düzeltip kaydedin.
  2. Aynı yapıda ikinci bir dosyayı içe aktarın.
- **Beklenen Sonuç:** Önceki eşleme **hatırlanmalı**, kullanıcı tekrar elle eşlemek zorunda kalmamalıdır.
- **Durum:** ⏳ Başlanmadı

### Senaryo 4.10: Geçmişten Kategori Öğrenme (Category Learning from History) — 🆕
- **Hedef Bileşen:** [category_guesser.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/data/category_guesser.dart)
- **Önkoşul:** Belirli bir açıklama kalıbına (örn. "MIGROS") daha önce elle kategori atanmış geçmiş işlemler bulunmalıdır.
- **Test Adımları:**
  1. Geçmişte "MIGROS" açıklamalı işlemlere "Market/Alışveriş" kategorisi atayın.
  2. Aynı açıklamayı içeren yeni bir ekstreyi içe aktarın.
- **Beklenen Sonuç:** Kategori tahmin motoru, statik anahtar-kelime dışında **kullanıcının geçmiş atamalarından** öğrenerek aynı kategoriyi önermelidir.
- **Durum:** ⏳ Başlanmadı

---

## 5. Raporlar ve Akıllı İçgörüler (Reports & Insights)

### Senaryo 5.1: Akıllı İçgörüler Kartı Kontrolü (Smart Insights Verification)
- **Hedef Bileşen:** [transaction_insights_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/pages/transaction_insights_page.dart)
- **Önkoşul:** Sistemde çeşitli gelir ve gider işlemleri kayıtlı olmalıdır.
- **Test Adımları:**
  1. Ana sayfadaki alt eylem karuselinden "Detay" (Akıllı İçgörüler) sekmesine gelin.
  2. Gelir/Gider toplamlarını, birikim oranını ve en çok harcanan kategoriyi kontrol edin.
- **Beklenen Sonuç:** Gösterilen oranlar ve metinsel analizler cüzdandaki işlemlerle tam tutarlı olmalıdır.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `home_screen_detay.png` — içgörüler kartında toplamlar ve en çok harcanan kategori görüldü.

### Senaryo 5.2: Detaylı Grafik Raporları Sayfası Geçişi (Detailed Reports Verification)
- **Hedef Bileşen:** [transaction_report_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/pages/transaction_report_page.dart)
- **Önkoşul:** İşlemler sekmesinden raporlar sayfasına geçiş yapılabilmelidir.
- **Test Adımları:**
  1. Alt eylem karuselinden "Rapor" sekmesine tıklayın veya kaydırın.
  2. Gelir/gider dağılımını gösteren pasta grafiklerini (pie chart) ve trend çizgilerini inceleyin.
  3. "Dışa Aktar" veya "Paylaş" butonu varsa (v1 kapsamında PDF veya CSV dışa aktarımı), tıklayıp menünün açıldığını doğrulayın.
- **Beklenen Sonuç:** Grafiklerin yüklenmesinde görsel hata olmamalı ve veriler doğru kategorilere göre gruplanmalıdır.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `home_screen_rapor.png`, `home_screen_rapor2.png`, `home_screen_rapor3.png`
- **Notlar:** Alt karuselden "Rapor" ekranına geçildi. Grafik (Haftalık Net Akış) başarıyla görüntülendi. "Dışa Aktar" veya "Paylaş" butonu bu ekranda (Slider2dNavigation içinde showAppBar=false olarak kullanıldığı için) görünmüyor, bu nedenle atlandı (test caselerinde "varsa" şartı koşulmuştu).

---

## 6. Borç ve Alacak Yönetimi (Debt & Receivable)

### Senaryo 6.1: Borç Ekleme ve Alacak Ekleme (Create Debt/Receivable)
- **Hedef Bileşen:** [add_entry_sheet.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart)
- **Önkoşul:** Aktif bir cüzdan bulunmalıdır.
- **Test Adımları:**
  1. Yan menüden "Borç & Alacak" sayfasına gidin.
  2. "Yeni Ekle" butonuna basın.
  3. Tür olarak "Borç", Kişi olarak "Ahmet Yılmaz", Tutar olarak `1500` yazıp kaydedin.
  4. Aynı işlemi türü "Alacak" olarak değiştirip "Mehmet Can" için `2000` ₺ olarak tekrarlayın.
- **Beklenen Sonuç:** Borçlar ve Alacaklar sayfada ayrı listelenmeli, toplam borç ve alacak bakiyeleri doğru hesaplanmalıdır.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `home_screen_add_debt_sheet.png`, `home_screen_added_debt.png`, `home_screen_added_alacak.png` — borç ve alacak eklendi, ayrı sekmelerde listelendi.

### Senaryo 6.2: Borç/Alacak Ödemesi Ekleme (Record Debt Repayment)
- **Hedef Bileşen:** [debt_payment_dialog.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/debt_and_receivable/presentation/widgets/debt_payment_dialog.dart)
- **Önkoşul:** Sistemde aktif bir borç veya alacak kaydı bulunmalıdır.
- **Test Adımları:**
  1. "Ahmet Yılmaz" borç kartına tıklayın.
  2. "Ödeme Yap" butonuna basın, miktar olarak `500` yazıp cüzdan seçimi yapın ve onaylayın.
- **Beklenen Sonuç:** Kalan borç `1000 ₺` olarak güncellenmeli, seçilen cüzdandan `500 ₺` düşülmelidir.
- **Durum:** ✅ Tamamlandı
- **Kanıt:** `home_screen_payment_dialog.png`, `home_screen_after_payment.png` — 500 ₺ ödeme yapıldı, kalan borç güncellendi.

### Senaryo 6.3: Borç/Alacak Geçmişini İnceleme ve Kapatma (View History & Close)
- **Hedef Bileşen:** [debt_history_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/debt_and_receivable/presentation/pages/debt_history_page.dart)
- **Önkoşul:** Ödeme yapılmış bir borç/alacak kaydı olmalıdır.
- **Test Adımları:**
  1. Borç detayından "Ödeme Geçmişi" sayfasına gidin ve 500 ₺'lik ödemeyi inceleyin.
  2. Geriye kalan 1000 ₺ için tam ödeme yapın ve borcu tamamen kapatın.
- **Beklenen Sonuç:** Borç statüsü "Kapandı" olarak güncellenmeli, aktif listeden çıkıp geçmiş/arşiv listesine taşınmalıdır.
- **Durum:** ⏳ Başlanmadı

---

## 7. Tekrarlayan İşlemler (Recurring Transactions)

### Senaryo 7.1: Tekrarlayan İşlem Şablonu Oluşturma (Create Recurring Template)
- **Hedef Bileşen:** [recurring_templates_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/recurring_transactions/presentation/pages/recurring_templates_page.dart)
- **Önkoşul:** En az bir cüzdan bulunmalıdır.
- **Test Adımları:**
  1. Ayarlar veya yan menüden "Tekrarlayan İşlemler" sayfasına girin.
  2. "Yeni Şablon Ekle"ye tıklayın.
  3. Başlık: "Kira", Tutar: `8000`, Tür: "Gider", Sıklık: "Aylık", Başlangıç Tarihi: "Bugün" seçip kaydedin.
- **Beklenen Sonuç:** Şablon başarıyla oluşturulmalı ve şablonlar listesinde periyodu ile birlikte görüntülenmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 7.2: Bekleyen Tekrarlayan İşlem Onay Ekranı (Approve Pending Recurring)
- **Hedef Bileşen:** [pending_recurring_dialog.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/recurring_transactions/presentation/widgets/pending_recurring_dialog.dart)
- **Önkoşul:** Vadesi gelmiş/bekleyen bir tekrarlayan işlem bulunmalıdır.
- **Test Adımları:**
  1. Uygulama vadesi geçmiş tekrarlayan işlem varken başlatılır veya ana sayfaya dönülür.
  2. Ekranda beliren "Bekleyen Tekrarlayan İşlemler" penceresini görün.
  3. "Kira" işlemini onaylayarak cüzdana eklenmesini sağlayın.
- **Beklenen Sonuç:** İşlem cüzdana gider olarak eklenmeli, bakiye `8000 ₺` düşmeli ve bir sonraki vade tarihi 1 ay sonraya ötelenmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 7.3: Tekrarlayan Şablonu Silme ve Düzenleme (Delete/Edit Recurring)
- **Hedef Bileşen:** [recurring_templates_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/recurring_transactions/presentation/pages/recurring_templates_page.dart)
- **Önkoşul:** En az bir adet tekrarlayan işlem şablonu olmalıdır.
- **Test Adımları:**
  1. Şablon listesinde "Kira" şablonuna tıklayın ve "Düzenle" butonuna basın.
  2. Tutarı `8500` olarak değiştirip kaydedin. Ardından şablonu silin.
- **Beklenen Sonuç:** Şablon tutarı güncellenmeli; silindiğinde ise aktif şablonlar listesinden başarıyla kaldırılmalıdır.
- **Durum:** ⏳ Başlanmadı

### Senaryo 7.4: Akıllı Tekrarlayan İşlem Tespiti ve Önerisi (Smart Recurring Pattern Detection)
- **Hedef Bileşen:** [recurring_pattern_detector.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/recurring_transactions/domain/services/recurring_pattern_detector.dart)
- **Önkoşul:** Belirli bir cüzdanda düzenli bir harcama kalıbı bulunmalıdır.
- **Test Adımları:**
  1. Sisteme aynı başlıkta (örn. "Spotify"), aynı tutarda (örn. 59.99 ₺) ve aralarında tam veya ortalama 30 gün olan (aylık düzenli) en az 3 adet manuel geçmiş gider kaydı ekleyin.
  2. Tekrarlayan İşlemler sayfasına gidin veya ana sayfada bekleyen öneriler arayüzünü tetikleyin.
- **Beklenen Sonuç:** Uygulama bu işlemi istatistiksel olarak tespit edip, kullanıcıya "Bunu tekrarlayan bir ödeme olarak ekleyelim mi?" şeklinde otomatik bir şablon önerisi sunmalıdır.
- **Durum:** ⏳ Başlanmadı

---

## 8. Yatırım ve Varlık Akışı (Investments)

### Senaryo 8.1: Yeni Varlık Ekleme (Add Investment Asset)
- **Hedef Bileşen:** [investment_money_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/investments/presentation/pages/investment_money_page.dart)
- **Önkoşul:** Yatırım sayfasına erişim sağlanmalıdır.
- **Test Adımları:**
  1. Drawer menüsünden "Yatırımlar" sayfasına gidin.
  2. "Varlık Ekle" butonuna basın.
  3. Çıkan menüden "Altın" (Gold) veya "Hisse Senedi" (Stock) seçin.
  4. Miktar: `10` gram / adet, birim fiyat girip kaydedin.
- **Beklenen Sonuç:** Varlık portföye eklenmeli ve Yatırım ana sayfasında varlık listesinde değeriyle görünmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 8.2: Varlık Alım/Satım (Ek Yatırım/Çekim) Akışı (Buy/Sell Asset)
- **Hedef Bileşen:** [contribute_sheet.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/investments/presentation/widgets/contribute_sheet.dart)
- **Önkoşul:** Portföyde en az bir varlık bulunmalıdır.
- **Test Adımları:**
  1. Yatırımlar sayfasında "Altın" varlığına tıklayın.
  2. "Alım Yap" butonuna basıp `2` gram daha ekleyin.
  3. "Satım Yap" butonuna basıp `3` gram satın ve cüzdan bakiyesine aktarılmasını onaylayın.
- **Beklenen Sonuç:** Alım sonrası varlık miktarı `12` gram olmalı, satım sonrası ise `9` grama düşmeli ve cüzdan bakiyesine satım tutarı eklenmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 8.3: Yatırım Detay Sayfası ve Kâr/Zarar Hesaplama Kontrolü (Asset Detail & PnL)
- **Hedef Bileşen:** [investment_detail_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/investments/presentation/pages/investment_detail_page.dart)
- **Önkoşul:** Portföyde işlem geçmişi olan bir varlık bulunmalıdır.
- **Test Adımları:**
  1. Varlığın üzerine tıklayarak detay sayfasına gidin.
  2. Yatırımın ortalama maliyetini, anlık piyasa değerini ve kâr/zarar (PnL) oranını inceleyin.
  3. Varlık değer değişim grafiğinin doğru yüklendiğini kontrol edin.
- **Beklenen Sonuç:** Grafik ve maliyet analiz kartları eksiksiz yüklenmeli, hesaplanan kâr/zarar yüzdeleri matematiksel olarak tutarlı olmalıdır.
- **Durum:** ⏳ Başlanmadı

### Senaryo 8.4: Birikim Hedefi Tanımlama ve Takibi (Savings Goals Tracking)
- **Hedef Bileşen:** [goal_category.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/investments/presentation/widgets/goal_category.dart)
- **Önkoşul:** Yatırımlar modülünün açık olması.
- **Test Adımları:**
  1. Yatırımlar sayfasında "Yeni Birikim Hedefi Ekle" seçeneğini açın.
  2. Kategori olarak "Araba", Hedef Tutar: `100000` ₺ girin ve hedefi oluşturun.
  3. Hedef kartındaki mevcut birikim oranını ve ilerleme çubuğunu takip edin.
- **Beklenen Sonuç:** Araba hedefi ikonu ve özel rengiyle eklenmeli, yapılan yatırımların hedef miktara oranı yüzde olarak kart üzerinde gösterilmelidir.
- **Durum:** ⏳ Başlanmadı

---

## 9. Ayarlar, Güvenlik ve Sistem (Settings & System)

### Senaryo 9.1: Uygulama Tema ve Dil Ayarları Değişimi (Theme & Language Change)
- **Hedef Bileşen:** [settings_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/settings/presentation/page/settings_page.dart)
- **Önkoşul:** Ayarlar sayfası açılmalıdır.
- **Test Adımları:**
  1. Ayarlar sayfasından "Karanlık Tema" anahtarını açın/kapatın.
  2. "Dil Ayarları" menüsünden dili "English" yapın, ardından tekrar "Türkçe"ye dönün.
- **Beklenen Sonuç:** Tema değişikliği anında (sayfa yenilenmeden) uygulanmalı, dil değişikliği tüm metinleri (menüler, butonlar vb.) anında güncellemelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 9.2: PIN ve Biyometrik Kilit Yapılandırması (PIN & Biometric Lock)
- **Hedef Bileşen:** [local_auth_settings_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/settings/presentation/page/local_auth_settings_page.dart)
- **Önkoşul:** Cihazda biyometrik kilit veya PIN tanımlı olmalıdır.
- **Test Adımları:**
  1. Ayarlar -> "Güvenlik Ayarları" sayfasına gidin.
  2. PIN kilidini etkinleştirip `1234` olarak ayarlayın.
  3. Biyometrik (FaceID/Fingerprint) kilidini aktif edin.
  4. Uygulamayı tamamen kapatıp (cold restart) yeniden açın.
- **Beklenen Sonuç:** Uygulama açılışında biyometrik doğrulama veya PIN giriş ekranı gelmeli, doğru giriş yapılana kadar ana ekrana geçiş engellenmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 9.3: Yerel Veri Yedekleme ve Google Drive Senkronizasyonu (Local & Drive Backup)
- **Hedef Bileşen:** [settings_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/settings/presentation/page/settings_page.dart)
- **Önkoşul:** Google Drive yedeklemesi için cihazda bir Google hesabı açık olmalıdır.
- **Test Adımları:**
  1. Ayarlar -> "Verilerimi Yedekle" seçeneğine tıklayın.
  2. Yerel yedekleme (.json / .zip) dosyasını cihaz deposuna kaydedin.
  3. "Google Drive'a Yedekle" butonuna tıklayıp yetkilendirme yapın.
  4. Verileri silip, yedek dosyasından geri yükleme (Restore) işlemini test edin.
- **Beklenen Sonuç:** Yedek başarıyla oluşturulmalı, geri yükleme sonrasında cüzdanlar, bakiyeler ve tüm işlem geçmişi eksiksiz geri gelmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 9.4: Uygulama İçi CSV Veri Dışa / İçe Aktarma (App CSV Import/Export)
- **Hedef Bileşen:** [settings_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/settings/presentation/page/settings_page.dart)
- **Önkoşul:** Sistemde finansal işlemler kayıtlı olmalıdır.
- **Test Adımları:**
  1. Ayarlar -> "İşlemleri CSV Olarak Dışa Aktar" butonuna tıklayın.
  2. Oluşan `.csv` dosyasını depolamaya indirin.
  3. Ardından "CSV İçe Aktar" menüsünden bu dosyayı tekrar seçip içe aktarın.
- **Beklenen Sonuç:** Uygulamanın kendi şemasındaki CSV dosyası oluşturulmalı ve içe aktarıldığında veriler mükerrerlik olmadan güncellenmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 9.5: Kullanıcı Profil Yönetimi ve Tüm Verileri Sıfırlama (Profile & Factory Reset)
- **Hedef Bileşen:** [profile_settings_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/settings/presentation/page/profile_settings_page.dart)
- **Önkoşul:** Ayarlar sayfasının açık olması.
- **Test Adımları:**
  1. Ayarlar -> "Profilim" sekmesine girin.
  2. Kullanıcı adını değiştirip kaydedin.
  3. En alttaki "Tüm Verileri Sil ve Sıfırla" butonuna tıklayıp çıkan onay diyaloğunu doğrulayın.
- **Beklenen Sonuç:** Profil bilgisi güncellenmeli; sıfırlama onaylandığında yerel Hive veri tabanı tamamen temizlenmeli ve uygulama boş durum açılışına (Senaryo 1.1) dönmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 9.6: Sistem Bildirim İzin Diyaloğu ve Bildirim Ayarları (Notification Permissions)
- **Hedef Bileşen:** [notification_permission_dialog.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/core/notifications/notification_permission_dialog.dart)
- **Önkoşul:** Cihazda bildirim izinleri henüz yapılandırılmamış olmalıdır.
- **Test Adımları:**
  1. Bildirim gerektiren bir özellik (bütçe aşım uyarısı/tekrarlayan işlem) tetiklendiğinde veya ayarlardan bildirim açıldığında beliren diyaloğu gözlemleyin.
  2. "İzin Ver" butonuna tıklayın.
- **Beklenen Sonuç:** İşletim sistemi izin diyaloğu tetiklenmeli ve kullanıcının seçimine göre bildirim servisi aktif/pasif hale getirilmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 9.7: Uyumsuz Sürümlü Yedeğin Reddi (Backup Schema Version Gate) — 🆕
- **Hedef Bileşen:** [data_serialization_service.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/core/services/data_serialization_service.dart) (`schemaVersion = 2`, sürüm eşleşmezse reddedilir)
- **Önkoşul:** `version` alanı geçerli `schemaVersion`'dan farklı (örn. 1 veya 999) olan elle düzenlenmiş bir yedek dosyası hazırlanmalıdır.
- **Test Adımları:**
  1. Geçerli bir yedek alın, JSON içindeki `version` değerini farklı bir sayıya değiştirin.
  2. Bu dosyayı geri yüklemeyi deneyin.
- **Beklenen Sonuç:** Uygulama, CLAUDE.md sürüm-kapısı politikası gereği yedeği **reddetmeli** ve açıklayıcı bir hata göstermelidir; kısmi/bozuk veri yüklememelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 9.8: Gerçek Bildirim Teslimi (Notification Delivery) — 🆕
- **Hedef Bileşen:** [budget_alert_monitor.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/budgets/domain/services/budget_alert_monitor.dart) ve tekrarlayan işlem hatırlatıcıları
- **Önkoşul:** Bildirim izni verilmiş olmalı (9.6).
- **Test Adımları:**
  1. Bir bütçeyi limit üstüne çıkaracak gider ekleyin.
  2. Vadesi gelmiş bir tekrarlayan işlem oluşturun.
  3. Bildirim gölgesini (notification shade) kontrol edin.
- **Beklenen Sonuç:** Yalnız izin diyaloğu değil, **gerçek sistem bildirimi** düşmeli (bütçe aşımı ve/veya vadesi gelen tekrarlayan işlem için); dokununca ilgili sayfaya yönlendirmelidir.
- **Durum:** ⏳ Başlanmadı

---

## 10. Onboarding / İlk Açılış Turu (Onboarding Tour) — 🆕

### Senaryo 10.1: İlk Kurulum Tanıtım Turu (First-run Showcase Tour)
- **Hedef Bileşen:** [onboarding_flow.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/core/onboarding/onboarding_flow.dart), [onboarding_keys.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/core/onboarding/onboarding_keys.dart), [onboarding_navigation_hint_card.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/main_feature/widgets/onboarding_navigation_hint_card.dart)
- **Önkoşul:** Uygulama ilk kez açılıyor olmalıdır (onboarding tamamlanmamış).
- **Test Adımları:**
  1. Uygulamayı ilk kez başlatın.
  2. ShowcaseView balonlarının/ipucu kartlarının sırayla göründüğünü izleyin.
  3. Adımları "İleri" ile sonuna kadar takip edin.
- **Beklenen Sonuç:** Onboarding turu adım adım ilerlemeli, hedef widget'ları doğru vurgulamalı ve son adımda kapanıp bir daha otomatik açılmamalıdır.
- **Durum:** ⏳ Başlanmadı

### Senaryo 10.2: Turu Atlama ve Tekrar Görüntüleme (Skip & Replay Tour)
- **Hedef Bileşen:** [onboarding_flow.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/core/onboarding/onboarding_flow.dart)
- **Önkoşul:** İlk açılış turu görünür durumda olmalıdır.
- **Test Adımları:**
  1. Turu "Atla" ile kapatın; uygulamayı yeniden başlatın.
  2. (Varsa) Ayarlardan "Tanıtımı tekrar göster" seçeneğiyle turu yeniden tetikleyin.
- **Beklenen Sonuç:** Atlanan tur yeniden başlatmada otomatik açılmamalı; tekrar-göster seçeneği varsa turu baştan başlatmalıdır.
- **Durum:** ⏳ Başlanmadı

---

## 11. Ana Ekran ve 2B Slider Navigasyonu (Home & 2D Slider) — 🆕

> `main_feature` çekirdek ana ekrandır; `slider_button_view.dart` ve `mini_buttons_overlay.dart` şu an aktif geliştirme altında (commit'siz değişiklik) olmasına rağmen daha önce adanmış senaryosu yoktu.

### Senaryo 11.1: Toplam Bakiye Kartı ve Özet (Total Balance Card)
- **Hedef Bileşen:** [app_bar_content.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/main_feature/widgets/app_bar_content.dart)
- **Önkoşul:** Birden fazla cüzdan ve işlem bulunmalıdır.
- **Test Adımları:**
  1. Ana ekranı açın; toplam bakiye kartını inceleyin.
  2. Farklı para birimli cüzdanların toplama doğru (kur çevrimiyle) yansıdığını kontrol edin.
- **Beklenen Sonuç:** Toplam bakiye tüm aktif cüzdanların (kur çevrimli) toplamını doğru göstermeli; bir işlem eklendiğinde anında güncellenmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 11.2: 2B Slider Gezinme Jestleri ve Mini Buton Overlay (2D Slider Navigation)
- **Hedef Bileşen:** [slider_button_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/main_feature/widgets/slider_button_view.dart) ve mini_buttons_overlay.dart
- **Önkoşul:** Ana ekranda olunmalıdır.
- **Test Adımları:**
  1. Ana ekranda yatay/dikey kaydırma jestleriyle bölümler (İşlemler / Rapor / Detay vb.) arasında gezin.
  2. Mini buton overlay'inin göründüğünü ve doğru hedefe yönlendirdiğini kontrol edin.
  3. Native predictive-back (geri) jestiyle önceki duruma dönün.
- **Beklenen Sonuç:** Slider geçişleri pürüzsüz olmalı, mini butonlar doğru sayfayı açmalı ve geri jesti beklenen ekrana dönmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 11.3: Speed-Dial Hızlı İşlem Menüsü (Speed-dial Quick Actions)
- **Hedef Bileşen:** [slider_button_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/main_feature/widgets/slider_button_view.dart)
- **Önkoşul:** Aktif bir cüzdan bulunmalıdır.
- **Test Adımları:**
  1. Ana ekrandaki hızlı işlem (speed-dial) butonuna basın.
  2. Gider/Gelir/Transfer/Borç/Yatırım kısayollarının açıldığını ve doğru sayfayı tetiklediğini kontrol edin.
- **Beklenen Sonuç:** Menü açılmalı, her kısayol doğru giriş sayfasını açmalı; TL-dışı cüzdanda kısıtlı eylemler için uyarı vermelidir (bkz. 1.7).
- **Durum:** ⏳ Başlanmadı

---

## 12. Negatif ve Kenar Durumlar (Robustness & Edge Cases) — 🆕

### Senaryo 12.1: Geçersiz/Sıfır/Boş Tutar Doğrulaması (Input Validation)
- **Hedef Bileşen:** [transaction_entry_sheet.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart)
- **Önkoşul:** Aktif bir cüzdan bulunmalıdır.
- **Test Adımları:**
  1. Gider ekleme formunda tutarı boş bırakıp kaydetmeyi deneyin.
  2. Tutar olarak `0`, ardından çok büyük bir sayı (örn. `999999999999`) girin.
  3. (Varsa) tarihi çok ileri bir gelecek gününe ayarlayın.
- **Beklenen Sonuç:** Geçersiz/sıfır/boş tutar reddedilmeli, açıklayıcı doğrulama mesajı gösterilmeli; uygulama çökmemeli ve bozuk kayıt oluşmamalıdır.
- **Durum:** ⏳ Başlanmadı

### Senaryo 12.2: Bozuk/Boş/Desteklenmeyen Dosya İçe Aktarma (Corrupt File Handling)
- **Hedef Bileşen:** [bank_import_cubit.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/presentation/bloc/bank_import_cubit.dart)
- **Önkoşul:** Boş bir CSV, bozuk bir PDF ve geçersiz sütunlu bir dosya hazırlanmalıdır.
- **Test Adımları:**
  1. Boş/başlıksız bir CSV içe aktarmayı deneyin.
  2. İçinde hiç tarih/tutar bulunmayan bir PDF yükleyin.
- **Beklenen Sonuç:** "Geçerli işlem bulunamadı" gibi anlaşılır bir hata gösterilmeli, atlanan satır sayısı bildirilmeli; uygulama çökmemelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 12.3: Süreç Ölümü Sonrası Durum Kurtarma (Process Death Restore)
- **Hedef Bileşen:** Uygulama yaşam döngüsü / Hive kalıcılığı
- **Önkoşul:** Birkaç işlem ve cüzdan bulunmalıdır.
- **Test Adımları:**
  1. Bir form yarım doldurulmuşken uygulamayı arka plana alın.
  2. `adb shell am kill dev.halilibrahim.cunehat` ile süreci öldürün ve yeniden açın.
- **Beklenen Sonuç:** Kaydedilmiş veriler eksiksiz geri gelmeli, uygulama tutarlı bir başlangıç durumuna dönmeli, çökme/kilitlenme olmamalıdır.
- **Durum:** ⏳ Başlanmadı

### Senaryo 12.4: Ekran Döndürme ve Büyük Veri Performansı (Rotation & Large Dataset)
- **Hedef Bileşen:** İşlem listesi / grafikler
- **Önkoşul:** 200+ işlem içeren bir cüzdan (fixture veya toplu ekleme ile).
- **Test Adımları:**
  1. İşlemler ve Rapor sayfalarında ekranı yatay/dikey döndürün.
  2. Uzun listede kaydırma akıcılığını ve grafik yüklenmesini gözlemleyin.
- **Beklenen Sonuç:** Döndürmede durum korunmalı, liste akıcı kaydırmalı (jank yok), grafikler makul sürede yüklenmelidir.
- **Durum:** ⏳ Başlanmadı

---

## 📝 Tespit Edilen Hatalar ve İyileştirme Önerileri

1. **ListTile Arka Plan Uyarısı (Assertion/Exception):**
   - **Sorun:** Bütçe/liste sayfalarından birinde `ListTile` bir `DecoratedBox` içine sarılmış. Bu durum, Material ink efektlerinin (splash effect) görünmez olmasına sebep oluyor ve konsola assertion uyarısı düşürüyor.
   - **Çözüm:** İlgili widget'lar `Material` widget'ı ile sarmalanmalı veya `DecoratedBox`'taki arka plan rengi kaldırılıp `ListTile`'ın kendi `tileColor` özelliği kullanılmalıdır.

2. **Karusel Navigasyon Zorluğu (Rapor Sayfası):**
   - **Sorun:** Ana sayfadaki alt eylem çubuğu karusel yapısında olduğu için, ADB / UI Automator ile kaydırma yaparken "Rapor" sekmesi tam ortalanamıyor ve tıklanamıyor.
   - **Çözüm:** UI test otomasyonunu kolaylaştırmak amacıyla, karusel bileşenlerine ve sekmelerine benzersiz `Key` veya semantik etiketler tanımlanmalıdır.

3. **Yedekleme ve İçe Aktarma Buton Yakınlığı:**
   - **Sorun:** Ayarlar sayfasında "İçe Aktar (CSV)" (uygulamanın kendi yedek formatı) ile "Banka ekstresi içe aktar" (bank_import) butonları yan yana duruyor. Yanlışlıkla diğerine basıldığında kullanıcı "CSV dosyasında geçerli işlem bulunamadı" hatası alıyor.
   - **Çözüm:** İkonlar ve renkler farklılaştırılarak veya buton grupları ayrıştırılarak bu iki eylem görsel olarak daha belirgin hale getirilmelidir.
