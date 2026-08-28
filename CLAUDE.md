# ÇuNehat — Proje Kuralları

## Veri uyumluluğu politikası (kapalı test YAYINDA)

**28 Ağustos 2026'dan beri gerçek kullanıcı var.** Play kapalı testinde 13 tester
uygulamayı kendi verisiyle kullanıyor. Üstelik production erişimi 14 gün boyunca
**kesintisiz 12 opted-in tester** şartına bağlı: verisi uçan bir testerın
uygulamayı silmesi yalnız o kişiyi değil, yayın takvimini de haftalarca geri atar.

Bu yüzden yayın öncesi politika — *"veri şeması değişince eski kurulumların
verisi geçersiz sayılır; çözüm veri silme/yeniden kurulumdur, migrasyon değil"* —
**EMEKLİYE AYRILDI.** Yerine aşağıdaki kurallar geçerlidir.

### Hive — cihazdaki yerel veri

- `HiveField` indeksleri **asla** yeniden numaralandırılmaz, takas edilmez veya
  geri dönüştürülmez. Bir alan silinirse indeksi **yakılır**, yeniden kullanılmaz.
- Yeni alan eklenirken eski kayıtlarda o alan **yoktur**: alan ya nullable olmalı
  ya da okuma tarafında güvenli bir varsayılana düşmeli. "Eski kayıt null olabilir"
  dalı artık yasak değil, **zorunlu**.
- Var olan bir alanın **tipi değiştirilmez** (int→String, enum sırasının kayması
  dahil — enum değerleri yalnız **sona** eklenir).
- `typeId` silinmez, adapter kaydı kaldırılmaz.
- Sıradaki serbest numaralar için ilgili hafıza notlarına bak; tahmin etme.

### Yedek şeması — `DataSerializationService.schemaVersion`

- Şu an **sıkı eşitlik**: `data_serialization_service.dart:509`, farklı sürüm
  `BackupVersionMismatch` ile reddediliyor. Mevcut sürüm **9**.
- ⛔ **Migrasyon yolu yazılmadan `schemaVersion` ARTIRILMAZ.** Bugün testerların
  Drive'ında duran v9 yedekleri, sürüm artıp migrasyon yazılmazsa geri
  yüklenemez hale gelir — yani "yedeğim vardı" diyen kullanıcı verisini
  kurtaramaz.
- Migrasyon, ayrıştırmadan **önce** ham JSON map üzerinde çalışan bir vN → vN+1
  zinciri olmalı; `_parseBackup` sürüm kapısının hemen ardında. Modellerin
  `fromJson`'ları tek (güncel) biçimi tanımaya devam etsin.
- Bu iş bilerek ertelendi: bugün sahada yalnız v9 yedekleri var, yani
  yazılacak dönüşümün test edilebilir tek bir vakası bile yok. Şema değişikliği
  gerektiren ilk işle **birlikte** yazılacak, öncesinde değil.

### Genel

- **"Veriyi sil, yeniden kur" artık bir çözüm değildir.** Ne kullanıcıya önerilir,
  ne kod içinde varsayılır, ne de bir hatanın kabul edilebilir sonucu sayılır.
- `fromJson`'da sıkı cast tercihi sürüyor (sessiz yanlış yorumlama, gürültülü
  hatadan kötüdür) — ama artık bunun karşılığı "eski veriyi reddet" değil,
  "eski veriyi migrasyonla yükselt".
