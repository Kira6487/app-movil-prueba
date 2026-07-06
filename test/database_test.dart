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
