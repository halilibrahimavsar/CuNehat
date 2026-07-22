import 'package:cunehat/features/bank_import/data/pdf_parsers/default_heuristic_pdf_parser.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultHeuristicPdfParser (PDF satır-sezgisel)', () {
    test('tarih + ilk tutar (bakiye değil) alınır, işaret yönü belirler', () {
      const text = 'HESAP EKSTRESİ\n'
          '15.06.2026 MARKET ALISVERISI -150,00 1.850,00\n'
          '16/06/2026 MAAS ODEME +5.000,00 6.850,00\n';
      final drafts = const DefaultHeuristicPdfParser().parseLines(text).drafts;
      expect(drafts.length, 2);
      expect(drafts[0].date, DateTime(2026, 6, 15));
      expect(drafts[0].description, 'MARKET ALISVERISI');
      expect(drafts[0].amount, 150.0);
      expect(drafts[0].type, TransactionTypeModel.expense);
      expect(drafts[1].amount, 5000.0);
      expect(drafts[1].type, TransactionTypeModel.income);
    });

    test('işaretsiz tutar gider varsayılır (kullanıcı düzeltir)', () {
      const text = '17.06.2026 FATURA ODEMESI 200,00\n';
      final drafts = const DefaultHeuristicPdfParser().parseLines(text).drafts;
      expect(drafts.single.amount, 200.0);
      expect(drafts.single.type, TransactionTypeModel.expense);
    });

    test(
        'tarihsiz / tutarsız satırlar atlanır (taslak yoksa eklenecek yer de yok)',
        () {
      const text = 'Hesap Özeti\n'
          'Müşteri No 12345\n'
          '18.06.2026 Sadece açıklama, tutar yok\n';
      final result = const DefaultHeuristicPdfParser().parseLines(text);
      expect(result.drafts, isEmpty);
      expect(result.skippedLines, 1); // tarihli ama tutarsız satır
    });

    test('muhasebe parantezi gider', () {
      const text = '19.06.2026 IADE (75,00)\n';
      final drafts = const DefaultHeuristicPdfParser().parseLines(text).drafts;
      expect(drafts.single.amount, 75.0);
      expect(drafts.single.type, TransactionTypeModel.expense);
    });

    test('sondaki eksi (TR borç işareti) gider olur', () {
      const text = '20.06.2026 EFT GONDERME 500,00-\n';
      final drafts = const DefaultHeuristicPdfParser().parseLines(text).drafts;
      expect(drafts.single.amount, 500.0);
      expect(drafts.single.type, TransactionTypeModel.expense);
    });

    test('Akbank düzeni: İngiliz format, tutar+bakiye, borç işaretli', () {
      // Gerçek layout: tarih, tür, açıklama, TUTAR, BAKİYE (virgül binlik).
      const text =
          '25/03/2026 FEFT Transfer İşlemleri - Gönderen HALIL 6,500.00 7,958.43\n'
          '25/03/2026 MB Transfer İşlemleri - Alıcı Midas -7,000.00 958.43\n'
          '25/03/2026 POS Kart İşlemleri - 000000003598401-DEMIR MARKET ISTANBUL -67.00 891.43\n'
          '26/03/2026 POS Kart İşlemleri - 000000000713593-SHELL ACIBADEM -293.62 597.81\n';
      final drafts = const DefaultHeuristicPdfParser().parseLines(text).drafts;
      expect(drafts.length, 4);

      // Bakiye (7,958.43) DEĞİL tutar (6,500.00); milyarlık birleşme YOK.
      expect(drafts[0].amount, 6500.00);
      expect(drafts[0].type, TransactionTypeModel.income); // işaretsiz = alacak
      expect(drafts[1].amount, 7000.00);
      expect(drafts[1].type, TransactionTypeModel.expense); // -7,000.00
      expect(drafts[2].amount, 67.00);
      expect(drafts[2].type, TransactionTypeModel.expense);
      expect(drafts[3].amount, 293.62);
      expect(drafts[3].type, TransactionTypeModel.expense);
    });

    test(
        'REGRESYON (gerçek QNB ekstresi): gelir satırının Tutar/Bakiye\'si '
        'sarılmış devam satırındaysa yine gelir olarak çıkar, gidere '
        'düşmez/kaybolmaz', () {
      // Kullanıcının gerçek PDF'inden (syncfusion layoutText çıktısı bu
      // şekle yakın): uzun "Gönderen/Alıcı" açıklaması ikinci fiziksel
      // satıra sarıyor VE Tutar/Bakiye o ikinci satırda — tarih satırında
      // DEĞİL. Önceki tasarım bu satırı ya tamamen kaybediyor ya da bir
      // önceki (ilgisiz) taslağın açıklamasına karıştırıyordu.
      const text = '''
İşlem Tarihi Kanal* İşlem Açıklaması Tutar Bakiye
DEVREDEN BAKİYE 0.00
28/01/2026 FEFT Transfer İşlemleri - Gönderen: AHMET YILMAZ Sorgu No: 5526000114 - KREDİ BORCU
Türkiye Garanti Bankası A.Ş. 10,000.00 10,000.00
28/01/2026 FEFT Kart İşlemleri - Kredi Kartları Otomatik Tahsilat -9,451.00 549.00
28/01/2026 FEFT Kart İşlemleri - Kredi Kartları Otomatik Tahsilat -549.00 0.00
04/03/2026 FEFT Transfer İşlemleri - Gönderen: HALİL İBRAHİM AVŞAR Sorgu No: 2076317 - 999/4888152-
Halil İbrahim Avşa Akbank T.A.Ş. 2,000.00 2,009.99
''';
      final result = const DefaultHeuristicPdfParser().parseLines(text);
      final drafts = result.drafts;

      expect(drafts.length, 4);

      // Sarılmış devam satırındaki gelir (10,000.00) doğru yakalanmalı.
      expect(drafts[0].date, DateTime(2026, 1, 28));
      expect(drafts[0].amount, 10000.00);
      expect(drafts[0].type, TransactionTypeModel.income);
      expect(drafts[0].description, contains('AHMET YILMAZ'));
      expect(drafts[0].description, contains('Türkiye Garanti Bankası A.Ş.'));

      // Aradaki iki tek-satırlık gider bozulmadan kalmalı.
      expect(drafts[1].amount, 9451.00);
      expect(drafts[1].type, TransactionTypeModel.expense);
      expect(drafts[2].amount, 549.00);
      expect(drafts[2].type, TransactionTypeModel.expense);

      // İkinci sarılmış gelir satırı da (2,000.00) doğru yakalanmalı; devam
      // satırındaki "Halil İbrahim Avşa Akbank T.A.Ş." metni açıklamaya
      // eklenmiş olmalı, önceki gider taslağına KARIŞMAMALI.
      expect(drafts[3].date, DateTime(2026, 3, 4));
      expect(drafts[3].amount, 2000.00);
      expect(drafts[3].type, TransactionTypeModel.income);
      expect(
          drafts[3].description, contains('Halil İbrahim Avşa Akbank T.A.Ş.'));
      // Önceki gider taslağının açıklaması kirlenmemiş olmalı.
      expect(drafts[2].description, isNot(contains('Akbank')));
    });

    test(
        'REGRESYON: Tutar+Bakiye arasında boşluk yoksa (bitişik) TR-biçim '
        'yanlışlıkla köprü kurup tutarı 1000 kat büyütmez', () {
      // Gerçek cihazda görülen kusur: "-263.44" (Tutar) ile "3,902.50"
      // (Bakiye) arasında hiç boşluk yoksa "-263.443,902.50" oluşuyor; eski
      // regex bunu TEK TR-biçim sayı sanıp -263443.90 döndürüyordu (2 basamak
      // "44" + bakiyenin ilk hanesi "3" tam 3 haneye denk geldiği için).
      // Belgede yalnız İngilizce (virgül-binlik) sayılar olduğundan artık
      // yalnız o biçim aranıyor; TR-biçim alternatifi hiç denenmediği için
      // köprü kuramaz.
      const text =
          '19/07/2026 POS Kart İşlemleri - MAGAZA ISTANBUL TR Pos satış. -263.443,902.50\n'
          '20/07/2026 POS Kart İşlemleri - BASKA MAGAZA TR Pos satış. -100.00 3,802.50\n';
      final drafts = const DefaultHeuristicPdfParser().parseLines(text).drafts;

      expect(drafts.length, 2);
      expect(drafts[0].amount, 263.44); // DEĞİL 263443.90
      expect(drafts[0].type, TransactionTypeModel.expense);
      expect(drafts[1].amount, 100.00);
    });

    test('moneyPatternFor: belge TR-biçimiyse bitişik durumda da doğru ayrışır',
        () {
      // Simetri kontrolü: belge TAMAMEN TR biçimindeyse (nokta-binlik/virgül-
      // ondalık), bitişik Tutar+Bakiye yine köprü kurmadan doğru ayrılmalı.
      const text = '19.07.2026 ISLEM ACIKLAMASI -1.234,561.890,12\n'
          '20.07.2026 BASKA ISLEM -500,00 1.390,12\n';
      final drafts = const DefaultHeuristicPdfParser().parseLines(text).drafts;

      expect(drafts.length, 2);
      expect(drafts[0].amount, 1234.56); // DEĞİL 1234561.890 vb.
      expect(drafts[1].amount, 500.00);
    });
  });
}
