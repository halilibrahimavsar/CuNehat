/// Zaman-serisi rapor grafiklerinin (haftalık net akış, bakiye trendi) ortak
/// eksen yardımcıları.
library;

import 'package:cunehat/features/finance_transactions/domain/services/report_series_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// "13 Haz" etiketinin yan yana durabilmesi için gereken yatay yer.
/// Etiketin kendisi ~34px; kalanı iki komşu arasındaki nefes payı.
const double kDateLabelSlot = 48;

/// [kDateLabelSlot]'un erişilebilirlik yazı ölçeğine göre büyütülmüş hâli.
/// Eksen etiketleri de `Text` olduğu için sistem yazı boyutu büyüdüğünde
/// genişliyorlar; sabit slotla hesaplarsak büyük yazıda etiketler yine
/// üst üste binerdi.
double scaledDateLabelSlot(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(kDateLabelSlot);

/// Sol eksen etiketlerine ayrılan genişlik; alt eksenin kullanabileceği
/// alanı hesaplarken düşülür.
const double kValueAxisWidth = 46;

/// Alt eksende KAÇ noktada bir etiket basılacağı.
///
/// Her noktaya etiket basmak 30 günlük veride yazıları üst üste bindiriyordu
/// (grafikler bunu `interval: 1` ile yapıyordu). Kullanılabilir genişliğe kaç
/// etiket sığıyorsa o kadarını gösteririz; dönen değer "her N noktada bir"dir
/// ve en az 1'dir.
int dateLabelStep({
  required int pointCount,
  required double availableWidth,
  double slotWidth = kDateLabelSlot,
}) {
  if (pointCount <= 1) return 1;
  // Sınırsız genişlikte (.floor() sonsuzda patlar) seyreltmeye gerek yok.
  if (!availableWidth.isFinite) return 1;
  final fits = (availableWidth / slotWidth).floor();
  if (fits >= pointCount) return 1;
  // Hiç sığmıyorsa tek etiket kalsın (0'a bölme ve step<1 durumunu kapatır).
  if (fits <= 1) return pointCount;
  return (pointCount / fits).ceil();
}

/// Grafik altındaki gün etiketi. Ay adı [Intl.defaultLocale]'den gelir.
String chartDateLabel(DateTime date) => DateFormat('dd MMM').format(date);

/// Tooltip başlığındaki tam tarih (gün + ay + yıl).
String chartTooltipDate(DateTime date) => DateFormat('d MMMM y').format(date);

/// Bir zaman kovasının alt eksen etiketi.
///
/// Ay kovasında yıl da yazılır ("Oca 26"): bir yıldan uzun aralıklarda
/// yalnız ay adı iki farklı yılın aynı ayını ayırt edemezdi.
String bucketAxisLabel(ReportBucket bucket, ReportBucketUnit unit) =>
    switch (unit) {
      ReportBucketUnit.day => chartDateLabel(bucket.start),
      ReportBucketUnit.week => chartDateLabel(bucket.start),
      ReportBucketUnit.month => DateFormat('MMM yy').format(bucket.start),
    };

/// Bir zaman kovasının tooltip başlığı.
///
/// Hafta kovasında ARALIK yazılır ("1 – 7 Haziran 2026"): tek bir tarih,
/// yanındaki tutarın yedi günün toplamı olduğunu gizlerdi.
String bucketTooltipDate(ReportBucket bucket, ReportBucketUnit unit) {
  switch (unit) {
    case ReportBucketUnit.day:
      return chartTooltipDate(bucket.start);
    case ReportBucketUnit.week:
      final end = bucket.endExclusive.subtract(const Duration(days: 1));
      final sameMonth =
          bucket.start.year == end.year && bucket.start.month == end.month;
      final startText = sameMonth
          ? DateFormat('d').format(bucket.start)
          : DateFormat('d MMM').format(bucket.start);
      return '$startText – ${chartTooltipDate(end)}';
    case ReportBucketUnit.month:
      return DateFormat('MMMM y').format(bucket.start);
  }
}

/// Grafik tooltip'lerinin ortak metin stili — iki grafikte de aynı.
const TextStyle kChartTooltipStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.bold,
  fontSize: 11,
);

/// Eksen (sayı/tarih) etiketlerinin ortak stili.
TextStyle chartAxisLabelStyle(ColorScheme scheme) => TextStyle(
      fontSize: 9,
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.bold,
    );
