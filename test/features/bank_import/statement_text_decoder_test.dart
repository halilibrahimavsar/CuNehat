import 'dart:convert';

import 'package:cunehat/features/bank_import/data/statement_text_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeStatementBytes', () {
    test('UTF-8 aynen çözülür', () {
      expect(decodeStatementBytes(utf8.encode('Şube;Açıklama;Avşar')),
          'Şube;Açıklama;Avşar');
    });

    test('UTF-8 BOM atılır', () {
      final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode('Tarih;Tutar')];
      expect(decodeStatementBytes(bytes), 'Tarih;Tutar');
    });

    test('REGRESYON: windows-1254 Türkçe harfler doğru çözülür', () {
      // Gerçek Akbank CSV'sindeki baytlar. latin1 fallback'i bunları
      // Þube / Açýklama / Avþar'a çeviriyordu.
      const bytes = [
        0xDE, 0x75, 0x62, 0x65, // Şube
        0x3B,
        0x41, 0xE7, 0xFD, 0x6B, 0x6C, 0x61, 0x6D, 0x61, // Açıklama
        0x3B,
        0x41, 0x76, 0xFE, 0x61, 0x72, // Avşar
        0x3B,
        0xDD, 0x62, 0x72, 0x61, 0x68, 0x69, 0x6D, // İbrahim
        0x3B,
        0xD0, 0xF0, // Ğğ
      ];
      expect(decodeStatementBytes(bytes), 'Şube;Açıklama;Avşar;İbrahim;Ğğ');
    });

    test('cp1254 0x80–0x9F aralığı', () {
      expect(decodeStatementBytes([0x80, 0x93, 0x94]), '€“”');
    });

    test('ASCII baytlar her iki yolda da aynı', () {
      expect(decodeStatementBytes(ascii.encode('Tarih;Tutar;Bakiye')),
          'Tarih;Tutar;Bakiye');
    });

    test('UTF-16LE (Excel "Unicode Text" export)', () {
      const bytes = [0xFF, 0xFE, 0x54, 0x00, 0x61, 0x00, 0x72, 0x00];
      expect(decodeStatementBytes(bytes), 'Tar');
    });

    test('UTF-16BE', () {
      const bytes = [0xFE, 0xFF, 0x00, 0x54, 0x00, 0x61, 0x00, 0x72];
      expect(decodeStatementBytes(bytes), 'Tar');
    });

    test('boş girdi boş string', () {
      expect(decodeStatementBytes(const []), '');
    });
  });
}
