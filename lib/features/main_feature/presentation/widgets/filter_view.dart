import 'package:cunehat/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class FilterView extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onTap;

  const FilterView({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tarih Aralığı:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Text(
                    '${AppFormatters.dateShort.format(startDate)} - ${AppFormatters.dateShort.format(endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
