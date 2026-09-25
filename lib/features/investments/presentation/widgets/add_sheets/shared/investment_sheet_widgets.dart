import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/ledger_transaction_picker.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/shared/purchase_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Yatırım ekleme/düzenleme sheet'lerinin (hisse / altın / özel) ortak yapı
/// taşları. Üç sheet de aynı görsel iskeleti paylaşır; tek değişen, türe özgü
/// vurgu rengi (accent), ikincil renk, başlık ve metinlerdir. Bu yüzden bu
/// widget'lar accent'i parametre alır ve sunum kararlarını çağırana bırakır.
///
/// [accent] her zaman bir [MaterialColor]'dır (purple / amber / blue) çünkü
/// kaydet butonu ve canlı-fiyat butonu `.shade600` tonunu kullanır.

/// Tutacak (drag handle) + başlık satırı (ikon + başlık + kapat).
class InvestmentSheetHeader extends StatelessWidget {
  final MaterialColor accent;
  final IconData icon;
  final String title;
  final VoidCallback onClose;

  const InvestmentSheetHeader({
    super.key,
    required this.accent,
    required this.icon,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded,
                    color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Mevcut Değer" büyük giriş kartı. [valueColor] hem degrade bitişini hem de
/// büyük rakamın rengini verir (üç sheet'te de aynıdır).
class InvestmentAmountCard extends StatelessWidget {
  final MaterialColor accent;
  final Color valueColor;
  final TextEditingController controller;
  final VoidCallback onChanged;

  /// Kaydın cüzdanının para birimi. Aktif cüzdandan okumak yerine açıkça
  /// geçilir: `context.activeWalletCurrency` WalletBloc yoksa sessizce
  /// TRY'ye düşer ve alan yanlış sembolle etiketlenirdi.
  final String currency;

  const InvestmentAmountCard({
    super.key,
    required this.accent,
    required this.valueColor,
    required this.controller,
    required this.onChanged,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.15),
            valueColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.mevcutDeger,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [AmountInputFormatter()],
                  onChanged: (_) => onChanged(),
                  cursorColor: accent,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    height: 1.0,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: accent.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  currencySymbol(currency),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: accent.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bölüm başlığı (küçük, kalın etiket).
class InvestmentSectionLabel extends StatelessWidget {
  final String text;

  const InvestmentSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: cs.onSurfaceVariant,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// Dolgulu metin alanı; odaklanınca kenarlık [accent] rengine döner.
class InvestmentFilledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final MaterialColor accent;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback onChanged;

  /// Değer başka bir kaynaktan geliyor (ör. defterden seçilen ödeme satırı)
  /// ve elle değiştirilmemeli.
  final bool readOnly;

  const InvestmentFilledField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.accent,
    required this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: keyboardType == null
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      onChanged: (_) => onChanged(),
      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon,
            size: 20, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
        suffixIcon: readOnly
            ? Icon(Icons.lock_outline_rounded,
                size: 18, color: cs.onSurfaceVariant)
            : null,
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
      ),
    );
  }
}

/// Renk seçici (yatay sarmal daireler).
class InvestmentColorSelector extends StatelessWidget {
  final List<Color> options;
  final Color selected;
  final ValueChanged<Color> onSelected;

  const InvestmentColorSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((color) {
        final isSelected = selected == color;
        return GestureDetector(
          onTap: () => onSelected(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : Border.all(color: Colors.transparent, width: 3),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

/// Düzenleme modunda gösterilen "maliyeti değiştirirsen fark cüzdana yansır"
/// bilgi şeridi. Türden bağımsız; her sheet'te aynıdır.
class InvestmentCostEditWarning extends StatelessWidget {
  const InvestmentCostEditWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return InvestmentWarningBanner(
        context.l10n.maliyetiDegistirirsenizFarkCuzdana);
  }
}

/// Formda kaydetmeden ÖNCE görülmesi gereken uyarı şeridi (turuncu, info
/// ikonlu). Sessizce veri anlamı değiştiren seçimler bunun arkasında durmaz.
class InvestmentWarningBanner extends StatelessWidget {
  final String text;

  const InvestmentWarningBanner(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded,
                size: 16, color: Colors.orange),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bir alanın altında gösterilen küçük açıklama metni (info ikon + metin).
/// "Mevcut Değer" / "Toplam Maliyet" gibi alanların ne anlama geldiğini
/// kullanıcıya açıklamak için kullanılır.
class InvestmentHintCaption extends StatelessWidget {
  final String text;

  const InvestmentHintCaption(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.3,
                color: cs.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hata şeridi. Türden bağımsız.
/// Hata gösterildikten sonra "Kaydet" düğmesini yeniden görünür kılar.
///
/// **Neden gerekli.** [InvestmentErrorBanner] formun DİBİNDE, kaydet
/// düğmesinin hemen üstünde duruyor. Banner görünür — o sorun değil — ama
/// eklendiği anda düğmeyi aşağı itiyor. Ölçüldü (gerçek altın sheet'i,
/// 411×914dp): "Kaydet" 854,5→877,5 iken hata sonrası 932,5→955,5'e kayıyor,
/// yani **ekranın 41,5dp dışına**. Kullanıcı hatayı okuyor ama az önce bastığı
/// düğmeyi kaybediyor ve hiçbir ipucu olmadan elle aşağı kaydırmak zorunda
/// kalıyor.
///
/// `alignment: 1.0` düğmeyi görünür alanın ALTINA hizalar; banner hemen
/// üstünde olduğu için ikisi birlikte ekrana gelir. Düğme zaten görünüyorsa
/// çağrı etkisizdir, yani her hata yolunda koşulsuz çağrılabilir.
void revealSaveButton(GlobalKey saveButtonKey) {
  // Banner ancak setState'ten SONRAKİ karede ağaca giriyor; ondan önce
  // ölçmek eski (kaymamış) konumu verir.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = saveButtonKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  });
}

class InvestmentErrorBanner extends StatelessWidget {
  final String error;

  const InvestmentErrorBanner(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                  color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kaydet / Güncelle butonu; degrade [accent].shade600 ile boyanır.
class InvestmentSaveButton extends StatelessWidget {
  final MaterialColor accent;
  final double radius;
  final bool isEditing;
  final VoidCallback onSave;

  const InvestmentSaveButton({
    super.key,
    required this.accent,
    required this.radius,
    required this.isEditing,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius.clamp(16, 20));
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: br,
          onTap: onSave,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppGradients.vivid(accent.shade600),
              borderRadius: br,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isEditing ? Icons.check_rounded : Icons.add_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? context.l10n.guncelle : context.l10n.kaydet,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Adet alanı + canlı fiyat "Hesapla" butonu (hisse ve altın sheet'lerinde
/// kullanılır). Buton [accent].shade600 ile boyanır; [fetchedMessage] varsa
/// altında [fetchedColor] ile gösterilir.
class InvestmentQuantityAndFetch extends StatelessWidget {
  final MaterialColor accent;
  final TextEditingController quantityController;
  final VoidCallback onQuantityChanged;
  final bool isLoading;
  final String? fetchedMessage;
  final Color fetchedColor;
  final VoidCallback onFetch;

  /// Miktarın birimi ("Gram Altın", "lot"); null → genel "Adet".
  /// Altın kaydında birim türün kendisidir; "Adet" yazmak 1 çeyreği 1 grama
  /// eş gösteriyordu.
  final String? unitLabel;

  const InvestmentQuantityAndFetch({
    super.key,
    required this.accent,
    required this.quantityController,
    required this.onQuantityChanged,
    required this.isLoading,
    required this.fetchedMessage,
    required this.fetchedColor,
    required this.onFetch,
    this.unitLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: InvestmentFilledField(
            controller: quantityController,
            hint: unitLabel ?? context.l10n.adet,
            icon: Icons.numbers_rounded,
            accent: accent,
            onChanged: onQuantityChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Adet para değildir; 0,125 gr gibi hassas girişe izin ver.
            inputFormatters: [AmountInputFormatter(decimalDigits: 4)],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56, // Match InvestmentFilledField height
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onFetch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded),
                  label: Text(
                    context.l10n.hesapla,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              if (fetchedMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    fetchedMessage!,
                    style: TextStyle(
                      color: fetchedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Alım tarihi + ödemenin NEREDEN geldiği ve cüzdana etkisinin tek
/// cümlelik özeti.
///
/// Neden gerekli: kayıt açıldığında maliyet cüzdana gider yazılıyor. İki
/// durumda bu yanlış: (1) varlık uygulamadan ÖNCE alınmıştı (para bugün
/// çıkmadı — "zaten bende", bkz. `InvestmentEntity.unbookedCost`); (2) ödeme
/// defterde ZATEN duruyor — ekstreden içe aktarılmış "MIDAS MENKUL DEGERLER
/// −5.000" gibi. İkinci durumda gider yeniden yazılınca para İKİ KEZ
/// düşüyordu; artık o satır seçilir ve kaydın nakit bacağı olur.
class InvestmentPurchaseRow extends StatelessWidget {
  final MaterialColor accent;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final PurchasePayment payment;
  final ValueChanged<PurchasePayment> onPaymentChanged;

  /// Defter seçicisinin kapsamı ve tutar biçimi.
  final String userId;
  final String walletId;
  final String walletCurrency;

  /// Girilen maliyet; `null` → henüz girilmedi. Özet satırını ve defter
  /// seçicisindeki sıralamayı (tutarı en yakın satırlar üstte) besler.
  final double? cost;

  /// Geçmiş tarihli alımda "bugünkü değeri hesapla" kısayolu. null →
  /// kısayol yok (özel varlığın canlı fiyat kaynağı yoktur).
  final VoidCallback? onCalculateTodayValue;

  /// Birikimdeki NAKİT KASALARI: ödeme kasadan yapılabilir (cüzdana ve
  /// deftere dokunmadan). Boşsa seçenek çizilmez.
  final List<InvestmentEntity> pots;

  const InvestmentPurchaseRow({
    super.key,
    required this.accent,
    required this.date,
    required this.onDateChanged,
    required this.payment,
    required this.onPaymentChanged,
    required this.userId,
    required this.walletId,
    required this.walletCurrency,
    required this.cost,
    this.onCalculateTodayValue,
    this.pots = const [],
  });

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      // İleri tarihli alım yok: gider defterine geleceğe kayıt düşürürdü.
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      onDateChanged(DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickLedgerRow(BuildContext context) async {
    final picked = await showLedgerTransactionPicker(
      context,
      userId: userId,
      walletId: walletId,
      currency: walletCurrency,
      isIncome: false,
      amountHint: (cost != null && cost! > 0) ? cost : null,
      dateHint: date,
    );
    if (picked != null) onPaymentChanged(PurchasePayment.ledger(picked));
  }

  void _select(BuildContext context, PurchasePaymentMode mode) {
    switch (mode) {
      case PurchasePaymentMode.wallet:
        onPaymentChanged(const PurchasePayment.wallet());
      case PurchasePaymentMode.alreadyOwned:
        onPaymentChanged(const PurchasePayment.alreadyOwned());
      case PurchasePaymentMode.ledger:
        if (payment.mode == PurchasePaymentMode.ledger) return;
        onPaymentChanged(const PurchasePayment.ledger());
        // Satırsız "defterde var" anlamsız: seçici hemen açılır.
        _pickLedgerRow(context);
      case PurchasePaymentMode.pot:
        // Kasa seçimi kendi satırından yapılır (bkz. build).
        break;
    }
  }

  String _caption(BuildContext context) {
    final l10n = context.l10n;
    final tx = payment.ledgerTransaction;
    return switch (payment.mode) {
      PurchasePaymentMode.ledger when tx != null =>
        l10n.alimDefterdenKarsilanacak(
            formatMoney(tx.amount, currency: walletCurrency)),
      PurchasePaymentMode.ledger => l10n.defterSatiriSecilmedi,
      PurchasePaymentMode.alreadyOwned => l10n.alimCuzdandanDusulmeyecek,
      PurchasePaymentMode.pot => l10n.alimKasadanDusulecek(
          payment.pot?.name ?? '',
          formatMoney(payment.pot?.amount ?? 0, currency: walletCurrency)),
      PurchasePaymentMode.wallet when cost == null || cost! <= 0 =>
        l10n.alimCuzdandanDusulmeyecek,
      PurchasePaymentMode.wallet => l10n.alimCuzdandanDusulecek(
          formatMoney(cost!, currency: walletCurrency),
          AppFormatters.dateLong.format(date),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final locked = payment.isLedgerLocked;
    final tx = payment.ledgerTransaction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            // Defterden seçilen satırın tarihi alımın tarihidir; ayrıca
            // değiştirilirse gider ile kayıt farklı günlerde dururdu.
            onTap: locked ? null : () => _pickDate(context),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 18, color: accent.shade600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${l10n.alimTarihi}: '
                      '${AppFormatters.dateLong.format(date)}',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(locked ? Icons.lock_outline_rounded : Icons.edit_rounded,
                      size: 16, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        InvestmentSectionLabel(l10n.odemeKaynagiBaslik),
        const SizedBox(height: 6),
        // Nakit kasaları ÖNCE: kullanıcı birikimindeki parayla yatırım
        // yapmayı seçtiyse cüzdan ikinci seçenektir.
        for (final pot in pots)
          _PaymentOption(
            key: ValueKey('pay-pot-${pot.id}'),
            accent: accent,
            selected: payment.mode == PurchasePaymentMode.pot &&
                payment.pot?.id == pot.id,
            title: l10n.odemeKasadanBaslik(pot.name),
            subtitle: l10n.kasaBakiyesi(
                formatMoney(pot.amount, currency: walletCurrency)),
            onTap: () => onPaymentChanged(PurchasePayment.pot(pot)),
          ),
        _PaymentOption(
          accent: accent,
          selected: payment.mode == PurchasePaymentMode.wallet,
          title: l10n.odemeCuzdandanBaslik,
          subtitle: l10n.odemeCuzdandanAciklama,
          onTap: () => _select(context, PurchasePaymentMode.wallet),
        ),
        _PaymentOption(
          accent: accent,
          selected: payment.mode == PurchasePaymentMode.ledger,
          title: l10n.odemeDefterdeBaslik,
          subtitle: l10n.odemeDefterdeAciklama,
          onTap: () => _select(context, PurchasePaymentMode.ledger),
        ),
        if (payment.mode == PurchasePaymentMode.ledger)
          Padding(
            padding: const EdgeInsets.fromLTRB(34, 0, 0, 6),
            child: Row(
              children: [
                if (tx != null)
                  Expanded(
                    child: Text(
                      '“${tx.title}” · −'
                      '${formatMoney(tx.amount, currency: walletCurrency)} · '
                      '${AppFormatters.dateShort.format(tx.date)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  const Spacer(),
                TextButton(
                  onPressed: () => _pickLedgerRow(context),
                  style: TextButton.styleFrom(
                      foregroundColor: accent.shade700),
                  child: Text(tx == null
                      ? l10n.defterSatiriSecDugme
                      : l10n.defterSatiriDegistir),
                ),
              ],
            ),
          ),
        _PaymentOption(
          accent: accent,
          selected: payment.mode == PurchasePaymentMode.alreadyOwned,
          title: l10n.zatenBendeBaslik,
          subtitle: l10n.zatenBendeAciklama,
          onTap: () => _select(context, PurchasePaymentMode.alreadyOwned),
        ),
        InvestmentHintCaption(_caption(context)),
        if (payment.exceedsPot(cost)) ...[
          const SizedBox(height: 8),
          InvestmentWarningBanner(l10n.kasaYetersizUyari(
              formatMoney(payment.pot?.amount ?? 0, currency: walletCurrency))),
        ],
        // Geçmiş tarihli alımda kafa karıştıran nokta: "Mevcut Değer" alanı
        // alım GÜNÜNÜN değeri sanılıyor. Kâr/zarar yanlış okunmasın diye
        // açıkça söylenir; altın/hissede bugünkü değeri hesaplama kısayolu
        // da buradan verilir.
        if (!_isToday(date)) ...[
          const SizedBox(height: 10),
          InvestmentWarningBanner(
            l10n.gecmisAlimUyarisi(AppFormatters.dateLong.format(date)),
          ),
          if (onCalculateTodayValue != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onCalculateTodayValue,
                icon: const Icon(Icons.calculate_rounded, size: 18),
                label: Text(l10n.bugunkuDegeriHesapla),
                style: TextButton.styleFrom(foregroundColor: accent.shade700),
              ),
            ),
        ],
      ],
    );
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// Ödeme seçeneklerinden biri: işaret + başlık + açıklama.
class _PaymentOption extends StatelessWidget {
  final MaterialColor accent;
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentOption({
    super.key,
    required this.accent,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Sheet'in renkli zemininde ink dalgası için kendi saydam Material'ı.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected ? accent.shade600 : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kaydı bir birikim hedefine bağlayan seçici.
///
/// Hedef tutarı ve kategorisi ARTIK BURADA DEĞİL: onlar hedefin kendi
/// alanları. Formda kalan tek soru "bu varlık hangi hedefe sayılsın".
class InvestmentGoalPicker extends StatelessWidget {
  final List<GoalEntity> goals;
  final String? selectedGoalId;
  final MaterialColor accent;
  final String walletCurrency;
  final ValueChanged<String?> onChanged;

  const InvestmentGoalPicker({
    super.key,
    required this.goals,
    required this.selectedGoalId,
    required this.accent,
    required this.walletCurrency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (goals.isEmpty) {
      return InvestmentHintCaption(context.l10n.hedefYokAciklama);
    }

    // Silinmiş/başka cüzdana ait bir kimlik seçili kalırsa DropdownButton
    // assert atar; bilinmeyen değer "bağlı değil"e düşer.
    final value =
        goals.any((g) => g.id == selectedGoalId) ? selectedGoalId : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          dropdownColor: cs.surface,
          icon: Icon(Icons.arrow_drop_down_rounded, color: cs.onSurfaceVariant),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.remove_circle_outline_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.hedefeBagliDegil,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            for (final goal in goals)
              DropdownMenuItem<String?>(
                value: goal.id,
                child: Row(
                  children: [
                    Icon(Icons.flag_rounded, size: 18, color: goal.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      formatMoney(goal.targetAmount, currency: walletCurrency),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
