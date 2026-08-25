part of 'investment_bloc.dart';

/// Yatırım eylemlerinin kullanıcıya söylenecek sonucu — METNİN KENDİSİ DEĞİL.
///
/// Bloc'ta `context` (dolayısıyla l10n) yok; hazır Türkçe cümle yayınlamak
/// uygulama İngilizce'ye alındığında bildirimleri Türkçe bırakıyordu. Metin
/// sayfada çözülür (`investmentNoticeText`).
sealed class InvestmentNotice extends Equatable {
  const InvestmentNotice();

  @override
  List<Object?> get props => [];
}

/// Depo/servis katmanından gelen ham hata metni: çevrilemez, olduğu gibi
/// gösterilir.
final class RawFailureNotice extends InvestmentNotice {
  final String message;

  const RawFailureNotice(this.message);

  @override
  List<Object?> get props => [message];
}

final class GoalSavedNotice extends InvestmentNotice {
  const GoalSavedNotice();
}

final class GoalDeletedNotice extends InvestmentNotice {
  const GoalDeletedNotice();
}

final class InvestmentAddedNotice extends InvestmentNotice {
  const InvestmentAddedNotice();
}

final class InvestmentUpdatedNotice extends InvestmentNotice {
  const InvestmentUpdatedNotice();
}

final class InvestmentSoldNotice extends InvestmentNotice {
  const InvestmentSoldNotice();
}

final class InvestmentPartiallySoldNotice extends InvestmentNotice {
  const InvestmentPartiallySoldNotice();
}

final class InvestmentDeletedNotice extends InvestmentNotice {
  const InvestmentDeletedNotice();
}

final class PricesRefreshedNotice extends InvestmentNotice {
  final int updated;
  final int failed;

  const PricesRefreshedNotice({required this.updated, required this.failed});

  @override
  List<Object?> get props => [updated, failed];
}

final class NoRefreshablePricesNotice extends InvestmentNotice {
  const NoRefreshablePricesNotice();
}

final class PricesUnavailableNotice extends InvestmentNotice {
  const PricesUnavailableNotice();
}

sealed class InvestmentState extends Equatable {
  const InvestmentState();

  @override
  List<Object?> get props => [];
}

final class InvestmentInitial extends InvestmentState {}

final class InvestmentLoading extends InvestmentState {}

final class InvestmentLoaded extends InvestmentState {
  final List<InvestmentEntity> investments;

  /// Cüzdanın birikim hedefleri. İlerleme burada TUTULMAZ; üyelerden
  /// hesaplanır (bkz. `buildGoalProgress`).
  final List<GoalEntity> goals;

  final double totalAmount;

  const InvestmentLoaded(
    this.investments, {
    this.goals = const [],
    this.totalAmount = 0.0,
  });

  /// Portföy özet metrikleri — UI build içinde hesap yapmasın diye state'te.
  ///
  /// Yuvarlama, cüzdan metriğiyle (`WalletMetricsService._syncInvestmentImpl`)
  /// AYNI olmalı: üst çubuk oradan, özet kart buradan besleniyor. Ham
  /// bırakıldığında toplam .085'e denk geldiğinde iki yol ayrışıyordu —
  /// `roundToCents` yarımı yukarı, `NumberFormat` çifte yuvarlar; üst çubuk
  /// 5.968.277,09 ₺ derken kart 5.968.277,08 ₺ diyordu.
  double get totalCurrentValue => roundToCents(
      investments.fold(0.0, (sum, item) => sum + item.currentValue));

  /// Kâr da yuvarlanmış iki toplamın farkı: kullanıcı ekranda gördüğü iki
  /// sayıyı çıkarıp aynı sonucu bulabilmeli (ham farkta -4.092,67 yazarken
  /// gösterilen değerlerin farkı -4.092,68 çıkıyordu).
  double get totalProfit => roundToCents(totalCurrentValue - totalAmount);

  double get totalProfitPercentage =>
      totalAmount > 0 ? (totalProfit / totalAmount) * 100 : 0.0;

  @override
  List<Object> get props => [investments, goals, totalAmount];
}

final class InvestmentError extends InvestmentState {
  /// Hatanın sebebi; metni sayfada çözülür (ham depo mesajları
  /// [RawFailureNotice] ile olduğu gibi taşınır).
  final InvestmentNotice notice;

  const InvestmentError(this.notice);

  @override
  List<Object> get props => [notice];
}

final class InvestmentActionSuccess extends InvestmentState {
  final InvestmentNotice notice;

  /// Nakit hareketi yazılabildi mi; false ise mesaja "bakiye güncellenemedi"
  /// uyarısı eklenir (bkz. `CashCouplingMixin.cashWarning`).
  final bool cashOk;

  /// Yalnız silmede dolu: UI bunu "Geri al" eylemine bağlar. Satışta da
  /// dolu — satış da kaydı defterden kaldırıp gelir yazar, geri alınabilir.
  final DeletionUndo? undo;

  const InvestmentActionSuccess(this.notice, {this.cashOk = true, this.undo});

  @override
  List<Object?> get props => [notice, cashOk, undo];
}
