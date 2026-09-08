import 'package:cunehat/config/initialization/app_initialization.dart';
import 'package:cunehat/core/models/legacy_safe_adapters.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// **Kayıt sırası ve kayıt TİPİ kilidi.**
///
/// `AppInitialization.registerTypeAdapters` bir typeId zaten kayıtlıysa ATLAR
/// (ikinci kayıt `HiveError` fırlatır; init hata ekranındaki "Tekrar Dene"
/// güvenli kalmalı). Bunun sessiz bedeli şudur: bir typeId için listeye ÖNCE
/// giren adapter kazanır. Biri ham (üretilen) adapter'ı `Safe*` varyantından
/// önce eklerse, `legacy_safe_adapters.dart`'ın tüm koruması devre dışı kalır
/// ve **hiçbir test kırılmaz** — çünkü diğer testlerin hepsi adapter'ı kendisi
/// register ediyor, üretimdeki listeyi kimse ölçmüyordu.
///
/// Bedeli hatırlatma: ham adapter eski kayıtta `null as double` yapar,
/// `openBox` kutunun BÜTÜN karelerini okur, yani tek bir eski kayıt kutuyu
/// tamamen açılamaz hâle getirir — uygulama hiç açılmaz.
void main() {
  group('AppInitialization.adapterRegistrations', () {
    test('aynı typeId listede iki kez geçmez', () {
      final seen = <int, String>{};
      for (final registration in AppInitialization.adapterRegistrations) {
        final clash = seen[registration.typeId];
        expect(
          clash,
          isNull,
          reason: 'typeId ${registration.typeId} hem $clash hem '
              '${registration.adapter.runtimeType} tarafından talep ediliyor; '
              'kayıt sırasında İLKİ kazanır, ikincisi sessizce yok sayılır.',
        );
        seen[registration.typeId] = '${registration.adapter.runtimeType}';
      }
    });

    test('geç eklenen alanı olan 5 model için Safe varyant kayıtlı', () {
      // Beklenen sınıflar isimle sabitlendi: `is SafeXAdapter` kontrolü
      // yetmezdi çünkü Safe sınıflar ham adapter'dan TÜREVİ — ters yönde
      // (`ham is Safe`) yanlış negatif, doğru yönde (`Safe is ham`) yanlış
      // pozitif verir. Ölçülmesi gereken çalışma-zamanı tipinin KENDİSİ.
      final expected = <TypeAdapter<dynamic>>[
        SafeInvestmentModelAdapter(),
        SafeDebtModelAdapter(),
        SafeReceivableModelAdapter(),
        SafePaymentModelAdapter(),
        SafeRecurringTransactionModelAdapter(),
      ];

      for (final safe in expected) {
        final matching = AppInitialization.adapterRegistrations
            .where((r) => r.typeId == safe.typeId)
            .toList();

        expect(
          matching,
          hasLength(1),
          reason: 'typeId ${safe.typeId} için tam olarak bir adapter '
              'beklenirdi (${safe.runtimeType}).',
        );
        expect(
          matching.single.adapter.runtimeType,
          safe.runtimeType,
          reason: 'typeId ${safe.typeId} ham adapter ile kayıtlı. Eski '
              'kayıtlar TypeError fırlatır ve kutu hiç açılmaz — '
              '${safe.runtimeType} kullanılmalı.',
        );
      }
    });

    test('hiçbir adapter `dynamic` için kaydedilmez', () {
      // Hive `registerAdapter<T>`'deki T'yi saklar ve YAZARKEN onunla eşleşir.
      // T `dynamic`'e düşerse o adapter HER değere uyar ve listedeki ilki
      // bütün yazma isteklerini üstlenir. Ölçüldü: cüzdan adapter'ı alacak
      // kaydını yazmaya çalışıp `type 'ReceivableModel' is not a subtype of
      // type 'WalletModel'` fırlattı — yani kutular bozulur.
      final registry = _RecordingRegistry();
      AppInitialization.registerTypeAdapters(registry);

      for (final entry in registry.registeredTypes.entries) {
        expect(
          entry.value,
          isNot(dynamic),
          reason: 'typeId ${entry.key} `dynamic` için kaydedildi; Hive bu '
              'adapter\'ı her değere uyan sayar.',
        );
      }
    });

    test('her model kendi tipiyle kaydedilir', () {
      final registry = _RecordingRegistry();
      AppInitialization.registerTypeAdapters(registry);

      expect(registry.registeredTypes[4], InvestmentModel);
      expect(registry.registeredTypes[6], DebtModel);
      expect(registry.registeredTypes[7], ReceivableModel);
      expect(registry.registeredTypes[9], PaymentModel);
      expect(registry.registeredTypes[11], RecurringTransactionModel);
    });

    test('kayıt iki kez çağrılabilir (init hata ekranı "Tekrar Dene")', () {
      final registry = _RecordingRegistry();

      AppInitialization.registerTypeAdapters(registry);
      final afterFirst = registry.registeredTypes.length;
      expect(afterFirst, AppInitialization.adapterRegistrations.length);

      AppInitialization.registerTypeAdapters(registry);
      expect(
        registry.registeredTypes.length,
        afterFirst,
        reason: 'İkinci çağrı hiçbir şey eklememeli; eklerse Hive HiveError '
            'fırlatır ve init hata ekranı kurtarılamaz olur.',
      );
    });
  });
}

/// Küresel `Hive`'ı kirletmeden kayıt davranışını ölçen minimal registry.
/// `registerAdapter`'ın tip argümanını da saklar — asıl ölçülen o.
class _RecordingRegistry implements TypeRegistry {
  final Map<int, Type> registeredTypes = {};

  @override
  void registerAdapter<T>(TypeAdapter<T> adapter,
      {bool internal = false, bool override = false}) {
    if (registeredTypes.containsKey(adapter.typeId) && !override) {
      throw HiveError(
          'there is already a TypeAdapter for typeId ${adapter.typeId}');
    }
    registeredTypes[adapter.typeId] = T;
  }

  @override
  bool isAdapterRegistered(int typeId, {bool internal = false}) =>
      registeredTypes.containsKey(typeId);

  @override
  void ignoreTypeId<T>(int typeId) => throw UnimplementedError();
}
