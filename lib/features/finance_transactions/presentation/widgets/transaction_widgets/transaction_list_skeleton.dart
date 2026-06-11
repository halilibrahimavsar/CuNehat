import 'package:flutter/material.dart';

/// İşlem listesi için premium yükleme iskeleti (shimmer/nabız).
///
/// Ek paket kullanmadan tek bir [AnimationController] ile tüm placeholder
/// satırlara yumuşak bir opaklık nabzı uygular.
class TransactionListSkeleton extends StatefulWidget {
  final int itemCount;

  const TransactionListSkeleton({super.key, this.itemCount = 7});

  @override
  State<TransactionListSkeleton> createState() =>
      _TransactionListSkeletonState();
}

class _TransactionListSkeletonState extends State<TransactionListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: widget.itemCount,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        // Araya ~her 3 satırda bir tarih başlığı iskeleti serpiştir.
        final isHeader = index % 3 == 0;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = 0.35 + (_controller.value * 0.35);
            return Opacity(
              opacity: t,
              child: isHeader
                  ? _buildHeaderSkeleton(context)
                  : _buildRowSkeleton(context),
            );
          },
        );
      },
    );
  }

  Color _bone(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10);

  Widget _box(BuildContext context,
      {double? width, double height = 12, double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _bone(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildHeaderSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration:
                BoxDecoration(color: _bone(context), shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(context, width: 120, height: 13),
              const SizedBox(height: 6),
              _box(context, width: 80, height: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(color: _bone(context), shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(context, width: 140, height: 13),
                  const SizedBox(height: 8),
                  _box(context, width: 90, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _box(context, width: 64, height: 14),
          ],
        ),
      ),
    );
  }
}
