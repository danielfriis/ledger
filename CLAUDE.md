# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ledger is a Rails application for append-only, double-entry bookkeeping — a modern
take on Plutus. Typed accounts (Asset, Liability, Equity, Revenue, Expense),
balanced journal entries, integer-cent money, and reports. The one invariant:
a line stores a **signed `amount_cents`** (debit +, credit −), so an entry
balances when its lines sum to zero and the trial balance is always zero.

The domain lives under the `Ledger` namespace in `app/models/ledger/`, with tables
prefixed `ledger_` (`Ledger.table_name_prefix`). The `Ledger` module itself —
`app/models/ledger.rb` — holds the domain config (`default_currency`,
`trial_balance`, the error classes). `LedgerApp` is the Rails application module,
kept deliberately separate so it never shadows the autoloaded `Ledger` namespace.

## How we build

- **The 37signals/DHH way.** Vanilla Rails: rich models, concerns over service
  objects, value objects, intention-revealing names, comments that explain *why*.
- **Append-only.** Posted entries and lines are immutable; fix mistakes with
  `reverse!`, never edits or deletes.
- **Accounts are reference data, not events.** They stay editable, with two
  guards: the fields the balance is computed from (`type`, `contra`, `currency`)
  lock once an account has postings, so history is never rewritten; and `name`/
  `code` edits are logged to an append-only `AccountChange` trail. Retire an
  account with `archive!` (reversible, refuses new postings), never delete.
- **Money is integer cents** via the owned `Ledger::Money` value object — no floats.
- **Tested and linted.** `mise exec ruby@3.3.13 -- bundle exec rake` runs Minitest
  + `rubocop-rails-omakase`; keep it green. (System Ruby is 2.6 — use mise's 3.3.13.)

## Keep this file alive

Update this file whenever the project's purpose or the way we build it changes,
so it always reflects how we actually work.
