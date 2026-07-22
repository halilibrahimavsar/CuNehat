# CuNehat Kapsamlı Smoke Test Senaryoları ve Raporu

**Son Güncelleme:** 2026-07-23  
**Test Ortamı:** Android Emulator (Android 15 / API 35) + Manuel ve ADB Etkileşimleri  
**Genel Durum:** 🔄 Geliştirme ve Test Süreci Devam Ediyor (16/41 Senaryo Tamamlandı)  

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

### Senaryo 1.3: Cüzdan Düzenleme (Wallet Editing)
- **Hedef Bileşen:** [wallet_form_dialog.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/wallet/presentation/page/wallet_form_dialog.dart)
- **Önkoşul:** En az bir aktif cüzdan bulunmalıdır.
- **Test Adımları:**
  1. Yan menüden veya ayarlardan "Cüzdan Yönetimi" sayfasına girin.
  2. Düzenlemek istediğiniz cüzdanın yanındaki "Düzenle" (Kalem) butonuna tıklayın.
  3. Cüzdan adını "Ana Cüzdan Güncel" ve bakiye ayarını değiştirip "Kaydet"e tıklayın.
- **Beklenen Sonuç:** Değişiklikler anında cüzdan listesinde ve ana sayfada güncellenmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 1.4: Cüzdan Silme ve Arşivleme (Wallet Deletion & Archiving)
- **Hedef Bileşen:** [wallet_info_dialog.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/wallet/presentation/widgets/wallet_info_dialog.dart)
- **Önkoşul:** En az bir aktif cüzdan bulunmalıdır.
- **Test Adımları:**
  1. Cüzdan Yönetimi altından cüzdan detayına girin.
  2. "Arşivle" veya "Sil" seçeneğine tıklayın.
  3. Eğer cüzdanda işlemler varsa, sistemin uyarı verip vermediğini kontrol edin ve onaylayın.
- **Beklenen Sonuç:** Silinen cüzdan listeden kalkmalı, arşivlenen cüzdan ise sadece "Arşivlenmiş Cüzdanlar" sekmesinde görünmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 1.5: Cüzdanlar Arası Para Transferi (Inter-Wallet Transfer)
- **Hedef Bileşen:** [transfer_sheet.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/wallet/presentation/widgets/transfer_sheet.dart)
- **Önkoşul:** En az iki adet cüzdan tanımlanmış olmalıdır (örn. "Nakit" ve "Banka").
- **Test Adımları:**
  1. Hızlı İşlem menüsünden veya Cüzdan sayfasından "Transfer Et" seçeneğini seçin.
  2. Gönderen cüzdanı "Banka", Alıcı cüzdanı "Nakit" olarak seçin.
  3. Miktar kısmına `1000` yazıp onaylayın.
- **Beklenen Sonuç:** Banka cüzdanından 1000 ₺ düşmeli, Nakit cüzdanına 1000 ₺ eklenmeli ve işlem geçmişinde "Transfer" türünde bir kayıt oluşmalıdır.
- **Durum:** ⏳ Başlanmadı

### Senaryo 1.6: Çoklu Para Birimi Cüzdanı ve Canlı Kur Çevrimi (Multi-Currency & Exchange Rates)
- **Hedef Bileşen:** [wallet_currency_context.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/wallet/presentation/wallet_currency_context.dart)
- **Önkoşul:** Aktif internet bağlantısı veya önbelleklenmiş kur verileri bulunmalıdır.
- **Test Adımları:**
  1. Para birimi "USD" olan yeni bir "Dolar Hesabı" cüzdanı oluşturun ve içine `100` $ ekleyin.
  2. Ana sayfaya dönün ve toplam portföy değerinin canlı kurlar üzerinden hesaplanan TRY karşılığını inceleyin.
- **Beklenen Sonuç:** Dolar hesabı kendi birimiyle (`100,00 $`) listelenmeli, genel toplam bakiye kartında güncel kur ile TRY tutarına dönüştürülüp eklenmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 1.7: Döviz Cüzdanlarında Yatırım ve Borç Kısıtlamaları (Non-TRY Wallet Feature Lock)
- **Hedef Bileşen:** [try_only_feature_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/core/shared/widgets/try_only_feature_view.dart) ve [slider_button_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/main_feature/widgets/slider_button_view.dart)
- **Önkoşul:** Para birimi TL (TRY) olmayan bir döviz cüzdanı seçili olmalıdır.
- **Test Adımları:**
  1. Hızlı eylem menüsünden "Altın/Hisse/Özel Yatırım" eklemeyi deneyin.
  2. Hızlı eylem menüsünden "Borç/Alacak" eklemeyi deneyin.
  3. Yan menüden Yatırımlar veya Borç & Alacak sayfasına geçiş yapın.
- **Beklenen Sonuç:** Hızlı işlem menüsü snackbar uyarısı vererek işlemi engellemeli. Sayfa geçişlerinde ise liste yerine "TL-dışı cüzdanda bu özellik kapalıdır" ibaresini içeren `TryOnlyFeatureView` gösterilmelidir.
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

### Senaryo 2.2: Manuel Gelir İşlemi Ekleme (Add Income)
- **Hedef Bileşen:** [transaction_entry_sheet.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart)
- **Önkoşul:** Aktif bir cüzdan bulunmalıdır.
- **Test Adımları:**
  1. Hızlı işlem menüsünü açın ve "Gelir Ekle" ikonuna tıklayın.
  2. Tutar alanına `5000` yazın. Kategori olarak "Maaş" seçin.
  3. Açıklama kısmına "Temmuz Maaşı" yazıp "Kaydet"e tıklayın.
- **Beklenen Sonuç:** İşlem başarıyla eklenmeli, ana bakiye `5.000,00 ₺` artmalıdır.
- **Durum:** ✅ Tamamlandı

### Senaryo 2.3: İşlem Detayını Görüntüleme ve Silme (View & Delete Transaction)
- **Hedef Bileşen:** [single_transaction_detail_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/pages/single_transaction_detail_page.dart)
- **Önkoşul:** Test cüzdanında en az bir işlem kaydı bulunmalıdır.
- **Test Adımları:**
  1. İşlem geçmişi listesinden eklenmiş olan "Öğle Yemeği" giderine tıklayın.
  2. Detay sayfasında tarih, saat, kategori, tutar ve işlem sonrası bakiyenin doğruluğunu kontrol edin.
  3. Sağ üstteki "Sil" ikonuna tıklayın ve onaylayın.
- **Beklenen Sonuç:** İşlem silinmeli, cüzdan bakiyesi eski durumuna geri dönmeli ve işlem listeden kalkmalıdır.
- **Durum:** ✅ Tamamlandı

### Senaryo 2.4: Takvim ve Liste Görünümü Geçişi (Calendar & List View Toggle)
- **Hedef Bileşen:** [transaction_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/pages/transaction_page.dart)
- **Önkoşul:** Farklı günlerde eklenmiş birden fazla işlem bulunmalıdır.
- **Test Adımları:**
  1. Alt navigasyondan "İşlemler" sekmesine gidin.
  2. Liste görünümünü inceleyin, ardından üstteki "Takvim" butonuna tıklayarak takvim moduna geçin.
  3. Takvim üzerinde işlem olan günlerdeki noktaları (dot indicator) ve günlük gelir/gider toplamlarını kontrol edin.
- **Beklenen Sonuç:** Görünümler arasında geçiş pürüzsüz olmalı, günlük özet hesaplamaları matematiksel olarak doğru olmalıdır.
- **Durum:** ✅ Tamamlandı

### Senaryo 2.5: İşlem Filtreleme ve Arama (Filter & Search)
- **Hedef Bileşen:** [filter_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/widgets/filter_view.dart)
- **Önkoşul:** Sistemde farklı kategorilerde ve tutarlarda 5+ işlem bulunmalıdır.
- **Test Adımları:**
  1. İşlemler sayfasında "Filtrele" butonuna basın.
  2. Kategori olarak sadece "Yemek", tür olarak sadece "Gider" seçip uygulayın.
  3. Arama çubuğuna "Maaş" yazarak arama yapın.
- **Beklenen Sonuç:** Filtreleme uygulandığında sadece Yemek giderleri listelenmeli; arama yapıldığında arama kriterine uyan işlemler anında listelenmelidir.
- **Durum:** ⏳ Başlanmadı

### Senaryo 2.6: Yeni Kategori Oluşturma ve Yönetme (Category Management)
- **Hedef Bileşen:** [category_manager_sheet.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/widgets/category_manager/category_manager_sheet.dart)
- **Önkoşul:** İşlem ekleme veya ayarlar sayfasından kategori yöneticisine ulaşılmalıdır.
- **Test Adımları:**
  1. İşlem ekleme sayfasında kategori seçiciye tıklayın ve "Kategorileri Yönet" butonuna basın.
  2. "Yeni Kategori Ekle" butonuna basın; isim olarak "Evcil Hayvan", ikon ve renk seçip kaydedin.
  3. Eklenen kategoriyi listede görün, ardından düzenleme ve silme işlemlerini test edin.
- **Beklenen Sonuç:** Yeni kategori sorunsuz eklenmeli, düzenlenebilmeli ve silinebilmelidir.
- **Durum:** ⏳ Başlanmadı

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
- **Durum:** ⏳ Başlanmadı

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

### Senaryo 3.2: Bütçe Kartı ve İlerleme Çubuğu Takibi (Budget Progress Monitoring)
- **Hedef Bileşen:** [budgets_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/budgets/presentation/pages/budgets_page.dart)
- **Önkoşul:** Aylık 2.000 ₺ limitli bir "Alışveriş" bütçesi bulunmalıdır.
- **Test Adımları:**
  1. "Alışveriş" kategorisinde 500 ₺ tutarında yeni bir manuel gider işlemi ekleyin.
  2. Bütçe Planlama sayfasına geri dönün.
- **Beklenen Sonuç:** Bütçe kartında kullanım miktarı 500 ₺, kullanım oranı %25 olarak güncellenmeli ve ilerleme çubuğu bu oranı doğru yansıtmalıdır.
- **Durum:** ✅ Tamamlandı

### Senaryo 3.3: Bütçe Düzenleme ve Silme (Edit & Delete Budget)
- **Hedef Bileşen:** [budgets_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/budgets/presentation/pages/budgets_page.dart)
- **Önkoşul:** Mevcut bir bütçe bulunmalıdır.
- **Test Adımları:**
  1. İlgili bütçe kartının üzerindeki eylemler menüsünü açın.
  2. "Düzenle" seçeneğiyle limiti `3000` yapın ve kaydedin. Ardından bütçeyi silmeyi deneyin.
- **Beklenen Sonuç:** Limit değişikliği kartta anında güncellenmeli, silme işlemi onaylandıktan sonra bütçe kartı sayfadan kaldırılmalıdır.
- **Durum:** ⏳ Başlanmadı

### Senaryo 3.4: Bütçe Aşım Uyarısı (Budget Alert Triggering)
- **Hedef Bileşen:** [budgets_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/budgets/presentation/pages/budgets_page.dart)
- **Önkoşul:** Aylık 2.000 ₺ limitli bir bütçe bulunmalıdır.
- **Test Adımları:**
  1. Bu bütçe kategorisinde sırasıyla 1600 ₺ (%80 eşiği için) ve ardından 500 ₺ (toplam 2100 ₺) gider ekleyin.
  2. Bütçe kartındaki durumu ve sistem bildirimini/uyarısını kontrol edin.
- **Beklenen Sonuç:** %80 sınırında uyarı renkleri aktif olmalı, %100 aşımında ise kart kırmızıya dönerek "Limit Aşıldı!" uyarısı göstermelidir.
- **Durum:** ⏳ Başlanmadı

---

## 4. Banka Ekstresi İçe Aktarma (Bank Import)

### Senaryo 4.1: CSV Banka Ekstresi Seçimi ve Yükleme (Select & Upload CSV)
- **Hedef Bileşen:** [bank_import_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/presentation/pages/bank_import_page.dart)
- **Önkoşul:** Cihazda veya emülatörde uyumlu formatta (gg.aa.yyyy tarihli, Türkçe ondalık virgüllü) banka CSV ekstresi bulunmalıdır.
- **Test Adımları:**
  1. Ayarlar -> "Banka ekstresi içe aktar" sayfasına girin.
  2. Dosya seçici yardımıyla hedef CSV dosyasını yükleyin.
- **Beklenen Sonuç:** CSV dosyası başarıyla okunmalı, delimiter ve kodlama tipi otomatik olarak algılanmalıdır.
- **Durum:** ✅ Tamamlandı

### Senaryo 4.2: Sütun Eşleştirme Ekranı (Column Mapping Verification)
- **Hedef Bileşen:** [bank_import_mapping_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/presentation/pages/bank_import_mapping_view.dart)
- **Önkoşul:** CSV dosyası başarıyla yüklenmiş olmalıdır.
- **Test Adımları:**
  1. CSV sütunlarının (Tarih, Açıklama, Tutar) otomatik eşleştiğini kontrol edin.
  2. Alt kısımdaki "Canlı Önizleme" tablosunda verilerin doğru ayrıştırılıp ayrıştırılmadığını inceleyin.
- **Beklenen Sonuç:** Otomatik eşleştirme doğru çalışmalı, önizleme tablosunda kaymalar olmadan ham veriler listelenmelidir.
- **Durum:** ✅ Tamamlandı

### Senaryo 4.3: İnceleme, Kategori Tahmini ve İşlem Onaylama (Review, Categorize & Import)
- **Hedef Bileşen:** [bank_import_review_view.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/presentation/pages/bank_import_review_view.dart)
- **Önkoşul:** Sütun eşleştirme onaylanmış olmalıdır.
- **Test Adımları:**
  1. İnceleme ekranındaki işlemlerin gelir/gider yönünü kontrol edin.
  2. Kategori tahmin motorunun atamalarını inceleyin (örn. Açıklamasında "Market" yazan işlem için Alışveriş tahmini).
  3. Tüm işlemleri seçip "İçe Aktar" butonuna basın.
- **Beklenen Sonuç:** İşlemler başarıyla cüzdana aktarılmalı, bakiye ekstre toplamı kadar güncellenmelidir.
- **Durum:** ✅ Tamamlandı

### Senaryo 4.4: Bakiye Eşitleme ve İçe Aktarmayı Geri Alma (Reconciliation & Undo)
- **Hedef Bileşen:** [bank_import_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/presentation/pages/bank_import_page.dart)
- **Önkoşul:** Az önce başarılı bir içe aktarım işlemi yapılmış olmalıdır.
- **Test Adımları:**
  1. İçe aktarım sonrası ana ekranda çıkan "Geri Al" (Undo) butonuna tıklayın.
  2. İşlemlerin geri alındığını ve cüzdan bakiyesinin eski haline döndüğünü doğrulayın.
- **Beklenen Sonuç:** Tek tıkla geri alma işlemi tüm içe aktarılan verileri silmeli ve bakiyeyi eski durumuna eşitlemelidir.
- **Durum:** ✅ Tamamlandı

### Senaryo 4.5: Banka PDF Ekstresi İçe Aktarma (PDF Statement Import)
- **Hedef Bileşen:** [pdf_statement_parser.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/bank_import/data/pdf_statement_parser.dart)
- **Önkoşul:** Cihazda Akbank, Garanti veya Ziraat bankasına ait örnek bir PDF hesap ekstresi bulunmalıdır.
- **Test Adımları:**
  1. "Banka ekstresi içe aktar" sayfasında dosya türü olarak PDF seçin.
  2. İlgili PDF dosyasını yükleyin.
  3. Banka özel parser'ının (örn. `akbank_pdf_parser.dart`) şablonu algılamasını bekleyin.
- **Beklenen Sonuç:** PDF metinleri başarıyla ayrıştırılmalı, işlemler tarih/tutar/açıklama şeklinde düzenli inceleme tablosuna aktarılmalıdır.
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

### Senaryo 5.2: Detaylı Grafik Raporları Sayfası Geçişi (Detailed Reports Verification)
- **Hedef Bileşen:** [transaction_report_page.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/finance_transactions/presentation/pages/transaction_report_page.dart)
- **Önkoşul:** İşlemler sekmesinden raporlar sayfasına geçiş yapılabilmelidir.
- **Test Adımları:**
  1. Alt eylem karuselinden "Rapor" sekmesine tıklayın veya kaydırın.
  2. Gelir/gider dağılımını gösteren pasta grafiklerini (pie chart) ve trend çizgilerini inceleyin.
- **Beklenen Sonuç:** Grafiklerin yüklenmesinde görsel hata olmamalı ve veriler doğru kategorilere göre gruplanmalıdır.
- **Durum:** 🔄 Devam Ediyor (Buton bounds tespiti ve karusel ortalama hatası nedeniyle yarım kaldı, uiautomator ile koordinat tespiti yapılacak)

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
- **Durum:** ⏳ Başlanmadı

### Senaryo 6.2: Borç/Alacak Ödemesi Ekleme (Record Debt Repayment)
- **Hedef Bileşen:** [debt_payment_dialog.dart](file:///home/garuda/Masaüstü/Programming/Flutterr/flutterProjects/CuNehat/lib/features/debt_and_receivable/presentation/widgets/debt_payment_dialog.dart)
- **Önkoşul:** Sistemde aktif bir borç veya alacak kaydı bulunmalıdır.
- **Test Adımları:**
  1. "Ahmet Yılmaz" borç kartına tıklayın.
  2. "Ödeme Yap" butonuna basın, miktar olarak `500` yazıp cüzdan seçimi yapın ve onaylayın.
- **Beklenen Sonuç:** Kalan borç `1000 ₺` olarak güncellenmeli, seçilen cüzdandan `500 ₺` düşülmelidir.
- **Durum:** ⏳ Başlanmadı

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
