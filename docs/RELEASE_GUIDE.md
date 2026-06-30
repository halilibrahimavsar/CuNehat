# CuNehat — Google Play İlk Yayın Rehberi (Kullanıcı Aksiyonları)

Bu doküman, kodla halledilemeyen ve **senin yapman gereken** adımları sıralar.
Kod tarafındaki hazırlık (finansal doğruluk testleri, allowBackup, gizlilik
politikası + onam + veri silme) tamamlandı; aşağıdakiler hesap/konsol işleridir.

> Önkoşullar: Google Play Developer hesabı (tek seferlik $25), bir Google Cloud
> projesi, Android Studio / Flutter SDK kurulu.

---

## 1. Upload Keystore üret (KRİTİK — bir kez)

Yayın için release imzası şart. `android/app/build.gradle.kts` zaten
`android/key.properties` varsa onu kullanacak şekilde hazır — sadece keystore +
key.properties üret.

```bash
# Proje kökünde çalıştır. Parolaları GÜVENLİ bir yerde sakla (kaybedersen
# uygulamayı bir daha güncelleyemezsin).
keytool -genkey -v -keystore ~/cunehat-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Sonra `android/key.properties` oluştur (bu dosya `.gitignore`'da, commit edilmez):

```properties
storePassword=<keystore-parolan>
keyPassword=<key-parolan>
keyAlias=upload
storeFile=/home/garuda/cunehat-upload.jks
```

> Play App Signing'i etkin bırak (varsayılan): Google dağıtım anahtarını yönetir,
> sen yalnız upload anahtarını tutarsın. Upload anahtarını kaybedersen Play
> Console'dan sıfırlanabilir; ama yine de yedekle.

---

## 2. Gizlilik politikasını yayınla (KRİTİK)

`docs/privacy-policy.html` hazır (TR + EN). Herkese açık bir URL gerekiyor:

- **GitHub Pages (ücretsiz):** Repo Settings → Pages → Source: `main` / `docs`
  klasörü. URL: `https://<kullanıcı-adın>.github.io/<repo>/privacy-policy.html`
- İçindeki iletişim e-postasını (şu an `halirlnj@gmail.com`) teyit et/güncelle.
- Bu URL'i Play Console'da ve OAuth consent ekranında kullanacaksın.

---

## 3. Google Cloud — OAuth Consent Ekranı (Drive yedeği için)

Uygulama `drive.appdata` (hassas) kapsamı kullanıyor; consent ekranı kurulmalı.

1. Google Cloud Console → APIs & Services → **OAuth consent screen**.
2. User type: **External**. Uygulama adı, destek e-postası, geliştirici
   e-postası, **gizlilik politikası URL'i** (Adım 2).
3. Scopes: yalnız `.../auth/drive.appdata` ekle.
4. **Credentials → OAuth Client ID → Android**: paket adı
   `dev.halilibrahim.cunehat` + imza SHA-1'i ekle. SHA-1'i şöyle al:
   ```bash
   keytool -list -v -keystore ~/cunehat-upload.jks -alias upload
   ```
   > Play App Signing kullanıyorsan, Play Console → Setup → App signing'deki
   > **App signing key** SHA-1'ini de eklemen gerekir (yoksa yayınlanan sürümde
   > Google ile giriş çalışmaz).
5. `drive.appdata` "restricted" değil "sensitive" kapsamdır; küçük/kişisel
   kullanımda genelde ağır güvenlik denetimi gerekmez, ama "unverified app"
   uyarısını kaldırmak için doğrulama gönderebilirsin. Test aşamasında kendi
   hesabını **Test users**'a ekle.

---

## 4. Play Console — Data Safety Formu

Koddan çıkarılan doğru beyanlar:

| Alan | Beyan |
|------|-------|
| Toplanan veri | **E-posta adresi** (yalnız Drive yedeği açılırsa), **Finansal bilgi** (cihazda) |
| Veri paylaşımı | **Hayır** (üçüncü tarafla paylaşım yok) |
| İletimde şifreli | **Evet** (tüm trafik HTTPS) |
| Beklemede (at rest) şifreli | **Şu an: Hayır** — yerel Hive henüz şifresiz (Faz 2 ertelendi). Hive şifrelemesi eklenince **Evet** yap. |
| Kullanıcı veri silebilir mi | **Evet** (Ayarlar → Gizlilik & Veri → Tüm Veriyi Sil; Drive yedeği de silinebilir) |
| Analytics/Reklam/Crash SDK | **Yok** |

> Reklam/IAP eklenirse (ertelendi): `google_mobile_ads` Advertising ID toplar →
> Data Safety güncellenmeli; IAP için Play Billing zorunlu.

---

## 5. Play Console — Diğer Yayın Maddeleri

- **İçerik derecelendirme** anketi (kategori: Finance; reklam/şiddet/IAP yok → düşük derece).
- **Uygulama kategorisi:** Finance.
- **Store listing:** 512×512 ikon, 1024×500 feature graphic, en az 2–8 telefon
  ekran görüntüsü, kısa (≤80) + uzun açıklama, gizlilik politikası URL'i, destek e-postası.
- **Hedef kitle/yaş:** 13+ (çocuklara yönelik değil).
- **App access:** Drive yedeği opsiyonel olduğundan inceleyici tüm özellikleri
  giriş yapmadan görebilir; gerekirse not düş.

---

## 6. Release Build + Cihaz Duman Testi

```bash
flutter clean
flutter pub get
flutter analyze            # 0 sorun beklenir
flutter test               # tümü yeşil beklenir
flutter build appbundle --release   # → build/app/outputs/bundle/release/app-release.aab
```

AAB'yi **Internal testing** track'ine yükle, kendi cihazına kur ve doğrula:

- [ ] Açılış, biyometrik/PIN kilidi, tema/dil
- [ ] İlk açılışta **gizlilik onam** diyaloğu bir kez çıkıyor
- [ ] Ayarlar → Gizlilik Politikası ekranı açılıyor
- [ ] İşlem ekle/sil → bakiye doğru; raporlar doğru toplam
- [ ] **Drive yedekle → geri yükle** gidiş-dönüşü: veri kaybı/yanlış bakiye yok
- [ ] Ayarlar → Yedekleme → **Yedeği Sil** çalışıyor
- [ ] Ayarlar → Gizlilik & Veri → **Tüm Veriyi Sil** → onay → sıfır durum
- [ ] Google ile giriş ekranında **yalnız `drive.appdata`** izni görünüyor
- [ ] R8/obfuscation altında çökme yok (Hive/google_sign_in)

> R8 ile bir runtime çökmesi olursa `android/app/proguard-rules.pro`'ya ilgili
> `-keep` kuralını ekle ve yeniden derle.

---

## 7. Ertelenen İşler (sonraki tur)

- **Faz 2 — Yerel Hive AES-256 şifreleme** (senin onayınla ertelendi). Eklenince
  Data Safety'de "beklemede şifreli = Evet" yapılır. DI'ı **elle** düzenle
  (build_runner `injection.config.dart`'ı bozuyor).
- **Para kazanma** (reklam/paid/bağış) — karar bekliyor; ayrı ele alınacak.
