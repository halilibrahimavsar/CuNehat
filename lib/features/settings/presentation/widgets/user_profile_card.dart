import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/features/auth_feature/presentation/bloc/remote_auth/remote_auth_bloc.dart';

/// Displays the current user's information in a card.
class UserProfileCard extends StatelessWidget {
  const UserProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<RemoteAuthBloc, AuthState>(
      builder: (context, state) {
        final user = _extractUser(state);
        final email = user?.email ?? 'Kullanıcı';
        final initial = email.isNotEmpty ? email[0].toUpperCase() : 'K';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildAvatar(theme, initial),
                const SizedBox(width: 16),
                _buildUserInfo(theme, email),
              ],
            ),
          ),
        );
      },
    );
  }

  dynamic _extractUser(AuthState state) {
    if (state is Authenticated) return state.user;
    if (state is AuthLocked) return state.user;
    return null;
  }

  Widget _buildAvatar(ThemeData theme, String initial) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildUserInfo(ThemeData theme, String email) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoşgeldiniz',
            style: theme.textTheme.bodySmall,
          ),
          Text(
            email,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
