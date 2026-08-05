import 'package:cunehat/core/onboarding/backup_offer_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool offer({
    bool alreadyOffered = false,
    bool autoBackupEnabled = false,
    int transactionCount = BackupOfferPrompt.minTransactions,
  }) {
    return BackupOfferPrompt.shouldOffer(
      alreadyOffered: alreadyOffered,
      autoBackupEnabled: autoBackupEnabled,
      transactionCount: transactionCount,
    );
  }

  test('eşiğe ulaşan, yedeksiz ve daha önce sorulmamış kullanıcıya sorulur',
      () {
    expect(offer(), isTrue);
  });

  test('bir kez sorulduktan sonra bir daha sorulmaz', () {
    expect(offer(alreadyOffered: true), isFalse);
  });

  test('otomatik yedekleme zaten açıksa sorulmaz', () {
    expect(offer(autoBackupEnabled: true), isFalse);
  });

  // Teklifin tek şansı var; sıfır veriyle sorulup refleksle kapatılırsa
  // kullanıcı gerçekten veri biriktirdiğinde bir daha uyarılamaz.
  test('eşiğin altında sorulmaz', () {
    expect(offer(transactionCount: 0), isFalse);
    expect(offer(transactionCount: BackupOfferPrompt.minTransactions - 1),
        isFalse);
  });

  test('eşik dahildir', () {
    expect(offer(transactionCount: BackupOfferPrompt.minTransactions), isTrue);
    expect(offer(transactionCount: BackupOfferPrompt.minTransactions + 100),
        isTrue);
  });

  test('daha önce sorulmuş olmak eşik aşılsa da baskındır', () {
    expect(offer(alreadyOffered: true, transactionCount: 9999), isFalse);
  });
}
