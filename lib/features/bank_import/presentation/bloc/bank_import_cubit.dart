import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cunehat/core/blocs/safe_emit.dart';
import 'package:cunehat/core/constants/prefs_keys.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/services/system_activity_guard.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/draft_dedup.dart';
import 'package:cunehat/features/bank_import/data/layout/statement_layout_engine.dart';
import 'package:cunehat/features/bank_import/data/pdf_rasterizer.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/statement_ocr_service.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/data/statement_currency_detector.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:cunehat/features/bank_import/data/xls/biff8_reader.dart';
import 'package:cunehat/features/bank_import/data/xls/ole2_reader.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/domain/statement_format.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';

/// Banka ekstresi içe aktarma akışının durum makinesi.
///
/// pickAndParse → (CSV/Excel) kolon eşleme → applyMapping → dedup → inceleme →
/// commit (mevcut cüzdana toplu yazım: tek syncBalance + tek notify).
@injectable
class BankImportCubit extends Cubit<BankImportState>
    with SafeEmitMixin<BankImportState> {
  final RawTableReader _reader;
  final ColumnMapper _mapper;
  final PdfStatementParser _pdfParser;
  final PdfRasterizer _rasterizer;
  final StatementOcrService _ocr;
  final CategoryGuesser _guesser;
  final CategoryRepository _categoryRepo;

  /// Kategori kapsamı cüzdana bağlı: hem tahmin havuzu hem de onaylanan
  /// önerilerin görünürlüğü buradan geçer.
  final WalletCategoryService _walletCategories;
  final TransactionsRepository _txRepo;
  final WalletMetricsService _metrics;
  final TransactionsChangedNotifier _notifier;
  final SystemActivityGuard _systemActivity;

  BankImportCubit(
    this._reader,
    this._mapper,
    this._pdfParser,
    this._rasterizer,
    this._ocr,
    this._guesser,
    this._categoryRepo,
    this._walletCategories,
    this._txRepo,
    this._metrics,
    this._notifier,
    this._systemActivity,
  ) : super(const BankImportInitial());

  String _userId = '';
  String _walletId = '';

  /// İçe aktarımın hedef cüzdanı — inceleme ekranındaki kategori seçicileri
  /// kapsamlarını buradan alır (kategoriler cüzdana göre görünür).
  String get walletId => _walletId;
  List<CategoryEntity> _expenseCats = const [];
  List<CategoryEntity> _incomeCats = const [];

  /// Kullanıcının geçmişinden kurulan token→kategori indeksi. İnceleme
  /// başlarken bir kez kurulur ve SAKLANIR: satırın türü sonradan çevrilince
  /// (gider↔gelir) kategori yeniden tahmin edilirken de aynı öğrenilmiş bilgi
  /// kullanılır (bkz. [_guessCategory]).
  HistoryCategoryIndex? _historyIndex;

  /// Son PDF içe aktarımının çıkarılan ham metni (tanılama/paylaşım için).
  String? _lastPdfRawText;
  String? get lastPdfRawText => _lastPdfRawText;

  /// Son eşlemenin bakiye-mutabakat sonucu; inceleme durumuna taşınır.
  /// Bakiye sütunu olmayan ekstrelerde `null` kalır.
  BalanceReconciliation? _reconciliation;

  /// Ekstrenin KENDİ beyanlarıyla (bakiye zinciri, "N kayıt bulunmuştur",
  /// devreden/kapanış bakiyesi, Borç/Alacak toplamları) yapılan doğrulama.
  /// İnceleme ekranında "doğrulandı"/"doğrulanamadı" olarak gösterilir.
  StatementVerification _verification = StatementVerification.none;

  /// Ekstrede sezilen baskın para birimi (₺/$/€ ya da kod). Cüzdan biriminden
  /// farklıysa inceleme ekranında uyarı gösterilir; sinyal yoksa `null`.
  String? _statementCurrency;

  /// Kaynak dosyanın bütünlük şüphesi (şimdilik yalnız `.xls` yolu doldurur):
  /// akış kapanmadan bitti / bazı hücrelerin değeri çözülemedi. İnceleme
  /// ekranında uyarı olarak gösterilir.
  bool _sourceTruncated = false;
  int _sourceUnresolvedCells = 0;

  /// Taslaklar OCR'dan geldi (ekran görüntüsü / taranmış PDF): inceleme
  /// ekranında ayrıca uyarılır, çünkü bu yolda hata olasılığı belirgin
  /// biçimde yüksektir.
  bool _fromOcr = false;

  /// Son `commit`te GERÇEKTEN yazılan işlem id'leri; `_Done`'daki "Geri al"
  /// bu partiyi (yalnız az önce eklenenleri) siler. Oturum-içi (Hive alanı yok).
  List<String> _lastImportedIds = const [];

  /// Son `commit`te tutarı ekstredekiyle düzeltilen defter kayıtlarının
  /// DÜZELTME ÖNCEKİ hâlleri; "Geri al" bunları geri yazar.
  List<TransactionEntity> _lastCorrectedOriginals = const [];

  /// İncelemenin başında çekilen defter (id → kayıt). Yaklaşık eşleşmede
  /// "tutarı düzelt" kararı, kaydın TAMAMINI (kategori, not, fiş…) koruyarak
  /// yalnız tutarını değiştirmek için buradan okur.
  Map<String, TransactionEntity> _ledgerById = const {};

  /// Son CSV/Excel tablosu ve ona uygulanan eşleme. İnceleme ekranından
  /// "sütunları yeniden eşle" dönüşü bunlarla kurulur; PDF/OCR yolunda
  /// (eşlenecek tablo yok) `null`.
  RawTable? _lastTable;
  ColumnMapping? _lastMapping;

  /// Paylaş menüsünden gelen ekstrenin önbellekteki TEK KULLANIMLIK kopyası
  /// (bkz. `SharedStatementPlugin.kt`). Finansal belge: akış başa dönünce
  /// ([reset]) ya da cubit kapanınca silinir.
  String? _sharedFilePath;
  String? get sharedFilePath => _sharedFilePath;

  /// Paylaşılan dosyayı bu akışa bağlar; kurulum adımı dosya seçici yerine
  /// bunu kullanır. Dosya seçici yolu olduğu gibi durmaya devam eder.
  void attachSharedFile(String path) => _sharedFilePath = path;

  /// Dosya seç + biçimi uzantısından otomatik algıla + ayrıştır.
  /// CSV/Excel → kolon eşleme; PDF → doğrudan inceleme.
  Future<void> pickAndParse({
    required String userId,
    required String walletId,
  }) async {
    // Uzantı BAZLI süzme (FileType.custom) bilerek kullanılmıyor: Android'de
    // file_picker bunu `EXTRA_MIME_TYPES` MIME süzgecine çeviriyor ve SAF,
    // dosyayı sağlayıcının bildirdiği MIME'a göre eliyor. Banka uygulamasından/
    // tarayıcıdan inen ekstreler indirme sağlayıcısında sık sık
    // `application/octet-stream` olarak kayıtlı → uzantı doğru olmasına rağmen
    // dosya seçicide GRİ görünüyordu. Her şeyi seçilebilir yapıp biçimi
    // içerik imzasından kendimiz belirliyoruz (bkz. [detectStatementFormat]).
    // Seçici sistem etkinliğidir: uygulamayı duraklatır. Sarmalanmazsa PIN
    // açık kullanıcıda dönüşte kilit ekranı açılıyor, router bu sayfayı
    // yığından siliyor ve seçilen dosya hiç ayrıştırılmıyordu
    // (bkz. [SystemActivityGuard]).
    final picked = await _systemActivity
        .run(() => FilePicker.pickFiles(type: FileType.any));
    final path = picked?.files.single.path;
    if (path == null) {
      emit(const BankImportInitial());
      return;
    }
    await parseFile(userId: userId, walletId: walletId, path: path);
  }

  /// Belirli bir dosyayı ayrıştırır. Dosya seçici de, paylaş menüsünden gelen
  /// ekstre de buradan geçer — kaynak ne olursa olsun biçim tespiti, doğrulama
  /// ve inceleme akışı AYNIDIR.
  Future<void> parseFile({
    required String userId,
    required String walletId,
    required String path,
  }) async {
    _userId = userId;
    _walletId = walletId;
    _reconciliation = null;
    _verification = StatementVerification.none;
    _statementCurrency = null;
    _fromOcr = false;
    _lastTable = null;
    _lastMapping = null;

    final DetectedStatementFormat detected;
    try {
      detected = detectStatementFormat(path: path, head: await _readHead(path));
    } catch (e) {
      emit(BankImportError('Dosya okunamadı: $e'));
      return;
    }
    if (detected == DetectedStatementFormat.unknown) {
      emit(const BankImportUnsupportedFile());
      return;
    }
    final format = detected.supported!;

    emit(const BankImportParsing());
    try {
      // Tahmin havuzu da cüzdana bağlı: iş cüzdanına aktarılan bir ekstre,
      // o cüzdanda kapalı olan "Eğlence"yi önermemeli.
      _expenseCats = await _walletCategories.categoriesFor(
        walletId: walletId,
        isExpense: true,
      );
      _incomeCats = await _walletCategories.categoriesFor(
        walletId: walletId,
        isExpense: false,
      );

      // PDF'te kolon yapısı güvenilir değil → satır-sezgisel doğrudan taslak,
      // eşleme adımı atlanır, direkt incelemeye gider.
      if (format == StatementFormat.image) {
        await _parseFromOcr([path]);
        return;
      }

      if (format == StatementFormat.pdf) {
        final result = await _pdfParser.parse(path);
        final hasTextLayer = result.rawText.trim().isNotEmpty;
        // Yalnız gerçekten metin varsa sakla: aksi halde AppBar'daki "ham metni
        // göster" düğmesi boş bir diyalog açıyordu ("\r\n" boş string DEĞİL).
        _lastPdfRawText = hasTextLayer ? result.rawText : null;
        _statementCurrency = detectDominantCurrency(result.rawText);
        if (!hasTextLayer) {
          // Taranmış/fotoğraf PDF: metin katmanı yok. Sayfaları görüntüye
          // çevirip OCR'a veriyoruz; rasterleştirme yapılamıyorsa (Android
          // dışı platform, parolalı/bozuk PDF) açıklayıcı ekrana düşülür.
          await _parseScannedPdf(path);
          return;
        }
        if (result.drafts.isEmpty) {
          // Metin çıktı ama satır tanınamadı → ham metni tanılama için göster.
          emit(BankImportRawText(result.rawText));
          return;
        }
        _applyParseDiagnostics(result);
        await _afterParse(result.drafts, result.skippedLines);
        return;
      }

      _sourceTruncated = false;
      _sourceUnresolvedCells = 0;
      final RawTable table;
      switch (format) {
        case StatementFormat.csv:
          table = await _reader.readCsv(path);
        case StatementFormat.excel:
          table = await _reader.readExcel(path);
        case StatementFormat.legacyExcel:
          // Eski .xls kendi okuyucumuzdan geçer; açılamazsa (parola, BIFF5,
          // bozuk kap) kullanıcıya "dönüştür" yönergesi gösterilir.
          try {
            final result = await _reader.readXls(path);
            table = result.table;
            _sourceTruncated = result.truncated;
            _sourceUnresolvedCells = result.unresolvedCells;
          } on Ole2Exception catch (e) {
            emit(BankImportLegacyExcel(e.message));
            return;
          } on Biff8Exception catch (e) {
            emit(BankImportLegacyExcel(e.message));
            return;
          }
        case StatementFormat.pdf:
        case StatementFormat.image:
          // Bu ikisi yukarıda kendi yollarına ayrıldı; buraya düşemezler.
          throw StateError('unreachable');
      }
      if (table.isEmpty) {
        emit(const BankImportError('Dosya boş veya okunamadı.'));
        return;
      }
      final guess = _mapper.guess(table);
      // Aynı bankadan tekrar içe aktarımda kullanıcının daha önce düzelttiği
      // eşleme kullanılır — ama yalnız AYNI başlıklı dosyada (bkz.
      // [_loadSavedMapping]).
      final saved = await _loadSavedMapping(table, guess);
      final assessment = _mapper.assess(table, saved ?? guess);
      _lastTable = table;

      // "Sütunları eşle" ekranı yalnız GEREKTİĞİNDE: başlıklar tanındı,
      // satırlar okundu ve (varsa) bakiye tutuyorsa sonuç zaten doğrudur;
      // ekran kullanıcıya bir şey sormadan önce çözülmüş bir işi gösterip
      // teknik bir karar istiyordu. Gerçek dosyaların hepsi (Garanti .xls,
      // Akbank CSV) bu kapıdan geçiyor. Yanılırsak inceleme ekranından
      // "sütunları yeniden eşle" ile dönülür.
      if (assessment.isConfident(userConfirmed: saved != null)) {
        await _applyAssessed(table, assessment);
      } else {
        emit(BankImportMapping(table: table, assessment: assessment));
      }
    } catch (e) {
      emit(BankImportError('Dosya okunamadı: $e'));
    }
  }

  /// Taranmış PDF: sayfaları görüntüye çevirip OCR yoluna sok. Rasterleştirme
  /// başarısızsa (Android dışı platform, parolalı/bozuk PDF) kullanıcıya neden
  /// okunamadığını ve ne yapabileceğini söyleyen ekrana düşülür.
  Future<void> _parseScannedPdf(String path) async {
    if (!_rasterizer.isSupported) {
      emit(const BankImportScannedPdf());
      return;
    }
    try {
      final pages = await _rasterizer.rasterize(path);
      if (pages.isEmpty) {
        emit(const BankImportScannedPdf());
        return;
      }
      await _parseFromOcr(pages);
    } on PdfRasterException {
      emit(const BankImportScannedPdf());
    }
  }

  /// Görüntülerden (ekran görüntüsü / taranmış sayfa) OCR ile metin çıkarıp
  /// PDF yolundaki AYNI ayrıştırıcıya verir — banka stratejileri, işaret
  /// sezgisi ve etiket ayırma yeniden kullanılır.
  ///
  /// OCR en düşük güvenilirlikli yol: tutarlarda `,`/`.` ve `1`/`7` karışması
  /// tipiktir ve ekran görüntüsünde bakiye sütunu çoğu zaman bulunmaz, yani
  /// mutabakat güvenlik ağı da devrede olmaz. Bu yüzden inceleme ekranında
  /// [BankImportReview.fromOcr] ile ayrıca uyarılır.
  Future<void> _parseFromOcr(List<String> imagePaths) async {
    final words = await _ocr.extractWords(imagePaths);
    if (words.isEmpty) {
      _lastPdfRawText = null;
      emit(const BankImportScannedPdf());
      return;
    }
    final result = _pdfParser.parseWords(words);
    _lastPdfRawText = result.rawText.trim().isEmpty ? null : result.rawText;
    _statementCurrency = detectDominantCurrency(result.rawText);
    if (result.drafts.isEmpty) {
      emit(BankImportRawText(result.rawText));
      return;
    }
    _fromOcr = true;
    _applyParseDiagnostics(result);
    await _afterParse(result.drafts, result.skippedLines);
  }

  /// PDF/OCR yolunun mutabakat + doğrulama sonuçlarını inceleme durumuna
  /// taşınmak üzere saklar. (CSV/Excel yolu bunları `applyMapping`'de kendi
  /// kurar.)
  void _applyParseDiagnostics(PdfParseResult result) {
    _reconciliation = result.reconciliation;
    _verification = result.verification;
  }

  /// Biçim imzası için dosyanın ilk baytları. 512 bayt hem her imzayı hem de
  /// "metne benziyor mu" örneklemesini kapsar; koca ekstreyi belleğe almaz.
  Future<List<int>> _readHead(String path) async {
    final handle = await File(path).open();
    try {
      return await handle.read(512);
    } finally {
      await handle.close();
    }
  }

  /// Başa dön (hata sonrası tekrar dene / yeni dosya). Önceki PDF denemesinin
  /// ham metnini de temizler; aksi halde sonraki CSV/Excel akışında AppBar'daki
  /// "ham metni göster" düğmesi eski PDF'e ait metni göstermeye devam eder.
  ///
  /// Paylaşılan dosya da burada bırakılır: "başka dosya seç" demek onunla işin
  /// bittiği anlamına gelir, kurulum adımı normal dosya seçiciye döner.
  void reset() {
    _lastPdfRawText = null;
    _lastTable = null;
    _lastMapping = null;
    _reconciliation = null;
    _verification = StatementVerification.none;
    _statementCurrency = null;
    unawaited(_discardSharedCopy());
    emit(const BankImportInitial());
  }

  /// Paylaşılan ekstrenin önbellekteki kopyasını siler. Kopya uygulamanın özel
  /// alanında ve `allowBackup=false` olduğu için dışarı sızmaz; yine de
  /// finansal bir belge, gerekmediği anda durmasın.
  Future<void> _discardSharedCopy() async {
    final path = _sharedFilePath;
    if (path == null) return;
    _sharedFilePath = null;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Silinemedi: native taraf bir sonraki paylaşımda dizini zaten temizler.
    }
  }

  @override
  Future<void> close() async {
    await _discardSharedCopy();
    return super.close();
  }

  void updateMapping(ColumnMapping mapping) {
    final s = state;
    if (s is BankImportMapping) {
      emit(BankImportMapping(
        table: s.table,
        assessment: _mapper.assess(s.table, mapping),
      ));
    }
  }

  /// İnceleme ekranından eşleme ekranına geri döner (CSV/Excel yolunda).
  /// Taslaklar dosyadan YENİDEN üretileceği için incelemedeki düzenlemeler
  /// gider — eylem bu yüzden akışın başında kullanılmak üzere.
  void remap() {
    final table = _lastTable;
    final mapping = _lastMapping;
    if (table == null || mapping == null) return;
    emit(BankImportMapping(
      table: table,
      assessment: _mapper.assess(table, mapping),
    ));
  }

  /// Seçili arayüz dili; okunamazsa Türkçe.
  Future<String> _languageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PrefsKeys.language) ?? 'tr';
    } catch (_) {
      return 'tr';
    }
  }

  static const _mappingPrefsKey = 'bank_import_last_mapping';

  /// Kullanıcının onayladığı eşlemeyi, dosyanın BAŞLIK İMZASIYLA birlikte
  /// saklar (best-effort).
  Future<void> _saveMapping(ColumnMapping m, RawTable table) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _mappingPrefsKey,
        jsonEncode({
          'columnCount': table.columnCount,
          'header': _mapper.headerSignature(table, m.headerRowIndex),
          'mapping': m.toMap(),
        }),
      );
    } catch (_) {
      // Kalıcılık best-effort; başarısızlık akışı bozmamalı.
    }
  }

  /// Kaydedilmiş eşlemeyi YALNIZ bu tablonun başlığı kaydedilenle aynıysa
  /// döner; başlık satırının KONUMU ise her zaman bu tablonun kendi
  /// tespitinden ([guess]) alınır.
  ///
  /// Eskiden ölçüt yalnız sütun sayısıydı ve kayıtlı `headerRowIndex` aynen
  /// uygulanıyordu. Ölçüldü: başlığı 6. satırda olan bir Akbank eşlemesi,
  /// aynı sütun sayılı ama künyesiz başka bir dosyaya uygulanınca 7 gerçek
  /// hareketten 0 taslak çıkıyordu — ilk 6 satır "başlıktan önce" sayılıp
  /// hiç okunmuyordu ve ekranda başlık satırını değiştirecek bir kontrol
  /// yoktu. Aynı bankanın ekstresinde künye bir satır kısalınca da ilk
  /// hareket sessizce düşüyordu. İmzası olmayan eski kayıtlar yok sayılır.
  Future<ColumnMapping?> _loadSavedMapping(
    RawTable table,
    ColumnMapping guess,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_mappingPrefsKey);
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['columnCount'] != table.columnCount) return null;
      final header = data['header'];
      if (header is! List) return null;
      final current = _mapper.headerSignature(table, guess.headerRowIndex);
      if (!listEquals(header.cast<String>(), current)) return null;
      return ColumnMapping.fromMap(
              (data['mapping'] as Map).cast<String, dynamic>())
          .copyWith(headerRowIndex: guess.headerRowIndex);
    } catch (_) {
      return null;
    }
  }

  /// Kullanıcının eşleme ekranında onayladığı eşlemeyi uygular (ve sonraki
  /// aynı başlıklı dosya için hatırlar) → inceleme.
  Future<void> applyMapping() async {
    final s = state;
    if (s is! BankImportMapping) return;
    await _saveMapping(s.mapping, s.table);
    await _applyAssessed(s.table, s.assessment);
  }

  /// Değerlendirilmiş eşlemenin sonucunu doğrulamadan geçirip kategori/
  /// tekrar adımlarına verir. Hem otomatik (güvenilir) yol hem kullanıcının
  /// onayladığı eşleme buradan geçer.
  Future<void> _applyAssessed(
    RawTable table,
    MappingAssessment assessment,
  ) async {
    emit(const BankImportParsing());
    _lastMapping = assessment.mapping;
    try {
      final result = assessment.result;
      _reconciliation = result.reconciliation;
      final sourceText = table.rows.map((r) => r.join(' ')).join('\n');
      _statementCurrency = detectDominantCurrency(sourceText);
      // CSV/Excel de PDF ile aynı doğrulama kapısından geçer: bakiye zinciri
      // + ekstrenin kendi beyanları (kayıt sayısı, devreden/kapanış bakiyesi,
      // Borç/Alacak toplamları).
      _verification = verifyStatement(
        signedAmounts: [
          for (final d in result.drafts) d.isIncome ? d.amount : -d.amount,
        ],
        balances: result.balances,
        reconciliation: result.reconciliation,
        sourceText: sourceText,
        englishGrouping: detectEnglishGrouping(sourceText),
      );
      await _afterParse(result.drafts, result.skippedRows);
    } catch (e) {
      emit(BankImportError('Eşleme uygulanamadı: $e'));
    }
  }

  /// Ayrıştırma bitti: bilinen ama kullanıcının listesinde karşılığı olmayan
  /// kategori grupları var mı bak. Varsa onay adımına dur; yoksa doğrudan
  /// incelemeye geç.
  Future<void> _afterParse(List<ImportDraft> raw, int skipped) async {
    final suggestions = _guesser.suggestNewCategories(
      drafts: raw,
      expenseCategories: _expenseCats,
      incomeCategories: _incomeCats,
      // Öneriden kurulan kategori kullanıcı verisidir: seçili dilde
      // yazılmalı. Dil tercihi burada prefs'ten okunur — cubit'in widget
      // ağacı yok (aynı gerekçe: `NotificationLocalizer`).
      languageCode: await _languageCode(),
    );
    if (suggestions.isEmpty) {
      await _toReview(raw, skipped);
      return;
    }
    emit(BankImportCategorySuggestion(
      suggestions: suggestions,
      rawDrafts: raw,
      skippedRows: skipped,
    ));
  }

  /// Kategori öneri adımının sonucu: [approved] içindekiler yaratılır
  /// (kullanıcının o türdeki listesine eklenir), geri kalanı hiç
  /// oluşturulmaz. Ardından incelemeye geçilir (yeni yaratılanlar artık
  /// `_toReview`'daki `guess()` çağrısında bulunur).
  ///
  /// Onay kimliği ÖNERİNİN KENDİSİDİR (Equatable), yalnız adı değil: aynı ad
  /// iki öneride birden bulunabiliyor — "Yatırım" hem gider hem gelir
  /// tarafında var ve alt kategori hedefleriyle birlikte aynı yaprak adı iki
  /// ana kategori altında da gelebilir. Ada bakan eski sürümde birini
  /// işaretlemek diğerini de kuruyordu.
  Future<void> resolveCategorySuggestions(
      Set<CategorySuggestion> approved) async {
    final s = state;
    if (s is! BankImportCategorySuggestion) return;

    // Öneriler bu CÜZDANIN havuzuna göre üretilir; aynı adlı kategori BAŞKA
    // bir cüzdanda zaten var olabilir. O durumda ikinci bir kayıt yaratmak
    // hem kardeş-ad tekilliğine takılırdı (`duplicateSiblingName` → sessizce
    // atlanır, satır kategorisiz kalırdı) hem de raporu aynı ada sahip iki
    // kimliğe bölerdi. Var olan bağlanır, yenisi yaratılmaz.
    final globalExpense = await _categoryRepo.getCategories(true);
    final globalIncome = await _categoryRepo.getCategories(false);

    for (final suggestion in s.suggestions) {
      if (!approved.contains(suggestion)) continue;
      final isExpense = !suggestion.isIncome;
      final global = isExpense ? globalExpense : globalIncome;
      try {
        // Öneri pakette bir alt kategoriyse ("Konut › Kira") önce üst
        // kategorinin var olması gerekir; yoksa o da kurulur.
        final parentId = await _ensureParent(suggestion,
            isExpense: isExpense, global: global);

        final existing = _findCategory(
          global,
          isExpense: isExpense,
          name: suggestion.name,
          parentId: parentId,
        );
        if (existing != null) {
          await _remember(existing);
          continue;
        }

        final category = await _categoryRepo.addCategory(
          name: suggestion.name,
          iconName: suggestion.iconName,
          isExpense: isExpense,
          parentId: parentId,
        );
        await _remember(category);
      } catch (_) {
        // Oluşturulamadıysa (ör. adı bu arada başka yerden eklendi) sessizce
        // atla; ilgili taslaklar kategorisiz kalır, akış durmaz.
      }
    }

    await _toReview(s.rawDrafts, s.skippedRows);
  }

  /// Taslağın kategorisinin adı; bulunamazsa `null`.
  String? _categoryNameOf(String? categoryId, bool isIncome) {
    if (categoryId == null) return null;
    final pool = isIncome ? _incomeCats : _expenseCats;
    return pool.where((c) => c.id == categoryId).firstOrNull?.name;
  }

  /// Önerinin üst kategorisini bulur; kullanıcıda yoksa oluşturur.
  /// Öneri kök seviyedeyse `null` döner.
  Future<String?> _ensureParent(
    CategorySuggestion suggestion, {
    required bool isExpense,
    required List<CategoryEntity> global,
  }) async {
    final parentName = suggestion.parentName;
    if (parentName == null) return null;

    final existing =
        _findCategory(global, isExpense: isExpense, name: parentName);
    if (existing != null) {
      await _remember(existing);
      return existing.id;
    }

    final created = await _categoryRepo.addCategory(
      name: parentName,
      // İkon önerinin kendisinden gelir: ada bakan eski arama, ad artık
      // dile göre değiştiği için hedefi ıskalardı.
      iconName: suggestion.parentIconName ?? 'category',
      isExpense: isExpense,
    );
    await _remember(created);
    return created.id;
  }

  /// Adı ve üst kategorisi eşleşen kaydı önce BU TURUN havuzunda, sonra
  /// küresel listede arar.
  ///
  /// Havuz önce gelir çünkü aynı turda yaratılanlar henüz [global] listesinde
  /// yok: aynı üst kategoriyi paylaşan iki öneri, ikincisinde ikiz kök
  /// yaratırdı.
  CategoryEntity? _findCategory(
    List<CategoryEntity> global, {
    required bool isExpense,
    required String name,
    String? parentId,
  }) {
    bool matches(CategoryEntity c) =>
        c.parentId == parentId && _sameName(c.name, name);
    final pool = isExpense ? _expenseCats : _incomeCats;
    return pool.where(matches).firstOrNull ?? global.where(matches).firstOrNull;
  }

  /// Kategoriyi bu turun havuzuna ekler (sonraki tahminler onu görsün) ve
  /// hedef cüzdanda görünür yapar.
  ///
  /// Görünürlük şart: kategori başka bir cüzdanda var olduğu için yeniden
  /// yaratılmadıysa, bu cüzdanın kümesine katılmadan seçilemez — kullanıcı
  /// onayladığı öneriyi listede bulamazdı.
  Future<void> _remember(CategoryEntity category) async {
    if (category.isExpense) {
      if (!_expenseCats.any((c) => c.id == category.id)) {
        _expenseCats = [..._expenseCats, category];
      }
    } else {
      if (!_incomeCats.any((c) => c.id == category.id)) {
        _incomeCats = [..._incomeCats, category];
      }
    }
    await _walletCategories.include(
      walletId: walletId,
      categoryIds: [category.id],
    );
  }

  static bool _sameName(String a, String b) =>
      normalizeCategoryName(a) == normalizeCategoryName(b);

  Future<void> _toReview(List<ImportDraft> raw, int skipped) async {
    // Kullanıcının TÜM geçmişi tek sorguda çekilir: hem geçmişe dayalı kategori
    // tahmini (öğrenen) hem dedup için ortak kullanılır.
    var history = const <TransactionEntity>[];
    if (raw.isNotEmpty) {
      final res = await _txRepo.getTransactions(
        userId: _userId,
        walletId: _walletId,
      );
      res.fold((_) {}, (list) => history = list);
    }
    _historyIndex = _guesser.buildHistoryIndex(
      history,
      statementTexts: [for (final d in raw) d.description],
    );
    _ledgerById = {
      for (final t in history)
        if (t.id != null) t.id!: t,
    };

    var drafts = [
      for (final d in raw) d.copyWith(categoryId: _guessCategory(d, d.type)),
    ];

    if (drafts.isNotEmpty) {
      drafts = markDuplicateDrafts(
        drafts,
        history,
        // Bakiye zinciri tutan ekstrede her satır bakiyeyi değiştirir: aynı
        // gün aynı tutarlı iki satır İKİ gerçek harekettir, dosya içi tekrar
        // sayılmamalı (bkz. `markDuplicateDrafts`).
        rowsProvenDistinct:
            _verification.status == StatementVerificationStatus.verified ||
                _reconciliation?.status == ReconcileStatus.matched,
        rootOf: _rootOf,
      );
    }

    // Hedef cüzdanın birimi HER ZAMAN okunur: inceleme ekranı tutarları bu
    // birimle biçimlendirir (eskiden yalnız uyarı gerektiğinde okunuyordu, bu
    // yüzden tutarlar hep ₺ ile gösteriliyordu — USD/EUR cüzdanda yanlış).
    final wRes = await _metrics.walletRepository.getWalletById(_walletId);
    final walletCurrency = wRes.fold((_) => null, (w) => w?.currency);

    // Ekstre belirgin bir para birimi taşıyor ve bu hedef cüzdanınkinden
    // farklıysa ayrıca uyar (ör. USD ekstresi TRY cüzdana).
    final foreignCurrency = (_statementCurrency != null &&
            walletCurrency != null &&
            _statementCurrency != walletCurrency)
        ? _statementCurrency
        : null;

    emit(BankImportReview(
      drafts: drafts,
      expenseCategories: _expenseCats,
      incomeCategories: _incomeCats,
      skippedRows: skipped,
      reconciliation: _reconciliation,
      verification: _verification,
      foreignCurrency: foreignCurrency,
      walletCurrency: walletCurrency,
      sourceTruncated: _sourceTruncated,
      sourceUnresolvedCells: _sourceUnresolvedCells,
      fromOcr: _fromOcr,
      canRemap: _lastTable != null && _lastMapping != null,
    ));
  }

  /// Kategorinin ana kategorisi (kökse kendisi). Yaklaşık tekrar tespitinde
  /// "Market" ile "Market › Kasap" aynı kalem sayılsın diye.
  String? _rootOf(String categoryId) {
    for (final c in [..._expenseCats, ..._incomeCats]) {
      if (c.id == categoryId) return c.parentId ?? c.id;
    }
    return categoryId;
  }

  // --- kategori tahmini ---

  /// [d]'nin [type] türü için kategori tahmini; güvenilirlik sırasıyla:
  /// (1) kullanıcının KENDİ geçmişi ("bu üye işyerini geçen sefer X
  /// yapmıştım"), (2) açıklamadaki üye işyeri (sabit sözlük), (3) bankanın
  /// ekstrede verdiği kendi etiketi. Üçü de tutmazsa BİLEREK `null` döner
  /// (türün ilk kategorisine düşülmez — eskiden işlemlerin ~%80'i tesadüfen
  /// "Yemek" görünüp yanlış güven veriyordu). Eşleşmeyenler inceleme
  /// ekranında elle seçilir (bkz. `BankImportReview.uncategorizedCount`).
  ///
  /// Etiket sözlükten SONRA gelir: gerçek bir Garanti ekstresinde banka tüm
  /// kart harcamalarını "Alışveriş" etiketliyor, önde durunca Market/İlaç/
  /// Fatura satırlarını eziyordu (bkz. `CategoryGuesser.guessFromSourceTag`).
  String? _guessCategory(ImportDraft d, TransactionTypeModel type) {
    final isIncome = type == TransactionTypeModel.income;
    final candidates = isIncome ? _incomeCats : _expenseCats;
    final index = _historyIndex;
    return (index == null
            ? null
            : _guesser.guessFromHistory(
                description: d.description,
                isIncome: isIncome,
                index: index,
                candidates: candidates,
              )) ??
        _guesser.guess(
          description: d.description,
          isIncome: isIncome,
          candidates: candidates,
        ) ??
        _guesser.guessFromSourceTag(
          sourceTag: d.sourceTag,
          isIncome: isIncome,
          candidates: candidates,
        );
  }

  /// Türü değişen taslağı yeniden kurar. `copyWith` DEĞİL: yeni tür için
  /// tahmin tutmuyorsa kategori `null`'a dönmeli, `copyWith` ise
  /// `categoryId ?? this.categoryId` ile eski (artık yanlış türe ait)
  /// kategoriyi korurdu.
  ///
  /// Defterle eşleşmesi varsa DÜŞER: eşleşme eski türdeki bir kayıtlaydı
  /// (gider ↔ gider), tür çevrilince artık o kaydın tekrarı değildir. Satır
  /// da yeniden seçilir — seçimsiz gelmesinin tek nedeni o eşleşmeydi.
  /// Dosya içi eş (aynı dosyada ikinci kez geçme) türden bağımsızdır, kalır.
  ImportDraft _retyped(ImportDraft d, TransactionTypeModel type) {
    final match = d.duplicateOf;
    final keepMatch = match != null && match.kind == DuplicateKind.withinFile;
    final dropsLedgerMatch = match != null && !keepMatch;
    return ImportDraft(
      date: d.date,
      description: d.description,
      amount: d.amount,
      type: type,
      categoryId: _guessCategory(d, type),
      sourceTag: d.sourceTag,
      reference: d.reference,
      duplicateOf: keepMatch ? match : null,
      selected: dropsLedgerMatch ? true : d.selected,
    );
  }

  // --- inceleme mutasyonları ---

  void toggleDraft(int i) => _mutate(
        (d) => [
          for (var k = 0; k < d.length; k++)
            k == i ? _withSelected(d[k], !d[k].selected) : d[k]
        ],
      );

  /// Seçim değişimi. Satır EKLENECEKSE eşleşen kaydı düzeltme kararı düşer:
  /// ya yeni kayıt açılır ya eskisi düzeltilir, ikisi birden aynı harcamayı
  /// iki kez sayardı.
  static ImportDraft _withSelected(ImportDraft d, bool selected) => d.copyWith(
        selected: selected,
        correctExisting: selected ? false : d.correctExisting,
      );

  /// Yaklaşık eşleşen satırda "aynı harcama, defterdekinin tutarını
  /// ekstredekiyle düzelt" kararı. Açılınca satır eklenmez (yeni kayıt
  /// açılmaz); yalnız eşleşmesi düzeltilebilir olan satırda geçerlidir
  /// (bkz. `DuplicateMatch.canCorrectAmount`).
  void setCorrectExisting(int i, bool value) => _mutate((d) => [
        for (var k = 0; k < d.length; k++)
          if (k == i && (d[k].duplicateOf?.canCorrectAmount ?? false))
            d[k].copyWith(
              correctExisting: value,
              selected: value ? false : d[k].selected,
            )
          else
            d[k],
      ]);

  /// Düzeltilebilir TÜM yaklaşık eşleşmelerde (kullanıcının "farklı işlem"
  /// deyip eklemeye aldıkları hariç) tutar düzeltmesini açar.
  void correctAllApproximate() => _mutate((d) => [
        for (final x in d)
          if (!x.selected &&
              (x.duplicateOf?.isApproximate ?? false) &&
              x.duplicateOf!.canCorrectAmount)
            x.copyWith(correctExisting: true)
          else
            x,
      ]);

  void setDraftCategory(int i, String categoryId) => _mutate(
        (d) => [
          for (var k = 0; k < d.length; k++)
            k == i ? d[k].copyWith(categoryId: categoryId) : d[k]
        ],
      );

  void setDraftAmount(int i, double amount) => _mutate(
        (d) => [
          for (var k = 0; k < d.length; k++)
            k == i ? d[k].copyWith(amount: amount) : d[k]
        ],
      );

  void setDraftDescription(int i, String description) => _mutate(
        (d) => [
          for (var k = 0; k < d.length; k++)
            k == i ? d[k].copyWith(description: description) : d[k]
        ],
      );

  void setDraftType(int i, TransactionTypeModel type) => _mutate((d) => [
        for (var k = 0; k < d.length; k++) k == i ? _retyped(d[k], type) : d[k],
      ]);

  void setAllSelected(bool value) =>
      _mutate((d) => [for (final x in d) _withSelected(x, value)]);

  /// Tüm taslakları tek türe (gider/gelir) çevirir. Tek pozitif "Tutar"
  /// sütunlu (işaretsiz) ekstrelerde tüm satırlar yanlışlıkla aynı yöne
  /// (ör. hep gelir) düşerse kullanıcı tek dokunuşla düzeltebilsin diye.
  ///
  /// Türü ZATEN hedef olan satırlara DOKUNULMAZ. Tür değişimi kategoriyi
  /// geçersiz kılar (gider kategorisi gelir satırına yazılamaz), bu yüzden
  /// çevrilen satırda yeniden tahmin doğrudur — ama zaten doğru türdeki bir
  /// satırı da yeniden tahmin etmek, kullanıcının ELLE seçtiği kategoriyi
  /// sessizce tahminle (çoğu zaman `null` ile) eziyordu.
  void setAllType(TransactionTypeModel type) => _mutate((d) => [
        for (final x in d)
          if (x.type == type) x else _retyped(x, type),
      ]);

  void setDraftSelected(int i, bool value) => _mutate(
        (d) => [
          for (var k = 0; k < d.length; k++)
            k == i ? _withSelected(d[k], value) : d[k]
        ],
      );

  /// Verilen indekslerdeki taslaklara aynı kategoriyi uygular.
  ///
  /// Toplu atamanın kapsamını inceleme ekranındaki arama+filtre belirler
  /// ("kategorisiz" + "MIGROS" → görünen satırlara Market): türün TAMAMINI
  /// tek kategoriye çeken eski toplu işlem, doğru tahmin edilmiş satırların
  /// üstüne de yazıyordu.
  void applyCategoryToIndexes(Iterable<int> indexes, String categoryId) {
    final target = indexes.toSet();
    if (target.isEmpty) return;
    _mutate((d) => [
          for (var k = 0; k < d.length; k++)
            target.contains(k) ? d[k].copyWith(categoryId: categoryId) : d[k],
        ]);
  }

  /// İnceleme sırasında oluşturulan kategoriyi akışa tanıtır: aday listesine
  /// eklenir (satır seçicileri onu hemen görür) ve sonraki tür çevirmelerinde
  /// tahmine girer. Kategori deftere zaten `showCategoryForm` tarafından
  /// yazılmıştır; burada yalnız bu akışın kopyası tazelenir.
  void registerCreatedCategory(CategoryEntity category) {
    if (category.isExpense) {
      if (_expenseCats.any((c) => c.id == category.id)) return;
      _expenseCats = [..._expenseCats, category];
    } else {
      if (_incomeCats.any((c) => c.id == category.id)) return;
      _incomeCats = [..._incomeCats, category];
    }
    final s = state;
    if (s is BankImportReview) {
      emit(s.copyWith(
        expenseCategories: _expenseCats,
        incomeCategories: _incomeCats,
      ));
    }
  }

  void _mutate(List<ImportDraft> Function(List<ImportDraft>) f) {
    final s = state;
    if (s is BankImportReview) emit(s.copyWith(drafts: f(s.drafts)));
  }

  /// Seçili taslakları mevcut cüzdana yazar ve "tutarı düzelt" denen
  /// eşleşmelerin defter kaydını düzeltir. Para zinciri: döngü sonunda TEK
  /// syncBalance + TEK notify (O(N²) ve bildirim fırtınası önlenir).
  Future<void> commit() async {
    final s = state;
    if (s is! BankImportReview) return;
    final selected = s.drafts.where((d) => d.selected).toList();
    final corrections = [
      for (final d in s.drafts)
        if (d.correctExisting && !d.selected) d,
    ];
    if (selected.isEmpty && corrections.isEmpty) {
      emit(await _buildDone(
          added: 0, totalDrafts: s.drafts.length, committed: const []));
      return;
    }

    final total = selected.length + corrections.length;
    emit(BankImportCommitting(done: 0, total: total));
    var added = 0;
    final importedIds = <String>[];
    for (var i = 0; i < selected.length; i++) {
      final id = UidGenerator.generateV7();
      final draft = selected[i];
      final entity = draft.toEntity(
        id: id,
        userId: _userId,
        walletId: _walletId,
        categoryName: _categoryNameOf(draft.categoryId, draft.isIncome),
      );
      final res = await _txRepo.addTransaction(entity);
      res.fold((_) {}, (_) {
        added++;
        importedIds.add(id);
      });
      if (i % 10 == 0 || i == selected.length - 1) {
        emit(BankImportCommitting(done: i + 1, total: total));
      }
    }
    _lastImportedIds = importedIds;

    final originals = <TransactionEntity>[];
    for (final draft in corrections) {
      final original = _ledgerById[draft.duplicateOf?.existingId];
      if (original == null || original.isSystem) continue;
      // Yalnız TUTAR (ve bankanın numarası) değişir: kategori, not, tarih/saat
      // ve fiş kullanıcınındır. Referans yazılınca aynı hareket bir sonraki
      // içe aktarımda kesin eşleşmeyle bulunur.
      final corrected = original.copyWith(
        amount: draft.amount,
        reference: draft.reference,
      );
      final res = await _txRepo.updateTransaction(corrected);
      res.fold((_) {}, (_) => originals.add(original));
    }
    _lastCorrectedOriginals = originals;

    await _metrics.syncBalance(_walletId);
    _notifier.notify(userId: _userId, walletId: _walletId);

    emit(await _buildDone(
      added: added,
      totalDrafts: s.drafts.length,
      committed: selected,
      corrected: originals.length,
    ));
  }

  /// `_Done`'daki "Geri al": son içe aktarımda yazılan işlemleri (yalnız o
  /// partiyi) siler, bakiyeyi yeniden hesaplar, dinleyicileri bilgilendirir ve
  /// başa döner. İkinci çağrı no-op (id listesi boşalır). Oturum kapanınca
  /// (yeni dosya/`reset`) geri alma imkânı da doğal olarak biter.
  Future<void> undoImport() async {
    final ids = _lastImportedIds;
    final originals = _lastCorrectedOriginals;
    if (ids.isEmpty && originals.isEmpty) return;
    _lastImportedIds = const [];
    _lastCorrectedOriginals = const [];
    for (final id in ids) {
      await _txRepo.deleteTransaction(id);
    }
    // Düzeltilen kayıtlar eski tutarlarına (ve referanslarına) döner.
    for (final original in originals) {
      await _txRepo.updateTransaction(original);
    }
    await _metrics.syncBalance(_walletId);
    _notifier.notify(userId: _userId, walletId: _walletId);
    emit(const BankImportInitial());
  }

  /// Test tohumu: cubit'i doğrudan kategori ÖNERİ adımına sokar.
  @visibleForTesting
  void debugSeedSuggestions({
    required String userId,
    required String walletId,
    required List<CategorySuggestion> suggestions,
    List<CategoryEntity> expenseCategories = const [],
    List<CategoryEntity> incomeCategories = const [],
  }) {
    _userId = userId;
    _walletId = walletId;
    _expenseCats = expenseCategories;
    _incomeCats = incomeCategories;
    emit(BankImportCategorySuggestion(
      suggestions: suggestions,
      rawDrafts: const [],
      skippedRows: 0,
    ));
  }

  /// Test tohumu: cubit'i doğrudan inceleme durumuna sokar (normalde dosya
  /// seçici + ayrıştırma gerektirir). `commit` gibi sonraki adımların testi için.
  @visibleForTesting
  void debugSeedReview({
    required String userId,
    required String walletId,
    required List<ImportDraft> drafts,
    List<CategoryEntity> expenseCategories = const [],
    List<CategoryEntity> incomeCategories = const [],
    List<TransactionEntity> ledger = const [],
  }) {
    _userId = userId;
    _walletId = walletId;
    _expenseCats = expenseCategories;
    _incomeCats = incomeCategories;
    _ledgerById = {
      for (final t in ledger)
        if (t.id != null) t.id!: t,
    };
    emit(BankImportReview(
      drafts: drafts,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
      skippedRows: 0,
    ));
  }

  /// Bitiş durumunu kurar. Bakiyeyi `syncBalance` sonrası defterden TAZE okur
  /// (UI'nin WalletBloc'un ~150ms gecikmeli box-watch akışını beklemeden gerçek
  /// bakiyeyi göstermesi için) ve eklenen hareketlerin bir kısmı mevcut ay
  /// dışındaysa (liste varsayılanı mevcut ay) bayrağı ile bildirir.
  Future<BankImportDone> _buildDone({
    required int added,
    required int totalDrafts,
    required List<ImportDraft> committed,
    int corrected = 0,
  }) async {
    final walletRes = await _metrics.walletRepository.getWalletById(_walletId);
    final balance = walletRes.fold((_) => 0.0, (w) => w?.balance ?? 0.0);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final hasOutOfMonthRows = committed.any(
      (d) => d.date.isBefore(monthStart) || d.date.isAfter(monthEnd),
    );

    return BankImportDone(
      added: added,
      corrected: corrected,
      skipped: totalDrafts - added - corrected,
      walletId: _walletId,
      userId: _userId,
      balance: balance,
      hasPastMonthRows: hasOutOfMonthRows,
    );
  }
}
