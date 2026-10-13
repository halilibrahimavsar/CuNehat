import 'package:cunehat/core/error/error_handling.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/finance_transactions/domain/category_starter_pack.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/install_starter_pack_usecase.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart';
import 'package:dartz/dartz.dart';

/// Karşılama ekranındaki "Başla"nın yaptığı iş: ilk cüzdanı ve hazır kategori
/// setini TEK dokunuşla kurar.
///
/// Eskiden ilk harcamadan önce kullanıcı sırasıyla şunlardan geçiyordu:
/// gizlilik diyaloğu → bildirim diyaloğu → "İlk Cüzdanı Oluştur" → adı zorunlu
/// cüzdan formu → kategori seti seçimi → hızlı başlangıç sayfası → altı tur
/// adımı. Hiçbiri "150 TL market harcadım, nereye yazacağım" sorusuna cevap
/// değil. Uygulamayı hiç bilmeyen biri için doğru varsayılanlar zaten belli:
/// tek cüzdan, yerel para birimi, hazır setin tamamı. Hepsi sonradan
/// değiştirilebilir (cüzdan formu, kategori yöneticisi).
///
/// **Cüzdan yalnız kullanıcı istediğinde doğar.** Açılışta sessizce
/// oluşturulsaydı "cihaz boş" tespiti bozulurdu: `BackupSummary.recordCount`
/// cüzdanı da sayar ve otomatik yedeğin "boş veriyle Drive'daki dolu yedeği
/// ezme" kapısı (`GoogleDriveBackupService`) bu sayıya bakar. Yedeğini geri
/// yüklemek için uygulamayı açan kullanıcı, daha "Yedeğim var"a dokunmadan
/// boş olmayan bir cihaza sahip olurdu.
class FirstWalletSetup {
  final WalletCreateUseCase _createWallet;
  final WalletSetActiveUseCase _setActive;
  final InstallStarterPackUseCase _installStarterPack;

  FirstWalletSetup(
    this._createWallet,
    this._setActive,
    this._installStarterPack,
  );

  /// Cüzdanı kurar, aktif yapar, kimliğini döner.
  ///
  /// Üç yazım art arda gelir (cüzdan, aktif cüzdan, kategoriler). Cüzdan
  /// akışı 150 ms'lik bir bekletmeyle yayın yaptığı için kabuk bunları TEK
  /// durum olarak görür: karşılama ekranından doğrudan dolu deftere geçilir.
  ///
  /// Aktifleştirme ya da kategori kurulumunun hatası cüzdanı GERİ ALMAZ ve
  /// akışı düşürmez: aktif cüzdan yoksa `WalletBloc` ilk cüzdana düşer;
  /// kategoriler formdaki "hazır setten kur" yolundan tamamlanır. (Kategori
  /// deposu `Either` değil exception fırlatır.)
  Future<Either<Failure, String>> call({
    required String userId,
    required String name,
    required double openingBalance,
    required String currency,
    required String languageCode,
    DateTime? now,
  }) async {
    final createdAt = now ?? DateTime.now();
    final balance = roundToCents(openingBalance);
    final walletId = UidGenerator.generateV7();

    final created = await _createWallet(
      WalletEntity(
        id: walletId,
        userId: userId,
        name: name,
        balance: balance,
        debt: 0,
        credit: 0,
        investment: 0,
        colorHex: defaultColorHex,
        iconName: defaultIconName,
        createdAt: createdAt,
        sortOrder: createdAt.millisecondsSinceEpoch,
        // Defter değişmezinin çapası: balance = opening + Σtx (henüz işlem yok).
        openingBalance: balance,
        currency: currency,
      ),
    );
    if (created.isLeft()) return created;

    final activated = await _setActive(userId: userId, walletId: walletId);
    activated.fold(
      (failure) => reportError(
        'İlk cüzdan · aktifleştirme',
        failure.message,
        StackTrace.current,
      ),
      (_) {},
    );

    try {
      await _installStarterPack(
        [
          for (final group in CategoryStarterPack.expense)
            (group: group, isExpense: true),
          for (final group in CategoryStarterPack.income)
            (group: group, isExpense: false),
        ],
        languageCode: languageCode,
        walletId: walletId,
      );
    } catch (e, st) {
      reportError('İlk cüzdan · kategori seti', e, st);
    }
    return created;
  }

  /// Cüzdan formunun yeni cüzdan varsayılanlarıyla aynı.
  static const String defaultColorHex = '0xFF2196F3';
  static const String defaultIconName = 'account_balance_wallet';
}
