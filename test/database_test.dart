import 'package:finanzas_personales/database/app_database.dart';
import 'package:finanzas_personales/models/account_model.dart';
import 'package:finanzas_personales/models/budget_rule_model.dart';
import 'package:finanzas_personales/models/budget_summary_model.dart';
import 'package:finanzas_personales/models/category_model.dart';
import 'package:finanzas_personales/models/financial_transaction_model.dart';
import 'package:finanzas_personales/models/quick_action_model.dart';
import 'package:finanzas_personales/models/transfer_model.dart';
import 'package:finanzas_personales/services/account_service.dart';
import 'package:finanzas_personales/services/budget_calculator.dart';
import 'package:finanzas_personales/services/budget_service.dart';
import 'package:finanzas_personales/services/category_service.dart';
import 'package:finanzas_personales/services/exchange_rate_service.dart';
import 'package:finanzas_personales/services/quick_action_service.dart';
import 'package:finanzas_personales/services/transaction_service.dart';
import 'package:finanzas_personales/services/transfer_service.dart';
import 'package:finanzas_personales/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late CategoryService categoryService;
  late AccountService accountService;
  late TransactionService transactionService;
  late TransferService transferService;
  late BudgetService budgetService;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await database.initialize();
    categoryService = CategoryService(database: database);
    accountService = AccountService(database: database);
    transactionService = TransactionService(database: database);
    transferService = TransferService(database: database);
    budgetService = BudgetService(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test('crea la base de datos y tablas iniciales', () async {
    final db = await database.database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'accounts'",
    );

    expect(tables, isNotEmpty);
  });

  test('inserta y lee categorias', () async {
    final now = AppDateUtils.nowIso();
    await categoryService.insertCategory(
      CategoryModel(name: 'Test categoria', type: 'expense', createdAt: now),
    );

    final categories = await categoryService.getAllCategories();

    expect(
      categories.any((category) => category.name == 'Test categoria'),
      isTrue,
    );
  });

  test('inserta y lee cuentas', () async {
    final now = AppDateUtils.nowIso();
    await accountService.insertAccount(
      AccountModel(
        name: 'Cuenta test',
        accountType: 'efectivo',
        currency: 'SOL',
        initialBalance: 50,
        currentBalance: 50,
        createdAt: now,
      ),
    );

    final accounts = await accountService.getAllAccounts();

    expect(accounts.any((account) => account.name == 'Cuenta test'), isTrue);
  });

  test('edita cuenta', () async {
    final now = AppDateUtils.nowIso();
    final id = await accountService.insertAccount(
      AccountModel(
        name: 'Cuenta editable',
        accountType: 'ahorros',
        currency: 'SOL',
        initialBalance: 0,
        currentBalance: 0,
        createdAt: now,
      ),
    );

    await accountService.updateAccount(
      AccountModel(
        id: id,
        name: 'Cuenta actualizada',
        accountType: 'billetera',
        currency: 'SOL',
        initialBalance: 0,
        currentBalance: 0,
        isHiddenFromBudget: true,
        color: '#16A34A',
        icon: 'wallet',
        createdAt: now,
      ),
    );

    final account = await accountService.getAccountById(id);

    expect(account!.name, 'Cuenta actualizada');
    expect(account.accountType, 'billetera');
    expect(account.isHiddenFromBudget, isTrue);
  });

  test('elimina cuenta sin movimientos', () async {
    final now = AppDateUtils.nowIso();
    final id = await accountService.insertAccount(
      AccountModel(
        name: 'Cuenta temporal',
        accountType: 'efectivo',
        currency: 'SOL',
        initialBalance: 0,
        currentBalance: 0,
        createdAt: now,
      ),
    );

    await accountService.deleteAccount(id);

    expect(await accountService.getAccountById(id), isNull);
  });

  test('no elimina cuenta con movimientos', () async {
    final account = (await accountService.getVisibleAccounts()).first;
    final category = (await categoryService.getAllCategories()).firstWhere(
      (category) => category.type == 'expense',
    );
    final now = AppDateUtils.nowIso();

    await transactionService.insertTransaction(
      FinancialTransactionModel(
        type: 'expense',
        amount: 5,
        currency: account.currency,
        accountId: account.id!,
        categoryId: category.id!,
        date: now,
        createdAt: now,
      ),
    );

    await expectLater(
      accountService.deleteAccount(account.id!),
      throwsStateError,
    );
  });

  test('inserta gasto y actualiza saldo', () async {
    final account = (await accountService.getVisibleAccounts()).first;
    final category = (await categoryService.getAllCategories()).firstWhere(
      (category) => category.type == 'expense',
    );
    final now = AppDateUtils.nowIso();

    await transactionService.insertTransaction(
      FinancialTransactionModel(
        type: 'expense',
        amount: 25,
        currency: account.currency,
        accountId: account.id!,
        categoryId: category.id!,
        date: now,
        createdAt: now,
      ),
    );

    final updated = await accountService.getAccountById(account.id!);
    final transactions = await transactionService.getAllTransactions();

    expect(updated!.currentBalance, account.currentBalance - 25);
    expect(transactions, hasLength(1));
    expect(transactions.single.type, 'expense');
  });

  test('inserta ingreso y actualiza saldo', () async {
    final account = (await accountService.getVisibleAccounts()).first;
    final category = (await categoryService.getAllCategories()).firstWhere(
      (category) => category.type == 'income',
    );
    final now = AppDateUtils.nowIso();

    await transactionService.insertTransaction(
      FinancialTransactionModel(
        type: 'income',
        amount: 100,
        currency: account.currency,
        accountId: account.id!,
        categoryId: category.id!,
        date: now,
        createdAt: now,
      ),
    );

    final updated = await accountService.getAccountById(account.id!);
    final transactions = await transactionService.getAllTransactions();

    expect(updated!.currentBalance, account.currentBalance + 100);
    expect(transactions, hasLength(1));
    expect(transactions.single.type, 'income');
  });

  test('edita transaccion y recalcula saldo', () async {
    final account = (await accountService.getVisibleAccounts()).first;
    final category = (await categoryService.getAllCategories()).firstWhere(
      (category) => category.type == 'expense',
    );
    final now = AppDateUtils.nowIso();

    final id = await transactionService.insertTransaction(
      FinancialTransactionModel(
        type: 'expense',
        amount: 10,
        currency: account.currency,
        accountId: account.id!,
        categoryId: category.id!,
        date: now,
        createdAt: now,
      ),
    );

    await transactionService.updateTransaction(
      FinancialTransactionModel(
        id: id,
        type: 'expense',
        amount: 25,
        currency: account.currency,
        accountId: account.id!,
        categoryId: category.id!,
        date: now,
        comment: 'Editado',
        createdAt: now,
      ),
    );

    final updated = await accountService.getAccountById(account.id!);
    final transaction = await transactionService.getTransactionById(id);

    expect(updated!.currentBalance, account.currentBalance - 25);
    expect(transaction!.amount, 25);
    expect(transaction.comment, 'Editado');
  });

  test('elimina gasto y devuelve saldo', () async {
    final account = (await accountService.getVisibleAccounts()).first;
    final category = (await categoryService.getAllCategories()).firstWhere(
      (category) => category.type == 'expense',
    );
    final now = AppDateUtils.nowIso();

    final id = await transactionService.insertTransaction(
      FinancialTransactionModel(
        type: 'expense',
        amount: 18,
        currency: account.currency,
        accountId: account.id!,
        categoryId: category.id!,
        date: now,
        createdAt: now,
      ),
    );

    await transactionService.deleteTransaction(id);

    final updated = await accountService.getAccountById(account.id!);
    final transactions = await transactionService.getAllTransactions();

    expect(updated!.currentBalance, account.currentBalance);
    expect(transactions, isEmpty);
  });

  test('lista transacciones por cuenta y globales', () async {
    final accounts = await accountService.getVisibleAccounts();
    final firstAccount = accounts.first;
    final secondAccount = accounts[1];
    final expenseCategory = (await categoryService.getAllCategories())
        .firstWhere((category) => category.type == 'expense');
    final incomeCategory = (await categoryService.getAllCategories())
        .firstWhere((category) => category.type == 'income');
    final now = AppDateUtils.nowIso();

    await transactionService.insertTransaction(
      FinancialTransactionModel(
        type: 'expense',
        amount: 12,
        currency: firstAccount.currency,
        accountId: firstAccount.id!,
        categoryId: expenseCategory.id!,
        date: now,
        createdAt: now,
      ),
    );
    await transactionService.insertTransaction(
      FinancialTransactionModel(
        type: 'income',
        amount: 30,
        currency: secondAccount.currency,
        accountId: secondAccount.id!,
        categoryId: incomeCategory.id!,
        date: now,
        createdAt: now,
      ),
    );

    final byAccount = await transactionService.getTransactionHistoryByAccount(
      firstAccount.id!,
    );
    final global = await transactionService.getTransactionHistory();

    expect(byAccount, hasLength(1));
    expect(byAccount.single.transaction.accountId, firstAccount.id);
    expect(global, hasLength(2));
  });

  test('guarda gasto USD con monto base usando tipo de cambio', () async {
    final account = (await accountService.getVisibleAccounts()).firstWhere(
      (account) => account.currency == 'USD',
    );
    final category = (await categoryService.getAllCategories()).firstWhere(
      (category) => category.type == 'expense',
    );
    final now = AppDateUtils.nowIso();

    await transactionService.insertTransaction(
      FinancialTransactionModel(
        type: 'expense',
        amount: 10,
        currency: 'USD',
        exchangeRate: 3.8,
        accountId: account.id!,
        categoryId: category.id!,
        date: now,
        createdAt: now,
      ),
    );

    final transactions = await transactionService.getAllTransactions();

    expect(transactions.single.amountInBaseCurrency, 38);
  });

  test('quick action carga datos correctos', () async {
    final actions = await QuickActionService(
      database: database,
    ).getAllQuickActions();
    final menu = actions.firstWhere((action) => action.name == 'Menú');

    expect(menu.amount, 12);
    expect(menu.currency, 'SOL');
    expect(menu.accountId, isNotNull);
    expect(menu.categoryId, isNotNull);
  });

  test('registro rapido guarda gasto y actualiza saldo', () async {
    final menu = (await QuickActionService(
      database: database,
    ).getAllQuickActions())
        .firstWhere((action) => action.name == 'Menú');
    final account = await accountService.getAccountById(menu.accountId!);
    final now = AppDateUtils.nowIso();

    await transactionService.insertTransaction(
      FinancialTransactionModel(
        type: 'expense',
        amount: menu.amount,
        currency: menu.currency,
        accountId: menu.accountId!,
        categoryId: menu.categoryId!,
        date: now,
        comment: menu.comment ?? menu.name,
        createdAt: now,
      ),
    );

    final updated = await accountService.getAccountById(menu.accountId!);
    final history = await transactionService.getTransactionHistoryByAccount(
      menu.accountId!,
    );

    expect(updated!.currentBalance, account!.currentBalance - menu.amount);
    expect(history.single.transaction.comment, menu.comment ?? menu.name);
  });

  test('no permite monto 0 o negativo', () async {
    final account = (await accountService.getVisibleAccounts()).first;
    final category = (await categoryService.getAllCategories()).firstWhere(
      (category) => category.type == 'expense',
    );
    final now = AppDateUtils.nowIso();

    Future<void> insertWithAmount(double amount) {
      return transactionService.insertTransaction(
        FinancialTransactionModel(
          type: 'expense',
          amount: amount,
          currency: account.currency,
          accountId: account.id!,
          categoryId: category.id!,
          date: now,
          createdAt: now,
        ),
      );
    }

    expect(() => insertWithAmount(0), throwsArgumentError);
    expect(() => insertWithAmount(-1), throwsArgumentError);
  });

  test('no permite guardar sin cuenta o categoria valida', () async {
    final account = (await accountService.getVisibleAccounts()).first;
    final category = (await categoryService.getAllCategories()).firstWhere(
      (category) => category.type == 'expense',
    );
    final now = AppDateUtils.nowIso();

    expect(
      () => transactionService.insertTransaction(
        FinancialTransactionModel(
          type: 'expense',
          amount: 10,
          currency: account.currency,
          accountId: 0,
          categoryId: category.id!,
          date: now,
          createdAt: now,
        ),
      ),
      throwsArgumentError,
    );

    expect(
      () => transactionService.insertTransaction(
        FinancialTransactionModel(
          type: 'expense',
          amount: 10,
          currency: account.currency,
          accountId: account.id!,
          categoryId: 0,
          date: now,
          createdAt: now,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('historial devuelve movimientos con cuenta y categoria', () async {
    final account = (await accountService.getVisibleAccounts()).first;
    final category = (await categoryService.getAllCategories()).firstWhere(
      (category) => category.type == 'income',
    );
    final now = AppDateUtils.nowIso();

    await transactionService.insertTransaction(
      FinancialTransactionModel(
        type: 'income',
        amount: 75,
        currency: account.currency,
        accountId: account.id!,
        categoryId: category.id!,
        date: now,
        comment: 'Bono',
        createdAt: now,
      ),
    );

    final history = await transactionService.getLatestTransactions();

    expect(history, hasLength(1));
    expect(history.single.accountName, account.name);
    expect(history.single.categoryName, category.name);
    expect(history.single.transaction.comment, 'Bono');
  });

  test('transfiere SOL a SOL y crea movimientos relacionados', () async {
    final accounts = await accountService.getVisibleAccounts();
    final solAccounts =
        accounts.where((account) => account.currency == 'SOL').toList();
    final from = solAccounts.first;
    final to = solAccounts[1];
    final now = AppDateUtils.nowIso();

    await transferService.insertTransfer(
      TransferModel(
        fromAccountId: from.id!,
        toAccountId: to.id!,
        amountFrom: 30,
        currencyFrom: from.currency,
        amountTo: 30,
        currencyTo: to.currency,
        date: now,
        createdAt: now,
      ),
    );

    final updatedFrom = await accountService.getAccountById(from.id!);
    final updatedTo = await accountService.getAccountById(to.id!);
    final transactions = await transactionService.getAllTransactions();
    final transfers = await transferService.getAllTransfers();

    expect(updatedFrom!.currentBalance, from.currentBalance - 30);
    expect(updatedTo!.currentBalance, to.currentBalance + 30);
    expect(transfers, hasLength(1));
    expect(transactions, hasLength(2));
    expect(
      transactions.map((transaction) => transaction.type),
      containsAll(['expense', 'income']),
    );
    expect(
      transactions.every(
        (transaction) => transaction.comment!.startsWith('Transferencia #'),
      ),
      isTrue,
    );
  });

  test('transfiere USD a USD y crea historial en ambas cuentas', () async {
    final accounts = await accountService.getVisibleAccounts();
    final from = accounts.firstWhere((account) => account.currency == 'USD');
    final now = AppDateUtils.nowIso();
    final toId = await accountService.insertAccount(
      AccountModel(
        name: 'Cuenta USD secundaria',
        accountType: 'ahorros',
        currency: 'USD',
        initialBalance: 50,
        currentBalance: 50,
        createdAt: now,
      ),
    );
    final to = (await accountService.getAccountById(toId))!;

    await transferService.insertTransfer(
      TransferModel(
        fromAccountId: from.id!,
        toAccountId: to.id!,
        amountFrom: 25,
        currencyFrom: 'USD',
        amountTo: 25,
        currencyTo: 'USD',
        date: now,
        createdAt: now,
      ),
    );

    final updatedFrom = await accountService.getAccountById(from.id!);
    final updatedTo = await accountService.getAccountById(to.id!);
    final fromHistory = await transactionService.getTransactionHistoryByAccount(
      from.id!,
    );
    final toHistory = await transactionService.getTransactionHistoryByAccount(
      to.id!,
    );

    expect(updatedFrom!.currentBalance, from.currentBalance - 25);
    expect(updatedTo!.currentBalance, to.currentBalance + 25);
    expect(fromHistory.single.transaction.type, 'expense');
    expect(toHistory.single.transaction.type, 'income');
  });

  test('transfiere SOL a USD con tipo de cambio manual', () async {
    final accounts = await accountService.getVisibleAccounts();
    final from = accounts.firstWhere((account) => account.currency == 'SOL');
    final to = accounts.firstWhere((account) => account.currency == 'USD');
    final now = AppDateUtils.nowIso();

    await transferService.insertTransfer(
      TransferModel(
        fromAccountId: from.id!,
        toAccountId: to.id!,
        amountFrom: 100,
        currencyFrom: 'SOL',
        amountTo: 100 / 3.75,
        currencyTo: 'USD',
        exchangeRate: 3.75,
        date: now,
        createdAt: now,
      ),
    );

    final updatedFrom = await accountService.getAccountById(from.id!);
    final updatedTo = await accountService.getAccountById(to.id!);
    final transactions = await transactionService.getAllTransactions();

    expect(updatedFrom!.currentBalance, from.currentBalance - 100);
    expect(updatedTo!.currentBalance, closeTo(to.currentBalance + 26.67, 0.01));
    expect(transactions, hasLength(2));
  });

  test('transfiere USD a SOL con tipo de cambio manual', () async {
    final accounts = await accountService.getVisibleAccounts();
    final from = accounts.firstWhere((account) => account.currency == 'USD');
    final to = accounts.firstWhere((account) => account.currency == 'SOL');
    final now = AppDateUtils.nowIso();

    await transferService.insertTransfer(
      TransferModel(
        fromAccountId: from.id!,
        toAccountId: to.id!,
        amountFrom: 10,
        currencyFrom: 'USD',
        amountTo: 37.5,
        currencyTo: 'SOL',
        exchangeRate: 3.75,
        date: now,
        createdAt: now,
      ),
    );

    final updatedFrom = await accountService.getAccountById(from.id!);
    final updatedTo = await accountService.getAccountById(to.id!);
    final transactions = await transactionService.getAllTransactions();

    expect(updatedFrom!.currentBalance, from.currentBalance - 10);
    expect(updatedTo!.currentBalance, to.currentBalance + 37.5);
    expect(transactions, hasLength(2));
  });

  test('no permite transferencia invalida', () async {
    final account = (await accountService.getVisibleAccounts()).first;
    final now = AppDateUtils.nowIso();

    expect(
      () => transferService.insertTransfer(
        TransferModel(
          fromAccountId: account.id!,
          toAccountId: account.id!,
          amountFrom: 10,
          currencyFrom: account.currency,
          amountTo: 10,
          currencyTo: account.currency,
          date: now,
          createdAt: now,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => transferService.insertTransfer(
        TransferModel(
          fromAccountId: account.id!,
          toAccountId: account.id! + 1,
          amountFrom: 0,
          currencyFrom: account.currency,
          amountTo: 0,
          currencyTo: account.currency,
          date: now,
          createdAt: now,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('crea edita y elimina boton rapido persistente', () async {
    final quickActionService = QuickActionService(database: database);
    final account = (await accountService.getVisibleAccounts()).first;
    final category = (await categoryService.getAllCategories()).firstWhere(
      (category) => category.type == 'expense',
    );
    final now = AppDateUtils.nowIso();

    final id = await quickActionService.insertQuickAction(
      QuickActionModel(
        name: 'Snack',
        amount: 7,
        currency: 'SOL',
        categoryId: category.id!,
        accountId: account.id!,
        icon: 'food',
        color: '#20C982',
        sortOrder: 8,
        createdAt: now,
      ),
    );
    await quickActionService.updateQuickAction(
      QuickActionModel(
        id: id,
        name: 'Snack editado',
        amount: 9,
        currency: 'SOL',
        categoryId: category.id!,
        accountId: account.id!,
        icon: 'coffee',
        color: '#FFB020',
        isActive: false,
        sortOrder: 9,
        createdAt: now,
      ),
    );

    final all = await quickActionService.getAllQuickActions(activeOnly: false);
    final edited = all.firstWhere((action) => action.id == id);
    expect(edited.name, 'Snack editado');
    expect(edited.isActive, isFalse);

    await quickActionService.deleteQuickAction(id);
    final afterDelete = await quickActionService.getAllQuickActions(
      activeOnly: false,
    );
    expect(afterDelete.any((action) => action.id == id), isFalse);
  });

  test('ajuste manual positivo suma saldo y genera movimiento', () async {
    final account = (await accountService.getVisibleAccounts()).first;
    final category = await categoryService.getOrCreateCategory(
      name: 'Ajuste Manual',
      type: 'income',
      icon: 'wallet',
      color: '#20C982',
    );
    final now = AppDateUtils.nowIso();

    await transactionService.insertTransaction(
      FinancialTransactionModel(
        type: 'income',
        amount: 12,
        currency: account.currency,
        accountId: account.id!,
        categoryId: category.id!,
        date: now,
        comment: 'Ajuste Manual',
        createdAt: now,
      ),
    );

    final updated = await accountService.getAccountById(account.id!);
    final history = await transactionService.getTransactionHistoryByAccount(
      account.id!,
    );

    expect(updated!.currentBalance, account.currentBalance + 12);
    expect(history.single.transaction.comment, 'Ajuste Manual');
  });

  test('ajuste manual negativo resta saldo y genera movimiento', () async {
    final account = (await accountService.getVisibleAccounts()).first;
    final category = await categoryService.getOrCreateCategory(
      name: 'Ajuste Manual',
      type: 'expense',
      icon: 'wallet',
      color: '#FF4D5E',
    );
    final now = AppDateUtils.nowIso();

    await transactionService.insertTransaction(
      FinancialTransactionModel(
        type: 'expense',
        amount: 7.5,
        currency: account.currency,
        accountId: account.id!,
        categoryId: category.id!,
        date: now,
        comment: 'Ajuste Manual',
        createdAt: now,
      ),
    );

    final updated = await accountService.getAccountById(account.id!);
    final history = await transactionService.getTransactionHistoryByAccount(
      account.id!,
    );

    expect(updated!.currentBalance, account.currentBalance - 7.5);
    expect(history.single.transaction.type, 'expense');
    expect(history.single.transaction.comment, 'Ajuste Manual');
  });

  test('lee botones rapidos iniciales', () async {
    final actions = await QuickActionService(
      database: database,
    ).getAllQuickActions();

    expect(
      actions.map((action) => action.name),
      containsAll(['Menú', 'Pasaje', 'Café', 'Postre', 'Taxi']),
    );
  });

  test('lee tipo de cambio inicial', () async {
    final latest = await ExchangeRateService(
      database: database,
    ).getLatestRate();

    expect(latest, isNotNull);
    expect(latest!.rate, 3.80);
  });

  test('persiste y edita un presupuesto por categoria', () async {
    final category = (await categoryService.getAllCategories())
        .firstWhere((item) => item.type == 'expense');
    final now = AppDateUtils.nowIso();
    final id = await budgetService.insertBudgetRule(
      BudgetRuleModel(
        name: 'Comida mensual',
        categoryId: category.id,
        amount: 600,
        currency: 'SOL',
        recurrenceType: BudgetRecurrenceType.monthly,
        startDate: '2026-07-01T00:00:00.000',
        createdAt: now,
      ),
    );

    final created = (await budgetService.getAllBudgetRules()).single;
    expect(created.id, id);
    expect(created.amount, 600);

    await budgetService.updateBudgetRule(created.copyWith(amount: 650));
    final edited = (await budgetService.getAllBudgetRules()).single;
    expect(edited.amount, 650);
  });

  test('migra reglas de presupuesto v1 sin borrar datos', () async {
    final path =
        '/tmp/duna_budget_migration_${DateTime.now().microsecondsSinceEpoch}.db';
    final oldDatabase = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
)
''');
          await db.execute('''
CREATE TABLE budget_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  currency TEXT NOT NULL,
  recurrence_type TEXT NOT NULL,
  selected_weekdays TEXT,
  start_date TEXT,
  end_date TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
)
''');
        },
      ),
    );
    final categoryId = await oldDatabase.insert('categories', {
      'name': 'Comida',
      'type': 'expense',
      'created_at': '2026-07-01T00:00:00.000',
    });
    await oldDatabase.insert('budget_rules', {
      'name': 'Presupuesto anterior',
      'category_id': categoryId,
      'amount': 250,
      'currency': 'SOL',
      'recurrence_type': BudgetRecurrenceType.monthly,
      'is_active': 1,
      'created_at': '2026-07-01T00:00:00.000',
    });
    await oldDatabase.close();

    final upgraded = AppDatabase.test(
      databaseFactory: databaseFactoryFfi,
      databasePath: path,
    );
    final migrated =
        await BudgetService(database: upgraded).getAllBudgetRules();

    expect(migrated, hasLength(1));
    expect(migrated.single.name, 'Presupuesto anterior');
    expect(migrated.single.amount, 250);
    await upgraded.close();
    await databaseFactoryFfi.deleteDatabase(path);
  });

  test('calcula repeticion por dias y unidades para el mes', () {
    const rule = BudgetRuleModel(
      name: 'Pasajes',
      budgetType: BudgetType.recurrence,
      categoryId: 1,
      amount: 3.20,
      unitsPerDay: 2,
      currency: 'SOL',
      recurrenceType: BudgetRecurrenceType.customWeekdays,
      selectedWeekdays: '1,2,3,4,5',
      startDate: '2026-07-01T00:00:00.000',
      createdAt: '2026-07-01T00:00:00.000',
    );

    expect(BudgetCalculator.occurrencesForMonth(rule, 2026, 7), hasLength(23));
    expect(
        BudgetCalculator.monthlyAmount(rule, 2026, 7), closeTo(147.2, 0.001));
  });

  test('clasifica estados de presupuesto en 80 y 100 por ciento', () {
    expect(
      BudgetStatus.from(spent: 79, budget: 100),
      BudgetStatus.good,
    );
    expect(
      BudgetStatus.from(spent: 80, budget: 100),
      BudgetStatus.warning,
    );
    expect(
      BudgetStatus.from(spent: 100, budget: 100),
      BudgetStatus.exceeded,
    );
  });

  test('compara gastos reales y excluye ingresos ajustes y transferencias',
      () async {
    final categories = await categoryService.getAllCategories();
    final food = categories.firstWhere((item) => item.name == 'Comida');
    final accounts = (await accountService.getVisibleAccounts())
        .where((item) => item.currency == 'SOL')
        .toList();
    const date = '2026-07-10T00:00:00.000';
    final now = AppDateUtils.nowIso();

    await transferService.insertTransfer(
      TransferModel(
        fromAccountId: accounts[0].id!,
        toAccountId: accounts[1].id!,
        amountFrom: 20,
        currencyFrom: 'SOL',
        amountTo: 20,
        currencyTo: 'SOL',
        date: date,
        createdAt: now,
      ),
    );
    final transferCategory = (await categoryService.getAllCategories())
        .firstWhere((item) => item.name == 'Transferencia enviada');

    for (final transaction in [
      FinancialTransactionModel(
        type: 'expense',
        amount: 30,
        currency: 'SOL',
        accountId: accounts[0].id!,
        categoryId: food.id!,
        date: date,
        comment: 'Almuerzo',
        createdAt: now,
      ),
      FinancialTransactionModel(
        type: 'income',
        amount: 50,
        currency: 'SOL',
        accountId: accounts[0].id!,
        categoryId: food.id!,
        date: date,
        comment: 'Devolución',
        createdAt: now,
      ),
      FinancialTransactionModel(
        type: 'expense',
        amount: 10,
        currency: 'SOL',
        accountId: accounts[0].id!,
        categoryId: food.id!,
        date: date,
        comment: 'Ajuste Manual',
        createdAt: now,
      ),
    ]) {
      await transactionService.insertTransaction(transaction);
    }

    for (final category in [food, transferCategory]) {
      await budgetService.insertBudgetRule(
        BudgetRuleModel(
          name: category.name,
          categoryId: category.id,
          amount: 100,
          currency: 'SOL',
          recurrenceType: BudgetRecurrenceType.monthly,
          startDate: '2026-07-01T00:00:00.000',
          createdAt: now,
        ),
      );
    }

    final overview = await budgetService.getOverview(year: 2026, month: 7);
    expect(overview.monthBudget, 200);
    expect(overview.monthSpent, 30);
    expect(
      overview.items
          .firstWhere((item) => item.view.rule.name == 'Comida')
          .spent,
      30,
    );
    expect(
      overview.items
          .firstWhere((item) => item.view.rule.name == 'Transferencia enviada')
          .spent,
      0,
    );
  });
}
