# Ledger

An append-only, double-entry bookkeeping **Rails application** — a modern take on
[Plutus](https://github.com/mbulat/plutus).

Ledger gives you the five standard account types, balanced journal entries, and
financial reports — with one design rule that keeps the books honest: **posted
entries are immutable**. You never edit or delete history; you post a reversing
entry. A few deliberate choices:

- **Signed integer money.** A line stores `amount_cents` where a debit is
  positive and a credit is negative. An entry is balanced when its lines sum to
  zero, and any balance is a single SQL `SUM` — no per-account iteration, and
  contra accounts net out for free. The trial balance is always zero.
- **Append-only by default.** Once posted, entries and lines can't be updated or
  destroyed. Corrections go through `reverse!`.
- **Plain, readable models.** Standard Rails STI and concerns — no DSL to learn.

The domain lives under the `Ledger` namespace in `app/models/ledger/`; its tables
are prefixed `ledger_`. (`LedgerApp` is the Rails application module itself.)

## Getting started

```bash
bin/setup                 # installs gems, prepares the database, starts the server
# or, step by step:
bundle install
bin/rails db:prepare      # create the database, run migrations, load seeds
bin/rails db:seed         # a tiny sample chart of accounts + opening entries
```

Ruby is pinned in `.ruby-version` (3.3.6). The one command that runs the whole
check suite — Minitest **and** RuboCop — is:

```bash
bin/rails test            # tests only
bundle exec rake          # tests + rubocop-rails-omakase
```

## Usage

Explore in the console with `bin/rails console`:

```ruby
cash    = Ledger::Asset.create!(name: "Cash", code: "1000")
capital = Ledger::Equity.create!(name: "Capital", code: "3000")
revenue = Ledger::Revenue.create!(name: "Sales", code: "4000")

# Amounts are integer cents (5_00 == $5.00). Money objects work too.
Ledger::Entry.post!(description: "Owner funds the business") do |entry|
  entry.debit  cash,    100_00
  entry.credit capital, 100_00
end

sale = Ledger::Entry.post!(description: "Cash sale", source: some_invoice) do |entry|
  entry.debit  cash,    5_00
  entry.credit revenue, 5_00
end

cash.balance                       # => #<Ledger::Money 105.00 USD>
Ledger::Revenue.balance            # => #<Ledger::Money 5.00 USD>
cash.balance(as_of: Date.today)    # cumulative up to a date
revenue.balance(from: a, to: b)    # activity within a window
```

The default currency is `Ledger::DEFAULT_CURRENCY` (`"USD"`) in
`app/models/ledger.rb` — one app, one place to change it.

### Corrections are reversals, not edits

```ruby
sale.update!(description: "...")   # raises ActiveRecord::ReadOnlyRecord
sale.destroy                       # raises Ledger::RecordImmutable

sale.reverse!                      # posts an offsetting entry
sale.reversed?                     # => true
sale.reversal                      # the reversing entry
Ledger.trial_balance.zero?         # => true, always
```

### Reports

```ruby
sheet = Ledger::BalanceSheet.new(as_of: Date.today)
sheet.total_assets
sheet.balanced?                    # Assets == Liabilities + Equity + retained earnings

income = Ledger::IncomeStatement.new(from: quarter_start, to: quarter_end)
income.net_income
```

## Account types

| Type        | Normal balance | Tracks                         |
| ----------- | -------------- | ------------------------------ |
| `Asset`     | debit          | resources owned                |
| `Liability` | credit         | what is owed                   |
| `Equity`    | credit         | owners' residual interest      |
| `Revenue`   | credit         | income earned                  |
| `Expense`   | debit          | costs incurred                 |

Pass `contra: true` to flip an account's normal side (e.g. a contra-asset like
accumulated depreciation).
