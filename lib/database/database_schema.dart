class DatabaseSchema {
  const DatabaseSchema._();

  static const databaseName = 'finanzas_personales.db';
  static const version = 5;

  static const createLedgerAccounts = '''
CREATE TABLE IF NOT EXISTS ledger_accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  account_type TEXT NOT NULL,
  parent_account_id INTEGER,
  currency TEXT NOT NULL,
  reference_type TEXT,
  reference_id INTEGER,
  is_active INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY(parent_account_id) REFERENCES ledger_accounts(id)
)
''';

  static const createJournalEntries = '''
CREATE TABLE IF NOT EXISTS journal_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  description TEXT NOT NULL,
  source_type TEXT NOT NULL,
  source_id INTEGER,
  budget_item_id INTEGER,
  savings_item_id INTEGER,
  status TEXT NOT NULL DEFAULT 'posted',
  created_at TEXT NOT NULL
)
''';

  static const createJournalLines = '''
CREATE TABLE IF NOT EXISTS journal_lines (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  journal_entry_id INTEGER NOT NULL,
  ledger_account_id INTEGER NOT NULL,
  debit REAL NOT NULL DEFAULT 0 CHECK(debit >= 0),
  credit REAL NOT NULL DEFAULT 0 CHECK(credit >= 0),
  currency TEXT NOT NULL,
  exchange_rate REAL,
  base_amount REAL,
  CHECK((debit > 0 AND credit = 0) OR (credit > 0 AND debit = 0)),
  FOREIGN KEY(journal_entry_id) REFERENCES journal_entries(id),
  FOREIGN KEY(ledger_account_id) REFERENCES ledger_accounts(id)
)
''';

  static const createBudgets = '''
CREATE TABLE IF NOT EXISTS budgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  budget_type TEXT NOT NULL,
  category_id INTEGER,
  amount REAL NOT NULL,
  currency TEXT NOT NULL,
  recurrence_type TEXT NOT NULL,
  selected_weekdays TEXT,
  units_per_day REAL NOT NULL DEFAULT 1,
  description TEXT,
  condition_text TEXT,
  start_date TEXT,
  end_date TEXT,
  icon_key TEXT,
  color_hex TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(category_id) REFERENCES categories(id)
)
''';

  static const statements = [
    '''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  icon_key TEXT,
  color_hex TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
)
''',
    '''
CREATE TABLE accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  account_type TEXT NOT NULL,
  currency TEXT NOT NULL,
  initial_balance REAL NOT NULL DEFAULT 0,
  current_balance REAL NOT NULL DEFAULT 0,
  is_hidden_from_budget INTEGER NOT NULL DEFAULT 0,
  color TEXT,
  icon TEXT,
  created_at TEXT NOT NULL
)
''',
    '''
CREATE TABLE financial_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  amount REAL NOT NULL,
  currency TEXT NOT NULL,
  exchange_rate REAL,
  amount_in_base_currency REAL,
  account_id INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  related_type TEXT,
  related_id INTEGER,
  journal_entry_id INTEGER,
  date TEXT NOT NULL,
  comment TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY(account_id) REFERENCES accounts(id),
  FOREIGN KEY(category_id) REFERENCES categories(id)
)
''',
    '''
CREATE TABLE transfers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_account_id INTEGER NOT NULL,
  to_account_id INTEGER NOT NULL,
  amount_from REAL NOT NULL,
  currency_from TEXT NOT NULL,
  amount_to REAL NOT NULL,
  currency_to TEXT NOT NULL,
  exchange_rate REAL,
  from_wallet_id INTEGER,
  to_wallet_id INTEGER,
  savings_item_id INTEGER,
  journal_entry_id INTEGER,
  date TEXT NOT NULL,
  comment TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY(from_account_id) REFERENCES accounts(id),
  FOREIGN KEY(to_account_id) REFERENCES accounts(id)
)
''',
    '''
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
  created_at TEXT NOT NULL,
  FOREIGN KEY(category_id) REFERENCES categories(id)
)
''',
    createBudgets,
    '''
CREATE TABLE scheduled_expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category_id INTEGER NOT NULL,
  account_id INTEGER,
  amount REAL NOT NULL,
  currency TEXT NOT NULL,
  due_day INTEGER,
  due_date TEXT,
  recurrence_type TEXT NOT NULL,
  alert_days_before INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL,
  comment TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  FOREIGN KEY(category_id) REFERENCES categories(id),
  FOREIGN KEY(account_id) REFERENCES accounts(id)
)
''',
    '''
CREATE TABLE credit_cards (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  bank_name TEXT,
  currency TEXT NOT NULL,
  credit_limit REAL NOT NULL,
  consumed_balance REAL NOT NULL DEFAULT 0,
  available_balance REAL NOT NULL,
  cut_day INTEGER,
  payment_due_day INTEGER,
  tea REAL,
  trea REAL,
  color TEXT,
  icon TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
)
''',
    '''
CREATE TABLE credit_card_installments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  credit_card_id INTEGER NOT NULL,
  category_id INTEGER,
  description TEXT,
  total_amount REAL NOT NULL,
  currency TEXT NOT NULL,
  installment_count INTEGER NOT NULL,
  installment_amount REAL NOT NULL,
  first_payment_date TEXT,
  current_installment INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY(credit_card_id) REFERENCES credit_cards(id),
  FOREIGN KEY(category_id) REFERENCES categories(id)
)
''',
    '''
CREATE TABLE savings_goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category_id INTEGER NOT NULL,
  target_amount REAL NOT NULL,
  current_amount REAL NOT NULL DEFAULT 0,
  currency TEXT NOT NULL,
  planned_monthly_amount REAL,
  deadline TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
  ,FOREIGN KEY(category_id) REFERENCES categories(id)
)
''',
    '''
CREATE TABLE wallets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  account_id INTEGER NOT NULL,
  ledger_account_id INTEGER,
  amount REAL NOT NULL DEFAULT 0,
  currency TEXT NOT NULL,
  wallet_type TEXT NOT NULL DEFAULT 'piggyBank',
  icon_key TEXT,
  color_hex TEXT,
  savings_category_id INTEGER,
  savings_item_id INTEGER,
  is_spendable INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  FOREIGN KEY(account_id) REFERENCES accounts(id)
)
''',
    '''
CREATE TABLE exchange_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_currency TEXT NOT NULL,
  to_currency TEXT NOT NULL,
  rate REAL NOT NULL,
  date TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''',
    '''
CREATE TABLE quick_actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  amount REAL NOT NULL,
  currency TEXT NOT NULL,
  category_id INTEGER,
  account_id INTEGER,
  budget_item_id INTEGER,
  comment TEXT,
  icon TEXT,
  color TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  FOREIGN KEY(category_id) REFERENCES categories(id),
  FOREIGN KEY(account_id) REFERENCES accounts(id)
)
''',
    createLedgerAccounts,
    createJournalEntries,
    createJournalLines,
    '''CREATE UNIQUE INDEX IF NOT EXISTS idx_journal_source
ON journal_entries(source_type, source_id) WHERE source_id IS NOT NULL''',
    '''CREATE UNIQUE INDEX IF NOT EXISTS idx_ledger_reference
ON ledger_accounts(reference_type, reference_id)
WHERE reference_type IS NOT NULL AND reference_id IS NOT NULL''',
    '''CREATE INDEX IF NOT EXISTS idx_journal_budget
ON journal_entries(budget_item_id, date)''',
    '''CREATE INDEX IF NOT EXISTS idx_journal_savings
ON journal_entries(savings_item_id, date)''',
  ];
}
