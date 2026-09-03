# ÇuNehat — Google Play İlk Yayın Rehberi

Kod tarafı hazır. Bu doküman **kodla halledilemeyen, senin yapman gereken**
adımları sırayla anlatır. Adımlar birbirine bağımlı — özellikle 4 ve 9
arasındaki sıra kritik, sebebi 9'da açıklanıyor.

**Önkoşullar:** Google Play Developer hesabı (tek seferlik 25 USD), bir Google
Cloud projesi, Flutter SDK kurulu.

**Uygulama kimliği (değiştirilemez, yayından sonra sabit):**
`dev.halilibrahim.cunehat` · sürüm `1.0.0+4` (yüklenmedi; `+3` kapalı testte)

> **Sürüm kodları kalıcı tüketilir.** Bir kod herhangi bir kanala bir kez
> yüklendiyse, o sürüm silinse/atılsa bile geri gelmez. `1` yakıldı (ilk
> deneme reddedildi), `2` ve `3` kapalı teste yüklendi. `4` **repoda hazır ama
> Play'e yüklenmedi** — yüklenene kadar yeni işler aynı `+4` içinde
> birikebilir, her commit için artırmaya gerek yok.
>
> **Hangi kodun yüklendiğini etiketlerden oku, hafızadan değil.** Yüklenen her
> derlemenin `v<versionName>+<versionCode>` adında açıklamalı bir git etiketi
> vardır (bkz. 15.6). `git tag -l "v*+*"` yüklenmiş kodların listesidir;
> pubspec'teki numara etikette YOKSA o kod henüz yakılmamıştır.
>
> `versionName` `1.0.0` duruyor. Kapalı test turlarında kullanıcıya görünen
> adı sabit tutmak normal; kullanıcıya duyurulacak bir davranış değişikliği
> çıkarken `1.0.1`'e geç.

---

## 📍 Durum panosu — son ölçüm 21 Ağustos 2026

| Adım | Ne | Durum |
|---|---|---|
| 1 | Upload keystore + imzalı AAB | ✅ `android/key.properties` var; AAB `CN=Halil Ibrahim Avsar` / SHA-1 `C6:75:6E:…:58:EB` ile imzalı (debug değil) |
| 2 | Syncfusion Community License | ✅ Onaylandı (#863579, 18 Ağu 2026). **Kodda yapılacak iş yok** — aşağıdaki nota bak |
| 3 | Gizlilik politikası yayında | ✅ `privacy-policy.html` → 200; `RELEASE_GUIDE.html` ve analiz dokümanı → 404 (sızıntı yok) |
| 4 | OAuth consent ekranı | ✅ Published; `drive.appdata` **non-sensitive** tabloda doğrulandı |
| 5 | Android OAuth istemcisi (upload anahtarı) | ✅ "ÇuNehat upload key" (10 Ağu 2026) |
| 6 | Play Console'da uygulama | ✅ Oluşturuldu |
| 7 | Data Safety formu | ✅ Dolduruldu |
| 8a | İçerik derecelendirme + hedef kitle | ✅ Dolduruldu |
| 8b | App access + finansal özellikler | ✅ Dolduruldu |
| 8c | **Mağaza girişi (metin + ikon + görseller)** | ✅ tr-TR + en-US girildi. Mağaza adı **`CuNehat`** olarak KALACAK — bilinçli karar (30 Ağu). Uygulama içi/görsel taraf `ÇuNehat`; fark biliniyor ve kabul edildi, bkz. aşağıdaki not |
| 8d | **Etiketler (3 tane)** | ✅ Mağaza ayarlarıyla birlikte gönderildi |
| — | **Cihaz duman testi** | ⬜ **KALAN** — Adım 10'daki 14 maddenin hiçbiri işaretli değil |
| 9 | AAB yükle → Play'in SHA-1'i → 3. OAuth istemcisi | ✅ **TAMAM** — üç istemci de doğru; Play sürümünde Drive yedekleme cihazda doğrulandı (29 Ağu) |
| 11 | Kapalı test 12 tester × 14 gün | 🟢 **SAYAÇ İŞLİYOR** — 13 tester opt-in oldu (28 Ağu). Panoda ilk iki madde ✔; kalan: "en az 12 kullanıcıyla 14 gün". Production başvurusu en erken **~11 Eyl**, inceleme ≤7 gün → **~18 Eyl** |
| 12 | Production | ⬜ |

**Kod tarafı sağlık (3 Eyl 2026 ölçümü):** `flutter test` **2123/2123**,
`dart analyze` **0 sorun**, `flutter build appbundle --release` **başarılı**
(88,6 MB, versionCode 4, upload anahtarıyla imzalı). Yayını bloke eden teknik
hata yok. **Cihaz duman testi hâlâ yapılmadı** ve `+4` uygulamanın açılış
ekranını baştan yazıyor — yüklemeden önce en az bir kez sideload edip bakılmalı
(bkz. Adım 10).

**Kritik yol:** mağaza girişi (8c/8d) → kapalı test track'i + 12 tester ×
14 gün → production ≤7 gün. **En erken yayın ~3 hafta.**

> **⚠️ Play imzalama parmak izi CİHAZDAN ölçüldü (28 Ağu 2026).** Console'a
> 26 Ağustos'ta girilen `CB:7A:0E:…:90:C4` **yanlış**. Play'in kurduğu APK
> `apksigner` ile okundu ve gerçek imza `3C:64:FF:8D:…:65:FC`
> (`CN=Android, O=Google Inc.`, 4096-bit RSA, `installerPackageName=
> com.android.vending`, `versionCode=2`). Yer gerçeği cihazdaki APK'dır;
> Play Console'daki "App signing key certificate" değerini yeniden oku ve
> hangisinin doğru olduğunu karşılaştır. Ölçüm komutu:
>
> ```bash
> P=$(adb shell pm path dev.halilibrahim.cunehat | grep base.apk | sed 's/package://' | tr -d '\r')
> adb pull "$P" /tmp/play.apk
> ~/Android/Sdk/build-tools/36.0.0/apksigner verify --print-certs /tmp/play.apk
> ```
>
> Bugün Drive **çalışıyor** olmasına rağmen bu kayıt düzeltilmeli: access
> token yolu bu eşleşme olmadan da yürüyor, ama ileride idToken /
> serverAuthCode eklenirse ya da Google bu yolu sıkılaştırırsa sessizce
> patlar. Doğru parmak izi için ayrı bir Android istemcisi aç; yanlış olanı
> ancak doğrusunun çalıştığı doğrulandıktan sonra sil.

> **🔴 KÖK NEDEN BULUNDU — Drive yedekleme (28 Ağu 2026).** Play'den inen
> `1.0.0+2`'de **giriş yapılıyor ama "Yedekle" patlıyor.** Bu ikisi AYRI
> yollar ve ayrı olmaları teşhisi bir gün geciktirdi:
>
> | Yol | Kayıtlı OAuth istemcisi gerekir mi | Play sürümünde |
> |---|---|---|
> | `signIn()` — hesap seçici | **Hayır** | ✅ çalışıyor |
> | `authHeaders` → `GoogleAuthUtil.getToken` | **Evet** — paket + imza + kapsam üçlüsü sunucuda eşleştirilir | ❌ patlıyor |
>
> **Sebep: Console'daki Play imzalama parmak izi yanlış.** Girilen
> `CB:7A:0E:…:90:C4`; cihazdan ölçülen gerçek imza
> `3C:64:FF:8D:…:65:FC`. Yani Play'den inen sürüm için kayıtlı istemci
> pratikte **yok**.
>
> Üç derleme bunu doğruluyor:
>
> | Derleme | İmza | Kayıtlı mı | R8 | Drive |
> |---|---|---|---|---|
> | debug | `C5:0D:…` | ✅ | kapalı | ✅ |
> | sideload release | `C6:75:…` | ✅ | **açık** | ✅ |
> | Play dahili test | `3C:64:…` | ❌ | açık | ❌ yedekleme |
>
> Sideload satırı **R8'i eliyor**: aynı minify'lı kod, kayıtlı imzayla
> çalışıyor. Tek değişken kayıtlı-olmayan sertifika.
>
> **ÇÖZÜM:** Cloud Console → Clients → Create client → Android:
> paket `dev.halilibrahim.cunehat`, SHA-1
> `3C:64:FF:8D:AB:77:B5:7F:34:00:8D:A4:7B:6B:07:FD:93:D8:65:FC`.
> Sonra uygulamayı **kaldırıp Play'den yeniden kur** — Play Hizmetleri
> (paket+imza+kapsam) için olumsuz sonucu önbelleğe alıyor ve beklemekle
> düşmüyor. Yanlış `CB:7A:…` istemcisini ancak yenisi doğrulandıktan sonra
> sil. Uygulamada değişiklik gerekmez, yeni sürüm yüklenmez.
>
> **Kod tarafında düzeltilen teşhis körlüğü:** `_mapPlatformException`
> tanımadığı her platform hatasını `serverError`a düşürüyordu → kullanıcıya
> *"Google Drive şu anda yanıt veremiyor, sonra tekrar deneyin"*, yani
> tekrar denemenin asla çözmeyeceği bir arıza için yanlış öneri. Artık ham
> `code/message/details` günlüğe basılıyor ve token yolunun kodları
> (`exception`, `user_recoverable_auth`, `failed_to_recover_auth`)
> `DriveOperationStatus.tokenFailed`e ayrılıyor.

---

## ⏱️ ÖNCE OKU — takvimi belirleyen kural: 12 tester / 14 gün

**13 Kasım 2023'ten sonra açılmış *kişisel* geliştirici hesapları**, production'a
başvurabilmek için önce **kapalı test (closed testing)** yürütmek zorunda:

| Şart | Değer |
|---|---|
| Minimum tester | **12** |
| Süre | **14 gün kesintisiz** opt-in |
| Dahili test sayılır mı | **HAYIR** — Google: *"internal testing does not satisfy this requirement"* |
| Sayaç ne zaman başlar | Kişinin **kapalı teste opt-in olduğu an**; kurulum değil opt-in sayılıyor |
| Kesinti olursa | 14 gün **ardışık** olmak zorunda; çıkıp giren kişinin sayacı SIFIRLANIR → 12 değil **14–15 kişi** hedefle |
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

> **⛔ En pahalı yanılgı: "önce her şeyi bitirip AAB'yi en son yüklerim."**
> AAB yüklemek son adım değil, **sayacı başlatan** adım. Yükleme geciktiği her
> gün yayına doğrudan ekleniyor. Kapalı test yayındayken yeni sürüm atmak
> sayacı **bozmaz** — düzeltmeleri test süresi içinde yapmak beklenen davranış,
> mükemmel sürümü beklemek değil.

---

## Adım 1 — Upload keystore üret (KRİTİK, bir kez)

Şu an release derlemesi **debug anahtarıyla** imzalanıyor (`build.gradle.kts`
`key.properties` yoksa debug'a düşüyor). Play bunu reddeder.

> **✅ ÇÖZÜLDÜ (21 Ağu 2026 doğrulaması).** `~/keystores/cunehat-upload.jks`
> kullanılıyor ve `android/key.properties` yerinde; `flutter build appbundle
> --release` bugün başarıyla derledi ve çıkan AAB **upload anahtarıyla**
> imzalı (`CN=Halil Ibrahim Avsar`, SHA-1 `C6:75:6E:…:58:EB`) — debug
> anahtarına düşmüyor. Aşağıdaki üretme komutuna **ihtiyacın yok**; yalnız
> keystore'u kaybedersen ya da Play'e ilk yüklemeden önce değiştirmek
> istersen gerekir. **Play'e henüz hiçbir şey yüklenmediği sürece yeni anahtar üretmek
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

> **APK'da bu komut çalışmaz.** minSdk 24+ olduğu için v1 (JAR) imzalama
> kapalı; APK'da `META-INF/*.RSA` yok, yalnız v2/v3 imza blokları var.
> APK için `apksigner` kullan:
>
> ```bash
> ~/Android/Sdk/build-tools/36.0.0/apksigner verify --print-certs \
>   build/app/outputs/flutter-apk/app-release.apk
> ```
>
> Beklenen: `Signer #1 certificate SHA-1 digest: c6756e5547e50abf672cbd8ef014c5d722b058eb`

### Yandan yüklenebilir APK (Drive'ı R8 altında erken denemek için)

AAB Play'e gider; cihaza elle kurmak için APK gerekir. Upload anahtarının
SHA-1'i Cloud Console'a kayıtlı olduğu için bu APK'da **Drive girişi de
çalışır** — yani obfuscation'ın Google Sign-In/Drive'ı bozup bozmadığını
Play turunu beklemeden görürsün.

```bash
flutter build apk --release --split-per-abi
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk  (~42 MB)
```

`--split-per-abi` olmadan tek "fat" APK üretilir (~108 MB, tüm ABI'ler).
Telefona atmak için arm64 sürümü yeter.

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

**✅ ALINDI — 18 Ağustos 2026, onay #863579.** Bu adım kapandı.

### "Lisansı aldık ama kodda hiçbir şey yapmıyoruz, boşa mı gitti?" — hayır

İki ayrı şey karıştırılıyor:

| | Ne demek | Bizde durum |
|---|---|---|
| **Lisans (hak)** | Paketi kullanma iznin var mı | **Şart. Alındı.** Olmadan `syncfusion_flutter_pdf`'i uygulamada kullanmak lisans ihlali — kod çalışsa bile. |
| **Anahtar kaydı (kod)** | Paketin hakkı *doğrulaması* | **Gerekmiyor.** Syncfusion bu doğrulamayı kaldırdı. |

Yani lisans, kodun değil **senin** yükümlülüğün. Play'e yüklerken kimse
sormuyor ama Syncfusion denetlerse dayanağın bu onay.

**Ölçülen kanıt (2026-08-21).** Projenin gerçekten çözdüğü sürüm
`syncfusion_flutter_pdf` **29.2.11** + `syncfusion_flutter_core` **29.2.11**
(`pubspec.lock`). Core'un içinde `registerLicense` *var* ama gövdesi boş:

```dart
// ~/.pub-cache/hosted/pub.dev/syncfusion_flutter_core-29.2.11/lib/src/license.dart
@Deprecated('License registration is not required now')
class SyncfusionLicense {
  static void validateLicense(BuildContext context) {}
  static void registerLicense(String licenseKey) {}   // ← hiçbir şey yapmıyor
}
```

Yani `registerLicense(...)` çağırsan da **hiçbir etkisi olmaz**. Bu yüzden:

- `syncfusion_flutter_core`'u doğrudan bağımlılık **yapma** (gereksiz),
- `main()`'de `registerLicense` **çağırma** (no-op),
- anahtarı **repoya koyma** (repo public, üstelik işe yaramıyor).

> Bu bölüm daha önce sürümü yanlış yazıyordu (core 31.1.19 denmişti; proje
> 29.2.11 çözüyor). Sonuç değişmedi — 29.2.11'de de kayıt gerekmiyor — ama
> ileride sürüm yükseltilirse **o sürümün `license.dart`'ına yeniden bak.**

> **Başvuru sonrası gelen e-postadaki 7 günlük anahtar seni ilgilendirmiyor.**
> O anahtar **Essential Studio installer**'ı (Windows/Mac/Linux masaüstü
> kurulumu) içindir. Sen paketi pub.dev'den alıyorsun, o kurulumu hiç
> indirmeyeceksin.

> **Devredilemez:** kodu satarsan alıcı kendi lisansını alır; projeyi açık
> kaynağa çevirmeden önce Syncfusion'dan ayrıca onay gerekir.

---

## Adım 3 — Gizlilik politikasını yayınla (KRİTİK)

`docs/privacy-policy.html` hazır (TR + EN, 4 Ağustos 2026 güncel). Play herkese
açık bir URL istiyor.

> **✅ YAYINDA ve doğrulandı (21 Ağu 2026).** Üç adres ölçüldü:
> `.../ÇuNehat/privacy-policy.html` → **200** (TR+EN içerik yerinde),
> `.../ÇuNehat/RELEASE_GUIDE.html` → **404**,
> `.../ÇuNehat/cunehat-mantiksal-analiz.html` → **404**.
> Yani `_config.yml`'deki `exclude` listesi çalışıyor, sızıntı yok.
> Aşağıdaki 1–6 adımları yeniden yapmana gerek yok; **ancak `_config.yml`'i
> değiştirirsen 6. maddedeki 404 kontrolünü tekrarla.**

> ⚠️ **Pages `/docs` içindeki HER dosyayı yayınlar.** Repo zaten public, ama
> Pages bu dosyaları tarayıcıda okunur ve indekslenebilir sayfalara çevirir.
> 2026-08-08'de buna göre düzenlendi:
> - `cunehat-monetizasyon-plani.md` **repodan çıkarıldı** (kişisel vergi /
>   BAĞ-KUR ayrıntıları içeriyordu) → `../ÇuNehat-ozel/` altında duruyor.
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
   `https://halilibrahimavsar.github.io/ÇuNehat/privacy-policy.html`
4. Tarayıcıda aç, TR ve EN bölümlerinin ikisinin de göründüğünü doğrula.
5. İçindeki iletişim e-postasını (`halirlnj@gmail.com`) teyit et.
6. **Sızıntı kontrolü:** `.../ÇuNehat/RELEASE_GUIDE.html` ve
   `.../ÇuNehat/cunehat-mantiksal-analiz.html` adreslerinin **404 verdiğini**
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
   - App name: `ÇuNehat`
   - User support email + Developer contact: kendi e-postan
   - App domain → **Privacy policy link**: Adım 3'teki URL
4. **Scopes** (yeni arayüzde **Data Access**) → Add or remove scopes → yalnız
   `https://www.googleapis.com/auth/drive.appdata` ekle. Başka kapsam ekleme.
   **Save'e basmayı unutma** — basılmazsa üç tablo da "No rows to display"
   kalır ve kapsam beyan edilmemiş olur. (2026-08-10'da tam olarak bu oldu.)
   - Kapsam **seçicide görünmüyorsa Drive API enable edilmemiştir** (2. adım);
     seçici yalnız açık API'lerin kapsamlarını listeler.
   - Ekledikten sonra **hangi tabloya düştüğüne bak.** Beklenen:
     *Your non-sensitive scopes*. Sensitive'e düşerse Console dokümantasyondan
     farklı sınıflandırıyor demektir → user cap ve doğrulama konusu açılır.
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
sınırlar. ÇuNehat hiç sensitive/restricted kapsam istemiyor → sınırlayacak
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
| Uygulama adı | **`ÇuNehat: Gelir Gider Takibi`** *(27 kr — gerekçesi `store-listing.md`)* |
| Varsayılan dil | Türkçe (tr-TR) |
| Uygulama mı oyun mu | Uygulama |
| Ücretsiz mi ücretli mi | Ücretsiz *(ücretliye sonradan geçilemez)* |
| Kategori | Finans |

> **Uygulama adı ≠ `android:label`.** Manifest'teki `ÇuNehat` telefondaki
> simgenin altında yazan ad; buradaki alan **mağazada aranan ve indekslenen**
> ad. Play'in en ağır ASO alanı bu, 30 karakterin 23'ünü sıfır arama hacimli
> markaya harcamak en pahalı hata olurdu. Uygulama oluştururken sade "ÇuNehat"
> girdiysen sorun değil — **Mağaza girişi** ekranından değiştirilebiliyor.

### Etiketler (en fazla 5)

Uygulama oluşturma ekranında değil, sonradan:
**Mağaza varlığı → Mağaza ayarları → Etiketleri yönet**

| Seç | Sırayla |
|---|---|
| 1 | Bütçeleme / Budgeting |
| 2 | Kişisel finans / Personal finance |
| 3 | Harcama takibi / Expense tracking *(ayrı seçenek olarak varsa)* |

Etiket listesi sabit bir seçicidir; birebir aynı etiketi bulamazsan **en yakınını**
seç, uydurma.

**Beşi doldurmak zorunlu değil ve doldurmaya çalışma.** Etiketler arama
sıralamasına girmiyor — aramayı başlık ve açıklamalar belirliyor. Etiketlerin
tek işi seni *gözat/keşfet kümelerine* ("Harcamalarını takip et") sokmak. Alakasız
etiket seni yanlış kümeye sokar, gelen kullanıcı bakıp çıkar ve 2026 algoritmasının
en ağır sinyali olan **kurulum sonrası davranış** bozulur. Az ve doğru > çok ve gevşek.

**⚠️ Mantıklı görünen ama seçilmemesi gerekenler:**

| Etiket | Neden hayır |
|---|---|
| Ödemeler, Bankacılık, Para transferi, Kripto | **Adım 8'deki "finans özelliği yok" beyanıyla çelişir.** Play beyanla mağaza metadata'sını karşılaştırıyor; çelişki inceleme takılması demek. |
| Yatırım / Alım satım | Aynı çelişki + seni borsa/kripto uygulamalarının kümesine sokar, orada dönüşüm sıfıra yakın olur |
| Kredi, Faturalar | Uygulama kredi vermiyor, fatura ödettirmiyor |

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

- **Telefon ekran görüntüleri** → ✅ `docs/store/screenshots/` altında **8 adet**
  hazır (26 Ağu 2026, düzeltilmiş yapı + demo veriyle yeniden çekildi). Ham
  çekimler `tools/store_screenshots.py` ile 1080×1920 tuvale, marka zemini,
  başlık şeridi ve özellik çipleriyle yerleştirildi. Şerit metni ya da renk
  değişirse betiği tekrar çalıştır, elle düzenleme.
  **Tablet (7"/10") görselleri YOK** — telefon yayınını bloke etmez ama Play'in
  büyük ekran vitrininde geri plana atar; ilk güncellemeye yazıldı.

> **Kalan iş bu adımda yalnız Console'a girmek:** metinleri `store-listing.md`'den
> kopyala, üç görsel setini yükle. Uygulama adının **`ÇuNehat: Gelir Gider Takibi`**
> olduğundan emin ol — sadece "ÇuNehat" bırakılırsa 30 karakterlik en ağır ASO
> alanının 23'ü boşa gider.

> **Metin yazarken dikkat:** "kredi verme", "borç para verme", "faizsiz kredi"
> gibi ifadeler Play'in Finansal Hizmetler politikasını tetikler ve ek beyan
> ister. ÇuNehat borç/alacak **takibi** yapıyor, finansal ürün sunmuyor —
> metin bunu net söylemeli. "Borçlarını ve alacaklarını takip et" güvenli;
> "kredi çöz" değil.

> **Marka yazımı — VERİLMİŞ KARAR (30 Ağu 2026).** Mağaza adı `CuNehat: Gelir
> Gider Takibi`, düz `C` ile, ve **öyle kalacak.** Bu bilinçli bir karardır,
> eksik iş değil; ileride "düzeltilecek hata" sanılmasın.
>
> Bilinen ve kabul edilen fark: uygulamanın kendisi `ÇuNehat` diyor —
> `android:label`, 14 l10n dizesi, gizlilik politikası (17 yerde) ve **tanıtım
> görselindeki kelime işareti**. Sonuncusu mağaza sayfasında başlığın hemen
> yanında duruyor, yani fark orada görünür. Vazgeçilirse iki alan düzenlemesi
> yeter (tr-TR + en-US uygulama adı), yeni derleme gerekmez;
> `docs/store/store-listing.md` hâlâ `Ç`'li metinleri taşıyor.

**Diğer formlar:**

| Form | Cevap |
|---|---|
| İçerik derecelendirmesi | Anket; kategori Finans, şiddet/cinsellik/kumar/IAP yok → düşük derece |
| Hedef kitle ve içerik | Planlanan 13+; **gönderilen 18+** (Play bunu `18 - 2147483647` diye gösteriyor). Finans uygulaması için savunulabilir ama kitleyi daraltır — bilinçli miydi, doğrula |
| Reklamlar | **Uygulamada reklam yok** |
| App access (uygulama erişimi) | **"Evet"** seç, kullanıcı adı/parola alanlarını **boş bırak**, talimat gir: *"Uygulamanın tüm işlevleri girişsiz kullanılabilir; hesap gerekmez. Google ile giriş yalnız isteğe bağlı Drive yedeği içindir. Uygulama kilidi (PIN/biyometrik) varsayılan olarak kapalıdır."* |
| Devlet uygulaması mı | Hayır |
| Finansal özellikler | Yalnız en alttaki **"Uygulamamda finans ile ilgili özellik sağlanmıyor"** kutusunu işaretle; diğer ~20 kutunun hepsi boş kalsın |

> **App access'te neden "Hayır" değil "Evet"?** Sezgi "giriş gerekmiyor → Hayır"
> diyor, ama **"Hayır" seçilince not alanı hiç açılmıyor.** İnceleyici o zaman
> Drive giriş ekranını ve PIN/biyometrik kilidi kendi başına yorumlamak zorunda
> kalıyor. "Evet" + boş kimlik bilgisi + talimat, notu iletmenin tek yolu.
> Kilidin varsayılan kapalı olduğu koddan doğrulandı
> (`app_auth_bloc.dart`: kilit yalnız `isBioEnabled || isPinSet` ise basılıyor).

> **Finansal özellikler formu boş bırakılamaz.** Finans özelliği *olmayan*
> uygulamalar dahil herkesin doldurması zorunlu; doldurulmadan güncelleme
> yayınlanamıyor. Sıfır kutu işaretli hâli "cevap yok" demek, "hayır" demek değil.
> Yakın-kaçırma tuzakları: **"Mobil ödemeler ve dijital cüzdanlar"** (bizim cüzdan
> bir defter kalemi, ödeme aracı değil), **"Borsada alım satım ve portföy
> yönetimi"** (yatırım *takibi*; emir iletmiyor, varlık saklamıyor),
> **"Kredi izleme ve raporlama"** (kredi *notu* izleme demek, borç takibi değil),
> **"Finansal danışmanlık"** (bütçe aşım uyarısı eşik alarmı, kişiselleştirilmiş
> tavsiye değil).

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
4. Yükleme bittikten sonra imzalama sayfasını aç. **Menüdeki "Uygulama
   imzalama" adı emekli oldu** — sayfa artık **Test ve yayınlama → Uygulama
   bütünlüğü** altında (Console sürümüne göre "Kurulum → Uygulama bütünlüğü"
   ya da "Play ile korunuyor → Play uygulama imzalamayı yönet"). Menüde
   aramak yerine adres çubuğunda `.../app/<appId>/keymanagement` en garantisi.
   Sayfada **İKİ** sertifika var; gereken **App signing key certificate**,
   "Upload key certificate" değil (ikisi `C6…` / `CB…` diye benzer başlıyor).
5. Bu SHA-1'i Cloud Console'a **aynı paket adıyla** kaydet:
   `dev.halilibrahim.cunehat`.

   > **Ölçüldü (2026-08-10):** Cloud Console'da Android istemcisinin
   > **tek bir SHA-1 alanı** var — `SHA-1 certificate fingerprint *`, tek
   > metin kutusu. İkinci parmak izi eklenemiyor. Her sertifika için **ayrı
   > Android OAuth istemcisi** açacaksın: paket adı aynı, SHA-1 farklı.
   > Google'ın kuralı *paket adı + SHA-1 çiftinin* tüm Cloud/Firebase
   > projelerinde benzersiz olması; aynı paketin birden çok istemcisi normal.

   Parmak izini Play Console'da bulacağın yer (Cloud Console'un kendi ipucu):
   **Protected with Play → Play Store protection → Manage Play app signing**.
   Eski arayüzdeki karşılığı: Test ve yayınlama → Kurulum → Uygulama imzalama.

**Bu uygulamanın üç sertifikası var — her biri ayrı istemci:**

| Ne için | SHA-1 | İstemci / durum (2026-08-10) |
|---|---|---|
| Debug — `flutter run` | `C5:0D:D6:24:25:FA:FA:AB:6F:7F:5E:68:A2:7F:BB:72:99:D2:92:0B` | ✅ "Android client 1" (30 Tem 2026) |
| Upload — yerel release APK (yandan yükleme) | `C6:75:6E:55:47:E5:0A:BF:67:2C:BD:8E:F0:14:C5:D7:22:B0:58:EB` | ✅ "ÇuNehat upload key" (10 Ağu 2026) |
| **Play App Signing** — mağazadan inen sürüm | **`3C:64:FF:8D:AB:77:B5:7F:34:00:8D:A4:7B:6B:07:FD:93:D8:65:FC`** (cihazdan ölçüldü) | ✅ Kayıtlı. Yanlış `CB:7A:…` değeri **yerinde düzeltildi** (yeni istemci açılmadı), Console'da 3 istemci var ve üçü de doğru |

**Hangisi ne zaman ısırır:**

- **Debug yoksa:** geliştirirken Drive girişi çalışmaz. (Kayıtlı, sorun yok.)
- **Upload yoksa:** yerel `--release` APK'sını cihaza yandan yüklediğinde
  Drive çalışmaz. R8 altında Drive'ı Play'i beklemeden denemek istiyorsan
  bunu ekle.
- **Play yoksa:** *mağazadan indiren herkeste* Drive çalışmaz — sende
  çalıştığı için fark edilmez. **En kritik ve en sık kaçırılan bu.**

> Yan not: Console uyarıyor — 6 ay kullanılmayan OAuth istemcileri silinmeye
> aday. Üç istemci de aktif kalacağı için pratikte konu değil.

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
- [ ] **Edge-to-edge:** hiçbir ekranda içerik durum çubuğunun / gezinme
      çubuğunun altına girmiyor, hiçbir düğme çubuğun arkasında kalmıyor ⚠️
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

> ⚠️ **Google ile giriş** başarısızsa: `google_sign_in` 6.x, Google'ın deprecate
> ettiği legacy SDK'yı kullanıyor. Çözüm `google_sign_in` 7.x'e (Credential
> Manager) geçiş — Production'a çıkmadan çöz.

> ⚠️ **Edge-to-edge neden ayrı bir madde:** `targetSdk = 36` (Android 16) ile
> edge-to-edge **zorunlu ve devre dışı bırakılamıyor** — uygulama artık durum ve
> gezinme çubuklarının altına da çiziyor. Kaynak koddan *kanıtlanamaz*, yalnız
> cihazda görülür — ama **nereye bakacağın** koddan çıkarılabilir.

### Edge-to-edge — ölçülmüş risk haritası (21 Ağu 2026)

| Ölçüm | Sonuç |
|---|---|
| `SystemChrome` / `SystemUiOverlayStyle` / `setEnabledSystemUIMode` | lib'de **0 sonuç** — hiç yapılandırılmamış, Flutter varsayılanına güveniliyor |
| `bottomNavigationBar` / `persistentFooterButtons` | **Yok** — bu klasik risk sınıfı bizde hiç yok ✅ |
| `showModalBottomSheet` çağrısı | **28 adet** |
| Bunlardan `useSafeArea: true` kullanan | **0 adet** ⚠️ |
| Alt dolgu için kullanılan desen | `viewInsets.bottom` (**klavye**) — `viewPadding.bottom` (**gezinme çubuğu**) hiç kullanılmıyor |

**Bu ayrım kritik:** `viewInsets.bottom` klavye kapalıyken **0**'dır. Yani
klavyeli formlar doğru davranırken, klavyesiz sheet'lerin en alt satırı
gezinme çubuğunun altına girebilir.

**Önce şu üçüne bak — sırayla:**

1. **Rapor → pasta grafikte bir kategoriye dokun** → açılan detay sheet'i
   (`category_details_bottom_sheet.dart`). Ekran yüksekliğinin %75'i sabit
   yükseklikte, `SafeArea` **yok**, alt dolgu **yok**. Listenin son satırı
   çubuğun altında kalıyor mu?
2. **Borç/alacak → kayıt düzenle** → `AddEntrySheet`. `SafeArea` var ama
   yalnız `viewInsets` ile besleniyor; **klavye kapalıyken** kaydet düğmesinin
   konumuna bak.
3. **İşlem ekleme sheet'i** (`transaction_form_fields.dart:188`) — burada
   `SafeArea` **var** ✅. Doğru davranışın referansı olarak kullan: diğer
   ikisi buna benzemiyorsa fark oradadır.

**Kırık çıkarsa çözüm sırası:** (a) `showModalBottomSheet`'e
`useSafeArea: true` eklemek en ucuz düzeltme; (b) yetmezse sheet gövdesine
`EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom)`.
Tek tek `SafeArea` sarmalamak **son çare** — sheet'in kendi köşe yuvarlaklığını
ve zeminini bozabiliyor.

R8 kaynaklı bir çökme çıkarsa `android/app/proguard-rules.pro`'ya ilgili
`-keep` kuralını ekleyip yeniden derle.

---

## Adım 11 — Kapalı test: 12 tester × 14 gün (muafsan atla)

> **⛔ ÖLÇÜLDÜ (28 Ağu 2026) — dahili test kapalı testi BLOKLUYOR.**
> Dahili teste opt-in olmuş bir hesap kapalı testi almaya **uygun değil**;
> Play ona dahili kanalı servis etmeye devam eder ve 12 kişilik sayaca
> yazılmaz. Google'ın kendi ifadesi:
>
> > *"A user who opts into your app's internal test is no longer eligible to
> > receive an open or closed test. To access an open or closed test, the user
> > must first opt out of the internal test and then opt in to the open or
> > closed test."*
>
> Kapalı test linkine tıklayıp kurmak **yetmiyor** — semptom "indirdi ama
> tester sayılmıyor". Opt-in durumu kullanıcı hesabına bağlı: developer
> tarafından listeden silmek onların kaydını DÜŞÜRMEZ. Her tester sırasıyla:
> (1) dahili test linki → "Programdan ayrıl", (2) kapalı test linki →
> opt-in, (3) uygulamayı kaldırıp Play'den yeniden kur.
>
> **Yapısal çözüm: listeleri kesiştirme.** Dahili testte yalnız geliştirici
> kalsın; 14–15 kişilik grup yalnız kapalı testte olsun.



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

### 14.1 `CLAUDE.md` geriye-uyumluluk politikası — ✅ EMEKLİYE AYRILDI (29 Ağu 2026)

Tetikleyici mağaza yayını değil, **gerçek kullanıcının veriye sahip olması**ydı
ve o eşik 28 Ağustos'ta kapalı testle geçildi: 13 testerın cihazında gerçek veri
var ve production erişimi onların uygulamayı **kurulu tutmasına** bağlı. Verisi
uçan tester uygulamayı siler, 14 günlük sayaç kırılır.

`CLAUDE.md` yeniden yazıldı: Hive alan kuralları, yedek migrasyon şartı ve
*"veriyi sil, yeniden kur artık bir çözüm değildir"* maddesi eklendi. Aşağıdaki
teknik gerekçe referans olarak duruyor:

- **`defaultValue` yasağı kalkmalı.** Mevcut bir `HiveType`'a yeni `HiveField`
  eklersen Hive eski kayıtlarda o alanı `null` döner; alan non-nullable ise
  üretilen adapter `fields[N] as String` yapıp **okuma anında çöker**.
  Çözüm: `@HiveField(20, defaultValue: 'TRY')` ya da alanı nullable yap.
- **Yedek şeması artık silinemez.** `data_serialization_service.dart:509`:

  ```dart
  if (version != schemaVersion) {
    throw BackupVersionMismatch(version, schemaVersion);
  }
  ```

  v1.0.0 **`schemaVersion = 9`** ile çıkıyor (`:135`). Son iki adım aynı
  yatırım turunda çıktı: **8** → `InvestmentModel.unbookedCost` (HiveField 15,
  uygulamaya girmeden önce alınmış varlığın cüzdandan düşülmeyen maliyeti);
  **9** → birikim hedefi kendi kaydı oldu (`goals` kutusu, **typeId 16**;
  yatırımdaki `targetAmount`/`goalCategory` kaldırıldı, yerine `goalId`
  HiveField 16 geldi). 6'dan 7'ye ise kategori hiyerarşisi turunda çıkmıştı —
  kategoriler prefs'ten Hive kutusuna taşındı ve kimlik ad yerine UUID oldu.
  Bu sıkı eşitlik, sürüm **9→10** olduğu anda v1.0.0 kullanıcısının Drive
  yedeğini geri yüklenemez yapar. Telefon değiştiren ilk kullanıcı verisini
  kaybeder. Şemayı yayından sonra ilk kez değiştirmeden ÖNCE bunu "eski
  sürümü oku ve yükselt" akışına çevir.

  > Yayın anında dondurulan sayı **9**'dur. Kapalı test sürecinde şema
  > değişirse bu sayıyı burada güncelle — yanlış sayı, migrasyonu yanlış
  > sürümden başlatır.
  >
  > ⚠️ **Bu paragrafın eski hali artık geçersizdi.** 8 ve 9'a geçiş eski
  > kurulumların yatırım kutusunu okunamaz yapmıştı (`fields[15] as double` →
  > null cast) ve o dönemin çözümü "veriyi sil"di. **Bir daha o çözüm
  > kullanılamaz:** sahada veri var. Aynı sınıftan bir değişiklik gerekirse
  > alan nullable olmalı ya da `defaultValue` almalı.
  >
  > Yeni kutu eklerken üç yer birlikte güncellenir: `app_initialization.dart`
  > (adapter kaydı + `openBox`), `DataSerializationService` (dışa aktarma,
  > geri yükleme, rollback, özet sayacı) ve `WalletMetricsService
  > .purgeWalletData` (cüzdan silinince temizlik). Hedef kutusu bunların
  > üçünde de var; sonraki kutu için örnek olarak bak.
  >
  > Migrasyonun neye benzediğinin çalışan bir örneği elde var:
  > `tools/migrate_backup_v6_to_v7.py` (6→7 geçişinde geliştiricinin kendi
  > yedeği için yazıldı). Uygulama içi migrasyon yazılırken referans alınabilir
  > — özellikle kategori kimliği ad→UUID dönüşümünde defterdeki `tag` ve
  > bütçedeki `categoryId` atıflarının da çevrilmesi gerektiği kısmı.

### 14.2 Çoklu para birimi genişlemesi — ne güvenli, ne değil

| Değişiklik | Geriye uyumluluk etkisi |
|---|---|
| Yeni para birimi eklemek (GBP, CHF, JPY…) | **Yok.** `currency` bir `String` (`wallet_model.dart:18`), enum değil. `kSupportedCurrencies`, `kCurrencySymbols`, `kNoiseThresholds` ve `ExchangeRateService._supported` listelerine eklemek yeterli. Şema değişmez. |
| Borç/alacağa `currency` alanı eklemek | **Gerek yok, ekleme.** Birim kaydın cüzdanından türetilir (`DebtModel.walletId` / `ReceivableModel.walletId`, ikisi de HiveField 2) ve v1'de borç/alacak her para biriminde açık. Alan eklemek hem gereksiz hem riskli: eski kayıtlarda null → 14.1'deki çökme. |
| Yatırımlara para birimi | Zaten var (`InvestmentModel.currency`, nullable) ama anlamı **fiyat kaynağının birimi** (AAPL → USD); değerleme birimi cüzdandan gelir. Bu ikisini karıştırma. |
| Cüzdanın para birimini sonradan değiştirilebilir yapmak | **Yapma — ve zaten gerekmiyor.** Kilit körü körüne değil koşullu: `wallet_form_dialog.dart:_resolveCurrencyLock` (:129) cüzdanda işlem *ve* sıfırdan farklı borç/alacak/yatırım yoksa kilidi kendiliğinden açıyor. Yani boş cüzdanda birim zaten serbest; dolu cüzdanda açmak tüm geçmiş tutarları sessizce yeniden yorumlar. |

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

---

## Adım 15 — Kapalı test yayındayken güncelleme yükleme (tekrarlanabilir)

Adım 9 *ilk* yüklemeyi anlatıyor; bu bölüm sonraki her sürüm için geçerli.
İlk kullanımı: **1 Eylül 2026, kapalı testin 3. günü, `1.0.0+3`.**

> **Sayaç bozulmaz.** 14 günlük kesintisiz-12-tester şartı *opt-in* durumunu
> sayar, sürüm sayısını değil. Kapalı test yayındayken sürüm atmak beklenen
> davranıştır; testerlar güncellemeyi Play üzerinden otomatik alır.

### 15.1 Yüklemeden önce — kod tarafı

```bash
dart analyze                                  # 0 sorun beklenir
flutter test                                  # tamamı yeşil olmalı
grep -n "schemaVersion = " lib/core/services/data_serialization_service.dart
git diff <yayındaki-commit>..HEAD -- lib/ | grep -E "^[-+].*(HiveField|typeId|schemaVersion)"
```

Son iki komut **veri uyumluluğu kapısıdır** (bkz. `CLAUDE.md`): 28 Ağustos'tan
beri testerların cihazında gerçek veri var.

- Çıktı boşsa → şema aynı, güncelleme mevcut veriyle ve mevcut Drive
  yedekleriyle uyumlu. Yükleyebilirsin.
- `schemaVersion` artmışsa → **önce migrasyon zinciri yazılmalı.** Migrasyonsuz
  yüklenen sürüm, testerların Drive'ındaki yedekleri geri yüklenemez hale
  getirir (`_parseBackup` sıkı eşitlik kontrolü, `data_serialization_service.dart`).
- `HiveField` / `typeId` satırları değişmişse → indeks yakma kurallarına uyduğunu
  ve yeni alanların eski kayıtlarda güvenli varsayılana düştüğünü doğrula.

### 15.2 versionCode

`pubspec.yaml` → `version: 1.0.0+N`. `N`, **herhangi bir kanala** yüklenmiş en
yüksek koddan büyük olmalı; yüklenen kod kalıcı tüketilir (bkz. dokümanın
başındaki not). Yükleme yapılmadığı sürece yeni işler aynı `+N` altında
birikebilir — her commit için artırmak gerekmez.

`versionName` (`1.0.0`) kapalı test turlarında sabit kalabilir; kullanıcıya
duyurulacak bir davranış değişikliği çıkarken artır.

### 15.3 Derle ve imzayı doğrula

```bash
flutter build appbundle --release

T=$(mktemp -d); unzip -q -o -d "$T" build/app/outputs/bundle/release/app-release.aab "META-INF/*"
keytool -printcert -file "$T"/META-INF/*.RSA | grep -E "Owner|Sahibi"; rm -rf "$T"
```

`CN=Halil Ibrahim Avsar` görmelisin. `CN=Android Debug` çıkarsa
`android/key.properties` okunmamış demektir — Play o dosyayı reddeder.

### 15.4 Play Console

1. **Test ve yayınlama → Test → Kapalı test** → yürüyen track → **Yeni sürüm
   oluştur** (mevcut sürümü "düzenleme", yeni sürüm oluştur).
2. `build/app/outputs/bundle/release/app-release.aab` dosyasını yükle.
   Play App Signing zaten açık; dosya otomatik yeniden imzalanır.
3. **Sürüm ayrıntıları → Bu sürümdeki yenilikler:** metni **her dil için ayrı**
   gir (tr-TR ve en-US). Hazır metinler: `docs/store/store-listing.md` →
   *Sürüm notları*. Sınır dil başına 500 karakter.
4. **Kaydet → Sürümü incele → İncelemeye gönder.** Kapalı test sürümleri de
   incelemeden geçer; ilk yayından sonraki turlar genelde saatler sürer.
5. Yayına alma yüzdesini **%100** bırak (kapalı testte kademeli dağıtım,
   güncellemeyi bazı testerlardan gizler ve sayacı izlemeyi zorlaştırır).

### 15.6 Etiketle — hangi kodun yüklendiğinin TEK kaydı

Play Console'da "hangi versionCode hangi commit'ti" diye bir alan yok; bunu
repo tutmak zorunda. Yükleme onaylandıktan sonra, AAB'nin derlendiği commit'e:

```bash
git tag -a "v1.0.0+4" -m "ÇuNehat 1.0.0 (versionCode 4) — kapalı test güncellemesi
...kapsam / şema durumu / doğrulama..."
git push origin "v1.0.0+4"      # repo'ya push ediyorsan
```

Kurallar:

- **Ad `v<versionName>+<versionCode>`** — pubspec'teki `version:` satırıyla
  birebir aynı. Böylece `git tag -l "v*+*"` yakılmış kodların listesi olur.
- **Açıklamalı (`-a`) olacak**, hafif etiket değil: mesaj kapsamı
  (`<önceki-etiket>..HEAD`), Hive şeması durumunu ve doğrulamayı
  (`dart analyze`, `flutter test`, AAB imzası) yazar. Mesaj, "bu sürümde ne
  vardı" sorusunun cevabıdır; sürüm notları kullanıcı diliyken bu mühendis
  dilidir.
- **Etiket AAB'nin derlendiği commit'i gösterir**, bir sonrakini değil.
  Yükleme reddedilirse etiketi sil, kodu artır, yeniden etiketle.

> Etiket olmadan geriye dönüp "testerdaki sürüm hangi koddu" sorusunu
> cevaplamanın yolu yok: `pubspec.yaml` her yüklemeden sonra ileri gidiyor ve
> geçmiş commit'lerdeki numara yalnız "o an ne hazırlanıyordu"yu söylüyor,
> "ne yüklendi"yi değil.

### 15.5 Yüklendikten sonra

- Bu dokümanın başındaki **sürüm satırını** güncelle (`+N (yüklenmedi)` →
  yüklendi / hangi kanalda).
- **Test ve yayınlama → Kapalı test → Testerlar** panosunda 12/14 sayacının
  bozulmadığını doğrula.
- Kendi cihazına Play'den güncellemeyi al ve Adım 10 duman testinin **dokunulan
  alanlarını** tekrarla (tümünü değil).
- Güncelleme mevcut kurulumun üzerine iner: en az bir cihazda **veri yerinde mi**
  diye bak — temiz kurulum bu riski göstermez.
