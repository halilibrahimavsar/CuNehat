# ÇuHat — Proje Kuralları

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
  (5 Eyl 2026 itibarıyla: `WalletModel` typeId 0 → sıradaki alan **15**;
  `CategoryModel` typeId 15 → sıradaki alan **6**; sıradaki typeId **17**.)

### Yedek şeması — `DataSerializationService.schemaVersion`

- Mevcut sürüm **10**. Kapı artık sıkı eşitlik DEĞİL: `migrateBackup`
  (`lib/core/services/backup_migrations.dart`) desteklenen aralıktaki eski
  yedeği güncel biçime yükseltir, aralık dışındakini `BackupVersionMismatch`
  ile reddeder. Desteklenen en eski sürüm **9**
  (`oldestSupportedBackupVersion`).
- ⛔ **`schemaVersion` artıran, aynı commit'te vN → vN+1 adımını da yazar.**
  Adım eksikse o sürümden eski TÜM yedekler sessizce reddedilmeye başlar —
  "yedeğim vardı" diyen kullanıcı verisini kurtaramaz.
  `backup_migrations_test.dart`'taki "zincir bütünlüğü" testi boşluğu yakalar,
  ama testi kırmadan geçmenin yolu adımı yazmaktır.
- Adımlar ayrıştırmadan **önce** ham JSON map üzerinde çalışır
  (`_parseBackup`'ta sürüm kapısının yerinde), saftır (girdiyi değiştirmez) ve
  tam bir sürüm atlar. Modellerin `fromJson`'ları tek (güncel) biçimi tanımaya
  devam eder.
- Her adımın kendi testi olmalı; ayrıca o sürümün gerçek bir dosyasının uçtan
  uca geri yüklendiği bir test (`data_serialization_service_test.dart` →
  "eski sürüm yedeği (v9) migrasyonla geri yüklenir").

### Genel

- **"Veriyi sil, yeniden kur" artık bir çözüm değildir.** Ne kullanıcıya önerilir,
  ne kod içinde varsayılır, ne de bir hatanın kabul edilebilir sonucu sayılır.
- `fromJson`'da sıkı cast tercihi sürüyor (sessiz yanlış yorumlama, gürültülü
  hatadan kötüdür) — ama artık bunun karşılığı "eski veriyi reddet" değil,
  "eski veriyi migrasyonla yükselt".
