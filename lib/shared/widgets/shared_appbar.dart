// ignore_for_file: deprecated_member_use

import 'package:cunehat/shared/widgets/wallet_managment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SharedAppbar extends StatefulWidget implements PreferredSizeWidget {
  final double currentSliderValue; // Yeni parametre
  // final VoidCallback onDateRangePressed; // Yeni callback (date range picker removing)

  const SharedAppbar({
    super.key,
    required this.currentSliderValue,
    // required this.onDateRangePressed, // Zorunlu parametre (date range picker removing)
  });

  @override
  State<SharedAppbar> createState() => _SharedAppbarState();

  @override
  Size get preferredSize => const Size(double.maxFinite, 50);
}

class _SharedAppbarState extends State<SharedAppbar> {
  // Artık state'te değer takip etmeye gerek yok, prop'tan alıyoruz

  /// Slider değerine göre AppBar rengini hesapla
  Color _getAppBarColor(double value) {
    if (value < 0.5) {
      return Color.lerp(Colors.red[700]!, Colors.blue[700]!, value * 2)!;
    } else {
      return Color.lerp(
          Colors.blue[700]!, Colors.green[700]!, (value - 0.5) * 2)!;
    }
  }

  /// Slider değerine göre AppBar gradient rengini hesapla
  List<Color> _getAppBarGradient(double value) {
    if (value < 0.5) {
      return [
        Color.lerp(Colors.red[400]!, Colors.blue[400]!, value * 2)!,
        Color.lerp(Colors.red[700]!, Colors.blue[700]!, value * 2)!,
      ];
    } else {
      return [
        Color.lerp(Colors.blue[400]!, Colors.green[400]!, (value - 0.5) * 2)!,
        Color.lerp(Colors.blue[700]!, Colors.green[700]!, (value - 0.5) * 2)!,
      ];
    }
  }

  /// Slider değerine göre ikon ve metin rengini belirle
  Color _getContentColor(double value) {
    return Colors.white;
  }

  /// Mevcut modu metin olarak göster
  String _getCurrentModeText(double value) {
    if (value < 0.25) return "Gider Modu";
    if (value > 0.75) return "Gelir Modu";
    return "Karşılaştırma Modu";
  }

  /// Mevcut mod için ikon belirle
  IconData _getCurrentModeIcon(double value) {
    if (value < 0.25) return Icons.arrow_downward;
    if (value > 0.75) return Icons.arrow_upward;
    return Icons.compare_arrows;
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = widget.currentSliderValue; // Prop'tan al

    return AppBar(
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      titleSpacing: 0,
      backgroundColor: _getAppBarColor(currentValue),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getAppBarGradient(currentValue),
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
      title: Row(
        children: [
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getContentColor(currentValue).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.transparent,
                backgroundImage: NetworkImage(
                  FirebaseAuth.instance.currentUser?.providerData[0].photoURL ??
                      "assets/images/logo.jpg",
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FirebaseAuth.instance.currentUser?.displayName ?? "Anonymous",
                  style: TextStyle(
                    fontSize: 16,
                    color: _getContentColor(currentValue),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      _getCurrentModeIcon(currentValue),
                      size: 12,
                      color: _getContentColor(currentValue).withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getCurrentModeText(currentValue),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getContentColor(currentValue).withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return WalletManagementPage();
              },
            );
          }, // Callback'i burada kullan
          icon: Icon(
            Icons.wallet_rounded,
            size: 24,
            color: _getContentColor(currentValue),
          ),
          tooltip: 'Cüzdan Yönetimi',
        ),
      ],
    );
  }
}
