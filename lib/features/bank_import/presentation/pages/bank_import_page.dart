import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/features/bank_import/domain/statement_format.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/bank_import/presentation/pages/bank_import_mapping_view.dart';
import 'package:cunehat/features/bank_import/presentation/pages/bank_import_review_view.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';

/// Banka ekstresi içe aktarma akışı (Ayarlar → Banka ekstresi içe aktar).
class BankImportPage extends StatelessWidget {
  const BankImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BankImportCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.bankImportTitle),
          actions: const [_RawTextAction()],
        ),
        body: BlocBuilder<BankImportCubit, BankImportState>(
          builder: (context, state) => switch (state) {
            BankImportInitial() => const _SetupStep(),
            BankImportParsing() => _Busy(label: context.l10n.bankImportParsing),
            BankImportMapping() => BankImportMappingView(state: state),
            BankImportReview() => BankImportReviewView(state: state),
            BankImportCommitting() => _Committing(state: state),
            BankImportDone() => _Done(state: state),
            BankImportRawText() => _RawTextView(text: state.rawText),
            BankImportError() => _ErrorView(message: state.message),
          },
        ),
      ),
    );
  }
}

// ======================================================= Raw text (PDF diag)

/// PDF içe aktarımında çıkarılan ham metni gösteren AppBar eylemi. Tutarlar
/// yanlış çıktığında kullanıcı bunu kopyalayıp paylaşır → ayrıştırıcı düzene
/// göre ayarlanır. Yalnız PDF sonrası (ham metin varken) görünür.
class _RawTextAction extends StatelessWidget {
  const _RawTextAction();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BankImportCubit, BankImportState>(
      builder: (context, _) {
        final raw = context.read<BankImportCubit>().lastPdfRawText;
        if (raw == null || raw.isEmpty) return const SizedBox.shrink();
        return IconButton(
          tooltip: context.l10n.bankImportShowRaw,
          icon: const Icon(Icons.description_outlined),
          onPressed: () => _show(context, raw),
        );
      },
    );
  }

  void _show(BuildContext context, String text) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.bankImportPdfRawTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.bankImportClose),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text(ctx.l10n.bankImportCopy),
          ),
        ],
      ),
    );
  }
}

// ============================================================ Setup step

class _SetupStep extends StatefulWidget {
  const _SetupStep();

  @override
  State<_SetupStep> createState() => _SetupStepState();
}

class _SetupStepState extends State<_SetupStep> {
  StatementFormat _format = StatementFormat.csv;
  String? _walletId;

  @override
  Widget build(BuildContext context) {
    final walletState = context.watch<WalletBloc>().state;
    final wallets =
        walletState is WalletLoadedSt ? walletState.wallets : <WalletEntity>[];
    final active =
        walletState is WalletLoadedSt ? walletState.activeWallet : null;
    _walletId ??= active?.id ?? (wallets.isNotEmpty ? wallets.first.id : null);

    if (wallets.isEmpty) {
      return Center(child: Text(context.l10n.bankImportNoWallet));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(context.l10n.bankImportSetupHint,
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.bankImportFormat,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SegmentedButton<StatementFormat>(
                segments: const [
                  ButtonSegment(value: StatementFormat.csv, label: Text('CSV')),
                  ButtonSegment(
                      value: StatementFormat.excel, label: Text('Excel')),
                  ButtonSegment(value: StatementFormat.pdf, label: Text('PDF')),
                ],
                selected: {_format},
                onSelectionChanged: (s) => setState(() => _format = s.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.bankImportTargetWallet,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              DropdownButton<String>(
                isExpanded: true,
                value: _walletId,
                items: [
                  for (final w in wallets)
                    DropdownMenuItem(value: w.id, child: Text(w.name)),
                ],
                onChanged: (v) => setState(() => _walletId = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _walletId == null ? null : () => _start(context),
          icon: const Icon(Icons.upload_file_rounded),
          label: Text(context.l10n.bankImportPickFile),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  void _start(BuildContext context) {
    final userId = _currentUserId(context) ?? 'local_user';
    context.read<BankImportCubit>().pickAndParse(
          userId: userId,
          walletId: _walletId!,
          format: _format,
        );
  }

  String? _currentUserId(BuildContext context) {
    final s = context.read<AppAuthBloc>().state;
    if (s is AppAuthenticated) return s.user.uid;
    if (s is AppAuthLocked) return s.user.uid;
    return null;
  }
}

// ============================================================ Simple states

class _Busy extends StatelessWidget {
  final String label;
  const _Busy({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label),
        ],
      ),
    );
  }
}

class _Committing extends StatelessWidget {
  final BankImportCommitting state;
  const _Committing({required this.state});

  @override
  Widget build(BuildContext context) {
    final ratio = state.total == 0 ? 0.0 : state.done / state.total;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: ratio),
            const SizedBox(height: 16),
            Text('${context.l10n.bankImportCommitting} ${state.done}/${state.total}'),
          ],
        ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  final BankImportDone state;
  const _Done({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 56),
            const SizedBox(height: 16),
            Text(
              context.l10n.bankImportDoneMsg(state.added, state.skipped),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.bankImportClose),
            ),
          ],
        ),
      ),
    );
  }
}

/// PDF metni çıktı ama satır tanınamadı: ham metni kopyalanabilir göster.
class _RawTextView extends StatelessWidget {
  final String text;
  const _RawTextView({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.bankImportPdfRawTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(context.l10n.bankImportPdfRawHint,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                text.isEmpty ? '(boş)' : text,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.read<BankImportCubit>().reset(),
                  child: Text(context.l10n.bankImportRetry),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(context.l10n.bankImportCopied)));
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(context.l10n.bankImportCopy),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.read<BankImportCubit>().reset(),
              child: Text(context.l10n.bankImportRetry),
            ),
          ],
        ),
      ),
    );
  }
}
