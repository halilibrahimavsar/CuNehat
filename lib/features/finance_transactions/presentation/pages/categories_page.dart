import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/category_manager/category_manager_view.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Yan menüden açılan kategori yönetimi.
///
/// **Neden ayrı bir sayfa:** kategori yöneticisine tek giriş işlem formundaki
/// "Yönet" düğmesiydi — düzenlemek için önce işlem eklemeye başlamak
/// gerekiyordu. Üstelik o alt sayfa formun türüne kilitli açıldığından, gider
/// formundayken gelir kategorilerine hiç ulaşılamıyordu. Buradaki iki sekme o
/// kilidi kaldırıyor.
///
/// Kapsam AKTİF CÜZDANDIR: satırlardaki anahtarlar "bu kategori bu cüzdanda
/// görünsün mü" sorusunu yanıtlar. Kategorinin kendisi küreseldir; silmek her
/// cüzdandan siler, anahtarı kapatmak yalnız buradan gizler.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  final GlobalKey<CategoryManagerViewState> _expenseKey = GlobalKey();
  final GlobalKey<CategoryManagerViewState> _incomeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Sekme değişince alt köşedeki düğmenin rengi/hedefi de değişir.
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _isExpenseTab => _tabs.index == 0;

  GlobalKey<CategoryManagerViewState> get _activeKey =>
      _isExpenseTab ? _expenseKey : _incomeKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final walletState = context.watch<WalletBloc>().state;
    // `WalletLoadedSt.activeWallet` NULLABLE. Bugünkü `WalletBloc` cüzdan
    // varken null yaymıyor (aktif bulunamazsa ilkini kendi koyuyor), yani bu
    // geri düşüş savunma amaçlı — ama tip izin verdiği sürece "cüzdan var,
    // aktif yok" durumunda "Cüzdan oluşturunuz" demek olgusal olarak yanlış
    // olurdu. Bütçe sayfası da aynı geri düşüşü kullanıyor.
    final wallet =
        walletState is WalletLoadedSt && walletState.wallets.isNotEmpty
            ? (walletState.activeWallet ?? walletState.wallets.first)
            : null;
    final walletId = wallet?.id;

    final color = _isExpenseTab ? Colors.red : Colors.green;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.kategorilerBaslik),
            if (wallet != null)
              Text(
                wallet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: context.l10n.giderKategorileri),
            Tab(text: context.l10n.gelirKategorileri),
          ],
        ),
      ),
      // Cüzdan yoksa yönetilecek kapsam da yok: kategori görünürlüğü cüzdana
      // yazılıyor, cüzdansız açılan sayfa hiçbir anahtarı kaydedemezdi.
      body: walletId == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.l10n.cuzdanOlusturunuz,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : TabBarView(
              controller: _tabs,
              children: [
                CategoryManagerView(
                  key: _expenseKey,
                  walletId: walletId,
                  isExpense: true,
                ),
                CategoryManagerView(
                  key: _incomeKey,
                  walletId: walletId,
                  isExpense: false,
                ),
              ],
            ),
      floatingActionButton: walletId == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: color,
              foregroundColor: Colors.white,
              onPressed: () => _activeKey.currentState?.addCategory(),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.yeniKategoriEkle),
            ),
    );
  }
}
