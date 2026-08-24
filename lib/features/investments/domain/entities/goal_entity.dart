import 'dart:ui';

import 'package:equatable/equatable.dart';

/// Birikim hedefi: BİRDEN ÇOK yatırımın altında toplandığı üst kayıt.
///
/// Hedef eskiden yatırımın bir alanıydı (`targetAmount` + `goalCategory`) ve
/// bu yüzden karışık portföy kurulamıyordu: gram altın, çeyrek altın ve hisse
/// aynı hedefe sayılamıyor, her biri kendi mini hedefi oluyordu. Artık hedef
/// kendi kaydıdır; yatırımlar ona [InvestmentEntity.goalId] ile bağlanır.
///
/// PARA BİRİMİ: [targetAmount] kaydın CÜZDANININ birimindedir (yatırımlarla
/// aynı kural — kayıtta ayrı birim alanı yok, `walletId`'den türer).
///
/// İlerleme burada DURMAZ: üyelerin güncel değerlerinin toplamıdır ve her
/// okumada hesaplanır (bkz. `goal_progress.dart`). Türetilmiş bir sayıyı
/// saklamak, üye eklenip çıkarıldıkça bayatlayan ikinci bir gerçek üretirdi.
class GoalEntity extends Equatable {
  final String id;
  final String userId;
  final String walletId;

  /// Kullanıcının verdiği ad ("Ev peşinatı"). Kimlik DEĞİL — ad değişebilir,
  /// [id] sabittir.
  final String name;

  /// Ulaşılmak istenen tutar; sıfırdan büyük olmalıdır.
  final double targetAmount;

  /// Hedef kategorisi anahtarı (ev, dugun, araba, acil_fon, egitim, diger).
  /// Yalnız ikon/etiket içindir.
  final String category;

  final Color color;
  final DateTime createdAt;

  const GoalEntity({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.name,
    required this.targetAmount,
    required this.category,
    required this.color,
    required this.createdAt,
  });

  GoalEntity copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? name,
    double? targetAmount,
    String? category,
    Color? color,
    DateTime? createdAt,
  }) {
    return GoalEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      category: category ?? this.category,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        name,
        targetAmount,
        category,
        color,
        createdAt,
      ];
}
