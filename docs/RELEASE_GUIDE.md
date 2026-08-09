# CuNehat — Google Play İlk Yayın Rehberi

Kod tarafı hazır. Bu doküman **kodla halledilemeyen, senin yapman gereken**
adımları sırayla anlatır. Adımlar birbirine bağımlı — özellikle 4 ve 9
arasındaki sıra kritik, sebebi 9'da açıklanıyor.

**Önkoşullar:** Google Play Developer hesabı (tek seferlik 25 USD), bir Google
Cloud projesi, Flutter SDK kurulu.

**Uygulama kimliği (değiştirilemez, yayından sonra sabit):**
`dev.halilibrahim.cunehat` · sürüm `1.0.0+1`

---

## ⏱️ ÖNCE OKU — takvimi belirleyen kural: 12 tester / 14 gün

**13 Kasım 2023'ten sonra açılmış *kişisel* geliştirici hesapları**, production'a
başvurabilmek için önce **kapalı test (closed testing)** yürütmek zorunda:

| Şart | Değer |
|---|---|
| Minimum tester | **12** |
| Süre | **14 gün kesintisiz** opt-in |
| Dahili test sayılır mı | **HAYIR** — Google: *"internal testing does not satisfy this requirement"* |
| Sonrası | Dashboard'dan production erişimi başvurusu → inceleme **≤7 gün** |

> Kural Kasım 2023'te **20 tester** olarak başlamıştı; Google **11 Aralık 2024'te
> 12'ye indirdi.** 20 rakamını hatırlıyorsan güncelliğini yitirmiş.

**Muaf olanlar:** 13 Kasım 2023'ten **önce** açılmış kişisel hesaplar ve
**kuruluş (organization)** hesapları. Hesap tipini Play Console → Ayarlar →
Geliştirici hesabı → Hesap ayrıntıları'ndan doğrula; kural sana uygulanıyorsa
Console ana panosunda ayrıca bir görev olarak görünür.

**Takvim etkisi:** AAB bugün hazır olsa bile production en erken **~3 hafta**
sonra. 14 gün test + ≤7 gün inceleme. 12 testerı toplamak bu sürenin dışında —
14 günlük sayaç ancak 12 kişi opt-in *olduktan sonra* işlemeye başlar.

Bu yüzden aşağıdaki **Adım 9 kapalı testtir, dahili test değildir.** Muafsan
Adım 9'daki dahili test kısayolunu kullanabilirsin.

---

## Adım 1 — Upload keystore üret (KRİTİK, bir kez)

Şu an release derlemesi **debug anahtarıyla** imzalanıyor (`build.gradle.kts`
`key.properties` yoksa debug'a düşüyor). Play bunu reddeder.

> **Not:** Bu makinede `~/keystores/cunehat-upload.jks` zaten var (PKCS12,
> 10 Haziran 2026, root sahipli, mod 644 → derleme okuyabilir). Parolasını ve
> alias'ını biliyorsan yeniden üretme; bilmiyorsan aşağıdaki komutla yenisini
> üret. **Play'e henüz hiçbir şey yüklenmediği sürece yeni anahtar üretmek
> bedava** — upload anahtarı ancak ilk yüklemede sabitlenir.
>
> Mevcut keystore'un parolasını sınamak (alias'ı da gösterir):
>
> ```bash
> keytool -list -keystore ~/keystores/cunehat-upload.jks
> ```

```bash
keytool -genkey -v -keystore ~/keystores/cunehat-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Soracağı alanlar (ad, kurum, şehir, ülke kodu `TR`) serbest; **parolayı bir
parola yöneticisine kaydet.** Sonra `android/key.properties` oluştur:

```properties
storePassword=<keystore-parolan>
keyPassword=<key-parolan>
keyAlias=upload
storeFile=/home/garuda/keystores/cunehat-upload.jks
```

> `key.properties` `.gitignore`'un 36. satırında. `*.jks` / `*.keystore` /
> `*.p12` de 2026-08-08'de eklendi — **daha önce yoktu**, yani repo içine
> konulan bir keystore sessizce commit'lenebilirdi. Keystore'u repo dışında
> tut; ikisi de commit edilmez, edilmemeli.

**Keystore dosyasını ayrıca yedekle** (harici disk + parola yöneticisi).
Play App Signing açıkken kaybedersen Play Console'dan upload anahtarı
sıfırlanabilir, ama süreç günler sürer.

Doğrula:

```bash
flutter build appbundle --release
unzip -p build/app/outputs/bundle/release/app-release.aab \
  BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map > /dev/null && echo "AAB hazır"
```

**İmzayı da doğrula** — `key.properties` yoksa derleme sessizce debug anahtarına
düşer ve bunu ancak Play reddedince fark edersin:

```bash
T=$(mktemp -d); unzip -q -o -d "$T" build/app/outputs/bundle/release/app-release.aab "META-INF/*"
keytool -printcert -file "$T"/META-INF/*.RSA | grep -E "Owner|Sahibi"; rm -rf "$T"
```

`CN=Android Debug` görüyorsan **yüklenemez** — `key.properties` eksik demektir.

> **AAB boyutu 87 MB görünecek, panik yok.** Bunun ~37 MB'ı
> `BUNDLE-METADATA` (proguard.map + native debug sembolleri): Play bunları
> çökme çözümlemesi için saklar, **cihaza göndermez.** Kalanı ABI'ye bölünür.
> Ölçülen gerçek indirme (arm64): **~19 MB**. Play'in sınırlarının çok altında.
> Native yükün en büyük tek kalemi ML Kit OCR (`libmlkit_google_ocr_pipeline.so`,
> ABI başına ~11 MB sıkıştırılmamış) — bkz. 14.5.

---

## Adım 2 — Syncfusion Community License (KRİTİK, ücretsiz ama başvuru şart)

PDF ekstre ayrıştırma `syncfusion_flutter_pdf` kullanıyor. Paketin LICENSE
dosyası açık: *"Under no circumstances can you use this product without either
a Community License or a commercial license."*

Tek geliştirici + yıllık 1M USD altı ciro ile hak kazanıyorsun, ama **almalısın**:
<https://www.syncfusion.com/products/communitylicense>

**Kodda anahtar tanımlaman gerekmiyor — doğrulandı (2026-08-10).**
`syncfusion_flutter_pdf` 29.2.11 ve `syncfusion_flutter_core` 31.1.19
paketlerinin `lib/` ağacında `registerLicense`, `SyncfusionLicense` veya
`licenseKey` diye bir sembol **yok** (grep sıfır sonuç). pub.dev paketinde
lisans doğrulama mekanizması bulunmuyor; şart tamamen hukuki.

> **Başvuru sonrası gelen e-postadaki 7 günlük anahtar seni ilgilendirmiyor.**
> O anahtar **Essential Studio installer**'ı (Windows/Mac/Linux masaüstü
> kurulumu) içindir. Sen paketi pub.dev'den alıyorsun, o kurulumu hiç
> indirmeyeceksin. Yapılacak tek şey topluluk lisansı onayının gelmesi.
> Anahtarı **repoya koyma** — hem gereksiz hem repo public.

---

## Adım 3 — Gizlilik politikasını yayınla (KRİTİK)

`docs/privacy-policy.html` hazır (TR + EN, 4 Ağustos 2026 güncel). Play herkese
açık bir URL istiyor.

> ⚠️ **Pages `/docs` içindeki HER dosyayı yayınlar.** Repo zaten public, ama
> Pages bu dosyaları tarayıcıda okunur ve indekslenebilir sayfalara çevirir.
> 2026-08-08'de buna göre düzenlendi:
> - `cunehat-monetizasyon-plani.md` **repodan çıkarıldı** (kişisel vergi /
>   BAĞ-KUR ayrıntıları içeriyordu) → `../CuNehat-ozel/` altında duruyor.
> - `docs/_config.yml` eklendi: `RELEASE_GUIDE.md`, eski analiz dokümanı ve
>   `store/` siteden hariç tutuluyor.
> - `docs/index.html` eklendi ki site kökü 404 vermesin.
>
> **`docs/.nojekyll` dosyası OLUŞTURMA** — Jekyll'i devre dışı bırakır ve
> `_config.yml`'deki `exclude` listesi işlemez, her şey yayınlanır.
>
> **Git geçmişi ayrı mesele:** monetizasyon planı eski commit'lerde duruyor ve
> public repoda erişilebilir. Tamamen silmek istersen `git filter-repo` +
> force push gerekir; bu, geçmişi yeniden yazdığı için ayrıca karar verilmeli.

1. GitHub → repo → **Settings → Pages**
2. Source: **Deploy from a branch** → Branch: `main`, klasör: `/docs`
3. Birkaç dakika sonra URL:
   `https://halilibrahimavsar.github.io/CuNehat/privacy-policy.html`
4. Tarayıcıda aç, TR ve EN bölümlerinin ikisinin de göründüğünü doğrula.
5. İçindeki iletişim e-postasını (`halirlnj@gmail.com`) teyit et.
6. **Sızıntı kontrolü:** `.../CuNehat/RELEASE_GUIDE.html` ve
   `.../CuNehat/cunehat-mantiksal-analiz.html` adreslerinin **404 verdiğini**
   doğrula. Veriyorlarsa `_config.yml` işlememiş demektir.

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

> **DÜZELTME (2026-08-10):** Bu rehber önce `drive.appdata`'yı "sensitive"
> diye yazıyordu — **yanlış.** Google'ın Drive API kapsam tablosunda
> `drive.appdata` **non-sensitive** ve "recommended" listesinde. Ne sensitive
> ne restricted doğrulaması gerekiyor; CASA güvenlik denetimi hiç gündeme
> gelmiyor. Uygulama başka kapsam istemiyor (`google_drive_backup_service.dart:38`,
> tek kapsam), `google_sign_in`'in eklediği `email`/`profile` de non-sensitive.

### "OAuth user cap — N users / 100 user cap" ne demek?

Consent screen sayfasında bu sayaç **her projede** görünür, korkutucu ama
seni bağlamıyor. Console'un kendi tanımı: cap, *"unapproved **sensitive or
restricted** scopes"* isteyen uygulamalardaki izin veren kullanıcı sayısını
sınırlar. CuNehat hiç sensitive/restricted kapsam istemiyor → sınırlayacak
bir şey yok. Sayaç yine artar, sadece bir sayaçtır.

> **Yine de gözünle doğrula:** Consent screen → **Scopes** sayfasında
> kapsamlar üç tabloya ayrılır (Non-sensitive / Sensitive / Restricted).
> `drive.appdata`'nın hangi tabloda durduğuna bak. Console'un seçicisi
> zaman zaman dokümantasyondan farklı grupluyor; **Sensitive** tablosundaysa
> 100 sınırı gerçekten işler ve doğrulama başvurusu gerekir.

### "Publish" durumu — Testing'de bırakma

Consent screen'i **Published** (In production) yap. `Testing` durumunda
kalırsan iki şey olur: yalnız listelediğin test kullanıcıları giriş yapabilir,
**ve refresh token'lar 7 günde bir geçersizleşir** — yani kullanıcının Drive
yedeği her hafta kopar. Bu sessiz bir arıza; ancak kullanıcı şikâyet edince
fark edilir.

---

## Adım 5 — Google Cloud: Android OAuth istemcisi (upload anahtarı)

**APIs & Services → Credentials → Create credentials → OAuth client ID**

- Application type: **Android**
- Package name: `dev.halilibrahim.cunehat` (birebir bu, tipo affetmez)
- SHA-1: upload keystore'unun parmak izi —

```bash
keytool -list -v -keystore ~/keystores/cunehat-upload.jks -alias upload | grep SHA1
```

**Upload anahtarının SHA-1'i (2026-08-08'de alındı):**

```
C6:75:6E:55:47:E5:0A:BF:67:2C:BD:8E:F0:14:C5:D7:22:B0:58:EB
```

> Bu değer **gizli değil** — yayınlanan her APK'nın içinde duruyor, isteyen
> çıkarabilir. Cloud Console'a birebir bu girilecek. Sertifika 2053'e kadar
> geçerli; Play en az 22 Ekim 2033 istiyor, fazlasıyla yeterli.

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

- Kısa/uzun açıklama + sürüm notları (TR + EN) → **`docs/store/store-listing.md`**
  (yazıldı, karakter sayıları ölçüldü, kopyala-yapıştır hazır)

**Senin üretmen gereken tek şey:**

- **Telefon ekran görüntüleri**: en az 2, en fazla 8. Cihazda release build'i
  açıp çek; önerilen kadraj listesi `store-listing.md`'nin sonunda. Gerçek
  kişisel verini gösterme, örnek veriyle çek.

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

**Hangi kanal?** 12 tester kuralı sana uygulanıyorsa (bkz. baştaki uyarı) bu
sürüm **kapalı teste** gitmeli — 14 günlük sayaç yalnız orada işler. Muafsan
dahili test yeterli. Yine de ilk yüklemeyi **dahili testte** yapıp SHA-1'i almak,
Drive'ı kendi cihazında doğrulamak ve *sonra* aynı AAB'yi kapalı teste
promote etmek en güvenlisi: 14 günlük sayacı bozuk bir derlemeyle başlatmazsın.

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

## Adım 11 — Kapalı test: 12 tester × 14 gün (muafsan atla)

Bu adım production'ın ön koşulu. Sayaç ancak 12 kişi opt-in **olduktan sonra**
işlemeye başlar, o yüzden testerları önce topla, sonra sürümü yayınla.

1. **Test ve yayınlama → Test → Kapalı test** → sürüm oluştur, Adım 9'daki
   **aynı AAB**'yi promote et (yeniden derlemeye gerek yok).
2. **Testers** sekmesi → e-posta listesi oluştur. Google Grubu kullanmak en
   pratiği: tek adres eklersin, grup üyeliği değiştikçe liste kendi güncellenir.
3. **12 kişiyi opt-in yaptır.** Sadece listede olmak yetmez — her kişi opt-in
   bağlantısını açıp *"Become a tester"* demeli **ve** uygulamayı Play'den
   kurmalı. Aile/arkadaş yeterli; ikinci Google hesapların da sayılır.
4. **14 gün boyunca kimse ayrılmamalı.** Süre **kesintisiz**: çıkıp geri dönen
   kişinin önceki günleri toplanmaz, sayaç sıfırlanır. Bu iki hafta boyunca
   testerlardan çıkmamalarını iste.
5. Bu sürede güncelleme yayınlamak sayacı **bozmaz** — hatta beklenen davranış.
   Geri bildirim geldikçe yeni sürüm at.

> **En sık hata:** listeye 12 kişi eklemek ve "tamam" sanmak. Play *opt-in olmuş*
> tester sayar. Kapalı test panosundaki sayacı gözünle doğrula.

Süre dolunca: **Dashboard → "Apply for production access"**. Kapalı testin nasıl
geçtiği, uygulamanın kime ne fayda sağladığı ve production'a hazır olduğu
sorulur — bunları ciddiye alarak yaz, form gerçekten okunuyor. İnceleme
**≤7 gün**.

---

## Adım 12 — Production'a çıkış

1. **Test ve yayınlama → Üretim** → yeni sürüm → aynı AAB'yi kullan
2. Sürüm notlarını yaz (TR + EN)
3. Ülke/bölge seçimi
4. **İncelemeye gönder**

İlk inceleme genelde birkaç gün sürer; yeni geliştirici hesaplarında daha uzun
sürebilir. Reddedilirse gerekçe e-postayla gelir.

---

## Adım 13 — Yayın sonrası ilk hafta

- Play Console → **Kalite → Android vitals**: ANR ve çökme oranını izle.
  Uygulamada çökme raporlama SDK'sı yok, bu yüzden Dart stack trace göremezsin
  — yalnız native/ANR verisi gelir. `mapping.txt` AAB'ye gömülü olduğu için
  Play'in gösterdiği yığınlar deobfuscate edilmiş olur.
- Kullanıcı yorumlarını izle: veri kaybı bildiren tek bir yorum bile
  Adım 14'teki ilk maddeyi acil hale getirir.

---

## Adım 14 — Yayından SONRA yapılması zorunlu teknik işler

Bunlar v1'i bloke etmiyor ama **ilk güncellemeden önce** çözülmeli.

### 14.1 `CLAUDE.md` geriye-uyumluluk politikasını emekliye ayır

Politika metninde zaten yazıyor: "ilk mağaza yayınına kadar geçerlidir."
O gün geldi. Yayından sonra:

- **`defaultValue` yasağı kalkmalı.** Mevcut bir `HiveType`'a yeni `HiveField`
  eklersen Hive eski kayıtlarda o alanı `null` döner; alan non-nullable ise
  üretilen adapter `fields[N] as String` yapıp **okuma anında çöker**.
  Çözüm: `@HiveField(20, defaultValue: 'TRY')` ya da alanı nullable yap.
- **Yedek şeması artık silinemez.** `data_serialization_service.dart:482`:

  ```dart
  if (version != schemaVersion) {
    throw BackupVersionMismatch(version, schemaVersion);
  }
  ```

  v1.0.0 **`schemaVersion = 6`** ile çıkıyor (`:112`; borç hesaplama modları
  turunda 5'ten 6'ya çıkarıldı). Bu sıkı eşitlik, sürüm **6→7** olduğu anda
  v1.0.0 kullanıcısının Drive yedeğini geri yüklenemez yapar. Telefon
  değiştiren ilk kullanıcı verisini kaybeder. Şemayı yayından sonra ilk kez
  değiştirmeden ÖNCE bunu "eski sürümü oku ve yükselt" akışına çevir.

  > Yayın anında dondurulan sayı **6**'dır. Kapalı test sürecinde şema
  > değişirse bu sayıyı burada güncelle — yanlış sayı, migrasyonu yanlış
  > sürümden başlatır.

### 14.2 Çoklu para birimi genişlemesi — ne güvenli, ne değil

| Değişiklik | Geriye uyumluluk etkisi |
|---|---|
| Yeni para birimi eklemek (GBP, CHF, JPY…) | **Yok.** `currency` bir `String` (`wallet_model.dart:18`), enum değil. `kSupportedCurrencies`, `kCurrencySymbols`, `kNoiseThresholds` ve `ExchangeRateService._supported` listelerine eklemek yeterli. Şema değişmez. |
| Borç/alacağa `currency` alanı eklemek | **Gerek yok, ekleme.** Birim kaydın cüzdanından türetilir (`DebtModel.walletId` / `ReceivableModel.walletId`, ikisi de HiveField 2) ve v1'de borç/alacak her para biriminde açık. Alan eklemek hem gereksiz hem riskli: eski kayıtlarda null → 14.1'deki çökme. |
| Yatırımlara para birimi | Zaten var (`InvestmentModel.currency`, nullable) ama anlamı **fiyat kaynağının birimi** (AAPL → USD); değerleme birimi cüzdandan gelir. Bu ikisini karıştırma. |
| Cüzdanın para birimini sonradan değiştirilebilir yapmak | **Yapma.** `wallet_form_dialog.dart:366` şu an kilitliyor ve doğrusu bu; açarsan tüm geçmiş tutarlar sessizce yeniden yorumlanır. |

### 14.3 `google_sign_in` 7.x'e geçiş

Mevcut 6.3.0, `google_sign_in_android` 6.2.1 üzerinden Google'ın deprecate
ettiği legacy Google Sign-In SDK'sını (`play-services-auth:21.0.0`) kullanıyor.
Google kesin kapatma tarihi yayınlamadı, ama v7 Credential Manager'a geçti.

### 14.4 Bozuk Hive kutusundan kurtarma yolu

`init_error_page` bilinçli olarak veri silmiyor — doğru karar. Ama kutu kalıcı
bozulursa "Tekrar Dene" sonsuza dek başarısız olur ve tek çare kaldır-yeniden
kur = tüm veri gider. Hata ekranına **"Drive yedeğinden geri yükle"** eklenmeli.

### 14.5 Ertelenmiş işler

- **Yerel Hive AES-256 şifrelemesi** — eklenince Data Safety'de "beklemede
  şifreli = Evet" yapılır. DI'ı elle düzenle (build_runner `injection.config.dart`'ı bozuyor).
- **Para kazanma** — karar verildi, bkz. `cunehat-monetizasyon-plani.md`:
  reklam ve abonelik **yok**; tek kalem, işlev açmayan bir bağış kutusu ve o da
  `kDonationEnabled` bayrağı `false` başlayacak. Kod henüz yazılmadı ve v1.0'ı
  **bloke etmiyor.** Açılması müşavirin faaliyet kodu cevabına bağlı.
  Data Safety formu bağış kutusundan **etkilenmez** (ödeme Play'de gerçekleşir).
- **ML Kit unbundled varyantı** — `play-services-mlkit-text-recognition`'a
  geçmek indirme boyutunu ABI başına ~11 MB düşürür. 2026-08-08'de ölçüldü:
  `libmlkit_google_ocr_pipeline.so` arm64'te 11,1 MB (sıkıştırılmamış) ve
  cihaza inen ~19 MB'ın tek en büyük kalemi.
- **Kotlin Gradle Plugin → Built-in Kotlin göçü.** Derleme şu uyarıyı veriyor:
  *"applies the Kotlin Gradle Plugin, which will cause build failures in future
  versions of Flutter."* Bugün yalnız uyarı; ama hem `android/app/build.gradle.kts`
  hem de `shared_preferences_android` eklentisi KGP uyguluyor. Flutter yükseltmesi
  bunu bir gün **sert hataya** çevirecek — yayını bloke etmez, ilk büyük Flutter
  yükseltmesinden önce hallet.
  Kılavuz: <https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers>
