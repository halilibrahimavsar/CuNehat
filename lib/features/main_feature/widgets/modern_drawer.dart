import 'dart:ui';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/models/local_user.dart';
import 'package:cunehat/core/services/google_drive_backup_service.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart'
    as constants;
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_state.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// A premium animated drawer featuring user profile, active wallet summary card,
/// categorized navigation menu with sub-titles, and system quick links.
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
                          primary.withValues(alpha: 0.18),
                          surface,
                        ),
                        Color.alphaBlend(
                          secondary.withValues(alpha: 0.12),
                          surface,
                        ),
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

                      // Active Wallet Summary Card (Hesap - Borç - Birikim)
                      _buildWalletMetricsSection(theme),
                      const SizedBox(height: 20),

                      // Section 1: Finansal Yönetim
                      _buildSectionHeader(
                        context.l10n.drawerSectionFinancial,
                        isDark,
                        theme,
                      ),
                      const SizedBox(height: 6),
                      _buildAnimatedMenuItem(
                        index: 0,
                        icon: Icons.pie_chart_outline_rounded,
                        title: context.l10n.budgetPlanning,
                        subtitle: context.l10n.drawerBudgetSubtitle,
                        gradientColors: const [
                          Color(0xFF8E2DE2),
                          Color(0xFF4A00E0),
                        ],
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
                        icon: Icons.sync_alt_rounded,
                        title: context.l10n.recurringTransactions,
                        subtitle: context.l10n.drawerRecurringSubtitle,
                        gradientColors: const [
                          Color(0xFFF2994A),
                          Color(0xFFF2C94C),
                        ],
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
                        icon: Icons.document_scanner_rounded,
                        // `bankStatementSectionHeader` DEĞİL: o metin ayarlar
                        // sayfasındaki bölüm başlığı için yazıldı ve büyük
                        // harf ("BANKA EKSTRESİ"). Menüde komşuları başlık
                        // düzeninde olduğu için tek başına bağırıyordu.
                        title: context.l10n.drawerBankImportTitle,
                        subtitle: context.l10n.drawerBankImportSubtitle,
                        gradientColors: const [
                          Color(0xFF11998E),
                          Color(0xFF38EF7D),
                        ],
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.bankStatementImport);
                        },
                        delay: 150,
                        isDark: isDark,
                        theme: theme,
                      ),

                      const SizedBox(height: 16),

                      // Section 2: Sistem & Ayarlar
                      _buildSectionHeader(
                        context.l10n.drawerSectionSystem,
                        isDark,
                        theme,
                      ),
                      const SizedBox(height: 6),
                      _buildAnimatedMenuItem(
                        index: 3,
                        icon: Icons.tune_rounded,
                        title: context.l10n.settings,
                        subtitle: context.l10n.drawerSettingsSubtitle,
                        gradientColors: const [
                          Color(0xFF2F80ED),
                          Color(0xFF56CCF2),
                        ],
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.settings);
                        },
                        delay: 200,
                        isDark: isDark,
                        theme: theme,
                      ),
                      _buildAnimatedMenuItem(
                        index: 4,
                        icon: Icons.shield_outlined,
                        title: context.l10n.drawerSecurityTitle,
                        subtitle: context.l10n.drawerSecuritySubtitle,
                        gradientColors: const [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2),
                        ],
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.localAuthSettings);
                        },
                        delay: 250,
                        isDark: isDark,
                        theme: theme,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                _buildDrawerFooter(isDark, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark
              ? Colors.white.withValues(alpha: 0.45)
              : theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// Kimlik bloğu (avatar + ad + e-posta) yalnızca gerçek bir Google (Drive)
  /// hesabı bağlıyken anlamlı; yerel modda sadece placeholder olur. Yerel
  /// modda placeholder yerine, durum çubuğu boşluğunu koruyan ince bir spacer
  /// göster ki cüzdan metrikleri üste yapışmasın.
  Widget _buildAnimatedHeader(LocalUser? user, bool isDark, ThemeData theme) {
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.10),
                        Colors.white.withValues(alpha: 0.04),
                      ]
                    : [
                        walletColor.withValues(alpha: 0.08),
                        theme.colorScheme.surface,
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : walletColor.withValues(alpha: 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: walletColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aktif cüzdan başlık şeridi
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: walletColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        AppIcons.getIconData(wallet.iconName),
                        color: walletColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.name,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.drawerActiveWalletLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.white54
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: walletColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: walletColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        wallet.currency.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : walletColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Ana nakit bakiye gösterimi
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 18,
                        color:
                            isDark ? Colors.white70 : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.drawerBalance,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white70
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatMoney(wallet.balance, currency: wallet.currency),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Sub Metrics Chips (Yatırım & Borç)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricChip(
                        label: context.l10n.drawerInvestment,
                        amount: wallet.investment,
                        currencyCode: wallet.currency,
                        icon: Icons.trending_up_rounded,
                        accentColor: const Color(0xFF2EC4B6),
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricChip(
                        label: context.l10n.drawerDebt,
                        amount: wallet.debt,
                        currencyCode: wallet.currency,
                        icon: Icons.credit_card_off_rounded,
                        accentColor: const Color(0xFFE63946),
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricChip({
    required String label,
    required double amount,
    required String currencyCode,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: 0.12)
            : accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white70
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(amount, currency: currencyCode),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? accentColor
                    : (accentColor == const Color(0xFF2EC4B6)
                        ? Colors.teal.shade800
                        : Colors.red.shade800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedMenuItem({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
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
          offset: Offset(-30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  _buildGradientIcon(icon, gradientColors, isDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white54
                                : theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (badgeCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
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
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? Colors.white38
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _pendingCount(BuildContext context) {
    final state = context.watch<PendingRecurringBloc>().state;
    return state is PendingRecurringLoaded
        ? state.pendingTransactions.length
        : 0;
  }

  Widget _buildGradientIcon(
    IconData icon,
    List<Color> colors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildDrawerFooter(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : theme.dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ÇuNehat v1.0.0',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? Colors.white38
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
