import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/filter_entity.dart';
import 'package:flutter/material.dart';

class CompactFilterInfo extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final DataFilter? dataFilter;
  final VoidCallback? onDateTap;
  final bool
      isLightMode; // True: Header için (Beyaz metin), False: BottomSheet için (Renkli)

  const CompactFilterInfo({
    super.key,
    required this.startDate,
    required this.endDate,
    this.dataFilter,
    this.onDateTap,
    this.isLightMode = true,
  });

  @override
  Widget build(BuildContext context) {
    // Tarih Badge Mantığı
    String? dateBadgeText;
    Color dateBadgeColor = isLightMode ? Colors.white : Colors.blue;

    final now = DateTime.now();
    final isToday = startDate.year == now.year &&
        startDate.month == now.month &&
        startDate.day == now.day &&
        endDate.year == now.year &&
        endDate.month == now.month &&
        endDate.day == now.day;
    final isThisMonth = !isToday &&
        startDate.year == now.year &&
        startDate.month == now.month &&
        endDate.year == now.year &&
        endDate.month == now.month;

    if (isToday) {
      dateBadgeText = 'BUGÜN';
      dateBadgeColor = isLightMode ? Colors.greenAccent : Colors.green;
    } else if (isThisMonth) {
      dateBadgeText = 'BU AY';
      dateBadgeColor = isLightMode ? Colors.amberAccent : Colors.orange;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // 1. Tarih Aralığı + Badge
          _buildInfoChip(
            icon: isLightMode
                ? Icons.calendar_month_rounded
                : Icons.calendar_today,
            text:
                '${AppFormatters.dateShort.format(startDate)} - ${AppFormatters.dateShort.format(endDate)}',
            badgeText: dateBadgeText,
            badgeColor: dateBadgeColor,
            onTap: onDateTap,
            isPrimary: true,
          ),

          // 2. Aktif Filtreler (Varsa göster)
          if (dataFilter != null) ..._buildActiveFilterChips(dataFilter!),
        ],
      ),
    );
  }

  List<Widget> _buildActiveFilterChips(DataFilter filter) {
    List<Widget> chips = [];

    // Kategori Filtresi
    if (filter.selectedCategories.isNotEmpty) {
      chips.add(const SizedBox(width: 8));
      chips.add(_buildInfoChip(
        icon: isLightMode ? Icons.category_rounded : Icons.category_outlined,
        text: '${filter.selectedCategories.length} Kategori',
        backgroundColor: isLightMode
            ? Colors.orange.shade400.withValues(alpha: 0.9)
            : Colors.orange.shade100,
        textColor: isLightMode ? Colors.white : Colors.orange.shade800,
        borderColor: isLightMode ? null : Colors.orange.shade300,
      ));
    }

    // Fiyat Filtresi
    if (filter.priceRange != null && filter.priceRange!.isNotEmpty) {
      chips.add(const SizedBox(width: 8));
      chips.add(_buildInfoChip(
        icon: isLightMode ? Icons.attach_money_rounded : Icons.attach_money,
        text: filter.priceRange.toString(),
        backgroundColor: isLightMode
            ? Colors.green.shade400.withValues(alpha: 0.9)
            : Colors.green.shade100,
        textColor: isLightMode ? Colors.white : Colors.green.shade800,
        borderColor: isLightMode ? null : Colors.green.shade300,
      ));
    }

    return chips;
  }

  Widget _buildInfoChip({
    IconData? icon,
    required String text,
    String? badgeText,
    Color? badgeColor,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    bool isPrimary = false,
  }) {
    // Tema renklerini belirle
    final baseTextColor =
        textColor ?? (isLightMode ? Colors.white : Colors.blue.shade800);
    final baseBgColor = backgroundColor ??
        (isLightMode
            ? (isPrimary
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.15))
            : Colors.blue.shade50);
    final baseBorderColor = borderColor ??
        (isLightMode
            ? Colors.white.withValues(alpha: isPrimary ? 0.4 : 0.2)
            : Colors.blue.shade200);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: baseBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: baseBorderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: baseTextColor),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                color: baseTextColor,
                fontSize: 12,
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLightMode
                      ? (badgeColor ?? Colors.white).withValues(alpha: 0.2)
                      : (badgeColor ?? Colors.blue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isLightMode
                        ? (badgeColor ?? Colors.white).withValues(alpha: 0.5)
                        : (badgeColor ?? Colors.blue).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? baseTextColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
