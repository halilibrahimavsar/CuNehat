import 'dart:math' as math;

import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:flutter/services.dart';

/// Tutar alanları için canlı binlik ayraç biçimlendirici.
///
/// Yazarken tam kısım noktayla gruplanır (1.234.567), ondalık ayracı
/// virgüldür. Klavyeden yazılan '.' ondalık niyeti sayılır ve ','ye çevrilir;
/// gruplama noktalarını yalnız formatter ekler. Bu yüzden alan metni her
/// zaman "nokta = gruplama, virgül = ondalık" biçimindedir ve yalnızca
/// [parseAmountInput]/[parseMoneyInput]/[validateAmountInput] ile
/// ayrıştırılmalıdır. Programatik `controller.text =` yazımları formatter'dan
/// GEÇMEZ; o değerler [formatAmountForInput] ile biçimlenmelidir.
class AmountInputFormatter extends TextInputFormatter {
  AmountInputFormatter({this.decimalDigits = 2, this.allowNegative = false});

  /// İzin verilen en çok ondalık hane; 0 → yalnız tam sayı (virgül yazılamaz).
  final int decimalDigits;

  /// Cüzdan bakiyesi gibi eksiye düşebilen alanlar için baştaki '-'e izin.
  final bool allowNegative;

  /// [kMaxAmount] (999.999.999) ile uyumlu tam-kısım hane sınırı.
  static const _maxIntDigits = 9;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (text.isEmpty) return newValue;

    var cursor = newValue.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) cursor = text.length;

    final lenDiff = text.length - oldValue.text.length;
    if (lenDiff == 1 && cursor > 0 && text[cursor - 1] == '.') {
      // Yazılan nokta = ondalık niyeti.
      text = text.replaceRange(cursor - 1, cursor, ',');
    } else if (lenDiff == -1 &&
        cursor < oldValue.text.length &&
        oldValue.text[cursor] == '.') {
      // Gruplama noktası silindi: nokta yeniden ekleneceği için silme boşa
      // giderdi; noktanın solundaki rakamı da sil.
      if (cursor > 0) {
        text = text.replaceRange(cursor - 1, cursor, '');
        cursor--;
      }
    } else if (lenDiff > 1) {
      // Yapıştırma: ayraçları bütün metin üzerinden yorumla.
      text = _normalizePasted(text);
      cursor = text.length;
    }

    // Ham forma indirger (işaret + rakamlar + tek virgül); imlecin ham
    // konumunu (rawCursor) aynı geçişte izler. Sınırları aşan rakamlar ve
    // fazladan ayraçlar sessizce düşer.
    final buf = StringBuffer();
    var rawCursor = 0;
    var negative = false;
    var hasComma = false;
    var intLen = 0;
    var decLen = 0;
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      var emitted = false;
      if (c == '-') {
        if (allowNegative && buf.isEmpty) {
          negative = true;
          buf.write(c);
          emitted = true;
        }
      } else if (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) {
        if (!hasComma) {
          if (intLen < _maxIntDigits) {
            intLen++;
            buf.write(c);
            emitted = true;
          }
        } else if (decLen < decimalDigits) {
          decLen++;
          buf.write(c);
          emitted = true;
        }
      } else if (c == ',' && !hasComma && decimalDigits > 0) {
        hasComma = true;
        buf.write(c);
        emitted = true;
      }
      if (emitted && i < cursor) rawCursor++;
    }
    final raw = buf.toString();
    if (raw.isEmpty || raw == '-') {
      return TextEditingValue(
        text: raw,
        selection: TextSelection.collapsed(offset: raw.length),
      );
    }

    final sign = negative ? '-' : '';
    final body = negative ? raw.substring(1) : raw;
    final commaIdx = body.indexOf(',');
    var intPart = commaIdx >= 0 ? body.substring(0, commaIdx) : body;
    final decPart = commaIdx >= 0 ? body.substring(commaIdx) : '';

    // Baş sıfırlar: "007" → "7"; tek "0" ve "0,5" korunur.
    final beforeStrip = intPart.length;
    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    rawCursor =
        math.max(sign.length, rawCursor - (beforeStrip - intPart.length));
    if (intPart.isEmpty && decPart.isNotEmpty) {
      // Virgülle başlandı ("," → "0,").
      intPart = '0';
      if (rawCursor > sign.length) rawCursor++;
    }

    final formatted = sign + groupThousands(intPart) + decPart;

    // Ham imleci biçimli metne taşı: gruplama noktaları sayılmaz.
    var offset = 0;
    if (rawCursor > 0) {
      offset = formatted.length;
      var seen = 0;
      for (var i = 0; i < formatted.length; i++) {
        if (formatted[i] != '.') seen++;
        if (seen == rawCursor) {
          offset = i + 1;
          break;
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  /// Panodan gelen metinde ayraç niyeti bilinemez; sezgisel çözüm:
  /// her iki ayraç varsa sondaki ondalıktır; yalnız nokta varsa tek nokta
  /// ondalık sayılır — ama "1.234" gibi üç haneli kuyruk (uygulamanın kendi
  /// biçiminden kopyalanmış olabilir) gruplama kabul edilir.
  String _normalizePasted(String text) {
    var t = text.trim();
    final lastDot = t.lastIndexOf('.');
    final lastComma = t.lastIndexOf(',');
    if (lastDot >= 0 && lastComma >= 0) {
      if (lastComma > lastDot) {
        t = t.replaceAll('.', ''); // 1.234,56
      } else {
        t = t.replaceAll(',', '').replaceAll('.', ','); // 1,234.56
      }
    } else if (lastDot >= 0) {
      final dotCount = '.'.allMatches(t).length;
      final tail = t.length - lastDot - 1;
      final head = t.substring(0, t.indexOf('.')).replaceFirst('-', '');
      final looksGrouped =
          dotCount > 1 || (tail == 3 && head.isNotEmpty && head != '0');
      t = looksGrouped ? t.replaceAll('.', '') : t.replaceAll('.', ',');
    }
    return t;
  }
}
