import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:flutter/widgets.dart';

/// Kategori kural ihlallerinin TEK çeviri noktası.
///
/// Veri katmanı tipli [CategoryValidationError] fırlatır, hazır metin değil:
/// eskiden `Exception('Bu isimde bir kategori zaten var')` doğrudan ekrana
/// basılıyordu ve İngilizce arayüzde Türkçe görünüyordu.
String categoryErrorMessage(BuildContext context, CategoryValidationError e) =>
    switch (e) {
      CategoryValidationError.emptyName => context.l10n.kategoriAdiBosOlamaz,
      CategoryValidationError.duplicateSiblingName =>
        context.l10n.categoryErrorDuplicateName,
      CategoryValidationError.parentNotFound =>
        context.l10n.categoryErrorParentNotFound,
      CategoryValidationError.parentIsNotRoot =>
        context.l10n.categoryErrorParentIsNotRoot,
      CategoryValidationError.typeMismatch =>
        context.l10n.categoryErrorTypeMismatch,
      CategoryValidationError.selfParent =>
        context.l10n.categoryErrorSelfParent,
      CategoryValidationError.parentHasChildren =>
        context.l10n.categoryErrorParentHasChildren,
    };

/// Yakalanan hatayı kullanıcıya gösterilecek metne çevirir. Kategori kuralı
/// dışındaki hatalar genel biçime düşer.
String categoryFailureMessage(BuildContext context, Object error) =>
    error is CategoryException
        ? categoryErrorMessage(context, error.error)
        : context.l10n.hataError(error.toString());
