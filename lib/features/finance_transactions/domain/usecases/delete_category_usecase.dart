import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

/// Kategori silmenin TEK doğru yolu.
///
/// Silme üç kutuya birden dokunduğu için repository'ye sığmaz:
/// işlemler ve düzenli şablonlar hedefe taşınır, bütçeler temizlenir, ancak
/// ondan sonra kategoriler kutudan düşer. Ana kategori silinirken alt
/// kategorileri de aynı hedefe taşınır — geride üçüncü seviyeye düşmüş ya da
/// sahipsiz kalmış kayıt bırakılmaz.
///
/// Eskiden silme yalnız kutudan `removeWhere` yapıyordu: işlemin `tag`'i
/// silinmiş kimliği taşımaya devam ediyor ve raporda ham kimlik olarak
/// görünüyordu. Bütçe temizliği ise UI'da, üstelik yalnız `isExpense` dalında
/// duruyordu — kategori yöneticisi dışından silinen her kategori hayalet bütçe
/// bırakıyordu.
@injectable
class DeleteCategoryUseCase {
  final CategoryRepository categoryRepository;
  final TransactionsRepository transactionsRepository;
  final RecurringTransactionRepository recurringRepository;
  final DeleteBudgetsForCategoryUsecase deleteBudgetsForCategory;
  final TransactionsChangedNotifier transactionsChangedNotifier;

  DeleteCategoryUseCase(
    this.categoryRepository,
    this.transactionsRepository,
    this.recurringRepository,
    this.deleteBudgetsForCategory,
    this.transactionsChangedNotifier,
  );

  /// [categoryId] ve (ana kategoriyse) alt kategorilerini siler.
  ///
  /// [reassignToId] silinen kimlikleri taşıyan işlemlerin/şablonların yeni
  /// kategorisidir. Kullanımda hiç kayıt yoksa çağıran `null` geçebilir;
  /// kayıt varken `null` geçmek [ValidationFailure] ile reddedilir — kategori
  /// zorunlu bir alan, kategorisiz işlem üretilemez.
  Future<Either<Failure, void>> call({
    required String categoryId,
    String? reassignToId,
  }) async {
    final all = await categoryRepository.getAllCategories();
    final subtree = subtreeIds(categoryId, all);

    if (reassignToId != null && subtree.contains(reassignToId)) {
      return const Left(
        ValidationFailure('Kategori kendi alt ağacına taşınamaz'),
      );
    }

    final countResult = await transactionsRepository.countByTags(subtree);
    final failure = countResult.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) return Left(failure);
    final usageCount = countResult.getOrElse(() => 0);

    if (usageCount > 0) {
      if (reassignToId == null) {
        return const Left(
          ValidationFailure('Taşınacak kategori seçilmeden silinemez'),
        );
      }
      final retag =
          await transactionsRepository.retagTransactions(subtree, reassignToId);
      final retagFailure = retag.fold<Failure?>((f) => f, (_) => null);
      if (retagFailure != null) return Left(retagFailure);
    }

    // Şablonlar defterden bağımsız sayılır: kullanımda hiç işlem olmasa bile
    // silinen kategoriye yazılmış bir şablon her ay onu geri getirirdi.
    if (reassignToId != null) {
      final retagTemplates =
          await recurringRepository.retagTemplates(subtree, reassignToId);
      final templateFailure =
          retagTemplates.fold<Failure?>((f) => f, (_) => null);
      if (templateFailure != null) return Left(templateFailure);
    }

    // Bütçe alt ağacın HER kimliği için ayrı ayrı temizlenir; ana kategorinin
    // bütçesini silip çocuğunkini bırakmak hayalet bütçe demekti.
    for (final id in subtree) {
      final result = await deleteBudgetsForCategory(id);
      final budgetFailure = result.fold<Failure?>((f) => f, (_) => null);
      if (budgetFailure != null) return Left(budgetFailure);
    }

    await categoryRepository.deleteCategories(subtree);

    // Kategori değişimini `CategoryRepository` yayar; defter değişimini burada
    // yaymak gerekir, yoksa açık işlem/rapor/bütçe sayfaları taşınmış
    // etiketleri eski hâliyle gösterir.
    if (usageCount > 0) transactionsChangedNotifier.notify();

    return const Right(null);
  }
}
