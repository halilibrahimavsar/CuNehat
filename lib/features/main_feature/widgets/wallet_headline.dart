import 'package:cunehat/core/shared/widgets/amount_eye_button.dart';
import 'package:cunehat/core/shared/widgets/animated_money_text.dart';
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
    this.badgeIcon = Icons.wallet,
    this.pageCount = 1,
    this.pageIndex = 0,
    this.amountIdentity,
  });

  /// [amount]'ın neye ait olduğu (cüzdan + bölüm). Verilirse tutar, AYNI
  /// şeyin değeri değiştiğinde sayarak gider (bkz. [AnimatedMoneyText]);
  /// verilmezse doğrudan yazılır.
  final Object? amountIdentity;

  /// Üst çubuk karuselindeki konum: kaç cüzdan var, bu kaçıncısı. Noktalar
  /// rozetin İÇİNE çizilir — ayrı bir satır yığını 70dp'nin dışına iterdi
  /// (bkz. baştaki tuzak). Tek cüzdanda nokta yoktur.
  final int pageCount;
  final int pageIndex;

  /// Bundan fazla cüzdanda noktalar rozeti doldurur; "3/9" yazılır.
  static const int _maxDots = 6;

  /// Rozetin ikonu; kredi kartı bağlamında kart ikonu.
  final IconData badgeIcon;

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
                _buildMoneyRow(),
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
          Icon(badgeIcon,
              size: 14, color: AppColors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              badgeLabel,
              // Cümle düzeni: harf aralığı büyük harf içindi (1,0); karışık
              // harfte kelimeyi dağıtıyor.
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (pageCount > 1) ...[
            const SizedBox(width: 8),
            _buildPager(),
          ],
        ],
      ),
    );
  }

  Widget _buildPager() {
    if (pageCount > _maxDots) {
      return Text(
        '${pageIndex + 1}/$pageCount',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.white.withValues(alpha: 0.8),
        ),
      );
    }
    return Row(
      key: const ValueKey('wallet-headline-dots'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < pageCount; i++)
          Container(
            width: i == pageIndex ? 6 : 4,
            height: i == pageIndex ? 6 : 4,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  AppColors.white.withValues(alpha: i == pageIndex ? 1.0 : 0.4),
            ),
          ),
      ],
    );
  }

  /// Tutar + hemen yanında göz düğmesi.
  ///
  /// Satır YÜKSEKLİĞİ değişmez (düğme 36dp, tutar satırı ~43dp): 70dp
  /// tuzağına yeni bir satır eklenmiyor. Tutar dar alanda SARMAZ, küçülür —
  /// sarsaydı yığın bir satır uzar ve bütün başlık küçülürdü.
  Widget _buildMoneyRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _buildMoneyText(),
          ),
        ),
        const SizedBox(width: 2),
        const AmountEyeButton(),
      ],
    );
  }

  static const TextStyle _moneyStyle = TextStyle(
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
  );

  Widget _buildMoneyText() {
    final identity = amountIdentity;
    if (identity == null) {
      return MoneyText(
        amount: amount,
        currency: currency,
        animationCurve: Curves.decelerate,
        obscureMode: AmountObscureMode.blur,
        alignment: Alignment.center,
        style: _moneyStyle,
      );
    }
    // Kayıt yazılınca bakiye yeni değerine sayarak gider.
    return AnimatedMoneyText(
      amount: amount,
      currency: currency,
      identity: identity,
      animationCurve: Curves.decelerate,
      obscureMode: AmountObscureMode.blur,
      alignment: Alignment.center,
      style: _moneyStyle,
    );
  }
}
