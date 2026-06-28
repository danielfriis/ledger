# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Ledger is a Rails-engine gem for append-only, double-entry bookkeeping — a modern
take on Plutus. Typed accounts (Asset, Liability, Equity, Revenue, Expense),
balanced journal entries, integer-cent money, and reports. The one invariant:
a line stores a **signed `amount_cents`** (debit +, credit −), so an entry
balances when its lines sum to zero and the trial balance is always zero.

## How we build

- **The 37signals/DHH way.** Vanilla Rails: rich models, concerns over service
  objects, value objects, intention-revealing names, comments that explain *why*.
- **Append-only.** Posted entries and lines are immutable; fix mistakes with
  `reverse!`, never edits or deletes.
- **Money is integer cents** via the owned `Ledger::Money` value object — no floats.
- **Tested and linted.** `mise exec ruby@3.3.6 -- bundle exec rake` runs Minitest
  + `rubocop-rails-omakase`; keep it green. (System Ruby is 2.6 — use mise's 3.3.6.)

## Keep this file alive

Update this file whenever the project's purpose or the way we build it changes,
so it always reflects how we actually work.
