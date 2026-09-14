import 'package:cunehat/core/services/system_activity_guard.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/pdf_rasterizer.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/data/statement_ocr_service.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReader extends Mock implements RawTableReader {}

class _MockMapper extends Mock implements ColumnMapper {}

class _MockPdf extends Mock implements PdfStatementParser {}

class _MockRasterizer extends Mock implements PdfRasterizer {}

class _MockOcr extends Mock implements StatementOcrService {}

class _MockGuesser extends Mock implements CategoryGuesser {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

class _MockWalletCategories extends Mock implements WalletCategoryService {}

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockMetrics extends Mock implements WalletMetricsService {}

class _MockNotifier extends Mock implements TransactionsChangedNotifier {}

/// Depolama izni reddedilmiş bir cihazdaki seçici gibi davranır.
class _ThrowingFilePicker extends FilePickerPlatform {
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
    bool cancelUploadOnWindowBlur = true,
    AndroidSAFOptions? androidSafOptions,
  }) async {
    throw PlatformException(code: 'read_external_storage_denied');
  }
}

void main() {
  // Depolama izni ya da sağlayıcı hatası eklentiden istisna olarak gelir.
  // Eskiden `pickAndParse` bunu yakalamıyordu: "dosya seç" düğmesi sessizce
  // hiçbir şey yapmıyordu.
  test('dosya seçici hata verirse akış hata ekranına geçer', () async {
    FilePickerPlatform.instance = _ThrowingFilePicker();
    final cubit = BankImportCubit(
      _MockReader(),
      _MockMapper(),
      _MockPdf(),
      _MockRasterizer(),
      _MockOcr(),
      _MockGuesser(),
      _MockCategoryRepo(),
      _MockWalletCategories(),
      _MockTxRepo(),
      _MockMetrics(),
      _MockNotifier(),
      SystemActivityGuard(),
    );
    addTearDown(cubit.close);

    await cubit.pickAndParse(userId: 'u1', walletId: 'w1');

    final state = cubit.state;
    expect(state, isA<BankImportError>());
    expect((state as BankImportError).message, contains('Dosya seçilemedi'));
  });
}
