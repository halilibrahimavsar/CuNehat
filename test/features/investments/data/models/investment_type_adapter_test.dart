import 'package:cunehat/features/investments/data/models/investment_type_adapter.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBinaryReader extends Mock implements BinaryReader {}

class MockBinaryWriter extends Mock implements BinaryWriter {}

void main() {
  late InvestmentTypeAdapter adapter;
  late MockBinaryReader mockReader;
  late MockBinaryWriter mockWriter;

  setUp(() {
    adapter = InvestmentTypeAdapter();
    mockReader = MockBinaryReader();
    mockWriter = MockBinaryWriter();
  });

  group('InvestmentTypeAdapter', () {
    test('has correct typeId', () {
      expect(adapter.typeId, 5);
    });

    test('read returns correct InvestmentType when index is valid', () {
      for (final type in InvestmentType.values) {
        when(() => mockReader.readByte()).thenReturn(type.index);
        final result = adapter.read(mockReader);
        expect(result, type);
      }
    });

    test('read returns InvestmentType.custom when index is out of bounds', () {
      when(() => mockReader.readByte())
          .thenReturn(InvestmentType.values.length + 10);
      final result = adapter.read(mockReader);
      expect(result, InvestmentType.custom);
    });

    test('write writes the correct byte value', () {
      for (final type in InvestmentType.values) {
        when(() => mockWriter.writeByte(type.index)).thenReturn(null);
        adapter.write(mockWriter, type);
        verify(() => mockWriter.writeByte(type.index)).called(1);
      }
    });
  });
}
