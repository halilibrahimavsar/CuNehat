import 'package:equatable/equatable.dart';

class ReceivableEntity extends Equatable {
  final String? id;
  final String userId;
  final String walletId;
  final String debtorName; // Borçlu Kişi Adı (UI: Title)
  final double amount;
  final DateTime dueDate; // Beklenen Tarih
  final bool isPaid;
  final String? notes;

  const ReceivableEntity({
    this.id,
    required this.userId,
    required this.walletId,
    required this.debtorName,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.notes,
  });

  ReceivableEntity copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? debtorName,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
    String? notes,
  }) {
    return ReceivableEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      debtorName: debtorName ?? this.debtorName,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        debtorName,
        amount,
        dueDate,
        isPaid,
        notes,
      ];
}
