import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/models/local_user.dart';
import 'package:go_router/go_router.dart';

/// Displays the current user's information in a premium, theme-aware card.
class UserProfileCard extends StatelessWidget {
  const UserProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AppAuthBloc, AppAuthState>(
      builder: (context, state) {
        final user = _extractUser(state);
        final name = user?.displayName ?? 'Kullanıcı';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'K';

        return AppCard(
          onTap: () {
            context.push(AppRoutes.profile);
          },
          child: Row(
            children: [
              _buildAvatar(theme, initial),
              const SizedBox(width: 16),
              _buildUserInfo(theme, name),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        );
      },
    );
  }

  LocalUser? _extractUser(AppAuthState state) {
    if (state is AppAuthenticated) return state.user;
    if (state is AppAuthLocked) return state.user;
    return null;
  }

  Widget _buildAvatar(ThemeData theme, String initial) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: theme.primaryColor.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 22,
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
