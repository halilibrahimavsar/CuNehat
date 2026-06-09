/// Local Authentication Feature - Comprehensive security and authentication system.
///
/// This feature provides:
/// - Biometric authentication (fingerprint, face ID)
/// - PIN-based authentication with progressive lockout
/// - Privacy guard for background content protection
/// - Background lock with configurable timeouts
/// - Security settings management
///
/// Quick Start:
/// ```dart
/// // Wrap your app with security layer
/// LocalAuthSecurityLayer(
///   repository: context.read<LocalAuthRepository>(),
///   child: YourApp(),
/// )
///
/// // Use authentication bloc
/// BlocProvider(
///   create: (context) => LocalAuthLoginBloc(
///     repository: context.read<LocalAuthRepository>(),
///   ),
///   child: AuthPage(),
/// )
/// ```

library;

// Data layer - Repository and implementations
export 'data/local_auth_repository.dart';
export 'data/local_auth_migration.dart';
export 'data/secure_local_auth_repository.dart';

// Presentation layer - All UI components and BLoCs
export 'presentation/local_auth.dart';
