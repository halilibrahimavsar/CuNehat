import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionEntity _tx(String title, String tag, {bool income = false}) =>
    TransactionEntity(
      id: title,
      userId: 'u',
      walletId: 'w',
      title: title,
      tag: tag,
      amount: 10,
      date: DateTime(2026, 1, 1),
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
    );

CategoryEntity _cat(String id, {bool expense = true}) => CategoryEntity(
      id: id,
      name: id,
      iconName: 'x',
      isExpense: expense,
      sortOrder: 1,
    );

void main() {
  final guesser = CategoryGuesser();

  group('guessFromHistory', () {
    test('geçmişte aynı marka nasıl kategorize edildiyse onu döner', () {
      final index = guesser.buildHistoryIndex([
        _tx('MIGROS KADIKOY', 'Market'),
        _tx('MIGROS BESIKTAS', 'Market'),
      ]);
      final r = guesser.guessFromHistory(
        description: 'MIGROS ATASEHIR',
        isIncome: false,
        index: index,
        candidates: [_cat('Market'), _cat('Yemek')],
      );
      expect(r, 'Market');
    });

    test('mağaza koduna tire ile bitişik marka da (SOK-10419) eşleşir', () {
      final index = guesser.buildHistoryIndex([
        _tx('SOK-11223-USKUDAR', 'Market'),
      ]);
      final r = guesser.guessFromHistory(
        description: 'SOK-99887-KADIKOY',
        isIncome: false,
        index: index,
        candidates: [_cat('Market')],
      );
      expect(r, 'Market'); // sayısal kod farklı ama 'sok' token'ı ortak
    });

    test('kategori artık listede yoksa (silinmiş) null döner', () {
      final index = guesser.buildHistoryIndex([_tx('MIGROS', 'Market')]);
      final r = guesser.guessFromHistory(
        description: 'MIGROS',
        isIncome: false,
        index: index,
        candidates: [_cat('Yemek')], // 'Market' yok
      );
      expect(r, isNull);
    });

    test('gelir/gider ayrı: gider geçmişi gelir tahminini etkilemez', () {
      final index = guesser.buildHistoryIndex([
        _tx('ACME LTD', 'Market'), // gider
      ]);
      final r = guesser.guessFromHistory(
        description: 'ACME LTD',
        isIncome: true, // gelir tarafı
        index: index,
        candidates: [_cat('Maaş', expense: false)],
      );
      expect(r, isNull);
    });

    test('jenerik/stopword token yanlış eşleşme yapmaz', () {
      final index = guesser.buildHistoryIndex([
        _tx('POS ODEME', 'Market'),
      ]);
      final r = guesser.guessFromHistory(
        description: 'POS ODEME',
        isIncome: false,
        index: index,
        candidates: [_cat('Market')],
      );
      expect(r, isNull); // 'pos'/'odeme' stopword → anlamlı token yok
    });

    test('en çok kullanılan kategori kazanır (frekans)', () {
      final index = guesser.buildHistoryIndex([
        _tx('AKARYAKIT SHELL', 'Ulaşım'),
        _tx('AKARYAKIT SHELL', 'Ulaşım'),
        _tx('AKARYAKIT MARKET', 'Market'),
      ]);
      final r = guesser.guessFromHistory(
        description: 'AKARYAKIT DEPO',
        isIncome: false,
        index: index,
        candidates: [_cat('Ulaşım'), _cat('Market')],
      );
      expect(r, 'Ulaşım'); // 'akaryakit' 2× Ulaşım, 1× Market
    });

    group('REGRESYON: bankanın kalıbı kategori taşımaz (ölçüldü, 11 Eyl)', () {
      // Eski sürüm açıklamayla paylaşılan HER token'ı oy sayıyordu. Gerçek
      // ekstrelerde her satır bankanın kalıbını taşır; ilk ekstre doğru
      // kategorize edilse bile ikinci ekstrede QNB'de 82 satırın 36'sı,
      // Garanti'de 43 satırın 25'i yanlış kategori alıyordu.

      test(
          'QNB: yeni üye işyeri "POS Kart İşlemleri … ISTANBUL" yüzünden '
          'Market olmaz', () {
        final index = guesser.buildHistoryIndex([
          for (var i = 0; i < 3; i++)
            _tx(
                'POS Kart İşlemleri - 2548298 -MIGROS-ACIBADEM KONAKLAR '
                    'ISTANBUL TR Pos satış.',
                'Market'),
        ]);
        final r = guesser.guessFromHistory(
          description: 'POS Kart İşlemleri - 000000000287101-SUDE MOTOR '
              'ISTANBUL TR Pos satış.',
          isIncome: false,
          index: index,
          candidates: [_cat('Market'), _cat('Ulaşım')],
        );
        expect(r, isNull, reason: 'eskiden: Market (kart/islemleri/satis)');
      });

      test('QNB: fatura kalıbı sözlüğün doğru bildiğini ezmez', () {
        // Eskiden Enerjisa satırı, geçmişteki Türk Telekom satırlarıyla
        // paylaştığı "Ödeme İşlemleri … tahsilatı. Mobil Bankacılık."
        // yüzünden Telefon'a gidiyordu — ve geçmiş sözlükten ÖNCE denendiği
        // için sözlüğün "elektrik" cevabı hiç sorulmuyordu.
        final index = guesser.buildHistoryIndex([
          for (var i = 0; i < 3; i++)
            _tx(
                'MB Ödeme İşlemleri - 5380283083 - Türk Telekom Mobil '
                    '(TT Mobil)-Faturalı Hat tahsilatı. Mobil Bankacılık.',
                'Telefon'),
        ]);
        final r = guesser.guessFromHistory(
          description: 'MB Ödeme İşlemleri - 001006006401 - Enerjisa Ayesaş '
              'tahsilatı. Mobil Bankacılık.',
          isIncome: false,
          index: index,
          candidates: [_cat('Telefon'), _cat('Elektrik')],
        );
        expect(r, isNull);
      });

      test(
          'Garanti: "SATIŞ-517040*4626-" öneki tüm kartları tek kategoriye '
          'çekmez', () {
        final index = guesser.buildHistoryIndex([
          for (var i = 0; i < 4; i++)
            _tx('SATIŞ-517040*4626-TRENDYOL.COM', 'Alışveriş'),
        ]);
        final r = guesser.guessFromHistory(
          description: 'SATIŞ-517040*4626-DEVA ECZANESI',
          isIncome: false,
          index: index,
          candidates: [_cat('Alışveriş'), _cat('İlaç')],
        );
        expect(r, isNull, reason: 'eskiden: Alışveriş (satis)');
      });

      test(
          'listede olmayan bir bankanın kalıbı ekstrenin kendisinden '
          'yakalanır', () {
        // "KARTLI ALIMI" kalıp listesinde yok; ama ekstrenin satırlarının
        // çoğunda geçtiği için üye işyeri sayılmaz.
        final statement = [
          for (var i = 0; i < 12; i++) 'KARTLI ALIMI - ISLETME $i',
        ];
        final index = guesser.buildHistoryIndex(
          [_tx('KARTLI ALIMI - MIGROS', 'Market')],
          statementTexts: statement,
        );
        final r = guesser.guessFromHistory(
          description: 'KARTLI ALIMI - YENI DUKKAN',
          isIncome: false,
          index: index,
          candidates: [_cat('Market')],
        );
        expect(r, isNull);
      });
    });

    test('tutarsız token (semt adı) kanıt sayılmaz', () {
      final index = guesser.buildHistoryIndex([
        _tx('SHELL ACIBADEM', 'Yakıt'),
        _tx('MIGROS ACIBADEM', 'Market'),
      ]);
      final r = guesser.guessFromHistory(
        description: 'YENI DUKKAN ACIBADEM',
        isIncome: false,
        index: index,
        candidates: [_cat('Yakıt'), _cat('Market')],
      );
      expect(r, isNull, reason: '"acibadem" iki kategoriye yarı yarıya');
    });

    test('karışık kelime başta dursa da tek anlamlı kelimeyi yenmez', () {
      // Gerçek QNB: "telekom" hem mobil hat (Telefon) hem TTNET (İnternet)
      // faturasında geçiyor; ayırt eden "ttnet".
      final index = guesser.buildHistoryIndex([
        for (var i = 0; i < 3; i++)
          _tx('Türk Telekom Mobil (TT Mobil)-Faturalı Hat', 'Telefon'),
        for (var i = 0; i < 2; i++)
          _tx('Türk Telekom İnternet/TV (TTNET)', 'İnternet'),
      ]);
      final r = guesser.guessFromHistory(
        description: 'MB Ödeme İşlemleri - 7019233814 - Türk Telekom '
            'İnternet/TV (TTNET) tahsilatı. Mobil Bankacılık.',
        isIncome: false,
        index: index,
        candidates: [_cat('Telefon'), _cat('İnternet')],
      );
      expect(r, 'İnternet');
    });

    test('üye işyeri adı (başta) sık görülen semt adını (arkada) yener', () {
      // Hep aynı istasyondan yakıt alan kullanıcı: "ACIBADEM" geçmişte hep
      // Yakıt. Bir kez görülmüş "BIM" yine de öne geçmeli.
      final index = guesser.buildHistoryIndex([
        for (var i = 0; i < 10; i++) _tx('SHELL ACIBADEM', 'Yakıt'),
        _tx('BIM KADIKOY', 'Market'),
      ]);
      final r = guesser.guessFromHistory(
        description: 'BIM V365 ACIBADEM',
        isIncome: false,
        index: index,
        candidates: [_cat('Yakıt'), _cat('Market')],
      );
      expect(r, 'Market');
    });

    test('kullanıcının kendi tercihi korunur (sözlükten farklı olsa da)', () {
      // Kullanıcı MIGROS'u "Ev" altında tutuyor: geçmiş bunu öğretmeli.
      final index = guesser.buildHistoryIndex([
        _tx(
            'POS Kart İşlemleri - 2548298 -MIGROS-ACIBADEM ISTANBUL TR Pos '
                'satış.',
            'Ev'),
      ]);
      final r = guesser.guessFromHistory(
        description: 'POS Kart İşlemleri - 999 -MIGROS-KADIKOY ISTANBUL TR Pos '
            'satış.',
        isIncome: false,
        index: index,
        candidates: [_cat('Ev'), _cat('Market')],
      );
      expect(r, 'Ev');
    });

    test('sistem işlemleri (isSystem) indekse girmez', () {
      final index = guesser.buildHistoryIndex([
        TransactionEntity(
          id: 't',
          userId: 'u',
          walletId: 'w',
          title: 'MIGROS TRANSFER',
          tag: 'Transfer',
          amount: 10,
          date: DateTime(2026, 1, 1),
          type: TransactionTypeModel.expense,
          isSystem: true,
        ),
      ]);
      expect(index.isEmpty, isTrue);
    });
  });
}
