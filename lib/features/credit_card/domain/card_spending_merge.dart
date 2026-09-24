import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// Hesabın raporuna bağlı kartlarının HARCAMALARINI katar ("kartlar dahil").
///
/// - Kartların kendi sistem hareketleri (karta gelen ödeme bacakları)
///   katılmaz: harcama değildir.
/// - Hesabın o kartlara yaptığı ödeme bacakları ÇIKARILIR (çift kimliği
///   [TransactionEntity.linkedRecordId] kartın defterindeki bacakla eşleşen
///   sistem hareketi): aynı para hem karttaki harcama hem hesaptaki ödeme
///   olarak iki kez sayılırdı ("sistem hareketlerini dahil et" açıkken).
///   Başka cüzdanlara transferlere dokunulmaz.
///
/// Bakiye çizgisi bu listeyle ÇİZİLMEZ: kart harcaması hesabın bakiyesini
/// değiştirmez; bakiye hep hesabın kendi defterinden türer.
List<TransactionEntity> mergeCardSpending({
  required List<TransactionEntity> account,
  required List<TransactionEntity> cards,
}) {
  final cardPairs = <String>{
    for (final t in cards)
      if (t.isSystem && t.linkedRecordId != null) t.linkedRecordId!,
  };
  return [
    for (final t in account)
      if (!(t.isSystem && cardPairs.contains(t.linkedRecordId))) t,
    for (final t in cards)
      if (!t.isSystem) t,
  ];
}
