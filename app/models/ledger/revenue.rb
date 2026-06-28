# frozen_string_literal: true

module Ledger
  # Income the entity earns. Credit-normal.
  class Revenue < Account
    self.normal_balance = :credit
  end
end
