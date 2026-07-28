/// Takvim ayı ekleme: gün, hedef ayın son gününe kenetlenir.
/// Örn. 31 Oca + 1 ay → 28/29 Şub (30×gün yaklaşımının aksine doğru vade).
///
/// Tek adımlık hesaplar içindir (takvim gezinme, borç taksit planı). ARDIŞIK
/// ilerletmede kullanma: kenetlenmiş sonuçtan devam etmek ayın gününü kalıcı
/// olarak aşağı çeker (31 Oca → 28 Şub → 28 Mar → …). Zincirleme ilerletme
/// için [addMonthsAnchored] kullan.
DateTime addMonthsClamped(DateTime d, int months) =>
    addMonthsAnchored(d, months, d.day);

/// [d]'den [months] ay ileri/geri gider ve günü **[anchorDay]'e** oturtur
/// (hedef ayın son gününü aşmamak üzere kenetleyerek).
///
/// Kenetlemenin birikmesini önler: çapa saklandığı sürece 31 Oca → 28 Şub →
/// **31** Mar → 30 Nis → 31 May diye ilerler. [addMonthsClamped]'in aksine
/// sonuç, girdinin gününe değil çapaya bağlıdır; bu yüzden aynı çapadan
/// yapılan ardışık çağrılar sapma üretmez.
///
/// Saat/dakika/saniye [d]'den taşınır.
DateTime addMonthsAnchored(DateTime d, int months, int anchorDay) {
  final totalMonths = d.year * 12 + (d.month - 1) + months;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = anchorDay > lastDay ? lastDay : anchorDay;
  return DateTime(year, month, day, d.hour, d.minute, d.second);
}
