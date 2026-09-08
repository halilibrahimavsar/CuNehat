/// Eski Hive kayıtlarını okuyabilen adapter'lar.
///
/// ## Sorun
///
/// `CLAUDE.md` kuralı açık: *"Yeni alan eklenirken eski kayıtlarda o alan
/// YOKTUR: alan ya nullable olmalı ya da okuma tarafında güvenli bir
/// varsayılana düşmeli."* Üretilen adapter'lar bunu yapmaz — geç eklenmiş
/// non-null bir alan için `fields[15] as double` yazarlar ve alan yoksa
/// `null as double` → **TypeError**.
///
/// Bedeli tek bir kayıt değil: `openBox` kutunun bütün karelerini okur, yani
/// TEK bir eski kayıt o kutuyu tamamen açılamaz hâle getirir. Ölçüldü — beş
/// modelin beşi de eski kayıtta `TypeError` fırlatıyordu:
/// `InvestmentModel` (alan 15, v8), `DebtModel` (13/17/18/19/20, v6),
/// `PaymentModel` (3/4, v6), `ReceivableModel` (8, v4),
/// `RecurringTransactionModel` (10, v3).
///
/// Kapalı test 28 Ağustos'ta başladığı ve bu alanların hepsi ondan ÖNCE
/// eklendiği için 13 testerın kayıtları güvenli; risk geliştiricinin kendi
/// cihazı ve dahili test kurulumlarındadır. Yine de kural kuraldır ve bedeli
/// "uygulama hiç açılmıyor" olan bir hata varsayıma bırakılmaz.
///
/// ## Çözüm ve neden BÖYLE
///
/// Adapter'lar elle yeniden yazılMADI; üretilen adapter'dan TÜRETİLİP yalnız
/// `read` ezildi. Böylece **yazma yolu tek kaynak** olarak üretilen kodda
/// kalır: alan sırasının iki yerde ayrı ayrı elle tutulması, sessiz veri
/// kaybının en kolay yoluydu. (`WalletModel` tamamen elle yazılmıştır; o
/// dosya bu sınıftan önce vardı ve `@HiveType` taşımıyor.)
///
/// ## Yeni alan eklerken
///
/// Buradaki `read` üretilen `write` ile SENKRON kalmak zorundadır: yazılan
/// ama burada okunmayan bir alan, ilk yazımda sessizce kaybolur. Kaymayı
/// `test/features/legacy_safe_adapters_test.dart` içindeki gidiş-dönüş
/// testleri yakalar — yeni alan eklerken o testler de güncellenmeli.
library;

import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_calc_mode.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/recurring_transactions/data/models/recurring_transaction_model.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:flutter/material.dart' show Color;
import 'package:hive/hive.dart';

/// Kare başlığını okuyup `{alanIndeksi: değer}` haritası kurar — üretilen
/// adapter'ların hepsi tam olarak bunu yapar.
Map<int, dynamic> readFieldMap(BinaryReader reader) {
  final numOfFields = reader.readByte();
  return <int, dynamic>{
    for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
  };
}

/// `InvestmentModel` — alan 15 (`unbookedCost`) v8'de (24 Ağu 2026) geldi.
class SafeInvestmentModelAdapter extends InvestmentModelAdapter {
  @override
  InvestmentModel read(BinaryReader reader) {
    final fields = readFieldMap(reader);
    return InvestmentModel(
      id: fields[0] as String?,
      userId: fields[1] as String,
      walletId: fields[2] as String,
      name: fields[3] as String,
      amount: fields[4] as double,
      currentValue: fields[5] as double,
      type: fields[6] as InvestmentType,
      color: fields[7] as Color,
      dateAdded: fields[8] as DateTime,
      symbol: fields[9] as String?,
      returnRate: fields[10] as double?,
      quantity: fields[12] as double?,
      goalId: fields[16] as String?,
      currency: fields[14] as String?,
      // Kavram yokken hiçbir maliyet "işlenmemiş" değildi: 0 doğru varsayılan.
      unbookedCost: fields[15] as double? ?? 0,
    );
  }
}

/// `ReceivableModel` — alan 8 (`createdAt`) v4'te (29 Tem 2026) geldi.
class SafeReceivableModelAdapter extends ReceivableModelAdapter {
  @override
  ReceivableModel read(BinaryReader reader) {
    final fields = readFieldMap(reader);
    final dueDate = fields[5] as DateTime;
    return ReceivableModel(
      id: fields[0] as String?,
      userId: fields[1] as String,
      walletId: fields[2] as String,
      debtorName: fields[3] as String,
      amount: fields[4] as double,
      dueDate: dueDate,
      // Oluşturma tarihi bilinmiyor. Vade, kayıttaki TEK tarih ve alacağın
      // kendi zamanına en yakın olanı; "bugün"e düşmek ters kayıtları
      // yaşanmamış bir aya yazardı.
      createdAt: fields[8] as DateTime? ?? dueDate,
      collectedAt: fields[9] as DateTime?,
      isPaid: fields[6] as bool,
      notes: fields[7] as String?,
    );
  }
}

/// `RecurringTransactionModel` — alan 10 (`anchorDay`) v3'te (28 Tem 2026)
/// geldi.
class SafeRecurringTransactionModelAdapter
    extends RecurringTransactionModelAdapter {
  @override
  RecurringTransactionModel read(BinaryReader reader) {
    final fields = readFieldMap(reader);
    final nextExecutionDate = fields[8] as DateTime;
    return RecurringTransactionModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      walletId: fields[2] as String,
      title: fields[3] as String,
      tag: fields[4] as String,
      amount: fields[5] as double,
      type: fields[6] as TransactionTypeModel,
      frequency: fields[7] as RecurringFrequency,
      nextExecutionDate: nextExecutionDate,
      // Çapa yokken vadenin gününden türetilir — `startingOn` fabrikası da
      // tam olarak bunu yapar. Kenetlenmiş bir tarihten (28 Şub) türetmek
      // çapayı aşağı çeker, ama alternatifi kaydı hiç okuyamamak.
      anchorDay: fields[10] as int? ?? nextExecutionDate.day,
      isActive: fields[9] as bool,
    );
  }
}

/// `PaymentModel` — alan 3 (`id`) ve 4 (`overdueInterestPart`) v6'da
/// (6 Ağu 2026) geldi.
class SafePaymentModelAdapter extends PaymentModelAdapter {
  @override
  PaymentModel read(BinaryReader reader) {
    final fields = readFieldMap(reader);
    final date = fields[0] as DateTime;
    final amount = fields[1] as double;
    return PaymentModel(
      // Kimlik ÜRETİLMEZ, TÜRETİLİR: her okumada yeni bir UUID vermek
      // ödemenin düzenlenmesini/silinmesini imkânsız kılardı (hedefleme
      // kimliğe dayanıyor). Tarih + tutar aynı kayıt için hep aynı sonucu
      // verir.
      id: fields[3] as String? ??
          'legacy-${date.microsecondsSinceEpoch}-$amount',
      date: date,
      amount: amount,
      // Gecikme faizi kavramı yokken hiçbir ödemenin faiz payı yoktu.
      overdueInterestPart: fields[4] as double? ?? 0,
      notes: fields[2] as String?,
    );
  }
}

/// `DebtModel` — alan 13/17/18/19/20 sonradan geldi (en yenisi `calcMode`,
/// v6 / 6 Ağu 2026).
class SafeDebtModelAdapter extends DebtModelAdapter {
  @override
  DebtModel read(BinaryReader reader) {
    final fields = readFieldMap(reader);
    final principalAmount = fields[5] as double;
    return DebtModel(
      id: fields[0] as String?,
      userId: fields[1] as String,
      walletId: fields[2] as String,
      title: fields[3] as String,
      // Karşı taraf bilinmiyordu; boş bırakmak kaydı okunur tutar.
      counterparty: fields[17] as String? ?? '',
      type: fields[4] as DebtType,
      // Yöntem bilinmiyorsa TAHMİN EDİLMEZ: `none` = "faizsiz, toplam =
      // ana para". Tahmin etmek borcun büyüklüğünü sessizce değiştirirdi —
      // `DebtCalcMode`'un var oluş sebebi tam olarak budur.
      calcMode: fields[20] as DebtCalcMode? ?? DebtCalcMode.none,
      principalAmount: principalAmount,
      interestRate: fields[6] as double,
      termMonths: fields[7] as int,
      overdueInterestRate: fields[13] as double? ?? 0,
      startDate: fields[8] as DateTime,
      dueDate: fields[9] as DateTime?,
      payments: (fields[14] as List?)?.cast<Payment>() ?? const <Payment>[],
      isPaid: fields[15] as bool? ?? false,
      notes: fields[16] as String?,
      // Dondurulmuş toplam yoksa ana paranın kendisi: faiz bilinmiyor.
      expectedTotalAmount: fields[18] as double? ?? principalAmount,
      // Entity'nin belgelenmiş varsayılanı.
      principalToWallet: fields[19] as bool? ?? true,
    );
  }
}
