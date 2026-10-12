import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/core/l10n/app_strings.dart';
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
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/transfer_service.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/card_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/bank_import/data/link_hint.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/draft_dedup.dart';
import 'package:cunehat/features/bank_import/data/layout/statement_layout_engine.dart';
import 'package:cunehat/features/bank_import/data/pdf_rasterizer.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/statement_ocr_service.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/data/statement_currency_detector.dart';
import 'package:cunehat/features/bank_import/data/statement_closing.dart';
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
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';

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
    this._systemActivity, {
    TransferService? transferService,
  })  : _transferServiceOverride = transferService,
        super(const BankImportInitial());

  /// Transfer olarak işaretlenen satırları bağlayan servis. Kurucudan
  /// verilmediyse (üretim) DI'dan tembel çözülür; kayıtlı değilse bağlama
  /// yapılmaz ve satır bitiş ekranında "Bağla" önerisi olarak kalır.
  final TransferService? _transferServiceOverride;
  TransferService? get _transfers =>
      _transferServiceOverride ??
      (getIt.isRegistered<TransferService>() ? getIt<TransferService>() : null);

  /// Son içe aktarımın kurduğu transfer çiftleri ve dokunduğu KARŞI
  /// cüzdanlar — "geri al" önce bunları çözer.
  List<String> _lastTransferPairs = const [];
  Set<String> _lastTransferWallets = const {};

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

  /// Kart ekstresi künyesi (PDF yolu); banka ekstresinde `null`.
  CardStatementFacts? _cardFacts;

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

  /// Son `commit`in karta yazdığı ekstre künyesi + yazmadan ÖNCEKİ değerler;
  /// "Geri al" künyeyi de geri çevirir (yanlış karta aktarılan ekstrenin son
  /// ödeme tarihi ve hatırlatması kalmasın). Künye yazılmadıysa `null`.
  _CardStatementWrite? _lastCardWrite;

  /// Son ayrıştırmanın ham taslakları (kategorisiz, eşleşmesiz). Hedef
  /// cüzdan inceleme sırasında değiştirilince ([switchTarget]) dosya yeniden
  /// okunmadan buradan yeniden kurulur.
  List<ImportDraft> _rawDrafts = const [];
  int _rawSkipped = 0;

  /// Taslaklarla aynı sırada satır bakiyeleri (sütun yoksa boş/`null` dolu);
  /// kapanış bakiyesi buradan okunur (bkz. [statementClosing]).
  List<double?> _balances = const [];

  /// Ekstrenin kanıtlanmış kapanış bakiyesi; yoksa `null`.
  StatementClosing? _closing;

  /// Tablo dosyalarında başlık imzası: "bu biçimdeki ekstreyi geçen sefer
  /// hangi cüzdana aktarmıştın" hafızasının anahtarı. PDF/OCR'da `null`.
  String? _sourceKey;

  /// Son incelemenin hedefi kart mı / ekstre başka para biriminde mi —
  /// bitiş ekranındaki kapanış kıyası bu durumlarda yapılmaz.
  bool _targetIsCard = false;
  String? _foreignCurrency;

  /// İncelemenin başında çekilen defter (id → kayıt). Yaklaşık eşleşmede
  /// "tutarı düzelt" kararı, kaydın TAMAMINI (kategori, not, fiş…) koruyarak
  /// yalnız tutarını değiştirmek için buradan okur.
  Map<String, TransactionEntity> _ledgerById = const {};

  /// Kullanıcının "hiçbiri" diyerek kapattığı karşılıksız kayıt önerileri
  /// (defter kimlikleri). Oturum içi: yeni dosyada sıfırlanır.
  Set<String> _dismissedLeftovers = {};

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
    final FilePickerResult? picked;
    try {
      picked = await _systemActivity
          .run(() => FilePicker.pickFiles(type: FileType.any));
    } catch (e) {
      // Sağlayıcı ya da izin hatası eklentiden istisna olarak gelir.
      // Yakalanmadığında "dosya seç" düğmesi sessizce hiçbir şey yapmıyordu.
      emit(BankImportError(appStrings.blocMsgImportPickFailed('$e')));
      return;
    }
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
    _cardFacts = null;
    _statementCurrency = null;
    _fromOcr = false;
    _lastTable = null;
    _lastMapping = null;
    _dismissedLeftovers = {};
    _rawDrafts = const [];
    _rawSkipped = 0;
    _balances = const [];
    _closing = null;
    _sourceKey = null;
    _targetIsCard = false;
    _foreignCurrency = null;

    final DetectedStatementFormat detected;
    try {
      detected = detectStatementFormat(path: path, head: await _readHead(path));
    } catch (e) {
      emit(BankImportError(appStrings.blocMsgImportReadFailed('$e')));
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
        emit(BankImportError(appStrings.blocMsgImportEmptyFile));
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
      emit(BankImportError(appStrings.blocMsgImportReadFailed('$e')));
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
    _cardFacts = result.cardFacts;
    _balances = result.balances;
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
    _cardFacts = null;
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
      _balances = result.balances;
      _sourceKey = _mapper
          .headerSignature(table, assessment.mapping.headerRowIndex)
          .join('\u001f');
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
      emit(BankImportError(appStrings.blocMsgImportMappingFailed('$e')));
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
    final List<CategoryEntity> globalExpense;
    final List<CategoryEntity> globalIncome;
    try {
      globalExpense = await _categoryRepo.getCategories(true);
      globalIncome = await _categoryRepo.getCategories(false);
    } catch (e) {
      // Kategori deposu `Either` DEĞİL, EXCEPTION fırlatır. Yakalanmadığında
      // öneri adımında kalınıyor, "devam" düğmesi hiçbir şey yapmıyordu.
      emit(BankImportError(appStrings.blocMsgImportCategoriesFailed('$e')));
      return;
    }

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
    _rawDrafts = raw;
    _rawSkipped = skipped;
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
      for (final d in raw)
        () {
          final g = _guessCategory(d, d.type);
          return d.withCategory(g.id, g.source);
        }(),
    ];

    // Bakiye zinciri tutan ekstrede her satır bakiyeyi değiştirir: aynı
    // gün aynı tutarlı iki satır İKİ gerçek harekettir, dosya içi tekrar
    // sayılmamalı (bkz. `markDuplicateDrafts`).
    final rowsProvenDistinct =
        _verification.status == StatementVerificationStatus.verified ||
            _reconciliation?.status == ReconcileStatus.matched;
    if (drafts.isNotEmpty) {
      drafts = markDuplicateDrafts(
        drafts,
        history,
        rowsProvenDistinct: rowsProvenDistinct,
        rootOf: _rootOf,
      );
    }

    // Hedef cüzdanın birimi HER ZAMAN okunur: inceleme ekranı tutarları bu
    // birimle biçimlendirir (eskiden yalnız uyarı gerektiğinde okunuyordu, bu
    // yüzden tutarlar hep ₺ ile gösteriliyordu — USD/EUR cüzdanda yanlış).
    final target = (await _metrics.walletRepository.getWalletById(_walletId))
        .fold((_) => null, (w) => w);
    final walletCurrency = target?.currency;
    final targetIsCard = target?.isCreditCard ?? false;

    // Ekstre belirgin bir para birimi taşıyor ve bu hedef cüzdanınkinden
    // farklıysa ayrıca uyar (ör. USD ekstresi TRY cüzdana).
    final foreignCurrency = (_statementCurrency != null &&
            walletCurrency != null &&
            _statementCurrency != walletCurrency)
        ? _statementCurrency
        : null;
    _targetIsCard = targetIsCard;
    _foreignCurrency = foreignCurrency;
    _closing = statementClosing(
      drafts: raw,
      balances: _balances,
      reconciliation: _reconciliation,
      verification: _verification,
    );

    // Satır satır bakiye taşıyan dosya bir HESAP ekstresidir; kart
    // ekstrelerinde bakiye sütunu olmaz (kart künyesi ayrı okunur).
    final accountOnCard =
        targetIsCard && _cardFacts == null && _balances.any((b) => b != null);

    final wallets = await _wallets();
    final suggestion = await _suggestTarget(
      drafts: drafts,
      wallets: wallets,
      target: target,
      accountOnCard: accountOnCard,
      rowsProvenDistinct: rowsProvenDistinct,
    );

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
      leftovers: _leftoversFor(drafts),
      cardFacts: _cardFacts,
      targetIsCard: targetIsCard,
      targetSuggestion: suggestion,
      accountStatementOnCard: accountOnCard,
    ));
  }

  /// Kullanıcının cüzdanları; okunamazsa boş (öneriler yalnız ipucudur,
  /// okunamamaları akışı durdurmamalı).
  Future<List<WalletEntity>> _wallets() async =>
      (await _metrics.walletRepository.getWallets(_userId))
          .fold((_) => const <WalletEntity>[], (list) => list);

  /// Hedef cüzdan yanlış görünüyorsa daha uygun olanı (bkz.
  /// [TargetSuggestionReason]); sıra kanıtın gücüne göre.
  ///
  /// En güçlüsü "satırlar başka cüzdanda BİREBİR kayıtlı": cihazda ölçüldü —
  /// "Banka Kartm"a aktarılmış bir ekstre aynen "World" kartına da uyarısız
  /// aktarılabiliyordu, çünkü tekrar tespiti yalnız HEDEF cüzdanın defterine
  /// bakıyordu.
  Future<TargetSuggestion?> _suggestTarget({
    required List<ImportDraft> drafts,
    required List<WalletEntity> wallets,
    required WalletEntity? target,
    required bool accountOnCard,
    required bool rowsProvenDistinct,
  }) async {
    if (drafts.isEmpty || wallets.isEmpty) return null;
    String nameOf(WalletEntity w) => familyLabel(w, wallets);
    WalletEntity? byId(String? id) =>
        id == null ? null : wallets.where((w) => w.id == id).firstOrNull;

    // (1) Satırlar başka bir cüzdanda birebir kayıtlı. Hedefte zaten
    // çoğunluk birebir eşleşiyorsa (ekstre bu cüzdana tekrar aktarılıyor)
    // bakmaya gerek yok.
    final exactHere =
        drafts.where((d) => d.duplicateOf?.kind == DuplicateKind.exact).length;
    if (exactHere * 2 < drafts.length) {
      WalletEntity? best;
      var bestCount = 0;
      for (final w in wallets) {
        if (w.id == null || w.id == _walletId) continue;
        final other = (await _txRepo.getTransactions(
          userId: _userId,
          walletId: w.id!,
        ))
            .fold((_) => const <TransactionEntity>[], (l) => l);
        if (other.isEmpty) continue;
        final count = markDuplicateDrafts(
          _rawDrafts,
          other,
          rowsProvenDistinct: rowsProvenDistinct,
        ).where((d) => d.duplicateOf?.kind == DuplicateKind.exact).length;
        if (count > bestCount) {
          best = w;
          bestCount = count;
        }
      }
      final n = drafts.length;
      final enough =
          n <= 3 ? bestCount == n : bestCount >= 3 && bestCount >= n * 0.3;
      if (best != null && enough) {
        return TargetSuggestion(
          walletId: best.id!,
          walletName: nameOf(best),
          reason: TargetSuggestionReason.entriesElsewhere,
          matchCount: bestCount,
        );
      }
    }

    // (2) Kart ekstresi: son 4 hanesi TEK bir kart cüzdanıyla eşleşiyor.
    final last4 = _cardFacts?.last4;
    if (last4 != null) {
      final cards = wallets.where((w) => w.creditCard?.last4 == last4).toList();
      if (cards.length == 1 && cards.single.id != _walletId) {
        return TargetSuggestion(
          walletId: cards.single.id!,
          walletName: nameOf(cards.single),
          reason: TargetSuggestionReason.cardNumber,
          last4: last4,
        );
      }
    }

    // (3) Hesap ekstresi kart cüzdanına gidiyor: kartın ödendiği hesap.
    if (accountOnCard) {
      final owner = byId(target?.creditCard?.paymentWalletId);
      if (owner != null && !owner.isCreditCard) {
        return TargetSuggestion(
          walletId: owner.id!,
          walletName: nameOf(owner),
          reason: TargetSuggestionReason.accountOnCard,
        );
      }
    }

    // (4) Aynı biçimdeki ekstre daha önce başka cüzdana aktarıldı.
    final key = _sourceKey;
    if (key != null) {
      final remembered = byId((await _sourceWallets())[key]);
      if (remembered != null && remembered.id != _walletId) {
        return TargetSuggestion(
          walletId: remembered.id!,
          walletName: nameOf(remembered),
          reason: TargetSuggestionReason.usedBefore,
        );
      }
    }
    return null;
  }

  /// İnceleme sırasında hedef cüzdanı değiştirir. Dosya yeniden okunmaz:
  /// ham taslaklar yeni cüzdanın defteri ve kategori havuzuyla yeniden
  /// eşleştirilip tahmin edilir. İncelemedeki düzenlemeler bu yüzden gider
  /// — eylem akışın başında, öneri şeridinden kullanılmak üzere.
  Future<void> switchTarget(String walletId) async {
    if (state is! BankImportReview || walletId == _walletId) return;
    _walletId = walletId;
    _dismissedLeftovers = {};
    emit(const BankImportParsing());
    try {
      _expenseCats = await _walletCategories.categoriesFor(
        walletId: walletId,
        isExpense: true,
      );
      _incomeCats = await _walletCategories.categoriesFor(
        walletId: walletId,
        isExpense: false,
      );
      await _toReview(_rawDrafts, _rawSkipped);
    } catch (e) {
      emit(BankImportError(appStrings.blocMsgImportWalletSwitchFailed('$e')));
    }
  }

  static const _lastWalletPrefsKey = 'bank_import_last_wallet';
  static const _sourceWalletsPrefsKey = 'bank_import_source_wallets';

  /// Son içe aktarımın hedef cüzdanı (kurulum adımının varsayılanı); yoksa
  /// `null`. Çoğu kullanıcı hep aynı hesabın ekstresini aktarır — varsayılanın
  /// o an AKTİF cüzdan olması her seferinde yanlış cüzdanla başlatıyordu.
  Future<String?> lastTargetWalletId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastWalletPrefsKey);
    } catch (_) {
      return null;
    }
  }

  /// `kaynak imzası → cüzdan kimliği` hafızası (best-effort).
  Future<Map<String, String>> _sourceWallets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sourceWalletsPrefsKey);
      if (raw == null) return const {};
      return (jsonDecode(raw) as Map).cast<String, String>();
    } catch (_) {
      return const {};
    }
  }

  /// Bu içe aktarımın hedefini hatırlar: son hedef + (tablo dosyasında)
  /// başlık imzasına göre hedef. Best-effort.
  Future<void> _rememberTarget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastWalletPrefsKey, _walletId);
      final key = _sourceKey;
      if (key != null) {
        final map = {...await _sourceWallets(), key: _walletId};
        await prefs.setString(_sourceWalletsPrefsKey, jsonEncode(map));
      }
    } catch (_) {}
  }

  /// Ekstre döneminde defterde duran ama hiçbir satırla eşleşmemiş, olası
  /// eşi olan kayıtlar (bkz. [findLedgerLeftovers]). Taslaklardan türetilir;
  /// her mutasyonda yeniden hesaplanır ki bir satır eşleşince ya da düzenlenince
  /// öneriler bayatlamasın.
  List<LedgerLeftover> _leftoversFor(List<ImportDraft> drafts) =>
      findLedgerLeftovers(
        drafts,
        _ledgerById.values.toList(),
        rootOf: _rootOf,
        ignoredEntryIds: _dismissedLeftovers,
      );

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
  ({String? id, CategorySource? source}) _guessCategory(
      ImportDraft d, TransactionTypeModel type) {
    final isIncome = type == TransactionTypeModel.income;
    final candidates = isIncome ? _incomeCats : _expenseCats;
    final index = _historyIndex;
    final fromHistory = index == null
        ? null
        : _guesser.guessFromHistory(
            description: d.description,
            isIncome: isIncome,
            index: index,
            candidates: candidates,
          );
    if (fromHistory != null) {
      return (id: fromHistory, source: CategorySource.history);
    }
    final fromKeyword = _guesser.guess(
      description: d.description,
      isIncome: isIncome,
      candidates: candidates,
    );
    if (fromKeyword != null) {
      return (id: fromKeyword, source: CategorySource.keyword);
    }
    final fromTag = _guesser.guessFromSourceTag(
      sourceTag: d.sourceTag,
      isIncome: isIncome,
      candidates: candidates,
    );
    return (
      id: fromTag,
      source: fromTag == null ? null : CategorySource.bankTag
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
    final guess = _guessCategory(d, type);
    return ImportDraft(
      date: d.date,
      description: d.description,
      amount: d.amount,
      type: type,
      categoryId: guess.id,
      categorySource: guess.source,
      sourceTag: d.sourceTag,
      reference: d.reference,
      // Taksit yalnız harcamadır; gelire çevrilen satır taksit olamaz.
      installment: type == TransactionTypeModel.expense ? d.installment : null,
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
        // Aynı gerekçe: ya yeni satır yazılır ya eskisi taşınır.
        relocateExisting: selected ? false : d.relocateExisting,
      );

  /// Eski içe aktarımın yanlış aya yazdığı taksit satırını doğru aya taşıma
  /// kararı (bkz. `ImportDraft.relocateExisting`). Yalnız eşleşmesi taşınabilir
  /// olan satırda geçerlidir; açılınca satır eklenmez.
  void setRelocateExisting(int i, bool value) => _mutate((d) => [
        for (var k = 0; k < d.length; k++)
          if (k == i && (d[k].duplicateOf?.legacyInstallment ?? false))
            d[k].copyWith(
              relocateExisting: value,
              selected: value ? false : d[k].selected,
            )
          else
            d[k],
      ]);

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

  /// Satırı kendi cüzdanların arasındaki bir transfer olarak işaretler
  /// ([walletId] karşı cüzdan) ya da işareti kaldırır (`null`). İşaretli
  /// satırda kategori aranmaz; yazılınca bağlanır (bkz. [commit]).
  void setDraftTransfer(int i, String? walletId) => _mutate(
        (d) => [
          for (var k = 0; k < d.length; k++)
            k == i ? d[k].withTransfer(walletId) : d[k],
        ],
      );

  // Tür, tutar, açıklama ve kategori tekrar tespitinin girdileridir: her biri
  // değişince o satır defterle YENİDEN eşleştirilir (bkz. [_rematch]).

  void setDraftCategory(int i, String categoryId) => _mutate(
        (d) => _rematch([
          for (var k = 0; k < d.length; k++)
            k == i ? d[k].withCategory(categoryId, CategorySource.user) : d[k]
        ], [
          i
        ]),
      );

  void setDraftAmount(int i, double amount) => _mutate(
        (d) => _rematch([
          for (var k = 0; k < d.length; k++)
            k == i ? d[k].copyWith(amount: amount) : d[k]
        ], [
          i
        ]),
      );

  void setDraftDescription(int i, String description) => _mutate(
        (d) => _rematch([
          for (var k = 0; k < d.length; k++)
            k == i ? d[k].copyWith(description: description) : d[k]
        ], [
          i
        ]),
      );

  void setDraftType(int i, TransactionTypeModel type) =>
      _mutate((d) => _rematch([
            for (var k = 0; k < d.length; k++)
              k == i ? _retyped(d[k], type) : d[k],
          ], [
            i
          ]));

  /// [indexes]'teki taslakları incelemenin başında çekilen defterle yeniden
  /// eşleştirir. Eskiden eşleştirme yalnız bir kez, ayrıştırmadan hemen sonra
  /// koşuyordu: gelir sanılıp gidere çevrilen ya da tutarı düzeltilen satır,
  /// elle girilmiş aynı harcamayı hiç görmüyor ve ikinci kez ekleniyordu.
  List<ImportDraft> _rematch(List<ImportDraft> drafts, Iterable<int> indexes) =>
      rematchDrafts(
        drafts,
        _ledgerById.values.toList(),
        indexes,
        rootOf: _rootOf,
      );

  /// Toplu seçim, yalnız [indexes]'e (inceleme ekranında GÖRÜNEN satırlar).
  ///
  /// Seçerken tekrar sanılan satırlar ATLANIR: eskiden "Tümü" onları da
  /// seçiyor (ve "tutarı düzelt" kararını düşürüyordu) — defterde zaten olan
  /// harcama ikinci kez yazılıyordu. Tekrar satırı ancak kendi panelindeki
  /// açık kararla ("Farklı işlem, ekle") eklenir. Seçimi kaldırmak ise
  /// hepsine uygulanır; kaldırmak veri riski taşımaz.
  void setSelectedAt(Iterable<int> indexes, bool value) {
    final target = indexes.toSet();
    if (target.isEmpty) return;
    _mutate((d) => [
          for (var k = 0; k < d.length; k++)
            if (target.contains(k) && (!value || !d[k].isDuplicate))
              _withSelected(d[k], value)
            else
              d[k],
        ]);
  }

  /// Tüm taslakları tek türe (gider/gelir) çevirir. Tek pozitif "Tutar"
  /// sütunlu (işaretsiz) ekstrelerde tüm satırlar yanlışlıkla aynı yöne
  /// (ör. hep gelir) düşerse kullanıcı tek dokunuşla düzeltebilsin diye.
  ///
  /// Türü ZATEN hedef olan satırlara DOKUNULMAZ. Tür değişimi kategoriyi
  /// geçersiz kılar (gider kategorisi gelir satırına yazılamaz), bu yüzden
  /// çevrilen satırda yeniden tahmin doğrudur — ama zaten doğru türdeki bir
  /// satırı da yeniden tahmin etmek, kullanıcının ELLE seçtiği kategoriyi
  /// sessizce tahminle (çoğu zaman `null` ile) eziyordu.
  void setAllType(TransactionTypeModel type) => _mutate((d) => _rematch([
        for (final x in d)
          if (x.type == type) x else _retyped(x, type),
      ], [
        for (var k = 0; k < d.length; k++)
          if (d[k].type != type) k,
      ]));

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
    _mutate((d) => _rematch([
          for (var k = 0; k < d.length; k++)
            target.contains(k)
                ? d[k].withCategory(categoryId, CategorySource.user)
                : d[k],
        ], target));
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
    if (s is! BankImportReview) return;
    final drafts = f(s.drafts);
    emit(s.copyWith(drafts: drafts, leftovers: _leftoversFor(drafts)));
  }

  /// "Karşılığı bulunamayan kayıtlar" önerisinde kullanıcının kararı: defterdeki
  /// [entryId] kaydı [draftIndex] satırıyla AYNI hareket. Satır seçimden düşer
  /// (yeni kayıt açılmaz) ve eşleşme [DuplicateKind.linkedByUser] olarak
  /// gerekçeleriyle panelde görünür; tutar farklıysa "tutarı düzelt" de
  /// seçilebilir. Yön farklıysa ya da satır zaten bir kayıtla eşleşmişse
  /// hiçbir şey yapılmaz.
  void linkLeftover(String entryId, int draftIndex) {
    final entry = _ledgerById[entryId];
    if (entry == null) return;
    _mutate((d) {
      if (draftIndex < 0 || draftIndex >= d.length) return d;
      final draft = d[draftIndex];
      if (draft.duplicateOf != null || draft.isIncome != entry.isIncome) {
        return d;
      }
      final linked = draft.copyWith(
        duplicateOf: linkedMatch(draft, entry, rootOf: _rootOf),
        selected: false,
        correctExisting: false,
      );
      return [
        for (var k = 0; k < d.length; k++) k == draftIndex ? linked : d[k],
      ];
    });
  }

  /// Belirsiz yaklaşık eşleşmede kullanıcının kararı: [from] satırının
  /// eşleştiği defter kaydı aslında [to] satırıyla aynı hareket (bkz.
  /// `DuplicateMatch.alternativeDraftIndex`). Kayıt [to]'ya kullanıcı
  /// bağlantısı olarak taşınır; [from] serbest kalır, seçilir ve başka bir
  /// kayda benziyorsa yeniden eşleştirilir.
  void moveMatch(int from, int to) {
    _mutate((d) {
      if (from == to ||
          from < 0 ||
          to < 0 ||
          from >= d.length ||
          to >= d.length) {
        return d;
      }
      final entryId = d[from].duplicateOf?.existingId;
      final entry = entryId == null ? null : _ledgerById[entryId];
      final target = d[to];
      if (entry == null ||
          target.duplicateOf != null ||
          target.isIncome != entry.isIncome) {
        return d;
      }
      final moved = [
        for (var k = 0; k < d.length; k++)
          if (k == from)
            d[k].withoutDuplicate().copyWith(selected: true)
          else if (k == to)
            target.copyWith(
              duplicateOf: linkedMatch(target, entry, rootOf: _rootOf),
              selected: false,
              correctExisting: false,
            )
          else
            d[k],
      ];
      return _rematch(moved, [from]);
    });
  }

  /// Öneriyi kapatır ("hiçbiri aynı değil"); satırlara dokunmaz.
  void dismissLeftover(String entryId) {
    _dismissedLeftovers = {..._dismissedLeftovers, entryId};
    _mutate((d) => d);
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
    final relocations = [
      for (final d in s.drafts)
        if (d.relocateExisting &&
            !d.selected &&
            (d.duplicateOf?.legacyInstallment ?? false))
          d,
    ];
    if (selected.isEmpty && corrections.isEmpty && relocations.isEmpty) {
      emit(await _buildDone(
        added: 0,
        totalDrafts: s.drafts.length,
        committed: const [],
        unresolvedLeftovers: s.leftovers.length,
      ));
      return;
    }

    final total = selected.length + corrections.length + relocations.length;
    emit(BankImportCommitting(done: 0, total: total));
    // Bu içe aktarımın bütün satırları aynı kimliği taşır: "Son içe
    // aktarımlar" listesi ve bitiş ekranından çıkıldıktan sonra geri alma
    // buna dayanır. UUIDv7: yazıldığı an kimliğin içinde.
    final batchId = UidGenerator.generateV7();
    var added = 0;
    var futureInstallments = 0;
    final importedIds = <String>[];
    final linkable = <LinkSuggestion>[];
    // İnceleme ekranında transfer olarak işaretlenen satırlar: yazıldıktan
    // SONRA bağlanır (bağlama deftere yazılmış bir satır ister).
    final toLink = <(TransactionEntity, String, LinkHint)>[];
    final investmentCategories = _investmentCategoryIds();
    for (var i = 0; i < selected.length; i++) {
      final id = UidGenerator.generateV7();
      final draft = selected[i];
      // Taksit satırı: süren bir grubun parçasıysa ona katılır (aynı
      // alışverişin başka taksiti daha önce yazılmış), değilse yeni grup.
      final groupId = draft.installment == null
          ? null
          : (_siblingGroupOf(draft) ?? UidGenerator.generateV7());
      final entity = draft.toEntity(
        id: id,
        userId: _userId,
        walletId: _walletId,
        categoryName: _categoryNameOf(draft.categoryId, draft.isIncome),
        importBatchId: batchId,
        installmentGroupId: groupId,
      );
      final res = await _txRepo.addTransaction(entity);
      res.fold((_) {}, (_) {
        added++;
        importedIds.add(id);
        final hint = linkHintOf(
          draft.description,
          isIncome: draft.isIncome,
          inInvestmentCategory: !draft.isIncome &&
              investmentCategories.contains(draft.categoryId),
          onCard: _targetIsCard,
        );
        if (draft.transferWalletId case final other?) {
          toLink.add((entity, other, hint ?? LinkHint.cardPayment));
        } else if (hint != null) {
          linkable.add(LinkSuggestion(entity, hint));
        }
      });
      // Kalan taksitler ileri tarihe yazılır (kullanıcı kararı, 11 Eki 2026):
      // kartın toplam borcu ve kullanılabilir limiti bankanınkiyle tutsun.
      // Aynı içe aktarım kimliğini taşırlar; "geri al" onları da kaldırır.
      if (res.isRight()) {
        for (final next in draft.remainingInstallments(
          entity,
          newId: UidGenerator.generateV7,
        )) {
          if (_installmentExists(next)) continue;
          final r = await _txRepo.addTransaction(next);
          r.fold((_) {}, (_) {
            futureInstallments++;
            importedIds.add(next.id!);
          });
        }
      }
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
      // Düzeltilen satır önceden yazılmış bir TAHMİNİ taksitse (bkz.
      // `ImportDraft.remainingInstallments`), aynı alışverişin SONRAKİ
      // taksitleri de bankanın tutarına çekilir: banka kuruş farkını tek
      // taksite yazar, kalanlar birbirine eşittir.
      final group = original.installmentGroupId;
      final no = original.installmentNo;
      if (res.isRight() && group != null && no != null) {
        for (final later in _ledgerById.values.toList()) {
          if (later.installmentGroupId != group) continue;
          if ((later.installmentNo ?? 0) <= no) continue;
          if (!moneyEquals(later.amount, original.amount)) continue;
          final r = await _txRepo
              .updateTransaction(later.copyWith(amount: draft.amount));
          r.fold((_) {}, (_) => originals.add(later));
        }
      }
    }
    final correctedCount = originals.length;

    // Eski içe aktarımın yanlış aya yazdığı taksit satırları TAŞINIR: tarih
    // taksitin kendi ayına çekilir, satır taksit grubuna bağlanır ve kalan
    // taksitler ileri tarihe yazılır. Başlık, kategori, tutar ve saat
    // kullanıcınındır — dokunulmaz. Özgün hâller `originals`'a girer:
    // "geri al" tarihi ve grup alanlarını eski hâline döndürür.
    var relocatedRows = 0;
    var relocatedDrafts = 0;
    final ledger = Map<String, TransactionEntity>.of(_ledgerById);
    Future<bool> relocate(
      TransactionEntity row, {
      required DateTime day,
      required String groupId,
      required int no,
      required int count,
      String? reference,
    }) async {
      final moved = row.copyWith(
        date: DateTime(day.year, day.month, day.day, row.date.hour,
            row.date.minute, row.date.second),
        installmentGroupId: groupId,
        installmentNo: no,
        installmentCount: count,
        reference: reference,
      );
      final res = await _txRepo.updateTransaction(moved);
      if (res.isLeft()) return false;
      originals.add(row);
      ledger[moved.id!] = moved;
      relocatedRows++;
      return true;
    }

    for (final draft in relocations) {
      final original = ledger[draft.duplicateOf?.existingId];
      final inst = draft.installment;
      if (original == null || inst == null || !_relocatable(original)) continue;
      // Kardeş araması GÜNCEL defterde: aynı içe aktarımda taşınan bir başka
      // taksit bu alışverişin grubunu az önce kurmuş olabilir.
      _ledgerById = ledger;
      final groupId = _siblingGroupOf(draft) ?? UidGenerator.generateV7();
      final ok = await relocate(
        original,
        day: draft.date,
        groupId: groupId,
        no: inst.no,
        count: inst.count,
        reference: draft.reference,
      );
      if (!ok) continue;
      relocatedDrafts++;
      _ledgerById = ledger;

      // Kalan taksitler. ÇİFT SAYIM ÖNLEMİ: eski içe aktarım sonraki
      // taksitleri de alışveriş gününe "(k/N)" başlığıyla yazmış olabilir;
      // öyleyse yenisi yazılmaz, o satır kendi ayına taşınır.
      final base = ledger[original.id]!.copyWith(importBatchId: batchId);
      for (final next in draft.remainingInstallments(
        base,
        newId: UidGenerator.generateV7,
      )) {
        if (_installmentExists(next)) continue;
        final twin = _legacyTwinOf(next, inst);
        if (twin != null) {
          await relocate(
            twin,
            day: next.date,
            groupId: groupId,
            no: next.installmentNo!,
            count: inst.count,
          );
          _ledgerById = ledger;
          continue;
        }
        final r = await _txRepo.addTransaction(next);
        r.fold((_) {}, (_) {
          futureInstallments++;
          importedIds.add(next.id!);
          ledger[next.id!] = next;
        });
        _ledgerById = ledger;
      }
    }
    _lastCorrectedOriginals = originals;

    // Transfer olarak işaretlenenler bağlanır. Bağlanamayan satır düz
    // hâliyle kalır ve bitiş ekranında "Bağla" önerisi olarak sunulur.
    var linkedTransfers = 0;
    final pairs = <String>[];
    final touched = <String>{};
    for (final (row, otherId, hint) in toLink) {
      final outcome = await _linkAsTransfer(row, otherId);
      final pairId = outcome?.pairId;
      if (outcome != null && outcome.isSuccess && pairId != null) {
        linkedTransfers++;
        pairs.add(pairId);
        touched.add(otherId);
      } else {
        linkable.add(LinkSuggestion(row, hint));
      }
    }
    _lastTransferPairs = pairs;
    _lastTransferWallets = touched;

    // Künye bakiye senkronundan ÖNCE yazılır: senkron cüzdanı taze okuyup
    // yazdığı için kart bilgisini ezmez; defter bildirimi de kart
    // hatırlatmasını yeni son ödeme tarihiyle kurar.
    final cardSaved = await _saveCardStatement();
    await _metrics.syncBalance(_walletId);
    _notifier.notify(userId: _userId, walletId: _walletId);
    // Bağlama karşı cüzdanın defterini de değiştirdi (yeni bacak ya da
    // benimsenen satır): o cüzdanı izleyen ekranlar da tazelensin.
    for (final other in touched) {
      _notifier.notify(userId: _userId, walletId: other);
    }
    await _rememberTarget();

    emit(await _buildDone(
      added: added,
      totalDrafts: s.drafts.length,
      committed: selected,
      corrected: correctedCount,
      relocated: relocatedRows,
      relocatedDrafts: relocatedDrafts,
      unresolvedLeftovers: s.leftovers.length,
      linkSuggestions: linkable,
      cardStatementSaved: cardSaved,
      futureInstallments: futureInstallments,
      linkedTransfers: linkedTransfers,
    ));
  }

  /// [row]'u [otherWalletId] ile arasındaki transferin bir bacağı yapar.
  ///
  /// Karşı cüzdanda bu taşımanın öbür bacağı ZATEN duruyorsa (o hesabın
  /// ekstresi daha önce aktarılmış: ters yön, aynı tutar, en çok
  /// [_maxTransferDayDistance] gün uzak) iki satır eşlenir — hiçbir şey
  /// yazılmaz. Yoksa karşı bacak yazılır. Bağlanamazsa `null` ya da başarısız
  /// sonuç döner; satır düz hâliyle kalır.
  Future<TransferOutcome?> _linkAsTransfer(
    TransactionEntity row,
    String otherWalletId,
  ) async {
    final service = _transfers;
    if (service == null) return null;
    final wallets = await _wallets();
    WalletEntity? byId(String id) {
      for (final w in wallets) {
        if (w.id == id) return w;
      }
      return null;
    }

    final own = byId(_walletId);
    final other = byId(otherWalletId);
    if (own == null || other == null) return null;

    final ledger = (await _txRepo.getTransactions(
      userId: _userId,
      walletId: otherWalletId,
    ))
        .fold((_) => const <TransactionEntity>[], (list) => list);
    final existing = _counterpartRow(
      ledger,
      row,
      sameCurrency: own.currency == other.currency,
    );
    if (existing == null) {
      return service.adoptAsTransfer(
        transaction: row,
        wallet: own,
        counterpart: other,
      );
    }
    return row.isExpense
        ? service.adoptPair(
            outgoing: row,
            from: own,
            incoming: existing,
            to: other,
          )
        : service.adoptPair(
            outgoing: existing,
            from: other,
            incoming: row,
            to: own,
          );
  }

  /// Transferin iki bacağı en çok bu kadar gün ayrı düşebilir (bkz.
  /// `kMaxTransferDayDistance` — elle bağlama akışıyla aynı kural).
  static const int _maxTransferDayDistance = 3;

  /// [ledger]'da [row]'un öbür bacağı olabilecek DÜZ satır: ters yön, (aynı
  /// birimde) kuruşu kuruşuna aynı tutar, en yakın günlüsü. Sistem
  /// hareketleri ve başka bir kayda bağlı satırlar aday değildir.
  static TransactionEntity? _counterpartRow(
    List<TransactionEntity> ledger,
    TransactionEntity row, {
    required bool sameCurrency,
  }) {
    int day(DateTime d) =>
        DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final rowDay = day(row.date);
    TransactionEntity? best;
    var bestDistance = _maxTransferDayDistance + 1;
    for (final t in ledger) {
      if (t.id == null || t.isSystem || t.linkedRecordId != null) continue;
      if (t.isIncome == row.isIncome) continue;
      if (sameCurrency && !moneyEquals(t.amount, row.amount)) continue;
      final distance = (day(t.date) - rowDay).abs();
      if (distance < bestDistance) {
        best = t;
        bestDistance = distance;
      }
    }
    return best;
  }

  /// [draft] taksitinin alışverişine ait, defterde ZATEN duran başka bir
  /// taksitin grubu (aynı taksit sayısı, alışveriş gününe çapalı tarih,
  /// yakın tutar); yoksa `null`.
  String? _siblingGroupOf(ImportDraft draft) {
    final inst = draft.installment;
    if (inst == null) return null;
    for (final t in _ledgerById.values) {
      final no = t.installmentNo;
      if (t.installmentGroupId == null || no == null) continue;
      if (t.installmentCount != inst.count || no == inst.no) continue;
      if (t.isIncome != draft.isIncome) continue;
      if (!_sameDay(t.date, inst.dateOf(no))) continue;
      if ((t.amount - draft.amount).abs() > inst.count) continue;
      return t.installmentGroupId;
    }
    return null;
  }

  /// [next] taksiti defterde zaten var mı (elle bölünmüş ya da önceki bir
  /// içe aktarımın yazdığı): aynı k/N, aynı gün, yakın tutar.
  bool _installmentExists(TransactionEntity next) {
    final count = next.installmentCount;
    if (count == null) return false;
    for (final t in _ledgerById.values) {
      if (t.installmentNo != next.installmentNo) continue;
      if (t.installmentCount != count || t.isIncome != next.isIncome) continue;
      if (!_sameDay(t.date, next.date)) continue;
      if ((t.amount - next.amount).abs() <= count) return true;
    }
    return false;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Satır taşınabilir mi: düz bir defter kaydı. Sistem, benimsenmiş ya da
  /// bir kayda bağlı satırın tarihi başka bir kaydın nakit bacağıdır.
  static bool _relocatable(TransactionEntity t) =>
      t.id != null && !t.isSystem && !t.isAdopted && t.linkedRecordId == null;

  /// [next] taksitinin defterdeki ESKİ biçimli eşi: alışverişin özgün gününe
  /// "(k/N)" başlığıyla, taksit alanı OLMADAN yazılmış ve tutarı yakın.
  TransactionEntity? _legacyTwinOf(
      TransactionEntity next, DraftInstallment inst) {
    final marker = '(${next.installmentNo}/${inst.count})';
    for (final t in _ledgerById.values) {
      if (!_relocatable(t) || t.installmentNo != null) continue;
      if (t.isIncome != next.isIncome) continue;
      if (!_sameDay(t.date, inst.purchaseDate)) continue;
      if (!t.title.contains(marker)) continue;
      if ((t.amount - next.amount).abs() > inst.count) continue;
      return t;
    }
    return null;
  }

  /// Kapanmış kart ekstresinin künyesini hedef KART cüzdanının son ekstresi
  /// olarak yazar (kesim, son ödeme, dönem borcu, asgari; limit ve eksikse son
  /// 4 hane). Daha YENİ bir beyan zaten varsa eski ekstre onu ezmez.
  Future<bool> _saveCardStatement() async {
    _lastCardWrite = null;
    final facts = _cardFacts;
    if (facts == null || !facts.isClosedStatement) return false;
    final wallet = (await _metrics.walletRepository.getWalletById(_walletId))
        .fold((_) => null, (w) => w);
    final card = wallet?.creditCard;
    if (wallet == null || card == null) return false;
    final closing = CardCycle.dateOnly(facts.closingDate!);
    final existing = card.lastStatement;
    if (existing != null && existing.closingDate.isAfter(closing)) return false;
    final written = CardStatement(
      closingDate: closing,
      dueDate: facts.dueDate ?? CardCycle(card).dueFor(closing),
      statementBalance: facts.statementBalance!,
      minimumPayment: facts.minimumPayment,
      source: CardStatementSource.bankImport,
      recordedAt: DateTime.now(),
    );
    final updated = wallet.copyWith(
      creditCard: card.copyWith(
        lastStatement: written,
        limit: facts.limit,
        last4: card.last4 ?? facts.last4,
      ),
    );
    final ok =
        (await _metrics.walletRepository.updateWallet(updated)).isRight();
    if (ok) {
      _lastCardWrite = _CardStatementWrite(
        written: written,
        before: card,
        limitWritten: facts.limit,
        last4Written: card.last4 == null ? facts.last4 : null,
      );
    }
    return ok;
  }

  /// Künyeyi içe aktarım öncesine döndürür — yalnız karttaki ekstre HÂLÂ
  /// bizim yazdığımızsa. Arada kullanıcı ya da başka bir içe aktarım yeni bir
  /// beyan yazdıysa o beyan kullanıcınındır, ezilmez. Limit ve son 4 hane de
  /// yalnız bizim yazdığımız değerde duruyorsa geri alınır (kullanıcı bu
  /// arada kart formundan düzelttiyse onun düzeltmesi kalır).
  Future<bool> _revertCardStatement() async {
    final write = _lastCardWrite;
    _lastCardWrite = null;
    if (write == null) return false;
    final wallet = (await _metrics.walletRepository.getWalletById(_walletId))
        .fold((_) => null, (w) => w);
    final card = wallet?.creditCard;
    if (wallet == null || card == null) return false;
    if (card.lastStatement != write.written) return false;
    final before = write.before;
    final restoreLimit =
        write.limitWritten != null && card.limit == write.limitWritten;
    final restoreLast4 =
        write.last4Written != null && card.last4 == write.last4Written;
    final reverted = wallet.copyWith(
      creditCard: card.copyWith(
        lastStatement: before.lastStatement,
        clearLastStatement: before.lastStatement == null,
        limit: restoreLimit ? before.limit : null,
        clearLimit: restoreLimit && before.limit == null,
        clearLast4: restoreLast4,
      ),
    );
    return (await _metrics.walletRepository.updateWallet(reverted)).isRight();
  }

  /// Kullanıcının gider tarafındaki "Yatırım" kategorisi ve alt kategorileri
  /// (ada göre, her dilde; bkz. `CategoryGuesser.resolveTarget`). Yoksa boş.
  Set<String> _investmentCategoryIds() {
    final root = _guesser.resolveTarget(
      parseCategoryTarget('investment'),
      _expenseCats,
    );
    if (root == null) return const {};
    return {
      root.id,
      for (final c in _expenseCats)
        if (c.parentId == root.id) c.id,
    };
  }

  /// `_Done`'daki "Geri al": son içe aktarımda yazılan işlemleri (yalnız o
  /// partiyi) siler, bakiyeyi yeniden hesaplar, dinleyicileri bilgilendirir ve
  /// başa döner. İkinci çağrı no-op (id listesi boşalır). Oturum kapanınca
  /// (yeni dosya/`reset`) geri alma imkânı da doğal olarak biter.
  ///
  /// Dönüş: silinen, eski tutarına dönen ve bu arada bir kayda BAĞLANDIĞI
  /// (benimsendiği) için yerinde bırakılan satır sayıları. Bağlanmış satır
  /// artık bir birikimin, borcun ya da transferin nakit bacağıdır: silmek o
  /// kaydı parasız bırakır, eski hâlini geri yazmak bağı sessizce koparırdı —
  /// ikisinde de bakiye kaydın tutarı kadar kayardı.
  Future<ImportUndoResult> undoImport() async {
    final ids = _lastImportedIds;
    final originals = _lastCorrectedOriginals;
    if (ids.isEmpty && originals.isEmpty && _lastCardWrite == null) {
      return ImportUndoResult.none;
    }
    _lastImportedIds = const [];
    _lastCorrectedOriginals = const [];
    // Bu içe aktarımın kurduğu transferler ÖNCE çözülür: benimsenen bacaklar
    // düz hâllerine döner (karşı cüzdandaki satır yerinde kalır), yazılan
    // karşı bacak silinir. Çözülmeden satırlar "bağlı" sayılıp atlanırdı.
    final pairs = _lastTransferPairs;
    final touched = _lastTransferWallets;
    _lastTransferPairs = const [];
    _lastTransferWallets = const {};
    final transfers = _transfers;
    if (transfers != null) {
      for (final pairId in pairs) {
        await transfers.unlinkTransfer(pairId);
      }
    }
    var kept = 0;
    var removed = 0;
    var reverted = 0;
    for (final id in ids) {
      if (await _isAdopted(id)) {
        kept++;
        continue;
      }
      final res = await _txRepo.deleteTransaction(id);
      if (res.isRight()) removed++;
    }
    // Düzeltilen kayıtlar eski tutarlarına (ve referanslarına) döner.
    for (final original in originals) {
      final id = original.id;
      if (id != null && await _isAdopted(id)) {
        kept++;
        continue;
      }
      final res = await _txRepo.updateTransaction(original);
      if (res.isRight()) reverted++;
    }
    // Künye bakiye senkronundan ÖNCE (commit'teki sırayla aynı gerekçe).
    final cardReverted = await _revertCardStatement();
    await _metrics.syncBalance(_walletId);
    _notifier.notify(userId: _userId, walletId: _walletId);
    for (final other in touched) {
      _notifier.notify(userId: _userId, walletId: other);
    }
    emit(const BankImportInitial());
    return ImportUndoResult(
      removed: removed,
      reverted: reverted,
      kept: kept,
      cardStatementReverted: cardReverted,
    );
  }

  /// Satır bu arada bir kayda bağlandı mı (taze okuma). Okunamazsa `false`:
  /// silme/geri yazma zaten kendi hatasını verir.
  Future<bool> _isAdopted(String id) async =>
      (await _txRepo.getTransactionById(id))
          .fold((_) => false, (t) => t.isAdopted);

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

  /// Test tohumu: ayrıştırılmış HAM taslakları gerçek inceleme kurulumundan
  /// (tahmin, tekrar tespiti, hedef önerisi, kapanış bakiyesi) geçirir —
  /// dosya okumadan. [debugSeedReview] bu adımları atlar.
  @visibleForTesting
  Future<void> debugParsed({
    required String userId,
    required String walletId,
    required List<ImportDraft> raw,
    List<double?> balances = const [],
    StatementVerification verification = StatementVerification.none,
    BalanceReconciliation? reconciliation,
    CardStatementFacts? cardFacts,
    String? sourceKey,
    List<CategoryEntity> expenseCategories = const [],
    List<CategoryEntity> incomeCategories = const [],
  }) async {
    _userId = userId;
    _walletId = walletId;
    _balances = balances;
    _verification = verification;
    _reconciliation = reconciliation;
    _cardFacts = cardFacts;
    _sourceKey = sourceKey;
    _expenseCats = expenseCategories;
    _incomeCats = incomeCategories;
    await _toReview(raw, 0);
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
    CardStatementFacts? cardFacts,
  }) {
    _userId = userId;
    _walletId = walletId;
    _cardFacts = cardFacts;
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
      leftovers: _leftoversFor(drafts),
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
    int relocated = 0,
    int relocatedDrafts = 0,
    int unresolvedLeftovers = 0,
    List<LinkSuggestion> linkSuggestions = const [],
    bool cardStatementSaved = false,
    int futureInstallments = 0,
    int linkedTransfers = 0,
  }) async {
    final walletRes = await _metrics.walletRepository.getWalletById(_walletId);
    final balance = walletRes.fold((_) => 0.0, (w) => w?.balance ?? 0.0);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final hasOutOfMonthRows = committed.any(
      (d) => d.date.isBefore(monthStart) || d.date.isAfter(monthEnd),
    );
    DateTime? first;
    DateTime? last;
    for (final d in committed) {
      if (first == null || d.date.isBefore(first)) first = d.date;
      if (last == null || d.date.isAfter(last)) last = d.date;
    }

    // Kapanış kıyası yalnız hesap ekstresinde ve aynı birimde anlamlı: kart
    // cüzdanının bakiyesi borçtur, yabancı birimli ekstrenin bakiyesi
    // cüzdanın biriminde değildir.
    final closing =
        (_targetIsCard || _foreignCurrency != null) ? null : _closing;
    double? ledgerAtClosing;
    if (closing != null) {
      ledgerAtClosing = await _ledgerBalanceAt(balance, closing.date);
    }

    return BankImportDone(
      added: added,
      corrected: corrected,
      relocated: relocated,
      skipped: totalDrafts - added - corrected - relocatedDrafts,
      walletId: _walletId,
      userId: _userId,
      balance: balance,
      hasPastMonthRows: hasOutOfMonthRows,
      unresolvedLeftovers: unresolvedLeftovers,
      linkSuggestions: linkSuggestions,
      cardStatementSaved: cardStatementSaved,
      futureInstallments: futureInstallments,
      linkedTransfers: linkedTransfers,
      firstDate: first,
      lastDate: last,
      closing: closing,
      ledgerAtClosing: ledgerAtClosing,
    );
  }

  /// Cüzdanın [day] günü SONUNDAKİ defter bakiyesi: bugünkü bakiyeden o
  /// günden sonra yazılmış hareketler geri çıkarılır. Bakiye defterden
  /// türediği için (bkz. `syncBalance`) bu, o günkü bakiyenin kendisidir.
  Future<double?> _ledgerBalanceAt(double balanceNow, DateTime day) async {
    final res = await _txRepo.getTransactions(
      userId: _userId,
      walletId: _walletId,
    );
    return res.fold((_) => null, (list) {
      final end = DateTime(day.year, day.month, day.day + 1);
      var after = 0.0;
      for (final t in list) {
        if (t.date.isBefore(end)) continue;
        after += t.isIncome ? t.amount : -t.amount;
      }
      return ((balanceNow - after) * 100).round() / 100;
    });
  }

  // --- içe aktarım geçmişi ---

  /// Son içe aktarımlar (en yenisi önce), defterdeki `importBatchId`'lerden
  /// kurulur — ayrı bir kayıt tutulmaz, yani satırlar silindikçe liste de
  /// kendiliğinden küçülür. Bitiş ekranından çıkıldıktan SONRA da bir içe
  /// aktarımı tek seferde geri almayı sağlar: eskiden bu imkân bitiş
  /// ekranıyla birlikte kayboluyor, 157 satırı tek tek silmek gerekiyordu.
  Future<List<ImportBatch>> importHistory({
    required String userId,
    int limit = 5,
  }) async {
    final wallets = (await _metrics.walletRepository.getWallets(userId))
        .fold((_) => const <WalletEntity>[], (l) => l);
    final groups = <String, List<TransactionEntity>>{};
    for (final w in wallets) {
      if (w.id == null) continue;
      final txs = (await _txRepo.getTransactions(
        userId: userId,
        walletId: w.id!,
      ))
          .fold((_) => const <TransactionEntity>[], (l) => l);
      for (final t in txs) {
        final batch = t.importBatchId;
        if (batch != null) groups.putIfAbsent(batch, () => []).add(t);
      }
    }
    final batches = <ImportBatch>[];
    for (final MapEntry(key: id, value: rows) in groups.entries) {
      final importedAt = importedAtOf(id);
      if (importedAt == null) continue;
      final wallet = wallets.where((w) => w.id == rows.first.walletId);
      var first = rows.first.date;
      var last = rows.first.date;
      for (final t in rows) {
        if (t.date.isBefore(first)) first = t.date;
        if (t.date.isAfter(last)) last = t.date;
      }
      batches.add(ImportBatch(
        id: id,
        walletId: rows.first.walletId,
        walletName: wallet.isEmpty
            ? rows.first.walletId
            : familyLabel(wallet.first, wallets),
        count: rows.length,
        importedAt: importedAt,
        firstDate: first,
        lastDate: last,
      ));
    }
    batches.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return batches.take(limit).toList();
  }

  /// UUIDv7 kimliğinin içindeki yazılma anı (ilk 48 bit, milisaniye);
  /// kimlik v7 değilse `null`.
  @visibleForTesting
  static DateTime? importedAtOf(String id) {
    final hex = id.replaceAll('-', '');
    if (hex.length != 32 || hex[12] != '7') return null;
    final ms = int.tryParse(hex.substring(0, 12), radix: 16);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Geçmişteki bir içe aktarımı geri alır: o partinin HÂLÂ duran satırları
  /// silinir, bu arada bir kayda bağlananlar yerinde kalır ([undoImport] ile
  /// aynı gerekçe). Tutar düzeltmeleri ve kart künyesi burada geri alınamaz —
  /// onların önceki hâli yalnız bitiş ekranındayken bellekte tutuluyor.
  Future<ImportUndoResult> undoBatch(ImportBatch batch,
      {required String userId}) async {
    final txs = (await _txRepo.getTransactions(
      userId: userId,
      walletId: batch.walletId,
    ))
        .fold((_) => const <TransactionEntity>[], (l) => l)
        .where((t) => t.importBatchId == batch.id);
    var removed = 0;
    var kept = 0;
    for (final t in txs) {
      final id = t.id;
      if (id == null) continue;
      if (t.isAdopted) {
        kept++;
        continue;
      }
      if ((await _txRepo.deleteTransaction(id)).isRight()) removed++;
    }
    // Aynı parti bu oturumun bitiş ekranında da duruyorsa oradaki "geri al"
    // ikinci kez silmeye çalışmasın.
    _lastImportedIds = [
      for (final id in _lastImportedIds)
        if (!txs.any((t) => t.id == id)) id,
    ];
    await _metrics.syncBalance(batch.walletId);
    _notifier.notify(userId: userId, walletId: batch.walletId);
    return ImportUndoResult(removed: removed, kept: kept);
  }
}

/// Karta yazılan ekstre künyesi ve yazımdan önceki kart bilgisi (bkz.
/// [BankImportCubit._revertCardStatement]).
class _CardStatementWrite {
  final CardStatement written;
  final CreditCardInfo before;

  /// Künyeyle birlikte yazılan limit (`null` → limit yazılmadı).
  final double? limitWritten;

  /// Kartta son 4 hane yokken künyeden yazılan değer (`null` → yazılmadı).
  final String? last4Written;

  const _CardStatementWrite({
    required this.written,
    required this.before,
    required this.limitWritten,
    required this.last4Written,
  });
}
