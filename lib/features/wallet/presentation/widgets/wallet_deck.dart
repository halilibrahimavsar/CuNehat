import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/shared/widgets/money_text.dart';
import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/credit_card/presentation/wallet_card_stack.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';

/// Cüzdan destesi: cüzdanlar yan yana, büyük kartlar hâlinde; ortadaki
/// "odaktaki" cüzdandır, komşuları iki kenardan görünür.
///
/// Eskiden cüzdanlar alt alta, her biri ~250dp'lik kutulardı ve sayfa
/// ekranın %60'ında açılıyordu: ekranda TEK cüzdan, o da yarım görünüyordu
/// (cihazda ölçüldü). Kutuya dokunmak cüzdanı seçiyor ama sayfayı
/// kapatmıyordu; düzenle/sil düğmeleri her kutuda tekrarlanıyordu.
///
/// Şimdi:
/// - yana kaydır → cüzdanlar arasında gez (hiçbir şey seçilmez);
/// - ortadaki karta dokun → o cüzdana geç ve sayfayı kapat;
/// - eylemler (geç · düzenle · sil) yalnız ODAKTAKİ cüzdan için, kartın
///   altında bir kez durur.
///
/// Kredi kartları ayrı sayfa DEĞİLDİR: odaktaki cüzdanın altında deste
/// olarak durur (bkz. `card_family.dart`). Yalnız sahibi olmayan (yetim)
/// kart kendi sayfasını alır, "bir cüzdana bağla" önerisiyle.
class WalletDeck extends StatefulWidget {
  /// Bütün cüzdanlar (aile hesabı için kartlar dahil).
  final List<WalletEntity> wallets;
  final WalletEntity? active;

  /// Sayfanın (`DraggableScrollableSheet`) kaydırma denetleyicisi: deste bu
  /// kaydırılabilirin içinde durmazsa sayfa içerikten sürüklenemez.
  final ScrollController scrollController;

  /// Kredi kartı desteleri gösterilsin mi (özellik bayrağı).
  final bool showCards;

  /// Cüzdana (ya da karta) geç ve sayfayı kapat.
  final ValueChanged<WalletEntity> onSelect;
  final ValueChanged<WalletEntity> onEdit;
  final ValueChanged<WalletEntity> onDelete;

  /// Odaktaki cüzdana kart ekle.
  final ValueChanged<WalletEntity> onAddCard;

  /// Yetim kartı bir cüzdana bağla.
  final ValueChanged<WalletEntity> onAttachCard;
  final ValueChanged<WalletEntity> onCardDetails;

  const WalletDeck({
    super.key,
    required this.wallets,
    required this.active,
    required this.scrollController,
    required this.showCards,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onAddCard,
    required this.onAttachCard,
    required this.onCardDetails,
  });

  @override
  State<WalletDeck> createState() => _WalletDeckState();
}

class _WalletDeckState extends State<WalletDeck> {
  late final PageController _pages;
  late int _focused;

  /// Odaktaki cüzdanın kimliği: liste değişince (ekleme/silme) aynı cüzdanda
  /// kalabilmek için indeksle birlikte tutulur.
  String? _focusedId;

  List<WalletEntity> get _tops =>
      widget.showCards ? topLevelWallets(widget.wallets) : widget.wallets;

  String? _accountIdOf(WalletEntity? wallet) =>
      wallet == null ? null : accountOf(wallet, widget.wallets).id;

  int _indexOf(String? id, List<WalletEntity> tops) {
    final i = tops.indexWhere((w) => w.id == id);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    final tops = _tops;
    // Açılışta etkin cüzdan ortada.
    _focused = _indexOf(_accountIdOf(widget.active), tops);
    _focusedId = tops.isEmpty ? null : tops[_focused].id;
    _pages = PageController(initialPage: _focused, viewportFraction: 0.86);
  }

  @override
  void didUpdateWidget(covariant WalletDeck old) {
    super.didUpdateWidget(old);
    final tops = _tops;
    if (tops.isEmpty) return;
    final oldAccount =
        old.active == null ? null : accountOf(old.active!, old.wallets).id;
    final newAccount = _accountIdOf(widget.active);
    // Etkin cüzdan değişti (yeni cüzdan kuruldu, kart bağlandı): deste oraya
    // gider. Değişmediyse odaktaki cüzdan korunur; silindiyse en yakını.
    final target = newAccount != oldAccount
        ? _indexOf(newAccount, tops)
        : (tops.any((w) => w.id == _focusedId)
            ? _indexOf(_focusedId, tops)
            : _focused.clamp(0, tops.length - 1));
    _focusedId = tops[target].id;
    if (target == _focused) return;
    _focused = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pages.hasClients) return;
      _pages.animateToPage(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onCardTap(int index, WalletEntity wallet) {
    if (index == _focused) {
      widget.onSelect(wallet);
    } else {
      // Kenardan görünen komşu: önce ortaya gelir, seçilmez.
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tops = _tops;
    if (tops.isEmpty) return const SizedBox.shrink();
    final focused = tops[_focused.clamp(0, tops.length - 1)];
    final activeAccountId = _accountIdOf(widget.active);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      children: [
        SizedBox(
          height: WalletDeckCard.height,
          child: PageView.builder(
            key: const ValueKey('wallet-deck'),
            controller: _pages,
            itemCount: tops.length,
            onPageChanged: (i) => setState(() {
              _focused = i;
              _focusedId = tops[i].id;
            }),
            itemBuilder: (context, i) {
              final wallet = tops[i];
              return AnimatedBuilder(
                animation: _pages,
                builder: (context, child) {
                  // Ortadan uzaklık: komşular küçülür ve solar.
                  final page = _pages.position.haveDimensions
                      ? (_pages.page ?? _focused.toDouble())
                      : _focused.toDouble();
                  final away = (page - i).abs().clamp(0.0, 1.0);
                  return Opacity(
                    opacity: 1 - 0.45 * away,
                    child: Transform.scale(
                      scale: 1 - 0.07 * away,
                      child: child,
                    ),
                  );
                },
                child: WalletDeckCard(
                  key: ValueKey('wallet-deck-card-${wallet.id}'),
                  wallet: wallet,
                  active: wallet.id == activeAccountId,
                  debt: debtOverview(wallet, widget.wallets).total,
                  onTap: () => _onCardTap(i, wallet),
                ),
              );
            },
          ),
        ),
        if (tops.length > 1) _DeckPager(count: tops.length, index: _focused),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
          child: _actions(context, focused,
              isActive: focused.id == activeAccountId),
        ),
        if (widget.showCards && !focused.isCreditCard)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: WalletCardStack(
              key: ValueKey('cards-${focused.id}'),
              cards: cardsOf(focused.id, widget.wallets),
              activeId: widget.active?.id,
              onCardTap: widget.onSelect,
              onCardLongPress: widget.onCardDetails,
              onAdd: () => widget.onAddCard(focused),
            ),
          ),
      ],
    );
  }

  Future<void> _showMore(
    BuildContext context,
    WalletEntity wallet, {
    required bool isActive,
  }) async {
    final l10n = context.l10n;
    final action = await RowActionSheet.show<RowEditDelete>(
      context,
      title: wallet.name,
      icon: Icons.account_balance_wallet_rounded,
      accent: WalletColors.hexToColor(wallet.colorHex),
      actions: [
        RowAction(
          value: RowEditDelete.edit,
          icon: Icons.edit_rounded,
          color: Colors.blueGrey,
          title: l10n.duzenle,
        ),
        RowAction(
          value: RowEditDelete.delete,
          icon: Icons.delete_outline_rounded,
          title: l10n.sil,
          // Etkin cüzdan silinemez; neden silinemediği satırda yazar
          // (eskiden düğme sessizce kayboluyordu).
          subtitle: isActive ? l10n.aktifCuzdanSilinemez : null,
          destructive: true,
          enabled: !isActive,
        ),
      ],
    );
    if (action == null) return;
    switch (action) {
      case RowEditDelete.edit:
        widget.onEdit(wallet);
      case RowEditDelete.delete:
        widget.onDelete(wallet);
    }
  }

  /// Odaktaki cüzdanın eylemleri — her kutuda tekrarlanmak yerine bir kez.
  Widget _actions(
    BuildContext context,
    WalletEntity wallet, {
    required bool isActive,
  }) {
    final l10n = context.l10n;
    final isCard = wallet.isCreditCard;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey('wallet-deck-select'),
            // Etkin cüzdanda düğme bir durum göstergesidir.
            onPressed: isActive ? null : () => widget.onSelect(wallet),
            icon: Icon(
              isActive ? Icons.check_circle_rounded : Icons.login_rounded,
              size: 18,
            ),
            label: Text(
              isActive
                  ? l10n.aktifCuzdan
                  : (isCard ? l10n.kartaGec : l10n.cuzdanaGec),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (isCard)
          IconButton.filledTonal(
            key: const ValueKey('wallet-deck-attach'),
            tooltip: l10n.kkCuzdanaBagla,
            icon: const Icon(Icons.link_rounded),
            onPressed: () => widget.onAttachCard(wallet),
          )
        else ...[
          IconButton.filledTonal(
            key: const ValueKey('wallet-deck-edit'),
            tooltip: l10n.duzenle,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => widget.onEdit(wallet),
          ),
          RowMenuButton(
            key: const ValueKey('wallet-deck-more'),
            iconSize: 24,
            onPressed: () => _showMore(context, wallet, isActive: isActive),
          ),
        ],
      ],
    );
  }
}

/// Destedeki konum: noktalar, çok cüzdanda "3/9".
class _DeckPager extends StatelessWidget {
  final int count;
  final int index;

  const _DeckPager({required this.count, required this.index});

  static const int _maxDots = 8;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (count > _maxDots) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Center(
          child: Text(
            '${index + 1}/$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        key: const ValueKey('wallet-deck-dots'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: i == index ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i == index
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Destedeki tek bir cüzdan: cüzdanın kendi renginde, kart biçiminde.
///
/// Kartın içinde düğme YOK — kartın tamamı tek bir dokunma hedefidir
/// (ortadaysa seç, kenardaysa ortaya getir); eylemler destenin altındadır.
class WalletDeckCard extends StatelessWidget {
  final WalletEntity wallet;

  /// Etkin bağlam bu cüzdan (ya da ona bağlı bir kart) mı.
  final bool active;

  /// Cüzdanın bütün borcu: krediler + bağlı kartlar (bkz. [debtOverview]).
  final double debt;
  final VoidCallback onTap;

  const WalletDeckCard({
    super.key,
    required this.wallet,
    required this.active,
    required this.debt,
    required this.onTap,
  });

  /// Sabit: yatay sayfa görünümü çocuklarına sınırlı bir yükseklik ister ve
  /// kartların boyu cüzdandan cüzdana oynamamalı.
  static const double height = 192;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final base = WalletColors.hexToColor(wallet.colorHex);
    final hsl = HSLColor.fromColor(base);
    final light =
        hsl.withLightness((hsl.lightness + 0.10).clamp(0.0, 1.0)).toColor();
    final dark =
        hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor();
    // Sarı gibi açık renklerde beyaz yazı okunmaz.
    final on = ThemeData.estimateBrightnessForColor(base) == Brightness.dark
        ? Colors.white
        : const Color(0xFF1B1B1F);
    final radius = BorderRadius.circular(24);
    final isCard = wallet.isCreditCard;
    final headline = isCard ? -wallet.balance : wallet.balance;
    final rate = wallet.currency == kDefaultCurrency
        ? null
        : getIt<ExchangeRateService>().cachedRateToTry(wallet.currency);
    final hasStats =
        !isCard && (debt > 0 || wallet.credit > 0 || wallet.investment > 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: base.withValues(alpha: 0.32),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [light, base, dark],
              ),
              border: active
                  ? Border.all(color: on.withValues(alpha: 0.85), width: 2)
                  : null,
              borderRadius: radius,
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: on.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            AppIcons.getIconData(wallet.iconName),
                            color: on,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            wallet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: on,
                            ),
                          ),
                        ),
                        if (active)
                          // Dar ekranda yalnız simge: yazılı rozet adı "Maaş
                          // he…" diye kesiyordu; "aktif" bilgisi kartın
                          // altındaki "Aktif cüzdan" düğmesinde de yazılı.
                          _ActiveChip(
                            color: on,
                            compact: MediaQuery.sizeOf(context).width /
                                    MediaQuery.textScalerOf(context).scale(1) <
                                360,
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      isCard ? l10n.drawerDebt : l10n.drawerBalance,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: on.withValues(alpha: 0.72),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: MoneyText(
                        amount: headline,
                        currency: wallet.currency,
                        style: TextStyle(
                          fontSize: 28,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: on,
                        ),
                      ),
                    ),
                    // Döviz cüzdanında son bilinen kurla TL karşılığı; kur
                    // hiç yoksa satır gizlenir (yanıltıcı 0 yazmayız).
                    if (rate != null)
                      Text(
                        l10n.yaklasikKarsilikFormat(
                            formatMoney(headline * rate)),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: on.withValues(alpha: 0.75),
                        ),
                      ),
                    if (hasStats) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _stat(l10n.birikimLabel, wallet.investment, on),
                          _stat(l10n.alacakLabel, wallet.credit, on),
                          _stat(l10n.borcLabel, debt, on),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, double amount, Color on) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: on.withValues(alpha: 0.7),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyText(
              amount: amount,
              currency: wallet.currency,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: on,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final Color color;
  final bool compact;

  const _ActiveChip({required this.color, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Semantics(
        label: context.l10n.aktif,
        child: Icon(Icons.check_circle_rounded, size: 18, color: color),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            context.l10n.aktif,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
