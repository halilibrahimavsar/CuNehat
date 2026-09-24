import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';

/// Kartın dönem durumu: defteri okur, [computeCardStatus] ile türetir.
/// Depo kayıtlı değilse (yalıtılmış testler) ya da kart değilse `null`.
Future<CardStatus?> loadCardStatus(WalletEntity card, {DateTime? today}) async {
  final info = card.creditCard;
  if (info == null || card.id == null) return null;
  if (!getIt.isRegistered<TransactionsRepository>()) return null;
  final result = await getIt<TransactionsRepository>().getTransactions(
    userId: card.userId,
    walletId: card.id!,
  );
  return computeCardStatus(
    card: info,
    openingBalance: card.openingBalance,
    walletCreatedAt: card.createdAt,
    ledger: result.getOrElse(() => const []),
    today: today ?? DateTime.now(),
  );
}

/// Kalan dönem borcu toplamı — "kart ödemeleri düşülünce" bakiyesi için.
/// Yalnız KESİLMİŞ ekstrenin ödenmemiş kısmı (kullanıcı kararı, 24 Eyl 2026):
/// bu ay gerçekten hesaptan çıkacak para; gelecek ekstreye girecek
/// harcamalar düşülmez.
double totalRemainingStatementDebt(Iterable<CardStatus> statuses) {
  var total = 0.0;
  for (final s in statuses) {
    if (s.remainingStatementDebt > 0) total += s.remainingStatementDebt;
  }
  return total;
}

/// Kartların dönem durumlarını defterden CANLI türetir: kartlardan birinin
/// defteri değişince (harcama, karta ödeme) ya da bakiyesi değişince yeniden
/// okur. [builder] ilk okuma bitene kadar boş harita alır; `loaded` false.
class CardsStatusBuilder extends StatefulWidget {
  final List<WalletEntity> cards;

  /// "Bugün" — test edilebilirlik için.
  final DateTime? today;

  final Widget Function(
    BuildContext context,
    Map<String, CardStatus> statuses,
    bool loaded,
  ) builder;

  const CardsStatusBuilder({
    super.key,
    required this.cards,
    required this.builder,
    this.today,
  });

  @override
  State<CardsStatusBuilder> createState() => _CardsStatusBuilderState();
}

class _CardsStatusBuilderState extends State<CardsStatusBuilder> {
  Map<String, CardStatus> _statuses = const {};
  bool _loaded = false;
  StreamSubscription<TransactionsChange>? _changes;

  /// Eşzamanlı okumalarda yalnız EN SON başlatılanın sonucu yazılır.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
    if (getIt.isRegistered<TransactionsChangedNotifier>()) {
      _changes = getIt<TransactionsChangedNotifier>().stream.listen((c) {
        if (c.walletId == null || widget.cards.any((w) => w.id == c.walletId)) {
          _load();
        }
      });
    }
  }

  /// Kart kümesi, bakiye ya da ayarlar (kesim günü, beyan) değişti mi.
  static String _signature(List<WalletEntity> cards) => [
        for (final c in cards)
          '${c.id}:${c.balance}:${c.creditCard.hashCode}:${c.openingBalance}',
      ].join('|');

  @override
  void didUpdateWidget(covariant CardsStatusBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signature(oldWidget.cards) != _signature(widget.cards)) _load();
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final cards = widget.cards;
    final results = await Future.wait(
      cards.map((c) => loadCardStatus(c, today: widget.today)),
    );
    if (!mounted || generation != _generation) return;
    setState(() {
      _statuses = {
        for (var i = 0; i < cards.length; i++)
          if (results[i] != null) cards[i].id!: results[i]!,
      };
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _statuses, _loaded);
}

/// Tek kart için [CardsStatusBuilder]: [builder] ilk okuma bitene kadar
/// `null` alır.
class CardStatusBuilder extends StatelessWidget {
  final WalletEntity card;

  /// "Bugün" — test edilebilirlik için.
  final DateTime? today;

  final Widget Function(BuildContext context, CardStatus? status) builder;

  const CardStatusBuilder({
    super.key,
    required this.card,
    required this.builder,
    this.today,
  });

  @override
  Widget build(BuildContext context) => CardsStatusBuilder(
        cards: [card],
        today: today,
        builder: (context, statuses, _) => builder(context, statuses[card.id]),
      );
}
