# frozen_string_literal: true

module Ledger
  # The owners' residual interest in the entity. Credit-normal.
  class Equity < Account
    self.normal_balance = :credit
  end
end
