import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/amount_visibility.dart';

/// Gizle/göster anahtarına duyarlı para metni.
///
/// Metnin kendisi [formatMoney]'den gelir. Paketin `AmountDisplay` /
/// `SignedAmountDisplay` widget'ları BİLEREK kullanılmaz: içlerinde ikinci
/// bir biçimleyici (`formatGroupedAmount`, sabit Türkçe ayraç) taşıyorlar ve
/// uygulamadaki tek para noktasını es geçiyorlardı. Buradan yalnız
/// görünürlük sarmalayıcısı ([AmountVisibilityObfuscator]) ödünç alınır.
///
/// Sembol yerine para birimi KODU alınır ('TRY'), böylece çağıran taraf
/// sembol çözmez — bu da [formatMoney]'nin işi.
class MoneyText extends StatelessWidget {
  final double amount;
  final String currency;
  final TextStyle? style;
  final AmountObscureMode obscureMode;
  final AlignmentGeometry alignment;
  final Curve animationCurve;

  const MoneyText({
    super.key,
    required this.amount,
    required this.currency,
    this.style,
    this.obscureMode = AmountObscureMode.replace,
    this.alignment = Alignment.centerLeft,
    this.animationCurve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return _ObscuredMoney(
      text: formatMoney(amount, currency: currency),
      hiddenText: hiddenMoneyText(currency),
      style: style,
      obscureMode: obscureMode,
      alignment: alignment,
      animationCurve: animationCurve,
    );
  }
}

/// [MoneyText]'in işaretli hâli: tutarın kendi işaretine değil, kaydın
/// gider/gelir oluşuna göre başa `-`/`+` yazar.
class SignedMoneyText extends StatelessWidget {
  final double amount;
  final bool isExpense;
  final String currency;
  final TextStyle? style;
  final AmountObscureMode obscureMode;
  final AlignmentGeometry alignment;
  final Curve animationCurve;

  const SignedMoneyText({
    super.key,
    required this.amount,
    required this.isExpense,
    required this.currency,
    this.style,
    this.obscureMode = AmountObscureMode.replace,
    this.alignment = Alignment.centerLeft,
    this.animationCurve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    final sign = isExpense ? '-' : '+';
    return _ObscuredMoney(
      text: '$sign${formatMoney(amount.abs(), currency: currency)}',
      hiddenText: '$sign${hiddenMoneyText(currency)}',
      style: style,
      obscureMode: obscureMode,
      alignment: alignment,
      animationCurve: animationCurve,
    );
  }
}

/// Tutarlar gizliyken yazılan metin; sembol korunur ki satır genişliği
/// ve birim bilgisi kaybolmasın.
String hiddenMoneyText(String currency) => '**** ${currencySymbol(currency)}';

class _ObscuredMoney extends StatelessWidget {
  final String text;
  final String hiddenText;
  final TextStyle? style;
  final AmountObscureMode obscureMode;
  final AlignmentGeometry alignment;
  final Curve animationCurve;

  const _ObscuredMoney({
    required this.text,
    required this.hiddenText,
    required this.style,
    required this.obscureMode,
    required this.alignment,
    required this.animationCurve,
  });

  @override
  Widget build(BuildContext context) {
    return AmountVisibilityObfuscator(
      obscureMode: obscureMode,
      alignment: alignment,
      animationCurve: animationCurve,
      hiddenChild: Text(hiddenText, style: style),
      child: Text(text, style: style),
    );
  }
}
