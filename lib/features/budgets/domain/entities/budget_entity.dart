import 'package:equatable/equatable.dart';

/// Bütçe nesnesi. Her bir kategori için kullanıcının belirlediği aylık harcama limitini temsil eder.
class BudgetEntity extends Equatable {
  /// Bütçenin ait olduğu kategori ID'si (genellikle kategorinin kendi adı).
  final String categoryId;

  /// Bu kategori için belirlenen aylık üst limit.
  final double limitAmount;

  const BudgetEntity({
    required this.categoryId,
    required this.limitAmount,
  });

  BudgetEntity copyWith({
    String? categoryId,
    double? limitAmount,
  }) {
    return BudgetEntity(
      categoryId: categoryId ?? this.categoryId,
      limitAmount: limitAmount ?? this.limitAmount,
    );
  }

  @override
  List<Object?> get props => [categoryId, limitAmount];
}
