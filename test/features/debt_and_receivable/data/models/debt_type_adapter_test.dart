import 'package:cunehat/features/debt_and_receivable/data/models/debt_calc_mode_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_type_adapter.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBinaryReader extends Mock implements BinaryReader {}

class MockBinaryWriter extends Mock implements BinaryWriter {}

void main() {
  late DebtTypeAdapter adapter;
  late MockBinaryReader mockReader;
  late MockBinaryWriter mockWriter;

  setUp(() {
    adapter = DebtTypeAdapter();
    mockReader = MockBinaryReader();
    mockWriter = MockBinaryWriter();
  });

  group('DebtTypeAdapter', () {
    test('has correct typeId', () {
      expect(adapter.typeId, 10);
    });

    test('read returns correct DebtType when index is valid', () {
      for (final type in DebtType.values) {
        when(() => mockReader.readByte()).thenReturn(type.index);
        final result = adapter.read(mockReader);
        expect(result, type);
      }
    });

    test('read returns DebtType.otherDebt when index is out of bounds', () {
      when(() => mockReader.readByte()).thenReturn(DebtType.values.length + 10);
      final result = adapter.read(mockReader);
      expect(result, DebtType.otherDebt);
    });

    test('write writes the correct byte value', () {
      for (final type in DebtType.values) {
        when(() => mockWriter.writeByte(type.index)).thenReturn(null);
        adapter.write(mockWriter, type);
        verify(() => mockWriter.writeByte(type.index)).called(1);
      }
    });
  });

  group('DebtCalcModeAdapter', () {
    late DebtCalcModeAdapter calcAdapter;

    setUp(() => calcAdapter = DebtCalcModeAdapter());

    test('has correct typeId', () {
      expect(calcAdapter.typeId, 14);
    });

    // Diske enum INDEX'i yazılıyor: üye sırası kalıcı şemadır. Araya üye
    // eklemek ya da sırayı değiştirmek, kayıtlı borçların hesap yöntemini
    // sessizce başka bir moda çevirir. Yeni üye yalnız SONA eklenmeli.
    test('üye sırası kilitli (diskteki index anlamı)', () {
      expect(DebtCalcMode.values.map((m) => m.name).toList(), [
        'none',
        'fixedInstallment',
        'amortized',
        'amortizedWithTaxes',
        'flatSurcharge',
        'simpleMonthlyInterest',
      ]);
    });

    test('read geçerli index için doğru modu döndürür', () {
      for (final mode in DebtCalcMode.values) {
        when(() => mockReader.readByte()).thenReturn(mode.index);
        expect(calcAdapter.read(mockReader), mode);
      }
    });

    test('read sınır dışı index için güvenli varsayılana düşer', () {
      when(() => mockReader.readByte())
          .thenReturn(DebtCalcMode.values.length + 10);
      expect(calcAdapter.read(mockReader), DebtCalcMode.none);
    });

    test('write doğru baytı yazar', () {
      for (final mode in DebtCalcMode.values) {
        when(() => mockWriter.writeByte(mode.index)).thenReturn(null);
        calcAdapter.write(mockWriter, mode);
        verify(() => mockWriter.writeByte(mode.index)).called(1);
      }
    });

    test('usesInterestRate: yalnız oran kullanan modlarda true', () {
      expect(DebtCalcMode.none.usesInterestRate, isFalse);
      expect(DebtCalcMode.fixedInstallment.usesInterestRate, isFalse);
      expect(DebtCalcMode.amortized.usesInterestRate, isTrue);
      expect(DebtCalcMode.amortizedWithTaxes.usesInterestRate, isTrue);
      expect(DebtCalcMode.flatSurcharge.usesInterestRate, isTrue);
      expect(DebtCalcMode.simpleMonthlyInterest.usesInterestRate, isTrue);
    });
  });
}
