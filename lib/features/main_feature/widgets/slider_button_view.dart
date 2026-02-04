import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/widgets/dynamic_slider_button.dart';

class SliderButtonView extends StatelessWidget {
  const SliderButtonView({
    super.key,
    required AnimationController controller,
    required this.context,
    required this.userId,
    required this.walletState,
  }) : _controller = controller;

  final AnimationController _controller;
  final BuildContext context;
  final String userId;
  final WalletLoadedSt walletState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: DynamicSlider(
        controller: _controller,
        onValueChanged: (value) {},
        onStateTap: (state) => {},
        miniButtons: _getMiniButtons(),
        subMenuItems: _getSubMenuItems(),
      ),
    );
  }

  Map<SliderState, List<MiniButtonData>> _getMiniButtons() {
    return {
      SliderState.savedMoney: [
        MiniButtonData(
          icon: Icons.add,
          label: 'Ekle',
          color: Colors.green,
          onTap: () => print('Birikim eklendi'),
        ),
        MiniButtonData(
          icon: Icons.remove,
          label: 'Çıkar',
          color: Colors.red,
          onTap: () => print('Birikim çıkarıldı'),
        ),
        MiniButtonData(
          icon: Icons.abc_outlined,
          label: 'Güncelle',
          color: Colors.red,
          onTap: () => print('Birikim güncellendi'),
        ),
      ],
      SliderState.transactions: [
        MiniButtonData(
          icon: Icons.send,
          label: 'Gönder',
          color: Colors.blue,
          onTap: () => print('İşlem gönderildi'),
        ),
        MiniButtonData(
          icon: Icons.download,
          label: 'Al',
          color: Colors.purple,
          onTap: () => print('İşlem alındı'),
        ),
      ],
      SliderState.debt: [
        MiniButtonData(
          icon: Icons.add,
          label: 'Borç Ekle',
          color: Colors.orange,
          onTap: () => print('Borç eklendi'),
        ),
      ],
    };
  }

  Map<SliderState, List<SubMenuItem>> _getSubMenuItems() {
    return {
      SliderState.savedMoney: [
        SubMenuItem(
          icon: Icons.account_balance,
          label: 'Header',
          onTap: () => print('header seçildi'),
          isMainTitle: true,
        ),
        SubMenuItem(
          icon: Icons.account_balance,
          label: 'Banka',
          onTap: () => print('Banka seçildi'),
          isDefault: true,
        ),
        SubMenuItem(
          icon: Icons.home,
          label: 'Ev',
          onTap: () => print('Ev seçildi'),
          isDefault: true,
        ),
      ],
      SliderState.transactions: [
        SubMenuItem(
          icon: Icons.account_balance,
          label: 'Header',
          onTap: () => print('header seçildi'),
          isMainTitle: true,
        ),
        SubMenuItem(
          icon: Icons.history,
          label: 'Geçmiş',
          onTap: () => print('Geçmiş seçildi'),
          isDefault: true,
        ),
        SubMenuItem(
          icon: Icons.pending,
          label: 'Bekleyen',
          onTap: () => print('Bekleyen seçildi'),
          isDefault: true,
        ),
      ],
      SliderState.debt: [
        SubMenuItem(
          icon: Icons.account_balance,
          label: 'Header',
          onTap: () => print('header seçildi'),
          isMainTitle: true,
        ),
        SubMenuItem(
          icon: Icons.person,
          label: 'Kişisel',
          onTap: () => print('Kişisel borç'),
          isDefault: true,
        ),
        SubMenuItem(
          icon: Icons.business,
          label: 'Kurumsal',
          onTap: () => print('Kurumsal borç'),
          isDefault: true,
        ),
      ],
    };
  }
}
