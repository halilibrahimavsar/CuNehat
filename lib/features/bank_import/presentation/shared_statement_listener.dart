import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/bank_import/data/shared_statement_channel.dart';

/// Paylaş menüsünden gelen ekstreyi içe aktarma akışına bağlayan app-ömürlü
/// dinleyici.
///
/// **Neden kanaldan olayı beklemek yerine ÇEKİYORUZ:** paylaşım intent'i
/// uygulama kapalıyken de gelebilir ve native taraf onu Dart hazır olmadan
/// önce alır. Native tampon + bizim çekmemiz, "olay geldi ama dinleyen yoktu"
/// yarışını yapısal olarak imkânsız kılar. Aynı yaklaşım bildirim yükünde de
/// kullanılıyor (bkz. `NotificationTapListener`).
///
/// **Kilit kapısı:** PIN/biyometrik açıksa paylaşım kilit açılmadan içe aktarma
/// ekranını AÇAMAZ. Yol, [AppAuthenticated] gelene kadar burada bekletilir.
class SharedStatementListener extends StatefulWidget {
  /// Yönlendirme router örneği üzerinden yapılır: bu widget MaterialApp'in
  /// ÜSTÜNDE durduğundan context'inde Router yok.
  final GoRouter router;
  final SharedStatementChannel channel;
  final Widget child;

  const SharedStatementListener({
    super.key,
    required this.router,
    required this.channel,
    required this.child,
  });

  @override
  State<SharedStatementListener> createState() =>
      _SharedStatementListenerState();
}

class _SharedStatementListenerState extends State<SharedStatementListener>
    with WidgetsBindingObserver {
  /// Alınmış ama henüz içe aktarma ekranına teslim edilememiş paylaşım
  /// (uygulama kilitli). Kilit açılınca salınır.
  String? _pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Soğuk açılış: uygulama kapalıyken paylaşılan dosya native tarafta
    // bekliyor olabilir.
    _drain();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plandayken paylaşım geldi → onNewIntent tamponladı →
    // sistem bizi öne aldı. Asıl yol bu.
    if (state == AppLifecycleState.resumed) _drain();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _drain() async {
    final path = await widget.channel.consume();
    if (path == null || !mounted) return;
    _pending = path;
    _release();
  }

  /// Kilit açıksa bekleyen paylaşımı içe aktarma ekranına götürür.
  ///
  /// Yol, ancak GERÇEKTEN o sayfaya indiğimizi gördükten sonra bırakılır.
  /// Sebep bir yarış: uygulama öne gelirken [AppAuthBloc] de kilit kararını
  /// veriyor; push'u kilit kararından önce yaparsak router'ın kilit
  /// yönlendirmesi (bkz. `createAppRouter`) sayfayı yığından siler ve paylaşım
  /// sessizce kaybolurdu. Yolu tutmaya devam edersek kilit açıldığında
  /// [AppAuthenticated] geçişi bizi tekrar buraya getirir.
  void _release() {
    final path = _pending;
    if (path == null) return;
    if (context.read<AppAuthBloc>().state is! AppAuthenticated) return;

    widget.router.push(AppRoutes.bankStatementImport, extra: path);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final location =
          widget.router.routerDelegate.currentConfiguration.uri.path;
      if (location == AppRoutes.bankStatementImport) _pending = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppAuthBloc, AppAuthState>(
      listenWhen: (_, state) => state is AppAuthenticated,
      listener: (_, __) => _release(),
      child: widget.child,
    );
  }
}
