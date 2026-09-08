import 'package:cunehat/core/models/local_user.dart';
import 'package:equatable/equatable.dart';

/// App-level auth events for lock/unlock functionality.
abstract class AppAuthEvent extends Equatable {
  const AppAuthEvent();

  @override
  List<Object?> get props => [];
}

class AppAuthUnlockRequested extends AppAuthEvent {
  final LocalUser user;
  const AppAuthUnlockRequested(this.user);

  @override
  List<Object?> get props => [user];
}

class AppAuthAppResumed extends AppAuthEvent {
  /// Uygulamanın arka planda kaldığı süre.
  ///
  /// `null` ise süre kapısı uygulanmaz (olay doğrudan gönderilmiştir); ölçüm
  /// yaşam döngüsü gözlemcisinde yapılır, karar ise burada — süre artık
  /// kullanıcının ayarından okunduğu ve okuma asenkron olduğu için.
  final Duration? pausedDuration;

  const AppAuthAppResumed({this.pausedDuration});

  @override
  List<Object?> get props => [pausedDuration];
}

class AppAuthLockRequested extends AppAuthEvent {
  const AppAuthLockRequested();
}

class AppAuthInitializeRequested extends AppAuthEvent {
  const AppAuthInitializeRequested();
}
