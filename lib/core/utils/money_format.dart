/// Tek noktadan para metni. v1'de mevcut çıktıyla bayt-aynı
/// (binlik ayraç yok); tr_TR NumberFormat'a geçiş post-1.0 işi —
/// o zaman yalnız bu fonksiyon değişir.
String formatMoney(double amount, {int decimals = 2}) =>
    '${amount.toStringAsFixed(decimals)} ₺';
