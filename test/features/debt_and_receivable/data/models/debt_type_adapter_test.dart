import 'package:cunehat/features/debt_and_receivable/data/models/debt_type_adapter.dart';
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
}
