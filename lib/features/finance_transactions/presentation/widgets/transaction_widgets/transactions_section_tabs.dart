import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/labeled_segment.dart';
import 'package:cunehat/features/credit_card/presentation/card_context_rail.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
import 'package:flutter/material.dart';

/// İşlemler · İçgörü · Rapor sekme şeridi — üç sayfanın tepesinde.
///
/// İçgörü ve Rapor eskiden yalnız alt sürgü düğmesinin üstündeki/altındaki
/// küçük etiketle (ya da dikey kaydırmayla) açılıyordu; cihazda üç sayfayı
/// gezen kullanıcı ikisinin varlığını keşfetmek için sürgüyü denemek
/// zorundaydı. Sürgü aynen çalışır; bu, görünür ikinci yoldur.
///
/// Her sayfa kendi kopyasını [current] ile kurar (dikey geçişte iki yüzde de
/// aynı şerit görünür). Dokunuş kabuğa [HomeNavigationRequests] üzerinden
/// gider: gezinme denetleyicisi ana sayfanın durumunda yaşıyor.
class TransactionsSectionTabs extends StatelessWidget {
  final TransactionsSection current;

  const TransactionsSectionTabs({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LabeledSegment<TransactionsSection>(
      asTabs: true,
      selected: current,
      onChanged: (section) {
        if (getIt.isRegistered<HomeNavigationRequests>()) {
          getIt<HomeNavigationRequests>().openSection(section);
        }
      },
      // Uygulamanın işlem mavisi: temanın varsayılan birincil rengi (mor)
      // kabuğun hiçbir yerinde kullanılmıyor, sekme yabancı duruyordu.
      items: [
        SegmentItem(
            value: TransactionsSection.ledger,
            label: l10n.sectionTabTransactions,
            color: AppGradients.transactions),
        SegmentItem(
            value: TransactionsSection.insights,
            label: l10n.menuDetails,
            color: AppGradients.transactions),
        SegmentItem(
            value: TransactionsSection.report,
            label: l10n.menuReport,
            color: AppGradients.transactions),
      ],
    );
  }
}

/// Üç sayfanın ortak tepesi: kart bağlam şeridi + sekme şeridi.
///
/// Sayfanın yükleniyor/boş hâllerinde de çizilir — sekmeler gezinmedir,
/// verisiz bir sayfada kaybolmamalı. Kart şeridi eskiden yalnız İşlemler'de
/// vardı: İçgörü ya da Rapor'a geçen kullanıcı hangi kartın (hesabın)
/// rakamlarına baktığını göremiyordu.
class TransactionsSectionHeader extends StatelessWidget {
  final TransactionsSection current;

  const TransactionsSectionHeader({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CardContextRail(pillsOnly: current != TransactionsSection.ledger),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TransactionsSectionTabs(current: current),
        ),
      ],
    );
  }
}
