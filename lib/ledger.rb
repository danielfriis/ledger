# frozen_string_literal: true

require "bigdecimal"
require "active_record"

# Ledger is an append-only, double-entry bookkeeping engine.
#
# The whole system rests on one invariant: every Entry's Lines sum to zero,
# where a Line stores a *signed* amount (debit positive, credit negative).
# Because the amounts are signed, balances are a single SQL +SUM+ and the
# books are correct by construction — the trial balance is always zero.
module Ledger
  class Error < StandardError; end

  # Raised when something tries to mutate an already-posted Entry or Line.
  class RecordImmutable < Error; end

  class << self
    attr_writer :default_currency

    # Currency used for accounts and money that don't specify one.
    def default_currency
      @default_currency ||= "USD"
    end

    # Ledger.configure { |c| c.default_currency = "EUR" }
    def configure
      yield self
    end

    # Namespacing the tables (ledger_accounts, ledger_entries, ledger_lines)
    # so the gem works inside a host app's schema without collisions — and
    # without needing the Rails engine to be loaded (handy for tests).
    def table_name_prefix
      "ledger_"
    end

    # The sum of every line in the system. It is always zero in a healthy set
    # of books; a non-zero value means an entry was written unbalanced.
    def trial_balance
      Money.new(Line.sum(:amount_cents))
    end
  end
end

require "ledger/version"
require "ledger/money"
require "ledger/immutable"

if defined?(Rails::Engine)
  require "ledger/engine"
else
  # Plain Ruby / test usage: load the ActiveRecord models directly, since
  # there is no Rails autoloader to do it for us.
  require "ledger/models"
end
