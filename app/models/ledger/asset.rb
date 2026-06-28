# frozen_string_literal: true

module Ledger
  # Resources the entity owns (cash, receivables, inventory). Debit-normal.
  class Asset < Account
    self.normal_balance = :debit
  end
end
