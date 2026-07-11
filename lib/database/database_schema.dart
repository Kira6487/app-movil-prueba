class DatabaseSchema {
  const DatabaseSchema._();

  static const databaseName = 'finanzas_personales.db';
  static const version = 2;

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
  target_amount REAL NOT NULL,
  current_amount REAL NOT NULL DEFAULT 0,
  currency TEXT NOT NULL,
  planned_monthly_amount REAL,
  deadline TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
)
''',
    '''
CREATE TABLE wallets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  account_id INTEGER NOT NULL,
  amount REAL NOT NULL DEFAULT 0,
  currency TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
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
  ];
}
