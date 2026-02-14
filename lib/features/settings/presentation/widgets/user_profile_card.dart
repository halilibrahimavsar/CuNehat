import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

/// Displays the current user's information in a card.
class UserProfileCard extends StatelessWidget {
  const UserProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AppAuthBloc, AppAuthState>(
      builder: (context, state) {
        final user = _extractUser(state);
        final email = user?.email ?? 'Kullanıcı';
        final initial = email.isNotEmpty ? email[0].toUpperCase() : 'K';

        return Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias, // Ensure ripple effect breaks at corners
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
               context.push(AppRoutes.profile);
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildAvatar(theme, initial),
                  const SizedBox(width: 16),
                  _buildUserInfo(theme, email),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  dynamic _extractUser(AppAuthState state) {
    if (state is AppAuthenticated) return state.user;
    if (state is AppAuthLocked) return state.user;
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
