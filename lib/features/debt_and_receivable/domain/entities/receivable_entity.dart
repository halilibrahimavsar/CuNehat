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

  /// Alacağın deftere yazıldığı an. Silmede ters kayıt bu tarihe yazılır ki
  /// para verilen ay kendi içinde sıfırlansın; [dueDate] gelecekteki beklenen
  /// tahsilat tarihidir ve bu iş için kullanılamaz.
  final DateTime createdAt;

  /// Tahsilatın deftere yazıldığı an; henüz tahsil edilmemişse `null`.
  ///
  /// Tutar düzeltmesinin tahsilat bacağı bu tarihe yazılır. Kaydedilmediği
  /// sürece düzeltmenin iki bacağı farklı dönemlere düşüyordu: alacak bacağı
  /// [createdAt]'e, tahsilat bacağı ise "bugüne".
  final DateTime? collectedAt;

  const ReceivableEntity({
    this.id,
    required this.userId,
    required this.walletId,
    required this.debtorName,
    required this.amount,
    required this.dueDate,
    required this.createdAt,
    this.collectedAt,
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
    DateTime? createdAt,
    DateTime? collectedAt,
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
      createdAt: createdAt ?? this.createdAt,
      collectedAt: collectedAt ?? this.collectedAt,
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
        createdAt,
        collectedAt,
        isPaid,
        notes,
      ];
}
