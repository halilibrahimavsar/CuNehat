import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/core/shared/widgets/pressable_scale.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

/// A premium, theme-aware empty state view when no wallet is selected or created.
class NoWalletView extends StatelessWidget {
  const NoWalletView({
    super.key,
    required this.infoText,
    this.showButton = true,
  });

  final String infoText;
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface.withValues(alpha: 0.8),
            scheme.surface,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Massive glowing icon container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 56,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.l10n.finansalNyolculugunuzBasliyor,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                infoText,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showButton) ...[
                const SizedBox(height: 48),
                PressableScale(
                  onTap: () {
                    final scaffoldState = context.findAncestorStateOfType<
                        AnimatedScaffoldWrapperState>();
                    final authState = context.read<AppAuthBloc>().state;
                    final userId = authState is AppAuthenticated
                        ? authState.user.uid
                        : (authState is AppAuthLocked
                            ? authState.user.uid
                            : 'local_user');

                    scaffoldState?.openWalletDialog(
                      WalletSheetContent(
                        scrollController: ScrollController(),
                        userId: userId,
                      ),
                    );
                  },
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary,
                          scheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            context.l10n.ilkCuzdaniOlustur,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
