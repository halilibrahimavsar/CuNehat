# CuNehat — Monetizasyon Kararı

> Felsefe: **İnsanlara yararlı olmak, soymak değil.** Bu doküman karanlık desen
> içermeyen, kullanıcıdan hiçbir şey esirgemeyen bir modeli tarif eder.
> Kaynak koddan ve gerçekçi sayılardan doğrulanmış gerçeklere dayanır.

**Tarih:** 2026-08-07 (2026-07-25 tarihli öneri revize edildi) · **Durum:** KARAR ·
**Sürüm:** v1.0.0 yayın öncesi

---

## 0. Karar — tek paragraf

**v1.0 tamamen ücretsiz çıkar. Hiçbir mevcut özellik kilitlenmez.** Tek
monetizasyon, isteğe bağlı bir **bağış kutusudur** ("çay/kahve ısmarla"):
ayarların içinde durur, hiçbir işlevi açmaz, kimseyi rahatsız etmez. **Pro
katmanı ertelendi** — gelecekse bugünkü özelliklerden değil, *yarın yazılacak
yeni* özelliklerden kurulur. Reklam yok, abonelik yok, ücretsiz deneme tuzağı yok.

**Bağış kutusu kodlanır; açılması TEK bir cevaba bağlı.** SGK tarafında sorun yok
(esnaf kurye faaliyetinden zaten aktif mükellefiyet + ödenen BAĞ-KUR var; ikinci
faaliyet ikinci prim doğurmaz). Ama para almak, mevcut kayda **uygulama geliştirme
faaliyet kodu eklemeyi zorunlu kılıyor** — bu kaçınılabilir bir adım değil, mekanizmanın
kendisi. **Müşavir "kurye rejimine etkisi yok" derse bağış kutusu v1.0'da açık çıkar;
demezse hiç eklenmez.** Yılda birkaç bin lira için çalışan bir vergi statüsü riske
atılmaz. → §6

---

## 1. Mevcut durum (koddan doğrulandı)

- `pubspec.yaml`'da reklam / satın alma / abonelik paketi **yok**.
- Koddaki "premium" kelimesi yalnızca **UI stil yorumlarında** geçiyor.
- Paywall, "pro", "unlock", abonelik akışı — hiçbiri yok.
- **iOS hiç yapılandırılmamış** (`ios/` klasöründe bundle id hâlâ
  `com.example.cunehat`). App Store bu planın kapsamı dışında; yılda 99 USD
  geliştirici ücretiyle *gerçek* bir yinelenen masraf yaratır.

Proje ölçeği: 2023-03'ten bu yana 540 commit, 346 Dart dosyası. Bu, 3,5 yıllık
kişisel emek demek — aşağıdaki maliyet analizinin merkezinde bu duruyor.

---

## 2. Maliyet yapısı — DÜZELTİLMİŞ

> ⚠️ Bu bölüm özgün dokümanın en büyük hatasını düzeltiyor. Eski metin
> "sunucu masrafım yok → süregelen maliyetim yok → abonelik etik değil"
> diyordu. İlk önerme doğru, sonuç yanlış.

### Doğru olan: kullanıcı başına *sunucu* maliyeti ≈ sıfır

| Servis | Kaynak | Kime maliyeti var? |
|---|---|---|
| Döviz + altın kuru | `finans.truncgil.com/today.json` (ücretsiz, anahtarsız) | Yok |
| Hisse fiyatları | `query1.finance.yahoo.com` (ücretsiz, belgelenmemiş uç) | Yok |
| Bulut yedek | Google Drive `appDataFolder` | **Kullanıcının kendi** Drive kotası |
| Giriş | `google_sign_in` | Yok |
| Veri, OCR, PDF/Excel, raporlar | Hive + ML Kit + saf Dart — hepsi **cihaz-içi** | Yok |

Yeni kullanıcı sana sunucu parası harcatmıyor. Bu gerçek.

### Yanlış olan: "o hâlde hiç yinelenen maliyetim yok"

Sunucu senin maliyetin değil. İki gerçek süregelen maliyetin var:

**1. Vergi/SGK yükü — bu projede ≈ SIFIR (özel durum).** Genel kural: Play'de para
almak Türkiye'de mükellefiyet + BAĞ-KUR doğurur ve bu, gelir 0 olsa da işleyen
aylık sabit bir giderdir. **Ama burada o gider zaten mevcut:** geliştiricinin esnaf
kurye faaliyetinden aktif mükellefiyeti ve ödenen 4/b primi var. BAĞ-KUR kişiye
bağlıdır, faaliyet sayısına değil — ikinci faaliyet ikinci prim doğurmaz. Muhasebeci
de zaten var. Dolayısıyla monetizasyonun **marjinal** sabit maliyeti yok. → §6

> Bu, "bu maliyet yok" demek değil; **"bu maliyet zaten ödeniyor ve uygulama onu
> artırmıyor"** demek. Kurye faaliyeti sona ererse bu kalem yeniden değerlendirilmeli.

**2. Senin zamanın.** Play her yıl `targetSdk` yükseltmeyi zorunlu kılıyor,
Flutter kırıcı değişiklikler getiriyor, bankalar ekstre formatını değiştiriyor.
"Ömür boyu" satmak, tek seferlik para karşılığında **sınırsız gelecek bakım
borcu** üstlenmektir.

### Bunun anlamı

Aboneliği reddetmek için kullanılan ahlaki gerekçe geçersiz — yazılımın
süregelen maliyeti sunucu değil **bakım emeğidir** ve bakım karşılığı abonelik
dürüst bir modeldir. Abonelik yine de yapılmayacak, ama **pazar gerekçesiyle**
(§3), ahlaki gerekçeyle değil. Kararı ahlak zeminine oturtmak, ileride manevra
alanını yok eder.

---

## 3. Neden ŞİMDİ Pro yok — sayılarla

Özgün doküman "zengin etmez" diyordu ama rakam vermiyordu. Rakam vermeyince
karar değişmiyor. İşte rakam:

| Adım | Varsayım | Sonuç |
|---|---|---|
| Birinci yıl indirme | Pazarlamasız, Türkçe niş, ilk uygulama (iyimser) | 1.000 – 3.000 |
| 30 gün sonra aktif | %10 – 20 tutunma | 150 – 600 kişi |
| Pro dönüşümü | Aktiflerin %2 – 3'ü | **5 – 18 satış** |
| Play kesintisi sonrası birim | ~200 TL (%15 indirimli komisyonla) | — |
| **Yıllık toplam gelir** | | **≈ 1.000 – 4.000 TL** |

> **Sonuç:** Bu rakam, monetizasyonun *sabit maliyeti* varsa zarardır; yoksa
> mütevazı ama temiz bir katkıdır. **Bu projede parasal sabit maliyet yok**
> (§6: BAĞ-KUR ve mükellefiyet zaten kurye faaliyetinden mevcut).
>
> **Ama bu rakamın asıl işlevi bir ölçü vermesi:** yılda 1.000–4.000 TL, mevcut
> ve çalışan bir vergi statüsünü riske atmaya değmez. §6'daki faaliyet kodu sorusu
> "belirsiz" çıkarsa doğru cevap, parayı almamaktır — uygulamayı ücretsiz
> yayınlamanın maliyeti sıfır ve bağış kutusu her zaman sonradan eklenebilir.

**Ama Pro'ya ilişkin karar bu hesaptan bağımsız.** Pro'yu ertelemenin gerekçesi
maliyet değil **ürün**: elinde tek bir kullanıcı verisi yokken ücretsiz/ücretli
sınırını tahminle çizmek ve bunu yayılmanın en kritik anında yapmak kötü bir
takas. Bağış kutusu bu riski taşımıyor — hiçbir şeyi kilitlemiyor.

Tersi de doğru: uygulama tutar ve 50 bin indirmeye giderse hesap tamamen
değişir. **Tam da bu yüzden Pro kararı şimdi verilmemeli.** Ertelemesi bedava,
yanlış vermesi pahalı. Bu bir opsiyon; harcama.

---

## 4. Sıralama kuralı: verip geri alma

Ekstre içe aktarma, OCR ve otomatik yedek **zaten var ve çalışıyor.** v1.0 bunlar
ücretsizken çıkar da sonraki bir sürüm paraya çevirirse, kullanıcıdan elindeki
bir şey alınmış olur. Bu, mağaza yorumlarında en sert cezalandırılan hamledir.

Aynı özellik hiç verilmemiş olsaydı kimse fark etmezdi bile.

> **Kural: vermeyip satmak normal; verip geri almak ihanet.**
>
> v1.0'da ücretsiz çıkan hiçbir şey bir daha kilitlenmez. Sonsuza kadar.

Bu yüzden §4'teki eski "özellik → katman" tablosu iptal edildi. **v1.0'da tüm
özellikler 🟢 ücretsizdir** — istisnasız. İleride Pro gelirse kuralları §7'de.

---

## 5. Bağış kutusu — tek monetizasyon

### İlke

Bağış **hiçbir işlevi açmaz.** Ödeyen ile ödemeyen aynı uygulamayı kullanır.
Karşılığı sadece teşekkürdür. Bu, satış değil; isteyen için bir kapı.

### Nerede durur

- **Ayarlar → "Geliştiriciye destek ol"** — kalıcı yeri burası.
- **Hakkında** ekranında tek satır bahis.
- **Açılır pencere YOK. Hatırlatma YOK. Rozet/nokta bildirimi YOK.**
- Tek istisna (isteğe bağlı): ~60 gün aktif kullanımdan sonra **bir kez**
  gösterilen, kapatılınca **bir daha asla dönmeyen** nazik bir kart. Dürüstlüğün
  izin verdiği azami görünürlük budur; fazlası karanlık desendir.

### Ürünler

Üç kademe, **tüketilebilir (consumable)** ürün — böylece isteyen tekrar tekrar
verebilir:

| Ürün id | Etiket | Öneri tutar | Not |
|---|---|---|---|
| `cunehat_tip_tea` | Bir çay ısmarla | ~bir bardak çay fiyatı | Giriş kademesi |
| `cunehat_tip_coffee` | Bir kahve ısmarla | ~bir fincan kahve fiyatı | Varsayılan vurgulanan |
| `cunehat_tip_generous` | Cömert destek | ~bir öğün yemek fiyatı | Üst kademe |

Tutarları **Play Console'un bölgesel fiyatlandırmasıyla** ve gerçekten o anki
çay/kahve fiyatına göre belirle; enflasyon nedeniyle **yılda bir gözden geçir.**
Play'in ülke bazlı asgari fiyat sınırını Console'dan teyit et.

### Karşılığında verilecek şey

- Anlık, samimi bir teşekkür ekranı.
- **Hakkında → "Teşekkürler"** listesinde isteğe bağlı takma ad (kullanıcı
  yazmak isterse; zorunlu değil, kişisel veri toplama).
- Ayarlarda küçük bir "destekçi" rozeti — salt kozmetik.
- **Fonksiyonel hiçbir şey yok.** Bilerek.

### Play Points / Play bakiyesi

Kullanıcı Play bakiyesini (Play Points'ten dönüştürdüğü kredi, hediye kartı,
iade bakiyesi) bu ürünlere harcayabilir. **Senin tarafında ekstra iş yok** —
normal satış olarak görünür, ödemen normal yapılır.

> Bu, bağışı **Play Billing üzerinden** yapmanın en güçlü gerekçesi: dışarıya
> bir "Buy Me a Coffee" linki koyarsan o bakiye havuzuna hiç erişemezsin.
> Türkiye'de kart bilgisi girme isteksizliği düşünülünce, insanların zaten
> cebinde duran ve başka türlü harcamayacağı parayı almak ciddi fark yaratır.

Ayrıca Play Billing dışına çıkmak, dijital ürünler için Play ödeme politikasıyla
sorun yaratabilir (bağış istisnalarının kapsamı geliştiriciye göre değişir ve
belirsizdir). Risk almaya değmez.

> ⚠️ **Dışarıdaki link vergi sorununu ÇÖZMEZ.** IBAN'a, Papara'ya veya
> Ko-fi'ye gelen para da gelirdir. §6'daki kapı her hâlükârda geçerli.

---

## 6. Vergi / SGK — engel yok

> ✅ Bu bölüm 2026-08-07'de baştan yazıldı. Önceki hâli "şirket kurmak zorundasın,
> sabit maliyeti geliri aşar" diyordu; **iki kez yanlıştı.** (1) Türkiye'de
> bireysel uygulama geliştiricisi için özel bir istisna var (GVK Mük. 20/B).
> (2) Bu projede zaten aktif bir esnaf mükellefiyeti ve ödenen BAĞ-KUR var, yani
> "kurulacak" bir maliyet de yok.

### GVK Mükerrer 20/B — uygulama geliştirici kazanç istisnası

Mobil cihazlar için uygulama geliştirenlerin **elektronik uygulama paylaşım ve
satış platformları** (Google Play, App Store) üzerinden elde ettiği kazanç gelir
vergisinden istisnadır. Şirket, defter, fatura, KDV — hiçbiri yok.

**Nasıl işliyor:**

1. İkametgâhının bağlı olduğu **vergi dairesine dilekçeyle** başvur →
   *"193 Sayılı Kanunun Mükerrer 20/B Maddesi Uygulamasına İlişkin İstisna Belgesi"*
2. **Türkiye'de kurulu bir bankada bu faaliyete özel hesap** aç, belgeyi bankaya ver.
3. Google Play ödemeleri **yalnızca** bu hesaba gelsin.
4. Banka, hesaba giren brüt tutardan **%15 gelir vergisi stopajı** keser.
   **Bu nihai vergidir.**
5. **Yıllık beyanname yok · defter tutma yok · belge düzenleme yok · KDV yok**
   (KDVK m.17/4-a).
6. **2026 sınırı: 5.300.000 TL** (GVK 103'ün 4. gelir dilimi). Aşılırsa istisna
   tamamen düşer ve kazancın *tamamı* beyan edilir. Bu ölçekte konu değil, ama
   sınır her yıl güncelleniyor — takip et.

**Eline geçen gerçek tutar:**

| Adım | Kesinti | Kalan (100 TL üzerinden) |
|---|---|---|
| Kullanıcı öder | — | 100,00 TL |
| Google Play komisyonu | %15 (indirimli program) | 85,00 TL |
| Banka stopajı | %15 | **72,25 TL** |

Yani brütün **~%72'si** sende kalıyor. Abonelik/şirket kurgusuyla kıyaslandığında
bu son derece iyi.

### ✅ BAĞ-KUR: bu projede engel değil — zaten ödeniyor

Geliştiricinin **esnaf kurye modelinde aktif bir mükellefiyeti ve ödenen 4/b primi
var.** BAĞ-KUR sigortalılığı **kişiye** bağlıdır, faaliyet sayısına değil: ikinci
bir ticari faaliyet ikinci bir prim doğurmaz. Uygulama geliri bu kalemi
**artırmıyor** — yani monetizasyonun marjinal sabit maliyeti sıfır.

Muhasebeci de zaten var; ek maliyet, uygulama gelirinin defterde ayrı izlenmesinden
ibaret.

> Not: Genç Girişimci BAĞ-KUR teşviki **2026-01-01 itibarıyla kaldırıldı.** Eski
> planlarda kaçış yolu olarak geçiyordu; artık yok. Burada zaten gerekmiyor.

### ⚠️ Düzeltme: "şirket gerekmiyor" ≠ "kayıt gerekmiyor"

Yaygın bir yanlış anlama var, netleştirelim (kaynak: **318 Seri No'lu GVGT**,
tam metin okundu):

- ✅ **Şirket (tüzel kişi) gerekmiyor.** İstisna yalnızca **gerçek kişilere**
  tanınmış; kurumlar vergisi mükellefleri yararlanamıyor (Madde 4/1).
- ❌ **Ama mükellefiyet her hâlükârda gerekiyor.** Tebliğ Madde 6/2 bu kazançları
  açıkça *"ticari kazanç kapsamında vergilendirilmekte"* diye tanımlıyor. Hiç
  kaydı olmayan biri için bile belge, ancak **"mükellefiyet tesisinin ardından"**
  veriliyor (Madde 4/4-b, Örnek 3).

**Yani "kaydımı hiç açtırmadan belge alayım" diye bir yol yok.** Ayrıca tek bir
gerçek kişi olarak **tek bir mükellefiyet kaydın** var — kurye kaydından ayrı,
paralel bir kayıt açman mümkün değil.

### Faaliyet kodu eklemek fazladan adım değil — belgenin ÖN KOŞULU

Tebliğin **Örnek 2**'si birebir bu senaryo (mevcut ticari mükellefiyet + istisna
faaliyeti): konfeksiyon perakendecisi bir mükellef istisna belgesi için başvuruyor.
Tebliğin cevabı:

> İstisna kapsamına giren faaliyetlerden **ek faaliyette bulunacağını bildirmesi
> halinde** belge verilebilecek; **ek faaliyetinin bulunmaması durumunda** ise hali
> hazırdaki kayıtlı faaliyeti istisna kapsamına uygun olmadığı için
> **"istisna belgesi verilemeyecektir."**

Yani faaliyet kodu ekleme, kaçınılabilecek bir yan etki değil; **eklemezsen belge
yok, belge yoksa istisna yok.** Bu, "mantıksız bir alt faaliyet" değil, mekanizmanın
kendisi.

### Eklemenin gerçek bedeli — ve ne kadar küçük olduğu

Tebliğ Madde 6/4, başka faaliyeti olanlar için şunları söylüyor:

| Yükümlülük | Sende değişen |
|---|---|
| Defter tasdiki + defter tutma + belge düzenleme **devam eder** | **Yok** — kurye nedeniyle zaten yapıyorsun |
| İstisna kapsamındaki/dışındaki hasılat, maliyet, gider **ayrı izlenmeli** ve birbiriyle ilişkilendirilmemeli | Müşavir için küçük ek iş |
| **Müşterek genel giderler** hasılat oranına göre dağıtılır; istisnaya düşen pay, diğer faaliyetin matrahında **gider yazılamaz** | Aşağıda ölçüldü |

**Son maddeyi sayısallaştıralım.** Uygulama geliri ~2.000 TL, kurye geliri ~500.000 TL
olsun → oran **%0,4**. Ortak giderlerinin (telefon, internet, müşavir ücreti) yalnızca
%0,4'ünü gider yazamazsın: **birkaç on lira.** İhmal edilebilir. Oran, uygulama geliri
küçük kaldıkça küçük kalıyor — yani risk kendiliğinden sınırlı.

### 🔴 Tebliğin CEVAPLAMADIĞI yer: basit usul

**318 no'lu tebliğ "basit usul" ifadesini hiç geçirmiyor** (425 satırlık tam metinde
sıfır eşleşme). Yani basit usul ile 20/B'nin etkileşimi **düzenlenmemiş.** Esnaf kurye
kaydı tipik olarak basit usul ya da gerçek usul olduğuna göre, senin için asıl
belirsizlik burada:

- 🟢 **GVK 51** (basit usulün geçerli olmadığı işler) listesinde sarraflık,
  ilan-reklam, inşaat taahhüdü, gayrimenkul/taşıt alım-satımı, aracılık gibi işler
  var — **yazılım/uygulama geliştirme bu listede yok.** Yani doğrudan "anında gerçek
  usule geçersin" tehlikesi görünmüyor.
- 🟡 Ama bu **tebliğde yazmadığı için** müşavir teyidi şart.
- 🟡 Ayrıca **8/9/2025 tarihli 10380 sayılı Cumhurbaşkanı Kararı** ile büyükşehirlerde
  nüfusu 30 binden fazla ilçelerde hizmet verenler zaten gerçek usule alındı —
  **rejimin bu yıl kendiliğinden değişmiş olabilir.** Önce mevcut durumunu öğren.

### Alternatif: 20/B'yi hiç kullanmamak

Zorunlu değil. Uygulama gelirini **normal ticari kazanç** olarak defterine yazabilirsin:

| | 20/B yolu | Normal yol |
|---|---|---|
| Faaliyet kodu | Gerekir | Gerekir (gelir bir yere yazılacak) |
| Vergi | %15 banka stopajı, **nihai** | Normal gelir vergisi dilimleri |
| KDV | **İstisna** (KDVK 17/4-a) | Soru işareti doğar |
| Ek bürokrasi | İstisna belgesi + özel hesap + ayrı izleme | Yok |

Bu tutarlarda iki yol arasındaki **vergi farkı birkaç yüz lira.** 20/B'nin asıl
avantajı vergi değil, **KDV'yi net biçimde kapatması.** Karar müşavirinin.

### Dürüst çerçeve: kazanç, kurulan mekanizmaya değer mi?

Bütün bu düzenek (faaliyet kodu + belge + ayrı hesap + ayrı defter izlemesi +
müşterek gider dağıtımı), §3'e göre **yılda 1.000–4.000 TL** toplamak için kuruluyor.

> **Karar kuralı:** Müşavirin cevabı *"kurye rejimine etkisi yok"* şeklinde net
> değilse, **bağış kutusunu hiç ekleme.** Uygulamayı ücretsiz yayınlamanın maliyeti
> sıfır ve bağış kutusu v1.1'de, v1.5'te, istediğin an eklenebilir. Birkaç bin lira
> için mevcut ve çalışan bir vergi statüsünü riske atmak kötü takas.

### Müşavirine sorulacak 4 şey

1. **Kurye kaydım şu an hangi usulde?** (Basit usul mü, gerçek usul mü — 2025 sonundaki
   Cumhurbaşkanı Kararı beni etkiledi mi?)
2. Uygulama geliştirme faaliyet kodu eklemek bu rejimi **bozar mı?**
   *Bu, kararı belirleyen soru.*
3. 20/B istisnası mı yoksa normal ticari kazanç mı benim için daha mantıklı?
   (Beklenen gelir yılda birkaç bin TL.)
4. Uygulama içi **"bağış" adıyla** satılan ürünün geliri istisna kapsamında sayılır mı?
   (Google tarafında normal *uygulama satış geliri* olarak yatıyor.)

> Ve her hâlükârda: istisna yoluna gidilecekse **belge yayından ÖNCE alınmalı**;
> belge öncesi elde edilen gelirin durumu ayrı bir tartışma, hiç doğmasın.

### Bunun bağış kutusu tasarımına etkisi

- 🔒 **Tüm hasılat tek hesaptan geçmek ZORUNDA.** Yani dışarıya Ko-fi / Buy Me a
  Coffee / IBAN / Papara linki koymak **istisnayı bozar.** Play Billing tek yol.
  (Bu, §5'teki Play Points argümanını ikinci kez ve daha sert biçimde destekliyor:
  dışarı çıkmanın artık vergisel bir cezası da var.)
- 💸 **KDV yok** → fiyatlandırma sade, kullanıcıya gösterilen tutar net.
- 📈 **5,3M TL sınırı** bu ölçekte hiç konu değil; ama uygulama tutarsa takip et.
- 📄 **Gizlilik politikası değişmez** — ödeme Google Play'de gerçekleşir, senin
  tarafına kart verisi hiç ulaşmaz.

---

## 7. İleride Pro gelirse — bağlayıcı kurallar

Pro *ertelendi*, iptal edilmedi. Geldiği gün şu üç kural bağlayıcıdır:

### Kural 1 — Sadece YENİ özellikler

v1.0'da ücretsiz çıkan hiçbir şey Pro'ya taşınamaz (§4). Pro yalnızca
**henüz yazılmamış** şeylerden kurulur. Kimse elindekini kaybetmez.

### Kural 2 — Sadece CİHAZDA çalışan özellikler "ömür boyu" satılabilir

Canlı fiyatlar tek bir küçük Türk sitesinden (`truncgil`) ve Yahoo'nun
**belgelenmemiş** bir ucundan geliyor. İkisi de sözleşme değil: yarın kapanabilir,
engelleyebilir, limit koyabilir. "Ömür boyu Pro'ya canlı fiyat dahil" deyip
kaynak kesilirse iade ve 1 yıldız gelir.

| Özellik türü | Satılabilir mi? |
|---|---|
| Cihazda çalışan (ekstre okuma, OCR, rapor, tema, kural motoru) | ✅ Ömür boyu sözü verilebilir |
| Üçüncü taraf ücretsiz uca bağlı (canlı fiyat, kur) | ❌ Ücretsiz + "elimizden geleni yaparız" |
| Kendi sunucunu gerektiren (senkron, paylaşımlı cüzdan) | ⚠️ Gerçek masraf doğar → **abonelik burada haklıdır** |

> Bu kural, özgün dokümanın #15'te açık bıraktığı "yatırım modülü Pro mu?"
> sorusunu gerekçesiyle kapatır: **canlı fiyat yenileme ücretsiz kalır.**

Ek not: PDF ekstre okuma `syncfusion_flutter_pdf`'in **topluluk lisansına**
dayanıyor — yani "küçük kaldığın sürece bedava". Bugün sorun değil (1M USD altı),
ama sahibi olmadığın bir izne yaslandığını unutma.

### Kural 3 — Pro "hayat kurtaran" değil, "zaman kazandıran" olur

Aday özellikler (hiçbiri henüz yok — **kullanıcı istemeden yazma**):

- **Otomatik kategori kuralları** — "açıklamasında X geçen işlem Y kategorisine".
- **Nakit akışı tahmini** — "bu gidişle ay sonunda bakiyen şu kadar olur".
- **Hedefler** — "6 ayda 50.000 TL biriktir", ilerleme takibi.
- **Ana ekran widget'ı** — hızlı gider girişi / bakiye.
- **Cihazlar arası senkron** — sunucu ister; tek dürüst abonelik adayı.

Hangisinin yazılacağını **kullanıcılar söyleyecek.** Bu liste bir tahmin, taahhüt
değil.

### Ebedî 🟢 ücretsiz çekirdek (asla kilitlenmez)

Cüzdanlar & çoklu para birimi · gelir/gider & kategoriler · bütçeler & uyarılar ·
borç/alacak · yinelenen işlemler & hatırlatıcılar · raporlar & grafikler ·
JSON/CSV dışa-içe aktarma · **güvenlik (biyometrik + PIN)** · tema & dil ·
bildirimler · banka ekstresi içe aktarma · fiş eki + OCR · Drive yedek ·
yatırım takibi & canlı fiyat.

> **Kırmızı çizgi:** kullanıcının kendi verisine erişimi ve güvenliği hiçbir
> koşulda ücretli olamaz. Dışa aktarma kilitlenirse bu bir veri fidyesidir.

---

## 8. Reklam neden YOK

Bu bölüm özgün dokümandan **değişmeden** geçerlidir; muhakemesi sağlamdır.

1. **Data Safety etiketi bir varlıktır; reklam onu yok eder.** Şu an Play
   formunda dürüstçe *"veri paylaşımı: Hayır · reklam SDK'sı: Yok"* diyebiliyorsun
   (`RELEASE_GUIDE.md` §7). Veri hasadıyla dolu bu kategoride bu **nadir ve
   pazarlanabilir bir farktır.** AdMob eklendiği an formda *"veriyi reklam
   ağlarıyla paylaşıyor"* demek zorunda kalırsın — en güçlü kozunu çöpe atarsın.
2. **TR'de reklam getirisi mertebe olarak komik.** eCPM'ler dünya ortalamasının
   çok altında; niş bir Türkçe finans uygulamasında on binlerce kullanıcıyla bile
   aylık kahve parası. Tüm mahremiyet farkını buna takas etmek en kötü değiş-tokuş.
3. **Reklam, fiyattan daha çok "soymak"tır.** Şeffaf fiyat dürüsttür — kişi ne
   verdiğini bilir. Reklam gizli bir dikkat + veri vergisidir.

> Opt-in ödüllü reklam da çözüm değil: SDK yine binary'de, Data Safety yine
> bozulur, eCPM yine düşük. **Finans + reklam ağı = kategorik olarak kötü takas.**

**"Çoğu insan ödemez" — doğru, ama sorun değil.** Reklamın tek işlevi ödemeyen
kullanıcıyı paraya çevirmektir; senin ödemeyen kullanıcın sunucu masrafı
çıkarmıyor. Doldurman gereken bir delik yok. Bedava kullanıcı yük değil,
**kitledir** — yorum, puan, ağızdan ağıza yayılım ve ileride gönüllü destek.

**Mağaza açıklamasının ilk satırı:**
*"Reklamsız · verini satmaz · veri cihazında kalır."*

---

## 9. Kaçınılacak karanlık desenler

- ❌ **Reklam yok** — finansal veri + reklam ağı, bu kategoride kırmızı çizgi.
- ❌ **Ücretsiz deneme → sessiz otomatik tahsilat** tuzağı yok.
- ❌ **Aylık abonelik yok** — birikerek soyma hissi veren kısım.
- ❌ **Veri fidyesi yok** — dışa aktarma/yedek asla kilitlenmez.
- ❌ **Sahte aciliyet / bitmeyen açılır pencere yok.**
- ❌ **Bağış hatırlatması yok** — kutu ayarlarda durur, peşine düşmez.
- ❌ **"Sonsuza kadar ücretsiz" sözü verilmez.** Cömert davran, ama kendinle
  sözleşme imzalama; sadece "ücretsiz" de. (§7'deki ebedî çekirdek listesi bu
  dokümanın iç taahhüdüdür, mağazada verilen bir vaat değil.)

---

## 10. Başarı ölçütü: para değil, TUTUNMA

v1.0'ın hedefi gelir değildir. Tek soru:

> **İnsanlar 30. günde uygulamayı hâlâ açıyor mu?**

Açmıyorsa hiçbir fiyatlandırma modeli işe yaramaz. Açıyorsa para kolaylaşır.

**Yeniden değerlendirme eşiği** (Play Console'un ücretsiz istatistikleriyle
ölçülür — ek analitik SDK'sı **eklenmez**, Data Safety temiz kalır):

| Ölçüt | Eşik |
|---|---|
| Aylık aktif kullanıcı | ≥ 1.000 |
| 30 günlük tutunma | ≥ %20 |
| Mağaza puanı | ≥ 4,3 |

**Üçü birden sağlanırsa:** şirketi kur, bağış kutusunu aç, Pro'yu §7 kurallarıyla
değerlendir.

**Sağlanmazsa:** uygulama ücretsiz kalır. Bu bir başarısızlık değil — 3,5 yıllık
emek zaten öğrenilenlerle karşılığını verdi ve ortada gerçekten kullanılan,
kimseyi sömürmeyen bir ürün var.

---

## 11. Teknik uygulama (bağış kutusu)

1. `in_app_purchase` (resmî Flutter eklentisi) ekle. RevenueCat gereksiz —
   tek platform, işlevsel kilit yok, sunucu doğrulaması gerekmiyor.
2. Üç **consumable** ürün: `cunehat_tip_tea`, `cunehat_tip_coffee`,
   `cunehat_tip_generous`. Tüketilebilir olması şart — insan ikinci kez vermek
   isteyebilir.
3. `kDonationEnabled` derleme bayrağı — **başlangıç değeri `false`.** `true`'ya
   çekilmesi §6'daki müşavir cevabına bağlı; cevap gelene kadar kod hazır bekler.
   Bayrak kalıcı olsun ki mağaza incelemesinde veya vergi tarafında sorun çıkarsa
   tek satırla kapanabilsin. `false` iken UI hiç görünmez ve `in_app_purchase`
   hiç başlatılmaz — yani **v1.0 bu bayrakla bugün yayınlanabilir.**
   **`true` ön koşulu:** istisna belgesi + özel banka hesabı hazır olmalı.
4. **Satın alma durumu yedeğe YAZILMAZ** (`DataSerializationService`). Bağış
   zaten bir kilidi açmıyor; yedeğe girmesine gerek yok.
5. Hata yolları: iptal / ağ hatası / bekleyen ödeme → sessizce ve nazikçe geç.
   Bağış ekranı asla kullanıcıyı hapsetmez, geri tuşu her zaman çalışır.
6. `docs/privacy-policy.html` güncellenir: ödeme sağlayıcısı = Google Play;
   **kart verisi uygulamaya hiç ulaşmaz.** Bağış rumuzu isteğe bağlıdır ve
   cihazda kalır.
7. Bağış ekranında sunucuya hiçbir şey gönderilmez → **Data Safety formu
   değişmez.**

---

## Ek — Özgün dokümandan (2026-07-25) neler değişti ve neden

| Değişen | Eski | Yeni | Gerekçe |
|---|---|---|---|
| Temel argüman | "Sunucu maliyetim yok = yinelenen maliyetim yok" | Asıl yinelenen maliyet **şirket + bakım emeği** | §2 — eski akıl yürütme eksikti |
| Aboneliğin reddi | Ahlaki gerekçe | **Pazar gerekçesi** | Ahlak zemini ileride manevrayı kilitler |
| Pro katmanı | v1.0 ile birlikte, mevcut 6 özellik kilitli | **Ertelendi**; sadece yeni özelliklerden kurulacak | §3 sayıları + §4 "geri alma" kuralı |
| Ekstre/OCR/oto-yedek | 🔵 Pro | 🟢 Ebedî ücretsiz | Zaten yayınlanıyor; geri alınamaz |
| Canlı fiyat (#15) | Karar açık bırakılmış | 🟢 Ücretsiz, "best-effort" | Üçüncü taraf uca ömür boyu söz verilemez |
| Bağış kutusu | "Hafif ek seçenek" | Tek monetizasyon; Play Billing üzerinden | İşlev açmaz, Play bakiyesiyle ödenebilir |
| **Vergi kapısı** | **"Şirket kurmak zorunlu"** | **Yanlıştı — GVK Mük. 20/B ile şirketsiz** | Bireysel istisna belgesi + özel hesap + %15 stopaj |
| **Engel kalemi** | Şirketin sabit maliyeti | BAĞ-KUR **engel değil** (kurye faaliyetinden zaten mevcut, ikinci prim doğmaz) | Parasal sabit maliyet yok |
| **Gerçek risk** | (görülmemişti) | **Faaliyet kodu eklemenin kurye vergi rejimine etkisi** | 318 tebliği "basit usul"den hiç bahsetmiyor → boşluk |
| Bağış kutusu takvimi | (yoktu) | Kod yazılır, **bayrak `false` başlar**; müşavir onayıyla açılır | Yılda 1–4 bin TL için çalışan statü riske atılmaz |
| Dış bağış linki | Politika riski | **Ayrıca istisnayı bozar** | Tüm hasılat tek hesaptan geçmek zorunda |
| Fiyat çıpası | YNAB/Monarch'ın yarısı | Çay/kahve fiyatı, yerel gerçeklik | ABD fiyatlandırma gücü TR için geçersiz |
| iOS / App Store | Planın parçası | **Kapsam dışı** | `ios/` hiç yapılandırılmamış + 99 USD/yıl |
| Başarı ölçütü | Gelir | **30 günlük tutunma** | Tutunma yoksa fiyat anlamsız |

---

## Özet

- **Şimdi:** Her şey ücretsiz, hiçbir özellik kilitli değil. **v1.0 bugün çıkabilir.**
- **Bağış kutusu:** Çay / kahve / cömert. Kod yazılır ama **bayrak kapalı başlar**;
  tek bir müşavir cevabıyla açılır. İşlev açmaz, peşe düşmez, Play bakiyesiyle ödenebilir.
- **Vergi tarafı:** Şirket gerekmiyor ama **mükellefiyet ve faaliyet kodu gerekiyor**
  (318 tebliği Örnek 2: ek faaliyet bildirilmezse belge verilmiyor). Sonrası GVK Mük.
  20/B: istisna belgesi + özel hesap → %15 banka stopajı nihai vergi, eline ~%72 geçer.
  BAĞ-KUR zaten ödeniyor, artmıyor.
- **Açılış koşulu:** Müşavir *"faaliyet kodu eklemek kurye rejimini bozmaz"* derse aç;
  net değilse **hiç ekleme** — yılda birkaç bin lira, çalışan bir statüyü riske atmaz.
- **Eşik tutarsa:** Pro değerlendirilir — sadece yeni, sadece cihazda çalışan,
  sadece zaman kazandıran özelliklerden.
- **Asla:** Reklam · aylık abonelik · veri fidyesi · verilmiş özelliği geri alma ·
  **Play dışı bağış linki** (hem politika hem vergi istisnası riski).

> Kırmızı çizgi tek cümle: **Kullanıcının kendi parası, verisi ve güvenliği
> hiçbir zaman satılık değildir; verilmiş hiçbir özellik geri alınmaz; para
> yalnızca gönüllü bir teşekkür olarak alınır.**
