import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/amount_visibility/ibo_amount_display.dart';

/// Üst çubuğun başlık yığını: cüzdan rozeti + tutar + (varsa) TL karşılığı.
///
/// **TUZAK — bu yığın 70dp'lik çubuğa SIĞMIYOR.** Ölçüldü (Roboto, yazı
/// ölçeği 1.0): rozet 27,2 + boşluk 2 + tutar 43,2 (34px yazı, `titleLarge`
/// mirasıyla satır kutusu ×1,27) = 72,4dp; döviz cüzdanında karşılık satırı
/// (15,2) ile 87,6dp. `AppBar` başlığı SINIRSIZ yükseklikte ölçüp ortalıyor
/// (`_AppBarTitleBox`) ve `ClipRect` ile kesiyor — yani taşma hata vermeden
/// üstten ve alttan kırpılıyordu: TRY cüzdanda 2,4dp (rozetin üst kenarı),
/// döviz cüzdanında 17,6dp (rozetin üstü + karşılık satırının yarısı).
///
/// Çözüm çubuğu büyütmek DEĞİL (gövde zaten dar), yığını çubuğa sığdırmak:
/// kutu [maxHeight]'e sabitlenir, taşan içerik oransal küçültülür. Bu aynı
/// zamanda yazı boyutu ayarına da bağışıklık verir — `AppBar` başlığı 1,34'e
/// kadar ölçekliyor ve o noktada yığın 117dp'ye çıkıyor.
///
/// Genişlik BİLEREK dıştan sabitlenir: [FittedBox] çocuğunu kısıtsız ölçer,
/// yani sabitlenmezse uzun cüzdan adı rozeti ekran dışına kadar uzatır ve
/// üç nokta (ellipsis) hiç devreye girmez — bunun yerine bütün başlık
/// küçülürdü.
class WalletHeadline extends StatelessWidget {
  const WalletHeadline({
    super.key,
    required this.badgeLabel,
    required this.amount,
    required this.currency,
    this.secondaryLine,
    this.maxHeight = AppSizes.appBarHeight,
  });

  /// Rozetin yazısı: aktif cüzdanın adı (işlemler dışındaki durumlarda
  /// "AD • DEĞER ADI").
  final String badgeLabel;

  final double amount;

  /// [amount]'ın birimi — aktif cüzdanınki.
  final String currency;

  /// Tutarın altındaki ikincil satır (döviz cüzdanında "≈ TL karşılığı");
  /// yoksa satır hiç kurulmaz.
  final String? secondaryLine;

  /// Yığının sığacağı yükseklik; üst çubuğun `toolbarHeight`'i.
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: maxHeight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.hasBoundedWidth ? constraints.maxWidth : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBadge(),
                const SizedBox(height: 2),
                _buildMoneyText(),
                if (secondaryLine case final String line)
                  Text(
                    line,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wallet,
              size: 14, color: AppColors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              badgeLabel,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyText() {
    return MoneyText(
      amount: amount,
      currency: currency,
      animationCurve: Curves.decelerate,
      obscureMode: AmountObscureMode.blur,
      alignment: Alignment.center,
      style: const TextStyle(
        fontSize: 34,
        color: AppColors.white,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        shadows: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
    );
  }
}
