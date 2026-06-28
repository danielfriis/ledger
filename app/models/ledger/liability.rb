# frozen_string_literal: true

module Ledger
  # What the entity owes to others (payables, loans). Credit-normal.
  class Liability < Account
    self.normal_balance = :credit
  end
end
