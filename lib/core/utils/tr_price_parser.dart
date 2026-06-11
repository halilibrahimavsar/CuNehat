/// Uzak fiyat kaynakları (truncgil vb.) için toleranslı sayı ayrıştırma.
///
/// API alanı sürüme göre num (4250.5) ya da Türkçe biçimli string
/// ("4.318,24") gelebiliyor. Virgül varsa noktalar binlik sayılıp atılır;
/// virgül yoksa nokta ondalık kabul edilir. Ayrıştırılamazsa `null` —
/// çağıran taraf hatayı kendi bağlamında ele alır.
double? parseTrPrice(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is! String) return null;
  final s = value.trim();
  if (s.isEmpty) return null;
  if (s.contains(',')) {
    return double.tryParse(s.replaceAll('.', '').replaceAll(',', '.'));
  }
  return double.tryParse(s);
}
