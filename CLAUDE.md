# ÇuNehat — Proje Kuralları

## Geriye uyumluluk politikası (yayın öncesi)

Uygulama henüz yayınlanmadı ve kullanıcısı yok. **Geriye dönük uyumluluk kodu YAZMA:**

- Hive alanlarında `defaultValue`, "eski kayıt null olabilir" dalları, lazy migrasyon/backfill yok.
- `fromJson`'da sürüm-kaynaklı `?? varsayılan` fallback'leri yok; alanlar sıkı cast'lenir.
  (Gerçekten nullable alanlar — `notes`, `quantity` gibi — elbette nullable kalır.)
- Yedek şeması (`DataSerializationService.schemaVersion`) sürüm kapılıdır: eşleşmeyen
  sürüm reddedilir. Şema değişince sürümü artır; eski yedeği destekleme.
- Veri şeması değişince eski kurulumların verisi geçersiz sayılır; çözüm veri
  silme/yeniden kurulumdur, migrasyon değil.

Bu politika ilk mağaza yayınına kadar geçerlidir. Yayından sonra kaldırılacak
(o noktadan itibaren Hive alan ekleme kuralları ve yedek migrasyonları gerekir).
