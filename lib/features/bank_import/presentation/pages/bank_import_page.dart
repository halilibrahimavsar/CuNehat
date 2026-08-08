import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/shared/widgets/icon_picker.dart';
import 'package:cunehat/core/utils/amount_input_formatter.dart';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/domain/statement_format.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/bank_import/presentation/pages/bank_import_mapping_view.dart';
import 'package:cunehat/features/bank_import/presentation/pages/bank_import_review_view.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

/// Banka ekstresi içe aktarma akışı (Ayarlar → Banka ekstresi içe aktar).
class BankImportPage extends StatefulWidget {
  /// Paylaş menüsünden gelen ekstrenin önbellekteki kopyası (bkz.
  /// `SharedStatementListener`). `null` ise akış dosya seçiciyle başlar —
  /// dosya seçici yolu kaldırılmadı, paylaşım ona ek bir giriş kapısı.
  final String? sharedFilePath;

  const BankImportPage({super.key, this.sharedFilePath});

  @override
  State<BankImportPage> createState() => _BankImportPageState();
}

class _BankImportPageState extends State<BankImportPage> {
  /// İnceleme listesinin tam ekran kipi. Sayfada tutulur çünkü kipin asıl
  /// kazancı AppBar'ın da gizlenmesi: 80+ satırlık bir ekstrede ekrana sığan
  /// satır sayısı asıl darboğaz (bkz. `BankImportReviewView`).
  bool _fullscreen = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<BankImportCubit>();
        final shared = widget.sharedFilePath;
        if (shared != null) cubit.attachSharedFile(shared);
        return cubit;
      },
      child: BlocBuilder<BankImportCubit, BankImportState>(
        builder: (context, state) {
          // Tam ekran YALNIZ inceleme adımında geçerli: diğer adımlarda AppBar
          // tek çıkış yolu, gizlenirse kullanıcı akışta kilitlenir.
          final hideChrome = _fullscreen && state is BankImportReview;
          return Scaffold(
            appBar: hideChrome
                ? null
                : AppBar(
                    title: Text(context.l10n.bankImportTitle),
                    actions: const [_RawTextAction()],
                  ),
            body: switch (state) {
              BankImportInitial() => const _SetupStep(),
              BankImportParsing() =>
                _Busy(label: context.l10n.bankImportParsing),
              BankImportCategorySuggestion() =>
                _CategorySuggestionStep(state: state),
              BankImportMapping() => BankImportMappingView(state: state),
              BankImportReview() => BankImportReviewView(
                  state: state,
                  fullscreen: _fullscreen,
                  onToggleFullscreen: () =>
                      setState(() => _fullscreen = !_fullscreen),
                ),
              BankImportCommitting() => _Committing(state: state),
              BankImportDone() => _Done(state: state),
              BankImportRawText() => _RawTextView(text: state.rawText),
              BankImportScannedPdf() => _BlockedView(
                  icon: Icons.image_not_supported_outlined,
                  title: context.l10n.bankImportScannedPdfTitle,
                  message: context.l10n.bankImportScannedPdfHint,
                ),
              BankImportLegacyExcel() => _BlockedView(
                  icon: Icons.table_chart_outlined,
                  title: context.l10n.bankImportLegacyExcelTitle,
                  message: context.l10n.bankImportLegacyExcelHint(state.reason),
                ),
              BankImportUnsupportedFile() => _BlockedView(
                  icon: Icons.help_outline_rounded,
                  title: context.l10n.bankImportUnsupportedTitle,
                  message: context.l10n.bankImportUnsupportedHint(
                    StatementFormat.supportedExtensions
                        .map((e) => '.$e')
                        .join(', '),
                  ),
                ),
              BankImportError() => _ErrorView(message: state.message),
            },
          );
        },
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

    // Paylaş menüsünden gelindiyse dosya zaten elimizde: kurulum adımı seçici
    // yerine "gelen dosya + hedef cüzdan" onayına dönüşür. Cüzdan seçimi
    // BİLEREK atlanmıyor — hareketlerin hangi deftere yazılacağı kullanıcının
    // kararı.
    final sharedPath = context.read<BankImportCubit>().sharedFilePath;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          sharedPath == null
              ? context.l10n.bankImportSetupHint
              : context.l10n.bankImportSharedSetupHint,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        if (sharedPath != null) ...[
          _SharedFileCard(fileName: _fileNameOf(sharedPath)),
          const SizedBox(height: 16),
        ],
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
        const SizedBox(height: 16),
        // Desteklenen biçimleri açıkça göster: dosya seçici artık her şeyi
        // seçilebilir bıraktığı için (bkz. cubit) kullanıcı neyi indirmesi
        // gerektiğini burada görmeli — özellikle eski `.xls` karışıklığında.
        // Paylaşımla gelindiğinde dosya zaten belli; liste gereksiz gürültü.
        if (sharedPath == null)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final ext in StatementFormat.supportedExtensions)
                Chip(
                  label: Text('.$ext', style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _walletId == null
              ? null
              : () => _start(context, sharedPath: sharedPath),
          icon: Icon(sharedPath == null
              ? Icons.upload_file_rounded
              : Icons.document_scanner_outlined),
          label: Text(sharedPath == null
              ? context.l10n.bankImportPickFile
              : context.l10n.bankImportSharedImport),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        if (sharedPath != null)
          TextButton.icon(
            onPressed: _walletId == null
                ? null
                : () => _start(context, sharedPath: null),
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: Text(context.l10n.bankImportPickAnother),
          ),
      ],
    );
  }

  /// [sharedPath] doluysa paylaşılan dosya ayrıştırılır, boşsa dosya seçici
  /// açılır. İkisi de aynı ayrıştırma yolundan geçer.
  void _start(BuildContext context, {required String? sharedPath}) {
    final userId = _currentUserId(context) ?? 'local_user';
    final cubit = context.read<BankImportCubit>();
    if (sharedPath == null) {
      cubit.pickAndParse(userId: userId, walletId: _walletId!);
    } else {
      cubit.parseFile(
        userId: userId,
        walletId: _walletId!,
        path: sharedPath,
      );
    }
  }

  String? _currentUserId(BuildContext context) {
    final s = context.read<AppAuthBloc>().state;
    if (s is AppAuthenticated) return s.user.uid;
    if (s is AppAuthLocked) return s.user.uid;
    return null;
  }
}

/// Paylaş menüsünden gelen dosyayı gösterir: kullanıcı cüzdanı seçmeden önce
/// "hangi dosyayı aktarıyorum" sorusunun cevabını görmeli — paylaşımı yanlış
/// dosyayla yapmak kolay.
class _SharedFileCard extends StatelessWidget {
  final String fileName;
  const _SharedFileCard({required this.fileName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.attach_file_rounded, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.bankImportSharedFileTitle,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Yol → görünen dosya adı. `path` paketine bağımlılık eklememek için elle
/// (aynı yaklaşım `statement_format.dart` içinde de var).
String _fileNameOf(String path) {
  final slash = path.lastIndexOf(RegExp(r'[/\\]'));
  return slash == -1 ? path : path.substring(slash + 1);
}

// ============================================================ Category suggestion

/// Bilinen ama kullanıcının kategori listesinde karşılığı olmayan gruplar
/// bulunduysa incelemeden önce onay ister. Varsayılan: hepsi işaretli (bir
/// öneriyi reddetmek için kullanıcı işareti kaldırır) — bkz. kullanıcı talebi.
class _CategorySuggestionStep extends StatefulWidget {
  final BankImportCategorySuggestion state;
  const _CategorySuggestionStep({required this.state});

  @override
  State<_CategorySuggestionStep> createState() =>
      _CategorySuggestionStepState();
}

class _CategorySuggestionStepState extends State<_CategorySuggestionStep> {
  late final Set<String> _approved =
      widget.state.suggestions.map((s) => s.name).toSet();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.bankImportCategorySuggestionTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.bankImportCategorySuggestionHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final s in widget.state.suggestions)
                CheckboxListTile(
                  value: _approved.contains(s.name),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _approved.add(s.name);
                    } else {
                      _approved.remove(s.name);
                    }
                  }),
                  secondary: Icon(AppIcons.getIconData(s.iconName)),
                  title: Text(s.name),
                  subtitle: Text(s.isIncome
                      ? context.l10n.detailLabelGelir
                      : context.l10n.detailLabelGider),
                ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context
                  .read<BankImportCubit>()
                  .resolveCategorySuggestions(_approved),
              child: Text(context.l10n.bankImportCategorySuggestionContinue),
            ),
          ),
        ),
      ],
    );
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
            Text(
                '${context.l10n.bankImportCommitting} ${state.done}/${state.total}'),
          ],
        ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  final BankImportDone state;
  const _Done({required this.state});

  WalletEntity? _findWallet(BuildContext context) {
    final walletState = context.watch<WalletBloc>().state;
    if (walletState is! WalletLoadedSt) return null;
    for (final w in walletState.wallets) {
      if (w.id == state.walletId) return w;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _findWallet(context);
    return Center(
      child: SingleChildScrollView(
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
            if (state.hasPastMonthRows) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      context.l10n.bankImportDonePastDatesHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (wallet != null) ...[
              const SizedBox(height: 20),
              _balanceCard(context, wallet),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                _activateTargetWallet(context);
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.bankImportClose),
            ),
            if (state.added > 0) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => _undo(context),
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: Text(context.l10n.bankImportUndo),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Son içe aktarımı geri alır (yalnız az önce eklenen işlemleri siler) ve
  /// başa döner; kullanıcıya kısa bir onay gösterir.
  Future<void> _undo(BuildContext context) async {
    final undoneMsg = context.l10n.bankImportUndoDone;
    await context.read<BankImportCubit>().undoImport();
    AppMessenger.success(undoneMsg);
  }

  /// İçe aktarım sonrası hesaplanan bakiyeyi gösterir + isteğe bağlı olarak
  /// gerçek banka bakiyesine eşitleme diyaloğu sunar (mevcut cüzdan düzenleme
  /// akışındaki `UpdateWalletEvent` bakiye-düzeltme mantığı yeniden kullanılır).
  Widget _balanceCard(BuildContext context, WalletEntity wallet) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            wallet.name,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.bankImportDoneBalanceLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoney(state.balance, currency: wallet.currency),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.bankImportDoneBalanceHint,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showSyncDialog(context, wallet),
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: Text(context.l10n.bankImportSyncButton),
            ),
          ),
        ],
      ),
    );
  }

  /// Hedef cüzdan o an aktif değilse aktif yapar: kullanıcı geri döndüğünde
  /// eklediği hareketleri gördüğü cüzdanda bulur (aksi halde başka cüzdana
  /// bakıp "hiçbir şey olmadı" sanabilir). Zaten aktifse dokunmaz.
  void _activateTargetWallet(BuildContext context) {
    final ws = context.read<WalletBloc>().state;
    if (ws is WalletLoadedSt && ws.activeWallet?.id != state.walletId) {
      context.read<WalletBloc>().add(
            SetActiveWalletEvent(
                userId: state.userId, walletId: state.walletId),
          );
    }
  }

  Future<void> _showSyncDialog(
      BuildContext context, WalletEntity wallet) async {
    final controller =
        TextEditingController(text: formatAmountForInput(state.balance));
    try {
      return await _runSyncDialog(context, wallet, controller);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _runSyncDialog(
    BuildContext context,
    WalletEntity wallet,
    TextEditingController controller,
  ) async {
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.bankImportSyncDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ctx.l10n.bankImportSyncDialogHint,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [AmountInputFormatter(allowNegative: true)],
              decoration: InputDecoration(
                labelText: ctx.l10n.bankImportSyncDialogLabel,
                suffixText: currencySymbol(wallet.currency),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.iptal),
          ),
          FilledButton(
            onPressed: () {
              final val = parseMoneyInput(controller.text);
              if (val != null) Navigator.pop(ctx, val);
            },
            child: Text(ctx.l10n.kaydet),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      // Baseline = diyalog açılırken alana önyüklenen bakiye; kullanıcı onu
      // değiştirdiyse fark opening'e yansır, dokunmadıysa defter olduğu gibi
      // kalır.
      context.read<WalletBloc>().add(
            UpdateWalletEvent(
              wallet.copyWith(balance: result),
              baselineBalance: state.balance,
            ),
          );
      AppMessenger.success(context.l10n.bankImportSyncSuccess);
    }
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
                      AppMessenger.info(context.l10n.bankImportCopied);
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

/// Dosya okunabildi ama içe aktarım BAŞLAYAMADI (taranmış PDF, eski .xls,
/// tanınmayan biçim). Hata değil, açıklanabilir bir engel: nedeni + ne
/// yapılacağı + doğrudan yeni dosya seçme yolu.
class _BlockedView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _BlockedView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.read<BankImportCubit>().reset(),
                icon: const Icon(Icons.upload_file_rounded),
                label: Text(context.l10n.bankImportPickAnother),
              ),
            ),
          ],
        ),
      ),
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
