import 'package:equatable/equatable.dart';

/// Bütçe nesnesi. Her bir kategori için kullanıcının belirlediği aylık harcama limitini temsil eder.
class BudgetEntity extends Equatable {
  /// Bütçenin ait olduğu kategori ID'si (genellikle kategorinin kendi adı).
  final String categoryId;

  /// Bu kategori için belirlenen aylık üst limit.
  final double limitAmount;

  /// Bu ay içinde harcanan miktar (Veritabanına kaydedilmez, anlık hesaplanır).
  final double spentAmount;

  const BudgetEntity({
    required this.categoryId,
    required this.limitAmount,
    this.spentAmount = 0.0,
  });

  BudgetEntity copyWith({
    String? categoryId,
    double? limitAmount,
    double? spentAmount,
  }) {
    return BudgetEntity(
      categoryId: categoryId ?? this.categoryId,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }

  double get progress => limitAmount > 0 ? (spentAmount / limitAmount).clamp(0.0, 1.0) : 0.0;
  bool get isExceeded => spentAmount > limitAmount;

  @override
  List<Object?> get props => [categoryId, limitAmount, spentAmount];
}
