import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/foundation.dart';

/// Az önce ELLE eklenen kayıtların imzası: defter, o satırı listeye
/// yumuşakça alır (bkz. `FreshEntrance`).
///
/// Kayıt yazılırken kimliği henüz yoktur (`id: null`; kimliği veri katmanı
/// verir) ve defter boşken liste widget'ı hiç kurulu değildir — yani "yeni
/// satır hangisi?" sorusu ne kimlikle ne de listenin önceki hâliyle
/// yanıtlanabilir. Onun yerine form, kaydettiği şeyin İMZASINI buraya
/// bırakır; satır kurulurken imzası eşleşirse girişini bir kez oynatır.
///
/// İmza cüzdan + an (ms) + kuruş + kategori + türdür: Hive tarihi milisaniye
/// duyarlığında saklar, tutar kuruşa yuvarlanır; ikisi de buna göre
/// karşılaştırılır.
///
/// İşaret [lifetime] sonra kendiliğinden düşer: kayıt başka bir döneme
/// yazıldıysa satırı hiç kurulmaz ve imza sonsuza dek beklememelidir.
class FreshEntryMarker {
  FreshEntryMarker({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Uygulamanın tek örneği. Form yazar, defter okur.
  static final FreshEntryMarker instance = FreshEntryMarker();

  static const Duration lifetime = Duration(seconds: 5);

  /// Tek seferde en çok bu kadar satır canlanır (taksitli kayıtta ilk üçü).
  static const int maxMarks = 3;

  final DateTime Function() _now;
  final List<_Mark> _marks = [];

  bool get isEmpty => _marks.isEmpty;

  /// [transactions] az önce kaydedildi.
  void mark(Iterable<TransactionEntity> transactions) {
    _dropExpired();
    final at = _now();
    for (final t in transactions.take(maxMarks)) {
      _marks.add(_Mark(_signatureOf(t), at));
    }
    while (_marks.length > maxMarks) {
      _marks.removeAt(0);
    }
  }

  /// [transaction] az önce eklendiyse `true` döner ve işareti TÜKETİR:
  /// satır yeniden kurulduğunda (kaydırma, yeniden çizim) giriş tekrar
  /// oynamaz.
  bool consume(TransactionEntity transaction) {
    if (_marks.isEmpty) return false;
    _dropExpired();
    final signature = _signatureOf(transaction);
    final index = _marks.indexWhere((m) => m.signature == signature);
    if (index < 0) return false;
    _marks.removeAt(index);
    return true;
  }

  @visibleForTesting
  void clear() => _marks.clear();

  void _dropExpired() {
    final now = _now();
    _marks.removeWhere((m) => now.difference(m.at) > lifetime);
  }

  static String _signatureOf(TransactionEntity t) =>
      '${t.walletId}|${t.date.millisecondsSinceEpoch}|'
      '${(t.amount * 100).round()}|${t.tag}|${t.type.name}';
}

class _Mark {
  const _Mark(this.signature, this.at);

  final String signature;
  final DateTime at;
}
