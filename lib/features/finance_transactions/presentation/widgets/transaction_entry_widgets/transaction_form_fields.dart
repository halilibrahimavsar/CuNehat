import 'package:cunehat/core/shared/widgets/field_hint.dart';
import 'package:flutter/material.dart';
import 'package:cunehat/core/shared/motion/app_haptics.dart';
import 'package:cunehat/features/finance_transactions/presentation/utils/fresh_entry_marker.dart';
import 'package:cunehat/features/main_feature/utils/section_records.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/config/theme/app_gradients.dart';
import 'package:cunehat/config/theme/app_surface_theme.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/credit_card/presentation/payment_method_selector.dart';
import 'package:cunehat/features/finance_transactions/domain/installments.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_form_controller.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_amount_hero.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_category_picker.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_when_row.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_receipt_row.dart';
import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';

/// Defterde bu kadar kayıt olunca formda "Kaydet ve yeni" de sunulur.
const int kSaveAndNewAfterRecords = 5;

/// Gelir/gider ekleme & düzenleme için sıfırdan tasarlanmış modern sayfa.
///
/// Odak: en üstte büyük tutar girişi, altında sade alanlar. Performans için
/// her parça kendi [ValueNotifier]'ını dinler — tutar yazarken kategori
/// ızgarası yeniden çizilmez.
class TransactionFormSheet extends StatefulWidget {
  final bool isExpense;
  final String walletId;
  final String userId;
  final TransactionEntity? initialTransaction;

  /// "Yeniden ekle": bu işlemin başlığı, tutarı ve kategorisiyle YENİ kayıt
  /// başlatır (tarih bugün). Düzenleme değildir; [initialTransaction] ile
  /// birlikte verilmez.
  final TransactionEntity? prefill;

  /// Yeni kayıt bu GÜNE açılır (defterde gün başlığındaki "+"); saat
  /// şimdiki saattir. Düzenlemede yok sayılır. "Kaydet ve yeni" tarihi
  /// korur — aynı güne art arda kayıt girilebilir.
  final DateTime? initialDate;
  final void Function(
      TransactionEntity transaction, RecurringFrequency? frequency) onSave;

  /// "Kaydet ve yeni": kayıt yazılır, sayfa AÇIK kalır ve form bir sonraki
  /// kayda hazırlanır. Taksitli alışverişte [rows] bölünmüş satırlardır,
  /// aksi halde tek elemanlıdır. Verilmezse düğme gösterilmez.
  final void Function(
          List<TransactionEntity> rows, RecurringFrequency? frequency)?
      onSaveAndNew;

  /// Taksitli alışveriş kaydedilince (kart cüzdanı, taksit > 1) bölünmüş
  /// satırlarla çağrılır; verilmezse taksit seçici gösterilmez.
  final void Function(List<TransactionEntity> installments)? onSaveInstallments;
  final VoidCallback onCancel;

  const TransactionFormSheet({
    super.key,
    required this.isExpense,
    required this.walletId,
    required this.userId,
    this.initialTransaction,
    this.prefill,
    this.initialDate,
    required this.onSave,
    this.onSaveAndNew,
    this.onSaveInstallments,
    required this.onCancel,
  });

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  late final TransactionFormController _c;
  final FocusNode _amountFocus = FocusNode();
  final ScrollController _scroll = ScrollController();
  Animation<double>? _routeAnimation;

  bool get _isEdit => widget.initialTransaction != null;
  bool get _isExpense => _c.isExpense.value;
  Color get _accent => _isExpense ? AppGradients.debt : AppGradients.savings;

  @override
  void initState() {
    super.initState();
    _c = TransactionFormController(
      isExpense: widget.isExpense,
      walletId: widget.walletId,
      userId: widget.userId,
    );
    if (_isEdit) {
      _c.initialize(widget.initialTransaction!);
    } else if (widget.prefill case final source?) {
      _c.prefill(source);
    }
    if (!_isEdit) {
      if (widget.initialDate case final day?) _c.startOn(day);
    }
    _c.targetWalletId.addListener(_onTargetChanged);

    // Açılış animasyonu bitince işle: ne kategori yüklemesi ne de klavye
    // sheet yukarı kayarken devreye girsin (çakışma = takılma).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final anim = ModalRoute.of(context)?.animation;
      if (anim == null || anim.isCompleted) {
        _onEntranceDone();
      } else {
        _routeAnimation = anim..addStatusListener(_onAnimStatus);
      }
    });
  }

  /// Hedef karttan hesaba dönünce seçili taksit gizli kalıp kayda sızmasın.
  void _onTargetChanged() {
    if (!_offersInstallments(context, _c.targetWalletId.value)) {
      _c.installments.value = 1;
    }
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _onEntranceDone();
  }

  void _onEntranceDone() {
    _routeAnimation?.removeStatusListener(_onAnimStatus);
    _routeAnimation = null;
    if (!mounted) return;
    _c.loadCategories();
    // Yeni kayıtta odak hep tutara gider. Eskiden form İLK açılışta üç
    // adımlı bir tanıtım oynatıyor ve o yüzden klavyeyi açmıyordu: yeni
    // kullanıcı tutarı yazmadan önce üç baloncuğu kapatmak zorundaydı.
    if (!_isEdit) _amountFocus.requestFocus();
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onAnimStatus);
    _c.targetWalletId.removeListener(_onTargetChanged);
    _amountFocus.dispose();
    _scroll.dispose();
    _c.dispose();
    super.dispose();
  }

  /// "Kaydet ve yeni" kullandıkça gelir: ilk kayıtlarda formun dibinde TEK
  /// düğme durur. Art arda kayıt girmek bir alışkanlık işidir; uygulamayı
  /// yeni açan kişi için ikinci düğme "hangisine basacağım?" sorusudur.
  ///
  /// Sayfa açılırken bir kez okunur (form açıkken düğme belirmez/kaybolmaz).
  /// Sayaç yoksa (test kabuğu) düğme gösterilir.
  late final bool _saveAndNewEarned = !getIt.isRegistered<SectionRecords>() ||
      getIt<SectionRecords>().transactionCount >= kSaveAndNewAfterRecords;

  /// [keepOpen]: "Kaydet ve yeni" — kayıt yazılır, sayfa kapanmaz.
  Future<void> _submit({bool keepOpen = false}) async {
    final err =
        _c.validate(categoryRequiredMessage: context.l10n.kategoriSecmeUyarisi);
    if (err != null) {
      _c.error.value = err;
      return;
    }
    _amountFocus.unfocus();
    _c.error.value = null;
    _c.submitting.value = true;

    // Fiş görselini yalnız KAYIT anında diske yaz (iptalde orphan kalmasın).
    // Eski dosyanın temizliği (değiştirme/kaldırma) repository katmanında,
    // eski ve yeni receiptFileName karşılaştırılarak yapılır.
    var receiptFileName = _c.receiptFileName.value;
    final picked = _c.pickedReceipt.value;
    if (picked != null) {
      try {
        receiptFileName =
            await getIt<ReceiptStorageService>().persist(picked.path);
      } catch (e) {
        debugPrint('Fiş kaydedilemedi: $e'); // Görselsiz de olsa işlemi kaydet.
        receiptFileName = _c.receiptFileName.value;
      }
    }
    if (!mounted) return;

    final when = _c.dateTime.value;
    // Başlık boşsa kategori ADINA düşer — kimlik UUID olduğundan
    // `categoryId`'yi basmak ekrana anlamsız bir dizgi yazardı.
    final title = _c.titleController.text.trim().isEmpty
        ? (_c.categories.value
                .where((c) => c.id == _c.categoryId.value)
                .firstOrNull
                ?.name ??
            context.l10n.islem)
        : _c.titleController.text.trim();
    final type =
        _isExpense ? TransactionTypeModel.expense : TransactionTypeModel.income;
    // Düzenlemede formda OLMAYAN alanlar (bankanın numarası vb.) özgün
    // kayıttan taşınır; sıfırdan kurmak onları sessizce siliyordu.
    final transaction = _isEdit
        ? widget.initialTransaction!.edited(
            title: title,
            tag: _c.categoryId.value!,
            amount: _c.parsedAmount!,
            date: when,
            type: type,
            receiptFileName: receiptFileName,
            // Düzenlemede cüzdan değişmiş olabilir (bkz. [_moveOptions]).
            walletId: _c.targetWalletId.value,
          )
        : TransactionEntity(
            id: null,
            userId: widget.userId,
            walletId: _c.targetWalletId.value,
            title: title,
            tag: _c.categoryId.value!,
            amount: _c.parsedAmount!,
            date: when,
            type: type,
            receiptFileName: receiptFileName,
            // Tekrar tespiti bununla "elle girildi"yi KESİN bilir; eskiden
            // başlığın yazımından tahmin ediyordu ("MIGROS" ekstreden
            // sanılıyordu).
            origin: TransactionOrigin.manual,
          );
    final installments = _c.installments.value;
    final onInstallments = widget.onSaveInstallments;
    final rows = !_isEdit && installments > 1 && onInstallments != null
        ? splitIntoInstallments(transaction, installments)
        : null;

    // Kayıt anı. Doğrulama geçti, kayıt yazılacak: parmak bunu hisseder,
    // yeni satır da listeye yumuşakça girer (bkz. `FreshEntrance`). İkisi de
    // kaydı BEKLETMEZ.
    AppHaptics.confirm();
    if (!_isEdit) FreshEntryMarker.instance.mark(rows ?? [transaction]);

    final onSaveAndNew = widget.onSaveAndNew;
    if (keepOpen && onSaveAndNew != null) {
      // Taksitli alışveriş tekrarlayan işlem olamaz.
      onSaveAndNew(
        rows ?? [transaction],
        rows == null ? _c.recurringFrequency.value : null,
      );
      _c.resetForNext(
        savedSummary: context.l10n.kaydedildiOzet(
          title,
          formatMoney(
            transaction.amount,
            currency: context.walletById(transaction.walletId)?.currency ??
                context.activeWalletCurrency,
          ),
        ),
      );
      if (_scroll.hasClients) _scroll.jumpTo(0);
      _amountFocus.requestFocus();
      return;
    }

    if (rows != null) {
      onInstallments!(rows);
      return;
    }
    widget.onSave(transaction, _c.recurringFrequency.value);
  }

  /// Taksit seçici yalnız YENİ gider + hedef kredi kartı + bayrak açıkken.
  bool _offersInstallments(BuildContext context, String targetId) =>
      FeatureFlags.creditCards &&
      !_isEdit &&
      _isExpense &&
      widget.onSaveInstallments != null &&
      (context.walletById(targetId)?.isCreditCard ?? false);

  /// "Ödeme yöntemi" seçeneklerinin ailesi: formun açıldığı cüzdanın sahibi
  /// + ona bağlı kartlar, AYNI birimde olanlar (tutar tek birimde yazılır).
  /// Yalnız YENİ giderde ve bayrak açıkken; tek seçenek kalırsa boş.
  List<WalletEntity> _paymentOptions(BuildContext context) {
    if (!FeatureFlags.creditCards || _isEdit || !_isExpense) {
      return const [];
    }
    final all = context.allWallets;
    final start = all.where((w) => w.id == widget.walletId).firstOrNull;
    if (start == null) return const [];
    final owner = accountOf(start, all);
    final family = [
      owner,
      ...cardsOf(owner.id, all),
    ].where((w) => w.currency == start.currency).toList();
    return family.length > 1 ? family : const [];
  }

  /// DÜZENLEMEDE kaydın taşınabileceği cüzdanlar: aynı birimdekiler (tutar
  /// çevrilmez, birim değişirse anlamı değişirdi), aile sırasında. Gelir
  /// yalnız hesaplara taşınır — kart cüzdanına gelir yazmak kart ödemesi
  /// demektir, o ayrı bir akış. Taşınamayan kayıtta ya da tek seçenekte boş.
  ///
  /// Eskiden yanlış cüzdana girilen kayıt taşınamıyordu: silinip doğru
  /// cüzdanda baştan giriliyordu.
  List<WalletEntity> _moveOptions(BuildContext context) {
    final t = widget.initialTransaction;
    if (t == null || !t.canMoveWallet) return const [];
    final all = context.allWallets;
    final current = all.where((w) => w.id == t.walletId).firstOrNull;
    if (current == null) return const [];
    final options = [
      for (final w in walletsInFamilyOrder(all))
        if (w.currency == current.currency &&
            (w.id == current.id ||
                (!w.isCreditCard
                    ? true
                    : FeatureFlags.creditCards && _isExpense)))
          w,
    ];
    return options.length > 1 ? options : const [];
  }

  @override
  Widget build(BuildContext context) {
    final surface =
        Theme.of(context).extension<AppSurface>() ?? AppSurface.light;

    // Tür değişince vurgu rengi, kategori listesi ve türe özgü alanlar
    // (ödeme yöntemi, taksit) birlikte değişir; nadir bir olay olduğundan
    // içeriğin tamamı yeniden kurulur.
    return ValueListenableBuilder<bool>(
      valueListenable: _c.isExpense,
      builder: (context, _, __) => _buildContent(context, surface),
    );
  }

  Widget _buildContent(BuildContext context, AppSurface surface) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          // Kaydet kaydırılan alanın DIŞINDA. Eskiden içeriğin sonundaydı;
          // tutar alanı açılışta odaklandığı için klavye hep açıktı ve düğme
          // görünür alanın 210dp altında kalıyordu (ölçüldü, 360×800: y=710,
          // sınır 500) — her kayıtta klavyeyi kapatmak ya da kaydırmak
          // gerekiyordu.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DragHandle(),
              Flexible(
                child: SingleChildScrollView(
                  controller: _scroll,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AmountHero(
                        controller: _c,
                        accent: _accent,
                        isExpense: _isExpense,
                        isEdit: _isEdit,
                        focusNode: _amountFocus,
                        onClose: widget.onCancel,
                        onTypeChanged: _c.setExpense,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: _buildFields(context),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ErrorBanner(controller: _c),
                    _SavedNotice(controller: _c),
                    Row(
                      children: [
                        if (!_isEdit &&
                            widget.onSaveAndNew != null &&
                            _saveAndNewEarned) ...[
                          Expanded(
                            flex: 4,
                            child: _SaveAndNewButton(
                              controller: _c,
                              accent: _accent,
                              onSubmit: () => _submit(keepOpen: true),
                              radius: surface.radius,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          flex: 5,
                          child: _SaveButton(
                            controller: _c,
                            accent: _accent,
                            isEdit: _isEdit,
                            onSubmit: _submit,
                            radius: surface.radius,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_paymentOptions(context) case final options
            when options.isNotEmpty) ...[
          PaymentMethodSelector(
            options: options,
            selected: _c.targetWalletId,
            accent: _accent,
          ),
          const SizedBox(height: 18),
        ],
        if (_moveOptions(context) case final options
            when options.isNotEmpty) ...[
          PaymentMethodSelector(
            key: const ValueKey('tx-move-wallet'),
            title: context.l10n.wallet,
            options: options,
            selected: _c.targetWalletId,
            accent: _accent,
          ),
          const SizedBox(height: 18),
        ],
        // Kategori nottan ÖNCE: zorunlu alan, klavye açıkken de kaydırmadan
        // görünmeli. Not isteğe bağlı ve üstteyken şeridi sabit Kaydet
        // satırının arkasına itiyordu (cihazda görüldü: karolar yarıdan
        // kesikti).
        CategoryPicker(
          controller: _c,
          accent: _accent,
          isExpense: _isExpense,
        ),
        const SizedBox(height: 18),
        _TitleField(
          controller: _c,
          accent: _accent,
          isExpense: _isExpense,
        ),
        const SizedBox(height: 22),
        WhenRow(controller: _c, accent: _accent),
        const SizedBox(height: 22),
        ReceiptRow(controller: _c, accent: _accent),
        const SizedBox(height: 22),
        ValueListenableBuilder<int>(
          valueListenable: _c.installments,
          // Taksitli alışveriş tekrarlayan işlem olamaz.
          builder: (context, n, _) => n > 1
              ? const SizedBox.shrink()
              : _RecurringRow(controller: _c, accent: _accent, isEdit: _isEdit),
        ),
        ValueListenableBuilder<String>(
          valueListenable: _c.targetWalletId,
          builder: (context, targetId, _) {
            final offers = _offersInstallments(context, targetId);
            return AnimatedSize(
              duration: _disableAnimations(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: offers
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _InstallmentRow(
                        controller: _c,
                        currency: context.walletById(targetId)?.currency ??
                            context.activeWalletCurrency,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            );
          },
        ),
      ],
    );
  }
}

bool _disableAnimations(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

// ============================================================ Drag handle

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ============================================================ Title field

class _TitleField extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;

  const _TitleField({
    required this.controller,
    required this.accent,
    required this.isExpense,
  });

  /// İpucundaki örnek türe uyar: gelir formunda "market alışverişi" örneği
  /// duruyordu.
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller.titleController,
      textCapitalization: TextCapitalization.sentences,
      maxLength: 50,
      onChanged: (_) {
        if (controller.error.value != null) controller.error.value = null;
      },
      style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        counterText: '',
        hintText: isExpense
            ? context.l10n.hintNotIstegeBagliOrn
            : context.l10n.hintNotIstegeBagliOrnGelir,
        prefixIcon: Icon(Icons.edit_note_rounded,
            color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
      ),
    );
  }
}

// ============================================================ Error banner

class _ErrorBanner extends StatelessWidget {
  final TransactionFormController controller;

  const _ErrorBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller.error,
      builder: (context, error, _) {
        if (error == null) return const SizedBox.shrink();
        final color = AppGradients.debt;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================ Save button

class _SaveButton extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;
  final bool isEdit;
  final VoidCallback onSubmit;
  final double radius;

  const _SaveButton({
    required this.controller,
    required this.accent,
    required this.isEdit,
    required this.onSubmit,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius.clamp(16, 20));
    return ValueListenableBuilder<bool>(
      valueListenable: controller.submitting,
      builder: (context, submitting, _) {
        // Gölge Material'ın DIŞINDA: `Ink` süslemesi Material'ın sınırına
        // kırpılır; gölge içeride kalınca yuvarlak köşelerin arkasında düz
        // renkli bir dikdörtgen olarak görünüyordu (cihazda görüldü).
        return Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: br,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: br,
              onTap: submitting ? null : onSubmit,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppGradients.vivid(accent),
                  borderRadius: br,
                ),
                child: Center(
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isEdit
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEdit
                                    ? context.l10n.guncelle
                                    : context.l10n.kaydet,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================ Save & new

/// "Kaydet ve yeni": kaydı yazar, sayfayı açık bırakır. Art arda birkaç fiş
/// giren kullanıcı her kayıtta kaydırıcı → mini düğme yolunu baştan
/// yürüyordu.
class _SaveAndNewButton extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;
  final VoidCallback onSubmit;
  final double radius;

  const _SaveAndNewButton({
    required this.controller,
    required this.accent,
    required this.onSubmit,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius.clamp(16, 20));
    return ValueListenableBuilder<bool>(
      valueListenable: controller.submitting,
      builder: (context, submitting, _) {
        return SizedBox(
          height: 56,
          child: Material(
            color: accent.withValues(alpha: 0.10),
            borderRadius: br,
            child: InkWell(
              borderRadius: br,
              onTap: submitting ? null : onSubmit,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.l10n.kaydetVeYeni,
                      maxLines: 1,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "Kaydet ve yeni" sonrası onay satırı; yeni tutar yazılmaya başlanınca
/// çekilir (bkz. `AmountHero`).
class _SavedNotice extends StatelessWidget {
  final TransactionFormController controller;

  const _SavedNotice({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller.lastSaved,
      builder: (context, summary, _) {
        if (summary == null) return const SizedBox.shrink();
        final color = AppGradients.savings;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================ Installment row

/// Kart cüzdanında taksit sayısı: tek çekim ya da 2–12 taksit. Seçilince
/// aylık tutar önizlenir (son taksit kuruş farkını emer).
class _InstallmentRow extends StatelessWidget {
  final TransactionFormController controller;
  final String currency;

  const _InstallmentRow({required this.controller, required this.currency});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Tutar yazıldıkça aylık önizleme de tazelenir.
    return ListenableBuilder(
      listenable: Listenable.merge(
          [controller.installments, controller.amountController]),
      builder: (context, _) {
        final n = controller.installments.value;
        final amount = controller.parsedAmount;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.credit_score_rounded,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: n,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: [
                          DropdownMenuItem(
                            value: 1,
                            child: Text(context.l10n.tekCekim),
                          ),
                          for (var k = 2; k <= 12; k++)
                            DropdownMenuItem(
                              value: k,
                              child: Text(context.l10n.taksitSecenek(k)),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          controller.installments.value = v;
                          // Taksitli alışveriş tekrarlayan işlem olamaz.
                          if (v > 1) controller.recurringFrequency.value = null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (n > 1 && amount != null && amount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    context.l10n.taksitOzeti(formatMoney(
                        ((amount * 100).round() ~/ n) / 100,
                        currency: currency)),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================ Recurring row

class _RecurringRow extends StatelessWidget {
  final TransactionFormController controller;
  final Color accent;
  final bool isEdit;

  const _RecurringRow({
    required this.controller,
    required this.accent,
    required this.isEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (isEdit) {
      return const SizedBox.shrink(); // Düzenlemede tekrarlama seçilemez
    }

    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<RecurringFrequency?>(
      valueListenable: controller.recurringFrequency,
      builder: (context, value, _) {
        final row = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.repeat_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RecurringFrequency?>(
                    value: value,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    hint: Text(context.l10n.tekrarlamaIstegeBagli),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(context.l10n.tekrarEtme),
                      ),
                      ...RecurringFrequency.values.map(
                        (freq) => DropdownMenuItem(
                          value: freq,
                          child: Text(
                            switch (freq) {
                              RecurringFrequency.daily => context.l10n.daily,
                              RecurringFrequency.weekly => context.l10n.weekly,
                              RecurringFrequency.monthly =>
                                context.l10n.monthly,
                              RecurringFrequency.yearly => context.l10n.yearly,
                            },
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      controller.recurringFrequency.value = val;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
        // Ne işe yaradığı satırın altında yazar. Eskiden bu, formun ilk
        // açılışında bir kez gösterilen tanıtım baloncuğundaydı.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [row, FieldHint(context.l10n.recurringRowHint)],
        );
      },
    );
  }
}
