import 'package:equatable/equatable.dart';

import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';

/// Banka ekstresinden çıkarılan tek bir hareket taslağı. Format-bağımsız ortak
/// birim: CSV/Excel (kolon eşleme) ve PDF (satır-sezgisel) yolları hep bunu üretir.
///
/// [amount] daima POZİTİF ve kuruşa yuvarlı; yön [type] ile taşınır (banka
/// ekstresinde işaret/borç-alacak ayrıştırıcıda çözülür). İnceleme adımında
/// [selected]/[type]/[categoryId] kullanıcı tarafından değiştirilebilir.
class ImportDraft extends Equatable {
  final DateTime date;
  final String description;
  final double amount;
  final TransactionTypeModel type;

  /// Atanan kategori (tag). Toplu varsayılandan gelir, satır bazında düzenlenir.
  final String? categoryId;

  /// Bankanın ekstrede verdiği KENDİ kategori etiketi ("Alışveriş",
  /// "Para Çekme", "Maaş"…). Yalnız kategori tahmininde ipucu olarak
  /// kullanılır; işleme yazılmaz. Ekstrede böyle bir sütun yoksa `null`.
  final String? sourceTag;

  /// Bankanın hareket referansı (dekont/fiş/işlem no). Ekstre içinde bir
  /// hareketi KESİN olarak tanımlar; gün+tutar+açıklama sezgisinin aksine
  /// kullanıcı düzenlemesinden ve biçim farklarından etkilenmez.
  /// Sütun yoksa `null`. Deftere de yazılır ([toEntity]) — içe aktarımlar
  /// ARASI tekrar tespiti buna dayanır (bkz. `markDuplicateDrafts`).
  final String? reference;

  /// Dedup tarafından mevcut cüzdanda ya da dosya içinde eşi bulunduysa true.
  final bool isDuplicate;

  /// İçe aktarılacak mı (tekrarlar varsayılan false gelir).
  final bool selected;

  const ImportDraft({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    this.categoryId,
    this.sourceTag,
    this.reference,
    this.isDuplicate = false,
    this.selected = true,
  });

  bool get isIncome => type == TransactionTypeModel.income;

  ImportDraft copyWith({
    DateTime? date,
    String? description,
    double? amount,
    TransactionTypeModel? type,
    String? categoryId,
    String? sourceTag,
    String? reference,
    bool? isDuplicate,
    bool? selected,
  }) {
    return ImportDraft(
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      sourceTag: sourceTag ?? this.sourceTag,
      reference: reference ?? this.reference,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      selected: selected ?? this.selected,
    );
  }

  /// Toplu yazımda kalıcı işleme dönüştürür. [id] çağıran tarafından üretilir
  /// (UUIDv7); ham repo [id] null kabul etmez.
  ///
  /// Başlık boşsa [categoryName]'e düşer — kategori kimliği UUID olduğundan
  /// onu basmak başlığa anlamsız bir dizgi yazardı.
  TransactionEntity toEntity({
    required String id,
    required String userId,
    required String walletId,
    String? categoryName,
  }) {
    final title = description.trim().isEmpty
        ? (categoryName ?? 'İşlem')
        : description.trim();
    return TransactionEntity(
      id: id,
      userId: userId,
      walletId: walletId,
      title: title,
      tag: categoryId ?? '',
      amount: amount,
      date: date,
      type: type,
      isSystem: false,
      reference: reference,
    );
  }

  @override
  List<Object?> get props => [
        date,
        description,
        amount,
        type,
        categoryId,
        sourceTag,
        reference,
        isDuplicate,
        selected,
      ];
}
