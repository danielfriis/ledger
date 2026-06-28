# frozen_string_literal: true

module Ledger
  # A snapshot of the accounting equation at a moment in time:
  #
  #   Assets = Liabilities + Equity + Retained earnings
  #
  # Retained earnings (revenue less expenses to date) are folded in so the
  # sheet balances before any closing entries are made.
  class BalanceSheet
    Position = Struct.new(:account, :balance)

    attr_reader :as_of

    def initialize(as_of: nil)
      @as_of = as_of
    end

    def assets = positions(Asset)
    def liabilities = positions(Liability)
    def equity = positions(Equity)

    def total_assets = Asset.balance(as_of:)
    def total_liabilities = Liability.balance(as_of:)
    def total_equity = Equity.balance(as_of:)

    def retained_earnings
      Revenue.balance(as_of:) - Expense.balance(as_of:)
    end

    def total_liabilities_and_equity
      total_liabilities + total_equity + retained_earnings
    end

    def balanced?
      total_assets == total_liabilities_and_equity
    end

    private

    def positions(type)
      type.order(:name).map { |account| Position.new(account, account.balance(as_of:)) }
    end
  end
end
