import 'package:flutter/material.dart';

import '../../models/account_model.dart';
import '../../models/category_model.dart';
import '../../models/transaction_history_item.dart';
import '../../providers/transaction_change_notifier.dart';
import '../../services/account_service.dart';
import '../../services/category_service.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/cards/transaction_list_item.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/inputs/app_dropdown_field.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late Future<_TransactionFiltersData> _filtersFuture;
  AccountModel? _account;
  CategoryModel? _category;
  String? _type;
  String? _currency;

  @override
  void initState() {
    super.initState();
    _filtersFuture = _loadFilters();
  }

  Future<_TransactionFiltersData> _loadFilters() async {
    final accounts = await AccountService().getAllAccounts();
    final categories = await CategoryService().getAllCategories();
    return _TransactionFiltersData(accounts: accounts, categories: categories);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Transacciones',
      children: [
        const SectionHeader(
          title: 'Todas las transacciones',
          subtitle: 'Historial global de ingresos y gastos.',
        ),
        FutureBuilder<_TransactionFiltersData>(
          future: _filtersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const EmptyState(
                title: 'No se pudieron cargar filtros',
                message: 'Revisa la base local e intenta nuevamente.',
                icon: Icons.error_outline,
              );
            }
            return _Filters(
              data: snapshot.data!,
              account: _account,
              category: _category,
              type: _type,
              currency: _currency,
              onAccountChanged: (value) => setState(() => _account = value),
              onCategoryChanged: (value) => setState(() => _category = value),
              onTypeChanged: (value) => setState(() => _type = value),
              onCurrencyChanged: (value) => setState(() => _currency = value),
              onClear: () {
                setState(() {
                  _account = null;
                  _category = null;
                  _type = null;
                  _currency = null;
                });
              },
            );
          },
        ),
        ValueListenableBuilder<int>(
          valueListenable: TransactionChangeNotifier.version,
          builder: (context, _, __) {
            return FutureBuilder<List<TransactionHistoryItem>>(
              future: TransactionService().getTransactionHistory(
                accountId: _account?.id,
                categoryId: _category?.id,
                type: _type,
                currency: _currency,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const EmptyState(
                    title: 'No se pudo cargar el historial',
                    message: 'Intenta nuevamente.',
                    icon: Icons.error_outline,
                  );
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'Sin movimientos',
                    message: 'No hay transacciones con estos filtros.',
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return AppCard(
                  child: Column(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        TransactionListItem(
                          item: items[index],
                          onTap: () => _editTransaction(items[index]),
                          trailing: IconButton(
                            tooltip: 'Eliminar',
                            onPressed: () => _deleteTransaction(items[index]),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                        if (index < items.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _editTransaction(TransactionHistoryItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => TransactionFormScreen(
          type: item.transaction.type,
          initialTransaction: item.transaction,
        ),
      ),
    );
    TransactionChangeNotifier.notifyChanged();
  }

  Future<void> _deleteTransaction(TransactionHistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text('Se revertira el saldo de la cuenta asociada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await TransactionService().deleteTransaction(item.transaction.id!);
    TransactionChangeNotifier.notifyChanged();
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.data,
    required this.account,
    required this.category,
    required this.type,
    required this.currency,
    required this.onAccountChanged,
    required this.onCategoryChanged,
    required this.onTypeChanged,
    required this.onCurrencyChanged,
    required this.onClear,
  });

  final _TransactionFiltersData data;
  final AccountModel? account;
  final CategoryModel? category;
  final String? type;
  final String? currency;
  final ValueChanged<AccountModel?> onAccountChanged;
  final ValueChanged<CategoryModel?> onCategoryChanged;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.surfaceAlt,
      child: Column(
        children: [
          AppDropdownField<AccountModel>(
            label: 'Cuenta',
            items: data.accounts,
            itemLabel: (item) => item.name,
            value: account,
            prefixIcon: Icons.account_balance_wallet_outlined,
            onChanged: onAccountChanged,
          ),
          const SizedBox(height: 12),
          AppDropdownField<CategoryModel>(
            label: 'Categoria',
            items: data.categories,
            itemLabel: (item) => item.name,
            value: category,
            prefixIcon: Icons.category_outlined,
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppDropdownField<String>(
                  label: 'Tipo',
                  items: const ['income', 'expense'],
                  itemLabel: (item) => item == 'income' ? 'Ingreso' : 'Gasto',
                  value: type,
                  prefixIcon: Icons.swap_vert,
                  onChanged: onTypeChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppDropdownField<String>(
                  label: 'Moneda',
                  items: const ['SOL', 'USD'],
                  itemLabel: (item) => item,
                  value: currency,
                  prefixIcon: Icons.currency_exchange,
                  onChanged: onCurrencyChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Limpiar filtros'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionFiltersData {
  const _TransactionFiltersData({
    required this.accounts,
    required this.categories,
  });

  final List<AccountModel> accounts;
  final List<CategoryModel> categories;
}
