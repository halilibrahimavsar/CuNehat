import 'package:cunehat/pages/expense_pages/expense_page.dart';
import 'package:cunehat/pages/income_pages/income_page.dart';
import 'package:cunehat/shared/animations/cube_animation_view.dart';
import 'package:cunehat/shared/animations/slider_button_view.dart';
import 'package:cunehat/shared/widgets/shared_appbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: SharedAppbar(),
        drawer: Drawer(
          elevation: 1,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Drawer Başlık Bölümü
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const Text(
                  'Menü',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),

              // Ayarlar Sayfasına Navigasyon
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Ayarlar"),
                onTap: () {
                  Navigator.pop(context); // Drawer'ı kapat
                  context.push("/settings"); // Ayarlar sayfasına git
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: CubeAnimationView(
                  controller: _controller,
                  firstView: IncomeView(),
                  secondView: ExpenseView(),
                ),
              ),
            ),
            // SLIDER ALANI
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SliderButtonExpenseIncome(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
