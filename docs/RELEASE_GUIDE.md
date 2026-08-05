# CuNehat — Google Play İlk Yayın Rehberi

Kod tarafı hazır. Bu doküman **kodla halledilemeyen, senin yapman gereken**
adımları sırayla anlatır. Adımlar birbirine bağımlı — özellikle 4 ve 9
arasındaki sıra kritik, sebebi 9'da açıklanıyor.

**Önkoşullar:** Google Play Developer hesabı (tek seferlik 25 USD), bir Google
Cloud projesi, Flutter SDK kurulu.

**Uygulama kimliği (değiştirilemez, yayından sonra sabit):**
`dev.halilibrahim.cunehat` · sürüm `1.0.0+1`

---

## Adım 1 — Upload keystore üret (KRİTİK, bir kez)

Şu an release derlemesi **debug anahtarıyla** imzalanıyor (`build.gradle.kts`
`key.properties` yoksa debug'a düşüyor). Play bunu reddeder.

```bash
keytool -genkey -v -keystore ~/cunehat-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Soracağı alanlar (ad, kurum, şehir, ülke kodu `TR`) serbest; **parolayı bir
parola yöneticisine kaydet.** Sonra `android/key.properties` oluştur:

```properties
storePassword=<keystore-parolan>
keyPassword=<key-parolan>
keyAlias=upload
storeFile=/home/garuda/cunehat-upload.jks
```

> `key.properties` ve `*.jks` `.gitignore`'da — commit edilmez, edilmemeli.

**Keystore dosyasını ayrıca yedekle** (harici disk + parola yöneticisi).
Play App Signing açıkken kaybedersen Play Console'dan upload anahtarı
sıfırlanabilir, ama süreç günler sürer.

Doğrula:

```bash
flutter build appbundle --release
unzip -p build/app/outputs/bundle/release/app-release.aab \
  BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map > /dev/null && echo "AAB hazır"
```

---

## Adım 2 — Syncfusion Community License (KRİTİK, ücretsiz ama başvuru şart)

PDF ekstre ayrıştırma `syncfusion_flutter_pdf` kullanıyor. Paketin LICENSE
dosyası açık: *"Under no circumstances can you use this product without either
a Community License or a commercial license."*

Tek geliştirici + yıllık 1M USD altı ciro ile hak kazanıyorsun, ama **almalısın**:
<https://www.syncfusion.com/products/communitylicense>

Kayıt sonrası kodda anahtar tanımlaman **gerekmiyor** (v18.3+ için geçerli değil).
Yapılacak tek şey lisansı hesabına tanımlatmak.

---

## Adım 3 — Gizlilik politikasını yayınla (KRİTİK)

`docs/privacy-policy.html` hazır (TR + EN, 4 Ağustos 2026 güncel). Play herkese
açık bir URL istiyor.

1. GitHub → repo → **Settings → Pages**
2. Source: **Deploy from a branch** → Branch: `main`, klasör: `/docs`
3. Birkaç dakika sonra URL:
   `https://<kullanıcı-adın>.github.io/<repo-adı>/privacy-policy.html`
4. Tarayıcıda aç, TR ve EN bölümlerinin ikisinin de göründüğünü doğrula.
5. İçindeki iletişim e-postasını (`halirlnj@gmail.com`) teyit et.

Bu URL'i iki yerde kullanacaksın: Play Console store listing + Google Cloud
OAuth consent ekranı.

---

## Adım 4 — Google Cloud: OAuth consent ekranı

Drive yedeği `drive.appdata` kapsamını kullanıyor (hassas kapsam).

1. <https://console.cloud.google.com> → doğru projeyi seç (yoksa oluştur)
2. **APIs & Services → Library** → **Google Drive API** → Enable
3. **APIs & Services → OAuth consent screen**
   - User type: **External**
   - App name: `CuNehat`
   - User support email + Developer contact: kendi e-postan
   - App domain → **Privacy policy link**: Adım 3'teki URL
4. **Scopes** → Add or remove scopes → yalnız
   `https://www.googleapis.com/auth/drive.appdata` ekle. Başka kapsam ekleme.
5. **Test users** → kendi Google hesabını ekle (yayın öncesi test için şart)

> `drive.appdata` "restricted" değil "sensitive" kapsamdır; ağır güvenlik
> denetimi gerekmez. "Unverified app" uyarısını kaldırmak istersen doğrulama
> gönderebilirsin, ama test aşaması için gerekmiyor.

---

## Adım 5 — Google Cloud: Android OAuth istemcisi (upload anahtarı)

**APIs & Services → Credentials → Create credentials → OAuth client ID**

- Application type: **Android**
- Package name: `dev.halilibrahim.cunehat` (birebir bu, tipo affetmez)
- SHA-1: upload keystore'unun parmak izi —

```bash
keytool -list -v -keystore ~/cunehat-upload.jks -alias upload | grep SHA1
```

> Geçmişte burada bir hata yapılmıştı: **Desktop** tipi istemci oluşturulmuştu.
> Android'de client_id koda yazılmaz; eşleştirme paket adı + SHA-1 üzerinden
> yapılır. Tip **Android** olmalı.

İkinci bir SHA-1 daha gerekecek (Play'in kendi imzalama anahtarı) ama o ancak
ilk yüklemeden sonra alınabiliyor — **Adım 9**.

---

## Adım 6 — Play Console: uygulamayı oluştur

<https://play.google.com/console> → **Uygulama oluştur**

| Alan | Değer |
|---|---|
| Uygulama adı | CuNehat |
| Varsayılan dil | Türkçe (tr-TR) |
| Uygulama mı oyun mu | Uygulama |
| Ücretsiz mi ücretli mi | Ücretsiz *(ücretliye sonradan geçilemez)* |
| Kategori | Finans |

---

## Adım 7 — Data Safety formu (koddan doğrulanmış cevaplar)

Bu tablo uygulamanın gerçek davranışından çıkarıldı; olduğu gibi gir.

**Toplanan/işlenen veri:**

| Veri türü | Toplanıyor mu | Paylaşılıyor mu | Zorunlu mu | Amaç |
|---|---|---|---|---|
| E-posta adresi | **Evet** (yalnız Drive yedeği açılırsa) | Hayır | İsteğe bağlı | Uygulama işlevi |
| Finansal bilgi — diğer | **Evet** (cihazda) | Hayır | Zorunlu | Uygulama işlevi |
| Fotoğraf | **Hayır** — cihazdan çıkmıyor | — | — | — |

> Fiş fotoğrafları ve banka ekstresi dosyaları cihazdan hiç çıkmadığı için
> Play'in tanımına göre "toplanan veri" değil. OCR tamamen cihaz içinde
> (gömülü ML Kit modeli) çalışıyor, sunucuya görsel gitmiyor.

**Güvenlik soruları:**

| Soru | Cevap |
|---|---|
| İletimde şifreleniyor mu | **Evet** (tüm trafik HTTPS) |
| Beklemede (at rest) şifreleniyor mu | **Hayır** — yerel Hive şifresiz |
| Kullanıcı silme talep edebilir mi | **Evet** (Ayarlar → Gizlilik & Veri → Tüm Veriyi Sil) |
| Üçüncü tarafla paylaşım | **Yok** |
| Analytics / reklam / çökme raporlama SDK'sı | **Yok** |

---

## Adım 8 — Store listing ve kalan formlar

**Hazır varlıklar** (üretildi, doğrudan yükle):

- Uygulama ikonu 512×512 → `docs/store/play-icon-512.png`
- Feature graphic 1024×500 → `docs/store/play-feature-graphic-1024x500.png`

**Senin üretmen gerekenler:**

- **Telefon ekran görüntüleri**: en az 2, en fazla 8. Öneri: ana ekran (cüzdan
  kartları), işlem listesi, rapor grafiği, bütçe ekranı, banka ekstresi
  içe aktarma. Cihazda release build'i açıp çek.
- **Kısa açıklama** (≤80 karakter)
- **Uzun açıklama** (≤4000 karakter)

> **Metin yazarken dikkat:** "kredi verme", "borç para verme", "faizsiz kredi"
> gibi ifadeler Play'in Finansal Hizmetler politikasını tetikler ve ek beyan
> ister. CuNehat borç/alacak **takibi** yapıyor, finansal ürün sunmuyor —
> metin bunu net söylemeli. "Borçlarını ve alacaklarını takip et" güvenli;
> "kredi çöz" değil.

**Diğer formlar:**

| Form | Cevap |
|---|---|
| İçerik derecelendirmesi | Anket; kategori Finans, şiddet/cinsellik/kumar/IAP yok → düşük derece |
| Hedef kitle ve içerik | 13+ *(çocuklara yönelik değil)* |
| Reklamlar | **Uygulamada reklam yok** |
| App access (uygulama erişimi) | Tüm işlevler girişsiz kullanılabilir. Drive yedeği isteğe bağlı; inceleyiciye not: *"Google ile giriş yalnız isteğe bağlı Drive yedeği içindir, diğer tüm özellikler girişsiz çalışır."* |
| Devlet uygulaması mı | Hayır |
| Finansal özellikler | "Bunların hiçbiri" — uygulama finansal ürün sunmuyor, yalnız kişisel kayıt tutuyor |

---

## Adım 9 — İlk yükleme ve İKİNCİ SHA-1 (sıra burada önemli)

1. **Test ve yayınlama → Test → Dahili test** → yeni sürüm oluştur
2. `build/app/outputs/bundle/release/app-release.aab` dosyasını yükle
3. Play App Signing'i **etkin bırak** (varsayılan)
4. Yükleme bittikten sonra: **Test ve yayınlama → Kurulum → Uygulama imzalama**
   sayfasını aç. Burada **App signing key certificate** altında bir SHA-1 var.
5. Bu SHA-1'i **Adım 5'teki Android OAuth istemcisine ikinci parmak izi olarak
   ekle** (Cloud Console → Credentials → istemciyi düzenle → SHA-1 ekle).

> **Bu adım atlanırsa ne olur:** Kendi cihazında `flutter run --release` ile
> Drive girişi çalışır (upload anahtarıyla imzalı), ama **Play'den indiren
> kullanıcıda çalışmaz** — çünkü Play uygulamayı kendi anahtarıyla yeniden
> imzalıyor ve o parmak izi Cloud Console'da kayıtlı değil. En sık yapılan
> hata bu ve ancak gerçek kullanıcıda fark ediliyor.

Değişikliğin yayılması birkaç dakika sürebilir.

---

## Adım 10 — Cihaz duman testi (Play'den kurulan sürümle)

Dahili test bağlantısından **kendi telefonuna Play üzerinden kur** (yandan
yükleme değil — imza farklı olur, Adım 9'un doğruluğunu test edemezsin).

- [ ] Açılış, splash, ikon ana ekranda doğru görünüyor
- [ ] İlk açılışta gizlilik onam diyaloğu bir kez çıkıyor
- [ ] Bildirim izni istemi çıkıyor, izin verince test bildirimi geliyor
- [ ] Biyometrik / PIN kilidi çalışıyor
- [ ] Cüzdan oluştur → işlem ekle/sil → bakiye doğru
- [ ] Raporlar doğru toplamı gösteriyor
- [ ] **Google ile giriş çalışıyor** ve izin ekranında **yalnız `drive.appdata`** görünüyor ⚠️
- [ ] Drive yedekle → geri yükle turu: veri kaybı / yanlış bakiye yok
- [ ] Ayarlar → Yedekleme → Yedeği Sil çalışıyor
- [ ] Ayarlar → Gizlilik & Veri → Tüm Veriyi Sil → onay → sıfır durum
- [ ] Banka ekstresi içe aktarma: dosya seçiciden **ve** paylaş menüsünden
- [ ] Fiş fotoğrafı ekleme + OCR ön-doldurma
- [ ] Uçak modunda: canlı fiyat ve kur ekranları **kilitlenmeden** hata veriyor
- [ ] R8/obfuscation altında çökme yok (özellikle Hive ve bildirimler)
- [ ] Cihazı yeniden başlat → planlı hatırlatmalar hâlâ geliyor

> ⚠️ işaretli madde başarısızsa: `google_sign_in` 6.x, Google'ın deprecate
> ettiği legacy SDK'yı kullanıyor. Çözüm `google_sign_in` 7.x'e (Credential
> Manager) geçiş — Production'a çıkmadan çöz.

R8 kaynaklı bir çökme çıkarsa `android/app/proguard-rules.pro`'ya ilgili
`-keep` kuralını ekleyip yeniden derle.

---

## Adım 11 — Production'a çıkış

1. **Test ve yayınlama → Üretim** → yeni sürüm → aynı AAB'yi kullan
2. Sürüm notlarını yaz (TR + EN)
3. Ülke/bölge seçimi
4. **İncelemeye gönder**

İlk inceleme genelde birkaç gün sürer; yeni geliştirici hesaplarında daha uzun
sürebilir. Reddedilirse gerekçe e-postayla gelir.

---

## Adım 12 — Yayın sonrası ilk hafta

- Play Console → **Kalite → Android vitals**: ANR ve çökme oranını izle.
  Uygulamada çökme raporlama SDK'sı yok, bu yüzden Dart stack trace göremezsin
  — yalnız native/ANR verisi gelir. `mapping.txt` AAB'ye gömülü olduğu için
  Play'in gösterdiği yığınlar deobfuscate edilmiş olur.
- Kullanıcı yorumlarını izle: veri kaybı bildiren tek bir yorum bile
  Adım 13'teki ilk maddeyi acil hale getirir.

---

## Adım 13 — Yayından SONRA yapılması zorunlu teknik işler

Bunlar v1'i bloke etmiyor ama **ilk güncellemeden önce** çözülmeli.

### 13.1 `CLAUDE.md` geriye-uyumluluk politikasını emekliye ayır

Politika metninde zaten yazıyor: "ilk mağaza yayınına kadar geçerlidir."
O gün geldi. Yayından sonra:

- **`defaultValue` yasağı kalkmalı.** Mevcut bir `HiveType`'a yeni `HiveField`
  eklersen Hive eski kayıtlarda o alanı `null` döner; alan non-nullable ise
  üretilen adapter `fields[N] as String` yapıp **okuma anında çöker**.
  Çözüm: `@HiveField(20, defaultValue: 'TRY')` ya da alanı nullable yap.
- **Yedek şeması artık silinemez.** `data_serialization_service.dart:475`:

  ```dart
  if (version != schemaVersion) {
    throw BackupVersionMismatch(version, schemaVersion);
  }
  ```

  Bu sıkı eşitlik, `schemaVersion` 5→6 olduğu anda **v1.0.0 kullanıcısının
  Drive yedeğini geri yüklenemez yapar.** Telefon değiştiren ilk kullanıcı
  verisini kaybeder. Şemayı ilk kez değiştirmeden ÖNCE bunu "eski sürümü oku
  ve yükselt" akışına çevir.

### 13.2 Çoklu para birimi genişlemesi — ne güvenli, ne değil

| Değişiklik | Geriye uyumluluk etkisi |
|---|---|
| Yeni para birimi eklemek (GBP, CHF, JPY…) | **Yok.** `currency` bir `String` (`wallet_model.dart:18`), enum değil. `kSupportedCurrencies`, `kCurrencySymbols`, `kNoiseThresholds` ve `ExchangeRateService._supported` listelerine eklemek yeterli. Şema değişmez. |
| Borç/alacağa `currency` alanı eklemek | **Var.** `DebtModel` (HiveField 19'a kadar) ve `ReceivableModel` (9'a kadar) bu alana sahip değil. Yeni alan → eski kayıtlarda null → 13.1'deki çökme. `defaultValue: 'TRY'` semantik olarak **doğru**, çünkü v1'de borç sayfası TL dışı cüzdanlarda `TryOnlyFeatureView` ile kapalı — üretilmiş her borç kaydı zaten TL. |
| Yatırımlara para birimi | Zaten var (`InvestmentModel.currency`, nullable) — sorun yok. |
| Cüzdanın para birimini sonradan değiştirilebilir yapmak | **Yapma.** `wallet_form_dialog.dart:366` şu an kilitliyor ve doğrusu bu; açarsan tüm geçmiş tutarlar sessizce yeniden yorumlanır. |

### 13.3 `google_sign_in` 7.x'e geçiş

Mevcut 6.3.0, `google_sign_in_android` 6.2.1 üzerinden Google'ın deprecate
ettiği legacy Google Sign-In SDK'sını (`play-services-auth:21.0.0`) kullanıyor.
Google kesin kapatma tarihi yayınlamadı, ama v7 Credential Manager'a geçti.

### 13.4 Bozuk Hive kutusundan kurtarma yolu

`init_error_page` bilinçli olarak veri silmiyor — doğru karar. Ama kutu kalıcı
bozulursa "Tekrar Dene" sonsuza dek başarısız olur ve tek çare kaldır-yeniden
kur = tüm veri gider. Hata ekranına **"Drive yedeğinden geri yükle"** eklenmeli.

### 13.5 Ertelenmiş işler

- **Yerel Hive AES-256 şifrelemesi** — eklenince Data Safety'de "beklemede
  şifreli = Evet" yapılır. DI'ı elle düzenle (build_runner `injection.config.dart`'ı bozuyor).
- **Para kazanma** (reklam / ücretli / bağış) — karar bekliyor. Reklam eklenirse
  `google_mobile_ads` Advertising ID toplar → Data Safety güncellenmeli.
- **ML Kit unbundled varyantı** — `play-services-mlkit-text-recognition`'a
  geçmek indirme boyutunu ABI başına ~11 MB düşürür.
