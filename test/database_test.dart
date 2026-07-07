import 'package:finanzas_personales/database/app_database.dart';
import 'package:finanzas_personales/models/account_model.dart';
import 'package:finanzas_personales/models/category_model.dart';
import 'package:finanzas_personales/models/financial_transaction_model.dart';
import 'package:finanzas_personales/models/transfer_model.dart';
import 'package:finanzas_personales/services/account_service.dart';
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

    expect(
      accounts.any((account) => account.name == 'Cuenta test'),
      isTrue,
    );
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
    final category = (await categoryService.getAllCategories())
        .firstWhere((category) => category.type == 'expense');
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
    final category = (await categoryService.getAllCategories())
        .firstWhere((category) => category.type == 'expense');
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
    final category = (await categoryService.getAllCategories())
        .firstWhere((category) => category.type == 'income');
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
    final category = (await categoryService.getAllCategories())
        .firstWhere((category) => category.type == 'expense');
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
    final category = (await categoryService.getAllCategories())
        .firstWhere((category) => category.type == 'expense');
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
    final account = (await accountService.getVisibleAccounts())
        .firstWhere((account) => account.currency == 'USD');
    final category = (await categoryService.getAllCategories())
        .firstWhere((category) => category.type == 'expense');
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
    final actions =
        await QuickActionService(database: database).getAllQuickActions();
    final menu = actions.firstWhere((action) => action.name == 'Menú');

    expect(menu.amount, 12);
    expect(menu.currency, 'SOL');
    expect(menu.accountId, isNotNull);
    expect(menu.categoryId, isNotNull);
  });

  test('registro rapido guarda gasto y actualiza saldo', () async {
    final menu =
        (await QuickActionService(database: database).getAllQuickActions())
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
    final category = (await categoryService.getAllCategories())
        .firstWhere((category) => category.type == 'expense');
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
    final category = (await categoryService.getAllCategories())
        .firstWhere((category) => category.type == 'expense');
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
    final category = (await categoryService.getAllCategories())
        .firstWhere((category) => category.type == 'income');
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

  test('transfiere entre cuentas sin crear ingreso o gasto', () async {
    final accounts = await accountService.getVisibleAccounts();
    final from = accounts.first;
    final to = accounts[1];
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

    expect(updatedFrom!.currentBalance, from.currentBalance - 30);
    expect(updatedTo!.currentBalance, to.currentBalance + 30);
    expect(transactions, isEmpty);
  });

  test('lee botones rapidos iniciales', () async {
    final actions =
        await QuickActionService(database: database).getAllQuickActions();

    expect(
      actions.map((action) => action.name),
      containsAll(['Menú', 'Pasaje', 'Café', 'Postre', 'Taxi']),
    );
  });

  test('lee tipo de cambio inicial', () async {
    final latest =
        await ExchangeRateService(database: database).getLatestRate();

    expect(latest, isNotNull);
    expect(latest!.rate, 3.80);
  });
}
