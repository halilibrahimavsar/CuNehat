// lib/features/recurring_transactions/presentation/pages/recurring_templates_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/shared/widgets/app_card.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import '../../domain/entities/recurring_frequency_enum.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/usecases/delete_recurring_transaction_usecase.dart';
import '../../domain/usecases/get_all_recurring_templates_usecase.dart';
import '../../domain/usecases/save_recurring_transaction_usecase.dart';

/// Düzenli işlem şablonlarını yönetir: listele, duraklat/devam ettir, sil.
/// (Şablonlar işlem girişinde "tekrarla" seçilerek oluşturulur.)
class RecurringTemplatesPage extends StatefulWidget {
  const RecurringTemplatesPage({super.key});

  @override
  State<RecurringTemplatesPage> createState() => _RecurringTemplatesPageState();
}

class _RecurringTemplatesPageState extends State<RecurringTemplatesPage> {
  final _getAllUsecase = getIt<GetAllRecurringTemplatesUsecase>();
  final _saveUsecase = getIt<SaveRecurringTransactionUsecase>();
  final _deleteUsecase = getIt<DeleteRecurringTransactionUsecase>();

  List<RecurringTransactionEntity> _templates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    final result = await _getAllUsecase();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _isLoading = false;
      }),
      (templates) => setState(() {
        _templates = templates
          ..sort((a, b) => a.nextExecutionDate.compareTo(b.nextExecutionDate));
        _error = null;
        _isLoading = false;
      }),
    );
  }

  Future<void> _toggleActive(RecurringTransactionEntity template) async {
    await _saveUsecase(template.copyWith(isActive: !template.isActive));
    _loadTemplates();
  }

  Future<void> _delete(RecurringTransactionEntity template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şablonu Sil'),
        content: Text(
            '"${template.title}" düzenli işlemi silinsin mi?\n\nDeftere işlenmiş geçmiş işlemler silinmez.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _deleteUsecase(template.id);
      _loadTemplates();
    }
  }

  String _frequencyLabel(RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'Günlük';
      case RecurringFrequency.weekly:
        return 'Haftalık';
      case RecurringFrequency.monthly:
        return 'Aylık';
      case RecurringFrequency.yearly:
        return 'Yıllık';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Düzenli İşlemler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Hata: $_error'));
    }
    if (_templates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Henüz düzenli işlem yok.\n\nİşlem eklerken tekrar sıklığı seçerseniz şablon burada görünür.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTemplates,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final template = _templates[index];
          final isIncome = template.type == TransactionTypeModel.income;
          final dateStr =
              DateFormat('dd MMM yyyy').format(template.nextExecutionDate);

          return AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Icon(
                isIncome ? Icons.trending_up : Icons.trending_down,
                color: isIncome ? Colors.green : Colors.red,
              ),
              title: Text(
                template.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration:
                      template.isActive ? null : TextDecoration.lineThrough,
                ),
              ),
              subtitle: Text(
                '${formatMoney(template.amount)} · ${_frequencyLabel(template.frequency)}\n'
                '${template.isActive ? "Sonraki: $dateStr" : "Duraklatıldı"}',
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: template.isActive,
                    onChanged: (_) => _toggleActive(template),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _delete(template),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
