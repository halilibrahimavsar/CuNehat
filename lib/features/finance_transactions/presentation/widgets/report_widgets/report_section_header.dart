import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:flutter/material.dart';

/// Rapor sayfasındaki bölüm başlığı (+ isteğe bağlı sağ kontrol).
///
/// [Row] DEĞİL, [Wrap]: başlık ile kontrol aynı satıra sığmadığında satır
/// taşmak yerine alta iner. Ölçüldü (gerçek Roboto, 360dp): "Kategori
/// Dağılımı" + 144dp'lik mod seçici metin ölçeği 1.0'da 59,6px boşlukla
/// sığıyor ama **1.5'te 2,6px taşıyordu**; İngilizce "Category Distribution"
/// zaten **1.3'te 15,2px** taşıyordu. Erişilebilirlik ayarı açık bir
/// kullanıcı sarı-siyah taşma şeridi görüyordu.
class ReportSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  /// Sayfa başlığı bölüm başlıklarından bir tık büyük yazılır.
  final double? fontSize;

  const ReportSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleWidget = Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
    );

    if (trailing == null) return titleWidget;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [titleWidget, trailing!],
    );
  }
}

/// Zaman grafiklerinin çözünürlük seçicisi: Gün / Hafta / Ay.
///
/// Neden var: aralık uzayınca günlük çubuklar okunmaz oluyordu. "Son 3 Ay"
/// ≈ 90 kova × ~6,75px = 607px genişlik ister, oysa telefonda ~282px var;
/// "Bu Yıl" 365 kova demekti. Otomatik seçim ([ReportSeriesService.
/// autoUnitFor]) makul bir varsayılan verir, bu seçici de kullanıcıya
/// yoğun bir ayı seyreltme ya da bir çeyreğe yakınlaşma imkânı bırakır.
///
/// Kova sayısı [maxBuckets]'i aşan seçenek KAPATILIR (tıklanamaz): açık
/// bırakıp okunmaz bir grafik çizmek seçenek değil, tuzaktır.
class ReportUnitSelector extends StatelessWidget {
  final ReportBucketUnit selected;
  final ValueChanged<ReportBucketUnit> onChanged;

  /// Her çözünürlüğün üreteceği kova sayısı (`unit → adet`).
  final Map<ReportBucketUnit, int> bucketCounts;

  /// Bu sayıdan çok kova okunmaz kabul edilir.
  final int maxBuckets;

  const ReportUnitSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.bucketCounts,
    this.maxBuckets = 62,
  });

  String _label(BuildContext context, ReportBucketUnit unit) =>
      switch (unit) {
        ReportBucketUnit.day => context.l10n.reportUnitDay,
        ReportBucketUnit.week => context.l10n.reportUnitWeek,
        ReportBucketUnit.month => context.l10n.reportUnitMonth,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.reportUnitSelectorLabel,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final unit in ReportBucketUnit.values)
            () {
              final count = bucketCounts[unit] ?? 0;
              // Tek kovaya inen çözünürlük de anlamsız: "Bu Ay" için "Ay"
              // seçeneği tek bir çubuk çizerdi.
              final enabled = count > 1 && count <= maxBuckets;
              return ChoiceChip(
                label: Text(_label(context, unit)),
                selected: selected == unit,
                onSelected: enabled ? (_) => onChanged(unit) : null,
                tooltip: enabled
                    ? null
                    : context.l10n.reportUnitTooDense(count.toString()),
                visualDensity: VisualDensity.compact,
              );
            }(),
        ],
      ),
    );
  }
}
