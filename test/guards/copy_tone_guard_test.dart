import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Arayüz metinlerinin SESİ: hitap "sen", bölümün tek adı "Birikim", başlıklar
/// cümle düzeninde.
///
/// 13 Eki 2026'ya kadar metinlerin ~%35'i "siz", ~%65'i "sen" diyordu; aynı
/// bölüm kaydırıcıda "BİRİKİM", çekmecede "Yatırım", turda "Yatırım" idi;
/// başlıklar üç ayrı büyük harf düzeniyle yazılıyordu. Bu test yeni eklenen
/// metinlerin eski alışkanlığı geri getirmesini engeller.
///
/// Kapsam dışı: gizlilik politikası sayfasının gövdesi (resmî metin) ve
/// kategori tohum adları (kurulduğu anda kullanıcı verisine dönüşür).
void main() {
  final Map<String, String> tr = {
    for (final entry in (jsonDecode(
      File('lib/core/l10n/app_tr.arb').readAsStringSync(),
    ) as Map<String, dynamic>)
        .entries)
      if (!entry.key.startsWith('@') && entry.value is String)
        entry.key: entry.value as String,
  };

  /// Resmî metin: gizlilik politikası sayfası.
  bool isPolicy(String key) =>
      key.startsWith('privacy') &&
      !const {
        'privacyConsentTitle',
        'privacyConsentBody',
        'privacyPolicyTitle',
        'privacyDataHeader',
      }.contains(key);

  test('hitap "sen": resmî "siz" biçimi kullanılmaz', () {
    // Dart'ın `\b` ve `\w`'si yalnız ASCII bilir: "görünür" içinde "görün"ü
    // ayrı sözcük sanır (ü sınır sayılır). Sınırlar harf sınıfıyla elle
    // kurulur.
    const letter = 'a-zA-ZçğıöşüÇĞİÖŞÜâîû';
    const before = '(?<![$letter])';
    const after = '(?![$letter])';
    final formal = RegExp(
      // -ınız / -sınız ekleri (cüzdanınız, yapabilirsiniz, borcunuzun)
      '[$letter]*(ınız|iniz|unuz|ünüz|sınız|siniz|sunuz|sünüz)[$letter]*'
      // -seniz / -sanız koşul çoğulu (ederseniz, açmazsanız). 13 Eki 2026'da
      // yedi metin bu ve bir alttaki kalıpla bekçiden kaçmıştı.
      '|[$letter]+(sanız|seniz)$after'
      // ünlüyle biten gövdede iyelik: -nız/-niz (+hâl eki) — "bütçenizi".
      // "henüz", "deniz", "önizle" aynı harf dizisini taşır; dışarıda kalır.
      '|$before(?!henüz|deniz|önizle)[$letter]*[aeıioöuü](nız|niz|nuz|nüz)'
      '(ı|i|u|ü|a|e|dan|den|da|de|ın|in|la|le)?$after'
      // -leyin / -ıyın emir çoğulu (ekleyin, yenileyin, taşıyın)
      '|[$letter]+(leyin|layın|ıyın|iyin|uyun|üyün)$after'
      // sık geçen emir çoğulları
      '|$before(edin|yapın|verin|alın|bakın|görün|seçin|girin|yazın|silin|'
      'açın|kapatın|kullanın|dokunun|kaydırın|bekleyin|geçin|deneyin|'
      'bağlanın|lütfen)$after',
      caseSensitive: false,
      unicode: true,
    );
    final offenders = [
      for (final e in tr.entries)
        if (!isPolicy(e.key) && formal.hasMatch(e.value))
          '${e.key}: ${e.value}',
    ];
    expect(offenders, isEmpty,
        reason: '"sen" diye yaz: "girin" değil "gir", "cüzdanınız" değil '
            '"cüzdanın".');
  });

  test('bölümün adı "Birikim": "Yatırım" yalnız kategori adında geçer', () {
    final offenders = [
      for (final e in tr.entries)
        if (!isPolicy(e.key) &&
            !e.key.startsWith('catSeed') &&
            RegExp('yatırım', caseSensitive: false).hasMatch(e.value))
          '${e.key}: ${e.value}',
    ];
    expect(offenders, isEmpty,
        reason: 'Bölüm "Birikim", içindeki kayıt "varlık".');
  });

  test('BÜYÜK HARFLE yazılmış sözcük yok (kısaltmalar dışında)', () {
    // Bilinen kısaltmalar ve yabancı adlar.
    const allowed = {
      'PIN',
      'CSV',
      'PDF',
      'KKDF',
      'BSMV',
      'TRY',
      'USD',
      'EUR',
      'API',
      'OCR',
      'SDK',
      'AAPL',
      'THYAO',
      'IS',
      'ML',
      'KREDI',
      'KULLANDIRIM',
      'ORNEK',
      'BIST',
      'IBAN',
      'EFT',
      'FAST',
      'ATM',
      'POS',
      'TL',
      'XLSX',
      'XLS',
      'ID',
    };
    final caps = RegExp(r'[A-ZÇĞİÖŞÜ]{3,}', unicode: true);
    final offenders = <String>[];
    for (final e in tr.entries) {
      if (isPolicy(e.key)) continue;
      final words = caps
          .allMatches(e.value)
          .map((m) => m.group(0)!)
          .where((w) => !allowed.contains(w));
      if (words.isNotEmpty) offenders.add('${e.key}: ${words.join(', ')}');
    }
    expect(offenders, isEmpty,
        reason: 'Vurguyu büyük harfle değil cümleyle ver; başlığı cümle '
            'düzeninde yaz.');
  });

  test('kategori tohum adlarına DOKUNULMADI', () {
    // Tohum adı kurulduğu dilde donar ve ekstre tahmini onunla eşleşir;
    // "Yatırım" kategorisi bölüm adından bağımsızdır.
    expect(tr['catSeedInvestment'], 'Yatırım');
    expect(tr['catSeedInvestmentIncome'], 'Yatırım');
  });
}
