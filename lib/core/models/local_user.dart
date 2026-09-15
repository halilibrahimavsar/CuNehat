import 'package:equatable/equatable.dart';

class LocalUser extends Equatable {
  final String uid;
  final String email;
  final String displayName;

  const LocalUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  /// Hesapsız (yerel) kullanıcı. [email] yalnız alanı dolduran bir yer
  /// tutucudur ve arayüzde GÖSTERİLMEZ: çekmece e-posta olarak yalnız bağlı
  /// Google Drive hesabını, o yoksa "Yerel Mod"u yazar.
  factory LocalUser.guest() {
    return const LocalUser(
      uid: 'local_user',
      email: 'guest@local',
      displayName: 'Misafir Kullanıcı',
    );
  }

  LocalUser copyWith({
    String? uid,
    String? email,
    String? displayName,
  }) {
    return LocalUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName];
}
