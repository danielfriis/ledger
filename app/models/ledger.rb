# frozen_string_literal: true

# Ledger is the append-only, double-entry bookkeeping domain.
#
# The whole system rests on one invariant: every Entry's Lines sum to zero,
# where a Line stores a *signed* amount (debit positive, credit negative).
# Because the amounts are signed, balances are a single SQL +SUM+ and the
# books are correct by construction — the trial balance is always zero.
#
# This module is the domain's namespace; Zeitwerk loads the models in
# app/models/ledger/ underneath it. It is intentionally *not* the Rails
# application module (that is LedgerApp), so it stays a pure domain home.
module Ledger
  # The currency applied to any account or Ledger::Money that doesn't name one.
  # Change it here — one app, one place, no configuration seam to thread.
  DEFAULT_CURRENCY = "USD"

  class Error < StandardError; end

  # Raised when something tries to mutate an already-posted Entry or Line.
  class RecordImmutable < Error; end

  class << self
    def default_currency = DEFAULT_CURRENCY

    # The sum of every line in the system. It is always zero in a healthy set
    # of books; a non-zero value means an entry was written unbalanced.
    def trial_balance
      Money.new(Line.sum(:amount_cents))
    end

    # Namespacing the tables (ledger_accounts, ledger_entries, ledger_lines)
    # keeps the bookkeeping schema tidily grouped. Rails applies this prefix
    # automatically to every model in the Ledger namespace.
    def table_name_prefix
      "ledger_"
    end
  end
end
