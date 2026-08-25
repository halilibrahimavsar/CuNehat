/// Türkçe-duyarlı BÜYÜK harfe çevirme — ekranda gösterilecek metin için.
///
/// `toUpperCase()` locale-bağımsızdır: 'i' → 'I' verir, 'İ' değil. Cüzdan adı
/// "Vadesiz Hesap" başlık rozetinde "VADESIZ HESAP" olarak çıkıyordu.
/// Diğer Türkçe harflerin (ş/ğ/ü/ö/ç) büyük karşılığı Unicode varsayılanıyla
/// zaten doğru; locale'e bağlı olan tek çift i/ı'dir, o yüzden yalnız o ikisi
/// elle katlanır.
///
/// Karşılaştırma/arama yönü için [foldTr] (`text_search.dart`) kullanılır;
/// ikisi aynı problemin iki yönüdür.
library;

/// [input]'u Türkçe kurallarıyla büyütür: i → İ, ı → I.
String upperTr(String input) =>
    input.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
