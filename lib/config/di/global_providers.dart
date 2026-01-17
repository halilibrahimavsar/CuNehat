import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/features/settings/data/repository/settings_repository_impl.dart';
import 'package:cunehat/features/auth_feature/data/datasources/auth_remote_data_source.dart';
import 'package:cunehat/features/auth_feature/data/repository/auth_repository_impl.dart';
import 'package:cunehat/features/auth_feature/data/datasources/biometric_data_source.dart';
import 'package:cunehat/features/auth_feature/data/repository/biometric_repository_impl.dart';
import 'package:cunehat/features/auth_feature/domain/usecases/local_auth_usecases/manage_local_auth_usecase.dart';
import 'package:cunehat/features/auth_feature/domain/usecases/remote_auth_usecases/sign_in_with_google.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/remote_auth/remote_auth_bloc.dart';

import 'package:cunehat/features/main_feature/blocs/amount_visibility_cubit.dart';
import 'package:cunehat/features/settings/presentation/bloc/settings_bloc.dart';

/// Global providers - uygulamanın en üst seviyesindeki temel bağımlılıkları yönetir
/// (Settings, Auth, Biometric, Amount Visibility)
class GlobalProviders extends StatelessWidget {
  final Widget child;

  const GlobalProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => SettingsRepositoryImpl(),
        ),
        RepositoryProvider(
          create: (context) =>
              AuthRepositoryImpl(remoteDataSource: AuthRemoteDataSource()),
        ),
        RepositoryProvider(
          create: (context) => BiometricRepositoryImpl(BiometricDataSource()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AmountVisibilityCubit(),
          ),
          BlocProvider(
            create: (context) => SettingsBloc(
              context.read<SettingsRepositoryImpl>(),
            )..add(const LoadStorageModeEvent()),
          ),
          BlocProvider(
            create: (context) => RemoteAuthBloc(
              authRepository: context.read<AuthRepositoryImpl>(),
              signInWithGoogle: SignInWithGoogle(
                context.read<AuthRepositoryImpl>(),
              ),
              manageLocalAuthUseCase: ManageLocalAuthUseCase(
                context.read<BiometricRepositoryImpl>(),
              ),
            ),
          ),
        ],
        child: child,
      ),
    );
  }
}
