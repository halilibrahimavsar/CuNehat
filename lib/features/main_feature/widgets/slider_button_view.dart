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
        onStateTap: (state) {},
        miniButtons: _buildMiniButtons(),
        subMenuItems: _buildSubMenuItems(),
      ),
    );
  }

  Map<SliderState, List<MiniButtonData>> _buildMiniButtons() {
    return {
      SliderState.savedMoney: [
        MiniButtonData(
          icon: Icons.add,
          label: 'Ekle',
          color: Colors.green,
          onTap: () {},
        ),
        MiniButtonData(
          icon: Icons.remove,
          label: 'Çıkar',
          color: Colors.red,
          onTap: () {},
        ),
      ],
      SliderState.transactions: [
        MiniButtonData(
          icon: Icons.send,
          label: 'Gönder',
          color: Colors.blue,
          onTap: () {},
        ),
        MiniButtonData(
          icon: Icons.download,
          label: 'Al',
          color: Colors.purple,
          onTap: () {},
        ),
      ],
      SliderState.debt: [
        MiniButtonData(
          icon: Icons.add,
          label: 'Borç Ekle',
          color: Colors.orange,
          onTap: () {},
        ),
      ],
    };
  }

  Map<SliderState, List<SubMenuItem>> _buildSubMenuItems() {
    return {
      SliderState.savedMoney: [
        SubMenuItem(
          icon: Icons.account_balance,
          label: 'Kategoriler',
          onTap: () {},
          isMainTitle: true,
        ),
        SubMenuItem(
          icon: Icons.account_balance,
          label: 'Banka',
          onTap: () {},
        ),
        SubMenuItem(
          icon: Icons.home,
          label: 'Ev',
          onTap: () {},
        ),
      ],
      SliderState.transactions: [
        SubMenuItem(
          icon: Icons.history,
          label: 'İşlemler',
          onTap: () {},
          isMainTitle: true,
        ),
        SubMenuItem(
          icon: Icons.history,
          label: 'Geçmiş',
          onTap: () {},
        ),
        SubMenuItem(
          icon: Icons.pending,
          label: 'Bekleyen',
          onTap: () {},
        ),
      ],
      SliderState.debt: [
        SubMenuItem(
          icon: Icons.account_balance,
          label: 'Borç Türleri',
          onTap: () {},
          isMainTitle: true,
        ),
        SubMenuItem(
          icon: Icons.person,
          label: 'Kişisel',
          onTap: () {},
        ),
        SubMenuItem(
          icon: Icons.business,
          label: 'Kurumsal',
          onTap: () {},
        ),
      ],
    };
  }
}
