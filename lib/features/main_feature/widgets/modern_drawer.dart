import 'dart:ui';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/models/local_user.dart';
import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart'
    as constants;
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_state.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// A premium animated drawer featuring user profile, active wallet metrics,
/// and navigation links to settings, profile, and sign-out actions.
class ModernDrawer extends StatefulWidget {
  const ModernDrawer({super.key});

  @override
  State<ModernDrawer> createState() => _ModernDrawerState();
}

class _ModernDrawerState extends State<ModernDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _controller.forward();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: constants.AppDurations.medium,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AppAuthBloc>().state;
    final localUser = authState is AppAuthenticated
        ? authState.user
        : (authState is AppAuthLocked ? authState.user : null);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final surface = theme.colorScheme.surface;

    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.85,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.4) : null,
              gradient: isDark
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                            primary.withValues(alpha: 0.18), surface),
                        Color.alphaBlend(
                            secondary.withValues(alpha: 0.12), surface),
                        surface,
                      ],
                    ),
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : primary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildAnimatedHeader(localUser, isDark, theme),
                      const SizedBox(height: 12),

                      // Active Wallet Metrics Section
                      _buildWalletMetricsSection(theme),
                      const SizedBox(height: 16),

                      _buildAnimatedMenuItem(
                        index: 0,
                        icon: Icons.account_balance_wallet_outlined,
                        title: context.l10n.budgetPlanning,
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.budgets);
                        },
                        delay: 50,
                        isDark: isDark,
                        theme: theme,
                      ),
                      _buildAnimatedMenuItem(
                        index: 1,
                        icon: Icons.event_repeat_rounded,
                        title: context.l10n.recurringTransactions,
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.recurringTemplates);
                        },
                        delay: 100,
                        isDark: isDark,
                        theme: theme,
                        // Onay bekleyen kalem = deftere işlenmemiş gerçek
                        // gelir/gider. Açılış hatırlatması "Sonra" ile
                        // susturulabildiğinden kalıcı görünürlük burada.
                        badgeCount: _pendingCount(context),
                      ),
                      _buildAnimatedMenuItem(
                        index: 2,
                        icon: Icons.settings_rounded,
                        title: context.l10n.settings,
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.settings);
                        },
                        delay: 150,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(LocalUser? user, bool isDark, ThemeData theme) {
    // Kimlik bloğu (avatar + ad + e-posta) yalnızca gerçek bir Google (Drive)
    // hesabı bağlıyken anlamlı; yerel modda sadece placeholder olur. Yerel
    // modda placeholder yerine, durum çubuğu boşluğunu koruyan ince bir spacer
    // göster ki cüzdan metrikleri üste yapışmasın.
    final driveUser = getIt<GoogleDriveBackupService>().currentUser;
    if (driveUser == null) {
      return const SizedBox(height: 50);
    }
    final primary = theme.colorScheme.primary;
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: constants.AppSizes.headerHeight,
          padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : primary.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft:
                  Radius.circular(constants.AppBorderRadius.drawerBottom),
              bottomRight:
                  Radius.circular(constants.AppBorderRadius.drawerBottom),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(user, isDark, primary),
              const SizedBox(height: 15),
              _buildUserInfo(context, user, isDark, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(LocalUser? user, bool isDark, Color primary) {
    final driveUser = getIt<GoogleDriveBackupService>().currentUser;
    final photoUrl = driveUser?.photoUrl;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: constants.AppDurations.long,
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: constants.AppSizes.avatarRadius,
              backgroundColor: Colors.white,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, size: 28, color: Colors.blueGrey)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo(
    BuildContext context,
    LocalUser? user,
    bool isDark,
    ThemeData theme,
  ) {
    final driveUser = getIt<GoogleDriveBackupService>().currentUser;
    final displayName =
        driveUser?.displayName ?? user?.displayName ?? context.l10n.defaultUser;
    final email = driveUser?.email ?? user?.email ?? context.l10n.yerelMod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            displayName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 3),
        FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            email,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.75)
                  : theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWalletMetricsSection(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        if (state is! WalletLoadedSt || state.activeWallet == null) {
          return const SizedBox.shrink();
        }

        final wallet = state.activeWallet!;
        final walletColor = WalletColors.hexToColor(wallet.colorHex);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: walletColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        AppIcons.getIconData(wallet.iconName),
                        color: walletColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        wallet.name,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                    color: isDark ? Colors.white12 : theme.dividerColor,
                    height: 1),
                const SizedBox(height: 12),
                _buildDrawerMetricRow(context.l10n.drawerBalance,
                    wallet.balance, Colors.white, theme, wallet.currency),
                const SizedBox(height: 8),
                _buildDrawerMetricRow(
                    context.l10n.drawerInvestment,
                    wallet.investment,
                    Colors.greenAccent,
                    theme,
                    wallet.currency),
                const SizedBox(height: 8),
                _buildDrawerMetricRow(context.l10n.drawerDebt, wallet.debt,
                    Colors.redAccent, theme, wallet.currency),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerMetricRow(String label, double amount, Color amountColor,
      ThemeData theme, String currencyCode) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          AppFormatters.currencyFor(currencyCode).format(amount),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark
                ? amountColor
                : (amountColor == Colors.white
                    ? theme.colorScheme.onSurface
                    : (amountColor == Colors.greenAccent
                        ? Colors.green.shade700
                        : (amountColor == Colors.redAccent
                            ? Colors.red.shade700
                            : amountColor))),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedMenuItem({
    required int index,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required int delay,
    required bool isDark,
    required ThemeData theme,
    int badgeCount = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-40 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _selectedIndex = index);
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: constants.AppDurations.short,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _selectedIndex == index
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : theme.colorScheme.primary.withValues(alpha: 0.12))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedIndex == index
                      ? (isDark
                          ? Colors.white.withValues(alpha: 0.25)
                          : theme.colorScheme.primary.withValues(alpha: 0.25))
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  _buildMenuIcon(icon, isDark, theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : theme.colorScheme.onSurface,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (badgeCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onError,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Onay bekleyen düzenli işlem sayısı. Bloc app-kapsamlı olduğundan drawer
  /// her açıldığında güncel değeri okur.
  int _pendingCount(BuildContext context) {
    final state = context.watch<PendingRecurringBloc>().state;
    return state is PendingRecurringLoaded
        ? state.pendingTransactions.length
        : 0;
  }

  Widget _buildMenuIcon(IconData icon, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.05),
                ]
              : [
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.colorScheme.primary.withValues(alpha: 0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.3)
              : theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: isDark ? Colors.white : theme.colorScheme.primary,
        size: 20,
      ),
    );
  }
}
