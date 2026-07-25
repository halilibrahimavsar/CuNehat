import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/notifications/notification_constants.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';

/// Bildirim dokunuşlarını ve uygulamaya dönüşleri bekleyen-işlem yüklemesine
/// bağlayan app-ömürlü dinleyici.
///
/// Neden sayfa değil app seviyesi: bekleyenler daha önce yalnızca
/// `HomePage.initState` içinde yükleniyordu. Bildirime dokunmak uygulamayı
/// arka plandan öne alırken HomePage yeniden mount OLMADIĞI için diyalog
/// açılmıyordu; yalnızca uygulama tamamen kapalıyken (ya da PIN kilidi
/// HomePage'i yeniden kurduğunda) çalışıyordu — "bazen açılıyor"un kaynağı
/// buydu.
class NotificationTapListener extends StatefulWidget {
  final Widget child;

  const NotificationTapListener({super.key, required this.child});

  @override
  State<NotificationTapListener> createState() =>
      _NotificationTapListenerState();
}

class _NotificationTapListenerState extends State<NotificationTapListener>
    with WidgetsBindingObserver {
  /// Arka planda bundan kısa kalındığında yeniden yükleme yapılmaz: hızlı
  /// uygulama geçişlerinde diyaloğun sürekli önümüze çıkmasını engeller.
  static const Duration _resumeReloadThreshold = Duration(minutes: 1);

  StreamSubscription<String>? _subscription;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Soğuk açılışta dokunulan bildirimin yükü servis tarafında tamponlanır
    // ve bu abonelikle birlikte teslim edilir.
    _subscription = getIt<NotificationService>()
        .onNotificationTap
        .listen(_onNotificationTap);
  }

  void _onNotificationTap(String payload) {
    if (!mounted) return;
    if (payload != NotificationPayloads.pendingRecurring) return;
    context
        .read<PendingRecurringBloc>()
        .add(const LoadPendingTransactionsEvent(forceShow: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt == null) return;
    if (DateTime.now().difference(pausedAt) < _resumeReloadThreshold) return;
    if (!mounted) return;

    context
        .read<PendingRecurringBloc>()
        .add(const LoadPendingTransactionsEvent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
