# frozen_string_literal: true

module Ledger
  # Costs the entity incurs to earn revenue. Debit-normal.
  class Expense < Account
    self.normal_balance = :debit
  end
end
